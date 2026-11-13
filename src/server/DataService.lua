local DSS=game:GetService("DataStoreService")
local Run=game:GetService("RunService")
local C=require(game.ReplicatedStorage.Shared.Config.ShopConfig)
local L=require(game.ReplicatedStorage.Shared.Locale)
local D={Profiles={},Busy={},Claims={}}
local memory=Run:IsStudio() and C.StudioMemory
local store=not memory and DSS:GetDataStore("GrowAMonster_v1");local owners=not memory and DSS:GetDataStore("GrowAMonsterOwners_v1")
local job=game.JobId~="" and game.JobId or game:GetService("HttpService"):GenerateGUID(false)
local function retry(fn) for i=1,C.Retries do local ok,v=pcall(fn);if ok then return true,v end;warn("Data retry",i,v);task.wait(C.RetryDelay*i) end return false end
local function fresh() return {coins=C.StartingCoins,zombies={},graves={{type="Wooden",slot=1,plantedAt=os.time()-require(game.ReplicatedStorage.Shared.Config.GraveConfig).Wooden.Seconds,starter=true}},upgrades={},zombiedex={},dailyStreak=0,lastDailyAt=0,lastSeenAt=os.time(),playTime=0,tutorialDone=false,tutorialStep=0,version=C.Version,vouchers={},shopUsed={}} end
function D.Load(p)
 local data
 if memory then data=fresh() else
 local ok,v=retry(function() return store:UpdateAsync("player_"..p.UserId,function(old)
 if old and old.sessionJobId and old.sessionJobId~=job and os.time()-(old.sessionTime or 0)<C.LockTTL then return nil end
 local n=old or fresh();n.sessionJobId=job;n.sessionTime=os.time();return n end) end)
 if not ok or not v then p:Kick(L.text(ok and "busy" or "loadError",p.LocaleId));return end data=v end
 require(game.ReplicatedStorage.Shared.ProfileV3).Migrate(data)
 require(game.ReplicatedStorage.Shared.InterfaceRules).Migrate(data)
 require(game.ReplicatedStorage.Shared.PetRules).Migrate(data)
 require(game.ReplicatedStorage.Shared.WeaponRules).Migrate(data)
 require(game.ReplicatedStorage.Shared.WeaponUpgrades).Migrate(data)
 require(game.ReplicatedStorage.Shared.QuestRules).Migrate(data)
 data.upgrades=data.upgrades or {};require(game.ReplicatedStorage.Shared.HouseRules).Migrate(data);require(game.ReplicatedStorage.Shared.RoadRules).Migrate(data)
 if data.language~="en" and data.language~="ru" then data.language=nil end
 local seen={};local clean={}
 for _,z in ipairs(data.zombies) do
 local allowed=not seen[z.id] and not D.Claims[z.id]
 if allowed and not memory then local ok,owner=retry(function() return owners:GetAsync(z.id) end);if not ok then p:Kick(L.text("loadError",p.LocaleId));return end;allowed=(owner==p.UserId) or (not owner and not z.pendingTransfer) end
 if z.stars~=2 and z.stars~=3 then z.stars=nil end
 require(game.ReplicatedStorage.Shared.MonsterCollection).Promote(z,data.zombiedex)
 if allowed then seen[z.id]=true;z.carriedBy=nil;z.pendingTransfer=nil;table.insert(clean,z) end end
 data.zombies=clean;data.vouchers=data.vouchers or {};data.shopUsed=data.shopUsed or {};data.tutorialStep=data.tutorialStep or (data.tutorialDone and 3 or 0)
 for _,z in ipairs(clean) do D.Claims[z.id]=p.UserId end
 -- The ownership journal also resolves interrupted grave transfers on rejoin.
 for _,key in {"graves","graveInventory"} do
  local kept={};for _,g in data[key] do
   local keep=true
   if not memory then local ok,owner=retry(function() return owners:GetAsync("grave_"..g.id) end);if not ok then p:Kick(L.text("loadError",p.LocaleId));return end;keep=owner==p.UserId or (not owner and not g.pendingTransfer) end
   if keep then g.carriedBy=nil;g.pendingTransfer=nil;table.insert(kept,g) end
  end;data[key]=kept
 end
 -- Free placement: every planted grave and field zombie keeps (or gets) a spot of its own.
 require(game.ReplicatedStorage.Shared.PlacementRules).Migrate(data)
 if not p.Parent then return end D.Profiles[p]=data;return data
end
-- Read-only look at any saved profile, for the champion statue. Takes no session lock and changes nothing.
function D.Peek(userId)
 if memory then return nil end
 local ok,v=retry(function() return store:GetAsync("player_"..userId) end)
 if not ok then error("Profile read failed") end
 return v
end
function D.Save(p,release)
 while D.Busy[p] do task.wait() end
 local d=D.Profiles[p];if not d then return false end;if memory then return true end
 D.Busy[p]=true
 local snapshot=game:GetService("HttpService"):JSONDecode(game:GetService("HttpService"):JSONEncode(d));snapshot.lastSeenAt=os.time();snapshot.sessionJobId=not release and job or nil;snapshot.sessionTime=os.time()
 local ok,v=retry(function() return store:UpdateAsync("player_"..p.UserId,function(old) if old and old.sessionJobId~=job then return nil end return snapshot end) end)
 D.Busy[p]=nil;return ok and v~=nil
end
function D.SetOwner(id,from,to)
 if memory then return true end
 local ok,v=retry(function() return owners:UpdateAsync(id,function(old) if old==to then return to end;if old and old~=from then return nil end return to end) end);return ok and v==to
end
function D.Release(p) D.Save(p,true);local d=D.Profiles[p];if d then for _,z in ipairs(d.zombies) do if D.Claims[z.id]==p.UserId then D.Claims[z.id]=nil end end end;D.Profiles[p]=nil end
D.Memory=memory
return D

