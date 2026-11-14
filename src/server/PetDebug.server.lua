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
 elseif command=="graves" then
  -- /graves Wooden,Stone,Marble,Golden,Lunar: plant those graves in the first grave spots (to look at the art)
  local G=require(script.Parent.GraveService);d.tutorialDone=true
  for i,kind in string.split(arg or "",",") do
   local g=G.New(kind);table.insert(d.graveInventory,g);d.selectedItem="grave";d.selectedGrave=g.id;G.Plant(p,i)
  end
  G.Render(p,d)
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
 elseif command=="hitboss" then
  -- /hitboss n: step into boss n's arena and hit it once (the arena shuts: the fight starts)
  local Road=require(script.Parent.RoadService);local cfg=Road.BossCfg[tonumber(arg) or 0];local a=cfg and cfg.Live
  local d=require(game.ReplicatedStorage.Shared.Config.RoadProgression).Districts[tonumber(arg) or 0]
  if not a or not d or not p.Character then return false end
  p.Character:PivotTo(Road.At(d.PocketS,d.PocketX-d.PocketSide*40,4));task.wait(.3)
  return require(script.Parent.MutantService).Damage(a,1,p)
 elseif command=="farm" then
  -- /farm [n]: skip the tutorial and put n first-tier monsters out in the yard (night raids need a target)
  local Z=require(script.Parent.ZombieService);local Place=require(game.ReplicatedStorage.Shared.PlacementRules)
  d.tutorialDone=true;local n=math.clamp(tonumber(arg) or 4,1,16);local placed=0
  for gz=-4,32,7 do for gx=-34,34,7 do
   if placed<n then local z=Z.Roll({100},false,false,1);local point=Place.Point(gx,gz)
    if not Place.Check(d,"Zombie",point,z) then z.zone="Field";z.slot=placed+1;z.pos=point;table.insert(d.zombies,z);placed+=1 end
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
    if not Place.Check(d,"Zombie",point,z) then z.zone="Field";z.slot=#d.zombies+1;z.pos=point;table.insert(d.zombies,z);placed+=1 end
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
