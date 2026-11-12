local C=require(game.ReplicatedStorage.Shared.Config.RewardConfig)
local R={}
function R.Claim(d)
 local today=math.floor(os.time()/C.DaySeconds);local prev=math.floor(d.lastDailyAt/C.DaySeconds);if today==prev then return false end
 d.dailyStreak=prev==today-1 and d.dailyStreak%#C.Daily+1 or 1;d.lastDailyAt=os.time();local prize=C.Daily[d.dailyStreak]
 if prize.Coins then d.coins+=prize.Coins else d.vouchers[prize.Grave]=(d.vouchers[prize.Grave] or 0)+prize.Count end;return true
end return R
