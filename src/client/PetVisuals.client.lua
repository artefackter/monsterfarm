-- Pets v3 (owner, 2026-11-12): nobody follows the player any more; every pet lives on its owner's farm.
--   DragonHead  patrols a ring inside the yard; when the server reports a breath (MutantFX "PetBreath") it runs at
--               the raider and spits fire at it
--   BedBanker   guards the zombucks heap, shuffling round it now and then and puffing out a coin sign
--   FacepalmCat walks along the top of the fence (hops down and across at the gate), sits, looks round, washes and
--               facepalms with its tail; it hops and shows a heart when its owner comes close
local Players=game:GetService("Players");local Run=game:GetService("RunService");local RS=game:GetService("ReplicatedStorage");local Tween=game:GetService("TweenService");local Debris=game:GetService("Debris")
local C=require(RS.Shared.Config.PetConfig);local Model=require(RS.Shared.PetModel);local L=require(RS.Shared.Locale);local Sfx=require(RS.Shared.Sfx)
local HC=require(RS.Shared.Config.HouseConfig);local PlC=require(RS.Shared.Config.PlacementConfig)
local me=Players.LocalPlayer;local rem=RS:WaitForChild("Remotes")
local folder=Instance.new("Folder",workspace);folder.Name="ClientPets"
local models,lists,fx,connections,states={},{},{},{},{}
local function update(p) local ok,list=pcall(game.HttpService.JSONDecode,game.HttpService,p:GetAttribute("EquippedPets") or "[]");lists[p]=ok and list or {} end
local function watch(p) update(p);connections[p]=p:GetAttributeChangedSignal("EquippedPets"):Connect(function() update(p) end) end
Players.PlayerAdded:Connect(watch);Players.PlayerRemoving:Connect(function(p) lists[p]=nil;if connections[p] then connections[p]:Disconnect();connections[p]=nil end end);for _,p in ipairs(Players:GetPlayers()) do watch(p) end
rem:WaitForChild("MutantFX").OnClientEvent:Connect(function(kind,id,pos,owner,petId) if kind=="PetBreath" and typeof(pos)=="Vector3" then fx[petId]={at=os.clock(),target=pos} end end)

-- The owner's farm: its lawn's top centre, turned like the plot (x across, -z towards the gate).
local farms={}
local function farmOf(p)
 local f=farms[p];if f and f.lawn.Parent then return f end
 local world=workspace:FindFirstChild("DigAZombie");if not world then return nil end
 for _,plot in world:GetChildren() do
  if plot:GetAttribute("Owner")==p.UserId then local lawn=plot:FindFirstChild("Lawn")
   if lawn then f={lawn=lawn,base=lawn.CFrame*CFrame.new(0,lawn.Size.Y/2,0),half=lawn.Size.X/2};farms[p]=f;return f end
  end
 end
 farms[p]=nil;return nil
end
local function at(f,x,y,z) return f.base*CFrame.new(x,y,z) end
local function facing(f,x,y,z,dx,dz) local cf=at(f,x,y,z);local dir=f.base:VectorToWorldSpace(Vector3.new(dx,0,dz));if dir.Magnitude<.01 then return cf end;return CFrame.lookAt(cf.Position,cf.Position+dir) end
local function pop(model,text,color)
 local b=Instance.new("BillboardGui");b.Size=UDim2.fromOffset(60,40);b.StudsOffset=Vector3.new(0,3.2,0);b.AlwaysOnTop=false;b.LightInfluence=0;b.Adornee=model.PrimaryPart;b.Parent=model
 local l=Instance.new("TextLabel",b);l.Size=UDim2.fromScale(1,1);l.BackgroundTransparency=1;l.Text=text;l.TextScaled=true;l.Font=Enum.Font.GothamBlack;l.TextColor3=color or Color3.new(1,1,1);l.TextStrokeTransparency=.3
 Tween:Create(b,TweenInfo.new(1.2),{StudsOffset=Vector3.new(0,5,0)}):Play();Tween:Create(l,TweenInfo.new(1.2),{TextTransparency=1,TextStrokeTransparency=1}):Play();Debris:AddItem(b,1.25)
end

-- Dragon -----------------------------------------------------------------------------------------------------------
local RING_X,RING_Z,RING_R,PATROL=4,-8,17,5.5
local function breathe(model,target)
 local mouth=model:GetPivot()*CFrame.new(0,.6,-2.4)
 for i=1,9 do
  task.delay(i*.035,function()
   if not model.Parent then return end
   local q=Instance.new("Part");q.Shape=Enum.PartType.Ball;q.Material=Enum.Material.Neon;q.Anchored=true;q.CanCollide=false;q.CanQuery=false;q.CanTouch=false;q.CastShadow=false
   q.Color=i%3==0 and Color3.fromHex("FFE15A") or Color3.fromHex("FF7A2E");q.Size=Vector3.one*(.5+math.random()*.4);q.Position=mouth.Position;q.Parent=folder
   local spread=Vector3.new(math.random()-.5,math.random()*.6,math.random()-.5)*2
   Tween:Create(q,TweenInfo.new(.32,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=target+spread,Size=Vector3.one*1.6,Transparency=.6}):Play();Debris:AddItem(q,.34)
  end)
 end
 task.delay(.35,function()
  local burst=Instance.new("Part");burst.Shape=Enum.PartType.Ball;burst.Material=Enum.Material.Neon;burst.Color=Color3.fromHex("FF9A3D");burst.Anchored=true;burst.CanCollide=false;burst.CanQuery=false;burst.CanTouch=false;burst.Size=Vector3.one*1.5;burst.Position=target;burst.Parent=folder
  Tween:Create(burst,TweenInfo.new(.35),{Size=Vector3.one*6,Transparency=1}):Play();Debris:AddItem(burst,.4)
 end)
 Sfx.play("BossCharge",.4,.45*Sfx.at(mouth.Position,20,160))
end
local function dragonGoal(p,pet,i,n,f,model,dt)
 local now=os.clock();local e=fx[pet.id]
 if e and now-e.at<1.6 then
  local local3=f.base:PointToObjectSpace(e.target);local here=f.base:PointToObjectSpace(model:GetPivot().Position)
  local flat=Vector3.new(local3.X-here.X,0,local3.Z-here.Z)
  local stop=flat.Magnitude>9 and Vector3.new(local3.X,0,local3.Z)-flat.Unit*8 or Vector3.new(here.X,0,here.Z)
  if not e.fired and now-e.at>.45 then e.fired=true;breathe(model,e.target) end
  return facing(f,stop.X,1,stop.Z,flat.X,flat.Z),true
 end
 local angle=now*PATROL/RING_R+(i-1)/math.max(1,n)*math.pi*2
 local x,z=RING_X+math.cos(angle)*RING_R,RING_Z+math.sin(angle)*RING_R
 return facing(f,x,1+math.abs(math.sin(now*5))*.12,z,-math.sin(angle),math.cos(angle)),false
end

-- Bed ----------------------------------------------------------------------------------------------------------------
local function bedGoal(p,pet,i,n,f,model)
 local s=states[pet.id] or {angle=(i-1)*2.1+.6,next=os.clock()+math.random(6,12),coin=os.clock()+math.random(4,9)};states[pet.id]=s
 local now=os.clock()
 if now>=s.next then s.angle+=math.random()<.5 and -.9 or .9;s.next=now+math.random(8,15) end
 if now>=s.coin then s.coin=now+math.random(7,12);pop(model,"$",Color3.fromRGB(120,255,110)) end
 local r=9.5;local x,z=PlC.Bank.X+math.cos(s.angle)*r,PlC.Bank.Z+math.sin(s.angle)*r
 -- it faces away from the heap: guarding it
 return facing(f,x,1+math.sin(now*2+i)*.04,z,math.cos(s.angle),math.sin(s.angle))
end

-- Cat ----------------------------------------------------------------------------------------------------------------
-- The fence top path, one way (it walks there and back); the two hops take it down to the lawn across the gate.
local function catPath(f)
 local F=f.half-1;local cut=(HC.Looks[1].W+2)/math.sqrt(2);local top=3.05
 -- round the outside of the cemetery where it sticks out over the back corner (2026-11-15)
 local c=PlC.Cemetery;local path={{-F+cut,F,top},{c.BackCut,F,top}}
 local from,to=math.atan2(F-c.Z,c.BackCut-c.X),math.atan2(c.SideCut-c.Z,F-c.X)
 while to>from do to-=2*math.pi end
 local n=math.ceil((from-to)*c.Radius/4)
 for k=1,n-1 do local a=from+(to-from)*k/n;table.insert(path,{c.X+math.cos(a)*c.Radius,c.Z+math.sin(a)*c.Radius,top}) end
 for _,q in {{F,c.SideCut,top},{F,-F,top},{7,-F,top},{5.5,-F+2,0,true},{-5.5,-F+2,0},{-7,-F,top,true},{-F,-F,top},{-F,F-cut,top}} do table.insert(path,q) end
 return path
end
local function pathPoint(path,s)
 local left=s
 for k=1,#path-1 do
  local a,b=path[k],path[k+1];local len=math.sqrt((b[1]-a[1])^2+(b[2]-a[2])^2)
  if left<=len or k==#path-1 then
   local t=math.clamp(left/math.max(len,.01),0,1)
   local y=a[3]+(b[3]-a[3])*t;if b[4] then y+=math.sin(t*math.pi)*2.4 end -- a hop
   return a[1]+(b[1]-a[1])*t,y,a[2]+(b[2]-a[2])*t,b[1]-a[1],b[2]-a[2],b[4]==true
  end
  left-=len
 end
end
local function pathLength(path) local n=0;for k=1,#path-1 do local a,b=path[k],path[k+1];n+=math.sqrt((b[1]-a[1])^2+(b[2]-a[2])^2) end;return n end
local function catGoal(p,pet,f,model,dt)
 local now=os.clock()
 local s=states[pet.id];if not s then local path=catPath(f);s={path=path,len=pathLength(path),pos=math.random()*20,dir=1,mode="walk",until_=now+math.random(5,9),heart=0};states[pet.id]=s end
 local x,y,z,dx,dz,hop=pathPoint(s.path,s.pos)
 local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
 local here=at(f,x,y,z).Position
 local near=root and (root.Position-here).Magnitude<11
 if s.mode=="walk" then
  local speed=hop and 6 or 3.4
  s.pos+=s.dir*speed*dt
  if s.pos>=s.len then s.pos=s.len;s.dir=-1;s.mode="sit";s.until_=now+2.5 elseif s.pos<=0 then s.pos=0;s.dir=1;s.mode="sit";s.until_=now+2.5 end
  if not hop and now>=s.until_ then
   local r=math.random();s.mode=r<.35 and "sit" or r<.65 and "facepalm" or r<.85 and "wash" or "look";s.since=now;s.until_=now+(s.mode=="facepalm" and 2 or 3)
   if s.mode=="facepalm" then pop(model,"🤦",nil) end
  end
  if near and not hop and now-s.heart>8 then s.heart=now;s.mode="greet";s.since=now;s.until_=now+1.6;pop(model,"♥",Color3.fromRGB(255,110,160)) end
 elseif now>=s.until_ then s.mode="walk";s.until_=now+math.random(6,11) end
 -- facing: along the fence while walking, into the yard when it stops, at its owner when greeting
 local face=Vector3.new(dx*s.dir,0,dz*s.dir)
 if s.mode~="walk" then face=Vector3.new(-x,0,-z) end
 if s.mode=="greet" and root then local o=f.base:PointToObjectSpace(root.Position);face=Vector3.new(o.X-x,0,o.Z-z) end
 local lift=0;local tilt=0
 if s.mode=="walk" then lift=math.abs(math.sin(now*9))*.08
 elseif s.mode=="sit" then lift=-.15;tilt=.12
 elseif s.mode=="wash" then lift=-.1+math.abs(math.sin(now*6))*.08;tilt=math.sin(now*6)*.08
 elseif s.mode=="greet" then lift=math.max(0,math.sin((now-s.since)*7))*.6
 elseif s.mode=="look" then tilt=0 end
 local cf=facing(f,x,y+1+lift,z,face.X,face.Z)*CFrame.Angles(tilt,0,0)
 if s.mode=="look" then cf*=CFrame.Angles(0,math.sin((now-(s.since or now))*1.6)*.7,0) end
 -- the tail swings forward and its angry head slaps the face
 local swing=0
 if s.mode=="facepalm" then local a=now-s.since;swing=a<.35 and -1.05*(a/.35)^2 or a<1.3 and -1.05+math.sin(a*30)*.04 or a<1.8 and -1.05*(1-(a-1.3)/.5) or 0 end
 return cf,swing
end
local function swingTail(model,data,angle)
 local body=model.PrimaryPart;if not body then return end
 if not data.rel then
  data.rel={};local hinge=model:FindFirstChild("TailHinge");data.hinge=hinge and body.CFrame:ToObjectSpace(hinge.CFrame) or CFrame.new(0,.45,.75)
  for _,q in model:GetDescendants() do if q:IsA("BasePart") and q:GetAttribute("Swing") then data.rel[q]=body.CFrame:ToObjectSpace(q.CFrame) end end
 end
 local turn=data.hinge*CFrame.Angles(angle,0,0)*data.hinge:Inverse()
 for q,rel in data.rel do q.CFrame=body.CFrame*turn*rel end
end

-- Every frame: each owner's pets on their own farm --------------------------------------------------------------------
local tagged={}
local function nameTag(model,pet)
 if tagged[model] then return end;tagged[model]=true
 local b=Instance.new("BillboardGui");b.Name="PetName";b.Size=UDim2.fromOffset(150,26);b.StudsOffset=Vector3.new(0,pet.species=="DragonHead" and 4.4 or 3,0);b.MaxDistance=35;b.LightInfluence=0;b.Adornee=model.PrimaryPart;b.Parent=model
 local l=Instance.new("TextLabel",b);l.Size=UDim2.fromScale(1,1);l.BackgroundTransparency=1;l.TextScaled=true;l.Font=Enum.Font.GothamBold;l.TextColor3=Color3.new(1,1,1);l.TextStrokeTransparency=.2;l.Text=L.text(pet.species,L.lang())
end
local swings={}
Run.RenderStepped:Connect(function(dt)
 local alive={};local camera=workspace.CurrentCamera.CFrame.Position
 for p,pets in pairs(lists) do
  local f=farmOf(p)
  if f and (f.base.Position-camera).Magnitude<=C.ViewDistance then
   local dragons=0;for _,pet in ipairs(pets) do if pet.species=="DragonHead" then dragons+=1 end end
   local di,bi=0,0
   for _,pet in ipairs(pets) do
    alive[pet.id]=true
    local m=models[pet.id];if not m then m=Model.Build(pet,folder);models[pet.id]=m;nameTag(m,pet) end
    local goal,swing
    if pet.species=="DragonHead" then di+=1;goal=dragonGoal(p,pet,di,dragons,f,m,dt)
    elseif pet.species=="BedBanker" then bi+=1;goal=bedGoal(p,pet,bi,#pets,f,m)
    elseif pet.species=="FacepalmCat" then goal,swing=catGoal(p,pet,f,m,dt)
    else goal=at(f,0,1,0) end
    local current=m:GetPivot()
    local next=(current.Position-goal.Position).Magnitude>40 and goal or current:Lerp(goal,1-math.exp(-(pet.species=="FacepalmCat" and 14 or 6)*dt))
    m:PivotTo(next)
    if pet.species=="FacepalmCat" then swings[m]=swings[m] or {};swingTail(m,swings[m],swing or 0) end
   end
  end
 end
 for id,m in pairs(models) do if not alive[id] then swings[m]=nil;tagged[m]=nil;m:Destroy();models[id]=nil;fx[id]=nil;states[id]=nil end end
end)
