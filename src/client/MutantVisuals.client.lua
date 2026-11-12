local RS=game.ReplicatedStorage;local S=RS:WaitForChild("Shared");local C=require(S.Config.MutantConfig);local Sfx=require(S.Sfx);local L=require(S.Locale)
local Run=game:GetService("RunService");local Tween=game:GetService("TweenService");local Debris=game:GetService("Debris");local p=game.Players.LocalPlayer
local Animation=require(S.MutantAnimation)
local Style=require(S.UIStyle)
local guardModels={};local models={};local folder=workspace:WaitForChild("Mutants")
local function add(m)
 if not m:IsA("Model") then return end
 models[m]={born=os.clock(),joints={}}
end
folder.ChildAdded:Connect(add);for _,m in ipairs(folder:GetChildren()) do add(m) end
local function dot(pos,color,size,seconds)
 local q=Instance.new("Part");q.Shape=Enum.PartType.Ball;q.Anchored=true;q.CanCollide=false;q.CanTouch=false;q.CanQuery=false;q.Size=Vector3.one*size;q.Color=color;q.Position=pos;q.Parent=workspace;Debris:AddItem(q,seconds);return q
end
local function smoke(pos)
 for i=1,8 do local q=dot(pos+Vector3.new(math.random()-0.5,math.random(),math.random()-.5),Color3.fromHex("9E63CF"),.8,.6);Tween:Create(q,TweenInfo.new(.6),{Size=Vector3.one*2,Transparency=1,Position=q.Position+Vector3.new(math.random()-0.5,1.8,math.random()-.5)}):Play() end
end
local function damage(pos,n,crit)
 local q=dot(pos,Color3.new(1,1,1),.1,.65);q.Transparency=1
 local b=Instance.new("BillboardGui",q);b.Size=UDim2.fromOffset(crit and 160 or 90,crit and 54 or 40);b.AlwaysOnTop=true
 -- a critical hit is bigger, red-orange and shouts
 local l=Instance.new("TextLabel",b);l.Size=UDim2.fromScale(1,1);l.BackgroundTransparency=1;l.Text=crit and (tostring(n).."!") or tostring(n);l.TextColor3=crit and Color3.fromRGB(255,96,48) or Color3.fromHex("FFE04F");l.Font=Enum.Font.GothamBlack;l.TextSize=crit and 38 or 24;l.TextStrokeTransparency=0
 Tween:Create(q,TweenInfo.new(.65),{Position=pos+Vector3.new(0,2.5,0)}):Play()
end
local function reward(pos,uid,amount)
 if uid~=p.UserId then return end
 local cam=workspace.CurrentCamera;local point=cam:WorldToViewportPoint(pos);local g=p.PlayerGui:FindFirstChild("CombatUI");if not g then return end
 local inset=game.GuiService:GetGuiInset();local ui=p.PlayerGui:FindFirstChild('DigUI');local metrics=ui and ui:FindFirstChild('Metrics');local coins=metrics and metrics:FindFirstChild('Coins');local target=coins and coins.AbsolutePosition+coins.AbsoluteSize*.5 or Vector2.new(75,cam.ViewportSize.Y-70)
 for i=1,6 do local f=Style.ModalArt(g,'cash',nil,UDim2.fromOffset(30,30),UDim2.fromOffset(point.X-inset.X+math.random(-35,35),point.Y-inset.Y));f.Name='MutantRewardCoin'
  Tween:Create(f,TweenInfo.new(.65+i*.04,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=UDim2.fromOffset(target.X,target.Y),Size=UDim2.fromOffset(12,12)}):Play();Debris:AddItem(f,1.1)
 end
 Sfx.play("Coins",.2)
end
local function modelById(id)
 for m in pairs(models) do if m.Parent and m:GetAttribute("MutantId")==id then return m end end
 return nil
end
local function flatDisc(pos,color,radius,seconds,transparency)
 local q=dot(Vector3.new(pos.X,.68,pos.Z),color,1,seconds);q.Shape=Enum.PartType.Cylinder;q.Material=Enum.Material.Neon
 q.Size=Vector3.new(.08,radius*2,radius*2);q.CFrame=CFrame.new(q.Position)*CFrame.Angles(0,0,math.pi/2);q.Transparency=transparency or .4
 return q
end
-- A ring that grows and fades: slams, landings, the scream's shock waves.
local function shockwave(pos,color,radius,seconds)
 local q=flatDisc(pos,color,1,seconds or .35,.2);q.Size=Vector3.new(.15,1,1)
 Tween:Create(q,TweenInfo.new(seconds or .35,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.new(.15,radius*2,radius*2),Transparency=1}):Play()
end
local function splash(pos,color,radius)
 shockwave(pos,color,radius,.4)
 for _=1,7 do
  local q=dot(Vector3.new(pos.X,1,pos.Z),color,.5+math.random()*.4,.45);q.Material=Enum.Material.Neon
  local a=math.random()*math.pi*2;local r=radius*(.4+math.random()*.6)
  Tween:Create(q,TweenInfo.new(.45,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=q.Position+Vector3.new(math.cos(a)*r,1.5+math.random()*2,math.sin(a)*r),Transparency=1,Size=Vector3.one*.15}):Play()
 end
end
local function shake(pos,radius,strength)
 if p:GetAttribute('CameraShake')==false then return end
 local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart");if not root then return end
 local near=1-math.clamp((root.Position-pos).Magnitude/(radius*1.6),0,1);if near<=0 then return end
 local hum=p.Character:FindFirstChildOfClass("Humanoid");if not hum then return end
 task.spawn(function()
  local t0=os.clock()
  while os.clock()-t0<.45 do
   local k=(1-(os.clock()-t0)/.45)*strength*near
   hum.CameraOffset=Vector3.new((math.random()-.5)*k,(math.random()-.5)*k,0)
   Run.RenderStepped:Wait()
  end
  hum.CameraOffset=Vector3.zero
 end)
end
-- An arcing throw: the projectile flies up and over, then bursts where it lands.
local function lob(from,to,color,size,seconds,onLand)
 local q=dot(from,color,size,seconds+.05);q.Material=Enum.Material.Neon
 task.spawn(function()
  local t0=os.clock();local height=math.clamp((to-from).Magnitude*.25,3,14)
  while os.clock()-t0<seconds and q.Parent do
   local t=(os.clock()-t0)/seconds
   q.Position=from:Lerp(to,t)+Vector3.new(0,math.sin(t*math.pi)*height,0)
   Run.RenderStepped:Wait()
  end
  if onLand then onLand() end
 end)
end
-- Death: the visible body slumps and sinks into smoke over half a second. Nothing stays behind (no corpses).
local function collapse(m)
 local root=m and m.PrimaryPart;if not root then return end
 local pivot=root.CFrame;local scale=m:GetScale();local ghost=Instance.new("Model");ghost.Name="MutantFall";ghost.Parent=workspace
 local side=math.random()<.5 and -1 or 1
 for _,q in m:GetDescendants() do
  if q:IsA("BasePart") and q~=root and q.Transparency<1 then
   local c=q:Clone()
   for _,child in c:GetChildren() do if not (child:IsA("SurfaceAppearance") or child:IsA("Decal") or child:IsA("SpecialMesh")) then child:Destroy() end end
   c.Anchored=true;c.CanCollide=false;c.CanQuery=false;c.CanTouch=false;c.CFrame=q.CFrame;c.Parent=ghost
  end
 end
 local feet=pivot*CFrame.new(0,-C.RootHeight*scale,0)
 local parts={};for _,c in ghost:GetChildren() do parts[c]=feet:ToObjectSpace(c.CFrame) end
 task.spawn(function()
  local t0=os.clock()
  while os.clock()-t0<.55 and ghost.Parent do
   local t=(os.clock()-t0)/.55;local ease=t*t
   local tip=feet*CFrame.new(0,-ease*2*scale,0)*CFrame.Angles(-ease*1.25,0,side*ease*.35)
   for c,offset in pairs(parts) do c.CFrame=tip*offset;c.Transparency=math.max(c.Transparency,ease*.85) end
   Run.RenderStepped:Wait()
  end
  ghost:Destroy()
 end)
 smoke(pivot.Position-Vector3.new(0,C.RootHeight*scale*.4,0))
end
local RED_WARN=Color3.fromHex("FF4A3D")
RS:WaitForChild("Remotes"):WaitForChild("MutantFX").OnClientEvent:Connect(function(kind,id,pos,value,extra,extra2)
 if kind=="Reward" then reward(pos,value,extra);return end
 if typeof(pos)~="Vector3" then return end
 local far=(pos-workspace.CurrentCamera.CFrame.Position).Magnitude
 if kind=="BossSpawn" then if far<220 then Sfx.play("BossRoar",1,Sfx.at(pos,40,220));shockwave(pos,Color3.fromHex("9E63CF"),18,.8) end;return end
 if kind=="BossDeath" then if far<220 then Sfx.play("BossRoar",1,Sfx.at(pos,40,220));for _=1,3 do smoke(pos+Vector3.new(math.random(-4,4),math.random(0,4),math.random(-4,4))) end end;return end
 -- the Blood Moon giant's blows are seen from much further away
 local source=id and id~="0" and modelById(id)
 if far>(source and source:GetAttribute("Giant") and 600 or C.AnimateDistance) then return end
 if kind=="GuardShot" then
  local guard=guardModels[id]
  if not guard or not guard.Parent then
   local world=workspace:FindFirstChild("DigAZombie")
   for _,plot in world and world:GetChildren() or {} do
    for _,child in plot:GetChildren() do if child:GetAttribute("ZombieId")==id then guard=child;guardModels[id]=child;break end end
    if guard and guard.Parent then break end
   end
  end
  local gun=guard and guard:FindFirstChild("GuardGun_Main");local muzzle=gun and gun:FindFirstChild("Muzzle")
  if muzzle then pos=muzzle.WorldPosition end
  local color=require(S.Config.WeaponConfig)[extra].Color
  local delta=value-pos;local q=dot(pos,color,.18,.08);q.Shape=Enum.PartType.Block;q.Material=Enum.Material.Neon;q.Size=Vector3.new(.09,.09,delta.Magnitude);q.CFrame=CFrame.lookAt(pos,value)*CFrame.new(0,0,-delta.Magnitude/2)
  local flash=dot(pos,Color3.fromRGB(255,230,150),.7,.06);flash.Material=Enum.Material.Neon
  Sfx.play("Fire"..extra,.1,.6*Sfx.at(pos,15,130));return
 end
 if kind=="Spawn" then
  local q=dot(Vector3.new(pos.X,.75,pos.Z),Color3.fromHex("5C0A2E"),3,C.SpawnSeconds);q.Size=Vector3.new(3,.08,1);smoke(pos-Vector3.new(0,1.3,0));Sfx.play("ImpLaugh",1,Sfx.at(pos,20,C.AnimateDistance))
 elseif kind=="Death" or kind=="Smoke" then
  if kind=="Death" then local m=modelById(id);if m then collapse(m) else smoke(pos) end;Sfx.play("ImpDeath",.15,Sfx.at(pos,25,C.AnimateDistance)) else smoke(pos) end
 elseif kind=="Hit" then
  damage(pos,value,extra==true);Sfx.play("ImpHit",.09)
  local m=modelById(id);if m then local h=Instance.new("Highlight");h.FillColor=Color3.new(1,1,1);h.FillTransparency=0;h.OutlineTransparency=1;h.Parent=m;Debris:AddItem(h,.08) end
 elseif kind=="Telegraph" then
  local q=flatDisc(pos,Color3.fromHex("FFAE37"),value,extra,.6);q.Name="MutantAttackWarning"
  Tween:Create(q,TweenInfo.new(extra),{Transparency=.15,Color=RED_WARN}):Play()
 elseif kind=="DashLine" then
  -- A lane on the floor from the monster to where its leap or charge will end.
  local from,to=Vector3.new(pos.X,.7,pos.Z),Vector3.new(value.X,.7,value.Z);local length=(to-from).Magnitude
  if length>.1 then
   local q=dot(from,Color3.fromHex("FFAE37"),1,extra);q.Name="MutantAttackWarning";q.Shape=Enum.PartType.Block;q.Material=Enum.Material.Neon
   q.Size=Vector3.new(extra2 or 4,.08,length);q.CFrame=CFrame.lookAt((from+to)/2,to);q.Transparency=.65
   Tween:Create(q,TweenInfo.new(extra),{Transparency=.2,Color=RED_WARN}):Play()
  end
 elseif kind=="Leap" or kind=="Charge" then
  -- dust kicked up at the take-off, a landing thud at the end
  shockwave(pos,Color3.fromHex("B49A7A"),4,.3)
  task.delay(extra or .4,function() shockwave(value,Color3.fromHex("B49A7A"),kind=="Charge" and 9 or 5,.35);if kind=="Charge" then shake(value,12,.6) end end)
  Sfx.play("ImpBite",.3,Sfx.at(pos,20,C.AnimateDistance))
 elseif kind=="HunterShot" then
  local delta=value-pos
  if delta.Magnitude>.01 then
   local from=pos+Vector3.new(0,1.5,0);delta=value-from
   local q=dot(from,Color3.fromRGB(255,219,122),.15,.1);q.Shape=Enum.PartType.Block;q.Material=Enum.Material.Neon;q.Size=Vector3.new(.12,.12,delta.Magnitude);q.CFrame=CFrame.lookAt(from,value)*CFrame.new(0,0,-delta.Magnitude/2)
   local flash=dot(from,Color3.fromRGB(255,239,183),.8,.08);flash.Material=Enum.Material.Neon
   splash(value,Color3.fromRGB(255,214,140),extra or 2)
   Sfx.play("FireAK",.12,.8*Sfx.at(pos,20,C.AnimateDistance))
  end
 elseif kind=="Acid" then
  lob(pos+Vector3.new(0,2,0),value,Color3.fromHex("B8F749"),.9,.35,function() splash(value,Color3.fromHex("9BE33A"),extra or 4) end)
 elseif kind=="Throw" then
  lob(pos+Vector3.new(0,3,0),value,Color3.fromHex("C98B3A"),1.1,.45,function() splash(value,Color3.fromHex("E0B262"),extra or 4) end)
 elseif kind=="Slam" then
  shockwave(value,Color3.fromHex("EC86B2"),extra,.35);splash(value,Color3.fromHex("C9A889"),extra*.6)
  if extra>=10 then shake(value,extra,.7) end
 elseif kind=="Scream" then
  -- three shock rings and a hard shake for everyone it reaches
  for i=0,2 do task.delay(i*.12,function() shockwave(pos,Color3.fromHex("D7FF3E"),value*(.7+i*.15),.55) end) end
  shake(pos,value,1.2);Sfx.play("BossScream",.5,Sfx.at(pos,40,180))
 elseif kind=="Chant" then
  local q=flatDisc(pos,Color3.fromHex("8E1F35"),9,extra or 1.2,.6);Tween:Create(q,TweenInfo.new(extra or 1.2),{Transparency=.1,Size=Vector3.new(.08,22,22)}):Play()
 elseif kind=="Summon" then
  shockwave(pos,Color3.fromHex("8E1F35"),16,.5);smoke(pos)
 elseif kind=="BossCue" then
  if extra=="Dash" then Sfx.play("BossCharge",.5,Sfx.at(pos,30,180)) end
 elseif kind=="Bite" then Sfx.play("ImpBite",.5,Sfx.at(pos,20,C.AnimateDistance))
 elseif kind=="Shovel" then
  local q=dot(pos,Color3.fromHex("C9D6EA"),.65,.25);q.Shape=Enum.PartType.Block;q.Size=Vector3.new(.8,.2,1.8);Tween:Create(q,TweenInfo.new(.25),{Position=value,Orientation=Vector3.new(360,0,90)}):Play()
 end
end)
-- Height of the mutant's head above its root, measured once from the parts at rest and scaled with the model.
local function topOf(m,root)
 local top=0
 for _,q in m:GetDescendants() do
  if q:IsA("BasePart") and q~=root then
   local cf,size=q.CFrame,q.Size
   local half=math.abs(cf.RightVector.Y)*size.X/2+math.abs(cf.UpVector.Y)*size.Y/2+math.abs(cf.LookVector.Y)*size.Z/2
   top=math.max(top,cf.Position.Y+half-root.Position.Y)
  end
 end
 return top>0 and top or 3*m:GetScale()
end
local GREEN,YELLOW,RED=Color3.fromHex("7DF04A"),Color3.fromHex("FFD23F"),Color3.fromHex("FF4F4F")
local function round(f,r) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(r or 1,0);c.Parent=f end
-- A health bar that floats over the head (not inside it) and follows the smoothed body, not the raw server hitbox.
local function makeBar(m,root,data)
 local b=Instance.new("BillboardGui");b.Name="MutantHealth";b.Size=UDim2.fromOffset(84,14);b.LightInfluence=0;b.MaxDistance=C.AnimateDistance;b.Adornee=root;b.Parent=root
 local alert=Instance.new('TextLabel',b);alert.Name='Alert';alert.Size=UDim2.fromOffset(84,36);alert.Position=UDim2.fromOffset(0,-38);alert.BackgroundTransparency=1;alert.TextColor3=Color3.fromRGB(255,221,71);alert.TextStrokeTransparency=0;alert.Font=Enum.Font.GothamBlack;alert.TextSize=34;data.alert=alert
 local stars=Instance.new('Frame',b);stars.Name='StunStars';stars.Size=UDim2.fromOffset(78,26);stars.Position=UDim2.fromOffset(3,-30);stars.BackgroundTransparency=1;data.stars=stars
 for i=1,3 do local star=Instance.new('ImageLabel',stars);star.Size=UDim2.fromOffset(24,24);star.Position=UDim2.fromOffset((i-1)*27,0);star.BackgroundTransparency=1;star.Image=require(S.Icons).star end
 local back=Instance.new("Frame",b);back.Name="Back";back.Size=UDim2.fromScale(1,1);back.BackgroundColor3=Color3.fromHex("2A1630");back.BorderSizePixel=0;round(back)
 local stroke=Instance.new("UIStroke",back);stroke.Color=Color3.fromHex("140A18");stroke.Thickness=2
 local lag=Instance.new("Frame",back);lag.Name="Lag";lag.Size=UDim2.fromScale(1,1);lag.BackgroundColor3=Color3.new(1,1,1);lag.BorderSizePixel=0;round(lag);data.lag=lag
 local fill=Instance.new("Frame",back);fill.Name="Fill";fill.Size=UDim2.fromScale(1,1);fill.BackgroundColor3=GREEN;fill.BorderSizePixel=0;round(fill);data.bar=fill
 local shine=Instance.new("Frame",fill);shine.Size=UDim2.new(1,-6,.35,0);shine.Position=UDim2.new(0,3,0,2);shine.BackgroundColor3=Color3.new(1,1,1);shine.BackgroundTransparency=.55;shine.BorderSizePixel=0;round(shine)
 data.gui=b;data.top=topOf(m,root);data.topScale=m:GetScale();data.shown=1
 if m:GetAttribute("Giant") then b.Enabled=false end -- the giant has the big bar at the top of the screen
end
Run.PreSimulation:Connect(function(dt)
 local now=os.clock();local cam=workspace.CurrentCamera.CFrame.Position
 for m,data in pairs(models) do
  local root=m.PrimaryPart
  if not m.Parent then models[m]=nil
  elseif root then
   if not data.bar then makeBar(m,root,data) end
   local serverNow=workspace:GetServerTimeNow();local stunned=serverNow<(m:GetAttribute('StunnedUntil') or 0);local notice=serverNow-(m:GetAttribute('NoticedAt') or -100)
   data.alert.Text=not stunned and notice<.8 and '!' or '';data.stars.Visible=stunned;data.stars.Rotation=math.sin(now*5)*8
   local frac=math.clamp((m:GetAttribute("Health") or 0)/math.max(1,m:GetAttribute("MaxHealth") or 30),0,1)
   data.bar.Size=UDim2.fromScale(frac,1);data.bar.Visible=frac>0
   data.bar.BackgroundColor3=frac>.5 and GREEN or frac>.25 and YELLOW or RED
   data.shown=frac<data.shown and data.shown+(frac-data.shown)*(1-math.exp(-dt*4)) or frac
   data.lag.Size=UDim2.fromScale(data.shown,1)
   local top=data.top*m:GetScale()/data.topScale+.9*m:GetScale()
   if (root.Position-cam).Magnitude<(m:GetAttribute("Giant") and 700 or C.AnimateDistance) then
    if not data.motion then data.motion=Animation.New(m) end
    Animation.Step(m,data.motion,dt)
    local target=root.CFrame;data.renderCF=data.renderCF or target
    local gap=(target.Position-data.renderCF.Position).Magnitude
    local alpha=1-math.exp(-math.min(dt,.1)*18)
    if gap>40 then alpha=1 elseif gap>0 then alpha=math.min(alpha,1.4/gap) end
    data.renderCF=data.renderCF:Lerp(target,alpha)
    local offset=target:ToObjectSpace(data.renderCF)
    for _,joint in root:GetChildren() do if joint:IsA('Motor6D') then joint.Transform=joint.C0:Inverse()*offset*joint.C0*joint.Transform end end
    m:SetAttribute('RenderedPosition',data.renderCF.Position)
    m:SetAttribute("AnimationSpeed",data.motion.speed)
    data.gui.StudsOffsetWorldSpace=data.renderCF.Position-target.Position+Vector3.new(0,top,0)
   else
    if data.motion then data.motion.last=root.Position;data.motion.speed=0 end;data.renderCF=nil
    data.gui.StudsOffsetWorldSpace=Vector3.new(0,top,0)
   end
  end
 end
end)
-- The boss bar: a wide health bar at the top of the screen while you stand in a boss's amphitheatre.
local Progression=require(S.Config.RoadProgression)
local bossGui=Instance.new("ScreenGui");bossGui.Name="BossBar";bossGui.ResetOnSpawn=false;bossGui.IgnoreGuiInset=false;bossGui.DisplayOrder=4;bossGui.Enabled=false;bossGui.Parent=p:WaitForChild("PlayerGui")
local bossFrame=Instance.new("Frame",bossGui);bossFrame.AnchorPoint=Vector2.new(.5,0);bossFrame.Position=UDim2.new(.5,0,0,64);bossFrame.Size=UDim2.new(.42,0,0,46);bossFrame.BackgroundTransparency=1
local bossSize=Instance.new("UISizeConstraint",bossFrame);bossSize.MinSize=Vector2.new(260,40);bossSize.MaxSize=Vector2.new(560,46)
local bossTitle=Instance.new("TextLabel",bossFrame);bossTitle.Size=UDim2.new(1,0,0,22);bossTitle.BackgroundTransparency=1;bossTitle.Font=Enum.Font.GothamBlack;bossTitle.TextSize=20;bossTitle.TextColor3=Color3.fromHex("FFE7A3");bossTitle.TextStrokeTransparency=0;bossTitle.AutoLocalize=false
local bossBack=Instance.new("Frame",bossFrame);bossBack.Position=UDim2.fromOffset(0,24);bossBack.Size=UDim2.new(1,0,0,18);bossBack.BackgroundColor3=Color3.fromHex("2A1630");bossBack.BorderSizePixel=0;round(bossBack,.5)
local bossStroke=Instance.new("UIStroke",bossBack);bossStroke.Color=Color3.fromHex("140A18");bossStroke.Thickness=2.5
local bossLag=Instance.new("Frame",bossBack);bossLag.Size=UDim2.fromScale(1,1);bossLag.BackgroundColor3=Color3.new(1,1,1);bossLag.BorderSizePixel=0;round(bossLag,.5)
local bossFill=Instance.new("Frame",bossBack);bossFill.Size=UDim2.fromScale(1,1);bossFill.BackgroundColor3=Color3.fromHex("E8364F");bossFill.BorderSizePixel=0;round(bossFill,.5)
local bossShown,bossModel=1,nil
Run.Heartbeat:Connect(function(dt)
 local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart");local found
 -- the Blood Moon giant is shown to everyone, wherever they are
 for m in pairs(models) do if m.Parent and m:GetAttribute("Giant") and (m:GetAttribute("Health") or 0)>0 then found=m;break end end
 if root and not found then
  for m in pairs(models) do
   local center=m.Parent and m:GetAttribute("ArenaCenter")
   if typeof(center)=="Vector3" and (m:GetAttribute("Health") or 0)>0 then
    local flat=Vector3.new(root.Position.X-center.X,0,root.Position.Z-center.Z)
    if flat.Magnitude<=Progression.ArenaRadius+30 and math.abs(root.Position.Y-center.Y)<40 then found=m;break end
   end
  end
 end
 bossGui.Enabled=found~=nil
 if not found then bossModel=nil;return end
 local frac=math.clamp((found:GetAttribute("Health") or 0)/math.max(1,found:GetAttribute("MaxHealth") or 1),0,1)
 if found~=bossModel then bossModel=found;bossShown=frac end
 if found:GetAttribute("Giant") then
  local left=math.max(0,(found:GetAttribute("GiantEndsAt") or 0)-workspace:GetServerTimeNow())
  bossTitle.Text="🩸 "..L.text("bloodMoonBar",L.lang()).." · "..L.text(found:GetAttribute("BossName") or "Chief",L.lang())..string.format(" · %d:%02d",math.floor(left/60),math.floor(left%60))
 else
  bossTitle.Text="☠ "..L.text("bossBar",L.lang()).." · "..L.text(found:GetAttribute("BossName") or "Chief",L.lang())..(found:GetAttribute("Enraged") and " 🌙" or "")
 end
 bossFill.Size=UDim2.fromScale(frac,1);bossFill.Visible=frac>0
 bossShown=frac<bossShown and bossShown+(frac-bossShown)*(1-math.exp(-dt*3)) or frac
 bossLag.Size=UDim2.fromScale(bossShown,1)
end)
