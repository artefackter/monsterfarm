-- Points shown on signs; actual movement derives from RoadRules.Speed.
-- Mutants of a location run exactly as fast as a runner with that location's recommended speed (900, 10K, 40K,
-- 170K, 700K, 2.5M): the lower threshold. Slower than that, they catch you; carrying a grave, you need more (owner, 2026-11-09).
-- Locations v4 (owner, 2026-11-12): every location ends in an amphitheatre, the arena of its own boss, and spawns
-- only its own two kinds of monsters (RoadMonsterRules.Districts). The first locations are longer so the regular
-- stretch before the arena keeps its length.
local P={Length=3900,EnemySpeedRatio=1,ArenaRadius=62,ArenaExit=18,Districts={
-- The owner's order since 2026-11-15 (road reskin, art/road-reskin-screenshot-concepts-v5): dark forest, backrooms,
-- abandoned city, abandoned village, Parasitown, abandoned cave (the blood mine). Lengths and speeds stay by place.
{Id="DarkForest",From=0,To=420,RecommendedSpeed=900},
{Id="Backrooms",From=420,To=860,RecommendedSpeed=10000},
{Id="City",From=860,To=1380,RecommendedSpeed=40000},
{Id="Village",From=1380,To=1980,RecommendedSpeed=170000},
{Id="Parasitown",From=1980,To=2800,RecommendedSpeed=700000},
{Id="Cave",From=2800,To=3900,RecommendedSpeed=2500000},
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
P.PocketRadius=100
-- Boss arenas v6 (owner, 2026-11-15, a circle drawn on a screenshot: "so the boss and its arena can be seen; where it
-- meets the road it should just be an arc of the circle"): no corridor any more. The round stands right against the
-- road, PocketOverlap studs of it reaching into the road, its middle PocketBeforeEnd studs before the location's end.
-- Where the circle crosses the road it is open: the road wall stops at the circle and the boundary between road and
-- arena is the circle's arc (a barrier stands along that arc while a fight is on). Seen from the road, the arena and
-- its sleeping boss are in plain view.
-- The old corridor frame is kept for the code that speaks in it: "along" runs straight across the road into the arena
-- (DirS 0, DirX the side), from the road's edge at DoorS (the opening's middle); DoorWidth is the opening's length
-- along the road wall's line; PocketGap is the same, for code that checks "in line with the way in".
P.PocketOverlap=20;P.PocketBeforeEnd=55
P.PocketNeck=0;P.PocketAngle=90
P.DoorWidth=2*math.sqrt(P.PocketRadius^2-(P.PocketRadius-P.PocketOverlap-2)^2) -- at the road wall (2 studs out)
P.PocketGap=P.DoorWidth
for i,d in P.Districts do
 d.PocketSide=i%2==1 and 1 or -1
 d.DirS,d.DirX=0,d.PocketSide
 d.PocketS=math.min(d.To-P.PocketBeforeEnd,P.Length-60)
 d.DoorS=d.PocketS
 d.PocketX=d.PocketSide*(P.RoadHalf+P.PocketRadius-P.PocketOverlap)
end
-- A point in the arena's frame: "along" from the road's edge straight into the arena (negative: out on the road) and
-- "across" along the road. Returns road s, x. DoorFrame is the way back.
function P.DoorPoint(i,along,across)
 local d=P.Districts[i];across=across or 0;local c,n=d.DirS,math.abs(d.DirX)
 return d.DoorS+along*c-across*n,d.PocketSide*(P.RoadHalf+along*n+across*c)
end
-- Where the road-local point s, x lies in that frame (along, across), as DoorPoint takes them.
function P.DoorFrame(i,s,x)
 local d=P.Districts[i];local rs,ro=s-d.DoorS,x*d.PocketSide-P.RoadHalf
 local c,n=d.DirS,math.abs(d.DirX)
 return rs*c+ro*n,-rs*n+ro*c
end
-- A spot on the road just clear of the arena's arc, `across` studs along the road from its middle.
function P.OutsidePoint(i,across,clear)
 return P.DoorPoint(i,-P.PocketOverlap-(clear or 10),across)
end
-- Is a point given relative to the round's middle (ds along the road, dx across) on the road's side of the arena: on
-- the road, or within margin of its wall? That part of the circle is open.
function P.FacesDoor(i,ds,dx,margin)
 local d=P.Districts[i]
 return (d.PocketX+dx)*d.PocketSide<P.RoadHalf+(margin or 0)
end
-- Which location's arena the road-local point s, x is in (with an optional margin), or nil.
function P.PocketAt(s,x,margin)
 margin=margin or 0
 for i,d in P.Districts do
  local ds,dx=s-d.PocketS,x-d.PocketX
  if ds*ds+dx*dx<=(P.PocketRadius+margin)^2 then return i end
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
