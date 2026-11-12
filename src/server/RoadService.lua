-- Prototype of the road through the ruins, built from plain blocks: run out, take a grave, carry it back past the Imps.
-- A grave delivered through the gate is planted at home, and the zombie hatches from it as usual.
local Players=game:GetService("Players");local RS=game.ReplicatedStorage;local S=RS.Shared
local C=require(S.Config.RoadConfig);local R=require(S.RoadRules);local Art=require(S.ArtKit);local Pal=require(S.Palette)
local MC=require(S.Config.MutantConfig);local HC=require(S.Config.HouseConfig)
local D=require(script.Parent.DataService);local P=require(script.Parent.PlotService);local G=require(script.Parent.GraveService)
local M=require(script.Parent.MutantService);local Raid=require(script.Parent.RaidService)
local Navigation=require(script.Parent.MutantNavigation)
local Progression=require(S.Config.RoadProgression)
local MonsterRules=require(S.RoadMonsterRules)
local Road={Carriers={},Hearts={},Spots={},Drops={},Holds={},BlockedUntil={},Imps={},Last=os.clock()}
local rng=Random.new();local base;local world;local lastOccupied=-math.huge
local RARITY={Wooden=Pal.Common,Stone=Pal.Uncommon,Marble=Pal.Rare,Golden=Pal.Legendary,Lunar=Pal.Epic}
local EARTH,STONE,DUSK=Color3.fromHex("A98463"),Color3.fromHex("8E86A8"),Color3.fromHex("6A5A94")
local function notice(p,key,args) RS.Remotes.Notice:FireClient(p,key,args) end
local function at(s,x,y) return base*CFrame.new(x,y or 0,-s) end
local function toRoad(pos) local v=base:PointToObjectSpace(pos);return -v.Z,v.X,pos.Y end
Road.At=function(s,x,y) return at(s,x,y) end;Road.ToRoad=function(pos) return toRoad(pos) end
function Road.IsOnRoad(p)
 local ch=p.Character;local root=ch and ch:FindFirstChild("HumanoidRootPart");local h=ch and ch:FindFirstChildOfClass("Humanoid")
 if not root or not h or h.Health<=0 or P.InHouse(p) then return false end
 local s,x,y=toRoad(root.Position)
 return s>C.GateLine and s<C.Length and math.abs(x)<C.Width/2-1 and y>=P.PlazaTop-1 and y<P.PlazaTop+10
end
function Road.Blocked(p) return require(script.Parent.ActionService).Blocked(p) or os.clock()<(Road.BlockedUntil[p] or 0) end
function Road.CancelPickup(p) Road.Holds[p]=nil;Raid.Cancel(p);require(script.Parent.ActionService).CancelDig(p) end
function Road.Stun(p,duration) return require(script.Parent.ActionService).Knockout(p,duration,Vector3.new(0,0,1),0) end
-- Night in the ruins: richer graves, nastier mutants (RoadConfig.Night).
function Road.Night() return (require(script.Parent.DayNightService).State()) end
-- Graves in the head doctor's biome stay locked while he stands.
function Road.BossAlive()
 for _,cfg in ipairs(C.Imps) do if cfg.Kind==C.Boss.Kind and cfg.Live and M.Live[cfg.Live.id] then return true end end
 return false
end
function Road.BossLocked(spot) return spot and not spot.Dropped and (spot.S or 0)>=C.Boss.From and Road.BossAlive() end
function Road.BeginPickup(p,spot)
 if Road.BossLocked(spot) then RS.Remotes.Notice:FireClient(p,"roadBossFirst");return false end
 local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
 if not require(script.Parent.ActionService).CanAct(p) or not D.Profiles[p] or not root or not spot.Model or (not spot.WorldPosition and not Road.IsOnRoad(p)) or P.InHouse(p) or Road.Blocked(p) or Road.Carriers[p] or Raid.Carriers[p] then return false end
 if (root.Position-Road.SpotPosition(spot,2)).Magnitude>11 then return false end
 Road.Holds[p]={spot=spot,began=os.clock()};require(script.Parent.ActionService).Dig(p,C.Hold);return true
end
function Road.EndPickup(p,spot)
 local hold=Road.Holds[p];if hold and hold.spot==spot then hold.ended=os.clock() end
end
function Road.CompletePickup(p,spot)
 local hold=Road.Holds[p];Road.Holds[p]=nil;require(script.Parent.ActionService).CancelDig(p)
 if not hold or hold.spot~=spot or (hold.ended or os.clock())-hold.began<C.Hold-.15 or (hold.ended and os.clock()-hold.ended>.2) then return false end
 return Road.Take(p,spot)
end
-- The road ---------------------------------------------------------------------------------------------------------------
local function block(name,size,cf,color)
 local part=P.Part(world,name,size,cf,color);part.Material=Enum.Material.SmoothPlastic;part.TopSurface=Enum.SurfaceType.Smooth;return part
end
local function decal(name,size,cf,color,transparency)
 local part=block(name,size,cf,color);part.Transparency=transparency or 0;part.CanCollide,part.CanTouch,part.CanQuery,part.CastShadow=false,false,false,false;return part
end
local function buildRoad()
 world=Instance.new('Model');world.Name='Road';world.Parent=P.World
 local WA=require(S.WorldArt);local districts=require(S.Config.WorldConfig).Districts
 local w,len=C.Width,C.Length
 -- Keep physical floors queryable for mutant navigation and server line-of-sight.
 for i,d in districts do
  local model=Instance.new('Model');model.Name='District'..i;model:SetAttribute('District',i);model.Parent=world
  local function floor(a,b,y)
   local p=block('RoadFloor',Vector3.new(w,1,b-a+.1),at((a+b)/2,0,(y or 0)-.5),Color3.fromHex(d.Floor));p.Parent=model
   if i==1 then local texture=Instance.new("Texture");texture.Texture="rbxassetid://132213762657371";texture.Face=Enum.NormalId.Top;texture.StudsPerTileU=20;texture.StudsPerTileV=20;texture.Transparency=.5;texture.Parent=p end
  end
  if d.From<C.Gap.From and d.To>C.Gap.To then
   floor(d.From,C.Gap.From);floor(C.Gap.To,d.To)
   -- A shallow pit catches jumps; no opening to the void under the obstacle.
   floor(C.Gap.From,C.Gap.To,-3)
  else floor(d.From,d.To) end
  -- Gameplay walls only: RoadArt dresses them as ruined facades.
  for _,side in {-1,1} do
   local body=block('RoadWall',Vector3.new(4,44,d.To-d.From+.2),at((d.From+d.To)/2,side*(w/2+2),20),Color3.fromHex(type(d.Wall)=='table' and d.Wall[1] or d.Wall));body.Parent=model;body.Transparency=1;body.CastShadow=false
  end
  task.wait()
 end
 -- Visible rocks/logs match the solid obstruction; both players and enemies route around it.
 for i,q in C.Walls do
  local solid=P.Solid(world,'RoadRubble',Vector3.new(q.W,3,q.D),at(q.S,q.X,1.5));solid.CanQuery=true
  local asset=i<=3 and 'MR_Log' or 'MR_Rocks'
  Art.Spawn(asset,world,at(q.S,q.X,0),{scale=Vector3.new(q.W/(i<=3 and 9 or 5.2),1.5,q.D/(i<=3 and 2 or 3.3))})
 end
 for _,q in C.Slime do decal('RoadSlime',Vector3.new(q.Width,.12,q.To-q.From),at((q.From+q.To)/2,q.X,.07),Pal.Slime,.12) end
 for _,q in C.Bushes do Art.Spawn('V3_Bush',world,at(q.S,q.X,0),{scale=1.7}) end
 decal('GuideRoad',Vector3.one,at(12,0,2),Pal.Panel,1)
 require(script.Parent.RoadArt).Build(world,at,C,districts,P)
 local gate=at(3,0,0)*CFrame.Angles(0,math.pi,0)
 -- The arch was modelled for a 96-wide road: stretch it across the wider biomes.
 Art.Spawn('V3_RoadArch',world,gate,{scale=Vector3.new(w/96,1.25,1)})
 P.SignText(world,gate*CFrame.new(0,25,-2.45),Vector3.new(44,3.6,.1),'signRoad',Pal.Text)
end
-- Graves lying out on the road ---------------------------------------------------------------------------------------------
local function spotPosition(spot,y) return spot.WorldPosition and spot.WorldPosition+Vector3.new(0,y or 0,0) or at(spot.S,spot.X,y).Position end
Road.SpotPosition=spotPosition
local function spawnGrave(spot)
 local kind=spot.Kind
 if not kind then
  -- Lunar graves only come out at night
  local pool=spot.Pool
  if not Road.Night() then local day={};for k,w in pool do if not C.NightOnly[k] then day[k]=w end end;if next(day) then pool=day end end
  kind=R.Roll(pool,rng:NextNumber())
  if Road.Night() then
   local order=require(S.Config.GraveConfig).Order
   for _=2,C.Night.GraveRolls do local other=R.Roll(pool,rng:NextNumber());if table.find(order,other)>table.find(order,kind) then kind=other end end
  end
 end
 local m=Instance.new("Model");m.Name=spot.Dropped and "DroppedGrave" or "RoadGrave"
 m:SetAttribute("MonsterType",spot.MonsterType);m:SetAttribute("Dropped",spot.Dropped==true);m:SetAttribute("DropBornAt",workspace:GetServerTimeNow());m:SetAttribute("DropExpiresAt",spot.Dropped and workspace:GetServerTimeNow()+(spot.Lifetime or C.DropLifetime) or nil)
 local cf=CFrame.new(spotPosition(spot,.25))
 Art.Spawn("G_Mound",m,cf);Art.Spawn("G_"..kind,m,cf)
 local ring=decal("RoadGlow",Vector3.new(.14,9,9),cf*CFrame.new(0,-.1,0)*CFrame.Angles(0,0,math.pi/2),RARITY[kind],.25);ring.Shape=Enum.PartType.Cylinder;ring.Material=Enum.Material.Neon;ring.Parent=m
 local spotPart=decal("RoadGrabSpot",Vector3.new(4,4,4),cf*CFrame.new(0,2,0),Pal.Panel,1);spotPart.Parent=m
 local pr=Instance.new("ProximityPrompt");pr.Name="RoadGrab";pr.ActionText="roadGrab";pr.HoldDuration=C.Hold;pr.MaxActivationDistance=10;pr.RequiresLineOfSight=false;pr:SetAttribute("Grave",kind);pr.Parent=spotPart
 pr.PromptButtonHoldBegan:Connect(function(p) Road.BeginPickup(p,spot) end)
 pr.PromptButtonHoldEnded:Connect(function(p) Road.EndPickup(p,spot) end)
 pr.Triggered:Connect(function(p) Road.CompletePickup(p,spot) end)
 if not spot.Dropped and (spot.S or 0)>=C.Boss.From then
  -- A padlock sign over the boss's graves; the road tick shows it while he stands.
  local b=Instance.new("BillboardGui");b.Name="BossLock";b.Size=UDim2.fromScale(9,2.2);b.StudsOffsetWorldSpace=Vector3.new(0,5.5,0);b.LightInfluence=0;b.MaxDistance=120;b.Parent=spotPart
  local l=Instance.new("TextLabel");l.Size=UDim2.fromScale(1,1);l.BackgroundColor3=Color3.fromHex("FF5468");l.TextColor3=Color3.new(1,1,1);l.TextScaled=true;l.Font=Enum.Font.GothamBlack;l.Text="";l:SetAttribute("LocKey","roadBossLock");l.Parent=b
  Instance.new("UICorner",l).CornerRadius=UDim.new(0,10);local st=Instance.new("UIStroke",l);st.Color=Color3.fromHex("3A2366");st.Thickness=3;st.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
 end
 if spot.MonsterType then
  local b=Instance.new("BillboardGui");b.Name="BossReward";b.Size=UDim2.fromOffset(200,38);b.StudsOffset=Vector3.new(0,4,0);b.MaxDistance=100;b.Parent=spotPart
  local label=Instance.new("TextLabel");label.BackgroundTransparency=1;label.Size=UDim2.fromScale(1,1);label.TextColor3=Pal.Accent;label.Font=Enum.Font.GothamBlack;label.TextScaled=true;label.Text="";label:SetAttribute("LocKey","chiefGrave");label.Parent=b
 end
 m.Parent=world;spot.Model=m;spot.Kind=kind;spot.Prompt=pr
 if not spot.Dropped and C.Announce[kind] then RS.Remotes.Notice:FireAllClients("roadRare",{grave=kind}) end
end
local function attach(p,kind)
 local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart");if not root then return nil end
 local m=Instance.new("Model");m.Name="CarriedGrave";m:SetAttribute("GraveType",kind)
 local parts=Art.Spawn("G_"..kind,m,root.CFrame*CFrame.new(0,-1.1,1.15),{scale=.7})
 local main=next(parts) and select(2,next(parts));if not main then m:Destroy();return end;m.PrimaryPart=main
 for _,part in pairs(parts) do part.Anchored=false;part.CanCollide=false;part.CanQuery=false;part.CanTouch=false;part.Massless=true;if part~=main then local w=Instance.new('WeldConstraint',part);w.Part0=main;w.Part1=part end end
 local grip=Instance.new('Motor6D');grip.Name='CarrierGrip';grip.Part0=root;grip.Part1=main;grip.C0=root.CFrame:ToObjectSpace(main.CFrame);grip.Parent=root
 m.Destroying:Connect(function() grip:Destroy() end)
 for _,x in {-1,1} do local strap=Instance.new('Part');strap.Name='CarryStrap';strap.Size=Vector3.new(.14,2.8,.14);strap.Color=Color3.fromRGB(116,78,49);strap.CanCollide=false;strap.CanQuery=false;strap.CanTouch=false;strap.Massless=true;strap.CFrame=root.CFrame*CFrame.new(x*.65,0,1.8)*CFrame.Angles(0,0,x*.35);strap.Parent=m;local w=Instance.new('WeldConstraint',strap);w.Part0=main;w.Part1=strap end
 local glow=Instance.new('Highlight',m);glow.FillColor=RARITY[kind];glow.FillTransparency=.7;glow.OutlineColor=RARITY[kind];glow.OutlineTransparency=.3;glow.DepthMode=Enum.HighlightDepthMode.Occluded
 if C.Announce[kind] then local e=Instance.new('ParticleEmitter',main);e.Color=ColorSequence.new(RARITY[kind]);e.Rate=5;e.Lifetime=NumberRange.new(.5,1);e.Speed=NumberRange.new(.3,1);e.Size=NumberSequence.new(.2) end
 m.Parent=p.Character;return m
end
function Road.Take(p,spot)
 if Road.BossLocked(spot) then return false end
 local d=D.Profiles[p];local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
 if not require(script.Parent.ActionService).CanAct(p) or not d or not root or not spot.Model or not spot.Model.Parent or (not spot.WorldPosition and not Road.IsOnRoad(p)) or P.InHouse(p) or Road.Blocked(p) or Road.Carriers[p] or Raid.Carriers[p] then return false end
 if (root.Position-Road.SpotPosition(spot,2)).Magnitude>11 then return false end
 local farm=spot.Farm;local kind=spot.Kind;spot.Model:Destroy();spot.Model=nil;spot.Kind=nil;spot.NextAt=os.clock()+C.Respawn
 Road.Drops[spot]=nil;Road.CancelPickup(p)
 if farm then return Raid.Adopt(p,farm) end
 Road.Carriers[p]={grave=kind,monsterType=spot.MonsterType,taken=os.clock(),from=spot.S,model=attach(p,kind)}
 if not d.tutorialDone and d.tutorialStep==2 then d.tutorialStep=3 end
 p:SetAttribute("CarryingGrave",true);return true
end
local function release(p)
 local c=Road.Carriers[p];if not c then return nil end
 local d=D.Profiles[p];if d and not d.tutorialDone and d.tutorialStep==3 and not c.farm then d.tutorialStep=2 end
 Road.Carriers[p]=nil;if c.model then c.model:Destroy() end;p:SetAttribute("CarryingGrave",false);return c
end
Road.Release=release
function Road.Carry(p,kind,farm)
 Road.Carriers[p]={grave=kind,taken=os.clock(),from=0,model=attach(p,kind),monsterType=farm and farm.g.monsterType,farm=farm};p:SetAttribute("CarryingGrave",true)
end
-- Drops are independent of natural spawn timers and can be claimed only once.
function Road.Drop(p,death)
 local c=Road.Carriers[p];local d=D.Profiles[p]
 if not c or not d then return false end
 local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
 local onRoad=root and Road.IsOnRoad(p);local farmPlot
 if root and not onRoad then for _,plot in P.Assigned do if P.Inside(p,plot) then farmPlot=plot;break end end end
 if not root or not onRoad and not farmPlot and not death then if c.farm then Raid.Return(p) else release(p) end;return false end
 local s,x=toRoad(root.Position)
 if not death and onRoad and not c.farm and not R.HonestTrip(math.abs(c.from-s),R.Speed(d),c.grave,os.clock()-c.taken) then release(p);return false end
 if s>C.Gap.From-3 and s<C.Gap.To+3 then s=C.Gap.From-4 end
 s=math.clamp(s,C.GateLine+5,C.Length-5);x=math.clamp(x,-C.Width/2+5,C.Width/2-5)
 release(p)
 local spot={S=s,X=x,Kind=c.grave,MonsterType=c.monsterType,Dropped=true,Expires=os.clock()+C.DropLifetime,WorldPosition=not onRoad and Vector3.new(root.Position.X,farmPlot and farmPlot.Base.Position.Y+.5 or .5,root.Position.Z) or nil}
 if c.farm then Raid.Detach(p,spot) end
 local count,oldest=0,nil
 for q in pairs(Road.Drops) do count+=1;if not oldest or q.Expires<oldest.Expires then oldest=q end end
 if count>=C.MaxDrops and oldest then if oldest.Farm then Raid.ReturnRecord(oldest.Farm) end; if oldest.Model then oldest.Model:Destroy();oldest.Model=nil end;Road.Drops[oldest]=nil end
 spawnGrave(spot);Road.Drops[spot]=true;if p.Parent==Players then notice(p,"roadDropped") end;return spot
end
function Road.SpawnBossGrave(pos)
 local s,x=toRoad(pos)
 local spot={S=math.clamp(s,C.Boss.From+10,C.Length-10),X=math.clamp(x,-C.Width/2+10,C.Width/2-10),Kind="Golden",MonsterType="DeerChief",Dropped=true,Lifetime=C.Boss.GraveLifetime,Expires=os.clock()+C.Boss.GraveLifetime}
 spawnGrave(spot);Road.Drops[spot]=true;return spot
end
function Road.Deliver(p)
 local d=D.Profiles[p];local c=Road.Carriers[p];if not d or not c or c.farm then return false end
 local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart");if not root then return false end
 local along,x,y=toRoad(root.Position);if along>C.GateLine or math.abs(x)>C.Width/2+2 or y<=C.DropBelow then return false end
 local honest=R.HonestTrip(c.from-C.GateLine,R.Speed(d),c.grave,os.clock()-c.taken)
 release(p)
 if not honest then warn("Road: impossible delivery by",p.UserId);return false end
 local item=G.New(c.grave);item.monsterType=c.monsterType;item.fromRoad=true;if not d.tutorialDone and d.tutorialStep==2 then d.tutorialStep=3 end;G.Store(p,item);require(script.Parent.QuestService).Track(p,"road",1);notice(p,"roadStored",{grave=c.grave});return true
end
function Road.Faint(p,key)
 local lost=Road.Carriers[p];if lost then Road.Drop(p,true) end;Road.Hearts[p]=C.Hearts;p:SetAttribute("RoadHearts",C.Hearts)
 local ch=p.Character;if ch then ch:PivotTo(at(-6,0,5)*CFrame.Angles(0,math.pi,0)) end
 notice(p,lost and "roadLost" or key or "roadFaint")
end
function Road.Bite(p,damage)
 require(script.Parent.ActionService).Slow(p)
 local left=(Road.Hearts[p] or C.Hearts)-((damage or 1)*(Road.Night() and C.Night.Damage or 1));Road.Hearts[p]=left;p:SetAttribute("RoadHearts",left)
 if left<=0 then Road.Faint(p) end
end
-- Imps of the road ---------------------------------------------------------------------------------------------------------
local function moveImp(a,goal,dt)
 Navigation.Move(a,goal,a.speed*(Road.Night() and C.Night.Speed or 1),dt)
end
local function tickImps(dt,now,runners)
 local occupied=#runners>0
 if occupied then lastOccupied=now end
 local live=0;for _,a in M.Live do if a.road then live+=1 end end
 local spawned=0
 for _,cfg in ipairs(C.Imps) do
  local a=cfg.Live
  if a and not M.Live[a.id] then a=nil;cfg.Live=nil;cfg.NextAt=now+(cfg.Kind==C.Boss.Kind and C.Boss.Respawn or rng:NextNumber(C.Population.RespawnMin,C.Population.RespawnMax)) end
  if not a then
   if occupied and now>=(cfg.NextAt or 0) and spawned<C.Population.SpawnBudget and live<C.Population.MaxLive and (cfg.Kind==C.Boss.Kind or MonsterRules.Near(cfg.S,runners,toRoad,C.Population.ActiveDistance)) then
    local variant=cfg.RandomVariant and MonsterRules.Roll(rng,cfg.LastVariant) or nil
    if variant then cfg.LastVariant=variant.Id end
    local s=cfg.RandomVariant and math.clamp(cfg.S+rng:NextNumber(-C.Population.SpawnJitter,C.Population.SpawnJitter),cfg.MinS,cfg.MaxS) or cfg.S
    local x=cfg.RandomVariant and rng:NextNumber(-C.Width*.34,C.Width*.34) or cfg.X
    local floorAt=at(s,x,0).Position
    local tooClose=false;for _,r in runners do local delta=Vector3.new(r.pos.X-floorAt.X,0,r.pos.Z-floorAt.Z);if delta.Magnitude<20 then tooClose=true;break end end
    if tooClose then cfg.NextAt=now+1;continue end
    local clear=Navigation.ClearSpawn(floorAt,7*C.BiomeScale[Progression.Index(cfg.S)])
    if not clear then cfg.NextAt=now+1;continue end
    cfg.Live=M.SpawnRoad(variant and variant.Kind or cfg.Kind or "Imp",at(s,x,MC.RootHeight),cfg.Speed,variant)
    spawned+=1;live+=1
    -- deeper biomes, bigger mutants; the feet stay on the floor
    local biome=Progression.Index(cfg.S);local k=C.BiomeScale[biome]
    if cfg.Live and k~=1 then local m=cfg.Live.model;m:ScaleTo(k);m:PivotTo(m:GetPivot()+Vector3.new(0,(k-1)*MC.RootHeight,0));m:SetAttribute("BiomeScale",k) end
    if cfg.Live then local enemy=cfg.Live;enemy.speed=Progression.EnemySpeed(biome,R);enemy.damage=C.BiomeDamage[biome];enemy.hp=math.floor(enemy.hp*C.BiomeHealth[biome]);enemy.model:SetAttribute('Health',enemy.hp);enemy.model:SetAttribute('MaxHealth',enemy.hp);enemy.model:SetAttribute('Biome',biome);enemy.biome=biome end
    if cfg.Live and Road.Night() then
     local a2=cfg.Live;a2.night=true;a2.hp=math.floor(a2.hp*C.Night.Health);a2.model:SetAttribute("Health",a2.hp);a2.model:SetAttribute("MaxHealth",a2.hp);a2.model:SetAttribute("Enraged",true)
     local glow=Instance.new("Highlight");glow.Name="NightRage";glow.FillTransparency=1;glow.OutlineColor=Color3.fromRGB(255,60,90);glow.OutlineTransparency=.15;glow.DepthMode=Enum.HighlightDepthMode.Occluded;glow.Parent=a2.model
    end
   end
  elseif now-lastOccupied>C.ImpsIdleAfter or (cfg.RandomVariant and not MonsterRules.Near(cfg.S,runners,toRoad,C.Population.ActiveDistance+120)) then M.Remove(a);cfg.Live=nil;cfg.NextAt=0
  elseif now<(a.stunnedUntil or 0) then
   -- Shovel stun also cancels prepared attacks.
  elseif a.state=="Spawning" then if now-a.since>=MC.SpawnSeconds then M.State(a,"Running",now) end
  else
   local root=a.model.PrimaryPart.Position;local best,bestDist
   for _,r in ipairs(runners) do
    local dist=(Vector3.new(r.pos.X,root.Y,r.pos.Z)-root).Magnitude
    if dist<=(r.carrying and C.AggroCarrier or C.Aggro) and (not bestDist or dist<bestDist or (r.carrying and not best.carrying)) then best,bestDist=r,dist end
   end
   if best and a.noticeTarget~=best.p then a.noticeTarget=best.p;a.model:SetAttribute('NoticedAt',workspace:GetServerTimeNow()) elseif not best then a.noticeTarget=nil end
   local spec=MC.Types[a.kind]
   if a.attack then
    if now>=a.attack.ends then
     local hitPos=a.attack.pos
     M.FX(a.kind=="Spitter" and "HunterShot" or "Slam",a.id,root,hitPos,spec.Radius)
     for _,r in ipairs(runners) do if (Vector3.new(r.pos.X,hitPos.Y,r.pos.Z)-hitPos).Magnitude<=spec.Radius and Navigation.Visible(root,r.pos) then Road.Bite(r.p,a.damage) end end
     a.attack=nil;a.nextSpecial=now+spec.Cooldown/(Road.Night() and C.Night.AttackRate or 1);M.State(a,"Recovering",now)
    end
   elseif a.state=="Recovering" and now-a.since<.4 then
    -- Recovery gives runners a clear escape window.
   elseif spec.Range and best and bestDist<=spec.Range and now>=(a.nextSpecial or 0) and Navigation.Visible(root,best.pos) then
    local hitPos=a.kind=="Spitter" and Vector3.new(best.pos.X,root.Y,best.pos.Z) or root
    a.attack={pos=hitPos,ends=now+spec.Windup};M.State(a,"Windup",now)
    a.model:SetAttribute("AttackDuration",spec.Windup)
    local flat=Vector3.new(best.pos.X,root.Y,best.pos.Z);if (flat-root).Magnitude>.1 then a.model.PrimaryPart.CFrame=CFrame.lookAt(root,flat) end
    M.FX("Telegraph",a.id,hitPos,spec.Radius,spec.Windup)
   elseif best and bestDist<=C.BiteRange*a.model:GetScale() and Navigation.Visible(root,best.pos) then
    if a.state~="Biting" then M.State(a,"Biting",now) end
    if now>=(a.nextBite or 0) then a.nextBite=now+C.BiteEvery/(Road.Night() and C.Night.AttackRate or 1);M.FX("Bite",a.id,root,0);Road.Bite(best.p,a.damage) end
   else
    if a.state~="Running" then M.State(a,"Running",now) end
    local s,x
    if best then s,x=toRoad(best.pos) else s,x=cfg.S,cfg.X end
    -- They follow a runner from one location into the next (owner, 2026-11-09); with nobody to chase they walk home.
    s=math.clamp(s,14,C.Length-4);x=math.clamp(x,-C.Width/2+5,C.Width/2-5)
    moveImp(a,at(s,x,MC.RootHeight).Position,dt)
   end
  end
 end
end
-- Every tenth of a second --------------------------------------------------------------------------------------------------
local function inSlime(s,x)
 for _,q in ipairs(C.Slime) do if s>=q.From and s<=q.To and math.abs(x-q.X)<=q.Width/2 then return true end end
 return false
end
local function setSpeed(p,d,h,slimed)
 local c=Road.Carriers[p];local speed=c and R.CarrySpeed(R.WalkSpeed(d),c.grave) or R.WalkSpeed(d)
 if c then local bonus=require(script.Parent.PetService).GetBonuses(p).carryPenaltyReduction
  speed=R.WalkSpeed(d)*math.min(1-require(S.Config.PetConfig).MinCarryPenalty,(C.Carry[c.grave] or 1)+bonus)
 end
 if slimed then speed*=C.SlimeSpeed end
 p:SetAttribute('SlimeSlowed',slimed==true)
 if os.clock()<(require(script.Parent.ActionService).State(p).slow or 0) then speed*=C.HitSlow end
 if Road.Blocked(p) then speed=0 end
 if math.abs(h.WalkSpeed-speed)>.01 then h.WalkSpeed=speed end
end
local function onTreadmill(p,plot,root)
 if not P.Inside(p,plot) then return false end
 local t=C.TreadmillSpot;local v=(plot.Base*CFrame.new(0,t.Y,0)):PointToObjectSpace(root.Position)
 return math.abs(v.X-t.X)<=t.W/2 and math.abs(v.Z-t.Z)<=t.D/2 and v.Y>=3 and v.Y<=6.5 and math.abs(root.AssemblyLinearVelocity.Y)<3
end
function Road.Tick()
 local now=os.clock();local dt=math.min(now-Road.Last,.5);Road.Last=now
 local runners={}
 for p,hold in pairs(Road.Holds) do
  local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
  if not root or not hold.spot.Model or (not hold.spot.WorldPosition and not Road.IsOnRoad(p)) or P.InHouse(p) or Road.Blocked(p) or (hold.ended and now-hold.ended>.2) or now-hold.began>C.Hold+3 or (root.Position-Road.SpotPosition(hold.spot,2)).Magnitude>11 then Road.CancelPickup(p) end
 end
 for spot in pairs(Road.Drops) do
  if not spot.Model or now>=spot.Expires then if spot.Farm then Raid.ReturnRecord(spot.Farm) end;if spot.Model then spot.Model:Destroy();spot.Model=nil end;Road.Drops[spot]=nil end
 end
 for _,p in ipairs(Players:GetPlayers()) do
  local d=D.Profiles[p];local ch=p.Character;local root=ch and ch:FindFirstChild("HumanoidRootPart");local h=ch and ch:FindFirstChildOfClass("Humanoid")
  if d and root and h then
   if h.Health<=0 then p:SetAttribute("Training",false);if Road.Carriers[p] then Road.Drop(p,true);notice(p,"roadDropped") end
   else
    local s,x,y=toRoad(root.Position)
    local over=s>0 and s<C.Length+6 and math.abs(x)<C.Width/2+6
    local on=over and y>C.DropBelow
    if over and y<=C.DropBelow and y>C.DropBelow-60 then Road.Faint(p,"roadFell");on=false end
    if p:GetAttribute("OnRoad")~=on then
     p:SetAttribute("OnRoad",on)
     if on and Road.Night() then notice(p,"roadNight") end
     if not on then Road.Hearts[p]=C.Hearts end
     p:SetAttribute("RoadHearts",Road.Hearts[p] or C.Hearts)
    end
    if Road.Carriers[p] and not Road.Carriers[p].farm and s<=C.GateLine and math.abs(x)<C.Width/2+2 and y>C.DropBelow then Road.Deliver(p) end
    if on then table.insert(runners,{p=p,pos=root.Position,carrying=Road.Carriers[p]~=nil}) end
    local plot=P.Assigned[p]
    if plot then
     local training=not Road.Blocked(p) and not Road.Carriers[p] and onTreadmill(p,plot,root)
     if training then local gain=R.Train(d,dt);if gain>0 then p:SetAttribute('TrainingStepAt',workspace:GetServerTimeNow());p:SetAttribute('TrainingStepGain',gain) end end
     p:SetAttribute('SpeedPoints',d.speedPoints or 0)
     if p:GetAttribute("Training")~=training then p:SetAttribute("Training",training) end
    end
    setSpeed(p,d,h,on and inSlime(s,x))
   end
  end
 end
 for _,spot in ipairs(Road.Spots) do if not spot.Model and now>=(spot.NextAt or 0) then spawnGrave(spot) end end
 local bossUp=Road.BossAlive()
 for _,spot in ipairs(Road.Spots) do
  if spot.Model and spot.Prompt and (spot.S or 0)>=C.Boss.From then
   spot.Prompt.Enabled=not bossUp;spot.Model:SetAttribute("BossLocked",bossUp)
   local lock=spot.Prompt.Parent:FindFirstChild("BossLock");if lock then lock.Enabled=bossUp end
  end
 end
 tickImps(dt,now,runners)
end
function Road.Forget(p)
 Road.Drop(p);release(p);Road.Hearts[p]=nil;Road.Holds[p]=nil;Road.BlockedUntil[p]=nil
end
function Road.Init()
 local dir=C.Dir.Unit;local rim=dir*C.Rim+Vector3.new(0,P.PlazaTop,0)
 base=CFrame.lookAt(rim,rim+dir)
 buildRoad()
 M.OnBossDefeated=function(killer,pos)
  if rng:NextNumber()<C.Boss.GraveChance then Road.SpawnBossGrave(pos);notice(killer,"chiefGraveDropped") end
 end
 for i,q in ipairs(C.Spots) do Road.Spots[i]={S=q.S,X=q.X,Pool=q.Pool} end
 task.spawn(function()
  while task.wait(.1) do
   local ok,err=pcall(Road.Tick)
   if not ok then warn("Road tick failed",err) end
  end
 end)
end
return Road
