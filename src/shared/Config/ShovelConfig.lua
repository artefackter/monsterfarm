-- Knockout (seconds): how long a hit player, or monster, stays down. Distance (studs): how far a hit PLAYER flies;
-- monsters are not shoved. The better the shovel, the longer and the further (owner, 2026-11-12). Bosses take the
-- damage only.
return {
 Order={'Rusty','Steel','Combat','Bone','Golden','Lunar','Rainbow'},
 CarryDamage=1.5,CarryKnockout=1.5,CarryDistance=1.3,
 HalfAngle=70,Windup=.10,Swing=.36,Immunity=3,KnockFlight=.28,Switch=.35,
 Rusty={Range=8,Cooldown=1.2,Knockout=1,Distance=6,Damage=10,Color='997657'},
 Steel={Price=15000,Range=9,Cooldown=1.1,Knockout=1.3,Distance=9,Damage=15,Color='ABBBC8'},
 Combat={Price=250000,Range=10,Cooldown=1,Knockout=1.6,Distance=12,Damage=25,Color='56685B'},
 Bone={Range=11,Cooldown=.9,Knockout=1.9,Distance=15,Damage=35,Color='E5D4B3'},
 Golden={Range=12,Cooldown=.8,Knockout=2.2,Distance=18,Damage=50,Color='FFD354'},
 Lunar={Range=12,Cooldown=.75,Knockout=2.5,Distance=21,Damage=70,Color='B8A0F7'},
 Rainbow={Range=13,Cooldown=.7,Knockout=3,Distance=25,Damage=100,Color='F98BC7'},
}
