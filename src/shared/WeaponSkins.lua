-- Cosmetic finishes; selection is validated against the owned weapon on the server.
local C=require(script.Parent.Config.WeaponConfig)
local S={Order={"Default","Asiimov","GoldenDragon","Cyberpunk"},
 Styles={Asiimov={Weapon="AK",Asset="Kalash_Asiimov"},GoldenDragon={Weapon="AK",Asset="Kalash_GoldenDragon"},Cyberpunk={Weapon="AK",Asset="Kalash_Cyberpunk"}}}
function S.Valid(weapon,skin)
 if not table.find(C.Order,weapon) then return false end
 return skin=="Default" or (S.Styles[skin]~=nil and S.Styles[skin].Weapon==weapon)
end
function S.Migrate(d)
 local old=type(d.weaponSkins)=="table" and d.weaponSkins or {};local clean={}
 for _,id in C.Order do local value=old[id];clean[id]=type(value)=="string" and S.Valid(id,value) and value or "Default" end
 d.weaponSkins=clean;return d
end
function S.Select(d,weapon,skin)
 if type(d.weapons)~="table" or d.weapons[weapon]~=true or not S.Valid(weapon,skin) then return false end
 if type(d.weaponSkins)~="table" then S.Migrate(d) end
 d.weaponSkins[weapon]=skin;return true
end
function S.Asset(weapon,skin)
 local finish=S.Styles[skin];if finish and finish.Weapon==weapon then return finish.Asset end
 return C[weapon] and (C[weapon].ArtAsset or "V3_Gun"..weapon)
end
return S
