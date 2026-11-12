-- Six progressively longer biomes. Recommendations are progression points, not studs/second.
local Progression=require(script.Parent.RoadProgression)
local config={
 Width=140,Length=Progression.Length,Dir=Vector3.new(.5,0,.866),Rim=208,GateLine=5,
 Hold=1.5,Respawn=40,DropBelow=-8,Hearts=5,
 Bat={Range=8,Cooldown=1.2},
 Trap={Price=100,MaxStock=10,MaxPlaced=3,Arm=1.25,Lifetime=60,Radius=2.6,Stun=1.5,Spacing=7},
 DropLifetime=180,MaxDrops=32,
 Carry={Wooden=.9,Stone=.85,Marble=.8,Golden=.75,Lunar=.7},
 Spots={},Imps={},NightOnly={Lunar=true},
 BiomeScale={1,1.12,1.25,1.4,1.55,1.75},
 BiomeHealth={1,1.5,2.2,3.2,4.5,6},
 BiomeDamage={1,1,1,2,2,2},
 Announce={Marble=true,Golden=true,Lunar=true},
 Boss={Kind="Chief",From=2110,Respawn=90,GraveChance=.10,GraveLifetime=300},
 Night={GraveRolls=2,KillReward=2,Speed=1.12,AttackRate=1.2,Health=1.5,Damage=2},
 Population={MaxLive=64,SpawnBudget=2,ActiveDistance=430,SpawnJitter=18,RespawnMin=12,RespawnMax=22},
 ImpRespawn=18,Aggro=100,AggroCarrier=145,BiteRange=4.5,BiteEvery=1.2,ImpsIdleAfter=30,
 Gap={From=1010,To=1017},
 Slime={{From=305,To=323,X=-24,Width=32},{From=1750,To=1775,X=22,Width=36}},SlimeSpeed=.6,
 Walls={{S=105,X=-32,W=26,D=4},{S=290,X=30,W=28,D=5},{S=650,X=-32,W=32,D=4},{S=1140,X=30,W=30,D=4},{S=1880,X=-30,W=28,D=6},{S=2700,X=30,W=32,D=5}},
 Bushes={},
 BaseSpeed=16,SlowSpeed=10,MaxSpeed=75,SpeedLog=8.8,SpeedDivisor=100,StepSeconds=.5,HitSlow=.65,HitSlowDuration=2.5,
 Treadmill={{Rate=3},{Rate=15,Price=5000},{Rate=60,Price=50000},{Rate=300,Price=500000},{Rate=1500,Price=5000000}},
 TreadmillSpot={X=27,Z=-24,W=6.4,D=12,Y=-.5},
}
local pools={
 {Wooden=90,Stone=10},{Wooden=25,Stone=75},{Stone=65,Marble=35},
 {Stone=15,Marble=65,Golden=20},{Marble=40,Golden=50,Lunar=10},{Golden=65,Lunar=35},
}
for i,d in Progression.Districts do
 local length=d.To-d.From
 local count=math.max(2,math.ceil(length/180))
 for n=1,count do table.insert(config.Spots,{S=d.From+length*n/(count+1),X=n%2==0 and 33 or -33,Pool=pools[i]}) end
 local enemies=require(script.Parent.Parent.RoadMonsterRules).Count(length)
 for n=1,enemies do
  local kind=i==1 and "Imp" or i==2 and (n%2==0 and "Spitter" or "Imp") or (n%3==0 and "Bubble" or n%2==0 and "Spitter" or "Imp")
  table.insert(config.Imps,{S=d.From+length*(n-.3)/(enemies+.5),X=n%2==0 and 24 or -24,Kind=kind,Speed=14,Biome=i,RandomVariant=true,MinS=d.From+12,MaxS=d.To-10})
 end
end
table.insert(config.Imps,1,{S=3225,X=0,Kind="Chief",Speed=14})
return config
