-- Illustrated quest/reward content. Claims are sent through the existing server intents.
local V={}
local Style=require(script.Parent.UIStyle)
local L=require(script.Parent.Locale)
local Icons=require(script.Parent.Icons)
local Rules=require(script.Parent.QuestRules)
local RC=require(script.Parent.Config.RewardConfig)
local Ink=Style.ModalColors.Ink
local Cream=Style.ModalColors.Cream
local Gold=Style.ModalColors.Gold
local Purple=Style.ModalColors.Purple
local Green=Style.ModalColors.Green
local function rect(o,x,y,w,h) o.Position=UDim2.fromOffset(x,y);o.Size=UDim2.fromOffset(w,h);return o end
local function rounded(o,r) local c=Instance.new('UICorner');c.CornerRadius=UDim.new(0,r);c.Parent=o end
local function stroke(o,color,width) local s=Instance.new('UIStroke');s.Color=color;s.Thickness=width;s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;s.Parent=o;return s end
local function frame(parent,name,x,y,w,h,color)
 local f=Instance.new('Frame');f.Name=name;f.BorderSizePixel=0;f.BackgroundColor3=color or Cream;f.ZIndex=2;rect(f,x,y,w,h);f.Parent=parent;return f
end
local function text(parent,name,value,x,y,w,h,max,light)
 local t=Style.ModalText(Style.Text(parent,value,UDim2.fromOffset(w,h),UDim2.fromOffset(x,y)),light);t.Name=name;t.ZIndex=6;t.UITextSizeConstraint.MaxTextSize=max or 28;t.UITextSizeConstraint.MinTextSize=8;return t
end
local function card(parent,name,x,y,w,h)
 local f=Style.ModalSurface(Instance.new('Frame'));f.Name=name;rect(f,x,y,w,h);f.ZIndex=2;f.MarketSkin.ZIndex=3;f.Parent=parent;return f
end
local function art(parent,kind,id,x,y,w,h)
 local a=Style.ModalArt(parent,kind,id,UDim2.fromOffset(w,h),UDim2.fromOffset(x,y));a.ZIndex=5;return a
end
local function icon(parent,key,x,y,w,h)
 local a=Instance.new('ImageLabel');a.Name='Illustration';a.BackgroundTransparency=1;a.ScaleType=Enum.ScaleType.Fit;a.Image=Icons[key] or '';a.ZIndex=5;rect(a,x,y,w,h);a.Parent=parent;return a
end
local function pill(parent,name,value,x,y,w,h,color)
 local f=frame(parent,name,x,y,w,h,color or Purple);rounded(f,13);stroke(f,Color3.fromRGB(184,113,63),2)
 local g=Instance.new('UIGradient');g.Rotation=90;g.Color=ColorSequence.new(color or Purple,(color or Purple):Lerp(Ink,.5));g.Parent=f
 return text(f,'Caption',value,5,1,w-10,h-2,29,true),f
end
local function button(parent,name,value,x,y,w,h,enabled,callback)
 local b=Instance.new('TextButton');b.Name=name;b.Text=value;b.Font=Style.Font();b.TextScaled=true;b.AutoLocalize=false;b.ZIndex=6;rect(b,x,y,w,h);b.Parent=parent
 Style.ModalButton(b,enabled and Green or Color3.fromRGB(162,155,146));b.AutoButtonColor=enabled;b.Selectable=enabled;b:SetAttribute('Available',enabled)
 local pending=false
 b.Activated:Connect(function()
  if not enabled or pending then return end
  pending=true;b.Text='…';b.AutoButtonColor=false;callback()
  task.delay(2,function() if b.Parent then pending=false;b.Text=value;b.AutoButtonColor=enabled end end)
 end)
 return b
end
local function progress(parent,x,y,w,h)
 local track=frame(parent,'Progress',x,y,w,h,Purple);rounded(track,h/2);stroke(track,Cream,2)
 local fill=frame(track,'Fill',3,3,w-6,h-6,Green);rounded(fill,h/2)
 local g=Instance.new('UIGradient');g.Rotation=90;g.Color=ColorSequence.new(Color3.fromRGB(174,248,21),Color3.fromRGB(61,147,0));g.Parent=fill
 local count=text(track,'Count','',6,0,w-12,h,29,true)
 return {fill=fill,count=count,width=w-6}
end
local function setProgress(bar,n,total,caption)
 bar.fill.Size=UDim2.fromOffset(bar.width*math.clamp(n/math.max(total,1),0,1),bar.fill.Size.Y.Offset)
 bar.fill.Visible=n>0;bar.count.Text=caption
end
function V.Create(panel,kind,state,send,locale)
 local lang=locale or L.lang();local function t(k,a) return L.text(k,lang,a) end
 local root=frame(panel,'ReferenceContent',36,174,778,614);root.BackgroundTransparency=1;root.ZIndex=12
 local view={Root=root,bars={}}
 if kind=='quests' then
  local q=state.quests
  if not q then return view end
  for i,item in q.items do
   local f=card(root,'Quest_'..item.id,0,(i-1)*144,778,134)
   local id=(item.id or ''):match('^%a+')
   if id=='upgrade' then icon(f,'house',8,10,205,112)
   elseif id=='hatch' then art(f,'pumpkin','Pumpkin',8,10,205,112)
   elseif id=='kill' or id=='rare' then
    art(f,'grave','Stone',65,10,135,112);art(f,'shovel','Rusty',4,10,95,112)
   elseif id=='time' or id=='dawn' then icon(f,'sun',24,14,165,105)
   elseif id=='earn' then art(f,'cash',nil,18,15,185,100)
   else art(f,'grave','Stone',15,6,192,120) end
   local heading=text(f,'Description',t((id=='road' or id=='rare') and 'referenceQuest_'..id or 'quest_'..item.id,{n=L.compact(Rules.Show(item,item.goal),lang)}),237,12,320,57,30)
   heading.TextXAlignment=Enum.TextXAlignment.Left;heading.TextSize=28;heading.TextScaled=false;heading:SetAttribute('FixedTypography',true)
   local bar=progress(f,238,83,314,33);view.bars[item.id]=bar
   frame(f,'Divider',574,17,2,100,Color3.fromRGB(211,164,105))
   art(f,'cash',nil,617,4,117,58)
   pill(f,'Reward','$'..L.compact(item.reward,lang),612,item.progress>=item.goal and 57 or 78,128,32)
   if item.progress>=item.goal or item.claimed then
    button(f,'Claim',t(item.claimed and 'referenceClaimed' or 'claim'),598,95,156,32,not item.claimed,function() send('quest',item.id) end)
   end
  end
  local f=card(root,'QuestBonus',0,440,778,144)
  local banner=frame(f,'PurpleBanner',10,10,758,124,Purple);rounded(banner,15);stroke(banner,Gold,2)
  icon(banner,'daily',9,5,198,113)
  text(banner,'Heading',t('referenceAllQuests'),220,6,343,46,38,true)
  local bar=progress(banner,224,70,305,34);view.bonusBar=bar
  frame(banner,'Divider',548,18,2,90,Gold)
  art(banner,'grave',q.bonus.grave,570,1,173,115)
  local caption=text(banner,'Prize','×'..q.bonus.count,672,87,64,28,24,true)
  local ready=not q.bonusClaimed
  for _,item in q.items do ready=ready and item.claimed end
  if ready or q.bonusClaimed then
   bar.fill.Parent.Visible=false
   button(banner,'Claim',t(q.bonusClaimed and 'referenceClaimed' or 'claim'),224,67,305,39,ready,function() send('quest','bonus') end)
  end
  view.timer=text(root,'ResetTimer','',120,592,538,24,19)
  function view:Update(s)
   local data=s.quests;if not data then return end
   local completed=0
   for _,item in data.items do
    local bar=self.bars[item.id]
    if bar then setProgress(bar,item.progress,item.goal,L.compact(Rules.Show(item,item.progress),lang)..' / '..L.compact(Rules.Show(item,item.goal),lang)) end
    if item.progress>=item.goal then completed+=1 end
   end
   setProgress(self.bonusBar,completed,#data.items,completed..' / '..#data.items)
   local left=Rules.SecondsLeft();self.timer.Text=t('questReset',{h=math.floor(left/3600),m=math.floor(left%3600/60)})
  end
  view:Update(state)
 else
  pill(root,'DailyHeading',t('referenceDailyRewards'),155,0,468,46,Cream)
  local heading=root.DailyHeading.Caption;heading.TextColor3=Ink;heading.ModalTextOutline.Transparency=1
  frame(root,'LineLeft',20,23,121,2,Ink);frame(root,'LineRight',637,23,121,2,Ink)
  local today=state.dailyNext or state.dailyStreak or 1
  for i,prize in RC.Daily do
   local special=i==#RC.Daily
   local x,y=(i<=4 and i-1 or i-5)*195,i<=4 and 73 or 318
   local w,h=special and 388 or 183,225
   local f=card(root,'Day'..i,x,y,w,h)
   local claimable=i==today and state.dailyReady==true
   local claimed=i<today or i==today and not state.dailyReady
   if special then
    local banner=frame(f,'SpecialBanner',8,8,w-16,h-16,Purple);rounded(banner,13);stroke(banner,Gold,2)
    pill(banner,'Day',t('daily',{n=i}),0,0,151,39,Gold)
    text(banner,'Special',t('referenceSpecialReward'),15,53,159,77,30,true)
    art(banner,prize.Coins and 'cash' or 'grave',prize.Grave,171,27,195,160)
    local name=prize.Coins and '$'..L.compact(prize.Coins,lang) or t('referenceGravePrize',{name=t('grave_'..prize.Grave)})
    text(banner,'Prize',name,14,134,160,40,23,true)
    local b=button(banner,'Claim',claimable and t('claim') or claimed and t('referenceClaimed') or '',13,174,w-42,30,claimable,function() send('daily') end)
    if not claimable and not claimed then icon(b,'lock',145,3,25,24) end
   else
    if claimed then local tint=frame(f,'ClaimedTint',9,9,w-18,h-18,Color3.fromRGB(148,189,80));tint.BackgroundTransparency=.65;rounded(tint,12) end
    text(f,'Day',t('daily',{n=i}),6,10,w-12,34,29)
    art(f,prize.Coins and 'cash' or 'grave',prize.Grave,31,50,w-62,87)
    local value=prize.Coins and '$'..L.compact(prize.Coins,lang) or '×'..prize.Count..' '..t(prize.Grave)
    pill(f,'Prize',value,20,139,w-40,32)
    local b=button(f,'Claim',claimable and t('claim') or claimed and '✓ '..t('referenceClaimed') or '',12,180,w-24,35,claimable,function() send('daily') end)
    if claimed then b.BackgroundColor3=Color3.fromRGB(112,164,62) end
    if not claimable and not claimed then icon(b,'lock',(w-49)/2,3,25,29) end
   end
   if claimable then
    f.UIStroke.Color=Gold;f.UIStroke.Thickness=4;f.UIStroke.Transparency=0
    local glow=stroke(f,Color3.fromRGB(255,230,57),6);glow.Transparency=.4
   end
  end
  function view:Update() end
 end
 -- Keep all painted children above the modal background.
 local function lift(container)
  for _,o in container:GetChildren() do
   if o:IsA('GuiObject') then
    o.ZIndex=container.ZIndex+(o.Name=='MarketSkin' and 1 or 2+o.ZIndex)
    lift(o)
   end
  end
 end
 lift(root)
 task.defer(function()
  if root.Parent then for _,o in root:GetDescendants() do if (o:IsA('TextLabel') or o:IsA('TextButton')) and not o:GetAttribute('FixedTypography') then o.TextScaled=true end end end
 end)
 return view
end
return V
