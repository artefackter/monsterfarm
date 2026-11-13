local C=require(script.Parent.Config.WeaponConfig)
local R={}
function R.Migrate(d)
 local old=type(d.weapons)=="table" and d.weapons or {};local clean={Deagle=true};local legacy={Pistol="Deagle",Rifle="AK",Shotgun="M4"};for oldId,newId in legacy do if old[oldId]==true then clean[newId]=true end end;d.equippedWeapon=legacy[d.equippedWeapon] or d.equippedWeapon
 for _,id in ipairs(C.Order) do if old[id]==true then clean[id]=true end end
 d.weapons=clean;require(script.Parent.WeaponSkins).Migrate(d);R.MigrateKills(d);if type(d.equippedWeapon)~="string" or not clean[d.equippedWeapon] then d.equippedWeapon="Deagle" end
 d.version=math.max(type(d.version)=="number" and d.version or 1,C.Version);return d
end
-- Monsters killed in each ruins location (the guns unlock with them, WeaponConfig.Unlock).
function R.MigrateKills(d)
 local old=type(d.ruinKills)=="table" and d.ruinKills or {};local clean={}
 for i=1,#require(script.Parent.Config.RoadProgression).Districts do local n=old[i];clean[i]=type(n)=="number" and n==n and math.max(0,math.floor(n)) or 0 end
 d.ruinKills=clean;return d
end
-- The guns this player has earned but does not have yet.
function R.Earned(d)
 local out={}
 for _,id in ipairs(C.Order) do local u=C.Unlock[id];if u and not (d.weapons and d.weapons[id]) and ((d.ruinKills or {})[u.Location] or 0)>=u.Kills then table.insert(out,id) end end
 return out
end
function R.ValidAim(v)
 return typeof(v)=="Vector3" and v.X==v.X and v.Y==v.Y and v.Z==v.Z and math.abs(v.X)<C.AimLimit and math.abs(v.Y)<C.AimLimit and math.abs(v.Z)<C.AimLimit
end
return R
