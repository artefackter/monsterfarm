local RS=game:GetService("ReplicatedStorage");local C=require(RS.Shared.Config.PetConfig);local PC=require(RS.Shared.Config.PumpkinConfig);local U=require(RS.Shared.Config.UpgradeConfig);local Rules=require(RS.Shared.PetRules)
local D=require(script.Parent.DataService);local P=require(script.Parent.PlotService);local Day=require(script.Parent.DayNightService);local A=require(script.Parent.AnalyticsTracker)
local Pet={Cache=setmetatable({},{__mode="k"}),Timers={},Alarm={},Rate={},Dirty={},FirstDig={},PendingStarter={},Breath={}}
local rng=Random.new();local rem
function Pet.ForData(d) if not Pet.Cache[d] then Pet.Cache[d]=Rules.Calculate(d) end return Pet.Cache[d] end
function Pet.GetBonuses(p) local d=D.Profiles[p];return d and Pet.ForData(d) or Rules.Calculate({}) end
function Pet.Find(d,id) for i,p in ipairs(d.pets) do if p.id==id then return p,i end end end
function Pet.Count(d) local n=0;for _,p in ipairs(d.pets) do if p.equipped and not Rules.IsStarter(p) then n+=1 end end return n end -- the farm cat takes no slot
function Pet.Refresh(p)
 local d=D.Profiles[p];Pet.Cache[d]=nil;local b=Pet.ForData(d);local list={};local timers=Pet.Timers[p] or {};local nextTimers={}
 for _,cat in ipairs(b.autoDiggers) do nextTimers[cat.id]=timers[cat.id] or os.clock()+cat.interval end;Pet.Timers[p]=nextTimers
 for _,pet in ipairs(d.pets) do if pet.equipped then table.insert(list,pet) end end
 p:SetAttribute("EquippedPets",game.HttpService:JSONEncode(list));Pet.Dirty[p]=true
end
function Pet.Push(p)
 if not rem then return end;local d=D.Profiles[p];if not d then return end
 local b=table.clone(Pet.ForData(d));local G=require(script.Parent.GraveService);local guard=b.guardPct
 for _,z in ipairs(d.zombies) do if z.zone=="Guards" then guard+=require(RS.Shared.Config.ZoneConfig).GuardChance*require(RS.Shared.MergeRules).Power(z) end end
 b.totalGrave=G.Boost(d);b.totalGuard=math.min(C.GuardCap,guard);b.carryPenalty=math.max(C.MinCarryPenalty,1-require(RS.Shared.Config.NightConfig).CarrySpeed-b.carryPenaltyReduction)
 rem.PetState:FireClient(p,{pets=d.pets,slots=C.StartSlots+d.petSlots,slotPrice=U.PetSlots.Price*U.PetSlots.Factor^d.petSlots,bonuses=b,coins=d.coins,starterPet=Pet.PendingStarter[p]})
end
function Pet.Grant(p,species,tier)
 local d=D.Profiles[p];if not d or #d.pets>=C.Inventory then return end
 local pet={id=game.HttpService:GenerateGUID(false),species=species,tier=tier,equipped=false};table.insert(d.pets,pet);Pet.Dirty[p]=true;return pet
end
-- Every farm already has its cat (PetRules.Migrate); once the tutorial is done the player is introduced to it.
function Pet.Starter(p)
 local d=D.Profiles[p]
 if d.tutorialDone and not d.petStarterGiven then
  for _,pet in ipairs(d.pets) do if Rules.IsStarter(pet) then d.petStarterGiven=true;A.Step(p,6);Pet.PendingStarter[p]=pet;break end end
 end
 if d.petRefundNotice and rem then rem.Notice:FireClient(p,"petsRefunded",{n=require(RS.Shared.Locale).compact(d.petRefundNotice,require(RS.Shared.Locale).lang(p))});d.petRefundNotice=nil end
end
function Pet.Roll(weights) local roll=rng:NextNumber()*100;for i,w in ipairs(weights) do roll-=w;if roll<=0 then return i end end return #weights end
function Pet.Action(p,op,id)
 if not require(script.Parent.ActionService).CanAct(p) then return false,"petBusy" end
 local d=D.Profiles[p];if not d then return false,"error" end
 local raid=require(script.Parent.RaidService);if raid.Carriers[p] then return false,"petBusy" end
 local before=d.coins
 if op=="PetHatch" then
 local pumpkin=PC[id];if type(pumpkin)~="table" or not pumpkin.Price then return false,"error" end
 if #d.pets>=C.Inventory then return false,"petFull" end
 if not require(script.Parent.InterfaceService).NearZone(p,"pumpkins") then return false,"petShopDistance" end
 if pumpkin.NightOnly and not Day.State() then return false,"petNightOnly" end
 if d.coins<pumpkin.Price then return false,"petNoCoins" end
 -- Prepare all potentially failing work before the non-yielding currency/inventory commit.
 local ok,result=pcall(function() return {id=game.HttpService:GenerateGUID(false),species=C.Order[Pet.Roll(C.Weights)],tier=Pet.Roll(pumpkin.Weights),equipped=false} end)
 if not ok then return false,"error" end
 d.coins-=pumpkin.Price;table.insert(d.pets,result);Pet.Dirty[p]=true;if Pet.OnHatch then Pet.OnHatch(p) end
 rem.PetHatched:FireClient(p,{pet=result,pumpkin=id})
 if result.tier>=4 then rem.Notice:FireAllClients("petRare",{name=p.DisplayName,rarity=C.Tiers[result.tier],species=result.species}) end
 pcall(function() game:GetService("AnalyticsService"):LogCustomEvent(p,"PetHatch",1,{pumpkin=id,species=result.species,tier=C.Tiers[result.tier]}) end)
 elseif op=="PetBuySlot" then
 return false,"actionBlocked"
 elseif op=="PetEquipBest" then
 local ordered={};for _,pet in ipairs(d.pets) do if not Rules.IsStarter(pet) then table.insert(ordered,pet) end end
 table.sort(ordered,function(a,b) if a.tier~=b.tier then return a.tier>b.tier end;if a.species~=b.species then return C.Priority[a.species]<C.Priority[b.species] end;return a.id<b.id end)
 for i,pet in ipairs(ordered) do pet.equipped=i<=C.StartSlots+d.petSlots end;Pet.Refresh(p);Pet.PendingStarter[p]=nil;A.Step(p,7)
 else
 local pet,index=Pet.Find(d,id);if not pet then return false,"error" end
 if Rules.IsStarter(pet) then return false,"petStarterStays" end -- the farm cat always lives on the farm
 if op=="PetEquip" then if not pet.equipped and Pet.Count(d)>=C.StartSlots+d.petSlots then return false,"petSlotsFull" end;pet.equipped=true;Pet.PendingStarter[p]=nil;A.Step(p,7)
 elseif op=="PetUnequip" then pet.equipped=false
 elseif op=="PetRelease" then if pet.equipped then return false,"petUnequipFirst" end;d.coins+=C.Release[pet.tier];table.remove(d.pets,index)
 else return false,"error" end
 Pet.Refresh(p)
 end
 Pet.Dirty[p]=true;if d.coins~=before then A.Economy(p,d.coins-before,d.coins,op) end;return true
end
-- DragonHead: whatever attacks this farm (MutantService raiders, inside the fence or just outside it) gets a breath
-- of fire every DragonCooldown seconds from each dragon; the client sends the dragon over to breathe.
function Pet.Tick()
 local M=require(script.Parent.MutantService);local half=require(RS.Shared.Config.ZoneConfig).FarmHalf+C.DragonReach
 for p,d in pairs(D.Profiles) do local plot=P.Assigned[p];if plot then
  Pet.Starter(p)
  local dragons=Pet.GetBonuses(p).dragons
  if #dragons>0 then
   local timers=Pet.Breath[p] or {};Pet.Breath[p]=timers
   for _,dragon in ipairs(dragons) do if os.clock()>=(timers[dragon.id] or 0) then
    local best,bestDist
    for _,a in pairs(M.Live) do
     local root=a.owner==p and a.hp>0 and a.state~="Spawning" and a.model.PrimaryPart
     if root then local v=plot.Base:PointToObjectSpace(root.Position);if math.abs(v.X)<=half and math.abs(v.Z)<=half and (not bestDist or v.Magnitude<bestDist) then best,bestDist=a,v.Magnitude end end
    end
    if best then
     timers[dragon.id]=os.clock()+C.DragonCooldown
     M.FX("PetBreath",best.id,best.model.PrimaryPart.Position,p.UserId,dragon.id) -- before the damage: it may remove the model
     M.Damage(best,dragon.damage,p)
    end
   end end
  end
 end end
end
function Pet.Init()
 rem=RS:WaitForChild("Remotes")
 for _,name in ipairs({"PetHatch","PetEquip","PetUnequip","PetEquipBest","PetRelease","PetBuySlot","PetHatched","PetDigFx","PetAlarm","PetState","PetSync"}) do if not rem:FindFirstChild(name) then local e=Instance.new("RemoteEvent");e.Name=name;e.Parent=rem end end
 for _,op in ipairs({"PetHatch","PetEquip","PetUnequip","PetEquipBest","PetRelease","PetBuySlot","PetSync"}) do rem[op].OnServerEvent:Connect(function(p,id)
 local now=os.clock();if now-(Pet.Rate[p] or -1)<C.RemoteInterval then return end;Pet.Rate[p]=now
 local needs=op=="PetHatch" or op=="PetEquip" or op=="PetUnequip" or op=="PetRelease"
 if needs and (type(id)~="string" or #id>100) or not needs and id~=nil then return end
 if op=="PetSync" then Pet.Push(p);return end
 local ok,key=Pet.Action(p,op,id);if not ok then rem.Notice:FireClient(p,key) end;Pet.Push(p)
 end) end
 for _,name in ipairs({"PetHatchSound","PetDigSound","PetAlarmSound"}) do if not RS.Sounds:FindFirstChild(name) then local s=Instance.new("Sound");s.Name=name;s.Parent=RS.Sounds end end
 task.spawn(function() while task.wait(C.Poll) do local ok,err=pcall(Pet.Tick);if not ok then warn("Pet tick failed",err) end end end)
 game.Players.PlayerRemoving:Connect(function(p) Pet.Timers[p]=nil;Pet.Breath[p]=nil;Pet.Alarm[p]=nil;Pet.Rate[p]=nil;Pet.Dirty[p]=nil;Pet.FirstDig[p]=nil;Pet.PendingStarter[p]=nil end)
end
return Pet
