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
P.PocketRadius=100;P.PocketGap=26;P.PocketNeck=8 -- the round floor; the opening in the wall; the passage to the round
for i,d in P.Districts do
 d.PocketSide=i%2==1 and 1 or -1;d.PocketS=d.To-P.PocketRadius;d.PocketX=d.PocketSide*(P.RoadHalf+P.PocketNeck+P.PocketRadius)
end
-- Which location's pocket (round or passage) the road-local point s, x is in, or nil.
function P.PocketAt(s,x,margin)
 margin=margin or 0
 for i,d in P.Districts do
  local ds,dx=s-d.PocketS,x-d.PocketX
  if ds*ds+dx*dx<=(P.PocketRadius+margin)^2 then return i end
  local out=x*d.PocketSide
  if math.abs(ds)<=P.PocketGap/2+margin and out>=P.RoadHalf-2 and out<=P.RoadHalf+P.PocketNeck+4 then return i end
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
