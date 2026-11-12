game.StarterGui.ScreenOrientation=Enum.ScreenOrientation.LandscapeSensor
local spawnPad=workspace:FindFirstChildWhichIsA("SpawnLocation");if spawnPad then spawnPad.Duration=0 end
local Players=game:GetService("Players");local RS=game:GetService("ReplicatedStorage");local S=RS.Shared
local SC=require(S.Config.ShopConfig);local GC=require(S.Config.GraveConfig);local UC=require(S.Config.UpgradeConfig);local NC=require(S.Config.NightConfig)
local D=require(script.Parent.DataService);local P=require(script.Parent.PlotService);local Z=require(script.Parent.ZombieService);local G=require(script.Parent.GraveService);local Shop=require(script.Parent.ShopService);local I=require(script.Parent.IncomeService);local Day=require(script.Parent.DayNightService);local Raid=require(script.Parent.RaidService);local Reward=require(script.Parent.RewardService);local A=require(script.Parent.AnalyticsTracker)
local Pets=require(script.Parent.PetService)
local Bank=require(script.Parent.BankService)
local Q=require(script.Parent.QuestService);local Board=require(script.Parent.LeaderboardService);local Ref=require(script.Parent.ReferralService);local Slots=require(script.Parent.SlotService);local House=require(script.Parent.HouseService);local HouseRules=require(S.HouseRules);local Road=require(script.Parent.RoadService);local RoadRules=require(S.RoadRules)
require(S.Locale).install()
local rem=RS:FindFirstChild("Remotes") or Instance.new("Folder",RS);rem.Name="Remotes"
for _,name in ipairs({"Intent","State","Notice","Merge"}) do if not rem:FindFirstChild(name) then local r=Instance.new("RemoteEvent");r.Name=name;r.Parent=rem end end
local sounds=RS:FindFirstChild("Sounds") or Instance.new("Folder",RS);sounds.Name="Sounds"
for name,cfg in pairs(require(S.Config.SoundConfig)) do local x=sounds:FindFirstChild(name) or Instance.new("Sound");x.Name=name;x.SoundId="rbxassetid://"..cfg.Id;x.Volume=cfg.Volume;x.PlaybackSpeed=cfg.Speed or 1;x.Parent=sounds end
require(script.Parent.ActionService).Init();Pets.Init();P.Build();Bank.Init();require(script.Parent.InviteSpots).Init();require(script.Parent.MutantService).Init();require(script.Parent.WeaponService).Init();Board.Init();House.Init();Road.Init();require(script.Parent.RoadGearService).Init();require(script.Parent.BloodMoonService).Init();require(script.Parent.MutantService).OnKill=function(p) Q.Track(p,"kill",1) end;Pets.OnHatch=function(p) Q.Track(p,"hatch",1) end;local lanternState=nil;local nightParticipants={};local accumulated={};local wasNight=Day.State();local last={};local joining={}
local function allowed(p) local now=os.clock();if now-(last[p] or -1)<SC.RemoteInterval then return false end;last[p]=now;return true end
local function notice(p,k,args) rem.Notice:FireClient(p,k,args) end
-- "x,z" in farm-local studs, as sent by the placement preview
local function spot(arg) if type(arg)~="string" then return end;local x,z=arg:match("^(%-?[%d%.]+),(%-?[%d%.]+)$");return tonumber(x),tonumber(z) end
local function push(p)
 local d=D.Profiles[p];if not d then return end;local night,left=Day.State();local stock,refresh=Shop.Stock(d,night);local graves={}
 for _,g in ipairs(d.graves) do table.insert(graves,{type=g.type,slot=g.slot,remaining=G.Remaining(d,g)}) end
 rem.State:FireClient(p,{settings=d.settings,dexClaims=d.dexClaims,freeGiftClaimed=d.freeGiftClaimed,upgradeCredits=d.upgradeCredits,coins=d.coins,income=Z.Income(d),zombies=d.zombies,graves=graves,graveInventory=d.graveInventory,selectedGrave=d.selectedGrave,tutorialDone=d.tutorialDone,dex=d.zombiedex,upgrades=d.upgrades,stock=stock,refresh=refresh,night=night,left=left,offline=d.offlinePending or 0,dailyStreak=d.dailyStreak,lastDailyAt=d.lastDailyAt,step=d.tutorialStep,vouchers=d.vouchers,protection=math.max(0,NC.Newbie-d.playTime),quests=d.quests,peak=math.floor(d.peakIncome or 0),language=d.language,house=HouseRules.Level(d),houseLeft=HouseRules.Remaining(d),speed=d.speedPoints,slowMode=d.slowMode,showRanges=d.showRanges,shovels=d.shovels,equippedShovel=d.equippedShovel,treadmill=RoadRules.Level(d)})
end
local UI=require(script.Parent.InterfaceService);UI.Init(push)
local function dig(p,slot,source,petId)
 local d=D.Profiles[p];if source~="pet" and not require(script.Parent.ActionService).CanAct(p) then return end;if not d or (source~="pet" and not allowed(p)) then return end
 for i,g in ipairs(d.graves) do if g.slot==slot and not g.carriedBy and G.Remaining(d,g)==0 and (source=="pet" and not G.IsHeld(p,slot) or source~="pet" and P.Near(p,P.Position(p,"Graves",slot).Position,SC.DigDistance)) then
 local free=Z.Slot(d,"Crypt");if not free then notice(p,"error");return end
 local z=Z.Roll(GC[g.type].Weights,Day.State(),g.starter,Pets.GetBonuses(p).luckMult);if g.monsterType=="DeerChief" then z.type="DeerChief";z.tier=6 end;z.slot=free;table.remove(d.graves,i);table.insert(d.zombies,z);D.Claims[z.id]=p.UserId;d.zombiedex[z.type..":"..z.mutation]=true;Q.Track(p,"dig",1);if z.tier>=2 then Q.Track(p,"rare",1) end
 if d.tutorialStep==0 then d.tutorialStep=1;A.Step(p,1) end
 G.Render(p,d);Z.Render(p,d);if source=="pet" then rem.Notice:FireClient(p,"petDug",{rarity=require(S.Config.ZombieConfig).Tiers[z.tier],type=z.type}) else rem.Notice:FireClient(p,"reveal",z) end
 if z.tier>=3 then rem.Notice:FireAllClients("rare",{name=p.DisplayName,rarity=require(S.Config.ZombieConfig).Tiers[z.tier],type=z.type}) end;push(p);return z end end
 notice(p,"error")
end
G.OnDig=dig;G.Dig=dig
G.OnModel=function(owner,g,m,head)
 if g.starter then return end
 local pr=Instance.new("ProximityPrompt");pr.Name="StealGrave";pr.ActionText="stealGrave";pr.HoldDuration=NC.StealHold;pr.MaxActivationDistance=NC.Distance;pr.RequiresLineOfSight=false;pr:SetAttribute("Owner",owner.UserId);pr.Parent=head
 pr.PromptButtonHoldBegan:Connect(function(p) Raid.Begin(p,owner,g) end)
 pr.PromptButtonHoldEnded:Connect(Raid.End)
 pr.Triggered:Connect(function(p) if not Raid.Complete(p,owner,g) then notice(p,"error") end end)
end
local function action(p,op,arg,zone)
 if type(op)~="string" or (arg~=nil and type(arg)~="string") or (zone~=nil and type(zone)~="string") or (arg and #arg>100) or not allowed(p) then return end
 local d=D.Profiles[p];if not d then return end;local before=d.coins;local ok,reason=false,nil
 if op=="sync" then push(p);return
 elseif not require(script.Parent.ActionService).CanAct(p) then return
 elseif op=="selectGrave" then ok=G.Select(p,arg)
 elseif op=="plantGrave" then ok=G.Plant(p,tonumber(arg))
 elseif op=="plantAt" then local x,z=spot(arg);ok,reason=G.PlantAt(p,x,z)
 elseif op=="holdZombie" then ok=Z.Hold(p,d,arg)
 elseif op=="placeZombie" then local x,z=spot(arg);ok,reason=Z.Place(p,d,x,z);if ok and d.tutorialStep==1 then d.tutorialStep=2;A.Step(p,2) end
 elseif op=="dropZombie" then Z.Drop(p);ok=true
 elseif op=="move" or op=="sell" then
 local z,i=Z.Find(d,arg);if z and not z.carriedBy and not z.pendingTransfer and P.Inside(p,P.Assigned[p]) and not Raid.Carriers[p] then
 if op=="sell" then d.coins+=Z.Rate(z)*require(S.Config.ZombieConfig).SaleSeconds;table.remove(d.zombies,i);Z.Remove(z.id);D.Claims[z.id]=nil;ok=true
 elseif zone=="Field" then ok=Z.Hold(p,d,z.id)
 elseif zone=="Crypt" then
  local slot=Z.Slot(d,zone);local point
  if zone=="Guards" then point=require(S.PlacementRules).FindFree(d,"Defender",z) end
  if slot and (zone=="Crypt" or point) then
   if Z.Holding[p] and Z.Holding[p].id==z.id then Z.Drop(p) end
   z.zone=zone;z.slot=slot;z.pos=point;Z.Remove(z.id);ok=true
  end
 end end
 elseif op=="upgrade" then ok=UI.Buy(p,arg)
 elseif op=="daily" then ok=UI.NearZone(p,"rewards") and Reward.Claim(d)
 elseif op=="quest" and arg then ok=UI.NearZone(p,"quests") and Q.Claim(p,d,arg)
 elseif op=="houseUpgrade" then ok=UI.Buy(p,"House")
 elseif op=="treadmill" then ok=UI.Buy(p,"Treadmill")
 elseif op=="plantVoucher" then ok=G.Select(p,arg)
 elseif op=="enterHouse" then if not House.Enter(p) then notice(p,"error") end;push(p);return
 elseif op=="leaveHouse" then if not House.Leave(p) then notice(p,"error") end;push(p);return
 elseif op=="language" and (arg=="auto" or arg=="en" or arg=="ru") then d.language=arg~="auto" and arg or nil;p:SetAttribute("Language",d.language);ok=true
 elseif op=="lock" then ok=UI.Buy(p,"Lock") end
 if d.coins~=before and op~="upgrade" and op~="houseUpgrade" and op~="treadmill" then A.Economy(p,d.coins-before,d.coins,op) end
 if ok then G.Render(p,d);Z.Render(p,d);Slots.Render(p,d) end;notice(p,ok and "ok" or reason or "error");push(p)
end
-- Clicking a placed zombie uses the same validated pickup as the inventory button.
Z.OnModel=function(owner,z,m)
 if z.zone~="Field" and z.zone~="Guards" then return end
 for _,part in m:GetDescendants() do if part:IsA("BasePart") and part.Name~="Ring" then
  part.CanQuery=true;local cd=Instance.new("ClickDetector");cd.MaxActivationDistance=80;cd.Parent=part
  cd.MouseClick:Connect(function(who) if who==owner and P.Inside(who,P.Assigned[owner]) then action(who,"holdZombie",z.id) end end)
 end end
end
rem.Intent.OnServerEvent:Connect(action)
Slots.OnExpand=function(p,zone) action(p,"upgrade",zone) end
Slots.OnPlant=function(p,slot) action(p,"plantGrave",tostring(slot)) end
rem.Merge.OnServerEvent:Connect(function(p,a,b,c)
 local d=D.Profiles[p];if not d or not require(script.Parent.ActionService).CanAct(p) or not allowed(p) then return end
 local plot=P.Assigned[p]
 local z=plot and House.NearMerge(p) and not Raid.Carriers[p] and require(script.Parent.MergeService).Try(d,{a,b,c})
 if not z then notice(p,"error");return end
 G.Render(p,d);Z.Render(p,d);Slots.Render(p,d)
 local shown=table.clone(z);shown.merged=true;rem.Notice:FireClient(p,"reveal",shown)
 if shown.stars>=3 then rem.Notice:FireAllClients("starRare",{name=p.DisplayName,type=z.type}) end
 push(p)
end)
local function join(p)
 if joining[p] then return end;joining[p]=true
 if #Players:GetPlayers()>SC.MaxPlayers then p:Kick(require(S.Locale).text("serverFull",require(S.Locale).lang(p)));return end
 local d=D.Load(p);if not d then return end;local plot=P.Assign(p);if not plot then D.Release(p);p:Kick(require(S.Locale).text("serverFull",require(S.Locale).lang(p)));return end
 require(script.Parent.ActionService).Push(p);Pets.Refresh(p);Pets.Starter(p);local away=I.Offline(d);if d.selectedGrave then G.Select(p,d.selectedGrave:gsub("^voucher:","")) end;p:SetAttribute("Language",d.language);Q.Ensure(p,d);Ref.Join(p,d);Board.Push(p);local stats=Instance.new("Folder");stats.Name="leaderstats";stats.Parent=p;for _,key in {"Income/s","Speed"} do local value=Instance.new("StringValue");value.Name=key;value.Parent=stats end
 p.CharacterAdded:Connect(function(c) task.wait(.2);P.Home(p);local h=c:WaitForChild("Humanoid");h.Died:Connect(function() if Road.Carriers[p] then Road.Drop(p,true) else Raid.Return(p) end end) end)
 if p.Character then P.Home(p) end

 House.Join(p,d);Bank.Join(p,d);UI.Join(p)
 -- Offline income already lies on the heap; say so once the HUD is up.
 if away>=1 then task.delay(4,function() if p.Parent then local Loc=require(S.Locale);notice(p,"offlineHeap",{n=Loc.compact(away,Loc.lang(p))}) end end) end
 G.Render(p,d);Z.Render(p,d);Slots.Render(p,d);push(p);Pets.Push(p);require(script.Parent.WeaponService).Push(p)
end
Players.PlayerAdded:Connect(join);for _,p in ipairs(Players:GetPlayers()) do task.spawn(join,p) end
Players.PlayerRemoving:Connect(function(p) Z.Drop(p);Raid.Leave(p);Board.Flush(p);Board.Forget(p.UserId);Ref.Forget(p);Slots.Forget(p);Road.Forget(p);UI.Forget(p);local departing=D.Profiles[p];if departing then for _,z in ipairs(departing.zombies) do Z.Remove(z.id) end end;D.Release(p);local plot=P.Assigned[p];if plot then local prompt=plot.Gate:FindFirstChild("LockPrompt");if prompt then prompt:Destroy() end end;House.Forget(p);P.Release(p);G.Models[p]=nil;joining[p]=nil;last[p]=nil;accumulated[p]=nil;nightParticipants[p]=nil end)
task.spawn(function() while task.wait(1) do for holder in pairs(Z.Holding) do local h=holder.Character and holder.Character:FindFirstChildOfClass('Humanoid');if not holder.Parent or not h or h.Health<=0 or not P.Inside(holder,P.Assigned[holder]) then Z.Drop(holder);if holder.Parent then notice(holder,'placeReturned') end end end;local night=Day.Update();if lanternState~=night then lanternState=night;P.SetNight(night) end;if wasNight and not night then for p in pairs(nightParticipants) do if p.Parent and D.Profiles[p] then A.Step(p,4);Q.Track(p,"dawn",1) end end;nightParticipants={} end;wasNight=night;for p,d in pairs(D.Profiles) do if P.Assigned[p] then local n=I.Tick(d);Bank.Add(p,d,0);UI.Refresh(p);House.Tick(p,d);Board.Observe(d,n);Q.Track(p,"earn",n);Q.Track(p,"time",1);Ref.Tick(p,d);if night then nightParticipants[p]=true end;accumulated[p]=(accumulated[p] or 0)+n;if p:FindFirstChild("leaderstats") then p.leaderstats["Income/s"].Value=require(S.Locale).compact(n,require(S.Locale).lang(p));p.leaderstats.Speed.Value=require(S.Locale).compact(d.speedPoints,require(S.Locale).lang(p)) end;G.Render(p,d);Z.Render(p,d);Slots.Render(p,d);push(p);Pets.Push(p) end end end end)
task.spawn(function() while task.wait(NC.Poll) do Raid.Tick() end end)
task.spawn(function() while task.wait(SC.Autosave) do for p in pairs(D.Profiles) do task.spawn(function() local gain=accumulated[p] or 0;if gain>0 then A.Economy(p,gain,D.Profiles[p].coins,"FarmIncome");accumulated[p]=0 end;if not D.Save(p) then p:Kick(require(S.Locale).text("savingError",require(S.Locale).lang(p))) end end) end end end)
game:BindToClose(function() local pending=0;for p in pairs(D.Profiles) do pending+=1;task.spawn(function() Raid.Leave(p);Board.Flush(p);D.Save(p,true);pending-=1 end) end;while pending>0 do task.wait(.1) end end)
workspace:SetAttribute("GameBuild","v3-stage6-motion-2026-11-07")
print("DigAZombie ready; Studio memory:",D.Memory)

