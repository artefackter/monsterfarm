-- Blood Moon (owner, 2026-11-12; BloodMoonConfig). On a Blood Moon night the road shuts, the sky turns crimson and a
-- giant ruins boss walks out through the barrier onto the island. It hunts the nearest player outside a house:
-- a Roar around itself, a Stomp when you are close, a Smash where you stand when you keep your distance. Every blow
-- is telegraphed on the ground and knocks you down and away; nothing is lost. Everyone who hits it is paid when it
-- falls (MutantService.Damage) and graves rain down round the body, a few for each player. If the time runs out
-- (or dawn comes) it walks back into the ruins. Studio: /bloodmoon starts one now.
local Players=game:GetService("Players");local RS=game.ReplicatedStorage;local S=RS.Shared
local C=require(S.Config.BloodMoonConfig);local NC=require(S.Config.NightConfig)
local Rules=require(S.RoadMonsterRules);local RR=require(S.RoadRules);local Art=require(S.ArtKit);local Pal=require(S.Palette)
local M=require(script.Parent.MutantService);local Day=require(script.Parent.DayNightService)
local D=require(script.Parent.DataService);local P=require(script.Parent.PlotService);local G=require(script.Parent.GraveService)
local B={Active=nil,LastCycle=nil,Graves={},Taken={}}
local rng=Random.new()
local GROUND=-.5 -- the island lawn
local function road() return require(script.Parent.RoadService) end
local function notice(p,key,args) RS.Remotes.Notice:FireClient(p,key,args) end
local function noticeAll(key,args) RS.Remotes.Notice:FireAllClients(key,args) end
local function flat(v,y) return Vector3.new(v.X,y or 0,v.Z) end
local function rootOf(p) return p.Character and p.Character:FindFirstChild("HumanoidRootPart") end
-- Farms are a refuge (owner, 2026-11-12): on any farm's ground the giant neither hunts you nor reaches you.
local function onFarm(p) for _,plot in ipairs(P.Plots) do if P.Inside(p,plot) then return true end end;return false end

function B.Start()
 if B.Active then return false end
 local boss=Rules.Bosses[rng:NextInteger(1,#Rules.Bosses)]
 local Road=road();Road.SetClosed(true)
 -- it appears a little way down the road and walks out through the barrier
 local feet=Road.At(36,0,0)*CFrame.Angles(0,math.pi,0)
 local a=M.SpawnGiant(boss.Kind,feet,boss,C.Height)
 if not a then Road.SetClosed(false);return false end
 local hp=math.min(C.MaxHealth,C.HealthPerPlayer+C.ExtraPlayerHealth*math.max(0,#Players:GetPlayers()-1))
 a.hp=hp;a.maxHp=hp;a.rewardMult=C.RewardMult;a.damagers={}
 local m=a.model;m:SetAttribute("Health",hp);m:SetAttribute("MaxHealth",hp);m:SetAttribute("BossName",boss.Name)
 m:SetAttribute("GiantEndsAt",workspace:GetServerTimeNow()+C.Duration);m:SetAttribute("Enraged",true)
 local glow=Instance.new("Highlight");glow.Name="BloodGlow";glow.FillTransparency=1;glow.OutlineColor=Color3.fromRGB(255,40,70);glow.OutlineTransparency=.1;glow.DepthMode=Enum.HighlightDepthMode.Occluded;glow.Parent=m
 B.Active={a=a,boss=boss,endsAt=os.clock()+C.Duration,cooldowns={},entering=true,entry=Road.At(-40,0,0).Position}
 B.Taken={}
 Day.SetBlood(true);workspace:SetAttribute("BloodMoon",true);M.PauseWaves=true
 noticeAll("bloodMoonRise",{boss=boss.Name})
 M.FX("BossSpawn",a.id,m.PrimaryPart.Position,0,boss.Name)
 return true
end

function B.Finish()
 B.Active=nil;road().SetClosed(false);Day.SetBlood(false);workspace:SetAttribute("BloodMoon",nil);M.PauseWaves=false
end

-- Time is up (or the night is over): it goes back into the ruins.
function B.Escape()
 local A=B.Active;if not A then return end
 noticeAll("bloodMoonLost",{boss=A.boss.Name})
 if M.Live[A.a.id] then M.Remove(A.a,"Smoke") end
 B.Finish()
end

-- Walks straight over fences and houses (it is ten times your height) but stays on the island.
local function walk(A,goal,dt)
 local root=A.a.model.PrimaryPart;local pos=root.Position
 local to=flat(goal,pos.Y)-pos;if to.Magnitude<1 then return false end
 local nextPos=pos+to.Unit*math.min(to.Magnitude,C.Speed*dt)
 local r=flat(nextPos)
 if A.entering then
  if r.Magnitude<=C.IslandRadius then A.entering=false end
 elseif r.Magnitude>C.IslandRadius then
  r=r.Unit*C.IslandRadius;nextPos=Vector3.new(r.X,pos.Y,r.Z)
 end
 root.CFrame=CFrame.lookAt(nextPos,nextPos+to.Unit)
 return true
end

local function target(A)
 local pos=A.a.model.PrimaryPart.Position;local best,bestDist
 for _,p in ipairs(Players:GetPlayers()) do
  local r=rootOf(p);local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
  if r and h and h.Health>0 and not p:GetAttribute("InHouse") and not p:GetAttribute("OnRoad") and not onFarm(p) then
   local dist=(flat(r.Position,pos.Y)-pos).Magnitude
   if dist<400 and (not bestDist or dist<bestDist) then best,bestDist=p,dist end
  end
 end
 return best,bestDist
end

local function begin(A,atk,p,now)
 local a=A.a;local root=a.model.PrimaryPart.Position;local tp=rootOf(p).Position
 local center=atk.Name=="Smash" and Vector3.new(tp.X,GROUND,tp.Z) or Vector3.new(root.X,GROUND,root.Z)
 A.attack={atk=atk,center=center,ends=now+atk.Windup}
 local look=flat(tp,root.Y);if (look-root).Magnitude>.5 then a.model.PrimaryPart.CFrame=CFrame.lookAt(root,look) end
 M.State(a,"Windup",now);a.model:SetAttribute("AttackName",atk.Pose);a.model:SetAttribute("AttackDuration",atk.Windup)
 M.FX("Telegraph",a.id,center,atk.Radius,atk.Windup)
 M.FX("BossCue",a.id,root,0,"Dash")
end

local function resolve(A,now)
 local a=A.a;local atk=A.attack.atk;local center=A.attack.center
 if atk.Name=="Roar" then M.FX("Scream",a.id,center,atk.Radius) else M.FX("Slam",a.id,center,center,atk.Radius) end
 local Act=require(script.Parent.ActionService)
 for _,p in ipairs(Players:GetPlayers()) do
  local r=rootOf(p)
  if r and not p:GetAttribute("InHouse") and not onFarm(p) and (flat(r.Position)-flat(center)).Magnitude<=atk.Radius and r.Position.Y-center.Y<25 then
   local away=flat(r.Position)-flat(center);if away.Magnitude<.5 then away=flat(a.model.PrimaryPart.CFrame.LookVector) end
   Act.Knockout(p,atk.Stun,away,atk.Fling)
  end
 end
 A.cooldowns[atk.Name]=now+atk.Cooldown;A.attack=nil;M.State(a,"Recovering",now)
end

function B.Tick(dt)
 local night,left,cycle=Day.State()
 if not B.Active then
  -- a Blood Moon night: StartAfter seconds in, once per night
  if night and cycle and cycle%C.Every==C.Offset and B.LastCycle~=cycle and NC.Night-(left or 0)>=C.StartAfter then B.LastCycle=cycle;B.Start() end
  return
 end
 local A=B.Active;local a=A.a
 if not M.Live[a.id] then return end -- its death is handled by OnGiantDefeated
 if os.clock()>=A.endsAt or not night then B.Escape();return end
 local now=os.clock()
 if a.state=="Spawning" then if now-a.since>=1.2 then M.State(a,"Running",now) end;return end
 if A.entering then walk(A,A.entry,dt);if a.state~="Running" then M.State(a,"Running",now) end;return end
 if A.attack then if now>=A.attack.ends then resolve(A,now) end;return end
 if a.state=="Recovering" and now-a.since<.9 then return end
 local p,dist=target(A)
 if p then
  for _,atk in ipairs(C.Attacks) do
   if now>=(A.cooldowns[atk.Name] or 0) and dist<=atk.Range and dist>=(atk.MinRange or 0) then begin(A,atk,p,now);return end
  end
 end
 local goal=p and dist>C.Reach and rootOf(p).Position or not p and Vector3.zero or nil
 if goal and walk(A,goal,dt) then
  if a.state~="Running" then M.State(a,"Running",now) end
 elseif a.state~="Idle" then M.State(a,"Idle",now) end
end

-- Graves rain down round the fallen giant: each falls from the sky and lies there to be picked up.
local function grave(spot,kind)
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={P.World};params.RespectCanCollide=true
 local hit=workspace:Raycast(spot+Vector3.new(0,80,0),Vector3.new(0,-160,0),params)
 local final=CFrame.new((hit and hit.Position or spot)+Vector3.new(0,.25,0))*CFrame.Angles(0,rng:NextNumber(0,math.pi*2),0)
 local m=Instance.new("Model");m.Name="BloodMoonGrave";m:SetAttribute("Dropped",true);m:SetAttribute("GraveType",kind)
 Art.Spawn("G_Mound",m,final);Art.Spawn("G_"..kind,m,final)
 local ring=Instance.new("Part");ring.Name="RoadGlow";ring.Shape=Enum.PartType.Cylinder;ring.Size=Vector3.new(.14,9,9);ring.CFrame=final*CFrame.new(0,-.1,0)*CFrame.Angles(0,0,math.pi/2);ring.Color=Color3.fromHex("FF3B5C");ring.Material=Enum.Material.Neon;ring.Transparency=.25;ring.Parent=m
 local spotPart=Instance.new("Part");spotPart.Name="RoadGrabSpot";spotPart.Size=Vector3.new(4,4,4);spotPart.CFrame=final*CFrame.new(0,2,0);spotPart.Transparency=1;spotPart.Parent=m
 for _,q in m:GetDescendants() do if q:IsA("BasePart") then q.Anchored=true;q.CanCollide=false;q.CanQuery=false;q.CanTouch=false;q.CastShadow=q.Name~="RoadGlow" end end
 local pr=Instance.new("ProximityPrompt");pr.Name="RoadGrab";pr.ActionText="roadGrab";pr.HoldDuration=.6;pr.MaxActivationDistance=12;pr.RequiresLineOfSight=false;pr:SetAttribute("Grave",kind);pr.Parent=spotPart
 local record={model=m,kind=kind,expires=os.clock()+C.Graves.Lifetime}
 pr.Triggered:Connect(function(p) B.Take(p,record) end)
 m:PivotTo(final+Vector3.new(0,70,0));m.Parent=P.World;B.Graves[record]=true
 task.spawn(function()
  local t0=os.clock()
  while os.clock()-t0<.8 and m.Parent do local k=((os.clock()-t0)/.8)^2;m:PivotTo(final+Vector3.new(0,70*(1-k),0));task.wait() end
  if m.Parent then m:PivotTo(final);M.FX("Slam","0",final.Position,final.Position,5) end
 end)
end
function B.Take(p,record)
 if not B.Graves[record] or not record.model.Parent then return end
 local d=D.Profiles[p];local r=rootOf(p);if not d or not r then return end
 if (r.Position-record.model:GetPivot().Position).Magnitude>16 then return end
 local got=B.Taken[p] or 0;if got>=C.Graves.PerPickup then notice(p,"bloodMoonEnough",{n=C.Graves.PerPickup});return end
 B.Graves[record]=nil;record.model:Destroy();B.Taken[p]=got+1
 local item=G.New(record.kind);item.fromRoad=true;G.Store(p,item);notice(p,"bloodMoonGrave",{grave=record.kind})
end
function B.Rain(center,count)
 for i=1,count do
  local angle=i/count*math.pi*2+rng:NextNumber(-.25,.25);local r=rng:NextNumber(9,24)
  local spot=Vector3.new(center.X+math.cos(angle)*r,GROUND,center.Z+math.sin(angle)*r)
  local f=flat(spot);if f.Magnitude>185 then f=f.Unit*185;spot=Vector3.new(f.X,GROUND,f.Z) end
  task.delay(i*.18,grave,spot,RR.Roll(C.Graves.Pool,rng:NextNumber()))
 end
end

function B.Init()
 M.OnGiantDefeated=function(killer,pos,a)
  local A=B.Active;if not A or A.a~=a then return end
  local n=0;for _ in pairs(a.damagers or {}) do n+=1 end
  noticeAll("bloodMoonWin",{boss=A.boss.Name,name=killer and killer.DisplayName or "?"})
  M.FX("BossDeath",a.id,pos,0,0)
  B.Rain(Vector3.new(pos.X,GROUND,pos.Z),math.clamp(n*C.Graves.PerPlayer,C.Graves.Min,C.Graves.Max))
  B.Finish()
 end
 game.Players.PlayerRemoving:Connect(function(p) B.Taken[p]=nil end)
 task.spawn(function()
  local last=os.clock()
  while task.wait(.1) do
   local now=os.clock();local dt=math.min(now-last,.3);last=now
   local ok,err=pcall(B.Tick,dt);if not ok then warn("Blood Moon tick failed",err) end
   for record in pairs(B.Graves) do if now>=record.expires or not record.model.Parent then B.Graves[record]=nil;if record.model.Parent then record.model:Destroy() end end end
  end
 end)
end
return B
