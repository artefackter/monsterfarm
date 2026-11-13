-- Farm gates (FenceService, owner 2026-11-13: raiders break the gate before they climb in). The server builds the
-- leaves shut and says what the gate is doing in its State attribute: "open" (by day, or someone walking up),
-- "closed" (night) or "broken" (knocked flat until it is mended). The leaves swing here, smoothly, about their hinges;
-- every blow shakes them, and a bar over the gate shows how much it has left.
local Players=game:GetService("Players");local Run=game:GetService("RunService");local RS=game:GetService("ReplicatedStorage")
local L=require(RS:WaitForChild("Shared"):WaitForChild("Locale"));local Pal=require(RS.Shared.Palette)
local me=Players.LocalPlayer
local gates={}
local function t(k,a) return L.text(k,L.lang(),a) end

local function bar(g,center)
 local b=Instance.new("BillboardGui");b.Name="GateHealth";b.Adornee=center;b.Size=UDim2.fromOffset(170,34);b.StudsOffsetWorldSpace=Vector3.new(0,5.2,0)
 b.MaxDistance=110;b.LightInfluence=0;b.ResetOnSpawn=false;b.Enabled=false;b.Parent=me:WaitForChild("PlayerGui")
 local back=Instance.new("Frame");back.Size=UDim2.new(1,0,0,16);back.Position=UDim2.fromOffset(0,18);back.BackgroundColor3=Color3.fromRGB(30,20,30);back.BorderSizePixel=0;back.Parent=b
 Instance.new("UICorner",back).CornerRadius=UDim.new(1,0);local st=Instance.new("UIStroke",back);st.Color=Color3.fromRGB(15,10,20);st.Thickness=2
 local fill=Instance.new("Frame");fill.Size=UDim2.fromScale(1,1);fill.BackgroundColor3=Color3.fromRGB(230,170,70);fill.BorderSizePixel=0;fill.Parent=back
 Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
 local label=Instance.new("TextLabel");label.BackgroundTransparency=1;label.Size=UDim2.new(1,0,0,18);label.Font=Enum.Font.GothamBlack;label.TextScaled=true
 label.TextColor3=Color3.new(1,1,1);label.TextStrokeTransparency=0;label.TextStrokeColor3=Color3.fromRGB(30,15,20);label.AutoLocalize=false;label.Parent=b
 return {gui=b,fill=fill,label=label}
end

local function add(g)
 if not g:IsA("Model") or g.Name~="FarmGate" or gates[g] then return end
 local center=g:WaitForChild("GateCenter",5);if not center then return end
 local leaves={}
 for _,name in {"LeafL","LeafR"} do
  local leaf=g:WaitForChild(name,5)
  if leaf and leaf.PrimaryPart then
   local side=leaf:GetAttribute("Side") or 1;local shut=leaf.PrimaryPart.CFrame
   table.insert(leaves,{model=leaf,side=side,shut=shut,now=shut*CFrame.Angles(0,side*math.pi/2,0)})
  end
 end
 local entry={model=g,leaves=leaves,bar=bar(g,center),hitAt=g:GetAttribute("HitAt") or 0,shake=0}
 gates[g]=entry
 g:GetAttributeChangedSignal("HitAt"):Connect(function() entry.shake=.18 end)
 g.Destroying:Connect(function() gates[g]=nil;entry.bar.gui:Destroy() end)
end
workspace.DescendantAdded:Connect(function(x) if x.Name=="FarmGate" then task.spawn(add,x) end end)
for _,x in workspace:GetDescendants() do if x.Name=="FarmGate" then task.spawn(add,x) end end

Run.RenderStepped:Connect(function(dt)
 local cam=workspace.CurrentCamera.CFrame.Position
 for g,e in gates do
  if not g.Parent then continue end
  local state=g:GetAttribute("State") or "open"
  local hp,max=g:GetAttribute("Hp") or 1,g:GetAttribute("MaxHp") or 1
  -- the bar: only while it is hurt or down
  local hurt=state=="broken" or hp<max
  e.bar.gui.Enabled=hurt
  if hurt then
   e.bar.fill.Size=UDim2.fromScale(math.clamp(hp/max,0,1),1)
   e.bar.fill.BackgroundColor3=hp/max>.5 and Color3.fromRGB(230,170,70) or Color3.fromRGB(230,70,60)
   e.bar.label.Text=state=="broken" and t("gateBrokenTag") or t("gateHp",{n=hp,max=max})
  end
  local near=(e.leaves[1] and (e.leaves[1].shut.Position-cam).Magnitude or 0)<220
  if not near then continue end
  e.shake=math.max(0,e.shake-dt)
  local k=1-math.exp(-dt*(state=="broken" and 9 or 5))
  for _,leaf in e.leaves do
   local goal
   if state=="broken" then goal=leaf.shut*CFrame.Angles(0,leaf.side*.25,0)*CFrame.new(0,.25,0)*CFrame.Angles(-math.pi/2+.08,0,0)
   elseif state=="open" then goal=leaf.shut*CFrame.Angles(0,leaf.side*math.pi/2,0)
   else goal=leaf.shut end
   leaf.now=leaf.now:Lerp(goal,k)
   local jitter=e.shake>0 and state=="closed" and CFrame.Angles(0,leaf.side*math.sin(os.clock()*70)*.05,0) or CFrame.identity
   leaf.model:PivotTo(leaf.now*jitter)
  end
 end
end)

-- The ruins gate's shutters (RoadArt.BuildEntrance): the server leaves them open against the road's edges; while the
-- Blood Moon has the road shut (workspace.RoadClosed) they swing slowly across it.
local shutters={}
local function addShutter(m)
 if not m:IsA("Model") or m.Name~="RuinsShutter" or shutters[m] then return end
 local pivot=m.PrimaryPart or m:WaitForChild("Hinge",5);if not pivot then return end
 local side=m:GetAttribute("Side") or 1;local open=m:GetPivot()
 shutters[m]={open=open,shut=open*CFrame.Angles(0,side*math.pi/2,0),now=open,moving=false}
 m.Destroying:Connect(function() shutters[m]=nil end)
end
workspace.DescendantAdded:Connect(function(x) if x.Name=="RuinsShutter" then task.spawn(addShutter,x) end end)
for _,x in workspace:GetDescendants() do if x.Name=="RuinsShutter" then task.spawn(addShutter,x) end end
Run.Heartbeat:Connect(function(dt)
 local closed=workspace:GetAttribute("RoadClosed")==true
 for m,s in shutters do
  local goal=closed and s.shut or s.open
  if (s.now.LookVector-goal.LookVector).Magnitude>.002 then
   s.now=s.now:Lerp(goal,1-math.exp(-dt*1.6));m:PivotTo(s.now)
  end
 end
end)
