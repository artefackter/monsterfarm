-- Points shown on signs; actual movement derives from RoadRules.Speed.
-- Mutants of a location run exactly as fast as a runner with that location's recommended speed (900, 10K, 40K,
-- 170K, 700K, 2.5M): the lower threshold. Slower than that, they catch you; carrying a grave, you need more (owner, 2026-11-09).
local P={Length=3325,EnemySpeedRatio=1,Districts={
-- The owner's order (reference picture, 2026-11-09): forest, dark forest, hospital, village, cultist cave, factory.
{Id="Forest",From=0,To=160,RecommendedSpeed=900},
{Id="DarkForest",From=160,To=400,RecommendedSpeed=10000},
{Id="Hospital",From=400,To=760,RecommendedSpeed=40000},
{Id="Village",From=760,To=1300,RecommendedSpeed=170000},
{Id="Cave",From=1300,To=2110,RecommendedSpeed=700000},
{Id="Factory",From=2110,To=3325,RecommendedSpeed=2500000},
}}
function P.Index(s)
 for i,d in P.Districts do if s<d.To then return i end end
 return #P.Districts
end
function P.EnemySpeed(i,roadRules)
 return roadRules.Speed({speedPoints=P.Districts[i].RecommendedSpeed})*P.EnemySpeedRatio
end
return P
