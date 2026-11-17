-- Melee weapons (slot 1). They were seven shovels until 2026-11-16 (owner: "let's replace the shovels with other
-- weapons: a chainsaw, the Reaper's scythe, a katana, a chainsword, the Mimicry dagger, a butterfly knife, a diamond
-- pickaxe" - weakest to strongest in his order). Each took a shovel's place with its numbers, price and way of
-- getting it: the first is the starter, the next two are bought, the last four are Monsterdex rewards
-- (InterfaceConfig.DexShovels). Legacy maps a profile's old shovel onto the weapon in its place (ActionRules).
-- The names in code stay "shovel" (this file, EquippedShovel, ShovelModel, ShovelMotion): only what the player
-- holds changed. Graves are still dug with a plain shovel (ShovelModel's "Dig"), whatever the weapon.
-- Knockout (seconds): how long a hit player, or monster, stays down. Distance (studs): how far a hit PLAYER flies;
-- monsters are not shoved. The better the weapon, the longer and the further (owner, 2026-11-12). Bosses take the
-- damage only.
-- Hands: 2 - the left hand joins the right on it (the swing, standing ready).
-- Finishers: its two boss finishers (owner: "each weapon must have finisher animations of its own, two each";
-- RoadConfig.Boss.Finisher.Kinds).
return {
 Order={'Chainsaw','Scythe','Katana','Chainsword','Dagger','Butterfly','Pickaxe'},
 Legacy={Rusty='Chainsaw',Steel='Scythe',Combat='Katana',Bone='Chainsword',Golden='Dagger',Lunar='Butterfly',Rainbow='Pickaxe'},
 CarryDamage=1.5,CarryKnockout=1.5,CarryDistance=1.3,
 HalfAngle=70,Windup=.10,Swing=.36,Immunity=3,KnockFlight=.28,Switch=.35,
 Chainsaw={Range=8,Cooldown=1.2,Knockout=1,Distance=6,Damage=10,Color='D2552A',Hands=2,Finishers={'SawPlunge','SawSweep'}},
 Scythe={Price=15000,Range=9,Cooldown=1.1,Knockout=1.3,Distance=9,Damage=15,Color='8A7BC8',Hands=2,Finishers={'ScytheWhirl','ScytheDescend'}},
 Katana={Price=250000,Range=10,Cooldown=1,Knockout=1.6,Distance=12,Damage=25,Color='D9DEE6',Hands=2,Finishers={'KatanaFlurry','KatanaIai'}},
 Chainsword={Range=11,Cooldown=.9,Knockout=1.9,Distance=15,Damage=35,Color='B3202A',Hands=2,Finishers={'SwordHeavy','SwordImpale'}},
 Dagger={Range=12,Cooldown=.8,Knockout=2.2,Distance=18,Damage=50,Color='B86BE0',Hands=1,Finishers={'DaggerStabs','DaggerPlunge'}},
 Butterfly={Range=12,Cooldown=.75,Knockout=2.5,Distance=21,Damage=70,Color='C9CED6',Hands=1,Finishers={'ButterflyFlourish','ButterflyRoll'}},
 Pickaxe={Range=13,Cooldown=.7,Knockout=3,Distance=25,Damage=100,Color='4FE3E8',Hands=2,Finishers={'PickMining','PickSpike'}},
}
