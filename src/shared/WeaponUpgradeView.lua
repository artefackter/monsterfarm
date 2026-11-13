-- Weapon workshop. The view only previews WeaponUpgrades; purchases remain server-authoritative.
local V={}
local Style=require(script.Parent.UIStyle)
local L=require(script.Parent.Locale)
local Icons=require(script.Parent.Icons)
local C=require(script.Parent.Config.WeaponConfig)
local Up=require(script.Parent.WeaponUpgrades)
local Ink=Color3.fromRGB(81,28,65)
local Cream=Color3.fromRGB(255,238,200)
local Gold=Color3.fromRGB(255,190,23)
local Purple=Color3.fromRGB(105,33,101)
local Green=Color3.fromRGB(127,218,0)
local function rect(o,x,y,w,h) o.Position=UDim2.fromOffset(x,y);o.Size=UDim2.fromOffset(w,h);return o end
local function stroke(o,color,width)
 local s=Instance.new('UIStroke');s.Color=color;s.Thickness=width;s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;s.Parent=o;return s
end
local function corner(o,r) local c=Instance.new('UICorner');c.CornerRadius=UDim.new(0,r);c.Parent=o end
local function gradient(o,top,bottom)
 local g=Instance.new('UIGradient');g.Rotation=90;g.Color=ColorSequence.new(top,bottom);g.Parent=o;return g
end
local function frame(parent,name,x,y,w,h,color,z,r)
 local f=Instance.new('Frame');f.Name=name;f.BorderSizePixel=0;f.BackgroundColor3=color or Cream;f.ZIndex=z or 2;rect(f,x,y,w,h);f.Parent=parent;if r then corner(f,r) end;return f
end
local function label(parent,name,value,x,y,w,h,max,light)
 local l=Style.ModalText(Style.Text(parent,value,UDim2.fromOffset(w,h),UDim2.fromOffset(x,y)),light)
 l.Name=name;l.ZIndex=6;l.UITextSizeConstraint.MaxTextSize=max or 28;l.UITextSizeConstraint.MinTextSize=8;l.TextWrapped=false;return l
end
local function surface(parent,name,x,y,w,h)
 local f=Style.ModalSurface(Instance.new('Frame'));f.Name=name;rect(f,x,y,w,h);f.ZIndex=3;f.MarketSkin.ZIndex=4;f.Parent=parent;return f
end
local function chip(parent,name,x,y,w,h,color)
 local f=frame(parent,name,x,y,w,h,color or Cream,4,14);stroke(f,Color3.fromRGB(190,123,59),2)
 gradient(f,color or Color3.fromRGB(255,238,207),color and color:Lerp(Ink,.23) or Color3.fromRGB(216,180,153))
 local rim=frame(f,'Rim',3,3,w-6,h-6,Cream,5,11);rim.BackgroundTransparency=1;stroke(rim,Cream,1.4);return f
end
local function art(parent,kind,id,x,y,w,h,finish)
 local a=Style.ModalArt(parent,kind,id,UDim2.fromOffset(w,h),UDim2.fromOffset(x,y),finish);a.ZIndex=5;return a
end
local function currency(parent,name,kind,value,x,y,w,h,max)
 local f=chip(parent,name,x,y,w,h);art(f,kind,nil,10,3,h+8,h-6)
 local t=label(f,'Value',value,h+17,2,w-h-23,h-4,max or 27);return t
end
-- Small code-native illustrations share the existing illustrated market palette.
local function illustration(parent,stat)
 local box=frame(parent,'Illustration',16,16,130,108,Cream,5);box.BackgroundTransparency=1
 local steel=Color3.fromRGB(83,91,114);local dark=Color3.fromRGB(39,31,45)
 local function shape(p,n,x,y,w,h,c,r) local f=frame(p,n,x,y,w,h,c,6,r);stroke(f,dark,2);return f end
 local function bullet(p,x,y,angle)
  local b=shape(p,'Bullet',x,y,67,20,Gold,10);b.Rotation=angle or 0;gradient(b,Color3.fromRGB(255,244,149),Color3.fromRGB(226,130,0))
  local band=frame(b,'CaseBand',19,1,3,18,Color3.fromRGB(155,78,14),7);band.BorderSizePixel=0
  frame(b,'Shine',25,4,29,3,Cream,7,2);return b
 end
 local function magazine()
  local m=frame(box,'Magazine',47,16,43,86,steel,6,10);m.Rotation=22;stroke(m,dark,3);gradient(m,Color3.fromRGB(137,144,164),steel)
  for i=0,2 do local line=frame(m,'Groove',8+i*11,16,4,58,dark,7,2);line.Rotation=6 end
  for i=0,1 do local b=shape(m,'Round',6,3+i*9,33,7,Gold,3);gradient(b,Cream,Gold) end
  return m
 end
 if stat=='Damage' then
  local plate=shape(box,'ImpactPlate',43,6,73,96,Color3.fromRGB(146,141,152),9);plate.Rotation=12;gradient(plate,Color3.fromRGB(221,214,209),steel)
  for _,p in {{9,9},{60,9},{9,82},{60,82}} do shape(plate,'Rivet',p[1],p[2],5,5,Cream,3) end
  for i=0,2 do local burst=shape(box,'Impact',60,32,40,40,i==2 and Cream or Gold,0);burst.Rotation=i*30 end
  bullet(box,3,51,-3)
 elseif stat=='FireRate' then
  for i=0,2 do
   for j=1,3 do local s=frame(box,'SpeedLine',2+j*5,18+i*29+j*3,34-j*5,2,Gold,6,1);s.BackgroundTransparency=.15*j end
   bullet(box,42+(i%2)*14,13+i*30,0)
  end
 elseif stat=='Magazine' or stat=='Reload' then
  magazine()
  if stat=='Reload' then
   for half=0,1 do
    for n=0,10 do
     local angle=math.rad(-150+half*180+n*12)
     local arc=frame(box,'ReloadArc',63+53*math.cos(angle)-7,55+49*math.sin(angle)-3,15,6,Color3.fromRGB(0,167,243),8,3)
     arc.Rotation=math.deg(angle)+90;stroke(arc,Color3.fromRGB(15,67,115),1)
    end
    local angle=math.rad(-30+half*180)
    for _,side in {-1,1} do
     local head=frame(box,'ArrowHead',63+53*math.cos(angle)-10,55+49*math.sin(angle)-3,23,7,Color3.fromRGB(0,167,243),9,2)
     head.Rotation=math.deg(angle)+90+side*38;stroke(head,Color3.fromRGB(15,67,115),1)
    end
   end
  end
 elseif stat=='Crit' then
  for i=0,2 do local burst=shape(box,'CriticalBurst',38,19,66,66,i==2 and Color3.fromRGB(255,227,41) or Color3.fromRGB(255,126,23),0);burst.Rotation=i*30 end
  bullet(box,4,62,-15)
 elseif stat=='Range' then
  shape(box,'ScopeTube',5,39,48,35,steel,7)
  local scope=shape(box,'Scope',35,6,85,85,dark,45)
  local rim=shape(scope,'MetalRim',5,5,75,75,Color3.fromRGB(135,151,177),40)
  local lens=shape(rim,'Lens',5,5,65,65,Color3.fromRGB(90,181,242),35);gradient(lens,Color3.fromRGB(110,199,255),Color3.fromRGB(218,244,255));lens.ClipsDescendants=true
  local hill=frame(lens,'Landscape',-3,44,75,30,Color3.fromRGB(106,165,68),7,8);hill.Rotation=-15
  frame(lens,'CrosshairX',0,31,65,2,dark,8);frame(lens,'CrosshairY',31,0,2,65,dark,8)
  for i=1,5 do frame(lens,'Tick',i*10,28,1,8,dark,8) end
  frame(box,'Ruler',1,103,127,3,Color3.fromRGB(134,78,38),7)
  for i=0,12 do frame(box,'RulerTick',2+i*10,96-(i%2)*4,2,8+(i%2)*4,Color3.fromRGB(134,78,38),7) end
 end
 return box
end
local function value(stat,a,b,lang)
 if stat=='Crit' then return L.number(a*100,lang,0)..'% ×'..L.number(b,lang,1)
 elseif stat=='FireRate' then return L.number(a,lang,1)
 elseif stat=='Reload' then return L.text('upSeconds',lang,{n=L.number(a,lang,2)})
 elseif stat=='Range' then return L.text('upStuds',lang,{n=L.number(a,lang,1)}) end
 return L.number(a,lang,0)
end
function V.Create(parent,callbacks)
 callbacks=callbacks or {}
 local view={selected=nil,snapshot=nil,pending=nil}
 local root=Style.ModalWindow(Instance.new('Frame'));root.Name='UpgradeBench';root.AnchorPoint=Vector2.new(.5,.5);root.Position=UDim2.fromScale(.5,.5);root.Size=UDim2.fromOffset(1600,900);root.ZIndex=20;root.Visible=false;root.Active=true;root.Parent=parent
 view.Root=root
 local fit=Instance.new('UIScale');fit.Name='Fit';fit.Parent=root
 local shade=Instance.new('TextButton');shade.Name='Shade';shade.Text='';shade.AutoButtonColor=false;shade.Active=true;shade.Modal=true;shade.BackgroundColor3=Color3.fromRGB(14,8,25);shade.BackgroundTransparency=.36;shade.Size=UDim2.fromScale(1,1);shade.ZIndex=19;shade.Visible=false;shade.Parent=parent
 root:GetPropertyChangedSignal('Visible'):Connect(function() shade.Visible=root.Visible end)
 local header=Instance.new('ImageLabel');header.Name='Canopy';header.BackgroundTransparency=1;header.Image=Icons.market_canopy or '';rect(header,0,-12,1600,170);header.ZIndex=3;header.Parent=root
 local title=label(root,'Title','',270,71,1060,68,51,true)
 for _,side in {-1,1} do
  local branch=frame(root,'Laurel',800+side*367,94,54,3,Gold,6,2);branch.Rotation=side*24
  for i=0,3 do
   local leaf=frame(root,'LaurelLeaf',800+side*(370+i*11),83-i*5,9,23,Gold,6,7);leaf.Rotation=side*(28+i*8)
   gradient(leaf,Color3.fromRGB(255,236,104),Color3.fromRGB(222,143,0))
  end
 end
 local close=Instance.new('TextButton');close.Name='Close';close.Text='';close.Font=Style.Font();close.TextScaled=true;rect(close,1489,78,65,60);close.ZIndex=8;close.Parent=root;Style.ModalButton(close,Style.ModalColors.Red);Style.ModalClose(close)
 local function dismiss() root.Visible=false;if callbacks.close then callbacks.close() end end
 close.Activated:Connect(dismiss);shade.Activated:Connect(dismiss)
 local tabs={}
 for i,id in C.Order do
  local b=Instance.new('TextButton');b.Name='Gun_'..id;b.Text='';b.AutoButtonColor=false;b.ZIndex=4;rect(b,44+(i-1)*189.5,169,184.5,77);b.Parent=root
  Style.ModalButton(b,Cream)
  local picture=art(b,'weapon',id,22,1,140,48)
  local name=label(b,'Label','',5,48,174,25,23)
  local lock=Instance.new('ImageLabel');lock.Name='Lock';lock.BackgroundTransparency=1;lock.Image=Icons.lock or '';rect(lock,158,6,18,21);lock.ZIndex=7;lock.Parent=b
  tabs[id]={button=b,picture=picture,name=name,lock=lock}
  b.Activated:Connect(function() view.selected=id;view.pending=nil;if callbacks.select then callbacks.select(id) end;if view.snapshot then view:Update(view.snapshot) end end)
 end
 local summary=surface(root,'Summary',44,263,380,578)
 local ribbon=chip(summary,'WeaponRibbon',28,34,324,62,Purple)
 local gunName=label(ribbon,'WeaponName','',10,3,304,56,32,true)
 local weaponArt
 local star=label(summary,'Decoration','────────  ★  ────────',43,347,294,38,26);star.TextColor3=Color3.fromRGB(220,144,24)
 local balance=currency(summary,'Coins','cash','',25,409,330,64,40)
 local mutagen=currency(summary,'Mutagen','mutagen','',25,489,330,64,40)
 local cards={}
 for i,stat in Up.Stats do
  local col=(i-1)%3;local row=math.floor((i-1)/3)
  local tile=surface(root,'Stat_'..stat,450+col*368,266+row*286,350,274)
  illustration(tile,stat)
  local heading=label(tile,'Heading','',146,15,194,35,29)
  local levelChip=chip(tile,'LevelChip',184,55,104,30,Color3.fromRGB(228,184,202))
  local levelText=label(levelChip,'Value','',2,1,100,28,24)
  local pips={}
  for n=1,Up.Max do
   local p=frame(tile,'Pip_'..n,152+(n-1)*17,99,16,15,Green,6,6);stroke(p,Ink,1.6);gradient(p,Color3.fromRGB(195,255,45),Green);pips[n]=p
  end
  local before=label(tile,'Current','',16,130,139,37,28)
  local arrow=Style.ModalArrow(tile,UDim2.fromOffset(34,28),UDim2.fromOffset(158,134));arrow.ZIndex=6
  local after=label(tile,'Next','',196,130,139,37,28);after.TextColor3=Color3.fromRGB(20,121,17)
  local price=chip(tile,'Cost',18,173,314,44)
  art(price,'cash',nil,12,3,45,38)
  local cost=label(price,'Coins','',59,2,117,40,25)
  frame(price,'Divider',180,1,1,42,Color3.fromRGB(178,113,68),6)
  art(price,'mutagen',nil,200,1,33,42)
  local need=label(price,'Mutagen','',237,2,69,40,25)
  local buy=Instance.new('TextButton');buy.Name='Buy';buy.Font=Style.Font();buy.TextScaled=true;buy.AutoLocalize=false;buy.ZIndex=6;rect(buy,19,225,312,39);buy.Parent=tile;Style.ModalButton(buy,Green)
  local pop=Instance.new('UIScale');pop.Parent=buy
  cards[stat]={tile=tile,heading=heading,level=levelText,pips=pips,before=before,after=after,arrow=arrow,price=price,cost=cost,need=need,buy=buy}
  buy.Activated:Connect(function() view:Purchase(stat,pop) end)

 end
 local hint=label(root,'MutagenHint','',350,851,900,28,23)
 function view:Fit(size)
  fit.Scale=math.max(.1,math.min(1.25,(size.X-16)/1600,(size.Y-16)/900))
 end
 function view:Update(s)
  self.snapshot=s;self.selected=C[self.selected] and self.selected or s.equipped or C.Order[1]
  local id=self.selected;local lang=L.lang();local function t(k) return L.text(k,lang) end
  local d={weapons=s.owned or {},weaponUpgrades=s.upgrades or {},coins=s.coins or 0,mutagen=s.mutagen or 0}
  if self.pending and (Up.Level(d,self.pending.id,self.pending.stat)~=self.pending.level or os.clock()-self.pending.at>=2) then self.pending=nil end
  title.TextScaled=true;title.Text=t('weaponWorkshop');hint.Text=t('weaponWorkshopHint')
  gunName.Text=t(id)..' ('..id..')'
  balance.Text='$'..L.compact(d.coins,lang);mutagen.Text=L.number(d.mutagen,lang,0)
  local finish=s.skins and s.skins[id] or 'Default';local artKey=id..':'..finish
  if self.artKey~=artKey then
   if weaponArt then weaponArt:Destroy() end
   weaponArt=art(summary,'weapon',id,10,109,360,238,finish);weaponArt.ZIndex=25;self.artKey=artKey
  end
  for gun,tab in tabs do
   tab.name.Text=t(gun);tab.lock.Visible=not d.weapons[gun]
   if tab.picture:IsA('ImageLabel') then tab.picture.ImageTransparency=d.weapons[gun] and 0 or .45 end
   tab.button.BackgroundColor3=gun==id and Color3.fromRGB(255,215,112) or Cream
   tab.button.UIStroke.Color=gun==id and Gold or Color3.fromRGB(190,123,59);tab.button.UIStroke.Thickness=gun==id and 3 or 2
  end
  for stat,card in cards do
   local level=Up.Level(d,id,stat);local why=Up.Check(d,id,stat);local max=level>=Up.Max
   card.heading.Text=t('up_'..stat);card.level.Text=level..'/'..Up.Max
   for n,p in card.pips do
    local on=n<=level;p.BackgroundColor3=on and Green or Color3.fromRGB(208,177,195)
    p.UIGradient.Enabled=on
   end
   local a,b=Up.Value(id,stat,level);card.before.Text=value(stat,a,b,lang)
   local nextA,nextB=Up.Value(id,stat,math.min(level+1,Up.Max));card.after.Text=max and t('upMax') or value(stat,nextA,nextB,lang)
   card.arrow.Visible=not max
   local coins,mut=Up.Cost(id,stat,level);card.cost.Text=max and '—' or '$'..L.compact(coins,lang);card.need.Text=max and '—' or tostring(mut)
   local waiting=self.pending~=nil
   card.buy.Text=waiting and '…' or t(why=='max' and 'upMax' or why=='bad' and 'upLocked' or why and 'upInsufficient' or 'upgradeTile')
   local enabled=not why and not waiting
   card.buy.BackgroundColor3=max and Gold or enabled and Green or Color3.fromRGB(155,157,163)
   card.buy.AutoButtonColor=enabled;card.buy.Selectable=enabled
   card.buy:SetAttribute('Available',enabled)
  end
 end
 function view:Purchase(stat,pop)
  local s=self.snapshot;if not s or self.pending or not cards[stat] then return false end
  local data={weapons=s.owned,weaponUpgrades=s.upgrades,coins=s.coins,mutagen=s.mutagen}
  if Up.Check(data,self.selected,stat) then return false end
  self.pending={id=self.selected,stat=stat,level=Up.Level(data,self.selected,stat),at=os.clock()}
  if pop then Style.Pop(pop,1) end;self:Update(s)
  if callbacks.buy then callbacks.buy(self.selected,stat) end
  task.delay(2,function()
   if root.Parent and self.pending and os.clock()-self.pending.at>=1.9 then
    self.pending=nil;if self.snapshot then self:Update(self.snapshot) end
   end
  end)
  return true
 end
 function view:Open(s) if s then self.selected=s.equipped;self:Update(s) end;root.Visible=true end
 local function fitWindow() view:Fit(parent.AbsoluteSize) end
 -- UIStyle's decorative children start at layer 1. Lift the entire workshop together
 -- so the modal's background cannot cover its own painted skins.
 for _,o in root:GetDescendants() do
  if o:IsA('GuiObject') then o.ZIndex+=20 end
 end
 local function refreshText()
  for _,o in root:GetDescendants() do
   if o:IsA('TextLabel') or o:IsA('TextButton') then o.TextScaled=true end
  end
 end
 task.defer(refreshText)
 parent:GetPropertyChangedSignal('AbsoluteSize'):Connect(fitWindow);fitWindow()
 return view
end
return V
