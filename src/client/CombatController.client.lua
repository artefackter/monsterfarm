local Players=game:GetService("Players");local UIS=game:GetService("UserInputService");local Run=game:GetService("RunService");local RS=game.ReplicatedStorage
local p=Players.LocalPlayer;local S=RS:WaitForChild("Shared");local rem=RS:WaitForChild("Remotes")
local C=require(S.Config.WeaponConfig);local L=require(S.Locale);local Pal=require(S.Palette);local Sfx=require(S.Sfx);local Models=require(S.WeaponModel)
local Tween=game:GetService("TweenService");local Debris=game:GetService("Debris")
local Icons=require(S.Icons);local Style=require(S.UIStyle)
local Pose=require(S.CombatPose);local WeaponAnimation=require(S.WeaponAnimation);local ShovelMotion=require(S.ShovelMotion)
local poses={};local heldModels={};local currentTarget;local targetSince=0;local nextScan=0;local currentAim;local hitUntil=0;local savedAutoRotate;local rotatingHumanoid
local font=L.lang():sub(1,2)=="ru" and Enum.Font.GothamBlack or Enum.Font.FredokaOne
local function t(k,args) return L.text(k,L.lang(),args) end
local gui=Instance.new("ScreenGui");gui.Name="CombatUI";gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.DisplayOrder=22;gui.ResetOnSpawn=false;gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets;gui.Parent=p:WaitForChild("PlayerGui")
local control=Instance.new("Frame",gui);control.Name="Hotbar";control.Size=UDim2.fromOffset(446,84);control.AnchorPoint=Vector2.new(.5,1);control.Position=UDim2.new(.5,0,1,-8);control.BackgroundTransparency=1
local scale=Instance.new("UIScale",control)
local function text(parent,name,label,size,pos,color)
 local b=Style.Panel(Instance.new("TextButton"),color or Pal.Panel);b.Name=name;b.Text=label;b.Size=size;b.Position=pos;b.TextColor3=Pal.Ink;b.Font=font;b.TextScaled=true;b.TextWrapped=true;b.AutoLocalize=false;b.Parent=parent;return b
end
local RoadC=require(S.Config.RoadConfig);local Shovels=require(S.Config.ShovelConfig)
local equipment=rem:WaitForChild("EquipmentAction")
local state;local auto=true;local focused=true;local held=false;local manualSpent=false;local nextShot=0;local reloadWas=false;local itemsState
local function roadAction(op,target) if not UIS:GetFocusedTextBox() then rem.RoadAction:FireServer(op,target) end end
local strip=Style.Panel(Instance.new('ScrollingFrame'),Pal.Panel);strip.Name='SelectionStrip';strip.Size=UDim2.fromOffset(400,100);strip.Position=UDim2.fromOffset(-28,-112);strip.Visible=false;strip.ScrollBarThickness=4;strip.AutomaticCanvasSize=Enum.AutomaticSize.X;strip.CanvasSize=UDim2.new();strip.Parent=control
local stripList=Instance.new('UIListLayout',strip);stripList.FillDirection=Enum.FillDirection.Horizontal;stripList.SortOrder=Enum.SortOrder.LayoutOrder;stripList.Padding=UDim.new(0,8)
local stripKind;local choiceOrder=0
local openUpgrades,upgradeRefresh,upgradeWindow -- the upgrade bench, built further down
local function clearStrip(kind) for _,c in strip:GetChildren() do if c:IsA('GuiObject') then c:Destroy() end end;choiceOrder=0;stripKind=kind;strip.Visible=true end
local function choice(kind,id,count,callback)
 local b=Style.Button(strip,id,UDim2.fromOffset(92,90),UDim2.new(),function() callback();strip.Visible=false end,Pal.Panel)
 choiceOrder+=1;b.LayoutOrder=choiceOrder
 Style.ModalArt(b,kind,id,UDim2.new(1,-8,1,-22),UDim2.fromOffset(4,2))
 if count then local n=Style.Text(b,tostring(count),UDim2.fromOffset(80,22),UDim2.fromOffset(6,65));n.ZIndex=3 end
end
local function chooseItems()
 if strip.Visible and stripKind=='items' then strip.Visible=false;return end;clearStrip('items')
 local n=0
 -- coffins brought back from the ruins first (drawn as coffins), then graves bought in the shop
 for _,g in itemsState and itemsState.graveInventory or {} do if not g.pendingTransfer then n+=1;choice('coffin',g.type,1,function() rem.Intent:FireServer('selectGrave',g.id) end) end end
 for _,id in require(S.Config.GraveConfig).Order do local count=itemsState and itemsState.vouchers[id] or 0;if count>0 then n+=1;choice('grave',id,count,function() rem.Intent:FireServer('selectGrave',id) end) end end
 if n==0 then strip.Visible=false end
end
-- Hotbar as in the reference: small dark glassy slots, a number in the corner, the selected one outlined white.
local function slotButton(name,x,callback)
 local b=Instance.new('TextButton');b.Name=name;b.Text='';b.AutoButtonColor=false;b.Size=UDim2.fromOffset(78,78);b.Position=UDim2.fromOffset(x,3)
 b.BackgroundColor3=Color3.fromRGB(28,30,44);b.BackgroundTransparency=.25;b.Parent=control
 Instance.new('UICorner',b).CornerRadius=UDim.new(0,10)
 local stroke=Instance.new('UIStroke',b);stroke.Name='Outline';stroke.Color=Color3.fromRGB(70,74,96);stroke.Thickness=2;stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
 local pop=Instance.new('UIScale',b);b.Activated:Connect(function() Style.Pop(pop,1);Sfx.play('Click');callback() end)
 return b
end
-- Hotbar v3 (owner, 2026-11-13): 1 shovel, 2 gun, 3 trap, a gap, 4 graves, 5 the crypt's monsters. A second press on
-- the slot in your hands empties them. One gun is carried at a time: it is changed at the gun shop, not here.
-- The server keeps its own numbers: 1 shovel, 2 gun, 3 graves, 4 trap (0 = empty hands).
local function pressSlot(n)
 strip.Visible=false
 if p:GetAttribute('ActiveSlot')==n and not p:GetAttribute('HoldingZombie') then equipment:FireServer('slot','0') else equipment:FireServer('slot',tostring(n)) end
end
local function pressGraves()
 if p:GetAttribute('ActiveSlot')==3 and not p:GetAttribute('HoldingZombie') then pressSlot(3) else equipment:FireServer('slot','3');chooseItems() end
end
local selectShovel=slotButton('Slot1',0,function() pressSlot(1) end)
local weaponTile=slotButton('Slot2',86,function() pressSlot(2) end)
local trapTile=slotButton('Slot3',172,function() pressSlot(4) end)
local itemTile=slotButton('Slot4',282,pressGraves)
local slots={selectShovel,weaponTile,itemTile,trapTile} -- indexed by the server's slot numbers
for b,i in {[selectShovel]=1,[weaponTile]=2,[trapTile]=3,[itemTile]=4} do local n=Style.Text(b,tostring(i),UDim2.fromOffset(18,18),UDim2.fromOffset(4,2));n.TextColor3=Color3.new(1,1,1);n.TextXAlignment=Enum.TextXAlignment.Left;n.ZIndex=4 end
local shovelIcon=Style.ModalArt(selectShovel,'shovel',p:GetAttribute('EquippedShovel') or 'Rusty',UDim2.fromOffset(62,58),UDim2.fromOffset(8,6))
Style.ModalArt(itemTile,'grave',nil,UDim2.fromOffset(56,52),UDim2.fromOffset(11,6))
Style.ModalArt(trapTile,'trap',nil,UDim2.fromOffset(56,52),UDim2.fromOffset(11,6))
local function badgeText(parent,name)
 local q=Style.Text(parent,'',UDim2.fromOffset(74,20),UDim2.fromOffset(2,56));q.Name=name;q.ZIndex=4;q.TextColor3=Color3.new(1,1,1)
 local st=Instance.new('UIStroke',q);st.Color=Color3.fromRGB(20,14,40);st.Thickness=2;return q
end
local cooldown=badgeText(selectShovel,'Cooldown')
local itemCount=badgeText(itemTile,'Count')
local trapCount=badgeText(trapTile,'Count')
local ammo=badgeText(weaponTile,'Ammo')
-- Slot 5 (owner, 2026-11-13) is the monster in your arms: its portrait while you carry one (a tap puts it back), else
-- a tap lists the crypt's monsters to take out. One table keeps this script under Luau's 200 locals.
local extra={}
do
 local function heldType() local m=p.Character and p.Character:FindFirstChild('HeldZombie');return m and m:GetAttribute('Type') end
 local function free(z) return z.zone=='Crypt' and not z.carriedBy and not z.pendingTransfer end
 extra.chooseMonsters=function()
  if strip.Visible and stripKind=='monsters' then strip.Visible=false;return end;clearStrip('monsters')
  local n=0
  for _,z in require(S.MergeRules).SortByIncome(itemsState and itemsState.zombies or {}) do
   if free(z) and n<30 then n+=1;choice('monster',z.type,string.rep('★',require(S.MergeRules).Stars(z)),function() rem.Intent:FireServer('move',z.id,'Field') end) end
  end
  if n==0 then strip.Visible=false;require(S.Notifications).Show(t('cryptNothing'),'error',3) end
 end
 extra.press=function()
  if p:GetAttribute('HoldingZombie') then rem.Intent:FireServer('dropZombie');strip.Visible=false else extra.chooseMonsters() end
 end
 extra.monster=slotButton('Slot5',368,extra.press)
 for i,b in {[5]=extra.monster} do local n=Style.Text(b,tostring(i),UDim2.fromOffset(18,18),UDim2.fromOffset(4,2));n.TextColor3=Color3.new(1,1,1);n.TextXAlignment=Enum.TextXAlignment.Left;n.ZIndex=4 end
 local portrait=Instance.new('ImageLabel');portrait.Name='MonsterPortrait';portrait.BackgroundTransparency=1;portrait.ScaleType=Enum.ScaleType.Fit
 portrait.Size=UDim2.fromOffset(62,56);portrait.Position=UDim2.fromOffset(8,6);portrait.ZIndex=3;portrait.Parent=extra.monster
 local count=badgeText(extra.monster,'Count')
 extra.refresh=function()
  local held=heldType()
  local icon=held and require(S.MonsterCollection).Icon(held,Icons)
  portrait.Image=held and (icon or '') or Icons.crypt or '';portrait.ImageTransparency=held and 0 or .3
  local model3d=extra.monster:FindFirstChild('MonsterModel') -- no painting yet (the rotation, the RingMaw): its 3D model
  if held and not icon then
   if not model3d or model3d:GetAttribute('Type')~=held then
    if model3d then model3d:Destroy() end
    local v=require(S.MonsterPortrait).Create(extra.monster,{id=held,type=held,tier=1},UDim2.fromOffset(62,56),UDim2.fromOffset(8,6));v.Name='MonsterModel';v.ZIndex=3;v:SetAttribute('Type',held)
   end
  elseif model3d then model3d:Destroy() end
  local n=0;for _,z in itemsState and itemsState.zombies or {} do if free(z) then n+=1 end end
  count.Text=held and '' or tostring(n)
 end
end
local weaponIcon=Instance.new('ImageLabel');local dotFor={};local rangeLabel=Instance.new('TextLabel')
local previewId;local preview
local function showWeapon(id) local finish=state and state.skins and state.skins[id] or "Default";local key=id..":"..finish;if previewId==key then return end;previewId=key;if preview then preview:Destroy() end;preview=Style.ModalArt(weaponTile,'weapon',id,UDim2.fromOffset(74,52),UDim2.fromOffset(2,6),finish) end
-- Slow mode: a switch with a green knob and its name beside it.
local slow=Instance.new('TextButton');slow.Name='SlowMode';slow.Text='';slow.AutoButtonColor=false;slow.BackgroundTransparency=1;slow.Size=UDim2.fromOffset(250,50);slow.Parent=gui
local slowScale=Instance.new('UIScale',slow)
local track=Instance.new('Frame',slow);track.Name='Track';track.Size=UDim2.fromOffset(104,46);track.Position=UDim2.fromOffset(0,2);track.BackgroundColor3=Color3.fromRGB(60,58,74);Instance.new('UICorner',track).CornerRadius=UDim.new(0,10)
local trackStroke=Instance.new('UIStroke',track);trackStroke.Color=Color3.fromRGB(28,26,40);trackStroke.Thickness=3
local knob=Instance.new('Frame',track);knob.Name='Knob';knob.Size=UDim2.fromOffset(40,36);knob.Position=UDim2.fromOffset(5,5);knob.BackgroundColor3=Color3.fromRGB(110,240,60);Instance.new('UICorner',knob).CornerRadius=UDim.new(0,8)
local knobStroke=Instance.new('UIStroke',knob);knobStroke.Color=Color3.fromRGB(40,110,20);knobStroke.Thickness=2
local slowLabel=Style.Text(slow,'',UDim2.fromOffset(136,46),UDim2.fromOffset(112,2));slowLabel.TextColor3=Color3.new(1,1,1);slowLabel.UITextSizeConstraint.MaxTextSize=19
local slowStroke=Instance.new('UIStroke',slowLabel);slowStroke.Color=Color3.fromRGB(20,14,40);slowStroke.Thickness=2
slow.Activated:Connect(function() equipment:FireServer('slow') end)
rem.State.OnClientEvent:Connect(function(s) itemsState=s end)
p:GetAttributeChangedSignal('EquippedShovel'):Connect(function() shovelIcon:Destroy();shovelIcon=Style.ModalArt(selectShovel,'shovel',p:GetAttribute('EquippedShovel'),UDim2.fromOffset(62,58),UDim2.fromOffset(8,6)) end)
local arrow=text(gui,"ThreatArrow","",UDim2.fromOffset(150,50),UDim2.fromScale(.5,.26),Pal.Red);arrow.AnchorPoint=Vector2.new(.5,.5);arrow.Active=false;arrow.Visible=false;local ars=Instance.new("UIScale",arrow)
local function resize()
 local v=gui.AbsoluteSize;local f=math.clamp(math.min(v.X/1000,v.Y/560),.52,1.1)
 scale.Scale=f;ars.Scale=f;slowScale.Scale=f
 local full=p.PlayerGui:FindFirstChild('MobileStats')
 local centerShift=UIS.TouchEnabled and full and (full.AbsolutePosition.Y-gui.AbsolutePosition.Y+(full.AbsoluteSize.Y-v.Y)/2+13*f) or 0
 slow.Position=UDim2.new(0,14,.5,8+centerShift)
 -- Five slots and a gap are wide (2026-11-13): the bar sits in the gap between the stats bottom-left and the day clock
 -- bottom-right, shrinking if that gap is narrower than the bar.
 local dig=p.PlayerGui:FindFirstChild('DigUI');local clock=dig and dig:FindFirstChild('DayClock')
 local ms=math.clamp(math.min(workspace.CurrentCamera.ViewportSize.X/1280,workspace.CurrentCamera.ViewportSize.Y/720),.48,1.25)
 local left=16+250*ms;local right=clock and clock.AbsoluteSize.X>0 and clock.AbsolutePosition.X-gui.AbsolutePosition.X-6 or v.X-12-300*f
 local k=math.clamp((right-left)/446,.4,f);scale.Scale=k
 control.Position=UDim2.new(0,math.clamp((left+right)/2,223*k+4,v.X-223*k-4),1,-8)
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize);gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize);resize()
task.spawn(function() local dig=p.PlayerGui:WaitForChild('DigUI',15);local c=dig and dig:WaitForChild('DayClock',15);if c then c:GetPropertyChangedSignal('AbsolutePosition'):Connect(resize);resize() end end)
p.PlayerGui.ChildAdded:Connect(function(c) if c.Name=='MobileStats' then c:GetPropertyChangedSignal('AbsoluteSize'):Connect(resize);task.defer(resize) end end)
local function menuOpen() if upgradeWindow and upgradeWindow.Visible then return true end;local dig=p.PlayerGui:FindFirstChild("DigUI");local menu=dig and dig:FindFirstChild("Menu");return dig and (dig:GetAttribute("ModalOpen")==true or menu and menu.Visible or dig:FindFirstChild("Reveal")~=nil or dig:FindFirstChild("PetHatch")~=nil) end
-- Round buttons to the right of the hotbar: drop the grave you carry (key G) and, on phones, reload (R on keyboards).
local function roundButton(name,y,color,callback)
 local b=Instance.new('TextButton');b.Name=name;b.Text='';b.AutoButtonColor=false;b.Size=UDim2.fromOffset(78,78);b.Position=UDim2.fromOffset(454,y);b.BackgroundColor3=color;b.Visible=false;b.Parent=control
 Instance.new('UICorner',b).CornerRadius=UDim.new(1,0)
 local st=Instance.new('UIStroke',b);st.Color=Color3.fromRGB(28,26,40);st.Thickness=3;st.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
 local pop=Instance.new('UIScale',b);b.Activated:Connect(function() Style.Pop(pop,1);Sfx.play('Click');callback() end)
 return b
end
local reloadButton=roundButton('ReloadButton',3,Color3.fromRGB(255,196,64),function() rem.WeaponAction:FireServer('reload') end)
local reloadIcon=Instance.new('ImageLabel');reloadIcon.Name='Icon';reloadIcon.BackgroundTransparency=1;reloadIcon.Size=UDim2.fromOffset(54,54);reloadIcon.Position=UDim2.fromOffset(12,12);reloadIcon.Image=Icons.reload;reloadIcon.ImageColor3=Color3.fromRGB(52,33,78);reloadIcon.Parent=reloadButton
local dropButton=roundButton('DropGraveButton',-83,Color3.fromRGB(255,110,110),function() roadAction('dropGrave') end)
Style.ModalArt(dropButton,'coffin',nil,UDim2.fromOffset(46,44),UDim2.fromOffset(16,4))
local dropLabel=Style.Text(dropButton,'',UDim2.fromOffset(70,22),UDim2.fromOffset(4,48));dropLabel.Name='Label';dropLabel.TextColor3=Color3.new(1,1,1);dropLabel.ZIndex=4
local dropStroke=Instance.new('UIStroke',dropLabel);dropStroke.Color=Color3.fromRGB(20,14,40);dropStroke.Thickness=2
Run.Heartbeat:Connect(function()
 local open=menuOpen()
 dropButton.Visible=p:GetAttribute('CarryingGrave')==true and not open
 dropLabel.Text=t('dropGrave')
 local cfg=state and C[state.equipped]
 reloadButton.Visible=UIS.TouchEnabled and not open and p:GetAttribute('ActiveSlot')==2 and cfg~=nil and not state.holstered and (state.reloadLeft or 0)<=0 and (state.ammo or 0)<(state.magazine or cfg.Magazine)
end)
do -- its own scope: this script is close to Luau's limit of 200 locals
-- Upgrade bench (WeaponUpgrades): one tile per stat with its picture, level, what the next level gives and a
-- green button with the price in zombucks and mutagen. Opened from the weapon strip or the mutagen chip.
local Up=require(S.WeaponUpgrades)
local MC=Style.ModalColors
local STAT_ICON={Damage='pistol',FireRate='auto_on',Magazine='rifle',Crit='star',Reload='reload'} -- Range has no picture: a target emoji
local benchWeapon
local function vial(parent,size,pos)
 if Icons.modal_mutagen then local art=Style.ModalArt(parent,'mutagen',nil,size,pos);art.ZIndex=7;return art end
 -- a little flask of green mutagen, drawn from frames so it needs no image
 local f=Instance.new('Frame');f.Name='Vial';f.BackgroundTransparency=1;f.Size=size;f.Position=pos;f.Parent=parent
 local body=Instance.new('Frame');body.AnchorPoint=Vector2.new(.5,1);body.Position=UDim2.fromScale(.5,1);body.Size=UDim2.fromScale(.72,.66);body.BackgroundColor3=Color3.fromRGB(96,240,90);body.Parent=f
 Instance.new('UICorner',body).CornerRadius=UDim.new(.45,0);local st=Instance.new('UIStroke',body);st.Color=Color3.fromRGB(20,70,24);st.Thickness=2
 local neck=Instance.new('Frame');neck.AnchorPoint=Vector2.new(.5,0);neck.Position=UDim2.fromScale(.5,.06);neck.Size=UDim2.fromScale(.3,.36);neck.BackgroundColor3=Color3.fromRGB(190,255,190);neck.Parent=f
 local st2=Instance.new('UIStroke',neck);st2.Color=Color3.fromRGB(20,70,24);st2.Thickness=2
 local cork=Instance.new('Frame');cork.AnchorPoint=Vector2.new(.5,0);cork.Position=UDim2.fromScale(.5,0);cork.Size=UDim2.fromScale(.44,.14);cork.BackgroundColor3=Color3.fromRGB(170,110,60);cork.Parent=f
 Instance.new('UICorner',cork).CornerRadius=UDim.new(.4,0)
 for _,c in f:GetChildren() do c.ZIndex=7 end -- above the window's skin, or the flask is hidden
 return f
end
local function fmt(stat,a,b)
 if stat=='FireRate' then return string.format('%.1f',a)
 elseif stat=='Crit' then return string.format('%d%% x%.1f',math.floor(a*100+.5),b)
 elseif stat=='Reload' then return t('upSeconds',{n=string.format('%.2f',a)})
 elseif stat=='Range' then return t('upStuds',{n=string.format('%.1f',a)}) end
 return L.compact(a,L.lang())
end
local function buildBench()
 local w=Style.ModalWindow(Instance.new('Frame'));w.Name='UpgradeBench';w.AnchorPoint=Vector2.new(.5,.5);w.Size=UDim2.fromOffset(1140,628);w.Visible=false;w.ZIndex=20;w.Active=true;w.Parent=gui
 local sc=Instance.new('UIScale',w);sc.Name='Fit'
 local header=Style.ModalHeader(Instance.new('Frame'),true);header.Size=UDim2.new(1,-24,0,62);header.Position=UDim2.fromOffset(12,0);header.Parent=w
 local title=Style.ModalText(Style.Text(header,'',UDim2.new(1,-90,0,44),UDim2.fromOffset(24,10)),true);title.Name='Title';title.TextXAlignment=Enum.TextXAlignment.Left;title.UITextSizeConstraint.MaxTextSize=36;title.ZIndex=3
 local close=Instance.new('TextButton');close.Name='Close';close.Position=UDim2.new(1,-66,0,8);close.Size=UDim2.fromOffset(48,48);close.ZIndex=4;close.Parent=w
 Style.ModalButton(close,MC.Red);Style.ModalClose(close);close.Activated:Connect(function() Sfx.play('Click');w.Visible=false end)
 local body=Instance.new('Frame');body.Name='Body';body.BackgroundTransparency=1;body.Position=UDim2.fromOffset(26,78);body.Size=UDim2.new(1,-52,1,-100);body.ZIndex=2;body.Parent=w
 upgradeWindow=w
 local function fit()
  local v=gui.AbsoluteSize;local k=math.max(.1,math.min(1.3,(v.X-40)/1188,(v.Y-24)/688));sc.Scale=k;w.Position=UDim2.new(.5,0,.5,24*k)
 end
 w:GetPropertyChangedSignal('Visible'):Connect(function() p.PlayerGui:SetAttribute('UpgradeModalOpen',w.Visible) end)
 gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(fit);fit()
 return w
end
local benchSig
upgradeRefresh=function(force)
 local w=upgradeWindow;if not w or not w.Visible or not state then return end
 if not benchWeapon then benchWeapon=state.equipped end
 local levels=state.upgrades and state.upgrades[benchWeapon] or {}
 local coins=state.coins or itemsState and itemsState.coins or 0;local mutagen=state.mutagen or 0
 local sig=L.lang()..benchWeapon..math.floor(coins)..':'..mutagen
 for _,stat in Up.Stats do sig..=':'..(levels[stat] or 0) end
 for _,id in C.Order do sig..=state.owned[id] and '1' or '0' end
 if sig==benchSig and not force then return end;benchSig=sig
 local body=w.Body;body:ClearAllChildren();w:FindFirstChild('Title',true).Text=t('weaponUpgrade')
 local function caption(parent,value,size,pos,light)
  local l=Style.ModalText(Style.Text(parent,value,size,pos),light);l.ZIndex=5;return l
 end
 local summary=Style.ModalSurface(Instance.new('Frame'),MC.Cream,14,false);summary.Name='Summary';summary.Size=UDim2.new(1,0,0,64);summary.ZIndex=3;summary.Parent=body
 caption(summary,t(benchWeapon),UDim2.fromOffset(160,48),UDim2.fromOffset(8,8))
 Style.ModalArt(summary,'weapon',benchWeapon,UDim2.fromOffset(230,60),UDim2.fromOffset(170,2),state.skins and state.skins[benchWeapon]).ZIndex=4
 local function currency(parent,kind,value,size,pos)
  local f=Style.ModalSurface(Instance.new('Frame'),MC.Cream,12,false);f.Size=size;f.Position=pos;f.ZIndex=4;f.Parent=parent
  if kind=='cash' then Style.ModalArt(f,'cash',nil,UDim2.fromOffset(36,36),UDim2.fromOffset(5,5)).ZIndex=5 else vial(f,UDim2.fromOffset(32,40),UDim2.fromOffset(5,3)) end
  caption(f,value,UDim2.new(1,-45,1,-4),UDim2.fromOffset(42,2));return f
 end
 currency(summary,'cash','$'..L.compact(coins,L.lang()),UDim2.fromOffset(200,48),UDim2.new(1,-360,0,8))
 currency(summary,'mutagen',tostring(mutagen),UDim2.fromOffset(138,48),UDim2.new(1,-148,0,8))
 for i,id in C.Order do
  local tab=Style.ModalSurface(Instance.new('TextButton'),MC.Cream,12,false);tab.Name='Gun_'..id;tab.Text='';tab.Size=UDim2.new(1/#C.Order,-7,0,76);tab.Position=UDim2.new((i-1)/#C.Order,3,0,76);tab.ZIndex=3;tab.Parent=body
  local art=Style.ModalArt(tab,'weapon',id,UDim2.new(1,-12,0,44),UDim2.fromOffset(6,4),state.skins and state.skins[id]);art.ZIndex=4
  caption(tab,t(id),UDim2.new(1,-6,0,24),UDim2.fromOffset(3,48)).UITextSizeConstraint.MaxTextSize=20
  if id==benchWeapon then Style.ModalSelected(tab) end
  if not state.owned[id] then art.ImageTransparency=.45 end
  tab.Activated:Connect(function() Sfx.play('Click');benchWeapon=id;upgradeRefresh(true) end)
 end
 local fake={weaponUpgrades=state.upgrades or {},weapons=state.owned,coins=coins,mutagen=mutagen}
 for i,stat in Up.Stats do
  local level=levels[stat] or 0
  local tile=Style.ModalSurface(Instance.new('Frame'),MC.Blue,14);tile.Name='Stat_'..stat;tile.Size=UDim2.new(1/#Up.Stats,-8,0,330);tile.Position=UDim2.new((i-1)/#Up.Stats,4,0,164);tile.ZIndex=3;tile.Parent=body
  local icon=Instance.new('ImageLabel');icon.BackgroundTransparency=1;icon.Size=UDim2.fromOffset(54,54);icon.Position=UDim2.new(.5,-27,0,9);icon.Image=Icons[STAT_ICON[stat] or ''] or '';icon.ZIndex=5;icon.Parent=tile
  if icon.Image=='' then local e=Style.Text(icon,'🎯',UDim2.fromScale(1,1));e.ZIndex=6;e.UITextSizeConstraint.MaxTextSize=46 end
  caption(tile,t('up_'..stat),UDim2.new(1,-12,0,28),UDim2.fromOffset(6,64)).UITextSizeConstraint.MaxTextSize=25
  local levelChip=Style.ModalSurface(Instance.new('Frame'),Color3.fromRGB(220,180,207),10,false);levelChip.Size=UDim2.fromOffset(72,22);levelChip.Position=UDim2.new(.5,-36,0,96);levelChip.ZIndex=4;levelChip.Parent=tile
  caption(levelChip,level..'/'..Up.Max,UDim2.fromScale(1,1))
  for n=1,Up.Max do
   local pip=Instance.new('Frame');pip.Size=UDim2.fromOffset(11,11);pip.Position=UDim2.new(.5,-68+(n-1)*14,0,128);pip.BackgroundColor3=n<=level and MC.Green or Color3.fromRGB(196,170,180);pip.ZIndex=5;pip.Parent=tile
   Instance.new('UICorner',pip).CornerRadius=UDim.new(1,0);local st=Instance.new('UIStroke',pip);st.Color=MC.Ink;st.Thickness=1.5
  end
  local a1,a2=Up.Value(benchWeapon,stat,level)
  local now=caption(tile,fmt(stat,a1,a2),UDim2.new(1,-12,0,30),UDim2.fromOffset(6,150))
  if level<Up.Max then
   local b1,b2=Up.Value(benchWeapon,stat,level+1)
   if stat=='Crit' then
    Style.ModalArrow(tile,UDim2.fromOffset(20,16),UDim2.new(.5,-10,0,182)).ZIndex=5;tile.MergeArrow.Rotation=90
    caption(tile,fmt(stat,b1,b2),UDim2.new(1,-12,0,28),UDim2.fromOffset(6,198)).TextColor3=Color3.fromRGB(25,135,18)
   else
    now.Size=UDim2.new(.4,0,0,46);now.Position=UDim2.fromOffset(4,161)
    Style.ModalArrow(tile,UDim2.fromOffset(28,24),UDim2.new(.5,-14,0,173)).ZIndex=5
    caption(tile,fmt(stat,b1,b2),UDim2.new(.4,0,0,46),UDim2.new(.6,-4,0,161)).TextColor3=Color3.fromRGB(25,135,18)
   end
  end
  local why=Up.Check(fake,benchWeapon,stat)
  if level<Up.Max then
   local price,need=Up.Cost(benchWeapon,stat,level)
   currency(tile,'cash','$'..L.compact(price,L.lang()),UDim2.new(.61,-8,0,40),UDim2.fromOffset(7,228))
   currency(tile,'mutagen',tostring(need),UDim2.new(.39,-8,0,40),UDim2.new(.61,1,0,228))
  end
  local buy=Instance.new('TextButton');buy.Name='Buy';buy.Text=t(why=='max' and 'upMax' or why=='bad' and 'upLocked' or why and 'upInsufficient' or 'upgradeTile');buy.Font=Style.Font();buy.TextScaled=true;buy.Size=UDim2.new(1,-16,0,32);buy.Position=UDim2.new(0,8,1,-39);buy.ZIndex=5;buy.Parent=tile
  Style.ModalButton(buy,why=='max' and MC.Gold or why and Color3.fromRGB(155,157,163) or MC.Green)
  buy.AutoButtonColor=why==nil
  local pop=Instance.new('UIScale',buy)
  buy.Activated:Connect(function()
   if why then Sfx.play('Error',.3);return end
   Style.Pop(pop,1);Sfx.play('Buy',.2);rem.WeaponAction:FireServer('upgrade',benchWeapon..':'..stat)
  end)
 end
 caption(body,t('mutagenHint'),UDim2.new(1,0,0,24),UDim2.fromOffset(0,502)).UITextSizeConstraint.MaxTextSize=20
end
openUpgrades=function()
 local w=upgradeWindow or buildBench()
 if w.Visible then w.Visible=false;return end
 benchWeapon=state and state.equipped;w.Visible=true;upgradeRefresh(true)
 local sc=w.Fit;local base=sc.Scale;sc.Scale=base*.9;Tween:Create(sc,TweenInfo.new(.16,Enum.EasingStyle.Back),{Scale=base}):Play()
end
local bridge=Instance.new('BindableEvent');bridge.Name='OpenUpgrades';bridge.Parent=gui;bridge.Event:Connect(openUpgrades)
-- Mutagen chip over the weapon slot: how much there is; a tap opens the bench.
local chip=Instance.new('TextButton');chip.Name='MutagenChip';chip.Text='';chip.AutoButtonColor=false;chip.Size=UDim2.fromOffset(78,26);chip.Position=UDim2.fromOffset(86,-28);chip.BackgroundColor3=Color3.fromRGB(28,30,44);chip.BackgroundTransparency=.2;chip.Visible=false;chip.Parent=control
Instance.new('UICorner',chip).CornerRadius=UDim.new(0,9);do local st=Instance.new('UIStroke',chip);st.Color=Color3.fromRGB(96,240,90);st.Thickness=2;st.ApplyStrokeMode=Enum.ApplyStrokeMode.Border end
vial(chip,UDim2.fromOffset(16,20),UDim2.fromOffset(6,3))
local chipText=Style.Text(chip,'0',UDim2.fromOffset(50,22),UDim2.fromOffset(25,2));chipText.TextColor3=Color3.fromRGB(190,255,180);chipText.TextXAlignment=Enum.TextXAlignment.Left
chip.Activated:Connect(function() Sfx.play('Click');openUpgrades() end)
-- moved to the HUD metrics at the bottom left (owner, 2026-11-12); the bench opens from the weapon strip
local function chipRefresh() local n=p:GetAttribute("Mutagen") or 0;chip.Visible=false;chipText.Text=L.compact(n,L.lang()) end
p:GetAttributeChangedSignal('Mutagen'):Connect(chipRefresh);chipRefresh()
end
local reticle=Instance.new("TextLabel");reticle.Name="TargetReticle";reticle.AnchorPoint=Vector2.new(.5,.5);reticle.Size=UDim2.fromOffset(32,32);reticle.BackgroundTransparency=1;reticle.Text="◇";reticle.Font=Enum.Font.GothamBold;reticle.TextSize=32;reticle.TextColor3=Pal.Orange;reticle.TextStrokeTransparency=.25;reticle.TextStrokeColor3=Pal.Stroke;reticle.Visible=false;reticle.Parent=gui
local function readyToAim()
 return p:GetAttribute("ActiveSlot")==2 and not p:GetAttribute("DiggingGrave") and state and not state.holstered and not p:GetAttribute("Training") and workspace:GetServerTimeNow()>=(p:GetAttribute("WeaponDrawUntil") or 0) and (auto or held) and focused and not menuOpen() and not UIS:GetFocusedTextBox() and not p:GetAttribute("CarryingZombie") and not p:GetAttribute("InHouse") and workspace:GetServerTimeNow()>=(p:GetAttribute("RoadBatUntil") or 0) and workspace:GetServerTimeNow()>=(p:GetAttribute("RoadStunnedUntil") or 0)
end
local function muzzlePosition(player,fallback)
 local held=heldModels[player];local m=held and held.model.PrimaryPart;local attachment=m and m:FindFirstChild("Muzzle")
 return attachment and attachment.WorldPosition or fallback
end
local function trace(a,b,color)
 if (a-b).Magnitude<.01 then return end
 local q=Instance.new("Part");q.Name="CombatTracer";q.Anchored=true;q.CanCollide=false;q.CanQuery=false;q.CanTouch=false;q.Material=Enum.Material.Neon;q.Color=color;q.Size=Vector3.new(.09,.09,(a-b).Magnitude);q.CFrame=CFrame.lookAt((a+b)/2,b);q.Parent=workspace;Tween:Create(q,TweenInfo.new(C.TracerSeconds),{Transparency=1,Size=Vector3.new(.025,.025,q.Size.Z)}):Play();Debris:AddItem(q,C.TracerSeconds)
end
local function muzzle(pos,color)
 local q=Instance.new("Part");q.Shape=Enum.PartType.Ball;q.Size=Vector3.one*.45;q.Color=color;q.Material=Enum.Material.Neon;q.Anchored=true;q.CanCollide=false;q.CanTouch=false;q.CanQuery=false;q.Position=pos;q.Parent=workspace;Tween:Create(q,TweenInfo.new(.065),{Size=Vector3.one*.1,Transparency=1}):Play();Debris:AddItem(q,.07)
end
local cameraKick=0
local function gunShot(who,id)
 local gun=heldModels[who];if not gun or not gun.model.PrimaryPart then return end
 gun.shotAt=os.clock()
 local main=gun.model.PrimaryPart
 local q=Instance.new('Part');q.Name='SpentCasing';q.Size=Vector3.new(.09,.09,id=='Deagle' and .18 or .28);q.Color=Color3.fromRGB(219,177,87);q.Material=Enum.Material.Metal;q.Anchored=true;q.CanCollide=false;q.CanTouch=false;q.CanQuery=false
 local cf=main.CFrame;q.CFrame=cf*CFrame.new(.35,.2,.15);q.Parent=workspace
 local start=q.Position;local target=start+cf.RightVector*(1.5+math.random()*.4)+Vector3.new(0,.6,0)
 Tween:Create(q,TweenInfo.new(.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=target,Orientation=Vector3.new(80,160,30)}):Play()
 task.delay(.15,function() if q.Parent then Tween:Create(q,TweenInfo.new(.35,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=target+cf.RightVector*.6-Vector3.new(0,2.4,0),Transparency=1,Orientation=Vector3.new(200,300,160)}):Play() end end);Debris:AddItem(q,.52)
 if who==p and p:GetAttribute('CameraShake')~=false then cameraKick=math.min(cameraKick+C[id].Recoil*.012,.025) end
end
Run:BindToRenderStep('WeaponCameraFeedback',Enum.RenderPriority.Camera.Value+1,function(dt)
 cameraKick*=math.exp(-math.min(dt,.1)*18)
 if p:GetAttribute('CameraShake')==false then cameraKick=0;return end
 if cameraKick>.00005 then workspace.CurrentCamera.CFrame*=CFrame.Angles(cameraKick*math.sin(os.clock()*65),0,cameraKick*.2*math.sin(os.clock()*41)) end
end)
local blockers={}
local function trackCollider(x)
 local world=workspace:FindFirstChild("DigAZombie")
 if x:IsA("BasePart") and world and x:IsDescendantOf(world) and not x:FindFirstAncestor("Zombie") and not x:FindFirstAncestor("Shopkeeper") then blockers[x]=true end
end
for _,x in ipairs(workspace:GetDescendants()) do trackCollider(x) end
workspace.DescendantAdded:Connect(trackCollider);workspace.DescendantRemoving:Connect(function(x) blockers[x]=nil end)
local function aimPoint()
 local ch=p.Character;local head=ch and ch:FindFirstChild("Head");if not head then return end
 local f=workspace:FindFirstChild("Mutants");local targets={};local include={}
 for x in pairs(blockers) do if x.Parent and x.CanCollide and x.CanQuery then table.insert(include,x) end end
 for _,m in ipairs(f and f:GetChildren() or {}) do if m.PrimaryPart and (m:GetAttribute("Health") or 0)>0 and m:GetAttribute("State")~="Spawning" then
  table.insert(include,m.PrimaryPart)
  local dist=(m.PrimaryPart.Position-head.Position).Magnitude
  if dist<=(state.range or C[state.equipped].Range) then table.insert(targets,{model=m,dist=dist}) end
 end end
 table.sort(targets,function(a,b) if a.model==currentTarget and b.model~=currentTarget then return true elseif b.model==currentTarget and a.model~=currentTarget then return false end;return a.dist<b.dist end)
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances=include
 for _,target in ipairs(targets) do local part=target.model.PrimaryPart;local hit=workspace:Raycast(head.Position,part.Position-head.Position,params)
  if hit and hit.Instance==part then return part.Position,target.model end
 end
end
local function shoot()
 if not readyToAim() or not currentAim or os.clock()<nextShot or os.clock()-targetSince<C.AimWarmup then return end
 local ch=p.Character;local head=ch and ch:FindFirstChild("Head");local root=ch and ch:FindFirstChild("HumanoidRootPart");local h=ch and ch:FindFirstChildOfClass("Humanoid")
 if not head or not root or not h or h.Health<=0 then return end
 local aim,target=aimPoint();if not aim or target~=currentTarget then return end
 local delta=aim-head.Position;local flat=Vector3.new(delta.X,0,delta.Z)
 if delta.Magnitude<.01 or delta.Magnitude>(state.range or C[state.equipped].Range) or (flat.Magnitude>.1 and root.CFrame.LookVector:Dot(flat.Unit)<math.cos(C.UpperBodyYaw)) then return end
 local cfg=C[state.equipped]
 if not auto and not cfg.Automatic and manualSpent then return end
 if state.reloadLeft>0 then return end
 nextShot=os.clock()+1/(state.fireRate or cfg.FireRate) -- upgraded guns fire faster
 if state.ammo<=0 then Sfx.play("Empty"..state.equipped,.2);rem.WeaponAction:FireServer("reload");return end
 -- Local prediction: pose/flash immediately; hit feedback only after the server confirms.
 manualSpent=true;state.ammo-=1;ammo.Text=state.ammo.."/"..(state.magazine or cfg.Magazine)
 if poses[p] then poses[p]:Kick(cfg.Recoil) end;gunShot(p,state.equipped)
 local origin=muzzlePosition(p,head.Position)
 -- Keep visuals on the near side of a wall even if the long barrel pokes through it.
 local include={};for x in pairs(blockers) do if x.Parent and x.CanCollide and x.CanQuery then table.insert(include,x) end end
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances=include
 local obstruction=workspace:Raycast(head.Position,origin-head.Position,params)
 if obstruction then origin=obstruction.Position-(origin-head.Position).Unit*.08 end
 muzzle(origin,cfg.Color);trace(origin,aim,cfg.Color)
 Sfx.play("Fire"..state.equipped,(state.equipped=="AK" or state.equipped=="M4") and .095 or .05);rem.WeaponFire:FireServer(state.equipped,aim)
end
UIS.InputBegan:Connect(function(input,processed)
 if processed or UIS:GetFocusedTextBox() or menuOpen() then return end
 if input.UserInputType==Enum.UserInputType.MouseButton1 and not p:GetAttribute("HoldingZombie") then if p:GetAttribute("ActiveSlot")==1 then roadAction("bat") elseif p:GetAttribute("ActiveSlot")==2 then held=true;manualSpent=false end end
 if input.KeyCode==Enum.KeyCode.F and not menuOpen() then roadAction("bat")
  elseif input.KeyCode==Enum.KeyCode.LeftShift or input.KeyCode==Enum.KeyCode.RightShift then if p:GetAttribute("ShiftSlow")~=false then equipment:FireServer("slow") end
 elseif input.KeyCode==Enum.KeyCode.R then rem.WeaponAction:FireServer("reload")
 elseif input.KeyCode==Enum.KeyCode.G then if p:GetAttribute("CarryingGrave") then roadAction("dropGrave") end
 else local n=({[Enum.KeyCode.One]=1,[Enum.KeyCode.Two]=2,[Enum.KeyCode.Three]=3,[Enum.KeyCode.Four]=4,[Enum.KeyCode.Five]=5})[input.KeyCode]
  if n==1 or n==2 then pressSlot(n) elseif n==3 then pressSlot(4) elseif n==4 then pressGraves() elseif n==5 then extra.press() end end
end)
UIS.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then held=false end end)
UIS.WindowFocusReleased:Connect(function() focused=false;held=false end)
UIS.WindowFocused:Connect(function() focused=true end)
rem:WaitForChild("WeaponState").OnClientEvent:Connect(function(s)
 state=s;rangeLabel.Text="↔ "..(s.range or C[s.equipped].Range);weaponIcon.Image="";weaponTile.Text="";showWeapon(s.equipped)
 local count=0;for _,id in ipairs(C.Order) do if s.owned[id] then count+=1 end end
 for id,d in pairs(dotFor) do d.Visible=count>1 and s.owned[id]==true;d.BackgroundColor3=id==s.equipped and C[id].Color or Pal.Common end
 if s.reloadLeft>0 and not reloadWas then Sfx.play("Reload"..s.equipped,.3) end;reloadWas=s.reloadLeft>0
 ammo.Text=s.reloadLeft>0 and "…" or (s.ammo.."/"..(s.magazine or C[s.equipped].Magazine));if upgradeRefresh then upgradeRefresh() end
end)
rem:WaitForChild("WeaponFX").OnClientEvent:Connect(function(uid,id,origin,ends,aim,didHit)
 if uid==p.UserId then if didHit then hitUntil=os.clock()+.16 end;return end
 local who=Players:GetPlayerByUserId(uid)
 if (workspace.CurrentCamera.CFrame.Position-origin).Magnitude>150 then return end
 if who and poses[who] then poses[who]:Kick(C[id].Recoil) end;if who then gunShot(who,id) end
 local from=who and muzzlePosition(who,origin) or origin
 muzzle(from,C[id].Color);for _,last in ipairs(ends) do trace(from,last,C[id].Color) end;Sfx.play("Fire"..id,.12,.7*Sfx.at(from,15,150))
end)
local function updateGun(player)
 local ch=player.Character;local hand=ch and (ch:FindFirstChild("RightHand") or ch:FindFirstChild("Right Arm"));local id=player:GetAttribute("EquippedWeapon")
 local skin=player:GetAttribute("EquippedWeaponSkin") or "Default"
 local onBack=player:GetAttribute("ActiveSlot")~=2 or player:GetAttribute("WeaponHolstered") or player:GetAttribute("Training") or player:GetAttribute("DiggingGrave")
 if onBack then hand=nil end -- one weapon at a time (owner, 2026-11-13): a gun out of your hands is not shown on the back
 local old=heldModels[player];local from=old and old.model.PrimaryPart and old.model.PrimaryPart.CFrame
 if old and (not hand or old.hand~=hand or old.id~=id or old.skin~=skin or old.onBack~=onBack or not old.model.Parent) then old.model:Destroy();heldModels[player]=nil;old=nil end
 if hand and C[id or ""] and not old then
  local cf=hand.CFrame*(onBack and (CFrame.new(.4,0,.7)*CFrame.Angles(0,math.pi/2,-.5)) or (CFrame.new(0,-.1,0)*CFrame.new(-require(S.WorldArt).Anchor(require(S.WeaponSkins).Asset(id,skin),"Grip"))));local m=Models.Build(id,ch,cf,skin)
  local grip=Instance.new("Weld");grip.Name="VisualGrip";grip.Part0=hand;grip.Part1=m.PrimaryPart;grip.C0=hand.CFrame:ToObjectSpace(m.PrimaryPart.CFrame);grip.Parent=m.PrimaryPart
  -- How far the gun reaches behind the grip and above it (in its own frame): the hold below keeps that much
  -- clear of the chest and the head, whatever the gun is.
  local rear,top=.5,.4
  if not onBack then
   -- measured in the hand's own frame: in the hold the hand looks where the gun shoots, so +Z is "behind the grip"
   rear,top=0,0
   for _,q in m:GetDescendants() do if q:IsA("BasePart") then
    for sx=-1,1,2 do for sy=-1,1,2 do for sz=-1,1,2 do
     local v=hand.CFrame:PointToObjectSpace((q.CFrame*CFrame.new(q.Size.X/2*sx,q.Size.Y/2*sy,q.Size.Z/2*sz)).Position)
     rear=math.max(rear,v.Z);top=math.max(top,v.Y)
    end end end
   end end
   rear=math.clamp(rear,.2,1.8);top=math.clamp(top*.7,.1,.7) -- the box overstates a thin sight
  end
  heldModels[player]={model=m,hand=hand,id=id,skin=skin,grip=grip,rest=grip.C0,onBack=onBack,from=from,transitionAt=os.clock(),rear=rear,top=top}
 end
end
-- Wave text comes exclusively from MutantService via Notice, once per wave.
Run.PreAnimation:Connect(function()
 local now=workspace:GetServerTimeNow()
 for player,pose in pairs(poses) do
  pose:Restore()
  local ch=pose.character;local h=ch:FindFirstChildOfClass('Humanoid');local arm=ch:FindFirstChild('LeftUpperArm');local hand=ch:FindFirstChild('LeftHand');local gun=heldModels[player]
  if h and arm and hand then
   local ik=h:FindFirstChild('SupportHandIK')
   if not ik then ik=Instance.new('IKControl');ik.Name='SupportHandIK';ik.Type=Enum.IKControlType.Position;ik.ChainRoot=arm;ik.EndEffector=hand;ik.SmoothTime=.04;ik.Priority=20;ik.Parent=h end
   local active=gun and gun.model.Parent and not gun.onBack and h.Health>0 and now>=(player:GetAttribute('RoadBatUntil') or 0) and now>=(player:GetAttribute('KnockedOutUntil') or 0)
   local reloadProgress=gun and now<(player:GetAttribute('WeaponReloadUntil') or 0) and math.clamp(1-((player:GetAttribute('WeaponReloadUntil') or 0)-now)/(player:GetAttribute('WeaponReloadTime') or C[gun.id].Reload),0,1) or nil
   local reloadTilt=reloadProgress and WeaponAnimation.Sample(gun.id,100,reloadProgress).tilt or 0
   ik.Target=active and (reloadProgress and reloadProgress>.1 and reloadProgress<.83 and gun.model:FindFirstChild('Magazine') or gun.model.PrimaryPart:FindFirstChild('SupportHand')) or nil;ik.Enabled=active==true or typeof(active)=='Instance';ik.Weight=ik.Enabled and 1 or 0
   ch:SetAttribute('SupportIKActive',ik.Enabled)
   local right=h:FindFirstChild('WeaponHandIK');local root=ch:FindFirstChild('HumanoidRootPart')
   if root and ch:FindFirstChild('RightUpperArm') and ch:FindFirstChild('RightHand') then
    local target=root:FindFirstChild('WeaponHandTarget') or Instance.new('Attachment',root);target.Name='WeaponHandTarget'
    if not right then right=Instance.new('IKControl');right.Name='WeaponHandIK';right.Type=Enum.IKControlType.Transform;right.ChainRoot=ch.RightUpperArm;right.EndEffector=ch.RightHand;right.SmoothTime=.04;right.Priority=10;right.Target=target;right.Parent=h end
    local aiming=player==p and currentAim~=nil or now<(player:GetAttribute('CombatAimUntil') or 0)
    -- Firearm hands are placed by CombatPose.GunArms (exact two-bone solve from the posed chest and head). Roblox's
    -- IKControl missed its target by up to 0.8 studs on this rig, which is how the gun ended up inside the body;
    -- it now only fills in while the pose has no gun to work with.
    target.CFrame=CFrame.new(CFrame.Angles(0,pose.yaw or 0,0)*Vector3.new(.45,.2,-1.2))*CFrame.Angles(0,pose.yaw or 0,0)
    local solved=pose.gunArms==true
    local shovel=ShovelMotion.ForPlayer(player,now)
    -- Shovel chains are solved together with the body turn in CombatPose.
    -- Firearm IK is unchanged and resumes as soon as the shovel is put away.
    right.Type=Enum.IKControlType.Transform;right.Pole=nil;ik.Pole=nil
    right.Enabled=not shovel and not solved and ik.Enabled;right.Weight=right.Enabled and 1 or 0
    if shovel or solved then ik.Enabled=false;ik.Weight=0 end
    ch:SetAttribute('WeaponIKActive',right.Enabled or solved or shovel~=nil)
    ch:SetAttribute('SupportIKActive',ik.Enabled or solved and pose.gunLeft==true or shovel~=nil and shovel.left>.15)
   end
  end
 end
end)
Run.PreSimulation:Connect(function(dt)
 for _,player in ipairs(Players:GetPlayers()) do
  local ch=player.Character;local h=ch and ch:FindFirstChildOfClass("Humanoid");local root=ch and ch:FindFirstChild("HumanoidRootPart")
  local pose=poses[player]
  if pose and pose.character~=ch then pose:Restore();poses[player]=nil;pose=nil end
  if ch and h and root then
   if not pose then pose=Pose.New(ch);poses[player]=pose end
   local now=workspace:GetServerTimeNow()
   local aim=player==p and currentAim or (now<(player:GetAttribute("CombatAimUntil") or 0) and player:GetAttribute("CombatAim") or nil)
   if player==p and not readyToAim() then aim=nil end
   local disabled=h.Health<=0 or h.Sit or player:GetAttribute("InHouse") or player:GetAttribute("CarryingZombie") or now<(player:GetAttribute("RoadBatUntil") or 0) or now<(player:GetAttribute("RoadStunnedUntil") or 0)
   local reloadActive=not disabled and now<(player:GetAttribute("WeaponReloadUntil") or 0)
   if disabled then aim=nil end
   if player==p then
    -- Running with a target ahead: the legs keep following the run and only the upper body turns (CombatPose).
    -- Standing still, or the target behind: the whole body turns to it, and the legs backpedal (Animate).
    local flat=aim and Vector3.new(aim.X,root.Position.Y,aim.Z)
    local turnBody=aim and (flat-root.Position).Magnitude>.1
    if turnBody and h.MoveDirection.Magnitude>.1 and h.MoveDirection.Unit:Dot((flat-root.Position).Unit)>math.cos(C.UpperBodyYaw) then turnBody=false end
    if turnBody then
     if rotatingHumanoid~=h then if rotatingHumanoid and rotatingHumanoid.Parent then rotatingHumanoid.AutoRotate=savedAutoRotate end;rotatingHumanoid=h;savedAutoRotate=h.AutoRotate end
     h.AutoRotate=false
     root.CFrame=root.CFrame:Lerp(CFrame.lookAt(root.Position,flat),1-math.exp(-dt*12))
    elseif rotatingHumanoid then if rotatingHumanoid.Parent then rotatingHumanoid.AutoRotate=savedAutoRotate end;rotatingHumanoid=nil end
   end
   local id=player:GetAttribute("EquippedWeapon") or "Deagle"
   pose.held=heldModels[player] -- CombatPose places both hands on it (GunArms)
   pose:Step(dt,aim,id,reloadActive,math.max(0,(player:GetAttribute("RoadBatUntil") or 0)-now),player:GetAttribute("Training"),math.clamp(((player:GetAttribute("WeaponDrawUntil") or 0)-now)/.45,0,1))
   local gun=heldModels[player]
   if gun then local reload=reloadActive and math.clamp(1-((player:GetAttribute('WeaponReloadUntil') or now)-now)/(player:GetAttribute('WeaponReloadTime') or C[id].Reload),0,1) or nil;WeaponAnimation.Step(gun.model,gun.id,os.clock()-(gun.shotAt or -100),reload) end
   ch:SetAttribute("CombatPoseWeight",pose.weight) -- local diagnostic, no gameplay authority
  end
 end
end)
Run.RenderStepped:Connect(function(dt)
 if os.clock()>=nextScan then
  nextScan=os.clock()+C.TargetScan
  local aim,target
  if readyToAim() then aim,target=aimPoint() end
  if currentTarget~=target then targetSince=os.clock() end
  currentAim,currentTarget=aim,target
 elseif currentTarget and currentTarget.PrimaryPart then currentAim=currentTarget.PrimaryPart.Position end
 reticle.Visible=currentAim~=nil and readyToAim() and not (state and state.reloadLeft>0)
 if reticle.Visible then
  local pt,onScreen=workspace.CurrentCamera:WorldToViewportPoint(currentAim)
  local inset=game:GetService("GuiService"):GetGuiInset()
  reticle.Position=UDim2.fromOffset(pt.X-inset.X,pt.Y-inset.Y);reticle.Visible=onScreen
  reticle.Text=os.clock()<hitUntil and "×" or "◇";reticle.TextColor3=os.clock()<hitUntil and Pal.Mint or Pal.Orange
 end
 for player,heldGun in pairs(heldModels) do
  local pose=poses[player];local hand=heldGun.hand
  if pose and hand.Parent and heldGun.grip.Parent and not heldGun.onBack then
   local ch=player.Character;local root=ch and ch:FindFirstChild("HumanoidRootPart")
   local now=workspace:GetServerTimeNow();local aim=player==p and currentAim or (now<(player:GetAttribute("CombatAimUntil") or 0) and player:GetAttribute("CombatAim") or nil)
   local reloading=now<(player:GetAttribute("WeaponReloadUntil") or 0)
   local reloadProgress=reloading and math.clamp(1-((player:GetAttribute("WeaponReloadUntil") or 0)-now)/(player:GetAttribute("WeaponReloadTime") or C[heldGun.id].Reload),0,1) or nil
   local tilt=reloadProgress and WeaponAnimation.Sample(heldGun.id,100,reloadProgress).tilt or 0
   if root then
    local goal=aim or (hand.Position+root.CFrame.LookVector*10-Vector3.new(0,4,0))
    if (goal-hand.Position).Magnitude>.1 then
     local bob=math.sin(pose.phase)*.025*math.min(root.AssemblyLinearVelocity.Magnitude/16,1)
     local rotation=CFrame.lookAt(hand.Position,goal).Rotation*CFrame.Angles(pose.recoil*.035-tilt*.55,0,-tilt*.3)
     local gripOffset=(heldGun.model:GetAttribute('OriginOffset')*heldGun.model.PrimaryPart.Grip.CFrame).Position
     local frame=CFrame.new(hand.Position-rotation:VectorToWorldSpace(gripOffset))*rotation
     local aimGrip=hand.CFrame:ToObjectSpace(frame*heldGun.model:GetAttribute("OriginOffset"))
     heldGun.grip.C0=heldGun.rest:Lerp(aimGrip,pose.weight)
    end
   end
  end
 end
 for player,gun in pairs(heldModels) do
  if gun.from and gun.hand.Parent and gun.grip.Parent then
   local t=math.clamp((os.clock()-gun.transitionAt)/.45,0,1);t=t*t*(3-2*t)
   local goal=gun.hand.CFrame*(gun.onBack and gun.rest or gun.grip.C0)
   gun.grip.C0=gun.hand.CFrame:ToObjectSpace(gun.from:Lerp(goal,t))
   if t==1 then gun.from=nil end
  end
 end

 local now=workspace:GetServerTimeNow();local slot=p:GetAttribute('ActiveSlot') or 1
 local left=math.max(0,(p:GetAttribute('RoadBatReadyAt') or 0)-now)
 cooldown.Text=left>0 and string.format('%.1f',left) or ''
 local holding=p:GetAttribute('HoldingZombie')~=nil;extra.refresh()
 for i,b in {slots[1],slots[2],slots[3],slots[4],extra.monster} do local on=holding and i==5 or not holding and i==slot;b.Outline.Color=on and Color3.new(1,1,1) or Color3.fromRGB(70,74,96);b.Outline.Thickness=on and 3 or 2;b.BackgroundTransparency=on and .1 or .25 end
 local count=0;if itemsState then count+=#(itemsState.graveInventory or {});for _,n in itemsState.vouchers or {} do count+=n end end;itemCount.Text=tostring(count);trapCount.Text='×'..tostring(p:GetAttribute('RoadTraps') or 0)
 local slowOn=p:GetAttribute('SlowMode')==true;slowLabel.Text=t('slowMode');knob.Position=slowOn and UDim2.fromOffset(59,5) or UDim2.fromOffset(5,5);track.BackgroundColor3=slowOn and Color3.fromRGB(60,140,50) or Color3.fromRGB(60,58,74);slow.Visible=not menuOpen()
 control.Visible=not menuOpen()
 if not control.Visible then held=false;strip.Visible=false end
 auto=p:GetAttribute('AutoFire')~=false
 if state then shoot() end
 local nearest,dist;local folder=workspace:FindFirstChild("Mutants");local cam=workspace.CurrentCamera
 for _,m in ipairs(folder and folder:GetChildren() or {}) do if m:GetAttribute("Owner")==p.UserId and m.PrimaryPart then local n=(m.PrimaryPart.Position-cam.CFrame.Position).Magnitude;if not dist or n<dist then nearest,dist=m,n end end end
 arrow.Visible=false
 if nearest and not menuOpen() then
  local pt,on=cam:WorldToViewportPoint(nearest.PrimaryPart.Position)
  if not on then
   local v=cam.CFrame:PointToObjectSpace(nearest.PrimaryPart.Position);local symbol=v.X<0 and "◀" or "▶"
   arrow.Text=symbol.." "..t("Imp");arrow.Position=UDim2.fromScale(v.X<0 and .32 or .77,.25);arrow.Visible=false
  end
 end
end)
task.spawn(function() while task.wait(.1) do for _,player in ipairs(Players:GetPlayers()) do updateGun(player) end end end)
Players.PlayerRemoving:Connect(function(player) if poses[player] then poses[player]:Restore();poses[player]=nil end;local x=heldModels[player];if x then x.model:Destroy();heldModels[player]=nil end end)
task.spawn(function() for _=1,10 do local ok=pcall(function() game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false) end);if ok then break end;task.wait(.5) end end)
p:GetAttributeChangedSignal("Language"):Connect(function()
 font=L.lang():sub(1,2)=="ru" and Enum.Font.GothamBlack or Enum.Font.FredokaOne
 for _,v in gui:GetDescendants() do if v:IsA('TextLabel') or v:IsA('TextButton') then v.Font=font end end;weaponTile.Text=""
end)
rem:WaitForChild("WeaponAction"):FireServer("sync")

local function placeAt(position)
 if p:GetAttribute('ActiveSlot')~=4 or menuOpen() then return end
 local cam=workspace.CurrentCamera;local ray=cam:ScreenPointToRay(position.X,position.Y);local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={workspace:FindFirstChild('DigAZombie')};params.RespectCanCollide=true
 local hit=workspace:Raycast(ray.Origin,ray.Direction*200,params);if hit then roadAction('placeTrap',hit.Position) end
end
UIS.InputBegan:Connect(function(input,processed) if not processed and input.UserInputType==Enum.UserInputType.MouseButton1 then placeAt(input.Position) end end)
UIS.TouchTapInWorld:Connect(function(position,processed)
 if processed or menuOpen() or UIS:GetFocusedTextBox() or p:GetAttribute('Training') or p:GetAttribute('DiggingGrave') or workspace:GetServerTimeNow()<(p:GetAttribute('KnockedOutUntil') or 0) then return end
 -- UI taps (including the native thumbstick/jump) never become combat input.
 for _,object in p.PlayerGui:GetGuiObjectsAtPosition(position.X,position.Y) do
  if object:IsA('GuiButton') or object.Active then return end
 end
 local slot=p:GetAttribute('ActiveSlot')
 if slot==1 and not p:GetAttribute('HoldingZombie') then roadAction('bat')
 elseif slot==2 and p:GetAttribute('AutoFire')==false then held=true;manualSpent=false;shoot();held=false
 elseif slot==4 then placeAt(position) end
end)
