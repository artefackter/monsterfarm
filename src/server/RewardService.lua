local C=require(game.ReplicatedStorage.Shared.Config.RewardConfig)
local R={}
function R.Claim(d)
 local today=math.floor(os.time()/C.DaySeconds);local prev=math.floor(d.lastDailyAt/C.DaySeconds);if today==prev then return false end
 d.dailyStreak=prev==today-1 and d.dailyStreak%#C.Daily+1 or 1;d.lastDailyAt=os.time();local prize=C.Daily[d.dailyStreak]
 if prize.Coins then d.coins+=prize.Coins else d.vouchers[prize.Grave]=(d.vouchers[prize.Grave] or 0)+prize.Count end;return true
end
-- For the menu and the button on the screen: can today's gift be taken, and which day of the week it is.
function R.Status(d)
 local today=math.floor(os.time()/C.DaySeconds);local prev=math.floor((d.lastDailyAt or 0)/C.DaySeconds)
 if today==prev then return false,d.dailyStreak or 1 end
 return true,prev==today-1 and (d.dailyStreak or 0)%#C.Daily+1 or 1
end
return R
