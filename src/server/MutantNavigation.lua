-- Kinematic enemies still obey solid map geometry. Pathfinding chooses a route;
-- a swept sphere is the final authority on every movement step (including stale paths).
local Pathfinding=game:GetService('PathfindingService')
local RootHeight=require(game.ReplicatedStorage.Shared.Config.MutantConfig).RootHeight
local N={Parts={},Pending=0,Ready=false,Dirty=true,Rebuilds=0,Connections={}}
local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include
function N.Init()
 if N.Ready then return end;N.Ready=true
 local world=workspace:WaitForChild('DigAZombie')
 local function track(v)
  if not v:IsA('BasePart') or N.Parts[v] then return end
  N.Parts[v]=true;N.Dirty=true
  local function changed() N.Dirty=true end
  N.Connections[v]={v:GetPropertyChangedSignal('CanCollide'):Connect(changed),v:GetPropertyChangedSignal('CanQuery'):Connect(changed)}
 end
 for _,v in world:GetDescendants() do track(v) end
 world.DescendantAdded:Connect(track)
 world.DescendantRemoving:Connect(function(v)
  if not N.Parts[v] then return end
  N.Parts[v]=nil;N.Dirty=true
  for _,c in N.Connections[v] or {} do c:Disconnect() end;N.Connections[v]=nil
 end)
end
function N.Params()
 if N.Dirty then
  local include={};for p in N.Parts do if p.Parent and p.CanCollide and p.CanQuery then table.insert(include,p) end end
  params.FilterDescendantsInstances=include;N.Dirty=false;N.Rebuilds+=1
 end
 return params
end
function N.ClearSpawn(ground,radius)
 local hit=workspace:Raycast(ground+Vector3.new(0,4,0),Vector3.new(0,-10,0),N.Params())
 if not hit or hit.Normal.Y<.7 or math.abs(hit.Position.Y-ground.Y)>2 then return false end
 local probe=Instance.new('Part');probe.Name='MonsterSpawnProbe';probe.Anchored=true;probe.Transparency=1;probe.CanCollide=false;probe.CanTouch=false;probe.CanQuery=false
 probe.Size=Vector3.new(radius*2,math.max(6,radius*1.7),radius*2);probe.CFrame=CFrame.new(hit.Position+Vector3.new(0,probe.Size.Y*.5+.1,0));probe.Parent=workspace
 local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Include;overlap.FilterDescendantsInstances=N.Params().FilterDescendantsInstances;overlap.RespectCanCollide=true;overlap.MaxParts=1
 local clear=#workspace:GetPartsInPart(probe,overlap)==0;probe:Destroy();return clear
end
function N.Visible(a,b) return workspace:Raycast(a,b-a,N.Params())==nil end
function N.Move(agent,goal,speed,dt)
 local root=agent.model.PrimaryPart;if not root then return end
 local heightOffset=RootHeight*agent.model:GetScale()
 local pos=root.Position;goal=Vector3.new(goal.X,pos.Y,goal.Z)
 local delta=goal-pos;if delta.Magnitude<.1 then return end
 local radius=(agent.model:GetAttribute('NavigationRadius') or (agent.kind=='Chief' and 2 or 1.35))*agent.model:GetScale()
 local sphereLift=math.max(1.2,radius-heightOffset+.3)
 local params=N.Params()
 local support=workspace:Raycast(pos+Vector3.new(0,1,0),Vector3.new(0,-heightOffset-4,0),params)
 if support and support.Normal.Y>.6 then
  local y=support.Position.Y+heightOffset
  if math.abs(y-pos.Y)<=1.5 then pos=Vector3.new(pos.X,y,pos.Z);root.CFrame=CFrame.new(pos)*root.CFrame.Rotation;goal=Vector3.new(goal.X,y,goal.Z);delta=goal-pos end
 end
 local obstructed=workspace:Spherecast(pos+Vector3.new(0,sphereLift,0),radius,delta,params)
 -- A low wall (the farm fence is 3 studs) slips under the body sphere, yet the feet can't climb it:
 -- without this the night cultists walked straight at the fence and stood there (owner, 2026-11-12).
 -- A knee-high ray along the whole way (capped) keeps the detour until the wall is really behind it.
 if not obstructed then
  local feet=pos-Vector3.new(0,heightOffset,0)
  obstructed=workspace:Raycast(feet+Vector3.new(0,1.6,0),delta.Unit*math.min(delta.Magnitude,40),params)
 end
 if obstructed then
  local now=os.clock()
  if not agent.pathBusy and now>=(agent.pathAt or 0) and N.Pending<3 then
   agent.pathAt=now+1.2;agent.pathBusy=true;N.Pending+=1
   task.spawn(function()
    local path=Pathfinding:CreatePath({AgentRadius=radius+1.4,AgentHeight=(agent.model:GetAttribute("MonsterHeight") or 12)*agent.model:GetScale(),AgentCanJump=false,WaypointSpacing=3})
    local ok=pcall(function() path:ComputeAsync(pos,goal) end)
    if ok and path.Status==Enum.PathStatus.Success then agent.path=path:GetWaypoints();agent.pathIndex=2 else agent.path=nil end
    agent.pathBusy=false;N.Pending-=1
   end)
  end
  local points=agent.path;local index=agent.pathIndex or 2
  while points and points[index] and (Vector3.new(points[index].Position.X,pos.Y,points[index].Position.Z)-pos).Magnitude<.6 do index+=1 end
  agent.pathIndex=index
  if points and points[index] then delta=Vector3.new(points[index].Position.X,pos.Y,points[index].Position.Z)-pos else return end
 else agent.path=nil end
 if delta.Magnitude<.05 then return end
 local step=delta.Unit*math.min(delta.Magnitude,speed*math.min(dt,.15))
 local hit=workspace:Spherecast(pos+Vector3.new(0,sphereLift,0),radius,step,params)
 if hit then
  step=step.Unit*math.max(0,hit.Distance-.12)
 end
 -- No stepping off the island or the road.
 local nextPos=pos+step
 local floor=workspace:Raycast(nextPos+Vector3.new(0,1,0),Vector3.new(0,-heightOffset-4,0),params)
 if not floor or floor.Normal.Y<.6 then agent.model:SetAttribute('NavigationStatus','NoFloor');return end
 -- Follow the physical floor height; raised farm beds must not trap a ground-level sphere.
 local height=floor.Position.Y+heightOffset
 if height-pos.Y>1.5 then agent.model:SetAttribute('NavigationStatus','StepTooHigh');return end
 nextPos=Vector3.new(nextPos.X,height,nextPos.Z)
 agent.model:SetAttribute('NavigationStatus','Moving')
 if step.Magnitude>.01 then root.CFrame=CFrame.lookAt(nextPos,nextPos+delta.Unit) end
end
return N
