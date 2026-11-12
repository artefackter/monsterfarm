local C=require(script.Parent.Config.WeaponConfig)
local R={}
function R.Migrate(d)
 local old=type(d.weapons)=="table" and d.weapons or {};local clean={Deagle=true};local legacy={Pistol="Deagle",Rifle="AK",Shotgun="M4"};for oldId,newId in legacy do if old[oldId]==true then clean[newId]=true end end;d.equippedWeapon=legacy[d.equippedWeapon] or d.equippedWeapon
 for _,id in ipairs(C.Order) do if old[id]==true then clean[id]=true end end
 d.weapons=clean;require(script.Parent.WeaponSkins).Migrate(d);if type(d.equippedWeapon)~="string" or not clean[d.equippedWeapon] then d.equippedWeapon="Deagle" end
 d.version=math.max(type(d.version)=="number" and d.version or 1,C.Version);return d
end
function R.ValidAim(v)
 return typeof(v)=="Vector3" and v.X==v.X and v.Y==v.Y and v.Z==v.Z and math.abs(v.X)<C.AimLimit and math.abs(v.Y)<C.AimLimit and math.abs(v.Z)<C.AimLimit
end
return R
