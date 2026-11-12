-- Six progressively longer biomes. Recommendations are progression points, not studs/second.
-- Locations v4 (owner, 2026-11-12): each location = a regular stretch with graves and its two monster kinds, then an
-- amphitheatre with the location's boss and two treasure graves locked until the boss falls.
local Progression=require(script.Parent.RoadProgression)
local MonsterRules=require(script.Parent.Parent.RoadMonsterRules)
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
 -- Boss of every amphitheatre: respawn after a defeat, the grave it may drop, how long its arena graves stay open.
 -- Kind is kept for the final boss (the Chief), whose grave hatches the DeerChief.
 Boss={Kind="Chief",Respawn=90,GraveChance=.10,GraveLifetime=300,Leash=6,RegenAfter=4,RegenRate=.12,
  Graves={{Kind="Stone",Chance=.6},{Kind="Marble",Chance=.4},{Kind="Marble",Chance=.6},{Kind="Golden",Chance=.35},{Kind="Golden",Chance=.5},{Kind="Golden",Chance=.10,MonsterType="DeerChief"}}},
 Night={GraveRolls=2,KillReward=2,Speed=1.12,AttackRate=1.2,Health=1.5,Damage=2},
 Population={MaxLive=64,SpawnBudget=2,ActiveDistance=430,SpawnJitter=18,RespawnMin=12,RespawnMax=22},
 ImpRespawn=18,Aggro=100,AggroCarrier=145,BiteRange=4.5,BiteEvery=1.2,ImpsIdleAfter=30,
 Gap={From=1660,To=1667},
 Slime={{From=560,To=580,X=-24,Width=32},{From=2300,To=2325,X=22,Width=36}},SlimeSpeed=.6,
 -- Fallen logs in the forests, rock piles further on.
 Walls={{S=140,X=-32,W=26,D=4,Log=true},{S=235,X=30,W=28,D=5,Log=true},{S=540,X=30,W=28,D=5,Log=true},{S=665,X=-32,W=32,D=4,Log=true},
  {S=1060,X=-32,W=30,D=4},{S=1500,X=30,W=30,D=4},{S=2150,X=-30,W=28,D=6},{S=2450,X=30,W=30,D=5},{S=3000,X=30,W=32,D=5},{S=3420,X=-30,W=30,D=5}},
 -- Hiding bushes: filled in below along every location's regular stretch (never in an arena). BushRadius is the
 -- hiding spot round a clump's middle; a shot or a swing from it gives the runner away for BushReveal seconds.
 Bushes={},BushRadius=4.6,BushReveal=2,BushSpacing=64,
 BaseSpeed=16,SlowSpeed=10,MaxSpeed=75,SpeedLog=8.8,SpeedDivisor=100,StepSeconds=.5,HitSlow=.65,HitSlowDuration=2.5,
 -- Levels 6-7 (2026-11-12) reuse the level-5 model with glowing rails (HouseService.RefreshTreadmill).
 Treadmill={{Rate=3},{Rate=15,Price=5000},{Rate=60,Price=50000},{Rate=300,Price=500000},{Rate=1500,Price=5000000},{Rate=6000,Price=25000000},{Rate=24000,Price=100000000}},
 TreadmillSpot={X=27,Z=-24,W=6.4,D=12,Y=-.5},
}
local pools={
 {Wooden=90,Stone=10},{Wooden=25,Stone=75},{Stone=65,Marble=35},
 {Stone=15,Marble=65,Golden=20},{Marble=40,Golden=50,Lunar=10},{Golden=65,Lunar=35},
}
-- The arena's two graves are the location's best.
local arenaPools={
 {Stone=70,Marble=30},{Stone=20,Marble=80},{Marble=60,Golden=40},
 {Marble=20,Golden=80},{Golden=70,Lunar=30},{Golden=45,Lunar=55},
}
for i,d in Progression.Districts do
 -- The regular stretch: from the location's start to a little before its arena.
 local from,to=d.From,d.ArenaFrom-8
 local length=to-from
 local count=math.max(2,math.ceil(length/180))
 for n=1,count do table.insert(config.Spots,{S=from+length*n/(count+1),X=n%2==0 and 33 or -33,Pool=pools[i]}) end
 -- Treasure behind the boss, on the far side of the arena.
 for _,x in {-34,34} do table.insert(config.Spots,{S=d.Arena+30,X=x,Pool=arenaPools[i],Arena=i}) end
 local enemies=MonsterRules.Count(length)
 for n=1,enemies do
  table.insert(config.Imps,{S=from+length*(n-.3)/(enemies+.5),X=n%2==0 and 24 or -24,Kind="Imp",Speed=14,Biome=i,RandomVariant=true,MinS=from+12,MaxS=to-4})
 end
 local boss=MonsterRules.Bosses[i]
 table.insert(config.Imps,1,{S=d.Arena,X=0,Kind=boss.Kind,Speed=14,Biome=i,Boss=i,Variant=boss})
end
-- Bushes: every BushSpacing studs, on the first of four lanes that keeps clear of graves, logs, slime and the jump.
local function clear(s,x)
 for _,q in config.Spots do if math.abs(q.S-s)<16 and math.abs(q.X-x)<14 then return false end end
 for _,q in config.Walls do if math.abs(q.S-s)<q.D/2+10 and math.abs(q.X-x)<q.W/2+8 then return false end end
 for _,q in config.Slime do if s>q.From-10 and s<q.To+10 and math.abs(q.X-x)<q.Width/2+8 then return false end end
 return not (s>config.Gap.From-24 and s<config.Gap.To+24)
end
local lanes={-48,20,-16,50}
for i,d in Progression.Districts do
 local n,s=0,d.From+48
 while s<d.ArenaFrom-34 do
  n+=1
  for k=0,#lanes-1 do local x=lanes[(n+k-1)%#lanes+1];if clear(s,x) then table.insert(config.Bushes,{S=s,X=x,District=i});break end end
  s+=config.BushSpacing
 end
end
return config
