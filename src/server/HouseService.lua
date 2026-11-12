-- Walk-in houses and outdoor treadmills; no teleport doors.
local S=game.ReplicatedStorage.Shared;local RS=game.ReplicatedStorage
local C=require(S.Config.HouseConfig);local R=require(S.HouseRules);local Art=require(S.ArtKit);local Pal=require(S.Palette);local L=require(S.Locale)
local D=require(script.Parent.DataService);local P=require(script.Parent.PlotService);local Raid=require(script.Parent.RaidService)
local WA=require(S.WorldArt)
local H={Rooms={},Timers={},Treadmills={}}
local function notice(p,key,args) RS.Remotes.Notice:FireClient(p,key,args) end
local function look(level) return C.Levels[level].Look end
-- Outside ------------------------------------------------------------------------------------------
-- v2 (owner, 2026-11-12, after a reference picture of a two-storey "base"): a monster base instead of the cottage.
-- Graphite walls between cream corner pillars, a glass storefront either side of an open glass door, a flat roof
-- behind a parapet. Levels (HouseConfig.Looks): an awning, planters and neon strips; a showroom floor whose big
-- windows show your best monsters on lit plinths (H.Showcase); a rooftop billboard with your name; gold trim and a
-- beacon; a third, set-back floor with more of the showcase; a golden crown. Everything above the ground floor
-- fades while you are inside (HouseRoof), as the old roof did. Same footprint and doorway as the cottage.
local COL={wall=Color3.fromHex("2F2A3D"),wallDark=Color3.fromHex("231F2E"),pillar=Color3.fromHex("EDE6F7"),trim=Color3.fromHex("CFC3E6"),
 neon=Color3.fromHex("B45CFF"),neonPink=Color3.fromHex("FF5FB4"),glass=Color3.fromHex("9FD8FF"),floor=Color3.fromHex("E2B985"),
 plinth=Color3.fromHex("6B5F86"),awningA=Color3.fromHex("8C4BFF"),awningB=Color3.fromHex("FFF0D4"),gold=Color3.fromHex("FFD34D"),
 bush=Color3.fromHex("5FCB4A"),lamp=Color3.fromHex("FFE58D"),show=Color3.fromHex("3B3352"),wood=Color3.fromHex("A8754A"),metal=Color3.fromHex("8E88A6")}
local SMOOTH=Enum.Material.SmoothPlastic
function H.Building(plot,index)
 local Lk=C.Looks[index];local W,Dp,Hh=Lk.W,Lk.D,Lk.Wall;local floors=Lk.Floors or 1;local FH=Lk.FloorHeight or 10
 local hb=plot.Base*CFrame.new(C.RoomX,C.FloorY or .7,C.RoomZ)*CFrame.Angles(0,math.rad(C.RoomYaw or 0),0)
 local m=Instance.new("Model");m.Name="House";m:SetAttribute("Look",index)
 local slots={};m:SetAttribute("Showcase",0)
 local function part(name,size,cf,color,material,solid,shape)
  local q=P.Part(m,name,size,hb*cf,color,shape);q.Material=material or SMOOTH
  q.CanCollide=solid==true;q.CanQuery=solid==true;q.CanTouch=false;return q
 end
 local function up(q) q:SetAttribute("HouseRoof",true);return q end
 local function neon(name,size,cf,color) local q=part(name,size,cf,color or COL.neon,Enum.Material.Neon);q.CastShadow=false;return q end
 local trimColor=Lk.Gold and COL.gold or COL.trim
 local base=.8;local top=base+Hh;local dw,dh=6,8
 -- Plinth down to the lawn, the floor, a two-step stoop
 part("Plinth",Vector3.new(W+2,2,Dp+2),CFrame.new(0,-.2,0),COL.plinth,Enum.Material.Slate,true)
 part("Floor",Vector3.new(W-1,.2,Dp-1),CFrame.new(0,.9,0),COL.floor,Enum.Material.WoodPlanks,true)
 part("Doorstep",Vector3.new(dw+3,.4,3),CFrame.new(0,.2,-Dp/2-1.5),COL.plinth,Enum.Material.Slate,true)
 part("DoorstepLow",Vector3.new(dw+4,.4,2),CFrame.new(0,-.3,-Dp/2-3.6),COL.plinth,Enum.Material.Slate,true)
 -- Ground floor: solid back and sides, a window panel on each side
 part("WallBack",Vector3.new(W,Hh,1),CFrame.new(0,base+Hh/2,Dp/2-.5),COL.wall,SMOOTH,true)
 for _,side in {-1,1} do
  part("WallSide",Vector3.new(1,Hh,Dp),CFrame.new(side*(W/2-.5),base+Hh/2,0),COL.wall,SMOOTH,true)
  local sideGlass=part("SideWindow",Vector3.new(.3,6,Dp-10),CFrame.new(side*(W/2+.05),base+6,0),COL.glass,Enum.Material.Glass);sideGlass.Transparency=.35
  part("SideWindowFrame",Vector3.new(.45,.6,Dp-9),CFrame.new(side*(W/2+.1),base+9.2,0),trimColor)
  part("SideWindowFrame",Vector3.new(.45,.6,Dp-9),CFrame.new(side*(W/2+.1),base+2.8,0),trimColor)
 end
 -- The storefront: a kick band, tall glass with a mullion, a header band; the doorway between
 local seg=(W-dw)/2
 for _,side in {-1,1} do
  local x=side*(dw/2+seg/2)
  part("Kick",Vector3.new(seg,1.6,1),CFrame.new(x,base+.8,-Dp/2+.5),COL.wallDark,SMOOTH,true)
  local glass=part("Storefront",Vector3.new(seg-.4,7.6,.4),CFrame.new(x,base+1.6+3.8,-Dp/2+.6),COL.glass,Enum.Material.Glass,true);glass.Transparency=.55
  part("Mullion",Vector3.new(.6,7.6,.7),CFrame.new(x,base+1.6+3.8,-Dp/2+.55),COL.pillar)
  part("Header",Vector3.new(seg,Hh-9.2,1),CFrame.new(x,base+9.2+(Hh-9.2)/2,-Dp/2+.5),COL.wall,SMOOTH,true)
  part("Sill",Vector3.new(seg,.4,1.4),CFrame.new(x,base+1.6,-Dp/2+.3),trimColor)
  part("Pillar",Vector3.new(1.8,Hh+.2,1.8),CFrame.new(side*W/2,base+Hh/2,-Dp/2),COL.pillar)
  part("Pillar",Vector3.new(1.8,Hh+.2,1.8),CFrame.new(side*W/2,base+Hh/2,Dp/2),COL.pillar)
 end
 part("Lintel",Vector3.new(dw,Hh-dh,1),CFrame.new(0,base+dh+(Hh-dh)/2,-Dp/2+.5),COL.wall,SMOOTH,true)
 -- Open glass double door in a light frame
 for _,side in {-1,1} do
  part("DoorPost",Vector3.new(.6,dh,1.2),CFrame.new(side*(dw/2+.3),base+dh/2,-Dp/2+.5),COL.pillar)
  local leaf=part("DoorLeaf",Vector3.new(2.9,dh-.4,.25),CFrame.new(side*(dw/2-.1),base+(dh-.4)/2,-Dp/2+1)*CFrame.Angles(0,side*math.rad(75),0)*CFrame.new(-side*1.45,0,0),COL.glass,Enum.Material.Glass);leaf.Transparency=.45
  part("DoorHandle",Vector3.new(.2,1.6,.3),hb:ToObjectSpace(leaf.CFrame)*CFrame.new(-side*1.1,0,-.2),COL.metal,Enum.Material.Metal)
 end
 part("DoorTop",Vector3.new(dw+1.2,.5,1.3),CFrame.new(0,base+dh+.25,-Dp/2+.5),COL.pillar)
 -- Sign over the door and wall lamps either side
 part("SignBoard",Vector3.new(dw+3,1.8,.3),CFrame.new(0,base+dh+1.6,-Dp/2-.1),COL.wallDark)
 P.SignText(m,hb*CFrame.new(0,base+dh+1.6,-Dp/2-.28),Vector3.new(dw+2.4,1.5,.1),'signHome',COL.lamp)
 for _,side in {-1,1} do
  local lamp=WA.NightGlow(part("Lamp",Vector3.new(.7,1.6,.5),CFrame.new(side*(dw/2+1.5),base+dh-1.2,-Dp/2-.3),COL.lamp,Enum.Material.Neon))
  local glow=Instance.new("PointLight");glow.Color=COL.lamp;glow.Range=14;glow.Brightness=1;glow.Parent=lamp;WA.NightLight(glow)
 end
 -- Inside, behind the storefront: a plinth in each front corner for the showcase
 for _,side in {-1,1} do
  local x=side*(W/2-4.2);local z=-Dp/2+3.6
  part("ShowPlinth",Vector3.new(3.2,1.4,3.2),CFrame.new(x,base+.9,z),COL.show,SMOOTH,true)
  neon("ShowPlinthGlow",Vector3.new(3.3,.2,3.3),CFrame.new(x,base+1.65,z),COL.neon)
  table.insert(slots,{cf=hb*CFrame.new(x,base+1.75,z),height=4.6,upper=false})
 end
 -- Neon strips: along the header and down the front pillars
 if Lk.Neon then
  neon("HeaderNeon",Vector3.new(W-2,.35,.3),CFrame.new(0,base+9.5,-Dp/2-.05))
  for _,side in {-1,1} do neon("PillarNeon",Vector3.new(.3,Hh-1,.3),CFrame.new(side*(W/2-1),base+Hh/2,-Dp/2-.95),COL.neonPink) end
 end
 -- Awning: purple and cream stripes leaning out over each storefront
 if Lk.Awning then
  for _,side in {-1,1} do
   local stripes=6;local width=(seg-.6)/stripes
   for k=0,stripes-1 do
    local x=side*(dw/2+.3)+side*(width*(k+.5))
    part("Awning",Vector3.new(width+.02,.25,3.6),CFrame.new(x,base+9.9,-Dp/2-1.5)*CFrame.Angles(math.rad(-18),0,0),k%2==0 and COL.awningA or COL.awningB)
   end
   part("AwningEdge",Vector3.new(seg-.4,.6,.3),CFrame.new(side*(dw/2+seg/2),base+9.2,-Dp/2-3.2),COL.awningA)
  end
 end
 -- Planters with round bushes at the front corners
 if Lk.Planters then
  for _,side in {-1,1} do
   part("Planter",Vector3.new(3.4,1.6,3.4),CFrame.new(side*(W/2+1.2),.6,-Dp/2-2.6),COL.wallDark,SMOOTH,true)
   part("PlanterRim",Vector3.new(3.8,.3,3.8),CFrame.new(side*(W/2+1.2),1.45,-Dp/2-2.6),trimColor)
   part("Bush",Vector3.new(3.4,3.4,3.4),CFrame.new(side*(W/2+1.2),2.8,-Dp/2-2.6),COL.bush,SMOOTH,false,Enum.PartType.Ball)
  end
 end
 -- Upper floors: showrooms. Each a slab, dark walls, three big front windows with lit plinths behind them.
 local y=top
 for f=2,floors do
  local inset=f>=3 and 3 or 0;local w,dp=W-inset*2,Dp-inset*2;local z0=inset*.6
  up(part("FloorSlab",Vector3.new(w+.6,.8,dp+.6),CFrame.new(0,y+.4,z0),COL.wallDark,SMOOTH,true))
  if f==3 then up(part("Terrace",Vector3.new(W+.6,.8,Dp+.6),CFrame.new(0,y+.4,0),COL.wallDark)) end
  local b=y+.8
  up(part("UpperBack",Vector3.new(w,FH,1),CFrame.new(0,b+FH/2,z0+dp/2-.5),COL.wall))
  for _,side in {-1,1} do
   up(part("UpperSide",Vector3.new(1,FH,dp),CFrame.new(side*(w/2-.5),b+FH/2,z0),COL.wall))
   up(part("UpperPillar",Vector3.new(1.8,FH+.2,1.8),CFrame.new(side*w/2,b+FH/2,z0-dp/2),COL.pillar))
   up(part("UpperPillar",Vector3.new(1.8,FH+.2,1.8),CFrame.new(side*w/2,b+FH/2,z0+dp/2),COL.pillar))
  end
  up(part("UpperSill",Vector3.new(w,1.4,1),CFrame.new(0,b+.7,z0-dp/2+.5),COL.wallDark))
  up(part("UpperHeader",Vector3.new(w,1.6,1),CFrame.new(0,b+FH-.8,z0-dp/2+.5),COL.wall))
  local pane=(w-2)/3
  for k=-1,1 do
   local x=k*pane
   local glass=up(part("ShowWindow",Vector3.new(pane-.5,FH-3,.35),CFrame.new(x,b+1.4+(FH-3)/2,z0-dp/2+.55),COL.glass,Enum.Material.Glass));glass.Transparency=.5
   up(part("ShowMullion",Vector3.new(.6,FH-3,.6),CFrame.new(x+pane/2,b+1.4+(FH-3)/2,z0-dp/2+.5),COL.pillar))
   local plinth=CFrame.new(x,b+.7,z0-dp/2+3.4)
   up(part("ShowPlinth",Vector3.new(3,1.4,3),plinth,COL.show))
   up(neon("ShowPlinthGlow",Vector3.new(3.1,.2,3.1),plinth*CFrame.new(0,.75,0),COL.neon))
   table.insert(slots,{cf=hb*plinth*CFrame.new(0,.85,0),height=FH-3.4,upper=true})
  end
  -- the showroom's back wall glows, so the figures stand out against it
  up(neon("ShowroomGlow",Vector3.new(w-3,.4,.3),CFrame.new(0,b+FH-2.2,z0+dp/2-1.1),COL.neonPink))
  local lamp=up(part("ShowroomLight",Vector3.new(1,1,1),CFrame.new(0,b+FH-1.5,z0),COL.lamp));lamp.Transparency=1
  local light=Instance.new("PointLight");light.Color=Color3.fromHex("FFE1F6");light.Range=20;light.Brightness=1.2;light.Parent=lamp
  if Lk.Neon then up(neon("UpperNeon",Vector3.new(w-2,.3,.3),CFrame.new(0,b+1.5,z0-dp/2-.05))) end
  y=b+FH
 end
 -- Roof: a slab, a parapet with a coping, two vents
 local inset=floors>=3 and 3 or 0;local w,dp,z0=W-inset*2,Dp-inset*2,inset*.6
 up(part("RoofSlab",Vector3.new(w+.6,.8,dp+.6),CFrame.new(0,y+.4,z0),COL.wallDark))
 for _,e in {-1,1} do
  up(part("Parapet",Vector3.new(w+.6,1.6,.8),CFrame.new(0,y+1.6,z0+e*(dp/2)),COL.wall))
  up(part("Parapet",Vector3.new(.8,1.6,dp+.6),CFrame.new(e*(w/2),y+1.6,z0),COL.wall))
  up(part("Coping",Vector3.new(w+1.2,.35,1.2),CFrame.new(0,y+2.5,z0+e*(dp/2)),trimColor))
  up(part("Coping",Vector3.new(1.2,.35,dp+1.2),CFrame.new(e*(w/2),y+2.5,z0),trimColor))
 end
 for _,v in {{-w/4,dp/5},{w/5,dp/4}} do
  up(part("Vent",Vector3.new(3,1.8,2.4),CFrame.new(v[1],y+1.7,z0+v[2]),COL.metal,Enum.Material.Metal))
  up(part("VentGrille",Vector3.new(2.4,.2,1.8),CFrame.new(v[1],y+2.7,z0+v[2]),COL.wallDark))
 end
 -- Rooftop billboard with the owner's name, lit by two spotlights
 if Lk.Billboard then
  local by=y+7.2
  for _,side in {-1,1} do up(part("BillboardPost",Vector3.new(.6,6,.6),CFrame.new(side*(w/2-6),y+3.4,z0-dp/2+3),COL.metal,Enum.Material.Metal)) end
  up(part("Billboard",Vector3.new(w-6,5,.6),CFrame.new(0,by,z0-dp/2+3),COL.wallDark))
  for _,e in {-1,1} do
   up(neon("BillboardEdge",Vector3.new(w-5.4,.35,.4),CFrame.new(0,by+e*2.6,z0-dp/2+2.95),Lk.Gold and COL.gold or COL.neon))
   up(neon("BillboardEdge",Vector3.new(.35,5.5,.4),CFrame.new(e*(w/2-3.1),by,z0-dp/2+2.95),Lk.Gold and COL.gold or COL.neon))
  end
  local label,carrier=P.SignText(m,hb*CFrame.new(0,by,z0-dp/2+2.62),Vector3.new(w-8,4,.1),nil,COL.pillar)
  label.Name="HouseNamePlate";label:SetAttribute("PlateKey","houseOwner");label:SetAttribute("OwnerPlate",true);label.Parent.PixelsPerStud=26
  carrier.Name="HouseNamePlate";up(carrier)
  for _,side in {-1,1} do
   local spot=up(part("Spotlight",Vector3.new(1.2,1.2,1.6),CFrame.new(side*(w/2-3),y+3.2,z0-dp/2+.4)*CFrame.Angles(math.rad(35),0,0),COL.metal,Enum.Material.Metal))
   local light=Instance.new("SpotLight");light.Face=Enum.NormalId.Back;light.Angle=60;light.Range=14;light.Brightness=2;light.Color=COL.lamp;light.Parent=spot;WA.NightLight(light)
  end
 end
 -- A beacon on the roof's back corner
 if Lk.Beacon then
  up(part("BeaconMast",Vector3.new(.4,7,.4),CFrame.new(w/2-2,y+5.4,z0+dp/2-2),COL.metal,Enum.Material.Metal))
  local beacon=up(neon("Beacon",Vector3.new(1.2,1.2,1.2),CFrame.new(w/2-2,y+9.2,z0+dp/2-2),COL.neonPink));beacon.Shape=Enum.PartType.Ball
  local light=Instance.new("PointLight");light.Color=COL.neonPink;light.Range=18;light.Brightness=1.4;light.Parent=beacon;WA.NightLight(light)
 end
 -- A golden crown along the front parapet
 if Lk.Crown then
  for k=-4,4 do
   local spike=up(part("CrownSpike",Vector3.new(1.4,k%2==0 and 3.2 or 2,1.4),CFrame.new(k*(w/10),y+3.6,z0-dp/2)*CFrame.Angles(0,math.rad(45),0),COL.gold,Enum.Material.Metal))
   if k%2==0 then local gem=up(neon("CrownGem",Vector3.new(.7,.7,.7),hb:ToObjectSpace(spike.CFrame)*CFrame.new(0,1.9,0),COL.neonPink));gem.Shape=Enum.PartType.Ball end
  end
 end
 m:SetAttribute("Showcase",#slots)
 return m,slots
end
-- The showcase: your best monsters (by income) on the plinths, the best upstairs where the street sees them.
-- Rebuilt only when the line-up changes (H.Tick).
local Merge=require(S.MergeRules)
local function showcase(plot,d)
 local slots=plot.ShowSlots;if not slots or not plot.House then return end
 local best={};for _,z in d.zombies do if not z.pendingTransfer then table.insert(best,z) end end
 table.sort(best,function(a,b) local ra,rb=Merge.Rate(a),Merge.Rate(b);if ra~=rb then return ra>rb end;return a.id<b.id end)
 -- upper plinths first: they face the farm
 local order={};for i,slot in slots do if slot.upper then table.insert(order,i) end end;for i,slot in slots do if not slot.upper then table.insert(order,i) end end
 local sig={};for k=1,math.min(#order,#best) do local z=best[k];sig[k]=z.id..z.tier..z.mutation..tostring(z.stars) end
 local key=table.concat(sig,"|")..":"..tostring(plot.Look)
 if plot.ShowKey==key and plot.ShowFolder and plot.ShowFolder.Parent then return end
 plot.ShowKey=key;if plot.ShowFolder then plot.ShowFolder:Destroy() end
 local folder=Instance.new("Model");folder.Name="Showcase";plot.ShowFolder=folder
 for k=1,math.min(#order,#best) do
  local slot=slots[order[k]];local z=best[k]
  local fig=Instance.new("Model");fig.Name="Figure"
  local ok=pcall(Art.BuildZombie,fig,slot.cf,{id=z.id,type=z.type,tier=z.tier,mutation=z.mutation,stars=z.stars})
  if ok and #fig:GetChildren()>0 then
   for _,q in fig:GetDescendants() do
    if q:IsA("BasePart") then q.Anchored=true;q.CanCollide=false;q.CanQuery=false;q.CanTouch=false;if slot.upper then q:SetAttribute("HouseRoof",true) end
    elseif q:IsA("Script") or q:IsA("LocalScript") then q:Destroy() end
   end
   local _,size=fig:GetBoundingBox();local scale=math.clamp(slot.height/math.max(size.Y,.1),.2,3);fig:ScaleTo(fig:GetScale()*scale)
   local cf,box=fig:GetBoundingBox();local foot=slot.cf.Position
   fig:PivotTo(fig:GetPivot()+Vector3.new(foot.X-cf.Position.X,foot.Y-(cf.Position.Y-box.Y/2),foot.Z-cf.Position.Z))
   fig.Parent=folder
  else fig:Destroy() end
 end
 folder.Parent=plot.House
end
H.Showcase=showcase
function H.SetLook(plot,index)
 if plot.Look==index and plot.House then return end
 if plot.House then plot.House:Destroy() end
 local m,slots=H.Building(plot,index)
 plot.ShowSlots=slots;plot.ShowKey=nil;plot.ShowFolder=nil
 m.Parent=plot.Model;plot.House=m;plot.Look=index
 local plate=m:FindFirstChild("HouseNamePlate",true);if plate and plate:IsA("BasePart") then plate=plate:FindFirstChild("HouseNamePlate",true) end
 if plate then plate:SetAttribute("OwnerName",plot.OwnerName) end
end
-- The rooftop billboard carries the owner's name (WorldVisuals draws it).
local function nameHouse(plot,name)
 plot.OwnerName=name
 for _,q in plot.House and plot.House:GetDescendants() or {} do if q:IsA("TextLabel") and q.Name=="HouseNamePlate" then q:SetAttribute("OwnerName",name) end end
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
 local m=WA.Model('V3_Treadmill'..math.min(level,5),plot.Model,cf);m.Name='OutdoorTreadmill';m:SetAttribute('Level',level);m:SetAttribute('Owner',p.UserId)
 if level>5 then -- the top levels: the best model with glowing rails, gold then pink
  for _,side in {-1,1} do local glow=P.Part(m,'RailGlow',Vector3.new(.35,.35,12.4),cf*CFrame.new(side*3.8,3.5,0),level>=7 and Color3.fromHex('FF5FB4') or Color3.fromHex('FFD34D'));glow.Material=Enum.Material.Neon;glow.CanCollide,glow.CanQuery,glow.CanTouch=false,false,false end
 end
 local belt=P.Solid(m,'Treadmill',Vector3.new(tm.W,1.6,tm.D),cf*CFrame.new(0,.8,0));belt:SetAttribute('TreadmillBelt',true);belt:SetAttribute('Owner',p.UserId)
 for _,side in {-1,1} do P.Solid(m,'TreadmillRail',Vector3.new(.6,3.4,12),cf*CFrame.new(side*3.8,1.7,0)) end
 P.Solid(m,'TreadmillConsole',Vector3.new(7,2,1),cf*CFrame.new(0,7,-5.6))
 H.Treadmills[p]=m
end
local function refresh(p,d)
 local plot=P.Assigned[p];if not plot then return end
 local index=look(R.Level(d));local changed=plot.Look~=index
 H.SetLook(plot,index);nameHouse(plot,p.DisplayName);showcase(plot,d)
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
 local plot=P.Assigned[p];if plot then showTimer(p,plot,R.Remaining(d));showcase(plot,d) end
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
  if plot.ShowFolder then plot.ShowFolder:Destroy();plot.ShowFolder=nil;plot.ShowKey=nil end
  H.SetLook(plot,1);nameHouse(plot,nil)
 end
end
function H.Init() for _,plot in ipairs(P.Plots) do H.SetLook(plot,1) end end
return H
