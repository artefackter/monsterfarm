-- Prestige (owner, 2026-11-12): start the farm over for a permanent income bonus.
-- Needs a house of level House and the price (PriceBase x Factor^prestige). It resets coins, monsters, graves and
-- coffins, the house, the treadmill and the zone upgrades; pets, the Monsterdex, weapons, shovels, mutagen, speed
-- and quests stay. Every prestige adds Bonus to the income multiplier (1 + Bonus x prestige).
local R={Bonus=.5,House=5,PriceBase=10000000,Factor=3}
function R.Level(d) return type(d.prestige)=="number" and d.prestige==d.prestige and math.max(0,math.floor(d.prestige)) or 0 end
function R.Mult(d) return 1+R.Bonus*R.Level(d) end
function R.MultAt(level) return 1+R.Bonus*level end
function R.Cost(d) return R.PriceBase*R.Factor^R.Level(d) end
return R
