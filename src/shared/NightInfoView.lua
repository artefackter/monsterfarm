-- Painted decoration, live/localized text and native controls. No player-data side effects.
local Icons=require(script.Parent.Icons)
local L=require(script.Parent.Locale)
local Tween=game:GetService("TweenService")
local V={}
local C={Ink=Color3.fromRGB(78,23,61),Cream=Color3.fromRGB(255,231,182),Gold=Color3.fromRGB(255,193,34),Purple=Color3.fromRGB(86,21,96),Green=Color3.fromRGB(111,213,0)}
local SPECS={
 {image="night_defend",fallback="pistol",title="nightDefendTitle",body="nightDefendBody"},
 {image="night_lock",fallback="lock",title="nightLockTitle",body="nightLockBody"},
 {image="night_ruins",fallback="moon",title="nightRuinsTitle",body="nightRuinsBody"},
}
local function corner(o,r) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r);c.Parent=o end
local function stroke(o,color,width) local s=Instance.new("UIStroke");s.Color=color;s.Thickness=width;s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;s.Parent=o;return s end
local function frame(parent,name,color,z)
 local o=Instance.new("Frame");o.Name=name;o.BackgroundColor3=color;o.BorderSizePixel=0;o.ZIndex=z or 1;o.Parent=parent;return o
end
local function text(parent,name,size,color,z)
 local o=Instance.new("TextLabel");o.Name=name;o.BackgroundTransparency=1;o.Font=Enum.Font.GothamBlack;o.TextColor3=color;o.TextScaled=true;o.TextWrapped=true;o.AutoLocalize=false;o.ZIndex=z or 3;o.Parent=parent
 local limit=Instance.new("UITextSizeConstraint");limit.MinTextSize=10;limit.MaxTextSize=size;limit.Parent=o;return o
end
local function rect(o,x,y,w,h) o.Position=UDim2.fromOffset(x,y);o.Size=UDim2.fromOffset(w,h) end
local function art(parent,name,key,z)
 local o=Instance.new("ImageLabel");o.Name=name;o.BackgroundTransparency=1;o.Image=Icons[key] or "";o.ZIndex=z or 2;o.Parent=parent;return o
end
-- opts (2026-11-14, the grave-heist tutorial reuses this window): specs (three cards), title (a Locale key),
-- noTimer, name.
function V.Create(parent,callbacks,opts)
 callbacks=callbacks or {};opts=opts or {}
 local view={night=false,left=0,dontShow=false,locale=nil}
 local root=frame(parent,opts.name or "NightInfoModal",Color3.new(0,0,0),1);root.Size=UDim2.fromScale(1,1);root.BackgroundTransparency=1;root.Visible=false
 local shade=Instance.new("TextButton");shade.Name="Shade";shade.Size=UDim2.fromScale(1,1);shade.BackgroundColor3=Color3.fromRGB(12,6,25);shade.BackgroundTransparency=.32;shade.BorderSizePixel=0;shade.Text="";shade.AutoButtonColor=false;shade.Active=true;shade.Modal=true;shade.ZIndex=1;shade.Parent=root
 local board=frame(root,"NightCard",C.Cream,2);board.BackgroundTransparency=1;board.Active=true;board.AnchorPoint=Vector2.new(.5,.5);board.Position=UDim2.fromScale(.5,.5)
 local scale=Instance.new("UIScale");scale.Parent=board
 local fallback=frame(board,"FallbackFrame",C.Cream,2);fallback.Position=UDim2.fromScale(.065,.08);fallback.Size=UDim2.fromScale(.87,.84);corner(fallback,20);stroke(fallback,Color3.fromRGB(129,64,30),10)
 local skin=art(board,"PaintedNightFrame","night_frame",3);skin.Size=UDim2.fromScale(1,1)
 fallback.Visible=skin.Image==""
 local header=frame(board,"FallbackHeader",C.Purple,3);corner(header,18);stroke(header,C.Gold,3);header.Visible=skin.Image==""
 local title=text(board,"Title",64,C.Gold,4);title.TextStrokeColor3=C.Ink;title.TextStrokeTransparency=0
 local timer=text(board,"PhaseTimer",30,C.Cream,4);timer.RichText=true;timer.TextWrapped=false
 local close=Instance.new("TextButton");close.Name="Close";close.BackgroundColor3=Color3.fromRGB(224,48,47);close.Text="";close.AutoButtonColor=true;close.ZIndex=6;close.Parent=board;corner(close,13);stroke(close,C.Gold,3)
 for _,angle in {45,-45} do
  local line=frame(close,"Cross",C.Cream,7);line.AnchorPoint=Vector2.new(.5,.5);line.Position=UDim2.fromScale(.5,.5);line.Size=UDim2.fromScale(.63,.14);line.Rotation=angle;corner(line,5)
 end
 local cards={}
 for i,spec in opts.specs or SPECS do
  local tile=frame(board,"Card_"..i,C.Cream,4);corner(tile,15);stroke(tile,C.Gold,3)
  local picture=art(tile,"Illustration",spec.image,5);picture.BackgroundColor3=C.Purple;picture.BackgroundTransparency=0;picture.ScaleType=Enum.ScaleType.Crop;corner(picture,12)
  local backup=art(picture,"FallbackIcon",spec.fallback,6);backup.AnchorPoint=Vector2.new(.5,.5);backup.Position=UDim2.fromScale(.5,.5);backup.Size=UDim2.fromScale(.55,.65);backup.ScaleType=Enum.ScaleType.Fit;backup.Visible=picture.Image==""
  local ribbon=frame(tile,"TitleRibbon",C.Purple,6);corner(ribbon,12);stroke(ribbon,C.Gold,2)
  local heading=text(ribbon,"Heading",29,C.Cream,7);heading.Position=UDim2.fromOffset(8,2);heading.Size=UDim2.new(1,-16,1,-4);heading.TextStrokeColor3=C.Ink;heading.TextStrokeTransparency=0
  local body=text(tile,"Description",27,C.Ink,6)
  cards[i]={tile=tile,picture=picture,ribbon=ribbon,heading=heading,body=body,spec=spec}
 end
 local acknowledge=Instance.new("TextButton");acknowledge.Name="Acknowledge";acknowledge.Text="";acknowledge.BackgroundColor3=C.Green;acknowledge.AutoButtonColor=true;acknowledge.ZIndex=5;acknowledge.Parent=board;corner(acknowledge,30);stroke(acknowledge,C.Gold,5)
 local gradient=Instance.new("UIGradient");gradient.Rotation=90;gradient.Color=ColorSequence.new(Color3.fromRGB(170,244,15),Color3.fromRGB(62,151,0));gradient.Parent=acknowledge
 local inner=frame(acknowledge,"InnerRim",C.Green,6);inner.BackgroundTransparency=1;inner.Position=UDim2.fromOffset(5,5);inner.Size=UDim2.new(1,-10,1,-10);corner(inner,24);stroke(inner,C.Cream,2)
 local ackText=text(acknowledge,"Caption",48,C.Cream,7);ackText.Position=UDim2.fromOffset(12,3);ackText.Size=UDim2.new(1,-24,1,-6);ackText.TextStrokeColor3=Color3.fromRGB(25,71,13);ackText.TextStrokeTransparency=0
 local preference=Instance.new("TextButton");preference.Name="DontShowAgain";preference.BackgroundTransparency=1;preference.Text="";preference.ZIndex=5;preference.Parent=board
 local checkBox=frame(preference,"Box",C.Cream,6);corner(checkBox,6);stroke(checkBox,C.Ink,3)
 local check=text(checkBox,"Check",33,C.Ink,7);check.Size=UDim2.fromScale(1,1);check.Text="✓";check.Visible=false
 local preferenceText=text(preference,"Caption",25,C.Ink,6);preferenceText.TextXAlignment=Enum.TextXAlignment.Left
 local function clicked() if callbacks.close then callbacks.close() else view:SetVisible(false) end end
 close.Activated:Connect(clicked);acknowledge.Activated:Connect(clicked)
 -- The backdrop blocks input; closing is explicit so the clock click cannot dismiss the newly opened modal.
 preference.Activated:Connect(function()
  view:SetDontShow(not view.dontShow)
  if callbacks.preference then callbacks.preference(view.dontShow) end
 end)
 function view:SetDontShow(value) self.dontShow=value==true;check.Visible=self.dontShow end
 function view:Refresh()
  local lang=self.locale or L.lang();local function t(k,a) return L.text(k,lang,a) end
  title.Text=opts.title and t(opts.title) or t(self.night and "nightCardTitle" or "nightCardDay")
  if opts.noTimer then -- no countdown: the plaque under the title carries a line of its own (SetSubtitle), if any
   local args={};for k,v in self.subtitleArgs or {} do args[k]=t(v) end
   timer.Visible=self.subtitleKey~=nil;timer.Text=self.subtitleKey and t(self.subtitleKey,args) or ""
  end
  local seconds=math.max(0,math.ceil(self.left));local time=string.format("%02d:%02d",math.floor(seconds/60),seconds%60)
  if not opts.noTimer then timer.Text=t(self.night and "nightUntilDawn" or "nightUntilDusk",{time='<font color="#FFE14A">'..time..'</font>'}) end
  for _,row in cards do row.heading.Text=t(row.spec.title);row.body.Text=t(row.spec.body) end
  ackText.Text=t("nightUnderstood");preferenceText.Text=t("nightDontShowAgain")
 end
 function view:SetSubtitle(key,args) self.subtitleKey=key;self.subtitleArgs=args;self:Refresh() end
 function view:Update(night,left,locale) self.night=night==true;self.left=left or 0;self.locale=locale;self:Refresh() end
 function view:Fit(viewport)
  local portrait=viewport.X<viewport.Y*.95
  local w,h=portrait and 620 or 1280,portrait and 1120 or 720
  board.Size=UDim2.fromOffset(w,h)
  scale.Scale=math.max(.1,math.min(1.25,(viewport.X-16)/w,(viewport.Y-16)/h))
  if portrait then
   skin.ScaleType=Enum.ScaleType.Slice;skin.SliceCenter=Rect.new(200,310,1470,810);skin.SliceScale=.50
   rect(header,87,72,446,86);rect(title,117,72,386,54);rect(timer,174,129,272,36);rect(close,530,46,52,52)
   for i,row in cards do
    rect(row.tile,87,186+(i-1)*264,446,246);rect(row.picture,7,7,197,232)
    rect(row.ribbon,213,10,224,66);rect(row.body,220,86,210,145)
   end
   rect(acknowledge,163,994,294,64);rect(preference,116,1069,410,42)
   rect(checkBox,0,2,36,36);rect(preferenceText,49,0,350,42)
  else
   skin.ScaleType=Enum.ScaleType.Stretch
   rect(header,317,102,646,108);rect(title,350,100,580,65);rect(timer,465,171,350,38);rect(close,1100,56,65,65)
   for i,row in cards do
    rect(row.tile,159+(i-1)*326,234,310,310);rect(row.picture,6,6,298,177)
    rect(row.ribbon,5,174,300,47);rect(row.body,13,227,284,77)
   end
   rect(acknowledge,447,578,386,70);rect(preference,874,589,296,58)
   rect(checkBox,0,12,32,32);rect(preferenceText,45,0,248,58)
  end
  header.Visible=portrait or skin.Image==""
  self.Portrait=portrait;self.Scale=scale.Scale
 end
 function view:SetVisible(value)
  root.Visible=value==true
  if root.Visible then
   self:Fit(parent.AbsoluteSize);self:Refresh()
   local target=scale.Scale;scale.Scale=target*.94;Tween:Create(scale,TweenInfo.new(.16,Enum.EasingStyle.Quad),{Scale=target}):Play()
  end
 end
 view.Root=root;view.Card=board;view.Timer=timer;view.Cards=cards;view.Checkbox=preference;view.Close=close;view.Acknowledge=acknowledge
 parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() view:Fit(parent.AbsoluteSize) end)
 view:Fit(parent.AbsoluteSize);view:Refresh()
 return view
end
return V
