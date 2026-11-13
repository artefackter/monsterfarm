local RS=game:GetService("ReplicatedStorage");local S=RS.Shared
local C=require(S.Config.MutantConfig);local NC=require(S.Config.NightConfig)
local D=require(script.Parent.DataService);local P=require(script.Parent.PlotService);local Z=require(script.Parent.ZombieService)
local Day=require(script.Parent.DayNightService);local Pets=require(script.Parent.PetService);local A=require(script.Parent.AnalyticsTracker)
local Model=require(S.MutantModel)
local Navigation=require(script.Parent.MutantNavigation)
local M={Live={},Targets={},Stunned={},GuardTimes={},AlarmTimes={},Serial=0,WaveIndex=0,Served={}}
local rng=Random.new();local rem;local folder;local nightStart
local function fx(...) if rem then rem.MutantFX:FireAllClients(...) end end
local function notify(p,key,args) if rem and p.Parent then rem.Notice:FireClient(p,key,args) end end
function M.Count() local n=0;for _,a in pairs(M.Live) do if not a.road then n+=1 end end;return n end -- the road has its own budget
M.FX=fx
function M.Eligible(d,z) return z.zone=="Field" and not z.carriedBy and not z.pendingTransfer and Z.Models[z.id] and Z.Models[z.id].Parent end
function M.BlocksIncome(d,z)
 local a=M.Targets[z.id];local s=M.Stunned[z.id]
 return (a and a.profile==d and a.state=="Attacking") or (s and s.profile==d and s.untilTime>os.clock()) or false
end
local function attributes(id)
 local m=Z.Models[id];if not m then return end
 local a=M.Targets[id];local s=M.Stunned[id]
 m:SetAttribute("MutantBiting",a~=nil and a.state=="Attacking")
 m:SetAttribute("MutantStunned",s~=nil and s.untilTime>os.clock())
end
function M.ReleaseTarget(a)
 local z=a.target;a.target=nil
 if z and M.Targets[z.id]==a then M.Targets[z.id]=nil;attributes(z.id) end
end
function M.ChooseTarget(a)
 M.ReleaseTarget(a);local choices={}
 for _,z in ipairs(a.profile.zombies) do if M.Eligible(a.profile,z) and not M.Targets[z.id] then table.insert(choices,z) end end
 if #choices==0 then return false end
 a.target=choices[rng:NextInteger(1,#choices)];M.Targets[a.target.id]=a;return true
end
function M.State(a,state,now)
 if state=="Running" and a.state=="Spawning" then a.model:SetAttribute("NoticedAt",workspace:GetServerTimeNow()) end
 -- hammering the farm gate looks like any other attack on the client
 a.state=state;a.since=now or os.clock();a.model:SetAttribute("State",state=="Breaking" and "Attacking" or state);a.model:SetAttribute("StateStartedAt",workspace:GetServerTimeNow())
 if a.target then attributes(a.target.id) end
end
function M.Remove(a,reason)
 if not M.Live[a.id] then return end
 M.Live[a.id]=nil;M.ReleaseTarget(a);fx(reason or "Smoke",a.id,a.model.PrimaryPart.Position,a.owner and a.owner.UserId or 0)
 a.model:Destroy()
end
function M.Damage(a,damage,killer,crit)
 if not a or not M.Live[a.id] or a.hp<=0 or a.state=="Spawning" then return false end
 a.model:SetAttribute("HitAt",workspace:GetServerTimeNow())
 a.hp=math.max(0,a.hp-damage);a.model:SetAttribute("Health",a.hp)
 -- Everyone who hits a boss shares the win, not only the last shot.
 if a.boss and killer then a.damagers=a.damagers or {};a.damagers[killer]=true end
 fx("Hit",a.id,a.model.PrimaryPart.Position,damage,crit==true)
 if a.hp==0 then
  -- Claim the death before analytics/remotes; repeated pellets can never pay again.
  local pos=a.model.PrimaryPart.Position;M.Remove(a,"Death")
  local paid={};if a.boss and a.damagers then paid=a.damagers elseif killer then paid[killer]=true end
  for who in pairs(paid) do
   local d=D.Profiles[who]
   if d and who.Parent then
    local reward=math.clamp(Z.Income(d)*C.RewardIncomeSeconds,C.RewardMin,C.RewardMax)*(a.night and require(S.Config.RoadConfig).Night.KillReward or 1)*(a.rewardMult or 1)
    d.coins+=reward;A.Economy(who,reward,d.coins,"MutantReward",pos);fx("Reward",a.id,pos,who.UserId,reward)
    if M.OnKill then M.OnKill(who) end
    if (a.road or a.giant) and M.OnRoadKill then M.OnRoadKill(who,a) end -- mutagen
   end
  end
  if a.road and a.boss and killer and D.Profiles[killer] and M.OnBossDefeated then M.OnBossDefeated(killer,pos,a) end
  if a.giant and M.OnGiantDefeated then M.OnGiantDefeated(killer,pos,a) end
 end
 return true
end
-- The Blood Moon giant (BloodMoonService moves it): a ruins boss blown up to `height` studs, feet at `feet`.
function M.SpawnGiant(kind,feet,variant,height)
 M.Serial+=1;local id=tostring(M.Serial);local model=Model.Build(kind,feet*CFrame.new(0,C.RootHeight,0),variant)
 local k=height/math.max(1,model:GetAttribute("MonsterHeight") or 12)
 model:ScaleTo(k);model:PivotTo(model:GetPivot()+Vector3.new(0,(k-1)*C.RootHeight,0))
 local a={id=id,giant=true,boss=true,kind=kind,hp=1,model=model,spawn=feet.Position}
 M.Live[id]=a;model:SetAttribute("MutantId",id);model:SetAttribute("Kind",kind);model:SetAttribute("Giant",true);model:SetAttribute("Boss",0)
 M.State(a,"Spawning");model.Parent=folder;return a
end
function M.SpawnRoad(kind,cf,speed,variant)
 M.Serial+=1;local id=tostring(M.Serial);local model=Model.Build(kind,cf,variant)
 local a={id=id,road=true,kind=kind,hp=C.Types[kind].Health,model=model,spawn=cf.Position,speed=speed}
 M.Live[id]=a;model:SetAttribute("MutantId",id);model:SetAttribute("Health",a.hp);model:SetAttribute("MaxHealth",a.hp);model:SetAttribute("Kind",kind)
 M.State(a,"Spawning");model.Parent=folder;fx("Spawn",id,cf.Position,0);return a
end
-- A night raider: a weighted pick from FarmRaiders (MutantConfig).
local function raider()
 local total=0;for _,r in ipairs(C.FarmRaiders or {}) do total+=r.Weight end
 local roll=rng:NextNumber()*total
 for _,r in ipairs(C.FarmRaiders or {}) do roll-=r.Weight;if roll<=0 then return r end end
 return nil
end
function M.Spawn(p,kind)
 local variant;if not kind then variant=raider() end
 local d=D.Profiles[p];local plot=P.Assigned[p];kind=kind or variant and variant.Kind or C.DefaultType
 if not d or not plot or not d.tutorialDone or not C.Types[kind] or M.Count()>=C.ServerLimit then return end
 M.Serial+=1;local id=tostring(M.Serial);local radius=rng:NextNumber(C.SpawnMin,C.SpawnMax);local side=rng:NextNumber(-C.SpawnSide,C.SpawnSide)
 local edge=require(S.Config.ZoneConfig).FarmHalf+6;local pos=(plot.Base*CFrame.new(rng:NextNumber()<.5 and -edge or edge,C.RootHeight,side)).Position
 local cf=CFrame.lookAt(pos,Vector3.new(plot.Base.X,pos.Y,plot.Base.Z));local model=Model.Build(kind,cf,variant)
 local a={id=id,owner=p,profile=d,kind=kind,hp=C.Types[kind].Health,model=model,spawn=pos,alarmed=false}
 if not M.ChooseTarget(a) then model:Destroy();return end
 M.Live[id]=a;model:SetAttribute("MutantId",id);model:SetAttribute("Owner",p.UserId);model:SetAttribute("Health",a.hp);model:SetAttribute("MaxHealth",a.hp);model:SetAttribute("Kind",kind)
 M.State(a,"Spawning");model.Parent=folder;fx("Spawn",id,pos,p.UserId);return a
end
function M.Quota(d) local n=0;for _,z in ipairs(d.zombies) do if z.zone=="Field" and not z.carriedBy and not z.pendingTransfer then n+=1 end end;return n==0 and 0 or math.min(C.MaxPerFarmWave,1+math.floor(n/C.FieldPerExtra)) end
function M.Wave()
 -- Rotate who goes first when the server cap prevents all farms receiving their quota.
 local players={} for p,d in pairs(D.Profiles) do if d.tutorialDone and P.Assigned[p] then table.insert(players,p) end end
 table.sort(players,function(a,b) return a.UserId<b.UserId end)
 for step=1,#players do local p=players[(step+M.WaveIndex-2)%#players+1];local n=M.Quota(D.Profiles[p]);local spawned=0
  for _=1,n do if M.Spawn(p) then spawned+=1 end end
  if spawned>0 then M.Served[p]=true;notify(p,"mutantWave") end
 end
end
function M.Flee(a,now) M.ReleaseTarget(a);M.State(a,"Fleeing",now) end
function M.FinishBite(a,now)
 local z=a.target;local d=a.profile
 if not z then M.Flee(a,now);return end
 if d.playTime<NC.Newbie then notify(a.owner,"mutantNewbie") else
  local amount=math.max(0,math.min(d.coins*C.TheftFraction,Z.Income(d,true)*C.TheftIncomeSeconds))
  d.coins-=amount;if amount>0 then A.Economy(a.owner,-amount,d.coins,"MutantTheft") end
  M.Stunned[z.id]={profile=d,owner=a.owner,untilTime=now+C.StunSeconds};notify(a.owner,"mutantStolen",{n=math.floor(amount)})
 end
 M.Flee(a,now);attributes(z.id)
end
local function move(a,target,dt)
 Navigation.Move(a,target,C.Types[a.kind].Speed,dt)
end
function M.ClearOwner(p)
 for _,a in pairs(M.Live) do if a.owner==p then M.Remove(a) end end
 for id,s in pairs(M.Stunned) do if s.owner==p then M.Stunned[id]=nil;attributes(id) end end
 M.GuardTimes[p]=nil;M.AlarmTimes[p]=nil;M.Served[p]=nil
end
function M.Tick(dt,now,night)
 now=now or os.clock();if night==nil then night=Day.State() end
 if night and not nightStart then nightStart=now;M.WaveIndex=0;M.Served={} end
 if not night then
  nightStart=nil;M.WaveIndex=0;for _,a in pairs(M.Live) do if not a.road and not a.giant then M.Remove(a) end end
 elseif not M.PauseWaves then -- no farm raids while the Blood Moon giant is out
  if M.WaveIndex<C.WavesPerNight and now-nightStart>=C.FirstWave+M.WaveIndex*C.WaveInterval then M.WaveIndex+=1;M.Wave() end
 end
 -- A farm becoming eligible after the scheduled waves still gets its first encounter tonight.
 if night and not M.PauseWaves and now-nightStart>=C.FirstWave then
  for p,d in pairs(D.Profiles) do if not M.Served[p] and d.tutorialDone and P.Assigned[p] and M.Quota(d)>0 then
   local n=0;for _=1,M.Quota(d) do if M.Spawn(p) then n+=1 end end
   if n>0 then M.Served[p]=true;notify(p,"mutantWave") end
  end end
 end
 for id,s in pairs(M.Stunned) do if s.untilTime<=now or D.Profiles[s.owner]~=s.profile or not Z.Find(s.profile,id) then M.Stunned[id]=nil end;attributes(id) end
 for _,a in pairs(M.Live) do
  if a.road or a.giant then continue end -- RoadService and BloodMoonService move their own
  local root=a.model.PrimaryPart;local plot=P.Assigned[a.owner]
  if not plot or D.Profiles[a.owner]~=a.profile or not a.owner.Parent then M.Remove(a);continue end
  if a.state~="Fleeing" and (not a.target or Z.Find(a.profile,a.target.id)~=a.target or not M.Eligible(a.profile,a.target)) then
   if M.ChooseTarget(a) then M.State(a,"Running",now) else M.Flee(a,now) end
  end
  local localPos=plot.Base:PointToObjectSpace(root.Position)
  local half=require(S.Config.ZoneConfig).FarmHalf;if not a.alarmed and math.abs(localPos.X)<=half and math.abs(localPos.Z)<=half then
   a.alarmed=true;fx("Intrusion",a.id,root.Position,a.owner.UserId)
   if Pets.GetBonuses(a.owner).hasAlarm and now-(M.AlarmTimes[a.owner] or -math.huge)>=C.AlarmGap then
    M.AlarmTimes[a.owner]=now;rem.PetAlarm:FireClient(a.owner,nil,"mutant")
   end
  end
  local Fence=require(script.Parent.FenceService)
  if a.state=="Spawning" then if now-a.since>=C.SpawnSeconds then M.State(a,"Running",now) end
  elseif now<(a.stunnedUntil or 0) then
  elseif a.state=="Stunned" then M.State(a,"Running",now)
  -- The farm gate first (owner, 2026-11-13): walk round to it and hammer it until it breaks; only then go in.
  elseif a.state=="Running" and not a.gateDone and not Fence.Open(plot) then
   local spot=Fence.Front(plot,a);local goal=Vector3.new(spot.X,root.Position.Y,spot.Z)
   if (root.Position-goal).Magnitude<=1.2 then M.State(a,"Breaking",now);a.nextStrike=now+.3 else move(a,goal,dt) end
  elseif a.state=="Breaking" then
   if Fence.Open(plot) then a.gateDone=true;M.State(a,"Running",now);continue end
   local center=Fence.Center(plot);local face=Vector3.new(center.X,root.Position.Y,center.Z)
   if (face-root.Position).Magnitude>.1 then root.CFrame=CFrame.lookAt(root.Position,face) end
   if now>=(a.nextStrike or 0) then
    a.nextStrike=now+1;a.model:SetAttribute("StrikeAt",workspace:GetServerTimeNow());fx("GateHit",a.id,center,a.owner.UserId)
    if Fence.Hit(plot,Fence.Damage(a.kind)) then a.gateDone=true;M.State(a,"Running",now);continue end
    -- a spiked fence hurts whoever hammers it; the owner gets the kill
    local spikes=Fence.Spikes(plot);if spikes>0 then M.Damage(a,spikes,a.owner);if not M.Live[a.id] then continue end end
   end
   if now-a.since>=require(S.Config.FenceConfig).Patience then M.Flee(a,now) end -- it gives up
  elseif a.state=="Running" then
   local goal=M.Contact(a)
   if (root.Position-goal).Magnitude<=.9 and Navigation.Visible(root.Position,goal) then M.State(a,"Attacking",now);a.nextStrike=now+.24 else move(a,goal,dt) end
  elseif a.state=="Attacking" then
   local goal=M.Contact(a)
   if (root.Position-goal).Magnitude>2 or not Navigation.Visible(root.Position,goal) then M.State(a,"Running",now);continue end
   local target=Z.Models[a.target.id]:GetPivot().Position;local face=Vector3.new(target.X,root.Position.Y,target.Z)
   if (face-root.Position).Magnitude>.1 then root.CFrame=CFrame.lookAt(root.Position,face) end
   if now>=(a.nextStrike or 0) then
    a.nextStrike=now+1;a.model:SetAttribute("StrikeAt",workspace:GetServerTimeNow())
    Z.Models[a.target.id]:SetAttribute("PanicUntil",workspace:GetServerTimeNow()+.4);fx("Bite",a.id,root.Position,a.owner.UserId)
   end
   if now-a.since>=C.BiteSeconds then M.FinishBite(a,now) end
  elseif a.state=="Fleeing" then move(a,a.spawn,dt);if now-a.since>=C.FleeSeconds then M.Remove(a) end end
 end

end
function M.Contact(a)
 local model=Z.Models[a.target.id];local cf,size=model:GetBoundingBox();local root=a.model.PrimaryPart
 local localPos=cf:PointToObjectSpace(root.Position);local half=size*.5
 local edge=Vector3.new(math.clamp(localPos.X,-half.X,half.X),localPos.Y,math.clamp(localPos.Z,-half.Z,half.Z))
 local delta=Vector3.new(localPos.X-edge.X,0,localPos.Z-edge.Z)
 if delta.Magnitude<.01 then
  if half.X-math.abs(localPos.X)<half.Z-math.abs(localPos.Z) then delta=Vector3.new(localPos.X>=0 and 1 or -1,0,0);edge=Vector3.new(delta.X*half.X,localPos.Y,localPos.Z)
  else delta=Vector3.new(0,0,localPos.Z>=0 and 1 or -1);edge=Vector3.new(localPos.X,localPos.Y,delta.Z*half.Z) end
 end
 local point=cf:PointToWorldSpace(edge+delta.Unit*1.8);return Vector3.new(point.X,root.Position.Y,point.Z)
end
function M.Init()
 Navigation.Init()
 folder=Instance.new("Folder");folder.Name="Mutants";folder.Parent=workspace
 rem=RS.Remotes;local e=Instance.new("RemoteEvent");e.Name="MutantFX";e.Parent=rem
 Z.IsIncomeBlocked=M.BlocksIncome
 game.Players.PlayerRemoving:Connect(M.ClearOwner)
 task.spawn(function() while task.wait(C.Poll) do M.Tick(C.Poll) end end)
end
return M
