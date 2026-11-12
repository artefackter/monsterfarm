local C=require(script.Parent.Config.PetConfig)
local R={}
local function isStarter(pet) return pet.species==C.Starter end
R.IsStarter=isStarter
function R.Migrate(d)
 d.pets=type(d.pets)=="table" and d.pets or {};d.petSlots=math.clamp(math.floor(tonumber(d.petSlots) or 0),0,C.MaxSlots-C.StartSlots);d.petStarterGiven=d.petStarterGiven==true
 local seen,clean,equipped,refund,hasStarter={}, {},0,0,false
 for _,pet in ipairs(d.pets) do
  if type(pet)=="table" and C.Removed[pet.species] and type(pet.tier)=="number" and C.Release[pet.tier] then
   refund+=C.Release[pet.tier] -- pets v3: the old kinds are gone, paid back at their release price
  elseif type(pet)=="table" and type(pet.id)=="string" and not seen[pet.id] and C.Power[pet.species] and type(pet.tier)=="number" and pet.tier%1==0 and C.Tiers[pet.tier] and not (isStarter(pet) and hasStarter) then
   seen[pet.id]=true;pet.equipped=pet.equipped==true
   if isStarter(pet) then hasStarter=true;pet.equipped=true -- the farm cat is always out and takes no slot
   elseif pet.equipped then equipped+=1;if equipped>C.StartSlots+d.petSlots then pet.equipped=false;warn("Pet migration: excess equipped",pet.id) end end
   table.insert(clean,pet)
  else warn("Pet migration: duplicate or invalid pet removed") end
 end
 if not hasStarter then table.insert(clean,1,{id=game:GetService("HttpService"):GenerateGUID(false),species=C.Starter,tier=1,equipped=true}) end
 if refund>0 then d.coins=(d.coins or 0)+refund;d.petRefundNotice=(d.petRefundNotice or 0)+refund end
 d.pets=clean;d.version=math.max(d.version or 1,C.Version);return d
end
-- incomeMult multiplies the farm's income (BedBanker); dragons breathe fire (PetService). The other fields stay
-- neutral for the systems the old pets fed (graves, guards, luck, carrying).
function R.Calculate(d)
 local b={incomePct=0,incomeMult=1,graveSpeedPct=0,guardPct=0,luckMult=1,carryPenaltyReduction=0,autoDiggers={},hasAlarm=false,dragons={}}
 for _,p in ipairs(d.pets or {}) do if p.equipped and C.Power[p.species] then local n=C.Power[p.species][p.tier]
  if p.species=="DragonHead" then table.insert(b.dragons,{id=p.id,damage=n})
  elseif p.species=="BedBanker" then b.incomeMult*=n end
 end end
 return b
end
return R
