-- Points shown on signs; actual movement derives from RoadRules.Speed.
-- Mutants of a location run exactly as fast as a runner with that location's recommended speed (900, 10K, 40K,
-- 170K, 700K, 2.5M): the lower threshold. Slower than that, they catch you; carrying a grave, you need more (owner, 2026-11-09).
-- Locations v4 (owner, 2026-11-12): every location ends in an amphitheatre, the arena of its own boss, and spawns
-- only its own two kinds of monsters (RoadMonsterRules.Districts). The first locations are longer so the regular
-- stretch before the arena keeps its length.
local P={Length=3900,EnemySpeedRatio=1,ArenaRadius=62,ArenaExit=18,Districts={
-- The owner's order (reference picture, 2026-11-09): forest, dark forest, hospital, village, cultist cave, factory.
{Id="Forest",From=0,To=420,RecommendedSpeed=900},
{Id="DarkForest",From=420,To=860,RecommendedSpeed=10000},
{Id="Hospital",From=860,To=1380,RecommendedSpeed=40000},
{Id="Village",From=1380,To=1980,RecommendedSpeed=170000},
{Id="Cave",From=1980,To=2800,RecommendedSpeed=700000},
{Id="Factory",From=2800,To=3900,RecommendedSpeed=2500000},
}}
-- The old amphitheatre marks across the road (the boss arena until 2026-11-13; now a pocket beside it, below). The
-- regular stretch of graves and monsters still ends before ArenaFrom.
for _,d in P.Districts do
 d.Arena=d.To-P.ArenaExit-P.ArenaRadius -- centre, in studs along the road
 d.ArenaFrom=d.Arena-P.ArenaRadius;d.ArenaTo=d.Arena+P.ArenaRadius
end
-- Boss arenas v5 (owner, 2026-11-13: "the boss arena should go off to the side, not stand on the road"): a round pocket
-- beside the road near the location's end, left and right in turn, reached through an opening in the road wall.
-- The old marks (Arena, ArenaFrom, ArenaTo) stay: the regular stretch still ends before them.
P.RoadHalf=70 -- half the road's width (RoadConfig.Width / 2)
-- As big as the Blood Moon arena since 2026-11-13 (owner: "make the boss fight as big as the Blood Moon arena"):
-- radius 100, its middle PocketRadius before the location's end so the round stays beside its own location.
P.PocketRadius=100;P.PocketGap=26 -- the round floor; the corridor's width
-- A slanted way in (owner, 2026-11-14: "the entrance at about 70 degrees, on the diagonal"): a corridor PocketNeck
-- studs long leaves the road at PocketAngle degrees, leaning forward along the road, and opens into the round.
-- In road terms (s along the road, x across it) it runs along (DirS, DirX) from DoorS on the road wall; the opening
-- in the wall is DoorWidth long (the corridor's width cut on the slant).
P.PocketNeck=26;P.PocketAngle=70
local ca,sa=math.cos(math.rad(P.PocketAngle)),math.sin(math.rad(P.PocketAngle))
P.DoorWidth=P.PocketGap/sa
for i,d in P.Districts do
 d.PocketSide=i%2==1 and 1 or -1;d.PocketS=d.To-P.PocketRadius
 d.DirS,d.DirX=ca,d.PocketSide*sa
 d.DoorS=d.PocketS-(P.PocketNeck+P.PocketRadius)*ca
 d.PocketX=d.PocketSide*(P.RoadHalf+(P.PocketNeck+P.PocketRadius)*sa)
end
-- A point in the corridor's frame: "along" it from the opening in the road wall (negative: out on the road) and
-- "across" it. Returns road s, x. DoorFrame is the way back.
function P.DoorPoint(i,along,across)
 local d=P.Districts[i];across=across or 0;local c,n=d.DirS,math.abs(d.DirX)
 return d.DoorS+along*c-across*n,d.PocketSide*(P.RoadHalf+along*n+across*c)
end
-- Where the road-local point s, x lies in the corridor's frame (along, across), as DoorPoint takes them.
function P.DoorFrame(i,s,x)
 local d=P.Districts[i];local rs,ro=s-d.DoorS,x*d.PocketSide-P.RoadHalf
 local c,n=d.DirS,math.abs(d.DirX)
 return rs*c+ro*n,-rs*n+ro*c
end
-- Is a point given relative to the round's middle (ds along the road, dx across) on the side the corridor comes in,
-- within its width (plus margin)?
function P.FacesDoor(i,ds,dx,margin)
 local d=P.Districts[i];local into=ds*d.DirS+dx*d.DirX;local across=-ds*d.DirX+dx*d.DirS
 return into<0 and math.abs(across)<P.PocketGap/2+(margin or 0)
end
-- Which location's pocket (round or passage) the road-local point s, x is in, or nil.
function P.PocketAt(s,x,margin)
 margin=margin or 0
 for i,d in P.Districts do
  local ds,dx=s-d.PocketS,x-d.PocketX
  if ds*ds+dx*dx<=(P.PocketRadius+margin)^2 then return i end
  local along,across=P.DoorFrame(i,s,x)
  if math.abs(across)<=P.PocketGap/2+margin and along>=-2 and along<=P.PocketNeck+4 then return i end
 end
 return nil
end
function P.Index(s)
 for i,d in P.Districts do if s<d.To then return i end end
 return #P.Districts
end
-- Which location's arena covers s (with an optional margin), or nil.
function P.ArenaAt(s,margin)
 margin=margin or 0
 for i,d in P.Districts do if s>=d.ArenaFrom-margin and s<=d.ArenaTo+margin then return i end end
 return nil
end
function P.EnemySpeed(i,roadRules)
 return roadRules.Speed({speedPoints=P.Districts[i].RecommendedSpeed})*P.EnemySpeedRatio
end
return P
