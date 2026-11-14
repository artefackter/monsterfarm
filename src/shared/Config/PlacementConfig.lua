-- Farm layout, farm-local studs (-z toward the gate and the plaza). The farm is 96 x 96 (ZoneConfig.FarmHalf 48; it was
-- 84 x 84 until 2026-11-13, when it grew by 6 studs a side: the old yard is untouched, the new ring holds garden beds).
-- House on the right fence, door to the farm centre; cemetery back-left (+x), zombie pen front-right (-x),
-- treadmill front-left, free yard at the back for guards. Graves and pen zombies have no count limit.
return {
 Snap=.5,GraveRadius=2.2,ZombieRadius=1.7,Overlap=.9,PlaceDistance=50,
 Yard={MinX=-46,MaxX=46,MinZ=-46,MaxZ=46},
 -- The cemetery is its own fenced yard beside the farm since 2026-11-14 (owner: "bigger, a separate branch outside the
 -- plot, fenced, like the arenas"): Annex is its fence, reached through a short passage from an opening in the farm's
 -- +x fence (DoorFrom..DoorTo along z); Cemetery is where graves may stand. Monsters are never placed there (it is out
 -- of the Yard). The island and the ring of farms grew the same day to make room (ZoneConfig).
 Annex={MinX=52,MaxX=98,MinZ=-9,MaxZ=37,DoorFrom=6,DoorTo=18},
 Cemetery={MinX=54.5,MaxX=95.5,MinZ=-6.5,MaxZ=34.5},
 Pen={MinX=-40,MaxX=-14,MinZ=-36,MaxZ=-8},
 PenGate={From=-26,To=-20}, -- the opening in the pen's inner fence (x=MaxX)
 Blocked={
  {MinX=21,MaxX=34,MinZ=-32,MaxZ=-15}, -- treadmill
  {MinX=-8,MaxX=8,MinZ=-48,MaxZ=-40}, -- the gate (its leaves swing inward)
  {MinX=-16,MaxX=-8,MinZ=-48,MaxZ=-41}, {MinX=8,MaxX=16,MinZ=-48,MaxZ=-41}, -- the Lock and Fence boards by the gate
  {MinX=-11,MaxX=-1,MinZ=41.5,MaxZ=48}, -- the cart at the back (the crates went on 2026-11-14)
  {MinX=40.5,MaxX=48,MinZ=-48,MaxZ=-38.5}, -- the scarecrow in the front left corner (the well went on 2026-11-14)
  {MinX=-43,MaxX=-30.5,MinZ=-41,MaxZ=-28.5}, -- the workbench in the front corner by the well (2026-11-14; was by the house door)
  {MinX=-18.5,MaxX=-5.5,MinZ=-28.5,MaxZ=-15.5}, -- the zombucks heap (Bank)
 },
 Bank={X=-12,Z=-22}, -- where income piles up until the owner collects it
 GraveSpots={{x=60,z=2},{x=66.5,z=2},{x=73,z=2},{x=79.5,z=2},{x=60,z=8.5},{x=66.5,z=8.5},{x=73,z=8.5},{x=79.5,z=8.5},{x=60,z=15},{x=66.5,z=15},{x=73,z=15},{x=79.5,z=15}},
 LegacyField={X=-17,Z=-33,Columns=5,DX=-5,DZ=5},
 LegacyGraves={X=60,Z=2,Columns=4,DX=6.5,DZ=6.5},
 Crypt={X=23.5,Z=28,Door=6,Yaw=45,HalfX=5.5,HalfZ=4.6}, -- in the cemetery's back half, turned to the farm centre like the house
 -- The house across the back-right corner (HouseConfig): one turned block covering walls, porch and bushes.
 Rotated={{X=-22.96,Z=22.96,Yaw=-45,HalfX=18.5,HalfZ=17}},
 -- The garden beds of the outer ring went on 2026-11-14 (owner: too much detail); the ring is plain yard again.
 Beds={},
 Guards={{X=6,Z=34},{X=8,Z=28},{X=4,Z=-12},{X=10,Z=-8}},
}
