local C=require(script.Parent.Config.PetConfig)
local R={}
function R.Migrate(d)
 d.pets=type(d.pets)=="table" and d.pets or {};d.petSlots=math.clamp(math.floor(tonumber(d.petSlots) or 0),0,C.MaxSlots-C.StartSlots);d.petStarterGiven=d.petStarterGiven==true
 local seen,clean,equipped={}, {},0
 for _,pet in ipairs(d.pets) do
 if type(pet)=="table" and type(pet.id)=="string" and not seen[pet.id] and C.Power[pet.species] and type(pet.tier)=="number" and pet.tier%1==0 and C.Tiers[pet.tier] then
 seen[pet.id]=true;pet.equipped=pet.equipped==true
 if pet.equipped then equipped+=1;if equipped>C.StartSlots+d.petSlots then pet.equipped=false;warn("Pet migration: excess equipped",pet.id) end end
 table.insert(clean,pet)
 else warn("Pet migration: duplicate or invalid pet removed") end end
 d.pets=clean;d.version=math.max(d.version or 1,C.Version);return d
end
function R.Calculate(d)
 local b={incomePct=0,graveSpeedPct=0,guardPct=0,luckMult=1,carryPenaltyReduction=0,autoDiggers={},hasAlarm=false}
 for _,p in ipairs(d.pets or {}) do if p.equipped then local n=C.Power[p.species][p.tier]
 if p.species=="FarmerCat" then table.insert(b.autoDiggers,{id=p.id,interval=n}) elseif p.species=="CoinHen" then b.incomePct+=n elseif p.species=="DiggerMole" then b.graveSpeedPct+=n elseif p.species=="LuckyOwl" then b.luckMult+=n-1 elseif p.species=="GuardDog" then b.guardPct+=n;b.hasAlarm=true elseif p.species=="BanditBat" then b.carryPenaltyReduction+=n end end end
 b.incomePct=math.min(C.IncomeCap,b.incomePct);b.luckMult=math.min(C.LuckCap,b.luckMult);return b
end
return R
