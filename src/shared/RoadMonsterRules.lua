-- Road enemies use the uncostumed family archetype, independently of farm collection skins.
-- The Chief remains the dedicated boss spawned by RoadConfig, outside this random pool.
local R={Pool={
 {Id="Deer",Asset="Deer_Root_Aggressive",Family="Deer",Kind="Imp"},
 {Id="Parasite",Asset="Parasite_Root_Aggressive",Family="Parasite",Kind="Bubble"},
 {Id="Stalker",Asset="Stalker_Root_Aggressive",Family="Stalker",Kind="Imp"},
 {Id="Verity",Asset="Verity_Root_Aggressive",Family="Verity",Kind="Imp"},
 {Id="RingMaw",Asset="RingMaw_Aggressive",Family="RingMaw",Kind="Bubble"},
 {Id="CaveDweller",Asset="CaveDweller_Aggressive",Family="CaveDweller",Kind="Imp"},
 {Id="SirenHead",Asset="SirenHead_Aggressive",Family="SirenHead",Kind="Bubble"},
 {Id="BuckshotDealer",Asset="BuckshotDealer_Aggressive",Family="BuckshotDealer",Kind="Imp"},
}}
for _,row in {{"CultistNormal","Cultist_Normal","Imp"},{"CultistHunter","Cultist_Hunter","Spitter"},{"CultistParasite","Cultist_Parasite","Bubble"}} do
 table.insert(R.Pool,{Id=row[1],Asset=row[2],Family="Cultist",Kind=row[3]})
end
function R.Roll(rng,last)
 local n=rng:NextInteger(1,#R.Pool)
 if R.Pool[n].Id==last and #R.Pool>1 then n=(n+rng:NextInteger(1,#R.Pool-1)-1)%#R.Pool+1 end
 return R.Pool[n]
end
function R.Count(length) return math.max(4,math.ceil(length/55)) end
function R.Near(s,runners,toRoad,radius)
 for _,r in runners do local distance=toRoad(r.pos);if math.abs(distance-s)<=radius then return true end end
 return false
end
return R
