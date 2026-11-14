-- Six progressively longer biomes. Recommendations are progression points, not studs/second.
-- Locations v4 (owner, 2026-11-12): each location = a regular stretch with graves and its two monster kinds, then an
-- arena with the location's boss asleep on its hoard of graves (Boss, below).
local Progression=require(script.Parent.RoadProgression);local Zone=require(script.Parent.ZoneConfig)
local MonsterRules=require(script.Parent.Parent.RoadMonsterRules)
local config={
 Width=140,Length=Progression.Length,Dir=Vector3.new(.5,0,.866),Rim=170*Zone.IslandScale-Zone.Boundary.Inset-.5, -- the island wall (208 until 2026-11-14, when the island grew for the cemeteries)
 GateLine=5,
 Hold=1.5,Respawn=40,DropBelow=-8,Hearts=5,
 Bat={Range=8,Cooldown=1.2},
 -- Traps catch only someone else carrying a grave: Stun s, and the grave drops (monsters walk over them; the owner
 -- tried traps on monsters on 2026-11-13 and took it back).
 Trap={Price=100,MaxStock=10,MaxPlaced=3,Arm=1.25,Lifetime=60,Radius=2.6,Stun=1.5,Spacing=7},
 DropLifetime=180,MaxDrops=32,
 Carry={Wooden=.9,Stone=.85,Marble=.8,Golden=.75,Emo=.74,Military=.73,Ghost=.72,Lunar=.7},
 Spots={},Imps={},NightOnly={Lunar=true},
 BiomeScale={1,1.12,1.25,1.4,1.55,1.75},
 BiomeHealth={1,1.5,2.2,3.2,4.5,6},
 BiomeDamage={1,1,1,2,2,2},
 Announce={Marble=true,Golden=true,Emo=true,Military=true,Ghost=true,Lunar=true},
 -- Boss of every arena: Respawn s after a defeat it is back (asleep) and its main grave locks again.
 -- Kind is kept for the final boss (the Chief), whose grave hatches the DeerChief.
 -- Harder since 2026-11-13: HealthMult and DamageMult on top of the location's; below Enrage.At of its health a boss
 -- turns red, moves Enrage.Speed times faster and attacks Enrage.Rate times as often. After a win a portal home stands
 -- in the pocket for PortalSeconds, for everyone who hit the boss.
 -- Sleeping bosses (owner, 2026-11-13: "like Steal the Egg"): a boss sleeps in the middle of its arena on a hoard of
 -- Hoard.Count graves in a ring Hoard.Radius round it. Dig one up and it wakes (Chase.Wake s of roaring) and runs
 -- after the thief at Chase.Speed times its location's monster speed, all the way to the ruins gate; if it gets within
 -- Chase.Catch of them they die and the grave goes back. It gives up Chase.GiveUp s after the chase ends and is back
 -- asleep in its bed. Hit it instead and its arena shuts on everyone inside: the fight goes on until it or they fall.
 -- The main grave (Main[i]) stands caged Hoard.MainBehind behind its bed (at the back of the arena), locked until it
 -- falls and then only for its winners.
 Boss={Kind="Chief",Respawn=15,AfterWin=15, -- back 15 s after a win, winners left in the arena go home (2026-11-14; was 90)
 Leash=6,RegenAfter=4,RegenRate=.12,
  HealthMult=2.4,DamageMult=1.5,Enrage={At=.5,Speed=1.35,Rate=1.6},PortalSeconds=15,
  Hoard={Count=3,Radius=30,Respawn=60,MainBehind=84}, -- the main grave's cage stands at the back of the arena (2026-11-14; was 18)
  -- Faster since 2026-11-14 (owner: "at speed 240 I simply outrun it"): 1.1x the location's monster speed (was .95),
  -- so only a runner trained well past the location's recommended speed gets away; a shorter roar (1 s, was 1.6).
  Chase={Wake=1,Speed=1.1,Catch=4,GiveUp=4,Stuck=1.2,Hop=16},
  Main={{Kind="Marble"},{Kind="Golden"},{Kind="Golden"},{Kind="Lunar"},{Kind="Lunar"},{Kind="Lunar",Chief=.15}}},
 Night={GraveRolls=2,KillReward=2,Speed=1.12,AttackRate=1.2,Health=1.5,Damage=2},
 Population={MaxLive=64,SpawnBudget=2,ActiveDistance=430,SpawnJitter=18,RespawnMin=12,RespawnMax=22},
 -- Shoving another player on the road (owner, 2026-11-13): for HitPenalty.Seconds the bully lifts graves HitPenalty.Hold
 -- times slower, and the road's monsters within Provoke.Radius turn on them for Provoke.Seconds. A monster hit by
 -- a shovel turns on whoever hit it the same way.
 HitPenalty={Seconds=30,Hold=2.5},Provoke={Seconds=8,Radius=70},
 ImpRespawn=18,Aggro=100,AggroCarrier=145,BiteRange=4.5,BiteEvery=1.2,ImpsIdleAfter=30,
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
 -- Emo, Military and Ghost (2026-11-14) turn up from the village on, more of them further along
 {Stone=15,Marble=60,Golden=20,Emo=5},{Marble=35,Golden=35,Emo=10,Military=7,Ghost=3,Lunar=10},{Golden=45,Emo=10,Military=10,Ghost=8,Lunar=27},
}
-- The hoard round a sleeping boss: the location's best graves.
local arenaPools={
 {Stone=70,Marble=30},{Stone=20,Marble=80},{Marble=60,Golden=40},
 {Marble=20,Golden=70,Emo=10},{Golden=50,Emo=15,Military=10,Ghost=5,Lunar=20},{Golden=30,Emo=12,Military=12,Ghost=11,Lunar=35},
}
for i,d in Progression.Districts do
 -- The regular stretch: from the location's start to a little before its arena.
 local from,to=d.From,d.ArenaFrom-8
 local length=to-from
 -- No graves along the road any more (owner, 2026-11-14): only the bosses' hoards and main graves below. The pools
 -- stay for the reference (and the Blood Moon has its own).
 local _=length;local _=pools
 -- The sleeping boss's hoard: a ring of graves round its bed (free to steal, if you can outrun it), and behind the
 -- bed the main grave, locked until the boss falls (RoadService).
 local hoard=config.Boss.Hoard
 -- at most three, and never as rare as the boss's own main grave (owner, 2026-11-14)
 local main=config.Boss.Main[i];local order=require(script.Parent.GraveConfig).Order
 local cap=table.find(order,main.Kind);local pool={}
 for kind,w in arenaPools[i] do if table.find(order,kind)<cap then pool[kind]=w end end
 if next(pool)==nil then pool={[order[math.max(1,cap-1)]]=100} end
 for n=1,hoard.Count do
  local t=(n-.5)/hoard.Count*math.pi*2
  table.insert(config.Spots,{S=d.PocketS+math.sin(t)*hoard.Radius,X=d.PocketX+math.cos(t)*hoard.Radius,Pool=pool,Guard=i,Respawn=hoard.Respawn})
 end
 table.insert(config.Spots,{S=d.PocketS+d.DirS*hoard.MainBehind,X=d.PocketX+d.DirX*hoard.MainBehind,Pool={[main.Kind]=100},Arena=i,Main=true,Chief=main.Chief})
 local enemies=MonsterRules.Count(length)
 for n=1,enemies do
  table.insert(config.Imps,{S=from+length*(n-.3)/(enemies+.5),X=n%2==0 and 24 or -24,Kind="Imp",Speed=14,Biome=i,RandomVariant=true,MinS=from+12,MaxS=to-4})
 end
 local boss=MonsterRules.Bosses[i]
 table.insert(config.Imps,1,{S=d.PocketS,X=d.PocketX,Kind=boss.Kind,Speed=14,Biome=i,Boss=i,Variant=boss})
end
-- Bushes: every BushSpacing studs, on the first of four lanes that keeps clear of graves, logs and slime.
local function clear(s,x)
 for _,q in config.Spots do if math.abs(q.S-s)<16 and math.abs(q.X-x)<14 then return false end end
 for _,q in config.Walls do if math.abs(q.S-s)<q.D/2+10 and math.abs(q.X-x)<q.W/2+8 then return false end end
 for _,q in config.Slime do if s>q.From-10 and s<q.To+10 and math.abs(q.X-x)<q.Width/2+8 then return false end end
 return true
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
