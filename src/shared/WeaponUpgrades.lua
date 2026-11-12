-- Weapon upgrades (owner, 2026-11-10): every owned gun has four stats that are raised one level at a time for
-- zombucks and mutagen. Mutagen drops, by chance, from monsters killed in the ruins: more often and in bigger
-- portions the deeper the location; the boss always drops a lot. Used by the server (truth) and the menu (preview).
local C=require(script.Parent.Config.WeaponConfig)
local U={
 Stats={"Damage","FireRate","Magazine","Crit"},Max=10,
 Step={Damage=.12,FireRate=.06,Magazine=.15}, -- share of the base value added per level
 Crit={BaseChance=.05,ChancePerLevel=.03,BaseMult=2,MultPerLevel=.2},
 CoinBase={Deagle=500,Double=1000,AK=2500,MP5=6000,M4=12000,Pump=22000,M249=40000,AWP=60000},CoinGrowth=1.7,
 Drop={Chance={.10,.12,.14,.16,.18,.20},Amount={1,1,2,2,3,3},Boss=15},
}
local function number(v) return type(v)=="number" and v==v and v~=math.huge and v~=-math.huge end
function U.Migrate(d)
 d.mutagen=number(d.mutagen) and math.max(0,math.floor(d.mutagen)) or 0
 local clean={}
 for _,id in ipairs(C.Order) do
  local old=type(d.weaponUpgrades)=="table" and d.weaponUpgrades[id];local row={}
  for _,stat in ipairs(U.Stats) do local n=type(old)=="table" and old[stat];row[stat]=number(n) and math.clamp(math.floor(n),0,U.Max) or 0 end
  clean[id]=row
 end
 d.weaponUpgrades=clean;return d
end
function U.Level(d,id,stat)
 local row=d and type(d.weaponUpgrades)=="table" and d.weaponUpgrades[id];local n=type(row)=="table" and row[stat]
 return number(n) and math.clamp(math.floor(n),0,U.Max) or 0
end
-- The stat's value at a level. Crit returns chance and multiplier.
function U.Value(id,stat,level)
 local cfg=C[id]
 if stat=="Damage" then return math.floor(cfg.Damage*(1+U.Step.Damage*level)+.5)
 elseif stat=="FireRate" then return cfg.FireRate*(1+U.Step.FireRate*level)
 elseif stat=="Magazine" then return math.ceil(cfg.Magazine*(1+U.Step.Magazine*level)-1e-6)
 end
 return U.Crit.BaseChance+U.Crit.ChancePerLevel*level,U.Crit.BaseMult+U.Crit.MultPerLevel*level
end
-- Everything the gun does for this player right now.
function U.Stats_(d,id)
 local chance,mult=U.Value(id,"Crit",U.Level(d,id,"Crit"))
 return {Damage=U.Value(id,"Damage",U.Level(d,id,"Damage")),FireRate=U.Value(id,"FireRate",U.Level(d,id,"FireRate")),Magazine=U.Value(id,"Magazine",U.Level(d,id,"Magazine")),CritChance=chance,CritMult=mult}
end
-- Price of the step from `level` to the next: zombucks, mutagen.
function U.Cost(id,stat,level)
 return math.floor(U.CoinBase[id]*U.CoinGrowth^level/50+.5)*50,1+math.floor(level*1.5)
end
-- nil when the step can be bought, otherwise why not.
function U.Check(d,id,stat)
 if not C[id] or not table.find(U.Stats,stat) or not d.weapons or not d.weapons[id] then return "bad" end
 local level=U.Level(d,id,stat);if level>=U.Max then return "max" end
 local coins,mutagen=U.Cost(id,stat,level)
 if (d.coins or 0)<coins then return "coins" end
 if (d.mutagen or 0)<mutagen then return "mutagen" end
 return nil
end
function U.Buy(d,id,stat)
 if U.Check(d,id,stat) then return false end
 local level=U.Level(d,id,stat);local coins,mutagen=U.Cost(id,stat,level)
 d.coins-=coins;d.mutagen-=mutagen;d.weaponUpgrades[id][stat]=level+1
 return true,coins,mutagen
end
-- How much mutagen a killed road monster leaves (0 most of the time). `roll` is a number in [0,1).
function U.DropFor(biome,isBoss,night,roll)
 if isBoss then return U.Drop.Boss end
 biome=math.clamp(biome or 1,1,#U.Drop.Chance)
 if roll>=U.Drop.Chance[biome] then return 0 end
 return U.Drop.Amount[biome]*(night and 2 or 1)
end
return U
