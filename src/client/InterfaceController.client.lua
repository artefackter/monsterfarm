local Players=game:GetService('Players');local Run=game:GetService('RunService');local Tween=game:GetService('TweenService')
local p=Players.LocalPlayer;local RS=game.ReplicatedStorage;local S=RS:WaitForChild('Shared');local rem=RS:WaitForChild('Remotes')
local C=require(S.Config.InterfaceConfig);local U=require(S.UIStyle);local L=require(S.Locale);local Pal=require(S.Palette)
local gui=p.PlayerGui:WaitForChild('DigUI');local bridge=gui:WaitForChild('ZoneMenu');local menu=gui:WaitForChild('Menu')
local function t(key,args) return L.text(key,L.lang(),args) end
local layer=Instance.new('ScreenGui');layer.Name='WorldInterface';layer.ResetOnSpawn=false;layer.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets;layer.DisplayOrder=5;layer.Parent=p.PlayerGui
local boards={};local zones={};local overhead={};local activeZone;local candidate;local enteredAt=0;local zonesFolder=Instance.new('Folder',workspace);zonesFolder.Name='LocalZoneRings'
local function board(part)
 if boards[part] or part:GetAttribute('Owner')~=p.UserId then return end
 local key=part:GetAttribute('UpgradeKey');if not key then return end
 local g=Instance.new('SurfaceGui');g.Name='Upgrade_'..key;g.Adornee=part;g.Face=Enum.NormalId.Front;g.CanvasSize=Vector2.new(600,345);g.LightInfluence=0;g.MaxDistance=70;g.Active=true;g.Parent=layer
 local frame=U.Panel(Instance.new('Frame'),Pal.Panel);frame.Size=UDim2.fromScale(1,1);frame.Parent=g
 local title=U.Text(frame,'',UDim2.new(1,-24,0,90),UDim2.fromOffset(12,8));local level=U.Text(frame,'',UDim2.new(1,-24,0,70),UDim2.fromOffset(12,94))
 local buy=U.Button(frame,'Buy',UDim2.new(1,-28,0,125),UDim2.fromOffset(14,198),function() rem.InterfaceAction:FireServer('upgrade',key) end)
 local price=U.Text(buy,'');price.TextColor3=Pal.Text;price.TextStrokeColor3=Pal.Stroke;price.TextStrokeTransparency=0
 title.UITextSizeConstraint.MaxTextSize=58;level.UITextSizeConstraint.MaxTextSize=43;price.UITextSizeConstraint.MaxTextSize=58
 local product=C.Products[key];if product and product.Id>0 then
  buy.Size=UDim2.new(.66,-22,0,125)
  local robux=U.Button(frame,'Robux',UDim2.new(.34,-14,0,125),UDim2.new(.66,0,0,198),function() rem.InterfaceAction:FireServer('product',key) end,Pal.Violet);U.Text(robux,'R$ '..product.Price).TextColor3=Pal.Text
 end
 local function update()
  title.Text=t('board'..key);level.Text=t('boardLevel',{n=part:GetAttribute('level') or 1,next=part:GetAttribute('next') or 2})
  local reason=part:GetAttribute('reason');local value=part:GetAttribute('price') or 0
  price.Text=part:GetAttribute('max') and t('boardMax') or reason=='houseLimit' and t('boardNeedHouse') or reason=='houseBuilding' and t('boardBusy',{n=value}) or reason=='lockWait' and t('lockWait',{n=value}) or key=='Lock' and t('boardReady') or part:GetAttribute('credit') and t('boardCredit') or L.compact(value,L.lang())..' $'
  buy.BackgroundColor3=part:GetAttribute('afford') and Pal.Mint or Pal.Red
 end
 local connection=part.AttributeChanged:Connect(update);boards[part]={gui=g,update=update,connection=connection};update()
end
-- Menu circles, alive: a glowing ring that breathes, dashes running round it, a wave that rolls outward
-- every couple of seconds and sparkles rising from the floor. Standing inside makes it all brighter and faster.
local DASHES=16
local function zone(q)
 if zones[q] or (not q:GetAttribute('MenuZone') and not q:GetAttribute('DisplayRing')) or q:GetAttribute('Owner') and q:GetAttribute('Owner')~=p.UserId then return end
 local radius=q:GetAttribute('Radius') or C.ZoneRadius;local ring=Instance.new('Folder',zonesFolder);local color=q.Color
 local anchor=Instance.new('Part');anchor.Name='ZoneAnchor';anchor.Size=Vector3.new(radius*2,.05,radius*2);anchor.CFrame=CFrame.new(q.Position);anchor.Transparency=1
 anchor.Anchored,anchor.CanCollide,anchor.CanTouch,anchor.CanQuery=true,false,false,false;anchor.Parent=ring
 local function band(name,inner,outer,height)
  local a=Instance.new('CylinderHandleAdornment');a.Name=name;a.Adornee=anchor;a.Radius=outer;a.InnerRadius=inner;a.Height=height or .08
  a.CFrame=CFrame.new(0,.04,0)*CFrame.Angles(math.pi/2,0,0);a.Color3=color;a.ZIndex=1;a.AlwaysOnTop=false;a.Parent=anchor;return a
 end
 local rim=band('Rim',radius-.32,radius,.1)
 local inner=band('Inner',radius*.62-.08,radius*.62,.06)
 local wave=band('Wave',radius-.2,radius,.05)
 local fill=Instance.new('Part');fill.Name='ZoneFill';fill.Shape=Enum.PartType.Cylinder;fill.Size=Vector3.new(.03,radius*2,radius*2);fill.CFrame=CFrame.new(q.Position)*CFrame.Angles(0,0,math.pi/2);fill.Color=color;fill.Transparency=.88;fill.Material=Enum.Material.Neon;fill.Anchored=true;fill.CanCollide=false;fill.CanTouch=false;fill.CanQuery=false;fill.Parent=ring
 local parts={}
 for i=1,DASHES do local v=Instance.new('Part');v.Name='ZoneDash';v.Size=Vector3.new(.22,.08,2*math.pi*radius/DASHES*.45);v.Color=color:Lerp(Color3.new(1,1,1),.35);v.Material=Enum.Material.Neon;v.Anchored=true;v.CanCollide=false;v.CanTouch=false;v.CanQuery=false;v.Parent=ring;parts[i]=v end
 local sparkle=Instance.new('ParticleEmitter');sparkle.Name='ZoneSparkles';sparkle.Shape=Enum.ParticleEmitterShape.Box;sparkle.Color=ColorSequence.new(color:Lerp(Color3.new(1,1,1),.4));sparkle.LightEmission=1
 sparkle.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.2,.28),NumberSequenceKeypoint.new(1,0)});sparkle.Transparency=NumberSequence.new(.1,1)
 sparkle.Lifetime=NumberRange.new(1.2,2);sparkle.Speed=NumberRange.new(1.5,3);sparkle.EmissionDirection=Enum.NormalId.Top;sparkle.SpreadAngle=Vector2.new(8,8);sparkle.Rate=5;sparkle.Parent=anchor
 zones[q]={ring=ring,parts=parts,fill=fill,rim=rim,inner=inner,wave=wave,sparkle=sparkle,key=q:GetAttribute('MenuZone'),radius=radius,center=q.Position,spin=math.random()*6,heat=0}
end
-- Every frame: run the dashes round, breathe the glow, roll the wave. Far circles are skipped.
Run.RenderStepped:Connect(function(dt)
 local now=os.clock();local cam=workspace.CurrentCamera.CFrame.Position;local parts,frames={},{}
 for q,z in zones do
  if (z.center-cam).Magnitude<160 then
   local hot=activeZone==q or candidate==q
   z.heat+=((hot and 1 or 0)-z.heat)*math.min(1,dt*6)
   z.spin+=dt*(.35+z.heat*1.4)
   for i,v in z.parts do
    local angle=z.spin+i*math.pi*2/DASHES;local pos=z.center+Vector3.new(math.cos(angle)*(z.radius+.32),.06,math.sin(angle)*(z.radius+.32))
    table.insert(parts,v);table.insert(frames,CFrame.lookAt(pos,pos+Vector3.new(-math.sin(angle),0,math.cos(angle))))
   end
   local breathe=.5+.5*math.sin(now*2.2+z.spin*.1)
   z.rim.Transparency=.35-.25*breathe-.25*z.heat;z.inner.Transparency=.55-.2*breathe-.3*z.heat
   z.inner.CFrame=CFrame.new(0,.04,0)*CFrame.Angles(math.pi/2,0,0)
   z.fill.Transparency=.9-.05*breathe-.08*z.heat
   local phase=(now*.55+z.spin*.05)%1
   z.wave.Radius=z.radius*(.35+.85*phase);z.wave.InnerRadius=math.max(0,z.wave.Radius-.22);z.wave.Transparency=.15+.85*phase
   z.sparkle.Rate=5+z.heat*20
  end
 end
 if #parts>0 then workspace:BulkMoveTo(parts,frames,Enum.BulkMoveMode.FireCFrameChanged) end
end)
local function track(q) if q:IsA('BasePart') then board(q);zone(q) end end
workspace.DescendantAdded:Connect(function(q) task.defer(track,q) end)
workspace.DescendantRemoving:Connect(function(q)
 local b=boards[q];if b then b.connection:Disconnect();b.gui:Destroy();boards[q]=nil end
 local z=zones[q];if z then z.ring:Destroy();zones[q]=nil;if activeZone==q then if z.key then bridge:Fire(z.key,false) end;activeZone=nil end end
end)
for _,q in workspace:GetDescendants() do track(q) end
p:GetAttributeChangedSignal('Language'):Connect(function() for _,b in boards do b.update() end;for _,x in layer:GetDescendants() do if x:IsA('TextLabel') or x:IsA('TextButton') then x.Font=U.Font() end end end)
local function overheadFor(who)
 local head=who.Character and who.Character:FindFirstChild('Head');local old=overhead[who]
 if old and old.head==head then return old end
 if old then old.gui:Destroy();overhead[who]=nil end;if not head then return end
 local g=Instance.new('BillboardGui');g.Name='FarmerStats';g.Adornee=head;g.Size=UDim2.fromOffset(200,52);g.StudsOffsetWorldSpace=Vector3.new(0,3.5,0);g.MaxDistance=90;g.Parent=layer
 local title=U.Text(g,'');title.TextColor3=Pal.Text;title.TextStrokeTransparency=0;title.TextStrokeColor3=Pal.Stroke
 old={gui=g,head=head,text=title};overhead[who]=old;return old
end
local accumulated=0
Run.Heartbeat:Connect(function(dt)
 accumulated+=dt;if accumulated<.1 then return end;accumulated=0
 local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart');local nearest;local distance=math.huge
 for q,b in boards do if q.Parent then b.gui.Face=q.CFrame:PointToObjectSpace(workspace.CurrentCamera.CFrame.Position).Z>0 and Enum.NormalId.Back or Enum.NormalId.Front end end
 for q,z in zones do
  local n=root and (Vector3.new(root.Position.X,q.Position.Y,root.Position.Z)-q.Position).Magnitude or math.huge
  if z.key and n<z.radius and root and math.abs(root.Position.Y-q.Position.Y)<7 and n<distance then nearest=q;distance=n end
 end
 if activeZone and nearest~=activeZone then local z=zones[activeZone];if z then bridge:Fire(z.key,false) end;activeZone=nil end
 if candidate~=nearest then candidate=nearest;enteredAt=os.clock() end
 if nearest and not activeZone and os.clock()-enteredAt>=C.ZoneDelay then activeZone=nearest;bridge:Fire(zones[nearest].key,true) end
 -- A manually closed window stays closed while activeZone remains the same.
 for _,who in Players:GetPlayers() do
  local h=overheadFor(who);if h then
   local slow=math.max(0,(who:GetAttribute('MutantSlowUntil') or 0)-workspace:GetServerTimeNow());local ko=math.max(0,(who:GetAttribute('KnockedOutUntil') or 0)-workspace:GetServerTimeNow())
   h.gui.Enabled=who~=p or slow>0
   h.text.Text=(who~=p and (t('incomeShort',{n=L.compact(who:GetAttribute('IncomeRate') or 0,L.lang())})..'  ·  '..L.compact(who:GetAttribute('SpeedPoints') or 0,L.lang())..' 👟') or '')..(slow>0 and string.format('\n◷ %.1f',slow) or ko>0 and '  ★' or '')
   h.text.TextColor3=slow>0 and Pal.Red or Pal.Text
  end
 end
end)
Players.PlayerRemoving:Connect(function(who) local h=overhead[who];if h then h.gui:Destroy();overhead[who]=nil end end)
local fade=Instance.new('Frame',layer);fade.Name='HomeFade';fade.Size=UDim2.fromScale(1,1);fade.BackgroundColor3=Color3.new();fade.BackgroundTransparency=1;fade.Visible=false;fade.ZIndex=40
rem:WaitForChild('InterfaceFX').OnClientEvent:Connect(function(kind) if kind~='home' then return end;fade.Visible=true;fade.BackgroundTransparency=1;Tween:Create(fade,TweenInfo.new(.13),{BackgroundTransparency=0}):Play();task.delay(.2,function() local tw=Tween:Create(fade,TweenInfo.new(.2),{BackgroundTransparency=1});tw:Play();tw.Completed:Once(function() fade.Visible=false end) end) end)
rem:WaitForChild('EconomyFX').OnClientEvent:Connect(function(delta,source,origin)
 local metrics=gui:FindFirstChild('Metrics');local counter=metrics and metrics:FindFirstChild('Coins');if not counter or delta==0 then return end
 local target=counter.AbsolutePosition+counter.AbsoluteSize*.5
 local start=Vector2.new(layer.AbsoluteSize.X*.5,layer.AbsoluteSize.Y*.5)
 if typeof(origin)=='Vector3' then local point,on=workspace.CurrentCamera:WorldToViewportPoint(origin);if on then start=Vector2.new(point.X,point.Y)-game.GuiService:GetGuiInset() end end
 local n=source=='income' and 1 or math.clamp(math.floor(math.log10(math.abs(delta)+1))+1,1,8)
 if delta>0 then for i=1,n do
  local icon=U.Icon(layer,'cash',nil,UDim2.fromOffset(44,35),UDim2.fromOffset(start.X+math.random(-25,25),start.Y+math.random(-20,20)));icon.ZIndex=12
  local tw=Tween:Create(icon,TweenInfo.new(.55+i*.035,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=UDim2.fromOffset(target.X-22,target.Y-17),Size=UDim2.fromOffset(23,18)});tw:Play();tw.Completed:Once(function() icon:Destroy() end)
 end end
 local number=U.Text(layer,(delta>0 and '+' or '−')..L.compact(math.abs(delta),L.lang()),UDim2.fromOffset(130,30),UDim2.fromOffset(target.X,target.Y-25));number.TextColor3=delta>0 and Pal.Mint or Pal.Red;number.TextStrokeTransparency=0;number.ZIndex=13
 Tween:Create(number,TweenInfo.new(.9),{Position=number.Position-UDim2.fromOffset(0,30),TextTransparency=1}):Play();game.Debris:AddItem(number,1)
 local sc=counter:FindFirstChildOfClass('UIScale') or Instance.new('UIScale',counter);U.Pop(sc,1)
 if delta<0 then counter.TextColor3=Pal.Red;local pos=counter.Position;Tween:Create(counter,TweenInfo.new(.05,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,4,true),{Position=pos+UDim2.fromOffset(4,0)}):Play();task.delay(.55,function() counter.Position=pos;counter.TextColor3=Pal.Mint end) end
end)
-- The current benefit is visible on the object itself, independently of its upgrade price.
local effects={}
local function effect(q)
 if effects[q] or not q:IsA('BasePart') or (q.Name~='Treadmill' and q.Name~='CryptSpot') or (q.Name=='Treadmill' and not q:GetAttribute('TreadmillBelt')) then return end
 -- HouseRoom is nested directly under a plot; find ownership without assuming its rebuild order.
 local ancestor=q.Parent;while ancestor and ancestor~=workspace and not ancestor:GetAttribute('Owner') do ancestor=ancestor.Parent end
 local uid=ancestor and ancestor:GetAttribute('Owner');if not uid then return end
 local g=Instance.new('BillboardGui');g.Name='ObjectEffect';g.Adornee=q;g.Size=UDim2.fromOffset(210,45);g.StudsOffsetWorldSpace=q.Name=='CryptSpot' and (Vector3.new(0,4.6,0)+q.CFrame.LookVector*4) or Vector3.new(0,6,0);g.MaxDistance=55;g.ResetOnSpawn=false;g.Parent=p.PlayerGui
 local label=U.Text(g,'',UDim2.new(1,-45,1,0),UDim2.fromOffset(45,0));label.TextColor3=Pal.Mint;label.TextStrokeTransparency=0;label.TextStrokeColor3=Pal.Stroke
 U.Icon(g,q.Name=='Treadmill' and 'shoe' or 'grave',nil,UDim2.fromOffset(45,45));effects[q]={gui=g,text=label,uid=uid}
end
for _,q in workspace:GetDescendants() do effect(q) end
workspace.DescendantAdded:Connect(function(q) task.defer(effect,q) end)
task.spawn(function() while task.wait(.5) do for q,e in effects do
 if not q.Parent then e.gui:Destroy();effects[q]=nil else local who=Players:GetPlayerByUserId(e.uid);e.gui.Enabled=q.Name~='CryptSpot' or e.uid==p.UserId and p:GetAttribute('InHouse')==true;if who then e.text.Text=q.Name=='Treadmill' and t('boardStep',{n=L.compact(who:GetAttribute('TreadmillRate') or 3,L.lang())}) or t('roomCrypt')..' '..tostring(who:GetAttribute('CryptUsed') or 0)..'/'..tostring(who:GetAttribute('CryptCapacity') or 20) end end
end end end)
