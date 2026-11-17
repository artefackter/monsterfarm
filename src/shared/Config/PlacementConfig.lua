-- Farm layout, farm-local studs (-z toward the gate and the plaza). The farm is 100 x 100 (ZoneConfig.FarmHalf 50;
-- 96 x 96 until 2026-11-15, 84 x 84 until 2026-11-13). The house across the back-right corner (-x, +z) with its door to
-- the farm centre, the round cemetery over the back-left one (+x, +z), zombie pen front-right (-x), treadmill front-left,
-- free yard between the house and the cemetery for guards. Graves and pen zombies have no count limit.
--
-- The cemetery (owner, 2026-11-15: it stuck out beside the farm and took too much room; a red circle on a screenshot
-- put it over the back-left corner, "the cemetery goes out past the farm and the farm bulges"): a circle 16 studs in
-- from the +x fence and 11 in from the back one, so it sticks out past both. The farm's fence stops where it meets
-- the circle (BackCut on the back fence, SideCut on the +x one) and the cemetery's own fence carries on round the
-- outside: the farm bulges there. Its opening faces the farm centre (its frame's -Z), the crypt in its middle with the
-- steps to the opening. Graves may stand anywhere inside its fence but on the crypt (Crypt.Keep) and the walk up to
-- the steps (Walk); monsters never stand in it (PlacementRules.InYard).
local F=require(script.Parent.ZoneConfig).FarmHalf-1 -- the farm's fence lines
local Cemetery={X=F-16,Z=F-11,Radius=22,Wall=1.6,Gate=12}
Cemetery.Yaw=math.deg(math.atan2(Cemetery.X,Cemetery.Z))
Cemetery.BackCut=Cemetery.X-math.sqrt(Cemetery.Radius^2-(F-Cemetery.Z)^2) -- x where the circle meets the back fence
Cemetery.SideCut=Cemetery.Z-math.sqrt(Cemetery.Radius^2-(F-Cemetery.X)^2) -- z where it meets the +x fence
local function spot(lx,lz) -- the cemetery's own frame -> farm-local
 local a=math.rad(Cemetery.Yaw);return Cemetery.X+lx*math.cos(a)+lz*math.sin(a),Cemetery.Z-lx*math.sin(a)+lz*math.cos(a)
end
local function turned(lx,lz,halfX,halfZ) local x,z=spot(lx,lz);return {X=x,Z=z,Yaw=Cemetery.Yaw,HalfX=halfX,HalfZ=halfZ} end
local cryptX,cryptZ=spot(0,3)
local menuX,menuZ=spot(0,-9)
-- the old default spots, a ring round the crypt clear of the walk (used when a profile has graves with no spot yet)
local graveSpots={}
for _,deg in {0,30,-30,60,-60,90,-90,120,-120,150,-150} do
 local x,z=spot(16.5*math.sin(math.rad(deg)),16.5*math.cos(math.rad(deg)));table.insert(graveSpots,{x=x,z=z})
end
return {
 Snap=.5,GraveRadius=2.2,ZombieRadius=1.7,Overlap=.9,PlaceDistance=50,
 -- Where the server puts a monster by itself (PlacementRules.FindFree): the yard is tried every Step studs outward
 -- from its middle; Ease is how much of the usual spacing is asked for, pass after pass, when there is no room.
 Auto={Step=2,Ease={1,.75,.5,.3,.15,0}},
 Yard={MinX=-48,MaxX=48,MinZ=-48,MaxZ=48},
 Cemetery=Cemetery,
 -- The crypt (art/crypt-optimized-v1, 2026-11-14) 3 studs behind the cemetery's middle; Keep is the ground it covers
 -- (turned with it), Menu the spot in front of its steps that opens the crypt menu.
 Crypt={X=cryptX,Z=cryptZ,Yaw=Cemetery.Yaw,Scale=1.4,Keep=turned(0,1.4,8.6,9),Menu={X=menuX,Z=menuZ}},
 Walk=turned(0,-15.1,3,7.5),
 Pen={MinX=-40,MaxX=-14,MinZ=-36,MaxZ=-8},
 PenGate={From=-26,To=-20}, -- the opening in the pen's inner fence (x=MaxX)
 Blocked={
  {MinX=21,MaxX=34,MinZ=-32,MaxZ=-15}, -- treadmill
  {MinX=-8,MaxX=8,MinZ=-50,MaxZ=-42}, -- the gate (its leaves swing inward)
  {MinX=-16,MaxX=-8,MinZ=-50,MaxZ=-43}, {MinX=8,MaxX=16,MinZ=-50,MaxZ=-43}, -- the boards by the gate
  {MinX=-11,MaxX=-1,MinZ=43.5,MaxZ=50}, -- the cart at the back (the crates went on 2026-11-14)
  {MinX=42.5,MaxX=50,MinZ=-50,MaxZ=-40.5}, -- the scarecrow in the front left corner (the well went on 2026-11-14)
  {MinX=-43,MaxX=-30.5,MinZ=-41,MaxZ=-28.5}, -- the workbench in the front corner by the well (2026-11-14; was by the house door)
  {MinX=-18.5,MaxX=-5.5,MinZ=-28.5,MaxZ=-15.5}, -- the zombucks heap (Bank)
 },
 Bank={X=-12,Z=-22}, -- where income piles up until the owner collects it
 GraveSpots=graveSpots,
 LegacyField={X=-17,Z=-33,Columns=5,DX=-5,DZ=5},
 -- The house across the back-right corner (HouseConfig): one turned block covering walls, porch and bushes.
 Rotated={{X=-24.96,Z=24.96,Yaw=-45,HalfX=18.5,HalfZ=17}},
 -- The garden beds of the outer ring went on 2026-11-14 (owner: too much detail); the ring is plain yard again.
 Beds={},
 Guards={{X=2,Z=38},{X=0,Z=30},{X=4,Z=-12},{X=10,Z=-8}}, -- the first two between the house and the cemetery
}
