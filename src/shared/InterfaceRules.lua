local S=script.Parent;local C=require(S.Config.InterfaceConfig);local Z=require(S.Config.ZombieConfig)
local R={Version=10}
function R.Migrate(d)
 d.settings=type(d.settings)=="table" and d.settings or {}
 for key,value in C.Settings do if type(d.settings[key])~=type(value) then d.settings[key]=value end end
 for _,key in {"MusicVolume","SfxVolume"} do local v=d.settings[key];d.settings[key]=v==v and math.clamp(v,0,1) or C.Settings[key] end
 d.settings.ShowRanges=d.showRanges~=false
 d.receipts=type(d.receipts)=="table" and d.receipts or {};d.upgradeCredits=type(d.upgradeCredits)=="table" and d.upgradeCredits or {}
 d.dexClaims=d.dexClaims or {};d.version=math.max(d.version or 1,R.Version);return d
end
function R.Count(d,page)
 local n=0;for _,entry in require(S.MonsterCollection).Catalog do if (d.zombiedex or {})[entry.Id..":"..page]==true then n+=1 end end;return n
end
function R.DexReward(page,threshold)
 local i=table.find(C.Pages,page);if not i or not table.find(C.Thresholds,threshold) then return end
 return {coins=threshold==1 and C.DexCoins[i] or threshold==4 and C.DexCoins[i]*10 or 0,speed=threshold==3 and C.DexSpeed[i] or threshold==4 and C.DexSpeed[i]*2 or 0,shovel=threshold==3 and C.DexShovels[i] or nil}
end
function R.ClaimDex(d,page,threshold)
 local reward=R.DexReward(page,threshold);local key=page..":"..tostring(threshold)
 if not reward or R.Count(d,page)<threshold or d.dexClaims[key] then return false end
 d.dexClaims[key]=true;d.coins+=reward.coins;d.speedPoints+=reward.speed
 if reward.shovel then d.shovels[reward.shovel]=true;d.equippedShovel=require(S.ActionRules).Best(d) end
 return true
end
function R.ClaimGift(d,groupId,isMember)
 if groupId<=0 or not isMember or d.freeGiftClaimed then return false end
 d.freeGiftClaimed=true;d.speedPoints+=C.FreeGift.Speed;d.vouchers[C.FreeGift.Grave]=(d.vouchers[C.FreeGift.Grave] or 0)+1;return true
end
function R.Receipt(d,purchaseId,key,save)
 if type(purchaseId)~="string" or purchaseId=="" or not C.Products[key] then return false end
 if not d.receipts[purchaseId] then d.receipts[purchaseId]=key;d.upgradeCredits[key]=(d.upgradeCredits[key] or 0)+1 end
 -- A failed save keeps the pending grant in memory; retry saves it without granting twice.
 return save()==true
end
function R.HomeReason(s)
 if not s.alive then return "homeUnavailable" end
 if s.road then return "homeRoad" end
 if s.carry then return "homeCarry" end
 if s.dig then return "homeDig" end
 if s.knockout then return "homeKO" end
 if s.trap then return "homeTrap" end
 if s.cooldown>0 then return "homeCooldown" end
end
return R
