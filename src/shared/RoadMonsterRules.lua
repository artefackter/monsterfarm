-- Road enemies come in their family's plain form, independently of the farm collection's looks.
-- Locations v4 (owner, 2026-11-12): each location spawns only its own kinds of monster, and its boss waits in the
-- arena at the end of it. Kind picks the behaviour (MutantConfig.Types), Family the way it moves.
-- The road reskin (owner, 2026-11-15): three kinds of monster per location and a new boss line-up; the same day,
-- "no looks on the road": every monster and boss is in its plain form (ArtModels Granny, Longmaw, ... converted from
-- the art packs' base models), save the dark forest's boss, which is the Chief Physician (owner: "replace the Horned
-- Alpha with the Chief Physician").
local R={Districts={
 -- 1. Dark forest: deer that bite, twitching Verity, stalkers that leap from afar
 {{Id="Deer",Asset="Deer_Root_Aggressive",Family="Deer",Kind="Imp"},
  {Id="Verity",Asset="Verity_Root_Aggressive",Family="Verity",Kind="Imp"},
  {Id="Stalker",Asset="Stalker_Root_Aggressive",Family="Stalker",Kind="Leaper"}},
 -- 2. Backrooms: Longmaws that run you down, RingMaw pouncers, Siren Head stamping down the corridor
 {{Id="Longmaw",Asset="Longmaw",Family="Longmaw",Kind="Imp"},
  {Id="RingMaw",Asset="RingMaw_Aggressive",Family="RingMaw",Kind="Leaper"},
  {Id="SirenHead",Asset="SirenHead_Aggressive",Family="SirenHead",Kind="Bubble"}},
 -- 3. Abandoned city: the Stranger, a leaping Slenderman, Mimics that slam
 {{Id="HoodedStranger",Asset="HoodedStranger",Family="HoodedStranger",Kind="Imp"},
  {Id="Slenderman",Asset="Slenderman",Family="Slenderman",Kind="Leaper"},
  {Id="Mimic",Asset="Mimic",Family="Mimic",Kind="Bubble"}},
 -- 4. Abandoned village: Granny, Grandpa throwing what he finds, Slendrina's Mom leaping on her spider legs
 {{Id="Granny",Asset="Granny",Family="Granny",Kind="Imp"},
  {Id="Grandfather",Asset="Grandfather",Family="Grandfather",Kind="Thrower"},
  {Id="SpiderMom",Asset="SpiderMom",Family="SpiderMom",Kind="Leaper"}},
 -- 5. Parasitown: the Assimilant, the heavy Dredge, the spitting Viscera
 {{Id="AssimilatedAdventurer",Asset="AssimilatedAdventurer",Family="AssimilatedAdventurer",Kind="Imp"},
  {Id="Dredge",Asset="Dredge",Family="Dredge",Kind="Bubble"},
  {Id="AdaptedViscera",Asset="AdaptedViscera",Family="AdaptedViscera",Kind="Spitter"}},
 -- 6. Abandoned cave: cave dwellers, the Summoner hurling rocks, the Dealer with his shotgun
 {{Id="CaveDweller",Asset="CaveDweller_Aggressive",Family="CaveDweller",Kind="Imp"},
  {Id="PrimitiveSummoner",Asset="PrimitiveSummoner",Family="PrimitiveSummoner",Kind="Thrower"},
  {Id="BuckshotDealer",Asset="BuckshotDealer_Aggressive",Family="BuckshotDealer",Kind="Spitter",Floating=true}},
},
-- One boss per location. Kind holds its health and attacks (MutantConfig.Types), Name its locale key.
Bosses={
 -- the Chief Physician with the first boss's strength and attacks (it was the Horned Alpha until 2026-11-15)
 -- Skinned (2026-11-15): the boss is built from its skinned model in ReplicatedStorage.ArtSkinned (one mesh on a
 -- skeleton: MutantModel, MutantAnimation) when it is there; Asset still gives its size, and stands in without it.
 -- The Stranger and Slendrina came with skeletons; the other four were rigid pieces and got theirs that evening
 -- (owner: "make skeletons for the other four bosses"; art/roblox-import-v1/tools/rig_bosses.py).
 {Id="DeerChief",Kind="BossHorned",Asset="Deer_Chief_Aggressive",Skinned="DeerChief_Skinned",Family="Deer",Name="Chief"},
 -- FinisherOff: studs further off its head a finisher is done from (FinisherController) - the RingMaw's maw is a
 -- dish six studs across, lifted at whoever stands over it
 {Id="BossRingMaw",Kind="BossRingMaw",Asset="RingMaw_Aggressive",Skinned="RingMaw_Skinned",Family="RingMaw",Name="bossRingMaw",FinisherOff=3}, -- was Siren Head until 2026-11-13
 {Id="BossStranger",Kind="BossStranger",Asset="HoodedStranger",Skinned="HoodedStranger_Skinned",Family="HoodedStranger",Name="bossStranger"},
 {Id="BossSlendrina",Kind="BossSlendrina",Asset="Slendrina",Skinned="Slendrina_Skinned",Family="Slendrina",Name="bossSlendrina"},
 {Id="BossPatient",Kind="BossPatient",Asset="Parasite_Root_Aggressive",Skinned="Parasite_Skinned",Family="Parasite",Name="bossPatient"},
 -- the last boss's main grave may still hatch the Chief Physician (RoadConfig.Boss.Main)
 {Id="BossCaveDweller",Kind="BossCaveDweller",Asset="CaveDweller_Aggressive",Skinned="CaveDweller_Skinned",Family="CaveDweller",Name="bossCaveDweller"},
}}
-- A flat list of every road variant, for code that needs to look one up by id.
R.Pool={}
for _,pair in R.Districts do for _,v in pair do table.insert(R.Pool,v) end end
-- Picks one of the location's kinds, never the same twice in a row, so every kind shows up.
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
