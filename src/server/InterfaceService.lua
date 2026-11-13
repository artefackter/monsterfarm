-- Authoritative stage-4 actions. World UI merely displays the quotes made here.
local RS=game.ReplicatedStorage;local S=RS.Shared
local C=require(S.Config.InterfaceConfig);local Rules=require(S.InterfaceRules)
local D=require(script.Parent.DataService);local P=require(script.Parent.PlotService);local Act=require(script.Parent.ActionService)
local HR=require(S.HouseRules);local RR=require(S.RoadRules);local UC=require(S.Config.UpgradeConfig);local PC=require(S.Config.PetConfig)
local Art=require(S.ArtKit);local WA=require(S.WorldArt)
local I={Boards={},Zones={},Requests={},HomeReady={},GiftBusy={},ReceiptBusy={}}
local function notice(p,key,args) RS.Remotes.Notice:FireClient(p,key,args) end
local function part(parent,name,size,cf,color)
 local q=Instance.new('Part');q.Name=name;q.Size=size;q.CFrame=cf;q.Color=Color3.fromHex(color);q.Anchored=true;q.CanCollide=false;q.CanTouch=false;q.CanQuery=false;q.Parent=parent;return q
end
local function label(q,key,width,height)
 -- Sized in studs, so neighbouring stall titles shrink with distance instead of piling onto each other.
 local b=Instance.new('BillboardGui');b.Name='Sign';b.Size=UDim2.fromScale((width or 200)/18,(height or 42)/18);b.StudsOffset=Vector3.new(0,3.6,0);b.MaxDistance=115;b.Parent=q
 local t=Instance.new('TextLabel');t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Text='';t:SetAttribute('LocKey',key);t.Font=Enum.Font.GothamBlack;t.TextScaled=true;t.TextColor3=Color3.new(1,1,1);t.TextStrokeColor3=Color3.fromHex('33234B');t.TextStrokeTransparency=0;t.Parent=b
end
function I.NearZone(p,key)
 local q=I.Zones[key]
 return q and P.Near(p,q.Position,(q:GetAttribute('Radius') or C.ZoneRadius)+4) or false
end
function I.NearBoard(p,key)
 local q=I.Boards[p] and I.Boards[p][key];return q and P.Near(p,q.Position,C.BoardDistance) or false
end
function I.Quote(p,key)
 local d=D.Profiles[p];if not d then return end
 local price,level,max,reason=0,1,false,nil
 if key=='House' then level=HR.Level(d);local n=HR.Next(d);max=not n;price=n and n.Price or 0;if d.houseEnds then reason='houseBuilding';price=HR.Remaining(d) end
 elseif key=='Treadmill' then level=RR.Level(d);local n=RR.Next(d);max=not n;price=n and n.Price or 0
 elseif key=='PetSlots' then level=PC.StartSlots+d.petSlots;max=level>=PC.MaxSlots;price=UC.PetSlots.Price*UC.PetSlots.Factor^d.petSlots
 elseif key=='Fence' then local FC=require(S.Config.FenceConfig);level=FC.Level(d);local n=FC.Levels[level+1];max=not n;price=n and n.Price or 0
 elseif key=='Lock' then local raid=require(script.Parent.RaidService);level=1;price=math.max(0,math.ceil((raid.LockCooldown[p] or 0)-os.clock()));if price>0 then reason='lockWait' end
 elseif key=='Prestige' then
  local PR=require(S.PrestigeRules);level=PR.Level(d);price=PR.Cost(d)
  if HR.Level(d)<PR.House then reason='prestigeHouse' end
  return {price=math.floor(price),level=level,next=level+1,max=false,reason=reason,credit=false,afford=not reason and d.coins>=price}
 elseif UC[key] and require(S.Config.ZoneConfig)[key] then
  level=HR.Cap(d,key);max=level>=require(S.Config.ZoneConfig)[key].Max;price=UC[key].Price*UC[key].Factor^(d.upgrades[key] or 0)
  local need=HR.Need(d,key);if need then reason='houseLimit' end
 else return end
 local credit=(d.upgradeCredits[key] or 0)>0
 return {price=math.floor(price),level=level,next=level+(key=='Crypt' and 10 or 1),max=max,reason=reason,credit=credit,afford=not max and not reason and (credit or key=='Lock' or d.coins>=price)}
end
function I.Buy(p,key)
 local d=D.Profiles[p];if not d or key=='Prestige' or not Act.CanAct(p) or not I.NearBoard(p,key) then return false end -- prestige only through its confirmation
 local q=I.Quote(p,key);if not q or not q.afford then return false end
 local before=d.coins
 if key=='Lock' then return require(script.Parent.RaidService).Lock(p) end
 if q.credit then d.upgradeCredits[key]-=1 else d.coins-=q.price end
 if key=='House' then d.houseEnds=os.time()+HR.Next(d).Seconds
 elseif key=='Treadmill' then d.treadmill=RR.Level(d)+1;require(script.Parent.HouseService).RefreshTreadmill(p,d)
 elseif key=='PetSlots' then d.petSlots+=1;require(script.Parent.PetService).Refresh(p);require(script.Parent.PetService).Push(p)
 elseif key=='Fence' then require(script.Parent.FenceService).Upgrade(p,d)
 else d.upgrades[key]=(d.upgrades[key] or 0)+1 end
 require(script.Parent.QuestService).Track(p,'upgrade',1)
 require(script.Parent.AnalyticsTracker).Economy(p,d.coins-before,d.coins,'Upgrade')
 require(script.Parent.SlotService).Render(p,d);return true
end
function I.HomeReason(p)
 local road=require(script.Parent.RoadService);local a=Act.State(p)
 local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart');local onRoad=false;if root then local along,x=road.ToRoad(root.Position);local rc=require(S.Config.RoadConfig);onRoad=along>rc.GateLine and along<rc.Length and road.InRuins(along,x,0) end
 return Rules.HomeReason({alive=p.Character~=nil and p.Character:FindFirstChildOfClass("Humanoid")~=nil and p.Character.Humanoid.Health>0 and P.Assigned[p]~=nil,road=onRoad,carry=road.Carriers[p]~=nil or require(script.Parent.RaidService).Carriers[p]~=nil,dig=a.dig~=nil,knockout=Act.Blocked(p),trap=road.Blocked(p),cooldown=math.max(0,(I.HomeReady[p] or 0)-os.clock())})
end
function I.Home(p)
 local reason=I.HomeReason(p);if reason then notice(p,reason);return false end
 I.HomeReady[p]=os.clock()+C.HomeCooldown;p:SetAttribute('HomeReadyAt',workspace:GetServerTimeNow()+C.HomeCooldown)
 RS.Remotes.InterfaceFX:FireClient(p,'home')
 -- Wait for the fade, then revalidate all escape restrictions.
 task.delay(.15,function() if not p.Parent then return end;local ready=I.HomeReady[p];I.HomeReady[p]=nil;local blocked=I.HomeReason(p);I.HomeReady[p]=ready;if blocked then notice(p,blocked);return end;P.Home(p) end)
 return true
end
function I.Gift(p)
 local d=D.Profiles[p];if C.GroupId<=0 or not d or not Act.CanAct(p) or not I.NearZone(p,'freeGift') or I.GiftBusy[p] or d.freeGiftClaimed then return false end
 I.GiftBusy[p]=true;local ok,member=pcall(function() return p:IsInGroupAsync(C.GroupId) end)
 local granted=ok and p.Parent and D.Profiles[p]==d and Act.CanAct(p) and I.NearZone(p,'freeGift') and Rules.ClaimGift(d,C.GroupId,member)
 I.GiftBusy[p]=nil;if granted then Act.Push(p) else notice(p,'giftGroupRequired') end;return granted==true
end
function I.Settings(p,key,value)
 local d=D.Profiles[p];local default=C.Settings[key];if not d or default==nil or type(value)~=type(default) then return false end
 if type(value)=='number' then if value~=value or value<0 or value>1 then return false end end
 d.settings[key]=value;if key=='ShowRanges' then d.showRanges=value end
 p:SetAttribute(key,value);Act.Push(p);return true
end
function I.ProcessReceipt(receipt)
 local decision=Enum.ProductPurchaseDecision;local p=game.Players:GetPlayerByUserId(receipt.PlayerId);local d=p and D.Profiles[p]
 if not d or I.ReceiptBusy[p] then return decision.NotProcessedYet end
 local key;for k,v in C.Products do if v.Id>0 and v.Id==receipt.ProductId then key=k;break end end
 if not key then return decision.NotProcessedYet end
 I.ReceiptBusy[p]=true
 local ok,result=pcall(function() return Rules.Receipt(d,receipt.PurchaseId,key,function() return D.Save(p) end) end)
 I.ReceiptBusy[p]=nil
 if ok and result then I.Refresh(p);if I.Push then I.Push(p) end;return decision.PurchaseGranted end
 return decision.NotProcessedYet
end
I.IncomeBatches={}
function I.Income(p,amount)
 local b=I.IncomeBatches[p] or {sum=0,at=os.clock()};I.IncomeBatches[p]=b;b.sum+=amount
 if os.clock()-b.at>=5 then if b.sum>0 then RS.Remotes.EconomyFX:FireClient(p,b.sum,'income',P.Assigned[p].Base.Position) end;b.sum=0;b.at=os.clock() end
end
function I.Refresh(p)
 local d=D.Profiles[p];if not d then return end
 for key,q in I.Boards[p] or {} do if q.Parent then local quote=I.Quote(p,key);for k,v in quote do q:SetAttribute(k,v) end;q:SetAttribute('reason',quote.reason) end end
 p:SetAttribute('HomeReason',I.HomeReason(p));p:SetAttribute('IncomeRate',require(script.Parent.ZombieService).Income(d))
 local used,field=0,0;for _,z in d.zombies do if z.zone=='Crypt' then used+=1 elseif z.zone=='Field' then field+=1 end end;p:SetAttribute('CryptUsed',used);p:SetAttribute('CryptCapacity',HR.Cap(d,'Crypt'));p:SetAttribute('TreadmillRate',RR.Rate(d))
 p:SetAttribute('FieldUsed',field);p:SetAttribute('FieldCapacity',HR.FieldCap(d));p:SetAttribute('HouseLevel',HR.Level(d));p:SetAttribute('TreadmillLevel',RR.Level(d))
 p:SetAttribute('Prestige',require(S.PrestigeRules).Level(d))
end
function I.Join(p)
 local d=D.Profiles[p];Rules.Migrate(d);for k,v in d.settings do p:SetAttribute(k,v) end
 local plot=P.Assigned[p];local folder=Instance.new('Folder');folder.Name='UpgradeBoards';folder.Parent=plot.Model;I.Boards[p]={}
 for key,pos in C.Boards do
  local cf=plot.Base*CFrame.new(pos.X,-.5,pos.Z)*CFrame.Angles(0,math.rad(pos.Yaw or 0),0)
  -- Bigger than before (owner, 2026-11-12: the levels went unnoticed): the board now also says what the next level gives.
  local k=1.1/.72
  Art.Spawn('V3_UpgradeBoard',folder,cf,{scale=.72*k})
  local board=part(folder,key,Vector3.new(4.608*k,2.664*k,.9),cf*CFrame.new(0,3.168*k,0),'342647');board.Transparency=1;board.CanQuery=true;board:SetAttribute('UpgradeKey',key);board:SetAttribute('Owner',p.UserId);I.Boards[p][key]=board
 end
 I.Refresh(p)
end
function I.Forget(p)
 local list=I.Boards[p];if list then local _,b=next(list);if b and b.Parent then b.Parent:Destroy() end end
 I.IncomeBatches[p]=nil;I.Boards[p]=nil;I.Requests[p]=nil;I.HomeReady[p]=nil;I.GiftBusy[p]=nil;I.ReceiptBusy[p]=nil
end
function I.Init(push)
 I.Push=push
 for _,name in {'InterfaceAction','InterfaceFX','EconomyFX'} do local e=Instance.new('RemoteEvent');e.Name=name;e.Parent=RS.Remotes end
 local world=P.World;local folder=Instance.new('Folder');folder.Name='MenuZones';folder.Parent=world
 -- Approved WorldV3 props around the existing authoritative menu zones.
 if P.Shop then P.Shop.Transparency=1;P.Shop.CanCollide=false end
 for key,cfg in C.Zones do if key~='freeGift' or C.GroupId>0 then
  local cf=CFrame.new(cfg.Position+Vector3.new(0,P.PlazaTop+.22,0))
  local q=part(folder,key,Vector3.one,cf,cfg.Color);q.Transparency=1;q:SetAttribute('MenuZone',key);q:SetAttribute('Radius',cfg.Radius or C.ZoneRadius);I.Zones[key]=q
  local asset=({weapons='V3_StallWeapons',pumpkins='V3_StallPets',traps='V3_StallBrawler',quests='V3_QuestBoard',rewards='V3_RewardChest',freeGift='V3_GiftChest',merge='V3_MergeTable',info='V3_QuestBoard'})[key]
  local shop=key=='weapons' or key=='pumpkins' or key=='traps'
  local outward=Vector3.new(cfg.Position.X,0,cfg.Position.Z).Unit
  local pos=cf.Position+outward*(shop and 2.5 or 1.5)
  local at=CFrame.lookAt(pos,Vector3.new(0,pos.Y,0))
  if key=='merge' or key=='quests' or key=='rewards' then at=CFrame.new(pos)*CFrame.Angles(0,math.pi,0) end
  local m=WA.Model(asset,folder,at,key=='info' and {scale=Vector3.new(1.5,1.5,1)} or nil);m.Name='Stand_'..key
  if key=='traps' or key=='pumpkins' then
   m.Canopy:Destroy()
   Art.Spawn(key=='traps' and 'V3_StallPets' or 'V3_StallBrawler',m,at,{skip={Main=true}})
  end
  local stand=part(m,'Title',Vector3.one,at*CFrame.new(0,shop and 9.6 or key=='info' and 10 or key=='quests' and 8.2 or 6,0),cfg.Color);stand.Transparency=1;label(stand,cfg.Title)
  if key=='merge' then
   P.Solid(m,'TableBlock',Vector3.new(11,4,6),at*CFrame.new(0,2,0))
   part(m,'MergePlaque',Vector3.new(9,1.8,.25),at*CFrame.new(0,6,2.3),'FFD65C')
   P.SignText(m,at*CFrame.new(0,6,2.14),Vector3.new(8.6,1.5,.02),'hubMergeHint')
  end
  if key=='quests' or key=='info' then
   local factor=key=='info' and 1.5 or 1
   P.Solid(m,'BoardBlock',Vector3.new(8*factor,6*factor,.8),at*CFrame.new(0,5*factor,0))
  end
  if key=='info' then
   local face=part(m,'InfoPaper',Vector3.new(10.8,7.8,.06),at*CFrame.new(0,7.5,-.72),'FFF3CF')
   local title=P.SignText(m,at*CFrame.new(0,10,-.77),Vector3.new(10.1,1.6,.03),'info',Color3.fromHex('7741BA'))
   local body=P.SignText(m,at*CFrame.new(0,6.5,-.77),Vector3.new(10,4.5,.03),'hubInfoBoard')
  end
  if shop then
   local npc=Instance.new('Model');npc.Name='Vendor';Art.BuildZombie(npc,at*CFrame.new(0,.6,1.3),{id=key,type=key=='weapons' and 'Knight' or key=='pumpkins' and 'Gardener' or 'Cowboy',tier=1});npc.Parent=m
   P.Solid(m,'Counter',Vector3.new(11,3,1),at*CFrame.new(0,1.5,-3))
  end

 end end
 RS.Remotes.InterfaceAction.OnServerEvent:Connect(function(p,op,arg,value,...)
  if select('#',...)>0 or type(op)~='string' or #op>24 or arg~=nil and (type(arg)~='string' or #arg>100) then return end
  if value~=nil and type(value)~='boolean' and type(value)~='number' then return end
  local now=os.clock();if now-(I.Requests[p] or -100)<C.RemoteInterval then return end;I.Requests[p]=now
  local d=D.Profiles[p];if not d then return end
  local before=d.coins;local ok=false
  if op=='home' then ok=I.Home(p)
  elseif not Act.CanAct(p) then return
  elseif op=='upgrade' then ok=I.Buy(p,arg)
  elseif op=='prestige' then
   if I.NearBoard(p,'Prestige') then local reason;ok,reason=require(script.Parent.PrestigeService).Do(p);if not ok and reason then notice(p,reason);I.Refresh(p);push(p);return end end
  elseif op=='setting' then ok=I.Settings(p,arg,value)
  elseif op=='dex' then local page,n=string.match(arg or '', '^(%a+):(%d+)$');if page then ok=Rules.ClaimDex(d,page,tonumber(n));Act.Push(p) end
  elseif op=='gift' then ok=I.Gift(p)
  elseif op=='trap' then ok=Act.Select(p,4)
  elseif op=='product' then local cfg=C.Products[arg];local q=I.Quote(p,arg);if cfg and cfg.Id>0 and I.NearBoard(p,arg) and q and not q.max and not q.reason then game:GetService('MarketplaceService'):PromptProductPurchase(p,cfg.Id);ok=true end
  end
  if op~='upgrade' and d.coins~=before then require(script.Parent.AnalyticsTracker).Economy(p,d.coins-before,d.coins,op) end
  if op~='home' then notice(p,ok and 'ok' or 'error') end
  I.Refresh(p);push(p)
 end)
 game:GetService('MarketplaceService').ProcessReceipt=I.ProcessReceipt
end
return I
