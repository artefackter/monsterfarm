if not game:GetService("RunService"):IsStudio() then return end
local Pet=require(script.Parent.PetService);local D=require(script.Parent.DataService);local C=require(game.ReplicatedStorage.Shared.Config.PetConfig)
local function execute(p,command,arg,value)
 local d=D.Profiles[p];if not d then return false end
 if command=="pet" and C.Power[arg] then local tier=tonumber(value) or 1;if tier%1==0 and tier>=1 and tier<=#C.Tiers then Pet.Grant(p,arg,tier) else return false end
 elseif command=="coins" then local n=tonumber(arg);if n and n==n then d.coins+=math.clamp(n,0,C.DebugMaxCoins) else return false end
 elseif command=="ripe" then for _,g in ipairs(d.graves) do g.plantedAt=os.time()-require(game.ReplicatedStorage.Shared.Config.GraveConfig)[g.type].Seconds end
 elseif command=="phase" and (arg=="day" or arg=="night") then workspace:SetAttribute("DebugPhase",arg)
 elseif command=="bloodmoon" then
  -- /bloodmoon: night now, and the giant breaks out at once
  workspace:SetAttribute("DebugPhase","night");return require(script.Parent.BloodMoonService).Start()
 elseif command=="giant" then
  -- /giant n: hit the Blood Moon giant for n as this player
  local A=require(script.Parent.BloodMoonService).Active;local n=tonumber(arg);if not A or not n then return false end
  return require(script.Parent.MutantService).Damage(A.a,n,p)
 elseif command=="house" then
  -- /house n: build the house at level n at once (to look at every level)
  local n=tonumber(arg);local HC=require(game.ReplicatedStorage.Shared.Config.HouseConfig);if not n or not HC.Levels[n] then return false end
  d.houseLevel=n;d.houseEnds=nil;require(script.Parent.HouseService).Refresh(p,d);require(script.Parent.InterfaceService).Refresh(p)
 elseif command=="treadmill" then
  local n=tonumber(arg);local RC=require(game.ReplicatedStorage.Shared.Config.RoadConfig);if not n or not RC.Treadmill[n] then return false end
  d.treadmill=n;require(script.Parent.HouseService).RefreshTreadmill(p,d);require(script.Parent.InterfaceService).Refresh(p)
 elseif command=="raid" then
  -- /raid [n]: send n night raiders at your farm now (needs /farm first)
  local n=math.clamp(tonumber(arg) or 3,1,8);local M=require(script.Parent.MutantService);local ok=false
  for _=1,n do if M.Spawn(p) then ok=true end end
  return ok
 elseif command=="fence" then
  -- /fence n: the fence and gate at level n
  local FC=require(game.ReplicatedStorage.Shared.Config.FenceConfig);local n=tonumber(arg);if not n or not FC.Levels[n] then return false end
  d.fenceLevel=n;require(script.Parent.FenceService).Join(p,d);require(script.Parent.InterfaceService).Refresh(p)
 elseif command=="kills" then
  -- /kills i n: count n monsters killed in location i (guns unlock with them)
  local i,n=tonumber(arg),tonumber(value);if not i or not n or not d.ruinKills or not d.ruinKills[i] then return false end
  d.ruinKills[i]+=n;require(script.Parent.WeaponService).Join(p)
 elseif command=="boss" then
  -- /boss n: finish off the boss of location n as this player (to see the win and the portal home)
  local Road=require(script.Parent.RoadService);local cfg=Road.BossCfg[tonumber(arg) or 0];local a=cfg and cfg.Live
  if not a then return false end
  a.canHurt=nil -- from anywhere, asleep or not
  return require(script.Parent.MutantService).Damage(a,a.hp,p)
 elseif command=="poke" then
  -- /poke n [part]: hit boss n by the usual rules for 1, or for that part of its whole health (/poke 1 0.31 to see a
  -- stagger); false: it can't be hurt now - asleep, or a theft is on. /finish [kind]: the finisher, as the target
  -- does; kind (RoadConfig.Boss.Finisher.Kinds: SawPlunge ... PickSpike) picks which, whatever the weapon.
  -- /melee id: own and hold that melee weapon (ShovelConfig.Order).
  local Road=require(script.Parent.RoadService);local cfg=Road.BossCfg[tonumber(arg) or 0];local a=cfg and cfg.Live
  if not a then return false end
  return require(script.Parent.MutantService).Damage(a,tonumber(value) and (a.maxHp or a.hp)*tonumber(value) or 1,p),a.mode,a.hp
 elseif command=="finish" then return require(script.Parent.RoadService).Finish(p,arg)
 elseif command=="melee" then
  local Melee=require(game.ReplicatedStorage.Shared.Config.ShovelConfig);if not Melee[arg or ""] or not table.find(Melee.Order,arg) then return false end
  d.shovels[arg]=true;d.equippedShovel=arg;require(script.Parent.ActionService).Push(p);return true
 elseif command=="hold" then
  -- /hold n [seconds]: keep boss n, already on its knees, down for that long (to look at a finisher's poses)
  local Road=require(script.Parent.RoadService);local cfg=Road.BossCfg[tonumber(arg) or 0];local a=cfg and cfg.Live
  if not a or not a.staggerUntil then return false end
  local seconds=tonumber(value) or 120;a.staggerUntil=os.clock()+seconds;a.model:SetAttribute("StaggeredUntil",workspace:GetServerTimeNow()+seconds)
 elseif command=="graves" then
  -- /graves Wooden,Stone,Marble,Golden,Lunar: plant those graves in the first grave spots (to look at the art); the
  -- grave slot is taken the way the hotbar does (planting needs it)
  local G=require(script.Parent.GraveService);d.tutorialDone=true
  for i,kind in string.split(arg or "",",") do
   local k,family=string.match(kind,"^(%a+):?(%a*)$") -- Stone:Deer plants a deer's grave (GraveService.Family)
   -- planted straight into the first free spot of the cemetery (no walking up to it), already ripe
   local g=G.New(k or kind);if family and family~="" then g.family=family end
   local slot=G.Slot(d);local point=require(game.ReplicatedStorage.Shared.PlacementRules).FindFree(d,"Grave")
   if slot and point then g.slot=slot;g.pos=point;g.plantedAt=0;g.progress=nil;table.insert(d.graves,g) end
  end
  G.Render(p,d)
 elseif command=="bag" then
  -- /bag Stone:Deer,Marble: graves into the bag, unplanted (the crypt's icon flashes for them)
  local G=require(script.Parent.GraveService)
  for _,kind in string.split(arg or "",",") do
   local k,family=string.match(kind,"^(%a+):?(%a*)$");local g=G.New(k or kind);if family and family~="" then g.family=family end;table.insert(d.graveInventory,g)
  end
 elseif command=="tutorial" then
  -- /tutorial n: put the tutorial on step n (0-8; 9 = done), to check a step
  local n=tonumber(arg);if not n or n<0 or n>9 then return false end
  d.tutorialStep=n;d.tutorialDone=n>=9;require(script.Parent.InterfaceService).Refresh(p);require(script.Parent.WeaponService).Push(p)
 elseif command=="traps" then
  -- /traps n: n traps in the bag
  local n=tonumber(arg);if not n then return false end
  d.traps=n;require(script.Parent.RoadGearService).Push(p)
 elseif command=="carry" then
  -- /carry Stone: a grave of that kind on your back, as if dug on the road
  require(script.Parent.RoadService).Carry(p,arg or "Stone")
 elseif command=="trapself" then
  -- /trapself on|off: your own traps catch you too (a trap only ever catches someone else carrying a grave)
  require(script.Parent.RoadGearService).CatchOwner=arg~="off"
 elseif command=="hearts" then
  -- /hearts n: n hearts on the road (to test without the road's monsters getting in the way)
  local n=tonumber(arg);if not n then return false end
  require(script.Parent.RoadService).Hearts[p]=n;p:SetAttribute("RoadHearts",n)
 elseif command=="steal" then
  -- /steal n: dig a grave out of boss n's hoard at once (it wakes and gives chase)
  local Road=require(script.Parent.RoadService);local i=tonumber(arg) or 1
  for _,spot in Road.Spots do
   if spot.Guard==i and spot.Model and p.Character then
    p.Character:PivotTo(CFrame.new(Road.SpotPosition(spot,4)));task.wait(.3)
    return Road.Take(p,spot)
   end
  end
  return false
 elseif command=="grab" then
  -- /grab: pick up the nearest grave lying on the road (a dropped one too) as if the prompt were held
  local Road=require(script.Parent.RoadService);local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart");if not root then return false end
  local best,bestD
  for spot in pairs(Road.Drops) do if spot.Model then local dd=(Road.SpotPosition(spot,2)-root.Position).Magnitude;if not bestD or dd<bestD then best,bestD=spot,dd end end end
  if not best then return false end
  p.Character:PivotTo(CFrame.new(Road.SpotPosition(best,4)));task.wait(.3)
  return Road.Take(p,best)
 elseif command=="hitboss" then
  -- /hitboss n: step into boss n's arena and hit it once (the arena shuts: the fight starts)
  local Road=require(script.Parent.RoadService);local cfg=Road.BossCfg[tonumber(arg) or 0];local a=cfg and cfg.Live
  local d=require(game.ReplicatedStorage.Shared.Config.RoadProgression).Districts[tonumber(arg) or 0]
  if not a or not d or not p.Character then return false end
  p.Character:PivotTo(Road.At(d.PocketS,d.PocketX-d.PocketSide*40,4));task.wait(.3)
  return Road.Challenge(p) -- as the target button over the boss does
 elseif command=="farm" then
  -- /farm [n]: skip the tutorial and put n first-tier monsters out in the yard (night raids need a target)
  local Z=require(script.Parent.ZombieService);local Place=require(game.ReplicatedStorage.Shared.PlacementRules)
  d.tutorialDone=true;local n=math.clamp(tonumber(arg) or 4,1,16);local placed=0
  for gz=-4,32,7 do for gx=-34,34,7 do
   if placed<n then local z=Z.Roll({100},false,false,1);local point=Place.Point(gx,gz)
    if Place.InYard(point,Place.Radius("Zombie",z)) then z.zone="Field";z.slot=placed+1;z.pos=point;table.insert(d.zombies,z);placed+=1 end
   end
  end end
  Z.Render(p,d)
 elseif command=="give" then
  -- /give DeerMiner,RingMawKing: put those monsters out in the yard, at their catalog rarity (to look at the art)
  local Z=require(script.Parent.ZombieService);local Place=require(game.ReplicatedStorage.Shared.PlacementRules);local Col=require(game.ReplicatedStorage.Shared.MonsterCollection)
  local tierOf={};for _,e in Col.Catalog do tierOf[e.Id]=e.Tier end
  d.tutorialDone=true;local queue=string.split(arg or "",",");local placed=0
  for gz=-4,40,9 do for gx=-36,36,9 do
   local id=queue[placed+1]
   if id and tierOf[id] then local z=Z.Roll({100},false,false,1);z.type=id;z.tier=tierOf[id];local point=Place.Point(gx,gz)
    if Place.InYard(point,Place.Radius("Zombie",z)) then z.zone="Field";z.slot=#d.zombies+1;z.pos=point;table.insert(d.zombies,z);placed+=1 end
   end
  end end
  Z.Render(p,d)
 else return false end
 Pet.Push(p);return true
end
local function connect(p) p.Chatted:Connect(function(message) local a=string.split(message," ");if a[1]:sub(1,1)=="/" then execute(p,a[1]:sub(2),a[2],a[3]) end end) end
game.Players.PlayerAdded:Connect(connect);for _,p in ipairs(game.Players:GetPlayers()) do connect(p) end
-- Server-only Studio Command Bar entry point; absent from published servers and invisible to clients.
local command=Instance.new("BindableFunction");command.Name="PetDebugCommand";command.OnInvoke=execute;command.Parent=game.ServerStorage
