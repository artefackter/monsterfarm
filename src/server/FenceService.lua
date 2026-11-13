-- The farm gate and the fence upgrades (owner, 2026-11-13: "a better fence, so fewer mutants get in at night; let
-- them break the player's gate before they climb in"). Rules and numbers: FenceConfig.
-- Every farm has a two-leaf gate under its arch. By day it stands open; at night it is shut against raiders (it still
-- swings open for anyone walking up, unless raiders are hammering it). MutantService sends each raider to the gate
-- first: it hammers until the gate breaks (F.Hit), then goes in. The leaves are only pictures - nothing here is
-- solid - so players are never stuck; the client (FarmGateVisuals) swings them by the gate's State attribute.
local RS=game.ReplicatedStorage;local S=RS.Shared
local C=require(S.Config.FenceConfig)
local D=require(script.Parent.DataService);local P=require(script.Parent.PlotService)
local CS=game:GetService("CollectionService")
local F={}
local LAWN=-.5
local HALF_OPENING=7
local wasNight
local function notice(p,key,args) if p and p.Parent then RS.Remotes.Notice:FireClient(p,key,args) end end
local function night() return (require(script.Parent.DayNightService).State()) end
local function part(parent,name,size,cf,color,material,shape)
 local q=Instance.new("Part");q.Name=name;q.Size=size;q.CFrame=cf;q.Color=color;q.Material=material or Enum.Material.SmoothPlastic
 q.Anchored=true;q.CanCollide=false;q.CanQuery=false;q.CanTouch=false;q.TopSurface=Enum.SurfaceType.Smooth;q.BottomSurface=Enum.SurfaceType.Smooth
 if shape then q.Shape=shape end;q.Parent=parent;return q
end
local WOOD,WOOD_DARK,IRON,RUST,BONE,GLOW=Color3.fromHex("6B4E3A"),Color3.fromHex("3E2C21"),Color3.fromHex("3A3A44"),Color3.fromHex("7A3A26"),Color3.fromHex("E6DCC4"),Color3.fromHex("8CFF6A")

-- One leaf, built shut: it runs from its hinge (x = side * 7) to the middle of the opening. Its PrimaryPart is the
-- hinge, so the client turns the whole leaf about it.
local function buildLeaf(g,plot,side,look)
 local m=Instance.new("Model");m.Name=side<0 and "LeafL" or "LeafR";m:SetAttribute("Side",side)
 local hinge=part(m,"Hinge",Vector3.one*.2,plot.Base*CFrame.new(side*HALF_OPENING,LAWN,-plot.FenceF),WOOD);hinge.Transparency=1
 m.PrimaryPart=hinge
 local w,h=HALF_OPENING-.1,5
 local function at(x,y,z) return hinge.CFrame*CFrame.new(-side*x,y,z or 0) end -- x runs from the hinge to the middle
 local metal=look=="Iron" or look=="Spiked" or look=="Bone"
 if not metal then
  -- planks with two cross bars and a brace
  for k=0,4 do part(m,"Plank",Vector3.new(w/5-.08,h-(k%2)*.3,.35),at((k+.5)*w/5,.2+(h-(k%2)*.3)/2),k%2==0 and WOOD or WOOD:Lerp(WOOD_DARK,.3),Enum.Material.WoodPlanks) end
  for _,y in {1.1,h-.9} do part(m,"CrossBar",Vector3.new(w-.2,.45,.25),at(w/2,y,-.28),WOOD_DARK,Enum.Material.Wood) end
  local brace=part(m,"Brace",Vector3.new(.4,math.sqrt((w-.6)^2+(h-2.4)^2),.22),at(w/2,h/2,-.3),WOOD_DARK,Enum.Material.Wood)
  brace.CFrame=brace.CFrame*CFrame.Angles(0,0,side*math.atan2(w-.6,h-2.4))
  if look=="Planks" then
   for _,y in {1.1,h-.9} do part(m,"IronBand",Vector3.new(w,.3,.42),at(w/2,y,0),IRON,Enum.Material.Metal) end
   for k=0,3 do part(m,"Stud",Vector3.new(.25,.25,.48),at(.6+k*(w-1.2)/3,h/2,0),Color3.fromHex("8C8C96"),Enum.Material.Metal) end
  end
 else
  local bar=look=="Bone" and BONE or IRON
  local n=math.floor(w/.85)
  for k=0,n do part(m,"Bar",Vector3.new(.26,h,.26),at(.2+k*(w-.4)/n,.2+h/2),bar,look=="Bone" and Enum.Material.SmoothPlastic or Enum.Material.Metal) end
  for _,y in {.8,h/2+.2,h-.2} do part(m,"Rail",Vector3.new(w,.32,.36),at(w/2,y),look=="Bone" and BONE:Lerp(WOOD,.25) or IRON,Enum.Material.Metal) end
  if look~="Iron" then
   for k=0,n,2 do
    local tip=part(m,"Spike",Vector3.new(.32,.32,.32),at(.2+k*(w-.4)/n,h+.45)*CFrame.Angles(0,math.pi/4,math.pi/4),look=="Bone" and GLOW or RUST,Enum.Material.Metal)
    if look=="Bone" then CS:AddTag(tip,"NightGlow") end
   end
  end
  if look=="Bone" then
   local skull=part(m,"Skull",Vector3.new(1.4,1.3,1.1),at(w-.9,h/2+.5,-.2),BONE,nil,Enum.PartType.Ball)
   for _,ex in {-.3,.3} do part(m,"Eye",Vector3.new(.3,.3,.3),skull.CFrame*CFrame.new(ex,.1,-.5),GLOW,Enum.Material.Neon,Enum.PartType.Ball) end
  end
 end
 m.Parent=g;return m
end

-- What the fence wears at each level, along the lines PlotService laid (plot.FenceLines)
local function buildOverlay(plot,look)
 if plot.FenceOverlay then plot.FenceOverlay:Destroy();plot.FenceOverlay=nil end
 if look=="Wood" then return end
 local m=Instance.new("Model");m.Name="FenceUpgrade"
 for _,line in plot.FenceLines or {} do
  local a,b=line[1],line[2];local v=b-a;local length=v.Magnitude;local dir=v.Unit
  local function at(t,y) local q=a+dir*t;return plot.Base*CFrame.lookAt(Vector3.new(q.X,LAWN+y,q.Z),Vector3.new(q.X+dir.X,LAWN+y,q.Z+dir.Z)) end
  if look=="Planks" then
   -- a second, heavier rail and squat posts
   for _,y in {1,2.3} do part(m,"Plank",Vector3.new(.3,.5,length),at(length/2,y)*CFrame.new(-.35,0,0),WOOD_DARK,Enum.Material.WoodPlanks) end
   for t=0,length,8 do part(m,"Post",Vector3.new(.8,3.6,.8),at(t,1.8),WOOD_DARK,Enum.Material.Wood) end
  else
   local bar=look=="Bone" and BONE or IRON;local step=1.6
   part(m,"TopRail",Vector3.new(.3,.3,length),at(length/2,4.1),bar,Enum.Material.Metal)
   for t=step/2,length,step do
    part(m,"Bar",Vector3.new(.2,4.2,.2),at(t,2.1),bar,Enum.Material.Metal)
    if look~="Iron" then
     local tip=part(m,"Spike",Vector3.new(.28,.28,.28),at(t,4.45)*CFrame.Angles(math.pi/4,0,math.pi/4),look=="Bone" and GLOW or RUST,Enum.Material.Metal)
     if look=="Bone" then CS:AddTag(tip,"NightGlow") end
    end
   end
   if look=="Bone" then
    for t=8,length-4,16 do
     local skull=part(m,"Skull",Vector3.new(1.2,1.1,1),at(t,4.9),BONE,nil,Enum.PartType.Ball)
     part(m,"Eye",Vector3.new(.25,.25,.25),skull.CFrame*CFrame.new(0,.1,-.45),GLOW,Enum.Material.Neon,Enum.PartType.Ball)
    end
   end
  end
 end
 m.Parent=plot.Model;plot.FenceOverlay=m
end

local function push(plot)
 local g=plot.GateModel;if not g then return end
 g:SetAttribute("Hp",math.floor(plot.GateHp+.5));g:SetAttribute("MaxHp",plot.GateMax);g:SetAttribute("Level",plot.FenceLevel or 1)
 g:SetAttribute("Broken",plot.GateBroken==true)
end

function F.SetLevel(plot,level)
 level=math.clamp(level or 1,1,#C.Levels)
 if plot.FenceLevel==level and plot.GateModel then return end
 plot.FenceLevel=level;local look=C.Levels[level].Look
 if plot.GateModel then plot.GateModel:Destroy() end
 local g=Instance.new("Model");g.Name="FarmGate";g:SetAttribute("State","open");g:SetAttribute("Look",look)
 buildLeaf(g,plot,-1,look);buildLeaf(g,plot,1,look)
 -- the spot raiders hammer and the owner mends, with the repair prompt and the health bar's anchor
 local center=part(g,"GateCenter",Vector3.new(1,1,1),plot.Base*CFrame.new(0,LAWN+3,-plot.FenceF),WOOD);center.Transparency=1
 local pr=Instance.new("ProximityPrompt");pr.Name="RepairGate";pr.ActionText="repairGate";pr.HoldDuration=C.RepairHold;pr.MaxActivationDistance=12;pr.RequiresLineOfSight=false
 pr:SetAttribute("Owner",plot.Owner and plot.Owner.UserId or -1);pr:SetAttribute("Needed",false);pr.Parent=center
 pr.Triggered:Connect(function(who) if who==plot.Owner then F.Repair(plot,true) end end)
 g.Parent=plot.Model;plot.GateModel=g;plot.GatePrompt=pr
 plot.GateMax=C.Levels[level].Hp;plot.GateHp=plot.GateMax;plot.GateBroken=false
 buildOverlay(plot,look);push(plot)
end
function F.Join(p,d)
 local plot=P.Assigned[p];if not plot then return end
 d.fenceLevel=C.Level(d)
 plot.FenceLevel=nil;F.SetLevel(plot,d.fenceLevel)
 if plot.GatePrompt then plot.GatePrompt:SetAttribute("Owner",p.UserId) end
end
function F.Reset(plot)
 if not plot then return end
 plot.FenceLevel=nil;F.SetLevel(plot,1)
 if plot.GatePrompt then plot.GatePrompt:SetAttribute("Owner",-1) end
end
-- The board by the gate (InterfaceService)
function F.Upgrade(p,d)
 local level=C.Level(d);if not C.Levels[level+1] then return false end
 d.fenceLevel=level+1
 local plot=P.Assigned[p];if plot then F.SetLevel(plot,d.fenceLevel) end
 return true
end

-- For MutantService ---------------------------------------------------------------------------------------------------
-- Raiders go straight in once the gate is down (or on a farm without one).
function F.Open(plot) return not plot.GateModel or plot.GateBroken==true end
-- Where raider `a` stands to hammer: spread along the outside of the gate.
function F.Front(plot,a)
 local k=(tonumber(a.id) or 0)%5-2
 return (plot.Base*CFrame.new(k*1.7,0,-(plot.FenceF+2.8))).Position
end
function F.Center(plot) return (plot.Base*CFrame.new(0,LAWN+2.5,-plot.FenceF)).Position end
function F.Spikes(plot) return C.Levels[plot.FenceLevel or 1].Spikes or 0 end
function F.Damage(kind) return C.Damage[kind] or C.Damage.Imp end
-- One blow on the gate. Returns true when it broke.
function F.Hit(plot,damage)
 if F.Open(plot) then return true end
 plot.GateHp=math.max(0,plot.GateHp-damage);plot.GateHitUntil=os.clock()+2.5
 plot.GateModel:SetAttribute("HitAt",workspace:GetServerTimeNow())
 if os.clock()-(plot.GateWarned or -100)>25 then plot.GateWarned=os.clock();notice(plot.Owner,"gateAttacked") end
 if plot.GateHp<=0 then F.Break(plot);return true end
 push(plot);return false
end
function F.Break(plot)
 plot.GateBroken=true;plot.GateHp=0;plot.GateRepairAt=os.clock()+C.Repair
 local fx=RS.Remotes:FindFirstChild("MutantFX");if fx then fx:FireAllClients("GateBreak","gate",F.Center(plot),plot.Owner and plot.Owner.UserId or 0) end
 notice(plot.Owner,"gateBroken",{n=C.Repair});push(plot)
end
function F.Repair(plot,byOwner)
 if not plot.GateModel or (not plot.GateBroken and plot.GateHp>=plot.GateMax) then return end
 plot.GateBroken=false;plot.GateHp=plot.GateMax;plot.GateRepairAt=nil;push(plot)
 if byOwner then notice(plot.Owner,"gateRepaired") end
end

function F.Tick()
 local isNight=night()
 local changed=isNight~=wasNight;wasNight=isNight
 for _,plot in P.Plots do
  local g=plot.GateModel
  if g then
   if changed or not isNight then F.Repair(plot,false) end -- a fresh gate every dusk; by day it is always whole
   if plot.GateBroken and os.clock()>=(plot.GateRepairAt or 0) then F.Repair(plot,false) end
   local state="open"
   if plot.GateBroken then state="broken"
   elseif isNight then
    state="closed"
    if os.clock()>=(plot.GateHitUntil or 0) then
     local center=F.Center(plot)
     for _,who in game.Players:GetPlayers() do
      local root=who.Character and who.Character:FindFirstChild("HumanoidRootPart")
      if root and (root.Position-center).Magnitude<=C.OpenDistance then state="open";break end
     end
    end
   end
   if g:GetAttribute("State")~=state then g:SetAttribute("State",state) end
   if plot.GatePrompt then plot.GatePrompt:SetAttribute("Needed",isNight and (plot.GateBroken or plot.GateHp<plot.GateMax)) end
  end
 end
end
function F.Init()
 for _,plot in P.Plots do F.SetLevel(plot,1) end
 task.spawn(function() while task.wait(.2) do local ok,err=pcall(F.Tick);if not ok then warn("FenceService",err) end end end)
end
return F
