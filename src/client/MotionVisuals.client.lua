-- Bounded, local-only presentation driven by replicated server state on every client.
local Players=game:GetService('Players');local Run=game:GetService('RunService');local Tween=game:GetService('TweenService');local Debris=game:GetService('Debris')
local p=Players.LocalPlayer;local S=game.ReplicatedStorage:WaitForChild('Shared');local L=require(S.Locale)
local folder=Instance.new('Folder',workspace);folder.Name='LocalMotionVisuals'
local people={};local belts={};local pulse=0
local function part(name,size,color)
 local q=Instance.new('Part');q.Name=name;q.Size=size;q.Color=color;q.Anchored=true;q.CanCollide=false;q.CanTouch=false;q.CanQuery=false;q.CastShadow=false;q.Parent=folder;return q
end
local function puff(pos,color,slime)
 local q=part(slime and 'SlowSlime' or 'RunDust',Vector3.one*(slime and .15 or .25),color);q.Shape=Enum.PartType.Ball;q.Material=slime and Enum.Material.Neon or Enum.Material.SmoothPlastic;q.Position=pos
 Tween:Create(q,TweenInfo.new(.45),{Position=pos+Vector3.new(0,slime and -.6 or .6,0),Size=Vector3.one*(slime and .08 or .8),Transparency=1}):Play();Debris:AddItem(q,.46)
end
-- Training numbers burst out of the treadmill (owner's reference): a sneaker and a pink "+N", three per half-second
-- step, each flung out fast in its own direction. The three always add up to what the step really gave.
local SHOE=require(S.Icons).hudSpeed
local function flyGain(origin,amount,flight)
 flight=flight or .7
 local q=part('TrainingGain',Vector3.one*.1,Color3.new());q.Transparency=1;q.Position=origin
 local b=Instance.new('BillboardGui');b.Size=UDim2.fromOffset(170,46);b.MaxDistance=90;b.LightInfluence=0;b.AlwaysOnTop=true;b.Parent=q
 local holder=Instance.new('Frame');holder.BackgroundTransparency=1;holder.Size=UDim2.fromScale(1,1);holder.Parent=b
 local pop=Instance.new('UIScale');pop.Scale=.3;pop.Parent=holder
 local icon=Instance.new('ImageLabel');icon.BackgroundTransparency=1;icon.Size=UDim2.fromOffset(42,42);icon.Position=UDim2.fromOffset(0,2);icon.Image=SHOE or '';icon.Parent=holder
 local t=Instance.new('TextLabel');t.BackgroundTransparency=1;t.Size=UDim2.new(1,-46,1,0);t.Position=UDim2.fromOffset(46,0);t.TextXAlignment=Enum.TextXAlignment.Left
 t.Text='+'..L.compact(amount,L.lang());t.Font=Enum.Font.GothamBlack;t.TextSize=36;t.TextColor3=Color3.fromRGB(255,62,108);t.Parent=holder
 local st=Instance.new('UIStroke');st.Color=Color3.fromRGB(46,10,34);st.Thickness=3;st.LineJoinMode=Enum.LineJoinMode.Round;st.Parent=t
 local angle=math.random()*math.pi*2
 local out=Vector3.new(math.cos(angle),0,math.sin(angle))*(3.5+math.random()*4)+Vector3.new(0,2+math.random()*3.5,0)
 Tween:Create(q,TweenInfo.new(flight,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Position=origin+out}):Play()
 Tween:Create(pop,TweenInfo.new(.16,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
 task.delay(flight*.6,function()
  if not q.Parent then return end
  local fade=TweenInfo.new(.28)
  Tween:Create(t,fade,{TextTransparency=1}):Play();Tween:Create(st,fade,{Transparency=1}):Play();Tween:Create(icon,fade,{ImageTransparency=1}):Play()
 end)
 Debris:AddItem(q,flight+.05)
end
-- The better the treadmill (owner, 2026-11-13), the faster the numbers pour out: more of them per step, closer
-- together and flung quicker. They still add up to what the step gave.
local function floatGain(root,gain,level)
 gain=math.max(0,math.floor(gain+.5));if gain<=0 then return end
 level=math.clamp(level or 1,1,7)
 local n=math.min(gain,2+level);local each=math.floor(gain/n);local gap=.42/n;local flight=math.max(.35,.75-.06*level)
 for i=1,n do
  local amount=i<n and each or gain-each*(n-1)
  if amount>0 then task.delay((i-1)*gap,function() if root.Parent then flyGain(root.Position+Vector3.new(0,1.5,0),amount,flight) end end) end
 end
end
local function add(q)
 if not q:IsA('Model') or q.Name~='OutdoorTreadmill' or belts[q] then return end
 task.defer(function()
  if not q.Parent then return end
  local belt=q:FindFirstChild('Belt');if not belt then return end
  local parts={};local arrows=q:FindFirstChild('Arrows');if arrows then arrows.LocalTransparencyModifier=1 end
  for i=1,8 do parts[i]=part('BeltStripe',Vector3.new(6.1,.025,.065),Color3.fromRGB(88,103,120)) end
  local chevrons={};for i=1,4 do chevrons[i]={part('BeltArrow',Vector3.new(.15,.035,1.4),Color3.fromRGB(104,245,231)),part('BeltArrow',Vector3.new(.15,.035,1.4),Color3.fromRGB(104,245,231))};for _,a in chevrons[i] do a.Material=Enum.Material.Neon end end
  local sounds={};local sources=game.ReplicatedStorage:FindFirstChild('Sounds')
  for _,name in {'TreadmillMotor','TreadmillWind'} do local source=sources and sources:FindFirstChild(name);if source then local sound=source:Clone();sound.Looped=true;sound.Volume=0;sound.RollOffMinDistance=5;sound.RollOffMaxDistance=38;sound.Parent=belt;sounds[name]=sound end end
  -- The belt runs away from the console, under the feet of a runner who faces it (it ran the other way before).
  local console=q:FindFirstChild('TreadmillConsole');local dir=console and belt.CFrame:PointToObjectSpace(console.Position).Z>0 and -1 or 1
  belts[q]={belt=belt,phase=0,parts=parts,arrows=chevrons,sounds=sounds,dir=dir,console=console}
 end)
end
workspace.DescendantAdded:Connect(add);for _,q in workspace:GetDescendants() do add(q) end
Run.RenderStepped:Connect(function(dt)
 dt=math.min(dt,.1);local now=workspace:GetServerTimeNow();local cam=workspace.CurrentCamera
 pulse=math.max(0,pulse-dt*4)
 local metrics=p.PlayerGui:FindFirstChild('DigUI');metrics=metrics and metrics:FindFirstChild('Metrics');local counter=metrics and metrics:FindFirstChild('Speed')
 if counter then local scale=counter:FindFirstChild('StepPulse') or Instance.new('UIScale',counter);scale.Name='StepPulse';scale.Scale=1+math.sin(pulse*math.pi)*.14 end
 for _,who in Players:GetPlayers() do
  local ch=who.Character;local root=ch and ch:FindFirstChild('HumanoidRootPart');local hum=ch and ch:FindFirstChildOfClass('Humanoid');local d=people[who]
  if d and d.ch~=ch then for _,q in d.stars do q:Destroy() end;people[who]=nil;d=nil end
  if root and hum and (root.Position-cam.CFrame.Position).Magnitude<110 then
   if not d then d={ch=ch,stars={},dust=0,line=0,slime=0,step=who:GetAttribute('TrainingStepAt')};people[who]=d end
   local ko=now<(who:GetAttribute('KnockedOutUntil') or 0)
   if ko then
    for i=1,3 do local q=d.stars[i];if not q then q=part('KnockoutStar',Vector3.new(.2,.2,.2),Color3.fromRGB(255,225,75));q.Material=Enum.Material.Neon;local b=Instance.new('BillboardGui',q);b.Size=UDim2.fromOffset(26,26);local t=Instance.new('ImageLabel',b);t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Image=require(S.Icons).star;q.Transparency=1;d.stars[i]=q end;local angle=now*3+i*math.pi*2/3;q.Position=root.Position+Vector3.new(math.cos(angle)*1.3,2.3+math.sin(angle*2)*.18,math.sin(angle)*1.3) end
   elseif #d.stars>0 then for _,q in d.stars do q:Destroy() end;table.clear(d.stars) end
   local speed=Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z).Magnitude
   if not ko and hum.FloorMaterial~=Enum.Material.Air and speed>8 and now>d.dust then d.dust=now+.16;puff(root.Position+Vector3.new(math.random()-.5,-2.8,math.random()-.5),Color3.fromRGB(186,169,130),false) end
   if speed>40 and not ko and now>d.line then
    d.line=now+.09;local q=part('SpeedLine',Vector3.new(.035,.035,2.5),Color3.fromRGB(210,245,255));q.Material=Enum.Material.Neon;q.CFrame=root.CFrame*CFrame.new((math.random()-.5)*4,math.random()-.5,2)
    Tween:Create(q,TweenInfo.new(.22),{CFrame=q.CFrame*CFrame.new(0,0,3),Transparency=1}):Play();Debris:AddItem(q,.23)
   end
   if now<(who:GetAttribute('MutantSlowUntil') or 0) and now>d.slime then d.slime=now+.14;puff(root.Position+Vector3.new(math.random()-.5,-2.1,math.random()-.5),Color3.fromRGB(156,222,64),true) end
   local step=who:GetAttribute('TrainingStepAt');if step and step~=d.step then d.step=step;floatGain(root,who:GetAttribute('TrainingStepGain') or 0,who:GetAttribute('TreadmillLevel'));if who==p then pulse=1 end end
  elseif d and #d.stars>0 then for _,q in d.stars do q:Destroy() end;table.clear(d.stars) end
 end
 for model,d in belts do
  if not model.Parent then for _,q in d.parts do q:Destroy() end;for _,pair in d.arrows do for _,q in pair do q:Destroy() end end;for _,q in d.sounds do q:Destroy() end;belts[model]=nil
  else
   local who=Players:GetPlayerByUserId(model:GetAttribute('Owner') or 0);local active=who and who:GetAttribute('Training')==true;local level=model:GetAttribute('Level') or 1
   if active then d.phase=(d.phase+dt*(3+level*1.3))%24 end
   local near=(d.belt.Position-cam.CFrame.Position).Magnitude<110
   for i,q in d.parts do local z=d.dir*(((i-1)*1.5+d.phase)%12-6);q.CFrame=d.belt.CFrame*CFrame.new(0,.115,z);q.Transparency=near and .5 or 1 end
   for i,pair in d.arrows do local z=d.dir*(((i-1)*3+d.phase)%12-6);for j,q in pair do local sign=j==1 and -1 or 1;q.CFrame=d.belt.CFrame*CFrame.new(sign*.43,.14,z)*CFrame.Angles(0,-d.dir*sign*.7,0);q.Transparency=near and math.clamp((math.abs(z)-4.8)/1.2,0,1) or 1 end end
   for name,sound in d.sounds do
    local playing=active and near
    if playing and not sound.Playing then sound:Play() elseif not playing and sound.Playing then sound:Stop() end
    sound.Volume=(name=='TreadmillMotor' and .08 or .06)*(p:GetAttribute('SfxVolume') or 1);sound.PlaybackSpeed=.8+level*.12
   end
   model:SetAttribute('VisualBeltPhase',d.phase)
   if who==p and d.console then
    local ch=p.Character;local root=ch and ch:FindFirstChild('HumanoidRootPart');local hum=ch and ch:FindFirstChildOfClass('Humanoid')
    if root and hum then
     if active then
      local flat=Vector3.new(d.console.Position.X,root.Position.Y,d.console.Position.Z)
      if (flat-root.Position).Magnitude>.5 then hum.AutoRotate=false;d.turned=true;root.CFrame=root.CFrame:Lerp(CFrame.lookAt(root.Position,flat),1-math.exp(-dt*10)) end
     elseif d.turned then d.turned=false;hum.AutoRotate=true end
    end
   end
  end
 end
end)
Players.PlayerRemoving:Connect(function(who) local d=people[who];if d then for _,q in d.stars do q:Destroy() end end;people[who]=nil end)
