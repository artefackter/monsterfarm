local Players=game:GetService('Players');local Run=game:GetService('RunService')
local p=Players.LocalPlayer;local gui=p:WaitForChild('PlayerGui'):WaitForChild('DigUI')
local arrow=Instance.new('BillboardGui');arrow.Name='TutorialArrow';arrow.Size=UDim2.fromOffset(70,70);arrow.AlwaysOnTop=true;arrow.Parent=gui
local view=Instance.new('ViewportFrame',arrow);view.Size=UDim2.fromScale(1,1);view.BackgroundTransparency=1;view.Ambient=Color3.new(1,1,1);view.LightColor=Color3.new(1,1,1)
local wm=Instance.new('WorldModel',view)
local function arrowPart(size,pos,color)
 local q=Instance.new('Part',wm);q.Size=size;q.Position=pos;q.Anchored=true;q.Color=Color3.fromHex(color);return q
end
arrowPart(Vector3.new(.8,2,.35),Vector3.new(0,.7,0),'38264E');arrowPart(Vector3.new(.55,1.8,.42),Vector3.new(0,.75,-.04),'FFE257')
for _,sign in {-1,1} do local q=arrowPart(Vector3.new(.65,1.5,.35),Vector3.new(sign*.42,-.45,0),'38264E');q.Rotation=Vector3.new(0,0,sign*45);local inner=q:Clone();inner.Size=Vector3.new(.42,1.35,.42);inner.Position+=Vector3.new(0,0,-.05);inner.Color=Color3.fromHex('FFE257');inner.Parent=wm end
local camera=Instance.new('Camera',view);camera.CFrame=CFrame.lookAt(Vector3.new(0,0,-7),Vector3.zero);camera.FieldOfView=35;view.CurrentCamera=camera
local edge=Instance.new('TextLabel',gui);edge.Name='GuideEdge';edge.Size=UDim2.fromOffset(48,48);edge.AnchorPoint=Vector2.one*.5;edge.BackgroundTransparency=1;edge.Font=Enum.Font.GothamBlack;edge.Text='➜';edge.TextSize=38;edge.TextColor3=Color3.fromHex('FFE257');edge.TextStrokeTransparency=0;edge.TextStrokeColor3=Color3.fromHex('38264E');edge.Visible=false
local gateTarget=Instance.new('Part',workspace);gateTarget.Name='GuideDeliveryGate';gateTarget.Size=Vector3.one;gateTarget.Transparency=1;gateTarget.Anchored=true;gateTarget.CanQuery=false;gateTarget.CanTouch=false;gateTarget.CanCollide=false
local RoadC=require(game.ReplicatedStorage.Shared.Config.RoadConfig);gateTarget.Position=RoadC.Dir.Unit*(RoadC.Rim+RoadC.GateLine-3)+Vector3.new(0,2,0)
local floor=Instance.new('Folder');floor.Name='TutorialFloorArrows';floor.Parent=workspace
local gunsmithZone
local function destination()
 local world=workspace:FindFirstChild('DigAZombie');if not world then return end
 local plot;for _,m in world:GetChildren() do if m:GetAttribute('Owner')==p.UserId then plot=m;break end end
 if p:GetAttribute('GuideArrows')==false then return end
 -- The arrows belong to the tutorial: once it is done they never come back (owner, 2026-11-08).
 local step=gui:GetAttribute('TutorialStep')
 if type(step)~='number' or step>=9 then return end
 if p:GetAttribute('CarryingGrave') then return p:GetAttribute('OnRoad') and gateTarget or plot and plot:FindFirstChild('Gate') end
 if p:GetAttribute('SelectedGrave') and plot then return plot:FindFirstChild('GuideCemetery') or plot:FindFirstChild('GuideField') end
 if p:GetAttribute('HoldingZombie') and plot then return plot:FindFirstChild('GuideField') end
 local key=({[0]='grave',[1]='field',[2]='road',[3]='plant',[4]='gunsmith',[5]='workbench',[6]='Treadmill',[7]='Fence',[8]='House'})[step]
 if not key then
  return
 end
 -- the upgrade steps (2026-11-15, TutorialService): the workbench's circle, then the farm's upgrade boards
 if key=='workbench' then
  local bench=plot and plot:FindFirstChild('Workbench',true);return bench and bench:FindFirstChild('WorkbenchZone')
 end
 if key=='Treadmill' or key=='Fence' or key=='House' then
  local boards=plot and plot:FindFirstChild('UpgradeBoards');return boards and boards:FindFirstChild(key)
 end
 -- the gunsmith's stall on the plaza (InterfaceService's menu zone)
 if key=='gunsmith' then
  if gunsmithZone and gunsmithZone.Parent then return gunsmithZone end
  for _,q in workspace:GetDescendants() do if q:IsA('BasePart') and q:GetAttribute('MenuZone')=='weapons' then gunsmithZone=q;return q end end
  return
 end
 if key=='road' then
  -- the nearest open grave, not whichever the road happens to list first (that could be at the far end)
  local road=world:FindFirstChild('Road');local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart');local best,bestDist
  for _,m in road and road:GetChildren() or {} do
   -- never a sleeping boss's hoard grave (its StealTag): digging one wakes the boss
   local spot=m.Name=='RoadGrave' and not m:GetAttribute('BossLocked') and m:FindFirstChild('RoadGrabSpot')
   if spot and spot:FindFirstChild('StealTag') then spot=nil end
   if spot and root then local d=(spot.Position-root.Position).Magnitude;if not bestDist or d<bestDist then best,bestDist=spot,d end end
  end
  return best
 end
 if key=='plant' and plot then
  if p:GetAttribute('CarryingGrave') then return plot:FindFirstChild('Gate') end
  return plot:FindFirstChild('GuideCemetery') or plot:FindFirstChild('GuideField')
 end
 -- Step 2: the crypt first (take a zombie), then the yard (handled above while holding).
 if key=='field' and plot then local crypt=plot:FindFirstChild('Crypt');return crypt and crypt:FindFirstChild('CryptZone') end
 if not plot then return end
 if key=='grave' then
  for _,m in plot:GetChildren() do if m.Name=='Grave' then return m:FindFirstChild('Headstone') or m:FindFirstChildWhichIsA('BasePart') end end
 end
 local room=plot:FindFirstChild('HouseRoom')
 if key=='merge' then local room=plot and plot:FindFirstChild('HouseRoom');return room and room:FindFirstChild('MergeZone') end -- the table is in the player's house
 if key=='treadmill' then local belt=plot and plot:FindFirstChild('OutdoorTreadmill');return belt and belt:FindFirstChild('Treadmill') end
 return plot:FindFirstChild(key=='guard' and 'GuideGuard' or 'GuideField')
end
-- The guide: a straight trail of glowing chevrons on the ground from the player to the target, always running
-- toward it, plus the bouncing arrow over the target and an edge pointer when it is off screen.
local CHEVRONS,SPACING,SPEED=48,2.6,7
local chevrons={};local parts={};local frames={}
local function chevronPart(name,size,color,transparency)
 local q=Instance.new('Part');q.Name=name;q.Size=size;q.Color=color;q.Material=Enum.Material.Neon;q.Transparency=transparency
 q.Anchored,q.CanCollide,q.CanQuery,q.CanTouch,q.CastShadow=true,false,false,false,false;q.Parent=floor;return q
end
-- One chevron is a ">" of two bright bars over a wider warm glow, pointing along -Z of its frame.
local ARMS={}
for _,side in {-1,1} do
 local tip=Vector3.new(0,0,-.6);local tail=Vector3.new(side*.9,0,.35);local mid=(tip+tail)/2
 table.insert(ARMS,CFrame.lookAt(mid,mid+(tail-tip)))
end
for i=1,CHEVRONS do
 local set={}
 for _,arm in ARMS do
  table.insert(set,{part=chevronPart('GuideGlow',Vector3.new(.78,.06,1.6),Color3.fromRGB(255,214,92),.55),arm=arm*CFrame.new(0,-.02,0)})
  table.insert(set,{part=chevronPart('GuideChevron',Vector3.new(.42,.1,1.38),Color3.fromRGB(255,255,236),.05),arm=arm})
 end
 chevrons[i]=set;for _,e in set do table.insert(parts,e.part) end
end
local hidden=CFrame.new(0,-500,0)
local shown=true
local function clear() if not shown then return end;shown=false;for i in parts do frames[i]=hidden end;workspace:BulkMoveTo(parts,frames,Enum.BulkMoveMode.FireCFrameChanged) end
clear()
local rayParams=RaycastParams.new();rayParams.FilterType=Enum.RaycastFilterType.Exclude
local function rebuild()
 local dest=destination();arrow.Adornee=dest;arrow.Enabled=dest~=nil
end
Run.RenderStepped:Connect(function(dt)
 local dest=arrow.Adornee;local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart');local enabled=not gui:GetAttribute('ModalOpen') and p:GetAttribute('GuideArrows')~=false and dest and dest.Parent
 arrow.Enabled=enabled==true or typeof(enabled)=='Instance';edge.Visible=false
 if not enabled then clear();return end
 arrow.StudsOffset=Vector3.new(0,5.5+math.sin(os.clock()*2.5)*.4,0)
 local point,on=workspace.CurrentCamera:WorldToViewportPoint(dest.Position)
 if not on then
  local size=gui.AbsoluteSize;local center=size*.5;local v=Vector2.new(point.X,point.Y)-center;if point.Z<0 then v=-v end
  if v.Magnitude>.1 then local k=math.min((center.X-32)/math.max(math.abs(v.X),1),(center.Y-65)/math.max(math.abs(v.Y),1));edge.Position=UDim2.fromOffset(center.X+v.X*k,center.Y+v.Y*k);edge.Rotation=math.deg(math.atan2(v.Y,v.X));edge.Visible=true end
 end
 if not root then clear();return end
 local exclude={floor};for _,who in Players:GetPlayers() do if who.Character then table.insert(exclude,who.Character) end end;rayParams.FilterDescendantsInstances=exclude
 local from=root.Position-Vector3.new(0,2.6,0);local to=dest.Position
 local flat=Vector3.new(to.X-from.X,0,to.Z-from.Z);local length=flat.Magnitude-2.5
 if length<4 then clear();return end
 local dir=flat.Unit;local shift=(os.clock()*SPEED)%SPACING;local index=0
 for i=1,CHEVRONS do
  local along=1.6+(i-1)*SPACING+shift
  local frame=hidden
  if along<length then
   local pos=from+dir*along;local hit=workspace:Raycast(pos+Vector3.new(0,7,0),Vector3.new(0,-16,0),rayParams)
   if hit then
    -- Fade in at the feet and out at the target.
    local alpha=math.clamp((along-1.6)/2.5,0,1)*math.clamp((length-along)/3,0,1)
    local at=hit.Position+Vector3.new(0,.08,0)
    frame=CFrame.lookAt(at,at+dir)
    for _,e in chevrons[i] do e.part.LocalTransparencyModifier=1-alpha end
   end
  end
  for _,e in chevrons[i] do index+=1;frames[index]=frame==hidden and hidden or frame*e.arm end
 end
 shown=true;workspace:BulkMoveTo(parts,frames,Enum.BulkMoveMode.FireCFrameChanged)
end)
gui:GetAttributeChangedSignal('GuideTarget'):Connect(function() task.spawn(rebuild) end)
p.CharacterAdded:Connect(function() clear() end)
task.spawn(function() while task.wait(.5) do rebuild() end end)
