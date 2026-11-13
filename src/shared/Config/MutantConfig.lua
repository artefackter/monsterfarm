-- Four waves deliberately capped: 15, 50, 85, 120 seconds (the uncapped formula also gives 155).
-- Attacks (road): Shape says how it lands.
--   Self    a slam around the monster itself          Target  a blast where the runner stood at the wind-up
--   Volley  Count blasts scattered round the runner   Dash    a leap/charge along a line, hits what it touches
--   Scream  a wide shock round the monster, slows     Summon  calls Count of its location's monsters
-- Damage is in hearts before the location multiplier (RoadConfig.BiomeDamage). Fx is the client effect.
return {
 DefaultType="Imp", ServerLimit=14, FirstWave=15, WaveInterval=35, WavesPerNight=4,
 FieldPerExtra=4, MaxPerFarmWave=3, Poll=.1, SpawnMin=45, SpawnMax=60, SpawnSide=12,
 SpawnSeconds=1, JumpSeconds=.35, JumpDistance=4, BiteSeconds=8, StunSeconds=40,
 TheftFraction=.05, TheftIncomeSeconds=60, RewardIncomeSeconds=10, RewardMin=25, RewardMax=5000,
 GuardInterval=2, GuardDamagePerTier=8, FleeSeconds=3, AnimateDistance=130,
 RootHeight=6, HitboxSize=Vector3.new(5,12,5), AlarmGap=10,
 -- Who raids the farms at night (owner, 2026-11-12: "not only cultists"): every raider bites the same way; Kind sets
 -- its health and speed (Types), Weight how often it comes.
 FarmRaiders={
  {Id="CultistNormal",Asset="Cultist_Normal",Family="Cultist",Kind="Imp",Weight=3},
  {Id="Deer",Asset="Deer_Root_Aggressive",Family="Deer",Kind="Imp",Weight=2},
  {Id="Stalker",Asset="Stalker_Root_Aggressive",Family="Stalker",Kind="Leaper",Weight=2},
  {Id="Verity",Asset="Verity_Root_Aggressive",Family="Verity",Kind="Imp",Weight=2},
  {Id="CaveDweller",Asset="CaveDweller_Aggressive",Family="CaveDweller",Kind="Imp",Weight=1},
  {Id="Parasite",Asset="Parasite_Root_Aggressive",Family="Parasite",Kind="Bubble",Weight=1},
 },
 Types={
  Imp={Health=30,Speed=14,Model="Cultist_Normal",Color=Color3.fromHex("B3123F")},
  Spitter={Health=55,Speed=12,Model="Cultist_Hunter",Color=Color3.fromHex("7D448E"),Range=40,Windup=.65,Cooldown=2.8,Radius=3,
   Attacks={{Name="Shot",Shape="Target",Range=40,Windup=.65,Cooldown=2.8,Radius=3,Fx="HunterShot"}}},
  Bubble={Health=90,Speed=11,Model="Cultist_Parasite",Color=Color3.fromHex("C95B90"),Range=8,Windup=1,Cooldown=3.5,Radius=8,
   Attacks={{Name="Slam",Shape="Self",Range=8,Windup=1,Cooldown=3.5,Radius=8,Fx="Slam"}}},
  Leaper={Health=40,Speed=14,Model="Stalker_Root_Aggressive",Color=Color3.fromHex("5F6B8C"),
   Attacks={{Name="Leap",Shape="Dash",Range=24,MinRange=7,Windup=.55,Cooldown=3.4,Radius=4.5,Speed=58,Distance=26,Fx="Leap"}}},
  Thrower={Health=45,Speed=12,Model="Stalker_Farmer_Aggressive",Color=Color3.fromHex("8C6A3F"),
   Attacks={{Name="Throw",Shape="Target",Range=34,MinRange=6,Windup=.8,Cooldown=3,Radius=4,Fx="Throw"}}},
  -- Bosses: one per location, kept inside its amphitheatre (RoadService). Scale multiplies the location's size,
  -- SpeedFactor the location's enemy speed; RewardMult multiplies the usual kill reward, paid to everyone who hit it.
  BossHorned={Boss=true,Health=420,Speed=12,Scale=1.55,SpeedFactor=.78,RewardMult=12,Model="Deer_Assassin_Aggressive",Color=Color3.fromHex("6B4A33"),
   Attacks={
    {Name="Charge",Shape="Dash",Range=46,MinRange=12,Windup=1,Cooldown=5,Radius=6,Speed=62,Distance=56,Damage=2,Fx="Charge"},
    {Name="Slam",Shape="Self",Range=12,Windup=1,Cooldown=4,Radius=13,Damage=2,Fx="Slam"},
   }},
  BossSiren={Boss=true,Health=380,Speed=11,Scale=1.85,SpeedFactor=.7,RewardMult=12,Model="SirenHead_Aggressive",Color=Color3.fromHex("8F9488"),
   Attacks={
    {Name="Scream",Shape="Scream",Range=30,Windup=1.3,Cooldown=7,Radius=30,Damage=1,Fx="Scream"},
    {Name="Stomp",Shape="Target",Range=40,MinRange=8,Windup=.9,Cooldown=3.5,Radius=7.5,Damage=2,Fx="Slam"},
   }},
  -- The second boss (owner, 2026-11-13): the RingMaw, in its own painted mesh (the part-built one was taken back the
  -- same day). It pounces across the arena, roars, and spits a fan of its seeds.
  BossRingMaw={Boss=true,Health=400,Speed=12,Scale=1.8,SpeedFactor=.8,RewardMult=12,Model="RingMaw_Assassin_Aggressive",Color=Color3.fromHex("967A83"),
   Attacks={
    {Name="Leap",Shape="Dash",Range=44,MinRange=10,Windup=.8,Cooldown=4.5,Radius=7,Speed=70,Distance=46,Damage=2,Fx="Leap"},
    {Name="Scream",Shape="Scream",Range=26,Windup=1.2,Cooldown=7,Radius=26,Damage=1,Fx="Scream"},
    {Name="Spit",Shape="Volley",Count=4,Spread=10,Range=36,MinRange=8,Windup=1,Cooldown=5,Radius=5,Damage=1,Fx="Acid"},
   }},
  BossPatient={Boss=true,Health=450,Speed=11,Scale=1.6,SpeedFactor=.75,RewardMult=12,Model="Parasite_Assassin_Aggressive",Color=Color3.fromHex("9C5A7A"),
   Attacks={
    {Name="Spit",Shape="Volley",Count=3,Spread=9,Range=38,MinRange=6,Windup=1,Cooldown=4.5,Radius=5.5,Damage=1,Fx="Acid"},
    {Name="Slam",Shape="Self",Range=12,Windup=1.1,Cooldown=4,Radius=14,Damage=2,Fx="Slam"},
   }},
  BossDealer={Boss=true,Health=480,Speed=12,Scale=1.7,SpeedFactor=.75,RewardMult=12,Model="BuckshotDealer_Aggressive",Color=Color3.fromHex("DDD9D0"),
   Attacks={
    {Name="Buckshot",Shape="Volley",Count=5,Spread=12,Range=40,MinRange=6,Windup=.9,Cooldown=4,Radius=4,Damage=1,Fx="HunterShot"},
    {Name="Smash",Shape="Self",Range=14,Windup=1,Cooldown=4.5,Radius=15,Damage=2,Fx="Slam"},
   }},
  BossPriest={Boss=true,Health=520,Speed=10,Scale=1.6,SpeedFactor=.7,RewardMult=12,Model="Cultist_Parasite",Color=Color3.fromHex("8E1F35"),
   Attacks={
    {Name="Summon",Shape="Summon",Count=2,MaxMinions=4,Range=60,Windup=1.4,Cooldown=14,Fx="Summon"},
    {Name="Curse",Shape="Volley",Count=2,Spread=7,Range=40,MinRange=5,Windup=1,Cooldown=3.5,Radius=7,Damage=2,Fx="Acid"},
   }},
  Chief={Boss=true,Health=560,Speed=10,Scale=1.45,SpeedFactor=.75,RewardMult=15,Model="Deer_Chief_Aggressive",Color=Color3.fromHex("699C87"),Range=10,Windup=1.2,Cooldown=4,Radius=11,
   Attacks={
    {Name="Slam",Shape="Self",Range=13,Windup=1.2,Cooldown=4,Radius=14,Damage=2,Fx="Slam"},
    {Name="Charge",Shape="Dash",Range=50,MinRange=12,Windup=1,Cooldown=6,Radius=7,Speed=70,Distance=60,Damage=2,Fx="Charge"},
   }},
 },
}
