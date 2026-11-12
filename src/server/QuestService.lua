-- Daily quests: picks them, counts events from the rest of the game, pays out on claim.
local S=game.ReplicatedStorage.Shared
local R=require(S.QuestRules)
local QC=require(S.Config.QuestConfig);local ZoneC=require(S.Config.ZoneConfig);local PetC=require(S.Config.PetConfig)
local D=require(script.Parent.DataService);local Z=require(script.Parent.ZombieService)
local Q={}
local ZONES={"Field","Graves","Guards","Crypt"}
local function context(d)
 local canUpgrade=false
 for _,zone in ipairs(ZONES) do if Z.Cap(d,zone)<math.min(ZoneC[zone].Max,require(S.HouseRules).Limit(d,zone)) then canUpgrade=true end end
 local income=Z.Income(d,true)
 return {income=income,canUpgrade=canUpgrade,canHatch=income>=QC.HatchMinIncome and #(d.pets or {})<PetC.Inventory,hasField=income>0}
end
-- Also handles the midnight rollover for a player who stays online through it.
function Q.Ensure(p,d)
 local today=R.Day()
 if type(d.quests)=="table" and d.quests.day==today then return false end
 d.quests=R.Generate(today,p.UserId,context(d));return true
end
function Q.Track(p,event,n)
 local d=D.Profiles[p];if not d then return end
 Q.Ensure(p,d)
 for _,item in ipairs(R.Advance(d.quests,event,n or 1)) do
  game.ReplicatedStorage.Remotes.Notice:FireClient(p,"questDone",{id=item.id,goal=R.Show(item,item.goal)})
 end
end
function Q.Claim(p,d,id)
 Q.Ensure(p,d)
 if id=="bonus" then
  local bonus=R.ClaimBonus(d.quests);if not bonus then return false end
  d.vouchers[bonus.grave]=(d.vouchers[bonus.grave] or 0)+bonus.count;return true
 end
 local reward=R.Claim(d.quests,id);if not reward then return false end
 d.coins+=reward;return true
end
return Q
