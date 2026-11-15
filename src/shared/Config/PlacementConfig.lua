-- Farm layout, farm-local studs (-z toward the gate and the plaza). The farm is 96 x 96 (ZoneConfig.FarmHalf 48; it was
-- 84 x 84 until 2026-11-13, when it grew by 6 studs a side: the old yard is untouched, the new ring holds garden beds).
-- House on the right fence, door to the farm centre; the round cemetery outside the +x fence, zombie pen front-right (-x),
-- treadmill front-left, free yard at the back for guards. Graves and pen zombies have no count limit.
return {
 Snap=.5,GraveRadius=2.2,ZombieRadius=1.7,Overlap=.9,PlaceDistance=50,
 Yard={MinX=-46,MaxX=46,MinZ=-46,MaxZ=46},
 -- The cemetery since 2026-11-14 (owner's picture: "a round yard, a continuation of the farm"): a circle beside the
 -- farm's +x fence, ringed by a low stone wall with an iron fence on it, the crypt in its middle and graves all round.
 -- Its opening faces the farm, at the end of a short passage from the opening in the farm's fence (DoorFrom..DoorTo
 -- along z). Graves may stand anywhere inside the wall but on the crypt (Crypt.Keep) and the walk up to its steps
 -- (Walk). Monsters are never placed there (it is out of the Yard). The farm and the cemetery count as one place for
 -- the owner (PlotService.Inside).
 Cemetery={X=74,Z=13,Radius=24,Wall=1.6,DoorFrom=7,DoorTo=19},
 -- The crypt (art/crypt-optimized-v1, 2026-11-14) in the cemetery's middle, its steps towards the farm (-x). Keep is
 -- the ground it covers, Menu the spot in front of its steps that opens the crypt menu.
 Crypt={X=77,Z=13,Scale=1.4,Keep={MinX=66.4,MaxX=84.4,MinZ=4.4,MaxZ=21.6},Menu={X=65,Z=13}},
 Walk={MinX=46,MaxX=67.5,MinZ=10,MaxZ=16},
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
 GraveSpots={{x=66,z=26},{x=72,z=26},{x=78,z=26},{x=84,z=26},{x=66,z=0},{x=72,z=0},{x=78,z=0},{x=84,z=0},{x=90,z=8},{x=90,z=13},{x=90,z=18},{x=58,z=22}},
 LegacyField={X=-17,Z=-33,Columns=5,DX=-5,DZ=5},
 -- The house across the back-right corner (HouseConfig): one turned block covering walls, porch and bushes.
 Rotated={{X=-22.96,Z=22.96,Yaw=-45,HalfX=18.5,HalfZ=17}},
 -- The garden beds of the outer ring went on 2026-11-14 (owner: too much detail); the ring is plain yard again.
 Beds={},
 Guards={{X=6,Z=34},{X=8,Z=28},{X=4,Z=-12},{X=10,Z=-8}},
}
