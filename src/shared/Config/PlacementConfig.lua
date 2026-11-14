-- Farm layout, farm-local studs (-z toward the gate and the plaza). The farm is 96 x 96 (ZoneConfig.FarmHalf 48; it was
-- 84 x 84 until 2026-11-13, when it grew by 6 studs a side: the old yard is untouched, the new ring holds garden beds).
-- House on the right fence, door to the farm centre; cemetery back-left (+x), zombie pen front-right (-x),
-- treadmill front-left, free yard at the back for guards. Graves and pen zombies have no count limit.
return {
 Snap=.5,GraveRadius=2.2,ZombieRadius=1.7,Overlap=.9,PlaceDistance=50,
 Yard={MinX=-46,MaxX=46,MinZ=-46,MaxZ=46},
 Cemetery={MinX=9.5,MaxX=38,MinZ=0,MaxZ=38}, -- a patch on the grass, a little bigger since 2026-11-12 (was 10..37 x 3..37)
 Pen={MinX=-40,MaxX=-14,MinZ=-36,MaxZ=-8},
 PenGate={From=-26,To=-20}, -- the opening in the pen's inner fence (x=MaxX)
 Blocked={
  {MinX=21,MaxX=34,MinZ=-32,MaxZ=-15}, -- treadmill
  {MinX=-8,MaxX=8,MinZ=-48,MaxZ=-40}, -- the gate (its leaves swing inward)
  {MinX=-16,MaxX=-8,MinZ=-48,MaxZ=-41}, {MinX=8,MaxX=16,MinZ=-48,MaxZ=-41}, -- the Lock and Fence boards by the gate
  {MinX=-11,MaxX=-1,MinZ=41.5,MaxZ=48}, {MinX=-20,MaxX=-12,MinZ=41.5,MaxZ=48}, -- the cart and the crates at the back
  {MinX=40.5,MaxX=48,MinZ=-48,MaxZ=-38.5}, {MinX=-48,MaxX=-40.5,MinZ=-48,MaxZ=-38.5}, -- the scarecrow and the well in the front corners
  {MinX=-24.5,MaxX=-13.5,MinZ=3,MaxZ=14}, -- the workbench by the house door, on its right (2026-11-13)
  {MinX=-18.5,MaxX=-5.5,MinZ=-28.5,MaxZ=-15.5}, -- the zombucks heap (Bank)
 },
 Bank={X=-12,Z=-22}, -- where income piles up until the owner collects it
 GraveSpots={{x=15,z=7},{x=20.5,z=7},{x=26,z=7},{x=31.5,z=7},{x=15,z=12},{x=20.5,z=12},{x=26,z=12},{x=31.5,z=12},{x=15,z=17},{x=20.5,z=17},{x=26,z=17},{x=31.5,z=17}},
 LegacyField={X=-17,Z=-33,Columns=5,DX=-5,DZ=5},
 LegacyGraves={X=15,Z=7,Columns=4,DX=5.5,DZ=5},
 Crypt={X=23.5,Z=28,Door=6,Yaw=45,HalfX=5.5,HalfZ=4.6}, -- in the cemetery's back half, turned to the farm centre like the house
 -- The house across the back-right corner (HouseConfig): one turned block covering walls, porch and bushes.
 Rotated={{X=-22.96,Z=22.96,Yaw=-45,HalfX=18.5,HalfZ=17}},
 -- Garden beds in the new outer ring (owner, 2026-11-13: "beds and all sorts, a livelier farm"). X,Z is the middle,
 -- W across x and D across z; Crop picks what grows. Nothing can be placed on a bed (PlacementRules).
 Beds={
  {X=20,Z=-43.5,W=7,D=4.5,Crop="Cabbage"},{X=28.5,Z=-43.5,W=7,D=4.5,Crop="Pumpkin"},{X=37,Z=-43.5,W=7,D=4.5,Crop="Brain"},
  {X=-20,Z=-43.5,W=7,D=4.5,Crop="Carrot"},{X=-28.5,Z=-43.5,W=7,D=4.5,Crop="Brain"},{X=-37,Z=-43.5,W=7,D=4.5,Crop="Cabbage"},
  {X=-43.5,Z=-30,W=4.5,D=9,Crop="Pumpkin"},{X=-43.5,Z=-18,W=4.5,D=9,Crop="Carrot"},{X=-43.5,Z=-6,W=4.5,D=9,Crop="Dead"},
  {X=43.5,Z=-30,W=4.5,D=9,Crop="Carrot"},{X=43.5,Z=-18,W=4.5,D=9,Crop="Cabbage"},{X=43.5,Z=-6,W=4.5,D=9,Crop="Brain"},
  {X=43.5,Z=12,W=4.5,D=12,Crop="Patch"},{X=43.5,Z=30,W=4.5,D=12,Crop="Patch"},
 },
 Guards={{X=6,Z=34},{X=8,Z=28},{X=4,Z=-12},{X=10,Z=-8}},
}
