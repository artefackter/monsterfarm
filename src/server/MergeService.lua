-- Server side of merging. The client only names three ids; everything about them is checked against the profile here.
local R=require(game.ReplicatedStorage.Shared.MergeRules)
local Z=require(script.Parent.ZombieService);local D=require(script.Parent.DataService)
local M={}
function M.Try(d,ids)
 if type(ids)~="table" then return nil end
 local list={}
 for i=1,3 do
  local id=ids[i]
  if type(id)~="string" or #id>64 then return nil end
  local z=Z.Find(d,id)
  if not z then return nil end
  list[i]=z
 end
 if not R.Check(list) then return nil end
 local keeper=R.Keeper(list);local zone,slot=R.Place(list)
 -- No yields from here on, so the three zombies and the new one can never both exist.
 for _,z in ipairs(list) do
  Z.Remove(z.id)
  if z~=keeper then
   local _,i=Z.Find(d,z.id);table.remove(d.zombies,i);D.Claims[z.id]=nil
  end
 end
 local result=R.Result(list);keeper.tier=result.tier;keeper.stars=result.stars;keeper.zone=zone;keeper.slot=slot
 return keeper
end
return M
