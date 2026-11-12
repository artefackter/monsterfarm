-- Road enemies use the uncostumed family archetype (or a themed costume), independently of farm collection skins.
-- Locations v4 (owner, 2026-11-12): each location spawns only its own two kinds of monster, and its boss waits
-- in the amphitheatre at the end of it. Kind picks the behaviour (MutantConfig.Types), Family the way it moves.
local R={Districts={
 -- 1. Forest: deer creatures that bite, stalkers that leap from afar
 {{Id="Deer",Asset="Deer_Root_Aggressive",Family="Deer",Kind="Imp"},
  {Id="Stalker",Asset="Stalker_Root_Aggressive",Family="Stalker",Kind="Leaper"}},
 -- 2. Dark forest: twitching Verity biters and RingMaw pouncers
 {{Id="Verity",Asset="Verity_Root_Aggressive",Family="Verity",Kind="Imp"},
  {Id="RingMaw",Asset="RingMaw_Aggressive",Family="RingMaw",Kind="Leaper"}},
 -- 3. Hospital: bloated parasites that slam, pale long-armed patients
 {{Id="Parasite",Asset="Parasite_Root_Aggressive",Family="Parasite",Kind="Bubble"},
  {Id="CaveDweller",Asset="CaveDweller_Aggressive",Family="CaveDweller",Kind="Imp"}},
 -- 4. Village: farmhands with pitchforks, and ones who throw their harvest
 {{Id="DeerFarmer",Asset="Deer_Farmer_Aggressive",Family="Deer",Kind="Imp"},
  {Id="StalkerFarmer",Asset="Stalker_Farmer_Aggressive",Family="Stalker",Kind="Thrower"}},
 -- 5. Cultist cave: robed cultists and their riflemen
 {{Id="CultistNormal",Asset="Cultist_Normal",Family="Cultist",Kind="Imp"},
  {Id="CultistHunter",Asset="Cultist_Hunter",Family="Cultist",Kind="Spitter"}},
 -- 6. Factory: mutated punks, heavy slammers and leaping long-arms
 {{Id="ParasitePunk",Asset="Parasite_Punk_Aggressive",Family="Parasite",Kind="Bubble"},
  {Id="CaveDwellerPunk",Asset="CaveDweller_Punk_Aggressive",Family="CaveDweller",Kind="Leaper"}},
},
-- One boss per location. Kind holds its health and attacks (MutantConfig.Types), Name its locale key.
Bosses={
 {Id="BossHorned",Kind="BossHorned",Asset="Deer_Assassin_Aggressive",Family="Deer",Name="bossHorned"},
 {Id="BossSiren",Kind="BossSiren",Asset="SirenHead_Aggressive",Family="SirenHead",Name="bossSiren"},
 {Id="BossPatient",Kind="BossPatient",Asset="Parasite_Assassin_Aggressive",Family="Parasite",Name="bossPatient"},
 {Id="BuckshotDealer",Kind="BossDealer",Asset="BuckshotDealer_Aggressive",Family="BuckshotDealer",Name="bossDealer",Floating=true},
 {Id="BossPriest",Kind="BossPriest",Asset="Cultist_Parasite",Family="Cultist",Name="bossPriest"},
 {Id="DeerChief",Kind="Chief",Asset="Deer_Chief_Aggressive",Family="Deer",Name="Chief"},
}}
-- A flat list of every road variant, for code that needs to look one up by id.
R.Pool={}
for _,pair in R.Districts do for _,v in pair do table.insert(R.Pool,v) end end
-- Alternates between the location's two kinds, so both always show up.
function R.Roll(rng,last,district)
 local pool=R.Districts[math.clamp(district or 1,1,#R.Districts)]
 local n=rng:NextInteger(1,#pool)
 if pool[n].Id==last and #pool>1 then n=n%#pool+1 end
 return pool[n]
end
function R.Count(length) return math.max(4,math.ceil(length/55)) end
function R.Near(s,runners,toRoad,radius)
 for _,r in runners do local distance=toRoad(r.pos);if math.abs(distance-s)<=radius then return true end end
 return false
end
return R
