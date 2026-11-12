-- Four waves deliberately capped: 15, 50, 85, 120 seconds (the uncapped formula also gives 155).
return {
 DefaultType="Imp", ServerLimit=14, FirstWave=15, WaveInterval=35, WavesPerNight=4,
 FieldPerExtra=4, MaxPerFarmWave=3, Poll=.1, SpawnMin=45, SpawnMax=60, SpawnSide=12,
 SpawnSeconds=1, JumpSeconds=.35, JumpDistance=4, BiteSeconds=8, StunSeconds=40,
 TheftFraction=.05, TheftIncomeSeconds=60, RewardIncomeSeconds=10, RewardMin=25, RewardMax=5000,
 GuardInterval=2, GuardDamagePerTier=8, FleeSeconds=3, AnimateDistance=130,
 RootHeight=6, HitboxSize=Vector3.new(5,12,5), AlarmGap=10,
 Types={
  Imp={Health=30,Speed=14,Model="Cultist_Normal",Color=Color3.fromHex("B3123F")},
  Spitter={Health=55,Speed=12,Model="Cultist_Hunter",Color=Color3.fromHex("7D448E"),Range=40,Windup=.65,Cooldown=2.8,Radius=3},
  Bubble={Health=90,Speed=11,Model="Cultist_Parasite",Color=Color3.fromHex("C95B90"),Range=8,Windup=1,Cooldown=3.5,Radius=8},
  Chief={Health=320,Speed=10,Model="Deer_Chief_Aggressive",Color=Color3.fromHex("699C87"),Range=10,Windup=1.2,Cooldown=4,Radius=11},
 },
}
