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
local Road={Carriers={},Hearts={},Spots={},Drops={},Holds={},BlockedUntil={},Imps={},BossCfg={},Summons={},RevealedUntil={},Last=os.clock()}
local rng=Random.new();local base;local world;local lastOccupied=-math.huge
local RARITY={Wooden=Pal.Common,Stone=Pal.Uncommon,Marble=Pal.Rare,Golden=Pal.Legendary,Lunar=Pal.Epic}
local EARTH,STONE,DUSK=Color3.fromHex("A98463"),Color3.fromHex("8E86A8"),Color3.fromHex("6A5A94")
local function notice(p,key,args) RS.Remotes.Notice:FireClient(p,key,args) end
local function at(s,x,y) return base*CFrame.new(x,y or 0,-s) end
local function toRoad(pos) local v=base:PointToObjectSpace(pos);return -v.Z,v.X,pos.Y end
Road.At=function(s,x,y) return at(s,x,y) end;Road.ToRoad=function(pos) return toRoad(pos) end
-- The road itself, or one of the boss pockets beside it (RoadProgression.PocketAt).
local function inRuins(s,x,margin) return math.abs(x)<C.Width/2+(margin or 0) or Progression.PocketAt(s,x,margin)~=nil end
Road.InRuins=inRuins
function Road.IsOnRoad(p)
 local ch=p.Character;local root=ch and ch:FindFirstChild("HumanoidRootPart");local h=ch and ch:FindFirstChildOfClass("Humanoid")
 if not root or not h or h.Health<=0 or P.InHouse(p) then return false end
 local s,x,y=toRoad(root.Position)
 return s>C.GateLine and s<C.Length and inRuins(s,x,-1) and y>=P.PlazaTop-1 and y<P.PlazaTop+10
end
function Road.Blocked(p) return require(script.Parent.ActionService).Blocked(p) or os.clock()<(Road.BlockedUntil[p] or 0) end
function Road.CancelPickup(p) Road.Holds[p]=nil;Raid.Cancel(p);require(script.Parent.ActionService).CancelDig(p) end
function Road.Stun(p,duration) return require(script.Parent.ActionService).Knockout(p,duration,Vector3.new(0,0,1),0) end
-- Night in the ruins: richer graves, nastier mutants (RoadConfig.Night).
function Road.Night() return (require(script.Parent.DayNightService).State()) end
-- Hiding bushes (owner, 2026-11-12): a runner standing in one is invisible to the monsters, until a shot or a swing
-- gives them away for C.BushReveal seconds. Area blows still land on whoever stands in them.
function Road.InBush(s,x)
 for _,q in ipairs(C.Bushes) do
  local ds,dx=q.S-s,q.X-x
  if math.abs(ds)<=C.BushRadius and ds*ds+dx*dx<=C.BushRadius*C.BushRadius then return true end
 end
 return false
end
function Road.Reveal(p) Road.RevealedUntil[p]=os.clock()+C.BushReveal end
-- Every location's arena keeps its main grave locked until its boss falls; it stays open until the boss comes back
-- (C.Boss.Respawn after the defeat, once somebody is near), and only for those who beat it (cfg.Winners). A boss
-- that merely went home while nobody was around was never beaten, so its grave stays shut.
function Road.BossAlive(i)
 local cfg=Road.BossCfg[i];return cfg~=nil and cfg.Live~=nil and M.Live[cfg.Live.id]~=nil
end
function Road.ArenaOpen(i)
 local cfg=Road.BossCfg[i];return cfg~=nil and cfg.DefeatedAt~=nil and not Road.BossAlive(i)
end
function Road.BossLocked(spot) return spot~=nil and not spot.Dropped and spot.Arena~=nil and not Road.ArenaOpen(spot.Arena) end
local function bossName(cfg) return cfg and cfg.Variant and cfg.Variant.Name or "Chief" end
-- The main grave of a beaten boss is its winners' alone.
local function forWinners(p,spot)
 if not spot or not spot.Main then return true end
 local cfg=Road.BossCfg[spot.Arena];return not (cfg and cfg.Winners) or cfg.Winners[p]==true
end
-- Arena geometry: the round pocket beside the road near the location's end (RoadProgression, since 2026-11-13).
local function arenaCenter(i,y) local d=Progression.Districts[i];return at(d.PocketS,d.PocketX,y or 0).Position end
local function arenaDistance(i,pos)
 local d=Progression.Districts[i];local s,x=toRoad(pos);local ds,dx=s-d.PocketS,x-d.PocketX;return math.sqrt(ds*ds+dx*dx)
end
local function clampToArena(i,s,x,margin)
 local d=Progression.Districts[i];local ds,dx=s-d.PocketS,x-d.PocketX;local r=math.sqrt(ds*ds+dx*dx);local limit=Progression.PocketRadius-(margin or 8)
 if r>limit then ds,dx=ds*limit/r,dx*limit/r end
 return d.PocketS+ds,d.PocketX+dx
end
Road.ArenaDistance=arenaDistance
-- Shoving another player on the road (RoadGearService, owner 2026-11-13): for a while the bully lifts graves slower
-- (the client stretches its prompt by the PickupSlowUntil attribute) and nearby monsters turn on them.
Road.SlowUntil={}
function Road.HoldFor(p,base) return (base or C.Hold)*(os.clock()<(Road.SlowUntil[p] or 0) and C.HitPenalty.Hold or 1) end
function Road.Punish(p)
 Road.SlowUntil[p]=os.clock()+C.HitPenalty.Seconds
 p:SetAttribute("PickupSlowUntil",workspace:GetServerTimeNow()+C.HitPenalty.Seconds)
 RS.Remotes.Notice:FireClient(p,"shovePenalty",{n=C.HitPenalty.Seconds})
 local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart");if not root then return end
 for _,a in pairs(M.Live) do
  if a.road and not a.boss and a.model.PrimaryPart and (a.model.PrimaryPart.Position-root.Position).Magnitude<=C.Provoke.Radius then
   a.provokedBy=p;a.provokedUntil=os.clock()+C.Provoke.Seconds
  end
 end
end
function Road.BeginPickup(p,spot)
 if Road.BossLocked(spot) then RS.Remotes.Notice:FireClient(p,"roadBossFirst");return false end
 if not forWinners(p,spot) then RS.Remotes.Notice:FireClient(p,"bossGraveWinners");return false end
 local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
 if not require(script.Parent.ActionService).CanAct(p) or not D.Profiles[p] or not root or not spot.Model or (not spot.WorldPosition and not Road.IsOnRoad(p)) or P.InHouse(p) or Road.Blocked(p) or Road.Carriers[p] or Raid.Carriers[p] then return false end
 if (root.Position-Road.SpotPosition(spot,2)).Magnitude>11 then return false end
 local need=Road.HoldFor(p)
 Road.Holds[p]={spot=spot,began=os.clock(),need=need};require(script.Parent.ActionService).Dig(p,need);return true
end
function Road.EndPickup(p,spot)
 local hold=Road.Holds[p];if hold and hold.spot==spot then hold.ended=os.clock() end
end
function Road.CompletePickup(p,spot)
 local hold=Road.Holds[p];Road.Holds[p]=nil;require(script.Parent.ActionService).CancelDig(p)
 if not hold or hold.spot~=spot or (hold.ended or os.clock())-hold.began<(hold.need or C.Hold)-.15 or (hold.ended and os.clock()-hold.ended>.2) then return false end
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
  -- The first floor reaches back under the island's round edge, so the corners at the road's start have no holes
  -- (the island lawn and the road share one height since 2026-11-12; the cobbled threshold covers the seam).
  if i==1 then local apron=block('RoadApron',Vector3.new(w,1,14),at(-7,0,-.52),Color3.fromHex(d.Floor));apron.Parent=model end
  floor(d.From,d.To) -- one flat floor (the pit across the road in the village was taken out on 2026-11-13)
  -- Gameplay walls only: RoadArt dresses them as ruined facades. On the boss pocket's side the wall has an opening.
  local wallColor=Color3.fromHex(type(d.Wall)=='table' and d.Wall[1] or d.Wall)
  local function wall(name,size,cf) local body=block(name,size,cf,wallColor);body.Parent=model;body.Transparency=1;body.CastShadow=false;return body end
  local pd=Progression.Districts[i];local half=Progression.DoorWidth/2
  for _,side in {-1,1} do
   if side==pd.PocketSide then
    for _,span in {{d.From,pd.DoorS-half},{pd.DoorS+half,d.To}} do wall('RoadWall',Vector3.new(4,44,span[2]-span[1]+.2),at((span[1]+span[2])/2,side*(w/2+2),20)) end
   else wall('RoadWall',Vector3.new(4,44,d.To-d.From+.2),at((d.From+d.To)/2,side*(w/2+2),20)) end
  end
  -- The boss pocket: a slanted corridor (RoadProgression, 2026-11-14: about 70 degrees to the road) from the opening
  -- in the wall to a round floor ringed by a wall.
  do
   local side,ps,px,R,neck=pd.PocketSide,pd.PocketS,pd.PocketX,Progression.PocketRadius,Progression.PocketNeck
   local floorColor=Color3.fromHex(d.Floor);local width=Progression.PocketGap
   -- a frame on the corridor between two "along" marks, its -Z running along it, and its length
   local function run(a0,a1,across,y)
    local s0,x0=Progression.DoorPoint(i,a0,across);local s1,x1=Progression.DoorPoint(i,a1,across)
    local p0,p1=at(s0,x0,y).Position,at(s1,x1,y).Position
    return CFrame.lookAt((p0+p1)/2,p1),(p1-p0).Magnitude
   end
   local cf,len=run(-8,neck+6,0,-.5) -- the floor overlaps the road's and the round's
   local passage=block('PocketFloor',Vector3.new(width+.2,1,len),cf,floorColor);passage.Parent=model
   local round=block('PocketFloor',Vector3.new(1,(R+4)*2,(R+4)*2),at(ps,px,-.5)*CFrame.Angles(0,0,math.pi/2),floorColor);round.Shape=Enum.PartType.Cylinder;round.Parent=model
   -- the corridor's side walls, each from where it meets the road wall's line to the round
   local c,n=pd.DirS,math.abs(pd.DirX)
   for _,e in {-1,1} do
    local across=e*(width/2+2);local start=(2-across*c)/n
    local wcf,wlen=run(start,neck+4,across,20);wall('PocketWall',Vector3.new(4,44,wlen),wcf)
   end
   -- the ring: wall segments all round, except where the corridor comes in
   local segments=40
   for k=0,segments-1 do
    local a0,a1=k/segments*math.pi*2,(k+1)/segments*math.pi*2;local am=(a0+a1)/2
    local ds,dx=math.sin(am)*(R+2),math.cos(am)*(R+2)
    if not Progression.FacesDoor(i,ds,dx,2) then -- where the corridor comes in
     local len=2*(R+2)*math.sin((a1-a0)/2)+.6
     local cf=at(ps+ds,px+dx,20);local look=at(ps+ds+math.cos(am),px+dx-math.sin(am),20)
     local q=wall('PocketWall',Vector3.new(4,44,len),CFrame.lookAt(cf.Position,look.Position))
    end
   end
  end
  task.wait()
 end
 -- Visible rocks/logs match the solid obstruction; both players and enemies route around it.
 for i,q in C.Walls do
  local solid=P.Solid(world,'RoadRubble',Vector3.new(q.W,3,q.D),at(q.S,q.X,1.5));solid.CanQuery=true
  local asset=q.Log and 'MR_Log' or 'MR_Rocks'
  Art.Spawn(asset,world,at(q.S,q.X,0),{scale=Vector3.new(q.W/(q.Log and 9 or 5.2),1.5,q.D/(q.Log and 2 or 3.3))})
 end
 for _,q in C.Slime do decal('RoadSlime',Vector3.new(q.Width,.12,q.To-q.From),at((q.From+q.To)/2,q.X,.07),Pal.Slime,.12) end
 -- Hiding bushes: a big bush between two smaller ones, tinted for the location. Walk-through, and invisible to the
 -- monsters' navigation; the clump's middle is the hiding spot (C.BushRadius).
 local tint={false,Color3.fromHex("3E7D3A"),Color3.fromHex("6E8F4A"),Color3.fromHex("8FA845"),Color3.fromHex("4F7F86"),Color3.fromHex("6B7A55")}
 local bushes=Instance.new('Model');bushes.Name='HidingBushes';bushes.Parent=world
 for n,q in C.Bushes do
  local clump=Instance.new('Model');clump.Name='HidingBush';clump:SetAttribute('HideRadius',C.BushRadius);clump.Parent=bushes
  for _,b in {{0,0,2.7,n*37},{-4.2,1.8,2,40+n*11},{4,-1.6,2.1,-25-n*13}} do
   local parts=Art.Spawn('V3_Bush',clump,at(q.S+b[2],q.X+b[1],0)*CFrame.Angles(0,math.rad(b[4]),0),{scale=b[3],tints=tint[q.District] and {Main=tint[q.District]} or nil})
   for _,part in parts do if typeof(part)=='Instance' and part:IsA('BasePart') then part.CanCollide=false;part.CanQuery=false;part.CanTouch=false end end
  end
 end
 decal('GuideRoad',Vector3.one,at(12,0,2),Pal.Panel,1)
 require(script.Parent.RoadArt).Build(world,at,C,districts,P)
 require(script.Parent.RoadArt).BuildEntrance(world,at,C,P)
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
 -- the last boss's main grave may promise the Chief (RoadConfig.Boss.Main)
 if spot.Main then spot.MonsterType=spot.Chief and rng:NextNumber()<spot.Chief and "DeerChief" or nil end
 local m=Instance.new("Model");m.Name=spot.Dropped and "DroppedGrave" or "RoadGrave"
 m:SetAttribute("MonsterType",spot.MonsterType);m:SetAttribute("Dropped",spot.Dropped==true);m:SetAttribute("DropBornAt",workspace:GetServerTimeNow());m:SetAttribute("DropExpiresAt",spot.Dropped and workspace:GetServerTimeNow()+(spot.Lifetime or C.DropLifetime) or nil)
 local cf=CFrame.new(spotPosition(spot,.25))
 Art.Spawn("Grave_V3_"..kind,m,cf) -- the cartoon V3 grave (2026-11-14)
 local ring=decal("RoadGlow",Vector3.new(.14,9,9),cf*CFrame.new(0,-.1,0)*CFrame.Angles(0,0,math.pi/2),RARITY[kind],.25);ring.Shape=Enum.PartType.Cylinder;ring.Material=Enum.Material.Neon;ring.Parent=m
 local spotPart=decal("RoadGrabSpot",Vector3.new(4,4,4),cf*CFrame.new(0,2,0),Pal.Panel,1);spotPart.Parent=m
 local pr=Instance.new("ProximityPrompt");pr.Name="RoadGrab";pr.ActionText="roadGrab";pr.HoldDuration=C.Hold;pr.MaxActivationDistance=10;pr.RequiresLineOfSight=false;pr:SetAttribute("Grave",kind);pr.Parent=spotPart
 pr.PromptButtonHoldBegan:Connect(function(p) Road.BeginPickup(p,spot) end)
 pr.PromptButtonHoldEnded:Connect(function(p) Road.EndPickup(p,spot) end)
 pr.Triggered:Connect(function(p) Road.CompletePickup(p,spot) end)
 if not spot.Dropped and spot.Arena then
  -- A padlock sign over the arena's graves; the road tick shows it until the boss falls.
  local b=Instance.new("BillboardGui");b.Name="BossLock";b.Size=UDim2.fromScale(9,2.2);b.StudsOffsetWorldSpace=Vector3.new(0,5.5,0);b.LightInfluence=0;b.MaxDistance=120;b.Parent=spotPart
  local l=Instance.new("TextLabel");l.Size=UDim2.fromScale(1,1);l.BackgroundColor3=Color3.fromHex("FF5468");l.TextColor3=Color3.new(1,1,1);l.TextScaled=true;l.Font=Enum.Font.GothamBlack;l.Text="";l:SetAttribute("LocKey","roadBossLock");l.Parent=b
  Instance.new("UICorner",l).CornerRadius=UDim.new(0,10);local st=Instance.new("UIStroke",l);st.Color=Color3.fromHex("3A2366");st.Thickness=3;st.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
 end
 if spot.MonsterType or spot.BossDrop or spot.Main then
  local b=Instance.new("BillboardGui");b.Name="BossReward";b.Size=UDim2.fromOffset(200,38);b.StudsOffset=Vector3.new(0,4,0);b.MaxDistance=100;b.Parent=spotPart
  local label=Instance.new("TextLabel");label.BackgroundTransparency=1;label.Size=UDim2.fromScale(1,1);label.TextColor3=Pal.Accent;label.Font=Enum.Font.GothamBlack;label.TextScaled=true;label.Text="";label:SetAttribute("LocKey",spot.MonsterType=="DeerChief" and "chiefGrave" or spot.Main and "bossMainGrave" or "bossGrave");label.Parent=b
 end
 m.Parent=world;spot.Model=m;spot.Kind=kind;spot.Prompt=pr
 if not spot.Dropped and not spot.Guard and not spot.Main and C.Announce[kind] then RS.Remotes.Notice:FireAllClients("roadRare",{grave=kind}) end
end
local function attach(p,kind)
 local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart");if not root then return nil end
 local m=Instance.new("Model");m.Name="CarriedGrave";m:SetAttribute("GraveType",kind)
 local parts=Art.Spawn("Grave_V3_"..kind,m,root.CFrame*CFrame.new(0,-2.4,1.25),{scale=.6})
 local main=parts.Headstone or (next(parts) and select(2,next(parts)));if not main then m:Destroy();return end;m.PrimaryPart=main
 for _,part in pairs(parts) do part.Anchored=false;part.CanCollide=false;part.CanQuery=false;part.CanTouch=false;part.Massless=true;if part~=main then local w=Instance.new('WeldConstraint',part);w.Part0=main;w.Part1=part end end
 local grip=Instance.new('Motor6D');grip.Name='CarrierGrip';grip.Part0=root;grip.Part1=main;grip.C0=root.CFrame:ToObjectSpace(main.CFrame);grip.Parent=root
 m.Destroying:Connect(function() grip:Destroy() end)
 for _,x in {-1,1} do local strap=Instance.new('Part');strap.Name='CarryStrap';strap.Size=Vector3.new(.14,2.8,.14);strap.Color=Color3.fromRGB(116,78,49);strap.CanCollide=false;strap.CanQuery=false;strap.CanTouch=false;strap.Massless=true;strap.CFrame=root.CFrame*CFrame.new(x*.65,0,1.8)*CFrame.Angles(0,0,x*.35);strap.Parent=m;local w=Instance.new('WeldConstraint',strap);w.Part0=main;w.Part1=strap end
 local glow=Instance.new('Highlight',m);glow.FillColor=RARITY[kind];glow.FillTransparency=.7;glow.OutlineColor=RARITY[kind];glow.OutlineTransparency=.3;glow.DepthMode=Enum.HighlightDepthMode.Occluded
 if C.Announce[kind] then local e=Instance.new('ParticleEmitter',main);e.Color=ColorSequence.new(RARITY[kind]);e.Rate=5;e.Lifetime=NumberRange.new(.5,1);e.Speed=NumberRange.new(.3,1);e.Size=NumberSequence.new(.2) end
 m.Parent=p.Character;return m
end
function Road.Take(p,spot)
 if Road.BossLocked(spot) or not forWinners(p,spot) then return false end
 local d=D.Profiles[p];local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
 if not require(script.Parent.ActionService).CanAct(p) or not d or not root or not spot.Model or not spot.Model.Parent or (not spot.WorldPosition and not Road.IsOnRoad(p)) or P.InHouse(p) or Road.Blocked(p) or Road.Carriers[p] or Raid.Carriers[p] then return false end
 if (root.Position-Road.SpotPosition(spot,2)).Magnitude>11 then return false end
 local farm=spot.Farm;local kind=spot.Kind;spot.Model:Destroy();spot.Model=nil;spot.Kind=nil;spot.NextAt=os.clock()+(spot.Respawn or C.Respawn)
 Road.Drops[spot]=nil;Road.CancelPickup(p)
 if farm then return Raid.Adopt(p,farm) end
 -- guard: dug from a sleeping boss's hoard (it wakes and gives chase); main: the beaten boss's own grave
 Road.Carriers[p]={grave=kind,monsterType=spot.MonsterType,taken=os.clock(),from=spot.S,model=attach(p,kind),guard=spot.Guard,spot=spot.Guard and spot or nil,main=spot.Main}
 if not d.tutorialDone and d.tutorialStep==2 then d.tutorialStep=3 end
 p:SetAttribute("CarryingGrave",true)
 if spot.Guard then Road.WakeForThief(spot.Guard,p) end
 return true
end
local function release(p)
 local c=Road.Carriers[p];if not c then return nil end
 local d=D.Profiles[p];if d and not d.tutorialDone and d.tutorialStep==3 and not c.farm then d.tutorialStep=2 end
 Road.Carriers[p]=nil;if c.model then c.model:Destroy() end;p:SetAttribute("CarryingGrave",false);return c
end
Road.Release=release
-- A grave stolen from a boss's hoard that is lost on the way (the thief caught, fainted or dead) goes back to it.
function Road.ReturnStolen(p)
 local c=Road.Carriers[p];if not c or not c.guard then return false end
 release(p);if c.spot then c.spot.NextAt=math.min(c.spot.NextAt or 0,os.clock()+1) end;return true
end
function Road.Carry(p,kind,farm)
 Road.Carriers[p]={grave=kind,taken=os.clock(),from=0,model=attach(p,kind),monsterType=farm and farm.g.monsterType,farm=farm};p:SetAttribute("CarryingGrave",true)
end
-- Drops are independent of natural spawn timers and can be claimed only once.
function Road.Drop(p,death)
 local c=Road.Carriers[p];local d=D.Profiles[p]
 if not c or not d then return false end
 if c.guard then Road.ReturnStolen(p);return false end -- never onto the road: back to its boss
 local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
 local onRoad=root and Road.IsOnRoad(p);local farmPlot
 if root and not onRoad then for _,plot in P.Assigned do if P.Inside(p,plot) then farmPlot=plot;break end end end
 if not root or not onRoad and not farmPlot and not death then if c.farm then Raid.Return(p) else release(p) end;return false end
 local s,x=toRoad(root.Position)
 if not death and onRoad and not c.farm and not R.HonestTrip(math.abs(c.from-s),R.Speed(d),c.grave,os.clock()-c.taken) then release(p);return false end
 s=math.clamp(s,C.GateLine+5,C.Length-5);x=math.clamp(x,-C.Width/2+5,C.Width/2-5)
 release(p)
 local spot={S=s,X=x,Kind=c.grave,MonsterType=c.monsterType,Dropped=true,Expires=os.clock()+C.DropLifetime,WorldPosition=not onRoad and Vector3.new(root.Position.X,farmPlot and farmPlot.Base.Position.Y+.5 or .5,root.Position.Z) or nil}
 if c.farm then Raid.Detach(p,spot) end
 local count,oldest=0,nil
 for q in pairs(Road.Drops) do count+=1;if not oldest or q.Expires<oldest.Expires then oldest=q end end
 if count>=C.MaxDrops and oldest then if oldest.Farm then Raid.ReturnRecord(oldest.Farm) end; if oldest.Model then oldest.Model:Destroy();oldest.Model=nil end;Road.Drops[oldest]=nil end
 spawnGrave(spot);Road.Drops[spot]=true;if p.Parent==Players then notice(p,"roadDropped") end;return spot
end
function Road.Deliver(p)
 local d=D.Profiles[p];local c=Road.Carriers[p];if not d or not c or c.farm then return false end
 local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart");if not root then return false end
 local along,x,y=toRoad(root.Position);if along>C.GateLine or math.abs(x)>C.Width/2+2 or y<=C.DropBelow then return false end
 local honest=R.HonestTrip(c.from-C.GateLine,R.Speed(d),c.grave,os.clock()-c.taken)
 release(p)
 if not honest then warn("Road: impossible delivery by",p.UserId);return false end
 if c.guard then notice(p,"bossEscaped",{boss=bossName(Road.BossCfg[c.guard])}) end -- outran the boss
 local item=G.New(c.grave);item.monsterType=c.monsterType;item.fromRoad=true;if not d.tutorialDone and d.tutorialStep==2 then d.tutorialStep=3 end;G.Store(p,item);require(script.Parent.QuestService).Track(p,"road",1);notice(p,"roadStored",{grave=c.grave});return true
end
function Road.Faint(p,key)
 local lost=Road.Carriers[p];if lost then Road.Drop(p,true) end;Road.Hearts[p]=C.Hearts;p:SetAttribute("RoadHearts",C.Hearts)
 local ch=p.Character;if ch then ch:PivotTo(at(-6,0,5)*CFrame.Angles(0,math.pi,0)) end
 notice(p,lost and "roadLost" or key or "roadFaint")
end
-- Blood Moon (BloodMoonService): the road shuts. A red barrier stands across the entrance; whoever is out on the
-- road is brought back to the island, a grave they carry already stored at home, and nobody gets in until it lifts.
Road.Closed=false
local closedNotice={}
local function evacuate(p)
 local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart");if not root then return end
 local s,x,y=toRoad(root.Position);if s<=C.GateLine-1 or not inRuins(s,x,6) or y<=C.DropBelow then return end
 local c=Road.Carriers[p]
 if c then
  if c.farm then Raid.Return(p) else
   release(p);local item=G.New(c.grave);item.monsterType=c.monsterType;item.fromRoad=true;G.Store(p,item);notice(p,"roadStored",{grave=c.grave})
  end
 end
 Road.CancelPickup(p)
 p.Character:PivotTo(at(-14,math.clamp(x,-40,40),4)*CFrame.Angles(0,math.pi,0))
 if os.clock()-(closedNotice[p] or -10)>4 then closedNotice[p]=os.clock();notice(p,"roadClosed") end
end
-- The way home after a boss win (owner, 2026-11-13): a portal stands in the pocket for a while, for everyone who hit
-- the boss. A grave carried through it is stored at home just as if it had been walked back through the gate.
Road.Portals={}
-- The shortcut has a price (owner, 2026-11-13): a grave carried through the portal comes home one rarity lower
-- (Lunar becomes Golden ... Stone becomes Wooden; a grave promising a particular monster loses that promise).
local function stow(p)
 local c=Road.Carriers[p]
 if c then
  if c.farm then Raid.Return(p) else
   local order=require(S.Config.GraveConfig).Order;local k=table.find(order,c.grave) or 1
   -- the main grave of a beaten boss is the prize of the fight: it comes home whole
   local kind=c.main and c.grave or order[math.max(1,k-1)];local monster=(c.main or k<=1) and c.monsterType or nil
   if kind~=c.grave then notice(p,"portalDowngrade",{from=c.grave,to=kind}) end
   release(p);local item=G.New(kind);item.monsterType=monster;item.fromRoad=true;G.Store(p,item)
   require(script.Parent.QuestService).Track(p,"road",1);notice(p,"roadStored",{grave=kind})
  end
 end
 Road.CancelPickup(p)
end
function Road.ClosePortal(i)
 local q=Road.Portals[i];Road.Portals[i]=nil
 if not q then return end
 q.model:Destroy()
 for p in pairs(q.allowed) do if p.Parent and p:GetAttribute("PortalBoss")==i then p:SetAttribute("PortalBoss",nil) end end
end
function Road.OpenPortal(i,allowed)
 Road.ClosePortal(i)
 local d=Progression.Districts[i];local side=d.PocketSide
 -- at the back of the round, straight across from the corridor, facing the way in
 local back=at(d.PocketS+d.DirS*(Progression.PocketRadius-26),d.PocketX+d.DirX*(Progression.PocketRadius-26),0).Position
 local cf=CFrame.lookAt(back,Vector3.new(arenaCenter(i).X,back.Y,arenaCenter(i).Z)) -- the ring's face looks at the middle
 local m=Instance.new("Model");m.Name="HomePortal";m:SetAttribute("Boss",i)
 local function piece(name,size,at_,color,material,shape)
  local q=P.Part(m,name,size,cf*at_,color,shape);q.Material=material or Enum.Material.Neon;q.CanCollide,q.CanQuery,q.CanTouch,q.CastShadow=false,false,false,false;return q
 end
 -- Softer since 2026-11-13 (owner: "the portal glows too brightly"): a stone ring with a few dim crystals, a
 -- tinted glass (not neon) core, a faint light and a slow drift of motes.
 local glow=Color3.fromHex("5FC9A2")
 for k=0,15 do
  local a=k/16*math.pi*2
  piece("PortalRing",Vector3.new(.9,2.2,.9),CFrame.new(math.cos(a)*5.2,6+math.sin(a)*5.2,0)*CFrame.Angles(0,0,a),k%4==0 and Color3.fromHex("3E8C74") or Color3.fromHex("4A4560"),k%4==0 and Enum.Material.Neon or Enum.Material.Slate)
 end
 local disc=piece("PortalCore",Vector3.new(.2,9.6,9.6),CFrame.new(0,6,0)*CFrame.Angles(0,math.pi/2,0),Color3.fromHex("7B5CD6"),Enum.Material.Glass,Enum.PartType.Cylinder);disc.Transparency=.3
 piece("PortalBase",Vector3.new(8,.6,3),CFrame.new(0,.3,0),Color3.fromHex("3B3150"),Enum.Material.Slate)
 local light=Instance.new("PointLight");light.Color=glow;light.Range=14;light.Brightness=.6;light.Shadows=false;light.Parent=disc
 local swirl=Instance.new("ParticleEmitter");swirl.Name="Swirl";swirl.Color=ColorSequence.new(glow,Color3.fromHex("A98AE0"));swirl.LightEmission=.25
 swirl.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.4),NumberSequenceKeypoint.new(1,1)})
 swirl.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.16),NumberSequenceKeypoint.new(1,0)});swirl.Lifetime=NumberRange.new(.8,1.4);swirl.Rate=10
 swirl.Speed=NumberRange.new(1,3);swirl.SpreadAngle=Vector2.new(180,180);swirl.Parent=disc
 local pr=Instance.new("ProximityPrompt");pr.Name="PortalHome";pr.ActionText="portalHome";pr.HoldDuration=.4;pr.MaxActivationDistance=12;pr.RequiresLineOfSight=false
 pr:SetAttribute("Boss",i);pr.Parent=disc
 pr.Triggered:Connect(function(p)
  local q=Road.Portals[i];if not q or q.model~=m or not q.allowed[p] or not Road.IsOnRoad(p) then return end
  stow(p);P.Home(p);notice(p,"portalUsed")
 end)
 m.Parent=world
 Road.Portals[i]={model=m,allowed=allowed}
 for p in pairs(allowed) do if p.Parent then p:SetAttribute("PortalBoss",i);notice(p,"portalOpen",{n=C.Boss.PortalSeconds}) end end
 task.delay(C.Boss.PortalSeconds,function() local q=Road.Portals[i];if q and q.model==m then Road.ClosePortal(i) end end)
end
function Road.SetClosed(on)
 if Road.Closed==on then return end
 Road.Closed=on;workspace:SetAttribute("RoadClosed",on or nil)
 if Road.Barrier then Road.Barrier:Destroy();Road.Barrier=nil end
 if not on then return end
 local m=Instance.new("Model");m.Name="BloodBarrier"
 local wall=P.Solid(m,"BloodWall",Vector3.new(C.Width+6,44,1.5),at(7,0,22));wall.CanQuery=false
 -- a faint red shimmer: the shutters closing behind it (RoadArt, FarmGateVisuals) are what you see
 wall.Transparency,wall.Color,wall.Material,wall.CastShadow=.72,Color3.fromHex("C0102E"),Enum.Material.ForceField,false
 for _,face in {math.pi,0} do
  local label=P.SignText(m,at(7,0,10)*CFrame.Angles(0,face,0)*CFrame.new(0,0,-1),Vector3.new(60,6,.1),"roadClosedSign",Color3.fromHex("FFE7A3"))
  label.Parent.PixelsPerStud=15;local st=Instance.new("UIStroke");st.Color=Color3.fromHex("4A0010");st.Thickness=3;st.Parent=label
 end
 m.Parent=world;Road.Barrier=m
 for _,p in ipairs(Players:GetPlayers()) do evacuate(p) end
end
function Road.Bite(p,damage)
 -- nobody is hit while lying knocked down, nor while getting up (owner, 2026-11-13)
 if workspace:GetServerTimeNow()<(p:GetAttribute("KnockedOutUntil") or 0)+.8 then return end
 require(script.Parent.ActionService).Slow(p)
 local left=(Road.Hearts[p] or C.Hearts)-((damage or 1)*(Road.Night() and C.Night.Damage or 1));Road.Hearts[p]=left;p:SetAttribute("RoadHearts",left)
 if left<=0 then Road.Faint(p) end
end
-- Monsters of the road -----------------------------------------------------------------------------------------------------
-- Locations v4: each location spawns only its own two kinds (RoadMonsterRules.Districts); its boss lives in the
-- amphitheatre and never leaves it. Attacks are data (MutantConfig.Types[kind].Attacks): a wind-up the client
-- telegraphs, then the blow. Regular monsters still follow a runner from one location into the next.
local function moveImp(a,goal,dt,speed)
 Navigation.Move(a,goal,(speed or a.speed)*(Road.Night() and C.Night.Speed or 1),dt)
end
local function flat(v,y) return Vector3.new(v.X,y,v.Z) end
-- Hearts a blow costs: the attack's own weight times the location's.
local function blow(a,attack) return (attack and attack.Damage or 1)*(a.damage or 1) end
-- One blast: every runner within radius of the centre and in sight of the monster loses hearts (once per hit set).
local function strike(runners,center,radius,from,hearts,hit)
 for _,r in ipairs(runners) do
  if not (hit and hit[r.p]) and (flat(r.pos,center.Y)-center).Magnitude<=radius and Navigation.Visible(from,r.pos) then
   if hit then hit[r.p]=true end
   Road.Bite(r.p,hearts)
  end
 end
end
local function setHealth(a,hp,max)
 a.hp=hp;a.model:SetAttribute("Health",hp)
 if max then a.maxHp=max;a.model:SetAttribute("MaxHealth",max) end
end
-- Spawns the monster a config row stands for, sized and toughened for its location (and the night).
local function spawnAgent(cfg,s,x,biome,variant,kind)
 local spec=MC.Types[kind]
 local a=M.SpawnRoad(kind,at(s,x,MC.RootHeight),cfg.Speed,variant)
 if not a then return nil end
 local m=a.model;local k=C.BiomeScale[biome]*(spec.Scale or 1)
 -- deeper biomes, bigger mutants; the feet stay on the floor
 if k~=1 then m:ScaleTo(k);m:PivotTo(m:GetPivot()+Vector3.new(0,(k-1)*MC.RootHeight,0));m:SetAttribute("BiomeScale",k) end
 a.cfg=cfg;a.biome=biome;a.cooldowns={}
 a.speed=Progression.EnemySpeed(biome,R)*(spec.SpeedFactor or 1);a.damage=C.BiomeDamage[biome]
 local night=Road.Night()
 local hp=math.floor(a.hp*C.BiomeHealth[biome]*(night and C.Night.Health or 1))
 if cfg.Boss then hp=math.floor(hp*C.Boss.HealthMult);a.damage*=C.Boss.DamageMult end -- tougher bosses (2026-11-13)
 setHealth(a,hp,hp);m:SetAttribute("Biome",biome)
 if night then
  a.night=true;m:SetAttribute("Enraged",true)
  local glow=Instance.new("Highlight");glow.Name="NightRage";glow.FillTransparency=1;glow.OutlineColor=Color3.fromRGB(255,60,90);glow.OutlineTransparency=.15;glow.DepthMode=Enum.HighlightDepthMode.Occluded;glow.Parent=m
 end
 if cfg.Boss then
  a.boss=true;a.arena=cfg.Boss;a.rewardMult=spec.RewardMult;a.lastEngaged=os.clock()
  m:SetAttribute("Boss",cfg.Boss);m:SetAttribute("BossName",bossName(cfg));m:SetAttribute("ArenaCenter",arenaCenter(cfg.Boss))
  cfg.DefeatedAt=nil;cfg.Winners=nil -- back on its feet: the main grave locks again
  a.home=m.PrimaryPart.Position;a.baseSpeed=a.speed;a.chaseSpeed=Progression.EnemySpeed(biome,R)*C.Boss.Chase.Speed
  a.canHurt=Road.BossCanHurt;a.onHurt=Road.BossHurt
  Road.Sleep(a) -- it comes back asleep in its bed (sleeping bosses, 2026-11-13)
 end
 return a
end
-- While a boss stands, its arena is its own fight (owner, 2026-11-13: "during a boss fight the next location's monsters
-- must not barge in"): a monster of another location neither chases a runner into it nor crosses it; it waits on its
-- own side. The boss's own location (and what the boss summons) may still go in.
local function foreignArena(a,s,x)
 if a.boss or (a.cfg and a.cfg.Minion) then return nil end
 local i=Progression.PocketAt(s,x,6)
 if i and i~=a.biome and Road.BossAlive(i) then return i end
 return nil
end
-- a goal inside a foreign arena is moved back out onto the road
local function keepOut(a,s,x)
 if not foreignArena(a,s,x) then return s,x end
 return s,math.clamp(x,-C.Width/2+8,C.Width/2-8)
end
-- Whom to chase: the nearest runner in reach (carriers first). A boss only looks around its own arena.
local function pickTarget(a,runners,root)
 local best,bestDist
 -- provoked: it goes for whoever shoved a player or hit it with a shovel (Road.Punish, RoadGearService), if near
 if a.provokedBy and os.clock()<(a.provokedUntil or 0) and not a.boss then
  for _,r in ipairs(runners) do
   if r.p==a.provokedBy and not foreignArena(a,toRoad(r.pos)) then
    local dist=(flat(r.pos,root.Y)-root).Magnitude
    if dist<=C.AggroCarrier*1.5 then return r,dist end
   end
  end
 end
 for _,r in ipairs(runners) do
  local dist=(flat(r.pos,root.Y)-root).Magnitude;local ok
  if not a.boss and foreignArena(a,toRoad(r.pos)) then continue end
  -- In a bush you are out of sight, but only for monsters that have not noticed you yet: one already chasing you
  -- keeps after you into the bush (owner, 2026-11-12). It lets go only when you get out of its reach.
  if r.hidden and a.noticeTarget~=r.p then ok=false
  elseif r.hidden and a.boss then ok=false
  elseif a.boss then local f=Road.Fights[a.arena];ok=f~=nil and f.fighters[r.p]==true -- only its shut arena's fighters
  else ok=dist<=(r.carrying and C.AggroCarrier or C.Aggro) end
  if ok and (not bestDist or dist<bestDist or (r.carrying and not best.carrying)) then best,bestDist=r,dist end
 end
 return best,bestDist
end
local function minions(a)
 local n=0;for _,q in ipairs(Road.Summons) do if q.Owner==a and q.Live and M.Live[q.Live.id] then n+=1 end end;return n
end
-- The first ready attack, in the order the kind lists them, whose range fits.
local function chooseAttack(a,spec,best,bestDist,now,root)
 if not spec.Attacks or not best or now<(a.nextSpecial or 0) then return nil end
 for _,atk in ipairs(spec.Attacks) do
  if now>=(a.cooldowns[atk.Name] or 0) and bestDist<=atk.Range and bestDist>=(atk.MinRange or 0) then
   if atk.Shape=="Summon" then
    if minions(a)<(atk.MaxMinions or 4) then return atk end
   elseif atk.Shape=="Scream" or Navigation.Visible(root,best.pos) then return atk end
  end
 end
 return nil
end
-- Keeps a goal on the floor: on the road, or inside a boss pocket if it is in one.
local function onRoad(s,x)
 if Progression.PocketAt(s,x) then return s,x end
 return math.clamp(s,14,C.Length-4),math.clamp(x,-C.Width/2+5,C.Width/2-5)
end
-- How far inside the arena's edge a boss's centre must stay: big bosses keep their bulk off the walls.
local function leash(a) return math.max(C.Boss.Leash+2,(a.model:GetAttribute("NavigationRadius") or 2)*a.model:GetScale()+3) end
local function startAttack(a,atk,best,root,now)
 local target=flat(best.pos,root.Y);local attack={atk=atk,ends=now+atk.Windup}
 if atk.Shape=="Target" then attack.pos=target
 elseif atk.Shape=="Volley" then
  attack.points={target}
  for _=2,atk.Count or 3 do
   local angle=rng:NextNumber(0,math.pi*2);local r=rng:NextNumber((atk.Spread or 8)*.4,atk.Spread or 8)
   table.insert(attack.points,target+Vector3.new(math.cos(angle)*r,0,math.sin(angle)*r))
  end
 elseif atk.Shape=="Dash" then
  local dir=target-root;dir=dir.Magnitude>.1 and dir.Unit or a.model.PrimaryPart.CFrame.LookVector
  local s,x=toRoad(root+dir*atk.Distance)
  if a.boss then s,x=clampToArena(a.arena,s,x,leash(a)) end
  if not a.boss then s,x=keepOut(a,s,x) end
  s,x=onRoad(s,x);attack.goal=flat(at(s,x,0).Position,root.Y);attack.pos=attack.goal
 else attack.pos=root end -- Self, Scream, Summon
 a.attack=attack;M.State(a,"Windup",now)
 a.model:SetAttribute("AttackDuration",atk.Windup);a.model:SetAttribute("AttackName",atk.Name)
 if (target-root).Magnitude>.1 then a.model.PrimaryPart.CFrame=CFrame.lookAt(root,target) end
 -- Telegraphs: what is coming and where, for exactly the wind-up.
 if attack.points then for _,q in ipairs(attack.points) do M.FX("Telegraph",a.id,q,atk.Radius,atk.Windup) end
 elseif atk.Shape=="Dash" then M.FX("DashLine",a.id,root,attack.goal,atk.Windup,atk.Radius*2*math.max(1,a.model:GetScale()*.6))
 elseif atk.Shape=="Summon" then M.FX("Chant",a.id,root,0,atk.Windup)
 else M.FX("Telegraph",a.id,attack.pos,atk.Radius,atk.Windup) end
 if a.boss then M.FX("BossCue",a.id,root,0,atk.Shape) end
end
local function finishAttack(a,atk,now)
 a.attack=nil;local rate=(Road.Night() and C.Night.AttackRate or 1)*(a.enraged and C.Boss.Enrage.Rate or 1)
 a.cooldowns[atk.Name]=now+atk.Cooldown/rate
 a.nextSpecial=now+(a.boss and 1.2 or atk.Cooldown)/rate
 M.State(a,"Recovering",now)
end
-- A boss calls in monsters of its own location around itself.
local function summon(a,atk)
 local i=a.arena or a.biome or 1;local s0,x0=toRoad(a.model.PrimaryPart.Position)
 for _=1,atk.Count or 2 do
  local angle=rng:NextNumber(0,math.pi*2);local s,x=s0+math.cos(angle)*16,x0+math.sin(angle)*16
  if a.arena then s,x=clampToArena(a.arena,s,x,8) end
  s,x=onRoad(s,x)
  if Navigation.ClearSpawn(at(s,x,0).Position,6*C.BiomeScale[i]) then
   local variant=MonsterRules.Roll(rng,nil,i)
   local cfg={S=s,X=x,Speed=14,Biome=i,Minion=true,Owner=a}
   cfg.Live=spawnAgent(cfg,s,x,i,variant,variant.Kind)
   if cfg.Live then table.insert(Road.Summons,cfg) end
  end
 end
end
local function resolveAttack(a,runners,root,now)
 local attack=a.attack;local atk=attack.atk
 if atk.Shape=="Dash" then
  -- The wind-up is over: the lunge itself runs over the next ticks (dash).
  local seconds=atk.Distance/atk.Speed
  attack.dashing=true;attack.hit={};attack.dashEnds=now+seconds+.1;M.State(a,"Dashing",now)
  a.model:SetAttribute("AttackDuration",seconds);M.FX(atk.Fx or "Leap",a.id,root,attack.goal,seconds)
  return
 elseif atk.Shape=="Summon" then
  M.FX("Summon",a.id,root,atk.Count or 2);summon(a,atk)
 elseif atk.Shape=="Scream" then
  M.FX("Scream",a.id,root,atk.Radius);strike(runners,root,atk.Radius,root,blow(a,atk))
 elseif attack.points then
  local hit={}
  for _,q in ipairs(attack.points) do M.FX(atk.Fx or "Slam",a.id,root,q,atk.Radius);strike(runners,q,atk.Radius,root,blow(a,atk),hit) end
 else
  M.FX(atk.Fx or "Slam",a.id,root,attack.pos,atk.Radius);strike(runners,attack.pos,atk.Radius,root,blow(a,atk))
 end
 finishAttack(a,atk,now)
end
local function dash(a,runners,dt,now)
 local attack=a.attack;local atk=attack.atk;local part=a.model.PrimaryPart;local before=part.Position
 moveImp(a,attack.goal,dt,atk.Speed)
 local root=part.Position
 strike(runners,root,atk.Radius*math.max(1,a.model:GetScale()*.6),root,blow(a,atk),attack.hit)
 if now>=attack.dashEnds or (flat(attack.goal,root.Y)-root).Magnitude<1.5 or (root-before).Magnitude<.05 then finishAttack(a,atk,now) end
end
-- Sleeping bosses (owner, 2026-11-13: "like Steal the Egg") ------------------------------------------------------------
-- A boss sleeps in its bed in the middle of its arena, on a ring of graves (RoadConfig.Boss.Hoard). Dig one up and it
-- wakes with a roar and chases the thief along the road all the way to the ruins gate: if it catches them they die
-- and the grave goes back to its ring; if they get home it gives up. Either way it is soon back in its bed, asleep.
-- Hit it instead (from inside its arena) and the arena shuts behind everyone in it: they fight it until it falls
-- (then its main grave opens for them and a portal takes them home) or they do (then it goes back to sleep, healed).
-- a.mode: "sleep", "wake" (the roar before a chase), "chase", "return" (going back to bed), "fight" (the shut arena:
-- the usual boss fight below).
Road.Fights={}
local function bossAgent(i) local cfg=Road.BossCfg[i];local a=cfg and cfg.Live;return a and M.Live[a.id] and a or nil end
-- Inside the arena proper: in its round or its passage, past the line where the shut barrier stands.
local function insideArena(i,pos)
 local s,x=toRoad(pos);local d=Progression.Districts[i]
 return Progression.PocketAt(s,x)==i and x*d.PocketSide>C.Width/2+4
end
Road.InsideArena=insideArena
local function rootOf(p) return p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") end
local function setChase(a,p) a.chase=p;a.model:SetAttribute("ChaseUserId",p and p.UserId or nil) end
function Road.Sleep(a)
 local i=a.arena;a.mode="sleep";a.attack=nil;setChase(a,nil)
 if a.enraged then a.enraged=nil;a.model:SetAttribute("BossEnraged",nil);local rage=a.model:FindFirstChild("BossRage");if rage then rage:Destroy() end end
 a.speed=a.baseSpeed or a.speed;a.damagers=nil
 setHealth(a,a.maxHp or a.hp);M.State(a,"Sleeping")
 -- in bed, facing the way in
 local d=Progression.Districts[i];local root=a.model.PrimaryPart;local door=at(d.PocketS-d.DirS*10,d.PocketX-d.DirX*10,0).Position
 a.model:PivotTo(CFrame.lookAt(a.home,Vector3.new(door.X,a.home.Y,door.Z)))
 local gui=root:FindFirstChild("SleepZzz")
 if not gui then
  local _,size=a.model:GetBoundingBox()
  gui=Instance.new("BillboardGui");gui.Name="SleepZzz";gui.Size=UDim2.fromScale(4,4);gui.StudsOffsetWorldSpace=Vector3.new(0,size.Y*.55+1,0);gui.LightInfluence=0;gui.MaxDistance=180;gui.Parent=root
  local l=Instance.new("TextLabel");l.Size=UDim2.fromScale(1,1);l.BackgroundTransparency=1;l.TextScaled=true;l.Font=Enum.Font.GothamBlack;l.Text="💤";l.Parent=gui
 end
 gui.Enabled=true;a.model:SetAttribute("Asleep",true)
end
local function awake(a,mode)
 a.mode=mode;a.modeAt=os.clock();a.model:SetAttribute("Asleep",nil)
 local gui=a.model.PrimaryPart:FindFirstChild("SleepZzz");if gui then gui.Enabled=false end
end
-- Who may hurt a boss: a sleeping one only from inside its arena (that starts the fight), a shut arena's boss only
-- its fighters; awake on the road, anyone.
function Road.BossCanHurt(a,p)
 if a.mode=="sleep" then local root=rootOf(p);return root~=nil and insideArena(a.arena,root.Position) end
 if a.mode=="fight" then local f=Road.Fights[a.arena];return f~=nil and f.fighters[p]==true end
 return true
end
function Road.BossHurt(a,p) if a.mode=="sleep" then Road.StartFight(a.arena,p) end end
function Road.WakeForThief(i,p)
 local a=bossAgent(i);if not a or a.mode~="sleep" then return end
 awake(a,"wake");setChase(a,p)
 M.State(a,"Windup");a.model:SetAttribute("AttackName","Scream");a.model:SetAttribute("AttackDuration",C.Boss.Chase.Wake)
 M.FX("BossSpawn",a.id,a.model.PrimaryPart.Position,i,bossName(a.cfg)) -- the roar
 notice(p,"bossWoke",{boss=bossName(a.cfg)})
end
-- The shut arena: a wall of red light across the opening, with a sign both ways.
local function shutArena(i)
 local d=Progression.Districts[i];local side=d.PocketSide
 local m=Instance.new("Model");m.Name="ArenaBarrier";m:SetAttribute("Boss",i)
 local wall=P.Solid(m,"ArenaBarrierWall",Vector3.new(4,44,Progression.DoorWidth+4),at(d.DoorS,side*(C.Width/2+2),20));wall.CanQuery=true
 wall.Transparency,wall.Color,wall.Material,wall.CastShadow=.25,Color3.fromHex("C0102E"),Enum.Material.ForceField,false
 for _,face in {math.pi/2,-math.pi/2} do
  local label=P.SignText(m,at(d.DoorS,side*(C.Width/2+2),9)*CFrame.Angles(0,face,0)*CFrame.new(0,0,-2.2),Vector3.new(Progression.PocketGap,4,.1),"bossFightSign",Color3.fromHex("FFE7A3"))
  label.Parent.PixelsPerStud=18;local st=Instance.new("UIStroke");st.Color=Color3.fromHex("4A0010");st.Thickness=3;st.Parent=label
 end
 m.Parent=world;return m
end
function Road.StartFight(i,starter)
 local a=bossAgent(i);if not a or Road.Fights[i] then return end
 local fighters={}
 for _,q in ipairs(Players:GetPlayers()) do local root=rootOf(q);if root and Road.IsOnRoad(q) and insideArena(i,root.Position) then fighters[q]=true end end
 fighters[starter]=true
 awake(a,"fight");setChase(a,nil);a.lastEngaged=os.clock();M.State(a,"Running")
 M.FX("BossSpawn",a.id,a.model.PrimaryPart.Position,i,bossName(a.cfg))
 Road.Fights[i]={fighters=fighters,barrier=shutArena(i)}
 for q in pairs(fighters) do notice(q,"bossFightLocked",{boss=bossName(a.cfg)}) end
end
function Road.EndFight(i)
 local f=Road.Fights[i];if not f then return end
 Road.Fights[i]=nil;if f.barrier then f.barrier:Destroy() end
end
-- Fighters drop out when they fall (fainting puts them back at the gate) or leave; with none left the boss wins.
local function tickFights()
 for i,f in pairs(Road.Fights) do
  for p in pairs(f.fighters) do
   local root=rootOf(p);local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
   if not p.Parent or not root or not h or h.Health<=0 or not insideArena(i,root.Position) then f.fighters[p]=nil end
  end
  local a=bossAgent(i)
  if not a then Road.EndFight(i)
  elseif not next(f.fighters) then
   Road.EndFight(i);awake(a,"return")
   for _,q in ipairs(Players:GetPlayers()) do local root=rootOf(q);if root and arenaDistance(i,root.Position)<Progression.PocketRadius+60 then notice(q,"bossSleepsAgain",{boss=bossName(a.cfg)}) end end
  end
 end
end
-- A thief of this boss's hoard, still carrying it on the road.
local function thiefOf(i,runners,prefer)
 local found
 for _,r in ipairs(runners) do
  local c=Road.Carriers[r.p]
  if c and c.guard==i then if r.p==prefer then return r end;found=found or r end
 end
 return found
end
-- Where to head for: out through the arena's opening first when the goal is outside it (and back in the same way).
local function routeTo(a,goal)
 local i=a.arena;local d=Progression.Districts[i];local root=a.model.PrimaryPart.Position
 local bs,bx=toRoad(root);local gs,gx=toRoad(goal)
 local inBoss,inGoal=Progression.PocketAt(bs,bx)==i,Progression.PocketAt(gs,gx)==i
 if inBoss~=inGoal then
  -- the two ends of the passage: just inside the round, and out on the road in front of the opening
  local door=at(d.PocketS-d.DirS*(Progression.PocketRadius-14),d.PocketX-d.DirX*(Progression.PocketRadius-14),0).Position
  local mouth=at(Progression.DoorPoint(i,-14,0)).Position
  local _,across=Progression.DoorFrame(i,bs,bx);local lined=math.abs(across)<=Progression.PocketGap/2-4 -- on the corridor's line
  if inBoss then return lined and mouth or door end -- out: line up with the passage, then through it
  return lined and door or mouth -- in: to the opening first, then through
 end
 local s,x=onRoad(gs,gx);return at(s,x,0).Position
end
-- A big boss can wedge itself on a log or a wall: if it hardly moves for a while it bounds ahead.
local function unstick(a,goal,now)
 local root=a.model.PrimaryPart.Position
 if not a.stuckFrom or (root-a.stuckFrom).Magnitude>1 then a.stuckFrom=root;a.stuckAt=now;return end
 if now-a.stuckAt<C.Boss.Chase.Stuck then return end
 local dir=flat(goal,root.Y)-root;if dir.Magnitude<1 then return end
 local s,x=onRoad(toRoad(root+dir.Unit*math.min(C.Boss.Chase.Hop,dir.Magnitude)))
 local to=at(s,x,0).Position;M.FX("Smoke",a.id,root,0)
 a.model:PivotTo(CFrame.lookAt(Vector3.new(to.X,a.home.Y,to.Z),Vector3.new(goal.X,a.home.Y,goal.Z)));a.path=nil
 a.stuckFrom=nil
end
local function catch(a,p)
 local root=a.model.PrimaryPart.Position
 M.State(a,"Recovering");M.FX("Bite",a.id,root,0)
 Road.ReturnStolen(p)
 notice(p,"bossCaught",{boss=bossName(a.cfg)})
 local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid");if h then h.Health=0 end
end
local function bossTick(a,cfg,dt,now,runners)
 local root=a.model.PrimaryPart.Position
 if a.mode=="sleep" then return end
 if a.mode=="wake" then
  if now-a.modeAt>=C.Boss.Chase.Wake then a.mode="chase";a.modeAt=now;M.State(a,"Running",now) end
  return
 end
 if a.mode=="chase" then
  local r=thiefOf(a.arena,runners,a.chase)
  if not r then a.mode="return";a.modeAt=now;setChase(a,nil);return end -- home with it, or lost it
  if r.p~=a.chase then setChase(a,r.p);notice(r.p,"bossWoke",{boss=bossName(cfg)}) end
  local reach=C.Boss.Chase.Catch+(a.model:GetAttribute("NavigationRadius") or 2)*a.model:GetScale()
  if (flat(r.pos,root.Y)-root).Magnitude<=reach then catch(a,r.p);a.mode="return";a.modeAt=now;setChase(a,nil);return end
  local goal=routeTo(a,r.pos)
  if a.state~="Running" then M.State(a,"Running",now) end
  moveImp(a,goal,dt,a.chaseSpeed);unstick(a,goal,now)
  return
 end
 -- return: back to bed; a boss far off along the road sinks away and is back in its bed
 local home=flat(a.home,root.Y)
 if (home-root).Magnitude<3 then Road.Sleep(a);return end
 if now-a.modeAt>=C.Boss.Chase.GiveUp and not insideArena(a.arena,root) then
  M.FX("Smoke",a.id,root,0);a.model:PivotTo(CFrame.new(a.home));a.path=nil;M.FX("Smoke",a.id,a.home,0);Road.Sleep(a);return
 end
 if a.state~="Running" then M.State(a,"Running",now) end
 local goal=routeTo(a,a.home);moveImp(a,goal,dt);unstick(a,goal,now)
end
local function tickAgent(a,cfg,dt,now,runners)
 if now<(a.stunnedUntil or 0) then return end -- the shovel's knockout (bosses are immune: RoadGearService)
 if a.boss and a.mode and a.mode~="fight" then bossTick(a,cfg,dt,now,runners);return end -- asleep, chasing, going home
 if a.state=="Spawning" then if now-a.since>=MC.SpawnSeconds then M.State(a,"Running",now) end;return end
 local root=a.model.PrimaryPart.Position
 -- Enrage (2026-11-13): below half its health a boss turns red, roars, moves faster and attacks more often.
 if a.boss and not a.enraged and a.hp<=(a.maxHp or a.hp)*C.Boss.Enrage.At then
  a.enraged=true;a.speed*=C.Boss.Enrage.Speed;a.model:SetAttribute("BossEnraged",true)
  local glow=Instance.new("Highlight");glow.Name="BossRage";glow.FillColor=Color3.fromRGB(255,40,60);glow.FillTransparency=.75
  glow.OutlineColor=Color3.fromRGB(255,60,90);glow.OutlineTransparency=0;glow.DepthMode=Enum.HighlightDepthMode.Occluded;glow.Parent=a.model
  M.FX("Scream",a.id,root,18)
  for _,r in ipairs(runners) do if arenaDistance(a.arena,r.pos)<=Progression.PocketRadius+6 then notice(r.p,"bossEnraged",{boss=bossName(a.cfg)}) end end
 end
 local best,bestDist=pickTarget(a,runners,root)
 if best and a.noticeTarget~=best.p then a.noticeTarget=best.p;a.model:SetAttribute('NoticedAt',workspace:GetServerTimeNow()) elseif not best then a.noticeTarget=nil end
 if a.boss then
  -- Nobody to fight in the arena: it heals, so a boss can't be whittled down from outside its reach.
  if best then a.lastEngaged=now
  elseif now-(a.lastEngaged or now)>C.Boss.RegenAfter and a.hp<(a.maxHp or a.hp) then setHealth(a,math.min(a.maxHp,a.hp+a.maxHp*C.Boss.RegenRate*dt)) end
 end
 if a.attack then
  if a.attack.dashing then dash(a,runners,dt,now) elseif now>=a.attack.ends then resolveAttack(a,runners,root,now) end
  return
 end
 if a.state=="Recovering" and now-a.since<(a.boss and .7 or .4) then return end -- a clear escape window
 local atk=chooseAttack(a,MC.Types[a.kind],best,bestDist,now,root)
 if atk then startAttack(a,atk,best,root,now);return end
 if best and bestDist<=C.BiteRange*a.model:GetScale() and Navigation.Visible(root,best.pos) then
  if a.state~="Biting" then M.State(a,"Biting",now) end
  if now>=(a.nextBite or 0) then a.nextBite=now+C.BiteEvery/(Road.Night() and C.Night.AttackRate or 1);M.FX("Bite",a.id,root,0);Road.Bite(best.p,a.damage) end
  return
 end
 local s,x
 if best then s,x=toRoad(best.pos) else s,x=cfg.S,cfg.X end
 if a.boss then s,x=clampToArena(a.arena,s,x,leash(a)) end
 if not a.boss then s,x=keepOut(a,s,x) end
 s,x=onRoad(s,x)
 local goal=at(s,x,MC.RootHeight).Position
 if not best and (flat(goal,root.Y)-root).Magnitude<2 then
  if a.state~="Idle" then M.State(a,"Idle",now) end -- home: stand and look around
  return
 end
 if a.state~="Running" then M.State(a,"Running",now) end
 moveImp(a,goal,dt)
end
-- Tells a runner whose arena they just walked into, while its boss stands.
local inArena={}
local function announceArenas(runners)
 local seen={}
 for _,r in ipairs(runners) do
  local s,x=toRoad(r.pos);local i=Progression.PocketAt(s,x,2);seen[r.p]=true
  if i~=inArena[r.p] then
   inArena[r.p]=i
   local a=i and bossAgent(i)
   if a and a.mode=="sleep" then notice(r.p,"bossAsleep",{boss=bossName(Road.BossCfg[i])}) end
  end
 end
 for p in pairs(inArena) do if not seen[p] then inArena[p]=nil end end
end
local function tickImps(dt,now,runners)
 local occupied=#runners>0
 if occupied then lastOccupied=now end
 announceArenas(runners)
 local live=0;for _,a in M.Live do if a.road then live+=1 end end
 local spawned=0
 for _,cfg in ipairs(C.Imps) do
  local a=cfg.Live
  if a and not M.Live[a.id] then a=nil;cfg.Live=nil;cfg.NextAt=now+(cfg.Boss and C.Boss.Respawn or rng:NextNumber(C.Population.RespawnMin,C.Population.RespawnMax)) end
  if not a then
   if occupied and now>=(cfg.NextAt or 0) and spawned<C.Population.SpawnBudget and live<C.Population.MaxLive and MonsterRules.Near(cfg.S,runners,toRoad,C.Population.ActiveDistance) then
    local biome=cfg.Biome or Progression.Index(cfg.S)
    local variant=cfg.Variant or (cfg.RandomVariant and MonsterRules.Roll(rng,cfg.LastVariant,biome)) or nil
    local kind=variant and variant.Kind or cfg.Kind or "Imp"
    local s=cfg.RandomVariant and math.clamp(cfg.S+rng:NextNumber(-C.Population.SpawnJitter,C.Population.SpawnJitter),cfg.MinS,cfg.MaxS) or cfg.S
    local x=cfg.RandomVariant and rng:NextNumber(-C.Width*.34,C.Width*.34) or cfg.X
    local floorAt=at(s,x,0).Position
    local tooClose=false;for _,r in runners do local delta=Vector3.new(r.pos.X-floorAt.X,0,r.pos.Z-floorAt.Z);if delta.Magnitude<20 then tooClose=true;break end end
    if tooClose then cfg.NextAt=now+1;continue end
    if not Navigation.ClearSpawn(floorAt,7*C.BiomeScale[biome]*(MC.Types[kind].Scale or 1)) then cfg.NextAt=now+1;continue end
    if variant and cfg.RandomVariant then cfg.LastVariant=variant.Id end
    cfg.Live=spawnAgent(cfg,s,x,biome,variant,kind)
    if cfg.Live then spawned+=1;live+=1 end
   end
  elseif not (a.mode=="chase" or a.mode=="wake" or a.mode=="fight") and (now-lastOccupied>C.ImpsIdleAfter or not MonsterRules.Near(cfg.S,runners,toRoad,C.Population.ActiveDistance+120)) then
   M.Remove(a);cfg.Live=nil;cfg.NextAt=0 -- nobody around: it goes home, a boss is not beaten by that
  else tickAgent(a,cfg,dt,now,runners) end
 end
 -- Monsters a boss called in fight like the rest and leave when nobody is around.
 for n=#Road.Summons,1,-1 do
  local cfg=Road.Summons[n];local a=cfg.Live
  if not a or not M.Live[a.id] then table.remove(Road.Summons,n)
  elseif now-lastOccupied>C.ImpsIdleAfter or not MonsterRules.Near(cfg.S,runners,toRoad,C.Population.ActiveDistance) then M.Remove(a);table.remove(Road.Summons,n)
  else tickAgent(a,cfg,dt,now,runners) end
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
    if Road.Closed and s>C.GateLine-1 and s<C.Length+6 and inRuins(s,x,6) and y>C.DropBelow then evacuate(p);s,x,y=toRoad(root.Position) end
    local over=s>0 and s<C.Length+6 and inRuins(s,x,6)
    local on=over and y>C.DropBelow
    if over and y<=C.DropBelow and y>C.DropBelow-60 then Road.Faint(p,"roadFell");on=false end
    if p:GetAttribute("OnRoad")~=on then
     p:SetAttribute("OnRoad",on)
     if on and Road.Night() then notice(p,"roadNight") end
     if not on then Road.Hearts[p]=C.Hearts end
     p:SetAttribute("RoadHearts",Road.Hearts[p] or C.Hearts)
    end
    if Road.Carriers[p] and not Road.Carriers[p].farm and s<=C.GateLine and math.abs(x)<C.Width/2+2 and y>C.DropBelow then Road.Deliver(p) end
    local hidden=on and now>=(Road.RevealedUntil[p] or 0) and Road.InBush(s,x)
    if p:GetAttribute("HiddenInBush")~=(hidden==true) then p:SetAttribute("HiddenInBush",hidden==true) end
    -- in a bush the name over your head goes too (owner, 2026-11-13); the income tag is hidden by InterfaceController
    local shown=hidden and Enum.HumanoidDisplayDistanceType.None or Enum.HumanoidDisplayDistanceType.Viewer
    if h.DisplayDistanceType~=shown then h.DisplayDistanceType=shown end
    if on then table.insert(runners,{p=p,pos=root.Position,carrying=Road.Carriers[p]~=nil,hidden=hidden}) end
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
 for _,spot in ipairs(Road.Spots) do
  if spot.Model and spot.Prompt and spot.Arena then
   local locked=not Road.ArenaOpen(spot.Arena)
   spot.Prompt.Enabled=not locked;spot.Model:SetAttribute("BossLocked",locked)
   local lock=spot.Prompt.Parent:FindFirstChild("BossLock");if lock then lock.Enabled=locked end
  end
 end
 tickFights()
 tickImps(dt,now,runners)
end
function Road.Forget(p)
 Road.SlowUntil[p]=nil
 Road.Drop(p);release(p);Road.Hearts[p]=nil;Road.Holds[p]=nil;Road.BlockedUntil[p]=nil;Road.RevealedUntil[p]=nil
end
function Road.Init()
 -- The road lies at the island lawn's height (a stud under the plaza), so the two meet without a step.
 local dir=C.Dir.Unit;local rim=dir*C.Rim+Vector3.new(0,P.PlazaTop-1,0)
 base=CFrame.lookAt(rim,rim+dir)
 buildRoad()
 for _,cfg in ipairs(C.Imps) do if cfg.Boss then Road.BossCfg[cfg.Boss]=cfg end end
 -- A boss falls: its arena opens again, everyone hears of it, and its main grave and a portal home are its winners'
 -- (everyone who fought it in the shut arena or hit it).
 M.OnBossDefeated=function(killer,pos,a)
  local i=a and a.arena;if not i then return end
  local winners={};for p in pairs(a.damagers or {}) do winners[p]=true end;if killer then winners[killer]=true end
  local fight=Road.Fights[i];if fight then for p in pairs(fight.fighters) do winners[p]=true end end
  Road.EndFight(i)
  local cfg=Road.BossCfg[i];if cfg then cfg.DefeatedAt=os.clock();cfg.Winners=winners end
  M.FX("BossDeath",a.id,pos,i,0)
  RS.Remotes.Notice:FireAllClients("bossDefeated",{boss=bossName(cfg),name=killer.DisplayName})
  Road.OpenPortal(i,winners) -- the way home for the winners
 end
 for i,q in ipairs(C.Spots) do Road.Spots[i]={S=q.S,X=q.X,Pool=q.Pool,Arena=q.Arena,Guard=q.Guard,Respawn=q.Respawn,Main=q.Main,Chief=q.Chief} end
 task.spawn(function()
  while task.wait(.1) do
   local ok,err=pcall(Road.Tick)
   if not ok then warn("Road tick failed",err) end
  end
 end)
end
return Road
