-- Farm layout, farm-local studs (-z toward the gate and the plaza). The farm is 84 x 84 (ZoneConfig.FarmHalf 42).
-- House on the right fence, door to the farm centre; cemetery back-left (+x), zombie pen front-right (-x),
-- treadmill front-left, free yard at the back for guards. Graves and pen zombies have no count limit.
return {
 Snap=.5,GraveRadius=2.2,ZombieRadius=1.7,Overlap=.9,PlaceDistance=50,
 Yard={MinX=-40,MaxX=40,MinZ=-40,MaxZ=40},
 Cemetery={MinX=10,MaxX=37,MinZ=3,MaxZ=37}, -- a patch on the grass, not pressed into the corner
 Pen={MinX=-40,MaxX=-14,MinZ=-36,MaxZ=-8},
 PenGate={From=-26,To=-20}, -- the opening in the pen's inner fence (x=MaxX)
 Blocked={
  {MinX=21,MaxX=34,MinZ=-32,MaxZ=-15}, -- treadmill
  {MinX=-7,MaxX=7,MinZ=-42,MaxZ=-35}, -- the gate
  {MinX=-18.5,MaxX=-5.5,MinZ=-28.5,MaxZ=-15.5}, -- the zombucks heap (Bank)
 },
 Bank={X=-12,Z=-22}, -- where income piles up until the owner collects it
 GraveSpots={{x=15,z=7},{x=20.5,z=7},{x=26,z=7},{x=31.5,z=7},{x=15,z=12},{x=20.5,z=12},{x=26,z=12},{x=31.5,z=12},{x=15,z=17},{x=20.5,z=17},{x=26,z=17},{x=31.5,z=17}},
 LegacyField={X=-17,Z=-33,Columns=5,DX=-5,DZ=5},
 LegacyGraves={X=15,Z=7,Columns=4,DX=5.5,DZ=5},
 Crypt={X=23.5,Z=28,Door=6,Yaw=45,HalfX=5.5,HalfZ=4.6}, -- in the cemetery's back half, turned to the farm centre like the house
 -- The house across the back-right corner (HouseConfig): one turned block covering walls, porch and bushes.
 Rotated={{X=-16.96,Z=16.96,Yaw=-45,HalfX=18.5,HalfZ=17}},
 Guards={{X=6,Z=34},{X=8,Z=28},{X=4,Z=-12},{X=10,Z=-8}},
}
