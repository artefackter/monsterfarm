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
 -- the locations' mini cemeteries (filled in below): centre X studs off the road's middle, Radius to the fence, the
 -- graves in a ring of radius Ring, Gap studs short of where the boss arena opens onto the road
 Graveyard={X=38,Radius=15,Ring=8.5,Gap=6},Graveyards={},
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
  -- Harder again on 2026-11-15 (owner: "the boss fights are too easy and don't match their level"): HealthMult 5
  -- (was 2.4), and by location (Level) a boss attacks more often (Rate divides its cooldowns), telegraphs for less
  -- (Windup), moves faster (Speed) and calls in its location's monsters (Summon of them at a time, up to Minions).
  -- An enraged boss is 1.25x as fast (was 1.35x: it is faster to begin with now).
  -- The summoned monsters are most of the danger, and meant to be (owner, 2026-11-16, when they had been taken out
  -- for a few hours: "don't remove the summon, it was a very cool feature; and don't lower the damage, that is the
  -- point of the difficulty"). Measured that day with a runner circling the arena: the boss's own attacks never
  -- reach him from afar; the hearts he loses far from the boss are the summoned monsters' bites (two hearts every
  -- half second at the fourth boss, of five). "Damage from the other end of the arena" is them, not the boss's hit
  -- registration.
  -- HealthMult 3.5 since the finisher became one a fight (below): it was 5 with three finishers taking .45 of it,
  -- so there is as much to shoot off as before.
  HealthMult=3.5,DamageMult=1.5,Enrage={At=.5,Speed=1.25,Rate=1.6},PortalSeconds=15,
  Level={Rate={1.15,1.3,1.45,1.6,1.8,2},Windup={1,.95,.9,.85,.8,.75},Speed={1.05,1.08,1.1,1.12,1.15,1.18},Summon={0,1,2,2,3,3},Minions={0,2,3,4,5,6},SummonEvery=16},
  -- A summoned monster's bite is seen coming (owner, 2026-11-16: "add a visible wind-up before the bite, the damage
  -- as it is"): for Windup s before it bites it flares red and rears, still coming on; the bite lands if its prey is
  -- then within Reach times its usual reach, and misses otherwise. What a bite costs and how often it comes are the
  -- road's own (BiteEvery, the location's damage).
  MinionBite={Windup=.45,Reach=1.25},
  -- Stagger and finisher (owner, 2026-11-15: "at some point the boss is stunned and you finish it like in an AAA
  -- game, for big damage"): when its health falls to each of At (parts of the whole) the boss drops to its knees for
  -- Window s with a pulsing target on it; a fighter within Reach studs who taps it plays the finisher - the shovel
  -- drawn from behind the back and driven into its head - Finisher.Seconds long, the blow landing Impact s in for
  -- Damage of its whole health (the last one kills). Nobody hurts the finisher meanwhile. Left alone, the boss gets
  -- up after Window; either way the next stagger is at least Gap s away, and every time it gets up it is Phase
  -- quicker to attack.
  -- The same day (owner: "not cinematic; I'd like it like a Dead by Daylight kill; and nobody should go on shooting
  -- once the monster is down"): a staggered boss can't be shot, only finished, from within Reach. Then (owner: "I've
  -- put animations in the project folder, let's try them", with The Legion's memento mori for the look) the finisher
  -- became real animation clips (shared/Clips, from the owner's files): the player walks up to the boss's front
  -- (Walk s), stands Stand studs off its bulk and plays Clips in turn (each starts At s in) with the shovel held as a
  -- blade. Hits are the moments the blade lands (the boss shudders, sparks fly); the one at Impact does the Damage.
  -- Once a fight since the evening of 2026-11-15 (owner: "make the finisher less frequent"; it was at .7, .4 and
  -- .12): the boss goes down once, at a fifth of its health, and the finisher is the kill.
  -- 2026-11-16 (owner: "the Finish button must show from further away - now only from a certain distance; and let
  -- the boss still be killable by shots, the damage just registering smaller"): the target shows, and works, from
  -- Reach studs (was 28) - from further than Run.Free the finisher begins with a run-up, (distance - Free) / Speed s
  -- of it, Max at most, before the usual walk; and a boss on its knees takes Shots of any damage (it took none),
  -- except while someone is finishing it.
  Stagger={At={.2},Window=8,Gap=5,Reach=90,Phase=.15,Shots=.35,Run={Free=16,Speed=50,Max=1.5}},
  -- Heavy (owner, the same day: "I found an animation pack: a heavy 4-hit combo") is Sword_Heavy_Combo of Quaternius'
  -- Universal Animation Library 2 (CC0): four heavy blows .47, 1.18, 1.85 and 2.63 s in, the last an overhead chop,
  -- stepping in at each (its eleven studs of travel are scaled to four: finisher_clips.py). The two clips tried
  -- before it ("Thrust Slash", "Sword slicing another person") are no longer used.
  -- Kinds (owner, that evening: "add other finishers; the most important - one of them must be with a chainsaw"):
  -- the server picks one each time - a player's first is First, after that any but the one they did last - and
  -- names it in the player's and the boss's FinisherKind attribute (Finisher.Of reads it, at the foot of this file).
  -- Each has its own Seconds, Walk, Stand (and Side: studs to the boss's right of its head, for one that would
  -- pass beside it - none does now), Hits and Impact; Damage is the same for all.
  --   Heavy     the four-hit combo above
  --   Flurry    Sword_Dash - a rush of four studs with a cut .33 s in - from further off, then on the spot
  --             Sword_Regular_Combo: four quick cuts .23, .73, 1.2 and 1.57 s in, the last the Impact (its travel
  --             scaled to one stud). The other way round, the dash ran through the boss's arm.
  --   Chainsaw  not clips: a coded two-hand pose (ShovelMotion, CombatPose.SawPose) with the saw of ChainsawModel.
  --             Saw times: Draw it comes into the hand, Pull the starter cord (it catches on the last), Raise,
  --             Plunge, Cut it is in the head and grinding (a hit every .35 s), Rip it is torn out (the Impact),
  --             Hold raised, Lower.
  -- 2026-11-16 (owner: the shovels became seven melee weapons, "each must have finisher animations of its own, two
  -- each"): fourteen Kinds, two a weapon (ShovelConfig.<weapon>.Finishers; Tool names the weapon back). The server
  -- takes the equipped weapon's first, then its other, turn about. What a kind is made of (ShovelMotion plays it):
  --   Saw     the chainsaw's coded two-hand poses: SawPlunge (the 2026-11-15 one: started, raised, driven down into
  --           the head, ground in, torn out) and SawSweep (Style="Sweep": drawn back flat and cut across the head
  --           from the side)
  --   Clips   entries in turn, each from its At: a clip of shared/Clips (Rate, From, Hold={clip time, seconds},
  --           Grip: "Reverse" the blade point down from the fist, "Point" straight on from the forearm - a stab),
  --           or Code - "spin" (the swing's spin, Turns in Seconds), "flourish" (the butterfly knife flipped in
  --           front of the chest)
  --   Moves   carry the body besides: Forward/Side studs from From to To, Up the top of a jump
  --   Engine  {from, to}: the chainsword's engine runs; Soft {from, to}: hits in it are the grinding's, a thud each
  -- The clips are the animation pack's (Quaternius' Universal Animation Library 1 and 2, CC0; finisher_clips.py):
  --   Heavy the four-hit combo; Dash a rush with a cut; Combo four quick cuts; SlashA, SlashB its first two cuts
  --   alone; Reap a wide cut with a step in; Chop an overhead chop (a loop); Overhand a throw's wind-up and slam;
  --   Lunge a low rush (the pack's shield dash, mirrored to the right hand); Cross a straight punch - a
  --   stab, the weapon held point on; Hook an uppercut (HookRec: back up from it); Leap, Jump a crouch
  --   and spring (the pack has no height in them: Moves lift the body), LeapLand the landing; Roll a dive roll.
  -- Hits are worked out from the clips (the right hand at its fastest); the one at Impact kills.
  Finisher={Damage=.25,Kinds={
   SawPlunge={Tool="Chainsaw",Seconds=5.7,Walk=.8,Stand=4.5,Saw={Draw=.3,Pull={.98,1.3},Raise=1.6,Plunge=2.15,Cut=2.4,Rip=4.25,Hold=4.65,Lower=5.25},Soft={2.4,4.45},Hits={2.4,2.75,3.1,3.45,3.8,4.15,4.5},Impact=4.5},
   SawSweep={Tool="Chainsaw",Seconds=5.2,Walk=.8,Stand=4.4,Saw={Style="Sweep",Draw=.3,Pull={.95},Raise=1.3,Plunge=1.85,Cut=2.1,Rip=3.6,Hold=4,Lower=4.6},Soft={2.1,3.55},Hits={2.1,2.4,2.7,3,3.3,3.6},Impact=3.6},
   ScytheWhirl={Tool="Scythe",Seconds=5,Walk=.8,Stand=5.5,Clips={{Code="spin",At=.8,Seconds=2.1,Turns=3},{Name="Reap",At=3}},Hits={1.03,1.7,2.31,3.42},Impact=3.42},
   ScytheDescend={Tool="Scythe",Seconds=4.6,Walk=.8,Stand=6.8,Clips={{Name="Reap",At=.8},{Name="Leap",At=1.95},{Name="LeapLand",At=3.05}},Moves={{From=2.35,To=3.1,Up=6,Forward=.3}},Hits={1.22,3.1},Impact=3.1},
   KatanaFlurry={Tool="Katana",Seconds=4.2,Walk=.8,Stand=8,Clips={{Name="Dash",At=.8},{Name="Combo",At=1.6}},Hits={1.13,1.83,2.33,2.8,3.17},Impact=3.17},
   KatanaIai={Tool="Katana",Seconds=4.6,Walk=.8,Stand=4.6,Side=3.2,Clips={{Name="SlashA",At=.8},{Name="SlashB",At=1.3},{Name="Lunge",At=1.95,Hold={.02,1.25}}},Moves={{From=1.95,To=2.2,Forward=9}},Hits={1.03,1.57,2.08,3.2},Impact=3.2},
   SwordHeavy={Tool="Chainsword",Seconds=4.7,Walk=.8,Stand=6,Clips={{Name="Heavy",At=.8}},Engine={.5,4.2},Hits={1.27,1.98,2.65,3.43},Impact=3.43},
   SwordImpale={Tool="Chainsword",Seconds=5,Walk=.8,Stand=5.6,Clips={{Name="Reap",At=.8},{Name="Cross",At=2,Grip="Point",Hold={.3,1.6}}},Engine={.5,4.3},Soft={2.3,3.85},Hits={1.22,2.3,2.6,2.9,3.2,3.5,3.9},Impact=3.9},
   DaggerStabs={Tool="Dagger",Seconds=4.1,Walk=.8,Stand=4.6,Clips={{Name="Cross",At=.8,Rate=1.5,Grip="Point"},{Name="Cross",At=1.4,Rate=1.6,Grip="Point"},{Name="Cross",At=1.95,Rate=1.8,Grip="Point"},{Name="Hook",At=2.5,Grip="Point"},{Name="HookRec",At=3.05,Grip="Point"}},Hits={1,1.59,2.12,2.77},Impact=2.77},
   DaggerPlunge={Tool="Dagger",Seconds=4.2,Walk=.8,Stand=4.5,Clips={{Name="Jump",At=.8},{Name="Overhand",At=1.65,Grip="Reverse",Hold={.42,.9}}},Moves={{From=1.2,To=2.05,Up=5,Forward=1.2}},Hits={2.05,2.4,2.75},Impact=2.75},
   ButterflyFlourish={Tool="Butterfly",Seconds=4.3,Walk=.8,Stand=5.4,Clips={{Code="flourish",At=.8,Seconds=1,Flips=2},{Name="SlashA",At=1.8},{Name="SlashB",At=2.25},{Name="Hook",At=2.85,Grip="Point"},{Name="HookRec",At=3.4,Grip="Point"}},Hits={2.03,2.52,3.12},Impact=3.12},
   ButterflyRoll={Tool="Butterfly",Seconds=4.6,Walk=.8,Stand=9.4,Clips={{Name="Roll",At=.8},{Name="Hook",At=2.2,Grip="Point"},{Name="Cross",At=2.75,Rate=1.6,Grip="Point"},{Name="Cross",At=3.3,Rate=1.6,Grip="Point"}},Hits={2.47,2.94,3.49},Impact=3.49},
   PickMining={Tool="Pickaxe",Seconds=4.9,Walk=.8,Stand=5.2,Clips={{Name="Chop",At=.8,From=.45},{Name="Chop",At=1.28},{Name="Chop",At=2.2},{Name="Chop",At=3.12,Hold={.27,.8}}},Hits={1.53,2.45,3.37},Impact=3.37},
   PickSpike={Tool="Pickaxe",Seconds=4.5,Walk=.8,Stand=5.6,Clips={{Name="Reap",At=.8},{Name="Overhand",At=2.05,Hold={.42,.9}}},Hits={1.22,2.45},Impact=2.45},
  }},
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
 -- No slime pools since the road reskin (2026-11-15: the concepts took the green patches out); the slowing stays
 -- ready for any that come back.
 Slime={},SlimeSpeed=.6,
 -- Obstructions, dressed by location (RoadService): logs in the dark forest, wall in the backrooms, wrecked cars in
 -- the city, a broken fence in the village, rubble in Parasitown, timber and rocks in the cave.
 Walls={{S=140,X=-32,W=26,D=4,Look="Log"},{S=235,X=30,W=28,D=5,Look="Log"},{S=540,X=30,W=28,D=5,Look="Panel"},{S=665,X=-32,W=32,D=4,Look="Panel"},
  {S=1060,X=-32,W=30,D=4,Look="Cars"},{S=1500,X=30,W=30,D=4,Look="Fence"},{S=2150,X=-30,W=28,D=6,Look="Rubble"},{S=2450,X=30,W=30,D=5,Look="Rubble"},{S=3000,X=30,W=32,D=5,Look="Timber"},{S=3420,X=-30,W=30,D=5,Look="Rocks"}},
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
 -- One mini cemetery per location (owner, 2026-11-15: "one zone on each location where graves appear, mini cemeteries
 -- like the players' farms; graves appear on the road only there"; they stood one per 180 studs along it that day):
 -- a round purple patch fenced like a farm's, open towards the road's middle, its graves in a ring inside - one per
 -- 180 studs of the location (at least four), from its pool, each back Respawn s after it is taken. The dark
 -- forest's are nearly all wooden, and the tutorial sends a newcomer to the nearest. It stands at the location's end,
 -- just short of the boss, on the side across from its arena (owner, the same day; it stood mid-way before), stepped
 -- back if an obstruction is in the way (RoadArt dresses it).
 local G=config.Graveyard;local yard
 local side=-d.PocketSide
 local s0=d.PocketS-Progression.DoorWidth/2-G.Radius-G.Gap
 for back=0,240,10 do
  local s,x,r=s0-back,side*G.X,G.Radius
  local free=s-r-8>from and not Progression.PocketAt(s,x,r+6)
  for _,w in config.Walls do if math.abs(w.S-s)<w.D/2+r+6 and math.abs(w.X-x)<w.W/2+r+6 then free=false end end
  if free then yard={S=s,X=x,Radius=r,Side=side,Location=i};break end
 end
 yard=yard or {S=s0,X=side*G.X,Radius=G.Radius,Side=side,Location=i}
 table.insert(config.Graveyards,yard)
 local count=math.max(4,math.ceil(length/180))
 for n=1,count do
  local a=(yard.Side>0 and math.pi or 0)+(n-.5)/count*math.pi*2 -- half a step off the opening (it faces the road's middle)
  table.insert(config.Spots,{S=yard.S+math.sin(a)*G.Ring,X=yard.X+math.cos(a)*G.Ring,Pool=pools[i],Yard=i})
 end
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
 if Progression.PocketAt(s,x,8) then return false end -- not on a boss arena's part of the road (2026-11-15)
 for _,q in config.Spots do if math.abs(q.S-s)<16 and math.abs(q.X-x)<14 then return false end end
 for _,g in config.Graveyards do if Vector2.new(g.S-s,g.X-x).Magnitude<g.Radius+8 then return false end end
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
-- The finisher a player or a boss is in: the kind named by their FinisherKind attribute (SawPlunge without one).
local finisher=config.Boss.Finisher
function finisher.Of(holder) return finisher.Kinds[holder and holder:GetAttribute("FinisherKind") or ""] or finisher.Kinds.SawPlunge end
return config
