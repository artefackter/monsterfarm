-- Road rules with no world attached: speed, the treadmill, which grave appears, how fast a carrier can honestly be.
local C=require(script.Parent.Config.RoadConfig)
local R={Version=9}
local function number(v) return type(v)=="number" and v==v and v~=math.huge and v~=-math.huge end
function R.Migrate(d)
 d.speed=number(d.speed) and math.clamp(d.speed,C.BaseSpeed,C.MaxSpeed) or C.BaseSpeed
 d.treadmill=number(d.treadmill) and C.Treadmill[d.treadmill] and d.treadmill or 1
 d.traps=number(d.traps) and math.clamp(math.floor(d.traps),0,C.Trap.MaxStock) or 0
 d.version=math.max(number(d.version) and d.version or 1,R.Version);return d
end
function R.Speed(d)
 local points=number(d.speedPoints) and math.max(0,d.speedPoints) or 0
 return math.min(C.MaxSpeed,C.BaseSpeed+C.SpeedLog*math.log10(1+points/C.SpeedDivisor))
end
function R.WalkSpeed(d) return d.slowMode and math.min(C.SlowSpeed,R.Speed(d)) or R.Speed(d) end -- slow mode walks, whatever the training
function R.Level(d) return number(d.treadmill) and C.Treadmill[d.treadmill] and d.treadmill or 1 end
function R.Rate(d) return C.Treadmill[R.Level(d)].Rate end
function R.Next(d) return C.Treadmill[R.Level(d)+1] end
function R.Train(d,seconds)
 local time=(d.trainingRemainder or 0)+math.max(0,seconds);local steps=math.floor(time/C.StepSeconds+1e-8);d.trainingRemainder=time-steps*C.StepSeconds
 d.speedPoints=(d.speedPoints or 0)+steps*R.Rate(d);return steps*R.Rate(d)
end
function R.Upgrade(d)
 local nextLevel=R.Next(d)
 if not nextLevel or d.coins<nextLevel.Price then return false end
 d.coins-=nextLevel.Price;d.treadmill=R.Level(d)+1;return true
end
function R.Roll(pool,roll)
 local total=0;local names={}
 for name,weight in pairs(pool) do total+=weight;table.insert(names,name) end
 table.sort(names) -- pairs order isn't fixed, and the same roll has to mean the same grave
 local at=roll*total
 for _,name in ipairs(names) do at-=pool[name];if at<=0 then return name end end
 return names[#names]
end
function R.CarrySpeed(speed,grave) return speed*(C.Carry[grave] or 1) end
-- Nobody carries a grave faster than their own legs allow: the margin only forgives lag.
function R.HonestTrip(distance,speed,grave,seconds) return seconds>=distance/(R.CarrySpeed(speed,grave)*1.6) end
return R
