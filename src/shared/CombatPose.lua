-- Arm poses layered on top of the Animate clips: weapon hold and aim, recoil, reload, digging, the shovel swing, knockout.
-- The previous layer is restored before Animator; joint poses compose in PreSimulation.
local Pose={}
local ShovelMotion=require(script.Parent.ShovelMotion)
local function smooth(t) t=math.clamp(t,0,1);return t*t*(3-2*t) end
function Pose.New(character)
 local self={character=character,joints={},original={},weight=0,recoil=0,phase=0,speed=0,moveWeight=0}
 for _,j in character:GetDescendants() do
  if (j:IsA('Motor6D') or j:IsA('AnimationConstraint')) and j.Part0 and j.Part1 then self.joints[j.Name:gsub(' ','')]=j end
 end
 return setmetatable(self,{__index=Pose})
end
function Pose:Restore()
 for j,t in self.original do if j.Parent then j.Transform=t end end;table.clear(self.original)
end
-- Analytic arm chains also work with the new AnimationConstraint avatars.
-- Solve after the Animator/body turn, without editing rig attachments or joint C0.
function Pose:JointFrame(j,parentFrame)
 return parentFrame*j.C0*j.Transform*j.C1:Inverse()
end
function Pose:SetJoint(j,parentFrame,childFrame)
 if not self.original[j] then self.original[j]=j.Transform end
 j.Transform=j.C0:Inverse()*parentFrame:ToObjectSpace(childFrame)*j.C1
end
function Pose:ShovelArms(motion)
 local root=self.character:FindFirstChild('HumanoidRootPart')
 local rj=self.joints.Root or self.joints.RootJoint
 if not root or not rj then return end
 local lower=self:JointFrame(rj,root.CFrame)
 local torso=self.joints.Waist and self:JointFrame(self.joints.Waist,lower) or lower
 local turn=root.CFrame*CFrame.Angles(0,motion.spin,0)
 local tool=turn*motion.frame
 local function arm(side,point)
  local shoulder,elbow,wrist=self.joints[side..'Shoulder'],self.joints[side..'Elbow'],self.joints[side..'Wrist']
  if not shoulder or not elbow or not wrist then return end
  local hand=CFrame.new(point)*turn.Rotation*CFrame.Angles(math.pi/2,0,side=='Right' and -.2 or .2)
  local from=(torso*shoulder.C0).Position
  local to=(hand*wrist.C1).Position
  local a=(shoulder.C1.Position-elbow.C0.Position).Magnitude
  local b=(elbow.C1.Position-wrist.C0.Position).Magnitude
  local delta=to-from;local distance=math.clamp(delta.Magnitude,.01,a+b-.005)
  local forward=delta.Magnitude>.001 and delta.Unit or turn.LookVector
  local pole=turn:PointToWorldSpace(Vector3.new(side=='Right' and 2.5 or -2.5,.2,-2))-from
  local bend=pole-forward*pole:Dot(forward)
  if bend.Magnitude<.001 then bend=turn.UpVector end;bend=bend.Unit
  local along=math.clamp((a*a-b*b+distance*distance)/(2*distance),-a,a)
  local hinge=from+forward*along+bend*math.sqrt(math.max(0,a*a-along*along))
  -- Clamp unreachable targets rather than stretching the arm through the torso.
  local endPoint=from+forward*distance
  hand+=endPoint-to
  local normal=forward:Cross(bend).Unit
  local upper=CFrame.lookAt(from,hinge,normal)*CFrame.lookAt(shoulder.C1.Position,elbow.C0.Position,Vector3.zAxis):Inverse()
  local forearm=CFrame.lookAt(hinge,endPoint,normal)*CFrame.lookAt(elbow.C1.Position,wrist.C0.Position,Vector3.zAxis):Inverse()
  self:SetJoint(shoulder,torso,upper);self:SetJoint(elbow,upper,forearm);self:SetJoint(wrist,forearm,hand)
 end
 arm('Right',tool.Position)
 if motion.left>0 then
  local rest=turn:PointToWorldSpace(Vector3.new(-1.2,-.2,-1.1))
  local point=turn:PointToObjectSpace(rest:Lerp(tool:PointToWorldSpace(Vector3.new(0,1,0)),motion.left))
  if motion.left<.99 then point=Vector3.new(math.min(point.X,-.35+.45*motion.left),point.Y,math.min(point.Z,-1.35)) end
  arm('Left',turn:PointToWorldSpace(point))
 end
end
-- One arm, solved exactly: shoulder, elbow and wrist put the hand at `hand` (a world CFrame); a target out of
-- reach is pulled in along the same line instead of stretching the arm. Returns where the hand really ended up.
function Pose:SolveArm(side,torso,hand,pole,onlyWithin)
 local shoulder,elbow,wrist=self.joints[side..'Shoulder'],self.joints[side..'Elbow'],self.joints[side..'Wrist']
 if not shoulder or not elbow or not wrist then return nil end
 local from=(torso*shoulder.C0).Position
 local to=(hand*wrist.C1).Position
 local a=(shoulder.C1.Position-elbow.C0.Position).Magnitude
 local b=(elbow.C1.Position-wrist.C0.Position).Magnitude
 local delta=to-from
 if onlyWithin and delta.Magnitude>(a+b)*onlyWithin then return nil end -- too far to pretend: leave this arm to its clip
 local distance=math.clamp(delta.Magnitude,math.abs(a-b)+.02,a+b-.005)
 local forward=delta.Magnitude>.001 and delta.Unit or hand.LookVector
 local bend=pole-forward*pole:Dot(forward)
 if bend.Magnitude<.001 then bend=hand.UpVector end;bend=bend.Unit
 local along=math.clamp((a*a-b*b+distance*distance)/(2*distance),-a,a)
 local hinge=from+forward*along+bend*math.sqrt(math.max(0,a*a-along*along))
 local endPoint=from+forward*distance
 hand+=endPoint-to
 local normal=forward:Cross(bend).Unit
 local upper=CFrame.lookAt(from,hinge,normal)*CFrame.lookAt(shoulder.C1.Position,elbow.C0.Position,Vector3.zAxis):Inverse()
 local forearm=CFrame.lookAt(hinge,endPoint,normal)*CFrame.lookAt(elbow.C1.Position,wrist.C0.Position,Vector3.zAxis):Inverse()
 self:SetJoint(shoulder,torso,upper);self:SetJoint(elbow,upper,forearm);self:SetJoint(wrist,forearm,hand)
 return hand
end
-- Holding a gun (self.held is set by CombatController: the model, its weld to the hand, how far it reaches behind
-- the grip and above it). The stance crouches and leans the body forward, so the grip is measured from the posed
-- chest and head, not from the root: ahead of the chest by the gun's own rear length and below the head, so the gun
-- never sinks into the body. Long guns sit at the right shoulder, beside the head, stock tucked in. The other hand
-- goes to the fore-end, or to the magazine while reloading.
function Pose:GunArms(aiming,tilt,reload)
 local ch=self.character;local held=self.held
 local root=ch:FindFirstChild('HumanoidRootPart');local rj=self.joints.Root or self.joints.RootJoint
 local chestPart=ch:FindFirstChild('UpperTorso');local headPart=ch:FindFirstChild('Head');local main=held.model.PrimaryPart
 if not root or not rj or not chestPart or not headPart or not main or not self.joints.Neck or not held.grip.Parent then return false end
 local lower=self:JointFrame(rj,root.CFrame)
 local torso=self.joints.Waist and self:JointFrame(self.joints.Waist,lower) or lower
 local head=self:JointFrame(self.joints.Neck,torso)
 local turn=root.CFrame.Rotation*CFrame.Angles(0,self.yaw or 0,0) -- the hands swing round with the twisted torso
 local f,r=turn.LookVector,turn.RightVector;local long=held.rear>.9
 local chest=(torso*CFrame.new(0,chestPart.Size.Y*.25,-chestPart.Size.Z/2)).Position-root.Position
 local ahead=chest:Dot(f)+(long and .3 or held.rear+.5)+(aiming and .2 or 0)-self.recoil*(long and .05 or .12)-tilt*.15
 local height=math.min(torso.Position.Y+(aiming and (long and .35 or .45) or (long and 0 or .15)),long and math.huge or head.Position.Y-headPart.Size.Y/2-held.top-.05)-tilt*.18
 local side=long and chestPart.Size.X/2+.2 or .45 -- a long gun rides beside the ribs, stock under the arm
 local grip=CFrame.new(Vector3.new(root.Position.X,height,root.Position.Z)+f*ahead+r*side)*turn
 local hand=self:SolveArm('Right',torso,grip,turn:VectorToWorldSpace(Vector3.new(1,-1.6,.3)))
 if not hand then return false end
 local mainFrame=hand*held.grip.C0
 local support=main:FindFirstChild('SupportHand');local magazine=held.model:FindFirstChild('Magazine')
 local point
 if reload and reload>.1 and reload<.83 and magazine then point=(mainFrame*main.CFrame:ToObjectSpace(magazine.CFrame)).Position
 elseif support then point=(mainFrame*support.CFrame).Position end
 self.gunLeft=point~=nil and self:SolveArm('Left',torso,CFrame.new(point)*turn*CFrame.Angles(0,0,-.35),turn:VectorToWorldSpace(Vector3.new(-1,-1.6,.3)),1.08)~=nil
 return true
end
function Pose:Kick(amount) self.recoil=math.min(self.recoil+amount,1.5) end
function Pose:Apply(name,rotation,weight,additive)
 if self.character:GetAttribute('WeaponIKActive') and (name=='RightShoulder' or name=='RightElbow' or name=='RightWrist') then return end
 if self.character:GetAttribute('SupportIKActive') and (name=='LeftShoulder' or name=='LeftElbow' or name=='LeftWrist') then return end
 local j=self.joints[name];if not j or not j.Parent or weight<=0 then return end
 local original=j.Transform;if not self.original[j] then self.original[j]=original end
 local basis=j.C0.Rotation;local offset=basis:Inverse()*rotation*basis
 j.Transform=additive and original*CFrame.identity:Lerp(offset,weight) or original:Lerp(offset,weight)
end
function Pose:Step(dt,aim,id,reloading,batLeft,training,drawWeight)
 dt=math.min(dt,.1)
 local ch=self.character;local root=ch:FindFirstChild('HumanoidRootPart');local h=ch:FindFirstChildOfClass('Humanoid')
 if not root or not h then self:Restore();return end
 local player=game.Players:GetPlayerFromCharacter(ch);local now=workspace:GetServerTimeNow()
 local function attr(key) return player and player:GetAttribute(key) end
 local digging=attr('DiggingGrave');local koUntil=attr('KnockedOutUntil') or 0;local knocked=now<koUntil
 local equipped=attr('ActiveSlot')==2 and not attr('WeaponHolstered') and not training
 local velocity=root.CFrame:VectorToObjectSpace(root.AssemblyLinearVelocity)
 local speed=Vector3.new(velocity.X,0,velocity.Z).Magnitude
 self.speed+=(speed-self.speed)*(1-math.exp(-dt*12))
 local grounded=h.FloorMaterial~=Enum.Material.Air and not h.Sit and h.Health>0
 local shovel=attr('ActiveSlot')==1 and not training
 local active=(shovel or equipped or aim or reloading or digging or knocked or (batLeft or 0)>0)
 local target=active and h.Health>0 and 1 or 0
 self.weight+=(target-self.weight)*(1-math.exp(-dt*(target==1 and 14 or 10)));self.recoil*=math.exp(-dt*(id=='AWP' and 11 or 18))
 local w=self.weight
 if knocked then
  local left=koUntil-now;local fall=smooth((now-(attr('KnockedOutAt') or now))/.18);local rise=smooth(left/.28)
  local rootJoint=self.joints.Root and 'Root' or 'RootJoint'
  self:Apply(rootJoint,CFrame.new(0,-.7*fall*rise,0)*CFrame.Angles(-1.05*fall*rise,0,.16*fall*rise),1,true)
  self:Apply('RightShoulder',CFrame.Angles(-.45,0,-.8),1);self:Apply('LeftShoulder',CFrame.Angles(-.45,0,.8),1)
  self:Apply('RightHip',CFrame.Angles(.35,0,-.2),1);self:Apply('LeftHip',CFrame.Angles(-.2,0,.2),1)
  self:Apply('RightKnee',CFrame.Angles(.65,0,0),1);self:Apply('LeftKnee',CFrame.Angles(.35,0,0),1);return
 end
 -- Legs, hips and the idle arms belong to the Animate clips; this only layers the arms for actions.
 if not active and w<.01 then return end
 local motion=player and ShovelMotion.ForPlayer(player,now)
 if motion then
  if motion.kind=='swing' then
   -- Rotate the rendered rig, not the physical root or camera. Keep jump/run
   -- torso offsets out of the two-hand action; leg clips continue normally.
   local rootJoint=self.joints.Root and 'Root' or 'RootJoint'
   self:Apply(rootJoint,CFrame.Angles(0,motion.spin,0),1)
   self:Apply('Waist',CFrame.identity,1)
  elseif motion.kind=='dig' then
   self:Apply(self.joints.Root and 'Root' or 'RootJoint',CFrame.identity,1)
   self:Apply('Waist',CFrame.Angles(-motion.lean,0,0),1)
  end
  -- R6 fallback; R15 hands use elbow poles and the shared shovel targets.
  self:Apply('RightShoulder',CFrame.Angles(.55,-.1,-.25),w)
  self:Apply('LeftShoulder',CFrame.Angles(.65,.1,.3),w*motion.left)
  self:Apply('RightElbow',CFrame.Angles(-.7,0,0),w)
  self:Apply('LeftElbow',CFrame.Angles(-.8,0,0),w*motion.left)
  self:ShovelArms(motion)
  return
 end
 local yaw,pitch=0,0
 if aim then local v=root.CFrame:VectorToObjectSpace(aim-root.Position);local limit=require(script.Parent.Config.WeaponConfig).UpperBodyYaw;yaw=math.clamp(math.atan2(-v.X,-v.Z),-limit,limit);pitch=math.clamp(math.atan2(v.Y,Vector3.new(v.X,0,v.Z).Magnitude),-.45,.45) end
 self.yaw=(self.yaw or 0)+(yaw-(self.yaw or 0))*(1-math.exp(-dt*14))
 local reloadUntil=attr('WeaponReloadUntil') or 0
 local reload=reloading and math.clamp(1-(reloadUntil-now)/require(script.Parent.Config.WeaponConfig)[id].Reload,0,1) or nil
 local tilt=reload and math.sin(reload*math.pi) or 0
 local ready=aim and 1 or 0;local twoHand=id~='Deagle'
 local lift=(aim and 1.43 or .82)+pitch+self.recoil*.14-tilt*.35
 self:Apply('RightShoulder',CFrame.Angles(lift,self.yaw*.45,-.12-tilt*.25),w)
 self:Apply('LeftShoulder',CFrame.Angles(lift+(twoHand and .1 or -.12)-tilt*.7,self.yaw*.45,(twoHand and .32 or .5)+tilt*.15),w)
 self:Apply('RightElbow',CFrame.Angles(-.2-tilt*.3,0,0),w)
 self:Apply('LeftElbow',CFrame.Angles(-.55-tilt*.6,0,0),w)
 self:Apply('RightWrist',CFrame.Angles(-.12,tilt*.25,0),w);self:Apply('LeftWrist',CFrame.Angles(.05,0,-.2),w)
 self:Apply('Waist',CFrame.Angles(-.06+self.recoil*.04,self.yaw*.55,0),w,true);self:Apply('Neck',CFrame.Angles(pitch*.35,self.yaw*.35,0),w,true)
 local held=self.held
 if held and equipped and not held.onBack and held.model.Parent and w>.5 and (batLeft or 0)<=0 then
  self.gunArms=self:GunArms(aim~=nil,tilt,reload)
 else self.gunArms=false end
 if (drawWeight or 0)>0 and not self.gunArms then self:Apply('RightShoulder',CFrame.Angles(-.6,0,-.55),math.sin(drawWeight*math.pi)*.8) end
 ch:SetAttribute('LocomotionPose',aim and 'AimStrafe' or equipped and 'WeaponRun' or 'Run')
end
return Pose
