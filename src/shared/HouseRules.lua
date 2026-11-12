-- House levels. Pure data, used by the server, the ground tiles and the menu alike.
local C=require(script.Parent.Config.HouseConfig);local ZoneC=require(script.Parent.Config.ZoneConfig);local UC=require(script.Parent.Config.UpgradeConfig)
local R={Version=5,Max=#C.Levels}
function R.Cap(d,zone) return math.min(ZoneC[zone].Max,ZoneC[zone].Start+((d.upgrades or {})[zone] or 0)*UC[zone].Step) end
function R.Level(d) return type(d.houseLevel)=="number" and C.Levels[d.houseLevel] and d.houseLevel or 1 end
function R.Limit(d,zone) return C.Levels[R.Level(d)].Limits[zone] end
-- The house level a player has to reach before this zone can grow again; nil means nothing stands in the way.
function R.Need(d,zone)
 local cap=R.Cap(d,zone)
 if cap>=ZoneC[zone].Max or cap<R.Limit(d,zone) then return nil end
 for level=R.Level(d)+1,R.Max do if C.Levels[level].Limits[zone]>cap then return level end end
end
-- Nobody loses anything to the new rule: an old farm starts at the level its upgrades already earned.
function R.Migrate(d)
 if not (type(d.houseLevel)=="number" and C.Levels[d.houseLevel]) then
  local level=R.Max
  for candidate=R.Max,1,-1 do
   local fits=true
   for _,zone in ipairs(C.Zones) do if R.Cap(d,zone)>C.Levels[candidate].Limits[zone] then fits=false end end
   if fits then level=candidate end
  end
  d.houseLevel=level
 end
 if type(d.houseEnds)~="number" or d.houseEnds~=d.houseEnds or d.houseLevel>=R.Max then d.houseEnds=nil end
 d.version=math.max(type(d.version)=="number" and d.version or 1,R.Version);return d
end
function R.Remaining(d,now)
 return d.houseEnds and math.max(0,d.houseEnds-(now or os.time())) or 0
end
function R.Next(d) return C.Levels[R.Level(d)+1] end
function R.Start(d,now)
 local nextLevel=R.Next(d)
 if not nextLevel or d.houseEnds or d.coins<nextLevel.Price then return false end
 d.coins-=nextLevel.Price;d.houseEnds=(now or os.time())+nextLevel.Seconds;return true
end
-- Returns true once, on the moment the building work ends.
function R.Finish(d,now)
 if not d.houseEnds or (now or os.time())<d.houseEnds then return false end
 d.houseEnds=nil;d.houseLevel=math.min(R.Max,R.Level(d)+1);return true
end
return R
