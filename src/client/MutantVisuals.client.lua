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
 for i=1,6 do local f=Style.Icon(g,'cash',nil,UDim2.fromOffset(30,30),UDim2.fromOffset(point.X-inset.X+math.random(-35,35),point.Y-inset.Y));f.Name='MutantRewardCoin'
  Tween:Create(f,TweenInfo.new(.65+i*.04,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=UDim2.fromOffset(target.X,target.Y),Size=UDim2.fromOffset(12,12)}):Play();Debris:AddItem(f,1.1)
 end
 Sfx.play("Coins",.2)
end
RS:WaitForChild("Remotes"):WaitForChild("MutantFX").OnClientEvent:Connect(function(kind,id,pos,value,extra)
 if kind=="Reward" then reward(pos,value,extra);return end
 if (pos-workspace.CurrentCamera.CFrame.Position).Magnitude>C.AnimateDistance then return end
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
  Sfx.play("Fire"..extra,.1);return
 end
 if kind=="Spawn" then
  local q=dot(Vector3.new(pos.X,.75,pos.Z),Color3.fromHex("5C0A2E"),3,C.SpawnSeconds);q.Size=Vector3.new(3,.08,1);smoke(pos-Vector3.new(0,1.3,0));Sfx.play("ImpLaugh",1)
 elseif kind=="Death" or kind=="Smoke" then smoke(pos);if kind=="Death" then Sfx.play("ImpDeath",.15) end
 elseif kind=="Hit" then
  damage(pos,value,extra==true);Sfx.play("ImpHit",.09)
  for m in pairs(models) do if m:GetAttribute("MutantId")==id then local h=Instance.new("Highlight");h.FillColor=Color3.new(1,1,1);h.FillTransparency=0;h.OutlineTransparency=1;h.Parent=m;Debris:AddItem(h,.08);break end end
 elseif kind=="Telegraph" then
  local q=dot(Vector3.new(pos.X,.65,pos.Z),Color3.fromHex("FFAE37"),1,extra)
  q.Name="MutantAttackWarning";q.Shape=Enum.PartType.Cylinder;q.Size=Vector3.new(.08,value*2,value*2);q.CFrame=CFrame.new(q.Position)*CFrame.Angles(0,0,math.pi/2);q.Material=Enum.Material.Neon;q.Transparency=.6
  Tween:Create(q,TweenInfo.new(extra),{Transparency=.15}):Play()
 elseif kind=="HunterShot" then
  local delta=value-pos
  if delta.Magnitude>.01 then
   local q=dot(pos,Color3.fromRGB(255,219,122),.15,.1);q.Shape=Enum.PartType.Block;q.Material=Enum.Material.Neon;q.Size=Vector3.new(.12,.12,delta.Magnitude);q.CFrame=CFrame.lookAt(pos,value)*CFrame.new(0,0,-delta.Magnitude/2)
   local flash=dot(pos,Color3.fromRGB(255,239,183),.8,.08);flash.Material=Enum.Material.Neon
   Sfx.play("FireAK",.12)
  end
 elseif kind=="Acid" then
  local q=dot(pos,Color3.fromHex("B8F749"),.85,.25);q.Material=Enum.Material.Neon
  Tween:Create(q,TweenInfo.new(.2),{Position=value}):Play()
 elseif kind=="Slam" then
  local q=dot(Vector3.new(value.X,.8,value.Z),Color3.fromHex("EC86B2"),1,.35);q.Shape=Enum.PartType.Cylinder;q.CFrame=CFrame.new(q.Position)*CFrame.Angles(0,0,math.pi/2);q.Size=Vector3.new(.15,1,1);q.Material=Enum.Material.Neon
  Tween:Create(q,TweenInfo.new(.35),{Size=Vector3.new(.15,extra*2,extra*2),Transparency=1}):Play()
 elseif kind=="Bite" then Sfx.play("ImpBite",.5)
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
   if (root.Position-cam).Magnitude<C.AnimateDistance then
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
