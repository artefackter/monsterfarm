-- Walk-in houses and outdoor treadmills; no teleport doors.
local S=game.ReplicatedStorage.Shared;local RS=game.ReplicatedStorage
local C=require(S.Config.HouseConfig);local R=require(S.HouseRules);local Art=require(S.ArtKit);local Pal=require(S.Palette);local L=require(S.Locale)
local D=require(script.Parent.DataService);local P=require(script.Parent.PlotService);local Raid=require(script.Parent.RaidService)
local WA=require(S.WorldArt)
local H={Rooms={},Timers={},Treadmills={}}
local function notice(p,key,args) RS.Remotes.Notice:FireClient(p,key,args) end
local function look(level) return C.Levels[level].Look end
-- Outside ------------------------------------------------------------------------------------------
-- A cottage from blocks, after the owner's reference: cream walls with wooden corners, blue windows in purple
-- frames, a purple gabled roof whose eaves flare out, a chimney, an open door with a lamp, bushes round it.
-- Levels add a porch, a second floor, a corner tower and finally gold trim and a flag.
local COL={wall=Color3.fromHex("FFF0D4"),trim=Color3.fromHex("EAD2AA"),wood=Color3.fromHex("A8754A"),floor=Color3.fromHex("E2B985"),
 roof=Color3.fromHex("8C4BFF"),roofDark=Color3.fromHex("6A2FD0"),frame=Color3.fromHex("7A3BE0"),glass=Color3.fromHex("8FE3FF"),
 stone=Color3.fromHex("CBC4E0"),bush=Color3.fromHex("5FCB4A"),gold=Color3.fromHex("FFD34D"),lamp=Color3.fromHex("FFE58D")}
local SMOOTH=Enum.Material.SmoothPlastic
function H.Cottage(plot,index)
 local L=C.Looks[index];local W,Dp,Hh,R=L.W,L.D,L.Wall,L.Roof
 local hb=plot.Base*CFrame.new(C.RoomX,C.FloorY or .7,C.RoomZ)*CFrame.Angles(0,math.rad(C.RoomYaw or 0),0)
 local m=Instance.new("Model");m.Name="House"
 local function part(name,size,cf,color,material,solid,shape)
  local q=P.Part(m,name,size,hb*cf,color,shape);q.Material=material or SMOOTH
  q.CanCollide=solid==true;q.CanQuery=solid==true;q.CanTouch=false;return q
 end
 local function roof(name,size,cf,color)
  local q=part(name,size,cf,color);q:SetAttribute("HouseRoof",true);q.CastShadow=true;return q
 end
 local top=.8+Hh;local dw,dh=6,8
 -- Plinth, floor, walls (the front one keeps a wide doorway)
 part("Plinth",Vector3.new(W+2,.8,Dp+2),CFrame.new(0,.4,0),COL.stone,Enum.Material.Slate,true)
 part("Floor",Vector3.new(W-1,.2,Dp-1),CFrame.new(0,.9,0),COL.floor,Enum.Material.WoodPlanks,true)
 part("WallBack",Vector3.new(W,Hh,1),CFrame.new(0,.8+Hh/2,Dp/2-.5),COL.wall,SMOOTH,true)
 for _,side in {-1,1} do
  part("WallSide",Vector3.new(1,Hh,Dp),CFrame.new(side*(W/2-.5),.8+Hh/2,0),COL.wall,SMOOTH,true)
  local seg=(W-dw)/2
  part("WallFront",Vector3.new(seg,Hh,1),CFrame.new(side*(dw/2+seg/2),.8+Hh/2,-Dp/2+.5),COL.wall,SMOOTH,true)
  part("Corner",Vector3.new(1.5,Hh+.2,1.5),CFrame.new(side*W/2,.8+Hh/2,-Dp/2),COL.wood)
  part("Corner",Vector3.new(1.5,Hh+.2,1.5),CFrame.new(side*W/2,.8+Hh/2,Dp/2),COL.wood)
 end
 part("Lintel",Vector3.new(dw,Hh-dh,1),CFrame.new(0,.8+dh+(Hh-dh)/2,-Dp/2+.5),COL.wall,SMOOTH,true)
 if (L.Floors or 1)>=2 then
  for _,z in {-Dp/2-.1,Dp/2+.1} do part("FloorBand",Vector3.new(W+.4,.7,.4),CFrame.new(0,.8+Hh/2,z),COL.trim) end
  for _,side in {-1,1} do part("FloorBand",Vector3.new(.4,.7,Dp+.4),CFrame.new(side*(W/2+.1),.8+Hh/2,0),COL.trim) end
 end
 -- Windows: glass, a purple frame with a cross, a wooden sill
 local function window(cf,flower)
  part("Glass",Vector3.new(3.6,3.6,.3),cf*CFrame.new(0,0,-.55),COL.glass).Reflectance=.15
  for _,e in {{0,1.95,4.4,.5},{0,-1.95,4.4,.5}} do part("Frame",Vector3.new(e[3],e[4],.4),cf*CFrame.new(e[1],e[2],-.7),COL.frame) end
  for _,x in {-1.95,1.95} do part("Frame",Vector3.new(.5,4.4,.4),cf*CFrame.new(x,0,-.7),COL.frame) end
  part("Mullion",Vector3.new(.25,3.6,.35),cf*CFrame.new(0,0,-.72),COL.frame);part("Mullion",Vector3.new(3.6,.25,.35),cf*CFrame.new(0,0,-.72),COL.frame)
  part("Sill",Vector3.new(4.8,.4,.9),cf*CFrame.new(0,-2.35,-.8),COL.wood)
  if flower then
   part("FlowerBox",Vector3.new(4.4,.9,1),cf*CFrame.new(0,-3,-1.1),COL.wood)
   for k=-1,1 do local b=part("Bloom",Vector3.new(.9,.9,.9),cf*CFrame.new(k*1.3,-2.35,-1.15),Color3.fromHex(({"FF6FA8","FFD93B","FF9A2E"})[k+2]),SMOOTH,false,Enum.PartType.Ball) end
  end
 end
 local wy=.8+4.6
 local rows=(L.Floors or 1)>=2 and {wy,.8+Hh-4.4} or {wy}
 local fx=dw/2+(W/2-dw/2)/2
 for r,y in rows do
  for _,side in {-1,1} do
   window(CFrame.new(side*fx,y,-Dp/2),r==1 and L.Porch)
   window(CFrame.new(side*W/2,y,0)*CFrame.Angles(0,-side*math.pi/2,0))
  end
  window(CFrame.new(0,y,Dp/2)*CFrame.Angles(0,math.pi,0))
  if r==2 then window(CFrame.new(0,y,-Dp/2)) end
 end
 -- Doorway: wooden frame, the door swung open inside, a step, a lamp and the farm's sign
 for _,side in {-1,1} do part("DoorPost",Vector3.new(.6,dh,1.4),CFrame.new(side*(dw/2+.3),.8+dh/2,-Dp/2+.5),COL.wood) end
 part("DoorTop",Vector3.new(dw+1.2,.6,1.4),CFrame.new(0,.8+dh+.3,-Dp/2+.5),COL.wood)
 part("DoorLeaf",Vector3.new(5.4,dh-.3,.3),CFrame.new(-dw/2-2.7,.8+(dh-.3)/2,-Dp/2+1.3),COL.wood)
 part("DoorKnob",Vector3.new(.45,.45,.45),CFrame.new(-dw/2-4.9,.8+dh/2,-Dp/2+1.5),COL.gold,Enum.Material.Metal,false,Enum.PartType.Ball)
 part("Doorstep",Vector3.new(dw+2,.4,3),CFrame.new(0,.2,-Dp/2-1.5),COL.stone,Enum.Material.Slate,true)
 part("LampArm",Vector3.new(.3,.3,1.2),CFrame.new(dw/2+1.6,.8+dh+.2,-Dp/2-.6),COL.roofDark)
 local lamp=WA.NightGlow(part("Lamp",Vector3.new(.9,1.2,.9),CFrame.new(dw/2+1.6,.8+dh-.5,-Dp/2-1.1),COL.lamp))
 local glow=Instance.new("PointLight");glow.Color=COL.lamp;glow.Range=16;glow.Brightness=1.2;glow.Parent=lamp;WA.NightLight(glow)
 part("SignBoard",Vector3.new(dw+2.4,1.8,.3),CFrame.new(0,.8+dh+1.6,-Dp/2-.2),COL.wood)
 P.SignText(m,hb*CFrame.new(0,.8+dh+1.6,-Dp/2-.42),Vector3.new(dw+2,1.5,.1),'signHome',Pal.Text)
 -- Roof: two slopes meeting at a ridge along the width, flared eaves, shingle stripes, gables at the sides
 local half=Dp/2+1.6;local len=math.sqrt(half*half+R*R);local nrm=Vector3.new(0,half,R).Unit
 for _,dir in {-1,1} do
  local center=Vector3.new(0,top+R/2,dir*half/2)
  local slope=CFrame.lookAt(center,center+Vector3.new(0,-R,dir*half))
  roof("RoofSlope",Vector3.new(W+3.2,1,len),slope*CFrame.new(0,.5,0),COL.roof)
  for k=1,3 do roof("Shingles",Vector3.new(W+3.3,.25,.5),slope*CFrame.new(0,1.05,(k/4-.5)*len),COL.roofDark) end
  local edge=Vector3.new(0,top,dir*half);local flare=CFrame.lookAt(edge+Vector3.new(0,-.25,dir*1.2),edge+Vector3.new(0,-.5,dir*2.4))
  roof("Eave",Vector3.new(W+3.2,.9,2.6),flare,COL.roof)
 end
 roof("Ridge",Vector3.new(W+3.8,1,1.6),CFrame.new(0,top+R+.35,0),L.Gold and COL.gold or COL.roofDark)
 -- WedgePart: the tall face looks to +Z, so the front half keeps its orientation and the back half turns round.
 for _,side in {-1,1} do
  for _,back in {false,true} do
   local w=Instance.new("WedgePart");w.Name="Gable";w.Size=Vector3.new(1,R,half);w.Color=COL.wall;w.Material=SMOOTH;w.Anchored=true;w.CanCollide=false;w.CanTouch=false;w.CanQuery=false
   w.CFrame=hb*CFrame.new(side*(W/2-.5),top+R/2,back and half/2 or -half/2)*(back and CFrame.Angles(0,math.pi,0) or CFrame.identity);w.Parent=m
  end
 end
 local gw=CFrame.new(W/2+.05,top+R*.38,0)*CFrame.Angles(0,-math.pi/2,0)
 if R>=8 then window(gw) end
 -- Chimney with a purple cap and a wisp of smoke
 local cx,cz=W/2-5,Dp/4
 local chimney=part("Chimney",Vector3.new(3,R+3,3),CFrame.new(cx,top+(R+3)/2,cz),COL.wall)
 part("ChimneyCap",Vector3.new(3.8,.8,3.8),CFrame.new(cx,top+R+3.2,cz),L.Gold and COL.gold or COL.roofDark)
 local smoke=Instance.new("ParticleEmitter");smoke.Color=ColorSequence.new(Color3.fromHex("EDE8F5"));smoke.Transparency=NumberSequence.new(.35,1);smoke.Size=NumberSequence.new(.8,2.4)
 smoke.Lifetime=NumberRange.new(2,3);smoke.Rate=2;smoke.Speed=NumberRange.new(1.5,2.5);smoke.SpreadAngle=Vector2.new(12,12);smoke.EmissionDirection=Enum.NormalId.Top
 local puff=part("Smoke",Vector3.new(1,1,1),CFrame.new(cx,top+R+3.8,cz),COL.wall);puff.Transparency=1;smoke.Parent=puff
 -- Porch over the door
 if L.Porch then
  for _,side in {-1,1} do part("PorchPost",Vector3.new(.7,dh+1.4,.7),CFrame.new(side*(dw/2+1.6),.8+(dh+1.4)/2,-Dp/2-3.6),COL.wood) end
  roof("PorchRoof",Vector3.new(dw+4.6,.7,4.6),CFrame.new(0,.8+dh+1.9,-Dp/2-2.2)*CFrame.Angles(-.22,0,0),COL.roof)
 end
 -- Corner tower with a pointed roof
 if L.Tower then
  local tx,tz=-W/2+3,-Dp/2+3;local th=Hh+6 -- tucked into the corner, so it stays inside the fence
  part("Tower",Vector3.new(th,9,9),CFrame.new(tx,.8+th/2,tz)*CFrame.Angles(0,0,math.pi/2),COL.wall,SMOOTH,true,Enum.PartType.Cylinder)
  for k,r in {11,8,5,2.4} do roof("TowerRoof",Vector3.new(2.2,r,r),CFrame.new(tx,.8+th+.9+(k-1)*1.9,tz)*CFrame.Angles(0,0,math.pi/2),k%2==0 and COL.roofDark or COL.roof).Shape=Enum.PartType.Cylinder end
  window(CFrame.new(tx,.8+th-4,tz-4.45))
  if L.Gold then
   part("FlagPole",Vector3.new(.3,5,.3),CFrame.new(tx,.8+th+10,tz),COL.gold,Enum.Material.Metal)
   part("Flag",Vector3.new(.15,1.8,3),CFrame.new(tx,.8+th+11.4,tz-1.6),Color3.fromHex("FF5468"))
  end
 end
 -- Round bushes along the front
 for _,b in {{-W/2-1,-Dp/2-1.4,3.4},{W/2+1,-Dp/2-1.4,3.4},{-W/2-1.2,Dp/4,2.8},{W/2+1.2,-Dp/6,2.6}} do
  part("Bush",Vector3.new(b[3],b[3],b[3]),CFrame.new(b[1],b[3]/2,b[2]),COL.bush,SMOOTH,false,Enum.PartType.Ball)
 end
 return m
end
function H.SetLook(plot,index)
 if plot.Look==index and plot.House then return end
 if plot.House then plot.House:Destroy() end
 local m=H.Cottage(plot,index)
 m.Parent=plot.Model;plot.House=m;plot.Look=index
end
function H.Base(plot) return plot.Base*CFrame.new(C.RoomX or 0,C.RoomY,C.RoomZ)*CFrame.Angles(0,math.rad(C.RoomYaw or 0),0) end
-- Facing the house, so the camera behind the player has the open path to stand on.
local function doorSpot(plot) return plot.Base*CFrame.new(C.Spot.X-11,5,C.Spot.Z)*CFrame.Angles(0,math.rad(-90),0) end
local function anchor(parent,name,cf,size)
 local a=P.Part(parent,name,size or Vector3.new(4,4,4),cf,Pal.Panel);a.Transparency=1;a.CanCollide,a.CanTouch,a.CanQuery,a.CastShadow=false,false,false,false;return a
end
local function prompt(part,name,text,distance,attrs)
 local pr=Instance.new("ProximityPrompt");pr.Name=name;pr.ActionText=text;pr.HoldDuration=0;pr.MaxActivationDistance=distance;pr.RequiresLineOfSight=false
 for k,v in pairs(attrs or {}) do pr:SetAttribute(k,v) end
 pr.Parent=part;return pr
end
local function tag(part,key,height)
 local b=Instance.new("BillboardGui");b.Name="Tag";b.Size=UDim2.fromOffset(170,36);b.StudsOffsetWorldSpace=Vector3.new(0,height,0);b.MaxDistance=45;b.LightInfluence=0;b.Parent=part
 local l=Instance.new("TextLabel");l.Size=UDim2.fromScale(1,1);l.BackgroundColor3=Pal.Panel;l.TextColor3=Pal.Ink;l.Font=Enum.Font.GothamBlack;l.TextScaled=true;l.AutoLocalize=false;l.Text=""
 l:SetAttribute("LocKey",key);l.Parent=b
 Instance.new("UICorner",l).CornerRadius=UDim.new(1,0)
 local s=Instance.new("UIStroke");s.Color=Pal.Stroke;s.Thickness=3;s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;s.Parent=l
end
-- Inside -------------------------------------------------------------------------------------------
H.MergeZones={}
local function buildRoom(p,plot,index)
 local m=Instance.new("Model");m.Name="HouseRoom"
 local L=C.Looks[index];local hb=plot.Base*CFrame.new(C.RoomX,C.FloorY or .7,C.RoomZ)*CFrame.Angles(0,math.rad(C.RoomYaw or 0),0)
 -- The merge table stands at the back wall, its menu circle in front of it.
 local mergeTable=WA.Model("V3_MergeTable",m,hb*CFrame.new(0,1,L.D/2-4.6)*CFrame.Angles(0,math.pi,0))
 mergeTable.Name="MergeTable"
 P.Solid(m,"TableBlock",Vector3.new(11,4,5),hb*CFrame.new(0,3,L.D/2-4.6))
 local zone=anchor(m,"MergeZone",hb*CFrame.new(0,1.05,L.D/2-11),Vector3.new(1,1,1))
 zone.Color=Color3.fromHex("53C7FF");zone:SetAttribute("MenuZone","merge");zone:SetAttribute("Radius",4.2);zone:SetAttribute("Owner",p.UserId)
 H.MergeZones[p]=zone
 local rug=P.Part(m,"Rug",Vector3.new(.1,10,10),hb*CFrame.new(0,1.02,L.D/2-11)*CFrame.Angles(0,0,math.pi/2),Color3.fromHex("FF8DB6"),Enum.PartType.Cylinder)
 rug.CanCollide,rug.CanQuery,rug.CanTouch=false,false,false
 for _,x in {-L.W/2+3.5,L.W/2-3.5} do
  local light=Instance.new("PointLight");light.Color=Color3.fromRGB(255,226,173);light.Brightness=.9;light.Range=22
  light.Parent=anchor(m,"Light",hb*CFrame.new(x,L.Wall-1,0),Vector3.new(1,1,1));WA.NightLight(light)
 end
 m.Parent=plot.Model;return m
end
function H.NearMerge(p)
 local zone=H.MergeZones[p]
 return zone and zone.Parent and P.Near(p,zone.Position,(zone:GetAttribute("Radius") or 4)+4) or false
end
function H.RefreshTreadmill(p,d)
 local plot=P.Assigned[p];if not plot then return end
 local level=require(S.RoadRules).Level(d);local old=H.Treadmills[p]
 if old and old.Parent and old:GetAttribute('Level')==level then return end
 if old then old:Destroy() end
 local tm=require(S.Config.RoadConfig).TreadmillSpot;local cf=plot.Base*CFrame.new(tm.X,tm.Y,tm.Z)
 local m=WA.Model('V3_Treadmill'..level,plot.Model,cf);m.Name='OutdoorTreadmill';m:SetAttribute('Level',level);m:SetAttribute('Owner',p.UserId)
 local belt=P.Solid(m,'Treadmill',Vector3.new(tm.W,1.6,tm.D),cf*CFrame.new(0,.8,0));belt:SetAttribute('TreadmillBelt',true);belt:SetAttribute('Owner',p.UserId)
 for _,side in {-1,1} do P.Solid(m,'TreadmillRail',Vector3.new(.6,3.4,12),cf*CFrame.new(side*3.8,1.7,0)) end
 P.Solid(m,'TreadmillConsole',Vector3.new(7,2,1),cf*CFrame.new(0,7,-5.6))
 H.Treadmills[p]=m
end
local function refresh(p,d)
 local plot=P.Assigned[p];if not plot then return end
 local index=look(R.Level(d));local changed=plot.Look~=index
 H.SetLook(plot,index)
 H.RefreshTreadmill(p,d)
 if changed or not H.Rooms[p] then
  if H.Rooms[p] then H.Rooms[p]:Destroy() end
  H.Rooms[p]=buildRoom(p,plot,index)
 end
end
H.Refresh=refresh
-- Movement -----------------------------------------------------------------------------------------
-- Retained entry points reject obsolete clients; open houses have no teleport.
function H.Enter(p) return false end
function H.Leave(p) return false end
-- Upgrades -----------------------------------------------------------------------------------------
function H.Upgrade(p,d)
 local plot=P.Assigned[p];if not plot or not P.Inside(p,plot) then return false end
 return R.Start(d)
end
local function timerText(left) return string.format("%d:%02d",math.floor(left/60),left%60) end
local function showTimer(p,plot,left)
 local b=H.Timers[p]
 if left<=0 then if b then if b.Parent then b.Parent:Destroy() end;H.Timers[p]=nil end;return end
 if not b or not b.Parent then
  local spot=anchor(plot.Model,"BuildTimer",H.Base(plot)*CFrame.new(0,7,-8),Vector3.new(1,1,1))
  b=Instance.new("BillboardGui");b.Name="BuildTimer";b.Size=UDim2.fromOffset(120,38);b.MaxDistance=90;b.LightInfluence=0;b.Parent=spot;H.Timers[p]=b
  local l=Instance.new("TextLabel");l.Name="Text";l.Size=UDim2.fromScale(1,1);l.BackgroundColor3=Pal.Accent;l.TextColor3=Pal.Ink;l.Font=Enum.Font.GothamBlack;l.TextScaled=true;l.AutoLocalize=false;l.Parent=b
  Instance.new("UICorner",l).CornerRadius=UDim.new(1,0)
  local s=Instance.new("UIStroke");s.Color=Pal.Stroke;s.Thickness=3;s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;s.Parent=l
 end
 b.Text.Text="🔨 "..timerText(left)
end
function H.Tick(p,d)
 local inside=P.InHouse(p);if p:GetAttribute("InHouse")~=inside then p:SetAttribute("InHouse",inside) end
 if R.Finish(d) then
  if H.Timers[p] then local spot=H.Timers[p].Parent;if spot then spot:Destroy() end;H.Timers[p]=nil end
  refresh(p,d);notice(p,"houseDone",{n=R.Level(d)})
 end
 H.RefreshTreadmill(p,d)
 local plot=P.Assigned[p];if plot then showTimer(p,plot,R.Remaining(d)) end
end
function H.Join(p,d)
 R.Finish(d);p:SetAttribute("InHouse",false);refresh(p,d)
 local plot=P.Assigned[p];if not plot then return end

end
function H.Forget(p)
 if H.Treadmills[p] then H.Treadmills[p]:Destroy();H.Treadmills[p]=nil end
 local plot=P.Assigned[p]
 if H.Rooms[p] then H.Rooms[p]:Destroy();H.Rooms[p]=nil end;H.MergeZones[p]=nil
 if H.Timers[p] then local spot=H.Timers[p].Parent;if spot then spot:Destroy() end;H.Timers[p]=nil end
 if plot then
  if plot.DoorPart then plot.DoorPart:Destroy();plot.DoorPart=nil end
  H.SetLook(plot,1)
 end
end
function H.Init() for _,plot in ipairs(P.Plots) do H.SetLook(plot,1) end end
return H
