-- Daily quest rules. Pure data in, data out, so migration and claims can be tested without a player.
local C=require(script.Parent.Config.QuestConfig)
local R={Version=4}
local function number(v) return type(v)=="number" and v==v and v~=math.huge and v~=-math.huge end
function R.Day(now) return math.floor((now or os.time())/C.DaySeconds) end
function R.SecondsLeft(now) return C.DaySeconds-((now or os.time())%C.DaySeconds) end
local function goalFor(q,income)
 if q.Goal then return q.Goal end
 return math.clamp(math.floor(income*q.IncomeSeconds),q.GoalMin,q.GoalMax)
end
local function rewardFor(slot,income)
 local r=C.Rewards[slot];return math.clamp(math.floor(income*r.Seconds),r.Min,C.RewardMax)
end
-- The same player gets the same quests all day, on any server. ctx holds income and the Needs flags.
function R.Generate(day,userId,ctx)
 ctx=ctx or {};local income=number(ctx.income) and math.max(ctx.income,0) or 0
 local rng=Random.new(day*1000003+userId%1000003);local items={}
 for slot,pool in ipairs(C.Slots) do
  local open={};for _,id in ipairs(pool) do local need=C.Quests[id].Needs;if not need or ctx[need] then table.insert(open,id) end end
  if #open==0 then open=pool end
  local id=open[rng:NextInteger(1,#open)]
  table.insert(items,{id=id,goal=goalFor(C.Quests[id],income),progress=0,reward=rewardFor(slot,income),claimed=false})
 end
 local bonus=C.Bonus[1];for _,band in ipairs(C.Bonus) do if income>=band.MinIncome then bonus=band end end
 return {day=day,items=items,bonus={grave=bonus.Grave,count=bonus.Count},bonusClaimed=false}
end
local function valid(q)
 if type(q)~="table" or not number(q.day) or type(q.items)~="table" or #q.items~=#C.Slots or type(q.bonusClaimed)~="boolean" then return false end
 if type(q.bonus)~="table" or type(q.bonus.grave)~="string" or not number(q.bonus.count) then return false end
 for _,item in ipairs(q.items) do
  if type(item)~="table" or not C.Quests[item.id] or not number(item.goal) or item.goal<=0 or not number(item.progress) or not number(item.reward) or type(item.claimed)~="boolean" then return false end
 end
 return true
end
-- Idempotent. Broken quest data is dropped and regenerated; it never blocks loading a profile.
function R.Migrate(d)
 d.peakIncome=number(d.peakIncome) and math.max(d.peakIncome,0) or 0
 if not number(d.referredBy) then d.referredBy=nil end
 d.referralPaid=d.referralPaid==true
 if not valid(d.quests) then d.quests=nil end
 d.version=math.max(number(d.version) and d.version or 1,R.Version);return d
end
-- Returns the quests this event just finished, so each one announces itself exactly once.
function R.Advance(q,event,n)
 local done={};if not number(n) or n<=0 then return done end
 for _,item in ipairs(q.items) do
  if C.Quests[item.id].Event==event and item.progress<item.goal then
   item.progress=math.min(item.goal,item.progress+n)
   if item.progress>=item.goal then table.insert(done,item) end
  end
 end
 return done
end
function R.Claim(q,id)
 for _,item in ipairs(q.items) do
  if item.id==id then
   if item.claimed or item.progress<item.goal then return nil end
   item.claimed=true;return item.reward
  end
 end
end
function R.ClaimBonus(q)
 if q.bonusClaimed then return nil end
 for _,item in ipairs(q.items) do if not item.claimed then return nil end end
 q.bonusClaimed=true;return q.bonus
end
function R.Claimable(q)
 local n,all=0,true
 for _,item in ipairs(q.items) do
  if not item.claimed then all=false;if item.progress>=item.goal then n+=1 end end
 end
 if all and not q.bonusClaimed then n+=1 end
 return n
end
function R.Show(item,value)
 local div=C.Quests[item.id].Display or 1;return math.floor(value/div)
end
return R
