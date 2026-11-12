-- Merging, as in Auto Chess: three identical zombies become one with a star more. Pure data, used by both server and menu.
local C=require(script.Parent.Config.ZombieConfig)
local R={}
local ZONE_RANK={Field=1,Guards=2,Crypt=3}
function R.Stars(z)
 local s=type(z)=="table" and z.stars
 return type(s)=="number" and C.Stars.Income[s] and s or 1
end
function R.Size(z) return (C.RaritySize[z.tier] or 1)*C.Stars.Size[R.Stars(z)] end
function R.Rate(z) return C.Income[z.tier]*(C.Mutations[z.mutation] or 1)*C.Stars.Income[R.Stars(z)] end
function R.Power(z) return z.tier*C.Stars.Power[R.Stars(z)] end
local function mutation(z) return C.Mutations[z.mutation] or 1 end
function R.Free(z) return not z.carriedBy and not z.pendingTransfer end
function R.Match(a,b) return a.type==b.type and a.tier==b.tier and R.Stars(a)==R.Stars(b) end
function R.Check(list)
 if type(list)~="table" or #list~=3 then return false end
 local a,b,c=list[1],list[2],list[3]
 if a==b or a==c or b==c then return false end
 for _,z in ipairs(list) do if not R.Free(z) then return false end end
 return R.Match(a,b) and R.Match(a,c) and R.Stars(a)<C.Stars.Max
end
-- The zombie that survives: the best mutation is kept, so a Rainbow is never wasted.
function R.Keeper(list)
 local best=list[1]
 for _,z in ipairs(list) do if mutation(z)>mutation(best) then best=z end end
 return best
end
-- The result stands where the most useful of the three stood, so merging never empties a working spot.
function R.Place(list)
 local best=list[1]
 for _,z in ipairs(list) do if (ZONE_RANK[z.zone] or 9)<(ZONE_RANK[best.zone] or 9) then best=z end end
 return best.zone,best.slot
end
-- Whatever a player would pick by hand: the best mutation, plus the two least valuable, taking crypt spares before workers.
function R.Pick(members)
 local keeper=R.Keeper(members)
 local rest={}
 for _,z in ipairs(members) do if z~=keeper then table.insert(rest,z) end end
 table.sort(rest,function(a,b)
  if mutation(a)~=mutation(b) then return mutation(a)<mutation(b) end
  return (ZONE_RANK[a.zone] or 9)>(ZONE_RANK[b.zone] or 9)
 end)
 return {keeper,rest[1],rest[2]}
end
-- Everything that can still gain a star, sorted so that ready triples and the richest come first.
function R.Groups(zombies)
 local map,list={},{}
 for _,z in ipairs(zombies) do
  if R.Free(z) and R.Stars(z)<C.Stars.Max then
   local key=z.type..":"..z.tier..":"..R.Stars(z)
   local g=map[key]
   if not g then g={type=z.type,tier=z.tier,stars=R.Stars(z),members={}};map[key]=g;table.insert(list,g) end
   table.insert(g.members,z)
  end
 end
 table.sort(list,function(a,b)
  local ra,rb=#a.members>=3,#b.members>=3
  if ra~=rb then return ra end
  if a.tier~=b.tier then return a.tier>b.tier end
  if a.stars~=b.stars then return a.stars>b.stars end
  return a.type<b.type
 end)
 return list
end
function R.Ready(zombies)
 local n=0
 for _,g in ipairs(R.Groups(zombies)) do n+=math.floor(#g.members/3) end
 return n
end
-- Inventory: richest first, then display rarity; stable IDs prevent cards jumping on refresh.
function R.SortByIncome(zombies)
 local rank={Common=1,Uncommon=2,Rare=3,Epic=4,Legendary=5,Mythic=6}
 local sorted=table.clone(zombies)
 table.sort(sorted,function(a,b)
  local incomeA,incomeB=R.Rate(a),R.Rate(b)
  if incomeA~=incomeB then return incomeA>incomeB end
  local rarityA,rarityB=rank[C.Tiers[a.tier]] or 0,rank[C.Tiers[b.tier]] or 0
  if rarityA~=rarityB then return rarityA>rarityB end
  return tostring(a.id)<tostring(b.id)
 end)
 return sorted
end
return R
