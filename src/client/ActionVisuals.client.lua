-- Presentation only. Gameplay, timers, equipment and contacts come from the server.
local Players=game:GetService('Players');local Run=game:GetService('RunService');local Tween=game:GetService('TweenService');local Debris=game:GetService('Debris')
local p=Players.LocalPlayer;local S=game.ReplicatedStorage:WaitForChild('Shared');local L=require(S.Locale);local Sfx=require(S.Sfx);local Shovels=require(S.Config.ShovelConfig);local Guns=require(S.Config.WeaponConfig);local Shovel=require(S.ShovelModel);local Chainsaw=require(S.ChainsawModel)
local function meleeOf(who) local id=who:GetAttribute('EquippedShovel');return Shovels[id or ''] and id or Shovels.Order[1] end
local ShovelMotion=require(S.ShovelMotion)
local visuals=Instance.new('Folder',workspace);visuals.Name='LocalActionVisuals'
local characters={};local drops={};local colliders={};local tickAt=0
local function part(name,color)
 local q=Instance.new('Part');q.Name=name;q.Anchored=true;q.CanCollide=false;q.CanQuery=false;q.CanTouch=false;q.CastShadow=false;q.Material=Enum.Material.Neon;q.Color=color;q.Parent=visuals;return q
end
local function label(parent,name)
 local b=Instance.new('BillboardGui');b.Name=name;b.Size=UDim2.fromOffset(150,56);b.StudsOffsetWorldSpace=Vector3.new(0,4,0);b.AlwaysOnTop=false;b.MaxDistance=90;b.Parent=parent
 local t=Instance.new('TextLabel',b);t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Font=Enum.Font.GothamBold;t.TextScaled=true;t.TextColor3=Color3.new(1,1,1);t.TextStrokeTransparency=.15;t.Text='';return b,t
end
local function clock(parent)
 local f=Instance.new('Frame');f.Name='SlowClock';f.BackgroundTransparency=1;f.Size=UDim2.fromOffset(34,34);f.Position=UDim2.new(.5,-17,1,-2);f.Parent=parent
 local segments={}
 for i=1,24 do local a=(i-1)/24*math.pi*2;local q=Instance.new('Frame',f);q.BorderSizePixel=0;q.Size=UDim2.fromOffset(3,6);q.AnchorPoint=Vector2.one*.5;q.Position=UDim2.fromOffset(17+14*math.sin(a),17-14*math.cos(a));q.Rotation=math.deg(a);q.BackgroundColor3=Color3.fromRGB(255,146,87);segments[i]=q end
 return f,segments
end
local function dirt(root)
 for i=1,5 do
  local q=part('DigDirt',Color3.fromRGB(113,76,45));q.Material=Enum.Material.Ground;q.Size=Vector3.one*(.15+math.random()*.16)
  q.CFrame=root.CFrame*CFrame.new((math.random()-.5)*.9,-2.5,-2);local to=q.Position+root.CFrame.RightVector*(math.random()-.5)*2+Vector3.new(0,1+math.random(),0)
  Tween:Create(q,TweenInfo.new(.22,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=to,Orientation=Vector3.new(60,30,100)}):Play()
  task.delay(.22,function() if q.Parent then Tween:Create(q,TweenInfo.new(.3),{Position=to-Vector3.new(0,1.8,0),Transparency=1}):Play() end end);Debris:AddItem(q,.55)
 end
end
local function watch(v)
 if v:IsA('BasePart') then local world=workspace:FindFirstChild('DigAZombie');if world and v.CanCollide and v.CanQuery and v:IsDescendantOf(world) then colliders[v]=true end end
 if v:IsA('Model') and v.Name=='DroppedGrave' then
  local born=v:GetAttribute('DropBornAt');if not born then return end
  local parts={};for _,q in v:GetDescendants() do if q:IsA('BasePart') and q.Name~='RoadGrabSpot' and q.Name~='RoadGlow' then parts[q]=q.CFrame end end
  local anchor=v:FindFirstChild('RoadGrabSpot');if anchor then local b,t=label(anchor,'DropTimer');b.StudsOffsetWorldSpace=Vector3.new(0,2,0);drops[v]={born=born,parts=parts,label=t,ring=v:FindFirstChild('RoadGlow')} end
 end
end
for _,v in workspace:GetDescendants() do watch(v) end
workspace.DescendantAdded:Connect(watch);workspace.DescendantRemoving:Connect(function(v) colliders[v]=nil;drops[v]=nil end)
local lines={};for i=1,52 do lines[i]=part('ActionRange',Color3.fromRGB(150,245,217));lines[i].Transparency=1 end
local function line(q,a,b,alpha)
 local d=b-a;if d.Magnitude<.02 then q.Transparency=1;return end
 q.Size=Vector3.new(.13,.08,d.Magnitude);q.CFrame=CFrame.lookAt((a+b)/2,b);q.Transparency=alpha
end
-- The owner dropped the range rings under the player (2026-11-08): they stay hidden.
local function range()
 for _,q in lines do q.Transparency=1 end
 do return end
 local ch=p.Character;local root=ch and ch:FindFirstChild('HumanoidRootPart');if not root or p:GetAttribute('ActiveSlot')==3 or p:GetAttribute('ShowRanges')==false or p:GetAttribute('InHouse') then return end
 local world=workspace:FindFirstChild('DigAZombie');local farm=false
 if game.Lighting.ClockTime>18 or game.Lighting.ClockTime<6 then
  local plots=world
  if plots then for _,m in plots:GetChildren() do local base=m:IsA('Model') and m.Name:match('^Plot%d+$') and m:FindFirstChild('Lawn');if base then local pos=base.CFrame:PointToObjectSpace(root.Position);if math.abs(pos.X)<=32 and pos.Z>=-32 and pos.Z<=62 then farm=true;break end end end end
 end
 if not p:GetAttribute('OnRoad') and not farm then return end
 local include={};for v in colliders do if v.Parent and v.CanCollide and v.CanQuery then table.insert(include,v) end end
 local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances=include
 local function ground(point) local hit=workspace:Raycast(point+Vector3.new(0,7,0),Vector3.new(0,-20,0),rp);return hit and hit.Position+Vector3.new(0,.065,0) end
 local gun=p:GetAttribute('ActiveSlot')==2;local cfg=gun and Guns[p:GetAttribute('EquippedWeapon') or 'Deagle'] or Shovels[meleeOf(p)]
 local radius=gun and (p:GetAttribute('WeaponRange') or cfg.Range) or cfg.Range;local half=gun and math.pi or math.rad(Shovels.HalfAngle);local menu=p.PlayerGui:FindFirstChild('DigUI');menu=menu and menu:FindFirstChild('Menu');local alpha=menu and menu.Visible and .88 or .4
 local center=ground(root.Position);local previous
 for i=0,48 do local angle=-half+2*half*i/48;local at=ground((root.CFrame*CFrame.new(math.sin(angle)*radius,0,-math.cos(angle)*radius)).Position)
  if previous and at then line(lines[i],previous,at,alpha) end
  if not gun and center and at and (i==0 or i==48) then line(lines[i==0 and 49 or 50],center,at,alpha) end
  previous=at
 end
end
Run.PreSimulation:Connect(function(dt)
 local now=workspace:GetServerTimeNow()
 for _,who in Players:GetPlayers() do
  local ch=who.Character;local root=ch and ch:FindFirstChild('HumanoidRootPart');local hand=ch and (ch:FindFirstChild('RightHand') or ch:FindFirstChild('Right Arm'))
  local data=characters[who]
  if data and data.ch~=ch then if data.shovel then data.shovel:Destroy() end;characters[who]=nil;data=nil end
  if root and hand then
   if not data then local b,t=label(root,'ActionStatus');local f,segments=clock(b);data={ch=ch,status=b,text=t,clock=f,segments=segments,phase=0};characters[who]=data end
   local ko=now<(who:GetAttribute('KnockedOutUntil') or 0);local dig=who:GetAttribute('DiggingGrave')
   local motion=ShovelMotion.ForPlayer(who,now)
   -- what is in the hands: the melee weapon, or the tool the motion names - a finisher's weapon, the shovel a grave
   -- is dug with ('Dig')
   local id=motion and motion.tool or meleeOf(who)
   -- only what is in the hands shows (owner, 2026-11-13: one weapon at a time): no shovel on the back
   local show=not ko and not who:GetAttribute('Training') and motion~=nil
   if data.shovel and (not show or id~=data.id or not data.shovel.Parent) then
    data.shovel:Destroy();data.shovel=nil
    if data.engine then data.engine:Destroy();data.engine=nil end
   end
   if show and not data.shovel then
    local m=Shovel.Build(id,ch);local w=Instance.new('Weld',m.PrimaryPart);w.Name='ShovelGrip';w.Part1=m.PrimaryPart;data.shovel=m;data.grip=w;data.id=id;data.mode=nil;data.origin=m:GetPivot():ToObjectSpace(m.PrimaryPart.CFrame)
    data.chain,data.pulls=0,0
   end
   -- Ready hold stays upright independently of wrist animation; actions follow the hand.
   local torso=ch:FindFirstChild('UpperTorso') or ch:FindFirstChild('Torso')
   local mode=motion and 'hand' or 'back'
   if data.shovel and torso and data.mode~=mode then
    local part0=mode~='back' and hand or torso
    local goal=mode=='hand' and CFrame.new(hand.Position)*root.CFrame.Rotation*CFrame.Angles(0,motion.spin,0)*motion.frame.Rotation or torso.CFrame*CFrame.new(-.8,.4,1.05)*CFrame.Angles(0,0,math.rad(-25))
    data.grip.Enabled=false;data.shovel:PivotTo(goal);data.grip.Part0=part0;data.grip.C0=part0.CFrame:ToObjectSpace(data.shovel.PrimaryPart.CFrame);data.grip.Enabled=true;data.mode=mode
   end
   if motion and data.shovel and data.grip then
    if motion.grip then
     data.grip.C0=motion.grip -- the saw's own frame (its PrimaryPart) sits in the hand as its motion says (CombatPose.SawPose puts the hand there)
    elseif ch:FindFirstChild('RightLowerArm') then
     -- Both wrist and shovel use the same pose basis, in the same simulation step.
     -- (slide: the boss finisher holds it by the top of the shaft, ShovelMotion.Finisher)
     data.grip.C0=CFrame.Angles(math.pi/2,0,-.2):Inverse()*motion.frame.Rotation*CFrame.new(0,motion.slide or 0,0)*data.origin
    else
     local frame=CFrame.new(hand.Position)*root.CFrame.Rotation*CFrame.Angles(0,motion.spin,0)*motion.frame.Rotation
     data.grip.C0=hand.CFrame:ToObjectSpace(frame*data.origin)
    end
   end
   -- The chainsaw alive (ShovelMotion's saw): the cord's rasp at each pull, the engine as a loop whose pitch and
   -- loudness follow the revs, smoke from the muffler, the chain running, sparks and chips where it cuts.
   -- (the chainsword's too, 2026-11-16; either revs through a plain swing)
   if motion and data.shovel and data.shovel:GetAttribute('Bar') then
    local saw=data.shovel;local handle=saw.PrimaryPart;local near=Sfx.at(handle.Position,30,160)
    local engine,cutting,pulls=motion.engine or 0,motion.cutting or 0,motion.pulls or 0
    if pulls>data.pulls then Sfx.play('ChainsawPull',.1,near) end
    data.pulls=pulls
    local running=engine>.02
    if running and not data.engine then
     local source=game.ReplicatedStorage:FindFirstChild('Sounds');source=source and source:FindFirstChild('ChainsawEngine')
     if source then local e=source:Clone();e.Name='Engine';e.Looped=true;e.RollOffMode=Enum.RollOffMode.InverseTapered;e.RollOffMinDistance=18;e.RollOffMaxDistance=170;e.Parent=handle;e:Play();data.engine=e;data.engineVolume=source.Volume end
    elseif not running and data.engine then data.engine:Destroy();data.engine=nil end
    if data.engine then
     data.engine.Volume=data.engineVolume*(p:GetAttribute('SfxVolume') or 1)*(.35+.65*engine+.25*cutting)
     data.engine.PlaybackSpeed=(data.id=='Chainsword' and .95 or .8)+.45*engine-.12*cutting+math.noise(now*9,4.2)*.05*cutting
    end
    data.chain+=dt*engine*34;Chainsaw.Run(saw,data.chain)
    local cut=handle:FindFirstChild('Cut');local muffler=saw:FindFirstChild('Muffler');local exhaust=muffler and muffler:FindFirstChild('Exhaust')
    if cut then cut.Sparks.Enabled=cutting>.5;cut.Chips.Enabled=cutting>.5 end
    if exhaust then exhaust.Smoke.Enabled=running;exhaust.Smoke.Rate=14+30*engine end
   end
   -- the butterfly knife flips in its flourish (ShovelModel.Flip)
   if data.shovel and data.id=='Butterfly' then
    local flip=motion and motion.flip or 0
    if flip~=data.flip then data.flip=flip;Shovel.Flip(data.shovel,flip) end
   end
   if dig then
    local start=who:GetAttribute('DigStartedAt') or now;local duration=who:GetAttribute('DigDuration') or 1.5
    if start~=data.digStart then data.digStart=start;data.stroke=0 end
    local stroke=math.clamp(math.floor((now-start)/duration*3+.48),0,3)
    if stroke>data.stroke then dirt(root);if (workspace.CurrentCamera.CFrame.Position-root.Position).Magnitude<25 then Sfx.play('Dig',.3) end;data.stroke=stroke;ch:SetAttribute('DigVisualStrokes',stroke) end
   else data.digStart=nil end
   local speed=Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z).Magnitude;data.phase+=dt*(5+math.min(speed,40)*.4)
   local carry=ch:FindFirstChild('CarriedGrave');local grip=root:FindFirstChild('CarrierGrip')
   if carry and grip then
    if data.carry~=carry then data.carry=carry;data.carryAt=now;local b,t=label(carry.PrimaryPart,'GraveName');b.StudsOffsetWorldSpace=Vector3.new(0,2.8,0);b.Size=UDim2.fromOffset(160,30);data.name=t end
    local arrive=math.max(0,1-(now-data.carryAt)/.45);local moving=math.min(speed/16,1)
    grip.Transform=CFrame.new(0,-1.8*arrive+math.abs(math.sin(data.phase))*.055*moving,-.6*arrive)*CFrame.Angles(.25*arrive,0,math.sin(data.phase)*.035*moving)
    local family=carry:GetAttribute('Family') -- whose grave it is (2026-11-17): "Stone grave · Deer"
    data.name.Text=L.text('grave_'..carry:GetAttribute('GraveType'),L.lang())..(family and ' · '..L.text('roadName_'..family,L.lang()) or '')
   end
   local left=math.max(0,(who:GetAttribute('MutantSlowUntil') or 0)-now)
   data.status.Enabled=ko or left>0;data.text.Text=ko and '' or '↓  −35%';data.text.TextColor3=ko and Color3.fromRGB(255,229,107) or Color3.fromRGB(255,156,94);data.text.Rotation=ko and math.sin(now*8)*8 or 0
   data.clock.Visible=not ko and left>0;for i,q in data.segments do q.Visible=i<=math.ceil(left/2.5*24) end
  end
 end
 for model,data in drops do
  if not model.Parent then drops[model]=nil else
   local age=now-data.born;local y=age<.7 and math.abs(math.sin(age/.7*math.pi*2))*(1-age/.7)*1.25 or 0
   for q,cf in data.parts do if q.Parent then q.CFrame=cf+Vector3.new(0,y,0) end end
   local left=math.max(0,(model:GetAttribute('DropExpiresAt') or now)-now);data.label.Text=tostring(math.ceil(left))..'s'
   -- the soft glow under a dropped grave breathes a little (softer since 2026-11-15)
   if data.ring then data.ring.Transparency=.62+math.sin(now*3)*.08;data.ring.Size=Vector3.new(.14,7,7)*(Vector3.new(1,1,1)*(1+.04*math.sin(now*3))) end
  end
 end
 if os.clock()>=tickAt then tickAt=os.clock()+.12;range() end
end)
Players.PlayerRemoving:Connect(function(who) characters[who]=nil end)

