local RS=game.ReplicatedStorage;local C=require(RS.Shared.Config.WeaponConfig);local Rules=require(RS.Shared.WeaponRules)
local Up=require(RS.Shared.WeaponUpgrades)
local Skins=require(RS.Shared.WeaponSkins)
local SC=require(RS.Shared.Config.ShopConfig);local D=require(script.Parent.DataService);local P=require(script.Parent.PlotService)
local R=require(script.Parent.RaidService);local M=require(script.Parent.MutantService);local A=require(script.Parent.AnalyticsTracker)
local W={Sessions={},ActionTimes={},Colliders={}};local rng=Random.new();local rem
-- Magazine size with the player's upgrades (WeaponUpgrades); the plain config until the profile is there.
local function magazine(p,id) local d=D.Profiles[p];return d and Up.Value(id,"Magazine",Up.Level(d,id,"Magazine")) or C[id].Magazine end
function W.Session(p)
 local s=W.Sessions[p];if not s then s={ammo={},reload={},nextShot=0,requestAt=0};W.Sessions[p]=s;for _,id in ipairs(C.Order) do s.ammo[id]=magazine(p,id) end end
 for id,finish in pairs(s.reload) do if os.clock()>=finish then s.reload[id]=nil;s.ammo[id]=magazine(p,id) end end;return s
end
function W.Push(p)
 local d=D.Profiles[p];if not d or not rem then return end;local s=W.Session(p)
 s.holstered=d.activeSlot~=2;p:SetAttribute("EquippedWeapon",d.equippedWeapon);p:SetAttribute("EquippedWeaponSkin",d.weaponSkins and d.weaponSkins[d.equippedWeapon] or "Default");p:SetAttribute("CarryingZombie",false)
 local ends=s.reload[d.equippedWeapon];p:SetAttribute("WeaponHolstered",s.holstered==true);p:SetAttribute("WeaponReloadUntil",ends and workspace:GetServerTimeNow()+math.max(0,ends-os.clock()) or 0);if p:GetAttribute('Mutagen')~=d.mutagen then p:SetAttribute('Mutagen',d.mutagen or 0) end;local stats=Up.Stats_(d,d.equippedWeapon);if p:GetAttribute("WeaponDamage")~=stats.Damage then p:SetAttribute("WeaponDamage",stats.Damage) end
 if p:GetAttribute("WeaponRange")~=stats.Range then p:SetAttribute("WeaponRange",stats.Range) end;if p:GetAttribute("WeaponReloadTime")~=stats.Reload then p:SetAttribute("WeaponReloadTime",stats.Reload) end
 rem.WeaponState:FireClient(p,{holstered=s.holstered==true,owned=d.weapons,skins=table.clone(d.weaponSkins or {}),equipped=d.equippedWeapon,skin=d.weaponSkins and d.weaponSkins[d.equippedWeapon] or "Default",ammo=s.ammo[d.equippedWeapon],reloadLeft=ends and math.max(0,ends-os.clock()) or 0,magazine=stats.Magazine,fireRate=stats.FireRate,range=stats.Range,reload=stats.Reload,kills=d.ruinKills,upgrades=d.weaponUpgrades,mutagen=d.mutagen or 0,coins=d.coins})
end
-- A gun earned in the ruins (WeaponConfig.Unlock): it is yours, and everyone hears about it.
function W.Grant(p,d,id)
 if d.weapons[id] then return end
 d.weapons[id]=true
 local Loc=require(RS.Shared.Locale);rem.Notice:FireClient(p,"weaponUnlocked",{weapon=Loc.text(id,Loc.lang(p))})
 W.Push(p)
end
-- Guns earned before this rule existed (or while the server was down) are handed over on join.
function W.Join(p)
 local d=D.Profiles[p];if not d then return end
 for _,id in ipairs(Rules.Earned(d)) do W.Grant(p,d,id) end
end
function W.Reload(p)
 local d=D.Profiles[p];if not d then return false end;local id=d.equippedWeapon;local s=W.Session(p);if not require(script.Parent.ActionService).Ready(p) or d.activeSlot~=2 then return false end
 if s.holstered or os.clock()<(s.drawUntil or 0) or s.reload[id] or s.ammo[id]>=magazine(p,id) then return false end
 s.reload[id]=os.clock()+Up.Stats_(d,id).Reload;W.Push(p);return true -- upgraded guns reload faster
end
function W.Action(p,op,id)
 local d=D.Profiles[p];if not d then return false end
 if op=="sync" then W.Push(p);return true end
 if op=="reload" then return W.Reload(p) end
 if op=='holster' then return false end
 if op=="skin" then
  if not require(script.Parent.ActionService).CanAct(p) then return false end
  local weapon,skin=string.match(type(id)=="string" and id or "","^(%a+%d*):(%a+)$")
  if not weapon or not Skins.Select(d,weapon,skin) then return false end
  W.Push(p);return true
 end
 if op=="upgrade" then
  -- id is "<weapon>:<stat>"; the rules decide, the server pays
  local weapon,stat=string.match(type(id)=="string" and id or "","^(%a+%d*):(%a+)$")
  if not weapon or not C[weapon] then return false end
  local ok,coins=Up.Buy(d,weapon,stat);if not ok then return false end
  if stat=="Magazine" then local s=W.Session(p);if not s.reload[weapon] then s.ammo[weapon]=magazine(p,weapon) end end
  A.Economy(p,-coins,d.coins,"WeaponUpgrade");W.Push(p);return true
 end
 if not require(script.Parent.ActionService).CanAct(p) then return false end
 if type(id)~="string" or not table.find(C.Order,id) then return false end
 if op=="buy" then
  -- no money any more: a gun is yours once you have hunted enough in its location (WeaponConfig.Unlock)
  if d.weapons[id] or not table.find(Rules.Earned(d),id) then return false end
  W.Grant(p,d,id)
 elseif op=="equip" then if not d.weapons[id] then return false end;d.equippedWeapon=id
 else return false end
 W.Push(p);return true
end
-- What a shot (or a line of sight) hits first: the map's solid parts and, unless wallsOnly, the monsters' hitboxes.
function W.Raycast(origin,delta,wallsOnly)
 local include={}
 for part in pairs(W.Colliders) do if part.Parent and part.CanCollide and part.CanQuery then table.insert(include,part) end end
 if not wallsOnly then for _,a in pairs(M.Live) do if a.model.PrimaryPart then table.insert(include,a.model.PrimaryPart) end end end
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances=include;params.RespectCanCollide=false
 return workspace:Raycast(origin,delta,params)
end
function W.Fire(p,id,aim)
 if type(id)~="string" or not table.find(C.Order,id) or not Rules.ValidAim(aim) then return false end
 if workspace:GetServerTimeNow()<(p:GetAttribute("RoadBatUntil") or 0) or workspace:GetServerTimeNow()<(p:GetAttribute("RoadStunnedUntil") or 0) then return false end
 local d=D.Profiles[p];if not require(script.Parent.ActionService).Ready(p) or not d or d.activeSlot~=2 or not d.weapons[id] or d.equippedWeapon~=id or p:GetAttribute("InHouse") then return false end -- nobody shoots through the floor
 local ch=p.Character;local head=ch and ch:FindFirstChild("Head");local h=ch and ch:FindFirstChildOfClass("Humanoid")
 if not head or not h or h.Health<=0 then return false end
 local stats=Up.Stats_(d,id) -- range, rate and damage with the player's upgrades
 local delta=aim-head.Position;if delta.Magnitude<.01 or delta.Magnitude>stats.Range then return false end
 require(script.Parent.RoadService).Reveal(p) -- a shot from a bush gives the shooter away
 local s=W.Session(p);local cfg=C[id];local now=os.clock()
 if s.holstered or now<(s.drawUntil or 0) or p:GetAttribute("Training") or now+C.RateTolerance<s.nextShot or s.reload[id] or s.ammo[id]<=0 then return false end
 local crit=rng:NextNumber()<stats.CritChance
 s.nextShot=math.max(now,s.nextShot)+1/stats.FireRate;s.ammo[id]-=1
 local look=CFrame.lookAt(Vector3.zero,delta.Unit);local hits={};local ends={}
 for _=1,cfg.Pellets do
  local angle=rng:NextNumber(0,math.pi*2);local radius=math.tan(math.rad(cfg.Spread))*math.sqrt(rng:NextNumber())
  local direction=look:VectorToWorldSpace(Vector3.new(math.cos(angle)*radius,math.sin(angle)*radius,-1).Unit)
  local hit=W.Raycast(head.Position,direction*stats.Range);table.insert(ends,hit and hit.Position or head.Position+direction*stats.Range)
  local model=hit and hit.Instance.Parent;local mid=model and model:GetAttribute("MutantId");if mid and M.Live[mid] and (hit.Position-head.Position).Magnitude<=stats.Range+1 then hits[mid]=(hits[mid] or 0)+stats.Damage*(crit and stats.CritMult or 1) end
 end
 for mid,damage in pairs(hits) do M.Damage(M.Live[mid],math.floor(damage+.5),p,crit) end
 p:SetAttribute("CombatAim",aim);p:SetAttribute("CombatAimUntil",workspace:GetServerTimeNow()+C.PoseHold)
 rem.WeaponFX:FireAllClients(p.UserId,id,head.Position,ends,aim,next(hits)~=nil);W.Push(p);return true
end
function W.Init()
 rem=RS.Remotes
 for _,name in ipairs({"WeaponFire","WeaponAction","WeaponState","WeaponFX"}) do local r=Instance.new("RemoteEvent");r.Name=name;r.Parent=rem end
 local function track(part)
  if part:IsA("BasePart") and not part:FindFirstAncestorOfClass("Tool") then
   local world=workspace:FindFirstChild("DigAZombie")
   if world and part:IsDescendantOf(world) and not part:FindFirstAncestor("Zombie") and not part:FindFirstAncestor("Shopkeeper") then W.Colliders[part]=true end
  end
 end
 for _,part in ipairs(workspace:GetDescendants()) do track(part) end
 workspace.DescendantAdded:Connect(track);workspace.DescendantRemoving:Connect(function(p) W.Colliders[p]=nil end)
 rem.WeaponFire.OnServerEvent:Connect(function(p,...)
  if select("#",...)~=2 then return end
  local s=W.Session(p);local now=os.clock();if now-s.requestAt<C.RequestInterval then return end;s.requestAt=now
  W.Fire(p,...)
 end)
 rem.WeaponAction.OnServerEvent:Connect(function(p,op,id,...)
  if select("#",...)>0 or type(op)~="string" or #op>20 or (id~=nil and (type(id)~="string" or #id>20)) then return end
  local now=os.clock();if now-(W.ActionTimes[p] or -math.huge)<C.ActionInterval then return end;W.ActionTimes[p]=now
  if not W.Action(p,op,id) then rem.Notice:FireClient(p,"weaponDenied") end
 end)
 game.Players.PlayerRemoving:Connect(function(p) W.Sessions[p]=nil;W.ActionTimes[p]=nil end)
 -- Mutagen: a chance drop from every monster killed in the ruins (WeaponUpgrades.Drop)
 M.OnRoadKill=function(killer,a)
  local d=D.Profiles[killer];if not d then return end
  -- the hunt that earns guns: every monster killed out on the road counts for its location
  if a.road and a.biome and d.ruinKills and d.ruinKills[a.biome] then
   d.ruinKills[a.biome]+=1
   for _,id in ipairs(Rules.Earned(d)) do W.Grant(killer,d,id) end
  end
  local amount=Up.DropFor(a.biome,a.boss==true,a.night==true,rng:NextNumber())
  if amount<=0 then return end
  d.mutagen=(d.mutagen or 0)+amount;killer:SetAttribute("Mutagen",d.mutagen)
  rem.Notice:FireClient(killer,"mutagenDrop",{n=amount});W.Push(killer)
 end
 task.spawn(function() while task.wait(.25) do for p in pairs(W.Sessions) do W.Push(p) end end end)
end
return W
