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
 else return false end
 Pet.Push(p);return true
end
local function connect(p) p.Chatted:Connect(function(message) local a=string.split(message," ");if a[1]:sub(1,1)=="/" then execute(p,a[1]:sub(2),a[2],a[3]) end end) end
game.Players.PlayerAdded:Connect(connect);for _,p in ipairs(game.Players:GetPlayers()) do connect(p) end
-- Server-only Studio Command Bar entry point; absent from published servers and invisible to clients.
local command=Instance.new("BindableFunction");command.Name="PetDebugCommand";command.OnInvoke=execute;command.Parent=game.ServerStorage
