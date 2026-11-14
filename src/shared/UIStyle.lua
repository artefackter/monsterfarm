local U={};local Pal=require(script.Parent.Palette);local L=require(script.Parent.Locale)
function U.Font() return L.lang():sub(1,2)=='ru' and Enum.Font.GothamBlack or Enum.Font.FredokaOne end
function U.Panel(f,color,radius)
 f.BackgroundColor3=color or Pal.Panel;f.BackgroundTransparency=0;f.BorderSizePixel=0
 local corner=f:FindFirstChildOfClass('UICorner') or Instance.new('UICorner',f);corner.CornerRadius=UDim.new(0,radius or 14)
 local stroke=f:FindFirstChildOfClass('UIStroke') or Instance.new('UIStroke',f);stroke.Color=Pal.Stroke;stroke.Thickness=3;stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
 local gradient=f:FindFirstChildOfClass('UIGradient') or Instance.new('UIGradient',f);gradient.Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(220,218,234));gradient.Rotation=90

 return f
end
function U.Shadow(f)
 local shadow=f:FindFirstChild('BottomShadow');if not shadow then shadow=Instance.new('Frame');shadow.Name='BottomShadow';shadow.Size=UDim2.new(1,-16,0,5);shadow.Position=UDim2.new(0,8,1,1);shadow.BackgroundColor3=Pal.Stroke;shadow.BackgroundTransparency=.35;shadow.BorderSizePixel=0;shadow.Parent=f;Instance.new('UICorner',shadow).CornerRadius=UDim.new(1,0) end
end
function U.Text(parent,value,size,pos)
 local t=Instance.new('TextLabel');t.BackgroundTransparency=1;t.Size=size or UDim2.fromScale(1,1);t.Position=pos or UDim2.new();t.Text=value or '';t.Font=U.Font();t.TextScaled=true;t.TextWrapped=true;t.AutoLocalize=false;t.TextColor3=Pal.Ink;t.Parent=parent
 local limit=Instance.new('UITextSizeConstraint',t);limit.MinTextSize=10;limit.MaxTextSize=28;return t
end
function U.Pop(scale,base) scale.Scale=base*.9;game.TweenService:Create(scale,TweenInfo.new(.15,Enum.EasingStyle.Back),{Scale=base}):Play() end
function U.Button(parent,name,size,pos,callback,color)
 local b=U.Panel(Instance.new('TextButton'),color);b.Name=name;b.Text='';b.Size=size;b.Position=pos or UDim2.new();b.AutoButtonColor=true;b.Parent=parent
 U.Shadow(b);local scale=Instance.new('UIScale',b);b.Activated:Connect(function() U.Pop(scale,1);require(script.Parent.Sfx).play('Click');callback() end);return b
end
-- Illustrated market theme, scoped to modals. HUD positioning is independent.
U.ModalColors={Blue=Color3.fromRGB(255,236,197),Purple=Color3.fromRGB(105,33,101),Green=Color3.fromRGB(132,221,0),Red=Color3.fromRGB(217,51,72),Gold=Color3.fromRGB(255,190,23),Ink=Color3.fromRGB(81,28,65),Cream=Color3.fromRGB(255,238,200),Wood=Color3.fromRGB(176,91,28)}
function U.ModalText(text,light)
 text.TextColor3=light and U.ModalColors.Cream or U.ModalColors.Ink;text.TextStrokeTransparency=1
 local stroke=text:FindFirstChild('ModalTextOutline') or Instance.new('UIStroke');stroke.Name='ModalTextOutline';stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual;stroke.Color=U.ModalColors.Ink;stroke.Thickness=light and 1.6 or .5;stroke.Transparency=light and 0 or 1;stroke.LineJoinMode=Enum.LineJoinMode.Round;stroke.Parent=text
 return text
end
local function skin(f,key,slice,scale)
 local image=f:FindFirstChild('MarketSkin') or Instance.new('ImageLabel');image.Name='MarketSkin';image.BackgroundTransparency=1;image.Active=false;image.Size=UDim2.fromScale(1,1);image.ZIndex=1;image.Image=require(script.Parent.Icons)[key] or '';image.ScaleType=Enum.ScaleType.Slice;image.SliceCenter=slice;image.SliceScale=scale;image.Parent=f;return image
end
function U.ModalSurface(f,color,radius,pattern)
 U.Panel(f,color or U.ModalColors.Blue,radius or 14)
 f:SetAttribute('ModalSurface',true)
 if pattern~=false then
  f.BackgroundTransparency=0;f.BackgroundColor3=U.ModalColors.Cream;f.UIStroke.Transparency=1;f.UIGradient.Enabled=false
  skin(f,'market_card',Rect.new(147,147,877,877),.135)
 else
  f.UIStroke.Color=U.ModalColors.Wood;f.UIStroke.Thickness=2.5
  f.UIGradient.Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(175,145,160));f.UIGradient.Rotation=90
  local previous=f:FindFirstChild('InnerRim');if previous then previous:Destroy() end
  local rim=Instance.new('Frame');rim.Name='InnerRim';rim.BackgroundTransparency=1;rim.Active=false;rim.Position=UDim2.fromOffset(3,3);rim.Size=UDim2.new(1,-6,1,-6);rim.Parent=f
  Instance.new('UICorner',rim).CornerRadius=UDim.new(0,math.max(0,(radius or 14)-3))
  local st=Instance.new('UIStroke',rim);st.Color=U.ModalColors.Cream;st.Transparency=.15;st.Thickness=1.5
 end
 return f
end
function U.ModalWindow(f)
 U.ModalSurface(f);f:SetAttribute('MarketWindow',true)
 skin(f,'market_frame',Rect.new(118,118,906,906),.27)
 return f
end
function U.ModalHeader(f,compact)
 f.BackgroundTransparency=1;f.BorderSizePixel=0;f:SetAttribute('ModalSurface',true);f:SetAttribute('MarketHeader',true)
 local art=Instance.new('ImageLabel');art.Name='MarketCanopy';art.BackgroundTransparency=1;art.Active=false;art.Image=require(script.Parent.Icons).market_canopy or '';art.Size=UDim2.new(1,48,0,compact and 118 or 174);art.Position=UDim2.fromOffset(-24,compact and -48 or -72);art.ZIndex=1;art.Parent=f
 return f
end
function U.ModalButton(b,color)
 U.ModalSurface(b,color or U.ModalColors.Green,10,false);U.ModalText(b,color~=U.ModalColors.Cream and color~=U.ModalColors.Blue)
 local shadow=b:FindFirstChild('BottomShadow');if shadow then shadow.BackgroundColor3=(color or U.ModalColors.Green):Lerp(U.ModalColors.Ink,.55) end
 b.UIGradient.Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(142,157,108))
 local limit=b:FindFirstChildOfClass('UITextSizeConstraint');if limit then limit.MaxTextSize=40 end
 return b
end
-- Transparent layout rows keep the painted card frame on the actual cards only.
function U.ModalRow(f)
 f.BackgroundTransparency=1
 local skin=f:FindFirstChild('MarketSkin');if skin then skin:Destroy() end
 local stroke=f:FindFirstChildOfClass('UIStroke');if stroke then stroke.Transparency=1 end
 return f
end
function U.ModalClose(button)
 button.Text=''
 for layer=1,2 do
  for _,angle in ipairs({45,-45}) do
   local line=Instance.new('Frame');line.Name='Cross';line.AnchorPoint=Vector2.new(.5,.5);line.Position=UDim2.fromScale(.5,.5);line.Size=layer==1 and UDim2.fromScale(.72,.27) or UDim2.fromScale(.6,.14);line.Rotation=angle;line.BackgroundColor3=layer==1 and Color3.fromRGB(155,51,55) or U.ModalColors.Cream;line.BorderSizePixel=0;line.Active=false;line.ZIndex=3+layer;line.Parent=button
   Instance.new('UICorner',line).CornerRadius=UDim.new(1,0)
  end
 end
 return button
end
function U.ModalSelected(f)
 f.UIStroke.Transparency=0;f.UIStroke.Color=U.ModalColors.Gold;f.UIStroke.Thickness=3
end
-- A native arrow stays visible in every locale/font, including Cyrillic.
function U.ModalArrow(parent,size,pos)
 local arrow=Instance.new('Frame');arrow.Name='MergeArrow';arrow.BackgroundTransparency=1;arrow.Size=size;arrow.Position=pos;arrow.Parent=parent
 for layer=1,2 do
  local color=layer==1 and U.ModalColors.Wood or U.ModalColors.Gold
  for _,piece in ipairs({{.43,.5,.64,.18,0},{.65,.37,.48,.18,45},{.65,.63,.48,.18,-45}}) do
   local line=Instance.new('Frame');line.BackgroundColor3=color;line.BorderSizePixel=0;line.AnchorPoint=Vector2.new(.5,.5);line.Position=UDim2.fromScale(piece[1],piece[2]);line.Size=UDim2.new(piece[3],layer==1 and 3 or 0,piece[4],layer==1 and 3 or 0);line.Rotation=piece[5];line.ZIndex=layer+1;line.Parent=arrow
   Instance.new('UICorner',line).CornerRadius=UDim.new(0,2)
  end
 end
 return arrow
end
function U.ModalShelf(parent)
 local shelf=Instance.new('Frame');shelf.Name='Shelf';shelf.Size=UDim2.new(1,-12,0,9);shelf.Position=UDim2.new(0,6,1,-8);shelf.BackgroundColor3=Color3.fromRGB(240,157,49);shelf.BorderSizePixel=0;shelf.Parent=parent
 Instance.new('UICorner',shelf).CornerRadius=UDim.new(0,2)
 local st=Instance.new('UIStroke',shelf);st.Color=Color3.fromRGB(171,81,22);st.Thickness=1
 local g=Instance.new('UIGradient',shelf);g.Rotation=90;g.Color=ColorSequence.new(Color3.fromRGB(255,241,180),Color3.fromRGB(177,85,23))
end
function U.ModalArt(parent,kind,id,size,pos,finish)
 if kind=="monster" and id and not require(script.Parent.MonsterCollection).Icon(id,require(script.Parent.Icons)) then -- the rotation: 3D
  local v=require(script.Parent.MonsterPortrait).Create(parent,{id=id,type=id,tier=1},size or UDim2.fromScale(1,1),pos);v.Name="Art_monster";return v
 end
 if kind=="weapon" and (finish and finish~="Default" or not require(script.Parent.Icons)["modal_weapon_"..tostring(id)]) then return U.Icon(parent,kind,id,size,pos,finish) end
 local icons=require(script.Parent.Icons)
 local key=kind=='cash' and 'hudZombucks' or kind=='shoe' and 'hudSpeed' or kind=='coffin' and 'hudCoffin' or kind=='crypt' and 'crypt' or kind=='grave' and (id=='Golden' and 'modal_grave_Golden' or 'modal_grave_Stone') or 'modal_'..kind..(id and '_'..id or '')
 if not icons[key] then return U.Icon(parent,kind,id,size,pos) end
 local image=Instance.new('ImageLabel');image.Name='Art_'..kind;image.BackgroundTransparency=1;image.Image=icons[key];image.ScaleType=Enum.ScaleType.Fit;image.Size=size or UDim2.fromScale(1,1);image.Position=pos or UDim2.new();image.Active=false;image.Parent=parent
 -- One stone and one coffin picture serve every grave: the material shows as a tint (the golden grave has its own).
 if (kind=='grave' and id~='Golden' or kind=='coffin') and U.GraveTint[id] then image.ImageColor3=U.GraveTint[id] end
 return image
end
U.GraveTint={Wooden=Color3.fromRGB(226,170,118),Stone=Color3.new(1,1,1),Marble=Color3.fromRGB(255,247,238),Golden=Color3.fromRGB(255,214,92),Emo=Color3.fromRGB(120,90,130),Military=Color3.fromRGB(150,170,100),Ghost=Color3.fromRGB(170,235,255),Lunar=Color3.fromRGB(192,166,255)}

-- Code-native original icons: no imported image IDs or unavailable assets.
function U.Icon(parent,kind,id,size,pos,finish)
 local v=Instance.new('ViewportFrame');v.Name='Icon_'..kind;v.BackgroundTransparency=1;v.Size=size or UDim2.fromScale(1,1);v.Position=pos or UDim2.new();v.Ambient=Color3.new(1,1,1);v.LightColor=Color3.new(1,1,1);v.Parent=parent
 local wm=Instance.new('WorldModel',v);local model
 local function part(name,s,at,color)
  local q=Instance.new('Part');q.Name=name;q.Size=s;q.CFrame=CFrame.new(at);q.Color=Color3.fromHex(color);q.Anchored=true;q.CanCollide=false;q.Parent=model;return q
 end
 if kind=='weapon' then model=require(script.Parent.WeaponModel).Build(id or 'Deagle',wm,CFrame.identity,finish)
 elseif kind=='shovel' then model=require(script.Parent.ShovelModel).Build(id or 'Rusty',wm)
 elseif kind=='trap' then model=require(script.Parent.RoadGearModel).Trap(wm,CFrame.identity)
 else
  model=Instance.new('Model',wm)
  if kind=='cash' then
   for i=0,2 do part('Bill',Vector3.new(3,.15,1.6),Vector3.new(0,i*.17,0),i==2 and '68E887' or '299D57') end
   part('Band',Vector3.new(.7,.58,1.65),Vector3.new(0,.2,0),'FFE58D')
  elseif kind=='shoe' then
   part('Sole',Vector3.new(2.9,.28,1.1),Vector3.new(0,0,0),'FFFFFF');part('Toe',Vector3.new(1.8,.65,1),Vector3.new(-.45,.4,0),'4CC9FF');part('Heel',Vector3.new(1,1.4,1),Vector3.new(.9,.8,0),'1675CF')
   for i=0,2 do part('Lace',Vector3.new(.16,.09,1.03),Vector3.new(-.3+i*.3,.76,0),'FFFFFF') end
  else
   part('Grave',Vector3.new(1.8,2.5,.7),Vector3.new(0,1.3,0),({Wooden='A3754B',Stone='9AA6AC',Marble='F4E8DE',Golden='FFD34D',Emo='3A2E44',Military='6E7D45',Ghost='BFEFFF',Lunar='B08CFF'})[id or ''] or 'AE9FD1');part('Base',Vector3.new(2.4,.4,1.3),Vector3.new(0,0,0),'675785');part('Mark',Vector3.new(.3,1,.1),Vector3.new(0,1.4,-.4),'F5EDD6');part('Mark',Vector3.new(.9,.3,.1),Vector3.new(0,1.6,-.4),'F5EDD6')
  end
 end
 for _,q in model:GetDescendants() do if q:IsA('BasePart') then q.Anchored=true end end
 local cf,bounds=model:GetBoundingBox();local radius=math.max(bounds.X,bounds.Y,bounds.Z)*1.25
 local cam=Instance.new('Camera',v);cam.FieldOfView=36
 cam.CFrame=CFrame.lookAt(cf.Position+Vector3.new(radius*.8,radius*.55,radius),cf.Position)
 if kind=='weapon' then cam.CFrame=CFrame.lookAt(cf.Position+Vector3.new(radius,.35*radius,.25*radius),cf.Position) end
 v.CurrentCamera=cam;return v
end
return U
