-- World layout. Gameplay still runs on the same invisible parts and coordinates as before;
-- everything visible is decoration spawned from the art library.
local P = { Assigned = {}, Plots = {}, Lights = {} }
local S = game.ReplicatedStorage.Shared
local CollectionService = game:GetService("CollectionService")
local C = require(S.Config.ZoneConfig)
local Color = require(S.Palette)
local Art = require(S.ArtKit)
local Garden = require(S.GardenEnvironment)

local LAWN_TOP = -0.5
local ISLAND_TOP = -0.5
local PLAZA_TOP = 0.5
local SEA_LEVEL = -14

function P.Part(parent, name, size, cf, color, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	p.Parent = parent
	return p
end

local function solid(parent, name, size, cf)
	local p = P.Part(parent, name, size, cf, Color3.new(1, 1, 1))
	p.Transparency = 1
	p.CastShadow = false
	return p
end

local function solidDisc(parent, name, radius, height, cf)
	-- Roblox cylinders run along X, hence the roll.
	local disc = solid(parent, name, Vector3.new(height, radius * 2, radius * 2), cf * CFrame.Angles(0, 0, math.pi / 2))
	disc.Shape = Enum.PartType.Cylinder
	return disc
end

-- Text on a sign. The client fills it in the player's language from the LocKey attribute.
local function signText(parent, cf, size, key, color)
	local carrier = Instance.new("Part")
	carrier.Name = "SignText"
	carrier.Size = size
	carrier.CFrame = cf
	carrier.Transparency = 1
	carrier.Anchored, carrier.CanCollide, carrier.CanTouch, carrier.CanQuery = true, false, false, false
	carrier.CastShadow = false
	carrier.Parent = parent
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 42
	gui.LightInfluence = 0.3
	gui.Parent = carrier
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = color or Color.Ink
	label.TextScaled = true
	label.TextWrapped = true
	label.AutoLocalize = false
	label.Font = Enum.Font.GothamBlack
	label.Text = ""
	if key then
		label:SetAttribute("LocKey", key)
	end
	label.Parent = gui
	return label, carrier
end

P.SignText = signText
P.Solid = solid
P.PlazaTop = PLAZA_TOP

local function addLantern(parent, cf)
	local parts = Art.Spawn("W_Lantern", parent, cf)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 228, 170)
	light.Range = 15
	light.Brightness = 0.35
	light.Parent = parts.Bulb
	require(S.WorldArt).NightLight(light)
end

-- Toggled by the day/night loop in Main.
function P.SetNight(night)
	workspace:SetAttribute("IsNight", night)
	for _, light in ipairs(CollectionService:GetTagged("NightLight")) do
		light.Enabled = night
	end
	for _, part in ipairs(CollectionService:GetTagged("NightGlow")) do
		part.Material = night and Enum.Material.Neon or Enum.Material.SmoothPlastic
	end
end

-- A closed outline around the island and the road extension. The opening in
-- the island wall is cut at the road edges, not by skipping approximate segments.
local function buildBoundary(w)
 local road = require(S.Config.RoadConfig)
 local cfg = C.Boundary
 local radius = 170 * C.IslandScale - cfg.Inset
 local half = road.Width / 2 + cfg.Thickness / 2
 local dir = road.Dir.Unit
 local right = Vector3.new(-dir.Z, 0, dir.X)
 local opening = math.asin(half / radius)
 local bottom = -4
 local wall = Instance.new("Model")
 wall.Name = "MapBoundary"
 wall:SetAttribute("Radius", radius)
 wall:SetAttribute("WallTop", bottom + cfg.Height)
 wall.Parent = w
 -- Every stretch has one invisible collider as tall as the old wall, so nobody jumps out.
 local function collider(a, b, cf, length)
  local body = P.Part(wall, "BoundaryWall", Vector3.new(cfg.Thickness, cfg.Height, length + .4), cf * CFrame.new(0, bottom + cfg.Height / 2, 0), Color3.fromHex("625474"))
  body.Transparency = 1
  body.CanTouch = false
  body.CastShadow = false
 end
 -- Round the island the wall you see is low and friendly: three courses of lilac blocks laid like bricks,
 -- a purple coping and battlements on top, a green tuft here and there.
 local stones = { Color3.fromHex("DCD2F2"), Color3.fromHex("CDC1EA"), Color3.fromHex("E7DEF7"), Color3.fromHex("C2B5E2") }
 local course = 3.2
 local COURSES = 6 -- about 20 studs of wall: you can't see over it from the island
 local rng = Random.new(77)
 local function voxel(name, size, cf, color)
  local q = P.Part(wall, name, size, cf, color)
  q.Material = Enum.Material.SmoothPlastic
  q.CanCollide, q.CanQuery, q.CanTouch = false, false, false
  return q
 end
 local function segment(a, b, visible)
  local length = (b - a).Magnitude
  local cf = CFrame.lookAt((a + b) / 2, b)
  collider(a, b, cf, length)
  if not visible then
   return -- along the road the road's own walls are what you see; a second face there flickers
  end
  local count = math.max(2, math.round(length / 4.4))
  local block = length / count
  for row = 0, COURSES - 1 do
   local shift = row % 2 == 1 and block / 2 or 0
   for k = 0, count - 1 do
    local from = -length / 2 + k * block + shift
    local size = block - 0.18
    if row % 2 == 1 and k == count - 1 then
     size = block / 2 - 0.18 -- the shifted course ends in a half block
    end
    local z = from + size / 2 + 0.09
    voxel("WallBlock", Vector3.new(cfg.Thickness + rng:NextNumber(-0.15, 0.15), course - 0.12, size), cf * CFrame.new(0, bottom + 2.6 + row * course + course / 2, z), stones[rng:NextInteger(1, #stones)])
    if row % 2 == 1 and k == 0 then
     voxel("WallBlock", Vector3.new(cfg.Thickness, course - 0.12, block / 2 - 0.18), cf * CFrame.new(0, bottom + 2.6 + row * course + course / 2, -length / 2 + block / 4), stones[rng:NextInteger(1, #stones)])
    end
   end
  end
  local top = bottom + 2.6 + COURSES * course
  voxel("WallCoping", Vector3.new(cfg.Thickness + 0.8, 0.7, length + 0.2), cf * CFrame.new(0, top + 0.35, 0), Color3.fromHex("8C6BD6"))
  for k = 0, count - 1, 2 do
   local z = -length / 2 + (k + 0.5) * block
   voxel("WallMerlon", Vector3.new(cfg.Thickness + 0.4, 2, block * 0.8), cf * CFrame.new(0, top + 1.7, z), Color3.fromHex("A58BE6"))
   if rng:NextNumber() < 0.25 then
    local tuft = voxel("WallTuft", Vector3.new(1.4, 1.4, 1.4), cf * CFrame.new(rng:NextNumber(-0.6, 0.6), top + 3, z), Color3.fromHex("7BDC4B"))
    tuft.Shape = Enum.PartType.Ball
   end
  end
 end
 local function point(angle)
  return (dir * math.cos(angle) + right * math.sin(angle)) * radius
 end
 for i = 1, cfg.Segments do
  local a = opening + (2 * math.pi - 2 * opening) * (i - 1) / cfg.Segments
  local b = opening + (2 * math.pi - 2 * opening) * i / cfg.Segments
  segment(point(a), point(b), true)
 end
 local join = math.sqrt(radius * radius - half * half)
 local finish = road.Rim + road.Length + cfg.Thickness / 2
 for _, side in ipairs({-1, 1}) do
  -- Visible up to the road's first buildings, so there is no gap; past them the road's own walls show
  segment(dir * join + right * half * side, dir * road.Rim + right * half * side, true)
  segment(dir * road.Rim + right * half * side, dir * finish + right * half * side, false)
 end
 segment(dir * finish - right * half, dir * finish + right * half, false)
end

-- Voxel bump overlay on a face of a part (works on invisible parts too). The owner wants the play area
-- to keep its smooth cartoon grass, so nothing on the island uses it; it is here for the ruins.
local function studs(part, face, transparency)
	local W = require(S.Config.WorldConfig)
	local t = Instance.new("Texture")
	t.Name = "Studs"
	t.Texture = W.StudTexture
	t.Face = face or Enum.NormalId.Top
	t.StudsPerTileU, t.StudsPerTileV = W.StudTile, W.StudTile
	t.Transparency = transparency or 0.1
	t.Parent = part
	return t
end
local function studLayer(parent, name, size, cf)
	local q = P.Part(parent, name, size, cf, Color3.new(1, 1, 1))
	q.Transparency, q.CanCollide, q.CanQuery, q.CanTouch, q.CastShadow = 1, false, false, false, false
	studs(q)
	return q
end

-- The reference hub uses a low stone promenade around an open lawn.
-- Garden V4 tiles share the original promenade footprint and collider.
local function decoratePlaza(w)
	local folder=Instance.new('Model');folder.Name='PlazaDecor';folder.Parent=w
	local function deco(name,size,cf,color,shape,material)
		local q=P.Part(folder,name,size,cf,Color3.fromHex(color),shape)
		q.Material=material or Enum.Material.SmoothPlastic
		q.CanCollide,q.CanTouch,q.CanQuery,q.CastShadow=false,false,false,false
		return q
	end
	local function disc(name,radius,height,y,color)
		return deco(name,Vector3.new(height,radius*2,radius*2),CFrame.new(0,y,0)*CFrame.Angles(0,0,math.pi/2),color,Enum.PartType.Cylinder)
	end
	disc('StoneBed',41,.65,PLAZA_TOP-.38,'D5AE75')
	Garden.Promenade(Art,folder,PLAZA_TOP)
	-- A flat shared collider lies beneath the lawn and paving; no raised lip to catch feet.
	Garden.ApplyGrass(disc('HubLawn',24.4,.15,PLAZA_TOP+.075,'91A62E'))
	for i=0,71 do
		local a=(i+.5)*math.pi*2/72
		local at=CFrame.new(math.sin(a)*40.8,PLAZA_TOP-.02,math.cos(a)*40.8)*CFrame.Angles(0,a,0)
		deco('StoneKerb',Vector3.new(3.48,.75,1.35),at,i%3==0 and 'F4D8A3' or 'E9C489')
	end
	local colors={'FF668C','FFD85D','83E88A','59CBF5','B388F5','FFA657'}
	local tops={}
	-- Offset the poles from the farm paths; cords stay above jumping players.
	for i=0,13 do
		local a=(i+.5)*math.pi*2/14
		local base=Vector3.new(math.sin(a)*40.1,PLAZA_TOP,math.cos(a)*40.1)
		deco('FestivalPole',Vector3.new(.55,8.5,.55),CFrame.new(base+Vector3.new(0,4.25,0)),'7741BA')
		deco('PoleFoot',Vector3.new(.35,1.5,1.5),CFrame.new(base+Vector3.new(0,.15,0))*CFrame.Angles(0,0,math.pi/2),'9655D6',Enum.PartType.Cylinder)
		local bulb=require(S.WorldArt).NightGlow(deco('PoleLantern',Vector3.new(1.25,1.25,1.25),CFrame.new(base+Vector3.new(0,8.8,0)),'FFF18A',Enum.PartType.Ball,Enum.Material.Neon))
		if i%2==0 then
			local light=Instance.new('PointLight');light.Color=Color3.fromHex('FFE9AF');light.Range=17;light.Brightness=.65;light.Parent=bulb;require(S.WorldArt).NightLight(light)
		end
		table.insert(tops,base+Vector3.new(0,8.5,0))
	end
	for i,a in tops do
		local b=tops[i%#tops+1];local previous=a
		for j=1,8 do
			local t=j/8;local point=a:Lerp(b,t)-Vector3.new(0,math.sin(t*math.pi)*.85,0)
			deco('GarlandCord',Vector3.new(.07,.07,(point-previous).Magnitude),CFrame.lookAt((point+previous)/2,point),'FFF4D9')
			local mid=(previous+point)/2
			if j%2==0 then
				require(S.WorldArt).NightGlow(deco('GarlandBulb',Vector3.new(.34,.48,.34),CFrame.new(mid-Vector3.new(0,.25,0)),'FFF09B',Enum.PartType.Ball,Enum.Material.Neon))
			else
				local flag=deco('FestivalFlag',Vector3.new(.85,.95,.06),CFrame.lookAt(mid,mid+(b-a):Cross(Vector3.yAxis).Unit)*CFrame.new(0,-.48,0),colors[(i+j)%#colors+1])
				CollectionService:AddTag(flag,'ArtSway')
			end
			previous=point
		end
	end
	-- Sparse flowers on the inner verge preserve the open middle and every approach.
	for _,degrees in {60,82,102,120,240,258,278,300} do
		local a=math.rad(degrees);Art.Spawn('W_Flowers',folder,CFrame.new(math.sin(a)*24.8,PLAZA_TOP,math.cos(a)*24.8),{scale=.45})
	end
	local ring=deco('FountainRing',Vector3.one,CFrame.new(0,PLAZA_TOP+.22,0),'79FF86');ring.Transparency=1
	ring:SetAttribute('DisplayRing',true);ring:SetAttribute('Radius',9.4)
	local spout=deco('FountainSpout',Vector3.one,CFrame.new(0,PLAZA_TOP+8.2,0),'8EFF75');spout.Transparency=1
	local jet=Instance.new('ParticleEmitter');jet.Name='SlimeMist';jet.Color=ColorSequence.new(Color3.fromHex('BEFF97'),Color3.fromHex('63E86B'));jet.LightEmission=.3
	jet.Size=NumberSequence.new(.18,.04);jet.Lifetime=NumberRange.new(.65,1);jet.Rate=12;jet.Speed=NumberRange.new(2,3);jet.SpreadAngle=Vector2.new(25,25);jet.Acceleration=Vector3.new(0,-8,0);jet.Parent=spout
end

local function buildWorld(w)
	-- Sea, island, plaza
	for gridX = -1, 1 do
		for gridZ = -1, 1 do
			local sea = P.Part(w, "Sea", Vector3.new(2048, 1, 2048), CFrame.new(gridX * 2048, SEA_LEVEL - 0.5, gridZ * 2048), Color.Sea)
			sea.Material = Enum.Material.SmoothPlastic
			sea.CanCollide, sea.CanQuery, sea.CanTouch, sea.CastShadow = false, false, false, false
		end
	end
	local grow = C.IslandScale
	Art.Spawn("W_Foam", w, CFrame.new(0, SEA_LEVEL + 0.05, 0), { scale = Vector3.new(grow, 1, grow) })
	Art.Spawn("W_Island", w, CFrame.new(0, ISLAND_TOP, 0), { scale = Vector3.new(grow, 1, grow) })
	solidDisc(w, "Island", 170 * grow, 4, CFrame.new(0, ISLAND_TOP - 2, 0))
	Garden.Lawn(w,170*grow-2,ISLAND_TOP+.015)
	decoratePlaza(w)
	solidDisc(w, "Plaza", 41, 2, CFrame.new(0, PLAZA_TOP - 1, 0))
	buildBoundary(w)




	-- Slime fountain
	Art.Spawn("W_Fountain", w, CFrame.new(0, PLAZA_TOP+.15, 0))
	solidDisc(w, "FountainBase", 7.4, 2.4, CFrame.new(0, PLAZA_TOP + 1.2, 0))


	-- Scenery between the farms, placed from a fixed seed so every server looks the same
	local rng = Random.new(1729)
	local RoadC = require(S.Config.RoadConfig)
	local function insidePlot(pos)
		-- the road to the ruins runs between two farms
		local roadDir = RoadC.Dir.Unit
		local roadAlong = pos:Dot(roadDir)
		local lateral = (pos - roadDir * roadAlong).Magnitude
		if roadAlong > 20 and lateral < 14 then
			return true -- the walkway from the plaza to the gate
		end
		if roadAlong > RoadC.Rim - 40 and lateral < RoadC.Width / 2 + 8 then
			return true -- the clearing in front of the gate
		end
		for i = 1, 6 do
			local a = math.rad(C.PlotAngles[i])
			local c = Vector3.new(math.sin(a) * C.PlotRadius, 0, math.cos(a) * C.PlotRadius)
			local v = CFrame.lookAt(c, Vector3.zero):PointToObjectSpace(pos)
			if math.abs(v.X) < C.FarmHalf + 3 and v.Z > -C.FarmHalf - 3 and v.Z < C.FarmHalf + 3 then
				return true
			end
			-- keep the walkway from the plaza to each gate clear
			local toGate = c.Unit
			local along = pos:Dot(toGate)
			if along > 30 and along < C.PlotRadius - 20 and (pos - toGate * along).Magnitude < 9 then
				return true
			end
		end
		return false
	end
	local function scatter(name, count, minR, maxR, minScale, maxScale)
		local placed, tries = 0, 0
		while placed < count and tries < count * 40 do
			tries += 1
			local a, r = rng:NextNumber(0, math.pi * 2), rng:NextNumber(minR, maxR)
			local pos = Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
			if not insidePlot(pos) then
				local scale = rng:NextNumber(minScale, maxScale)
				Art.Spawn(name, w, CFrame.new(pos.X, ISLAND_TOP - 0.05, pos.Z) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0), { scale = scale })
				placed += 1
			end
		end
	end
	local edge = 170 * grow - C.Boundary.Inset - 12
	scatter("W_TreeA", 26, 60, edge, 0.85, 1.25)
	scatter("W_TreeB", 15, 60, edge, 0.85, 1.2)
	task.wait()
	scatter("W_Bush", 32, 50, edge, 0.8, 1.3)
	scatter("W_Rock", 20, 55, edge, 0.7, 1.5)
	scatter("W_Mushroom", 26, 48, edge, 0.8, 1.6)
	scatter("W_Flowers", 38, 46, edge, 1.3, 2)
	task.wait()
	scatter("W_Tuft", 64, 44, edge, 1, 1.8)
	-- Friendly spooky trees: placed by hand so their faces look toward the plaza.
	for i = 1, 6 do
		local a = (i - 0.5) * math.pi / 3
		for _, r in ipairs(i == 1 and {} or { 62, 118 }) do -- the first gap is the road's
			local pos = Vector3.new(math.sin(a) * r, ISLAND_TOP - 0.05, math.cos(a) * r)
			if not insidePlot(Vector3.new(pos.X,0,pos.Z)) then Art.Spawn("W_TreeC", w, CFrame.lookAt(pos, Vector3.new(0, pos.Y, 0)), { scale = 1.25 }) end
		end
	end

	-- Clouds, drifted slowly by the client
	for i = 1, 10 do
		local a = i / 10 * math.pi * 2 + rng:NextNumber(0, 0.4)
		local r = rng:NextNumber(210, 380)
		local parts = Art.Spawn("W_Cloud", w, CFrame.new(math.cos(a) * r, rng:NextNumber(55, 105), math.sin(a) * r) * CFrame.Angles(0, a, 0), { scale = rng:NextNumber(0.9, 1.7) })
		CollectionService:AddTag(parts.Main, "ArtCloud")
	end

	-- The walkway from the plaza to the ruins gate in the island wall
	do
		local dir = RoadC.Dir.Unit
		local start = dir * 41 + Vector3.new(0, ISLAND_TOP, 0)
		local side = Vector3.new(dir.Z, 0, -dir.X) * 8
		for k = 0, math.ceil((RoadC.Rim - 41) / 22.5) - 1 do
			Art.Spawn("W_Path", w, CFrame.lookAt(start + dir * (k * 22.5), start + dir * (k * 22.5) - dir))
			local spot = start + dir * (12 + k * 22.5)
			addLantern(w, CFrame.lookAt(spot + (k % 2 == 0 and side or -side), spot))
		end
	end
	-- Stepping stones from the plaza to every farm, each with a lantern
	for i = 1, 6 do
		local a = math.rad(C.PlotAngles[i])
		local dir = Vector3.new(math.sin(a), 0, math.cos(a))
		local start = dir * 41 + Vector3.new(0, ISLAND_TOP, 0)
		local side = Vector3.new(dir.Z, 0, -dir.X) * 7
		for k = 0, math.ceil((C.PlotRadius - C.FarmHalf - 41) / 22.5) - 1 do
			Art.Spawn("W_Path", w, CFrame.lookAt(start + dir * (k * 22.5), start + dir * (k * 22.5) - dir))
			local spot = start + dir * (12 + k * 22.5)
			local across = k % 2 == 0 and side or -side
			addLantern(w, CFrame.lookAt(spot + across, spot))
		end
	end
end

-- An undead crypt on every farm: a stepped stone vault under arching bone ribs, a skull over a glowing door
-- and a soul orb on top. Built from blocks, voxel style. Stored zombies live here; its ring opens the crypt menu.
local function buildCrypt(m, base)
	local PC = require(S.Config.PlacementConfig).Crypt
	local c = base * CFrame.new(PC.X, LAWN_TOP, PC.Z)
	local model = Instance.new("Model")
	model.Name = "Crypt"
	model.Parent = m
	local stone, dark, bone, glow, void = Color3.fromHex("4A3F66"), Color3.fromHex("2C2440"), Color3.fromHex("EDE3C8"), Color3.fromHex("8CFF6A"), Color3.fromHex("140F1F")
	local function block(name, size, cf, color, material)
		local q = P.Part(model, name, size, c * cf, color)
		q.Material = material or Enum.Material.Slate
		q.CanCollide = false
		q.CanTouch = false
		return q
	end
	local smooth, neon = Enum.Material.SmoothPlastic, Enum.Material.Neon
	block("Plinth", Vector3.new(18, 1, 15), CFrame.new(0, 0.5, 0), dark)
	block("TierLow", Vector3.new(14, 5, 11.5), CFrame.new(0, 3.5, 0.5), stone)
	block("TrimLow", Vector3.new(14.6, 0.6, 12.1), CFrame.new(0, 6.1, 0.5), dark)
	block("TierMid", Vector3.new(10, 4, 8.5), CFrame.new(0, 8.4, 1), stone)
	block("TrimMid", Vector3.new(10.6, 0.6, 9.1), CFrame.new(0, 10.5, 1), dark)
	block("TierTop", Vector3.new(6, 3, 5.5), CFrame.new(0, 12.3, 1.2), stone)
	block("Spire", Vector3.new(1.4, 3, 1.4), CFrame.new(0, 15.3, 1.2), bone, smooth)
	local orb = block("SoulOrb", Vector3.new(2.4, 2.4, 2.4), CFrame.new(0, 17.8, 1.2), glow, neon)
	orb.Shape = Enum.PartType.Ball
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness = glow, 20, 1.6
	light.Parent = orb
	require(S.WorldArt).NightLight(light)
	-- Door with a green glow, a skull above it, glowing eyes
	block("Doorway", Vector3.new(4.4, 5.2, 0.4), CFrame.new(0, 3.6, -5.35), void, smooth)
	for _, x in { -2.5, 2.5 } do
		block("DoorGlow", Vector3.new(0.35, 5.4, 0.3), CFrame.new(x, 3.7, -5.5), glow, neon)
	end
	block("DoorGlowTop", Vector3.new(5.3, 0.35, 0.3), CFrame.new(0, 6.45, -5.5), glow, neon)
	block("Skull", Vector3.new(3.2, 2.8, 2.4), CFrame.new(0, 8.6, -3.9), bone, smooth)
	block("Jaw", Vector3.new(2.2, 0.9, 1.8), CFrame.new(0, 6.9, -4.1), bone, smooth)
	for _, x in { -0.75, 0.75 } do
		block("EyeSocket", Vector3.new(0.9, 0.8, 0.3), CFrame.new(x, 8.8, -5.15), void, smooth)
		block("EyeGlow", Vector3.new(0.35, 0.35, 0.2), CFrame.new(x, 8.8, -5.33), glow, neon)
	end
	-- Bone ribs arching over the vault, three on each side
	for _, side in { -1, 1 } do
		for _, z in { -3.5, 0.5, 4.5 } do
			block("RibBase", Vector3.new(1.1, 6, 1.1), CFrame.new(side * 8.2, 4, z) * CFrame.Angles(0, 0, side * 0.15), bone, smooth)
			block("RibBend", Vector3.new(1, 4, 1), CFrame.new(side * 6.7, 8.7, z) * CFrame.Angles(0, 0, side * 0.55), bone, smooth)
			block("RibTip", Vector3.new(0.8, 2.6, 0.8), CFrame.new(side * 4.5, 11.05, z) * CFrame.Angles(0, 0, side * 1.05), bone, smooth)
		end
		block("Rune", Vector3.new(0.25, 2.2, 0.8), CFrame.new(side * 7.05, 3.8, -2), glow, neon)
	end
	-- Mist creeping out of the door
	local mistPart = block("Mist", Vector3.new(4, 0.2, 2), CFrame.new(0, 0.9, -6.5), glow, smooth)
	mistPart.Transparency = 1
	local mist = Instance.new("ParticleEmitter")
	mist.Color = ColorSequence.new(glow)
	mist.LightEmission = 0.4
	mist.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.75), NumberSequenceKeypoint.new(1, 1) })
	mist.Size = NumberSequence.new(1.5, 3)
	mist.Lifetime = NumberRange.new(1.5, 2.5)
	mist.Rate = 6
	mist.Speed = NumberRange.new(0.6, 1.2)
	mist.SpreadAngle = Vector2.new(60, 20)
	mist.EmissionDirection = Enum.NormalId.Front
	mist.Parent = mistPart
	-- One solid block so nobody walks into the vault, and the menu ring in front of the door
	solid(model, "CryptBlock", Vector3.new(15, 12, 12), c * CFrame.new(0, 6, 0.6))
	local zone = P.Part(model, "CryptZone", Vector3.one, c * CFrame.new(0, 0.15, -10), glow)
	zone.Transparency, zone.CanCollide, zone.CanQuery, zone.CanTouch = 1, false, false, false
	zone:SetAttribute("MenuZone", "crypt")
	zone:SetAttribute("Radius", 4.5)
	zone:SetAttribute("Owner", -1)
	return { Model = model, Zone = zone, Door = c * CFrame.new(0, 3, -6.5) }
end

local function buildPlot(w,i)
 local H=C.FarmHalf;local F=H-1
 local PC=require(S.Config.PlacementConfig)
 local angle=math.rad(C.PlotAngles[i]);local pos=Vector3.new(math.sin(angle)*C.PlotRadius,0,math.cos(angle)*C.PlotRadius)
 local m=Instance.new('Model');m.Name='Plot'..i;m.Parent=w
 local base=CFrame.lookAt(pos,Vector3.zero);local plot={Model=m,Base=base,Index=i};P.Plots[i]=plot
 local function at(x,z,y) return base*CFrame.new(x,y or LAWN_TOP,z) end
 local function deco(asset,x,z,scale) return Art.Spawn(asset,m,at(x,z),{scale=scale or 1}) end
 solid(m,'Lawn',Vector3.new(2*H,1,2*H),at(0,0,LAWN_TOP-.5))
 -- Cemetery, back left: a stone-rimmed purple patch with the crypt at its back
 local cb=PC.Cemetery
 local cemetery=Instance.new('Model');cemetery.Name='Cemetery';cemetery.Parent=m
 Art.Spawn('W_Graveyard',cemetery,at((cb.MinX+cb.MaxX)/2,(cb.MinZ+cb.MaxZ)/2,LAWN_TOP+.03),{scale=Vector3.new((cb.MaxX-cb.MinX+1)/26,.35,(cb.MaxZ-cb.MinZ+1)/24),tints={Main=Color3.fromRGB(173,145,204)}})
 plot.Crypt=buildCrypt(m,base)
 local pc=PC.Crypt
 local cryptBase=at(pc.X,pc.Z)
 plot.Crypt.Model.WorldPivot=cryptBase;plot.Crypt.Model:ScaleTo(.6)
 local cryptFacing=cryptBase*CFrame.Angles(0,math.rad(pc.Yaw),0)
 plot.Crypt.Model:PivotTo(cryptFacing)
 local zone=plot.Crypt.Zone;zone.Size=Vector3.one;zone.CFrame=cryptFacing*CFrame.new(0,.15,-pc.Door);zone:SetAttribute('Radius',3.2)
 plot.Crypt.Door=cryptFacing*CFrame.new(0,1.65,-3.9)
 -- Wooden rails and stone posts; the income area remains an open lawn.
 local function fence(a,b)
  local v=b-a;local length=v.Magnitude;local center=(a+b)/2
  if length<.5 then return end
  local n=math.max(1,math.ceil(length/8))
  for j=1,n do local q=a:Lerp(b,(j-.5)/n);Art.Spawn('W_Fence',m,base*CFrame.lookAt(q+Vector3.new(0,LAWN_TOP,0),q+Vector3.new(v.Z,LAWN_TOP,-v.X)),{scale=Vector3.new(length/n/8,1,1)}) end
  solid(m,'Fence',Vector3.new(.6,3,length),base*CFrame.lookAt(center+Vector3.new(0,LAWN_TOP+1.5,0),b+Vector3.new(0,LAWN_TOP+1.5,0)))
 end
 local function seg(x1,z1,x2,z2) fence(Vector3.new(x1,0,z1),Vector3.new(x2,0,z2)) end
 local HC=require(S.Config.HouseConfig)
 -- The house closes the back-right corner at 45 degrees: both fences stop where its back corners touch them
 local cut=(HC.Looks[1].W+2)/math.sqrt(2)
 seg(7,-F,F,-F);seg(F,-F,F,F);seg(F,F,-F+cut,F);seg(-F,F-cut,-F,-F);seg(-F,-F,-7,-F)
 -- Each rail mesh includes its end post. Cap the two open starts only.
 deco('W_FencePost',7,-F);deco('W_FencePost',-F,F-cut)
 local pb=PC.Pen -- Preserve existing zombie income positions.
 -- Gate arch with the owner's name
 plot.Gate=P.Part(m,'Gate',Vector3.new(12,.1,5),at(0,-F+2,LAWN_TOP+.05),Color.Grass or Color3.fromHex('86CF4B'));plot.Gate.Transparency=1
 plot.Barrier=P.Part(m,'Barrier',Vector3.new(14,7,1),at(0,-F-1,3),Color.Pink);plot.Barrier.Material=Enum.Material.ForceField;plot.Barrier.Transparency=1;plot.Barrier.CanCollide=false
 deco('W_GateArch',0,-F,.85)
 plot.Label=signText(m,at(0,-F-.6,6.4),Vector3.new(8,1.5,.1),nil)
 plot.LabelBack=signText(m,at(0,-F+.6,6.4)*CFrame.Angles(0,math.pi,0),Vector3.new(8,1.5,.1),nil)
 plot.Label:SetAttribute('OwnerPlate',true);plot.LabelBack:SetAttribute('OwnerPlate',true)
 -- Stepping stones: gate straight to the house door, branches to the cemetery and the treadmill
 local laidStones={}
 local function path(ax,az,bx,bz)
  local a=Vector3.new(ax,0,az);local b=Vector3.new(bx,0,bz)
  local distance=(b-a).Magnitude
  if distance<.01 then return end
  local direction=(b-a).Unit;local n=math.ceil(distance/3.5);local step=distance/n
  for j=0,n do
   local v=a:Lerp(b,j/n);local duplicate=false
   for _,previous in laidStones do if (v-previous).Magnitude<1.65 then duplicate=true;break end end
   if not duplicate then
    table.insert(laidStones,v)
    local p=Vector3.new(v.X,LAWN_TOP+.035,v.Z)
    local parts=Art.Spawn('ENV_Tile'..(1+#laidStones%3),m,base*CFrame.lookAt(p,p+direction),{scale=Vector3.new(.94,.55,step*.97/3.8)})
    for _,stone in parts do stone.Name='PathStone';stone.CastShadow=false end
   end
  end
 end
 local doorReach=(HC.Looks[1].D/2+2.5)/math.sqrt(2)
 path(0,-F,0,0);path(0,0,HC.RoomX+doorReach,HC.RoomZ-doorReach);path(0,-24,21,-24)
 local pcr=PC.Crypt;local cryptDoor=Vector3.new(pcr.X,0,pcr.Z)-Vector3.new(math.sin(math.rad(pcr.Yaw)),0,math.cos(math.rad(pcr.Yaw)))*(pcr.Door+1)
 path(0,-2,cb.MinX,6);path(cb.MinX,6,cryptDoor.X,cryptDoor.Z)
 -- A softer cemetery edge: tufts, mushrooms and flowers round the patch
 for _,q in {{cb.MinX-1.5,cb.MaxZ-3,'W_Mushroom',1.2},{cb.MaxX+1.5,cb.MinZ+4,'W_Tuft',1.6},{cb.MaxX+1,cb.MaxZ+1,'W_Mushroom',1.4},{cb.MinX+4,cb.MaxZ+1.5,'W_Tuft',1.4},{cb.MaxX+1.5,(cb.MinZ+cb.MaxZ)/2,'W_Flowers',1.1},{cb.MinX-1.5,cb.MinZ+10,'W_Flowers',1}} do deco(q[3],q[1],q[2],q[4]) end
 local guideCemetery=P.Part(m,'GuideCemetery',Vector3.one,at((cb.MinX+cb.MaxX)/2,cb.MinZ+8,1),Color.Panel);guideCemetery.Transparency=1;guideCemetery.CanCollide=false;guideCemetery.CanQuery=false
 for _,q in {{-38,38},{-20,38},{38,-38},{-38,-38+2},{12,-2},{-12,4}} do deco('W_Flowers',q[1],q[2],.8) end
 local field=P.Part(m,'GuideField',Vector3.one,at((pb.MinX+pb.MaxX)/2,(pb.MinZ+pb.MaxZ)/2,1),Color.Panel);field.Transparency=1;field.CanCollide=false;field.CanQuery=false
 local guard=P.Part(m,'GuideGuard',Vector3.one,at(6,30,1),Color.Panel);guard.Transparency=1;guard.CanCollide=false;guard.CanQuery=false
 m:SetAttribute('BasePosition',base.Position);m:SetAttribute('BaseYaw',math.atan2(-base.LookVector.X,-base.LookVector.Z))
end

function P.Build()
	local old = workspace:FindFirstChild("DigAZombie")
	if old then
		old:Destroy()
	end
	Art.Preload()
	local w = Instance.new("Folder")
	w.Name = "DigAZombie"
	w.Parent = workspace
	P.World = w
	buildWorld(w)
	for i = 1, 6 do
		buildPlot(w, i)
		task.wait()
	end
	-- Everyone is teleported home on spawn; the pad itself and its force-field bubble should not show.
	local spawn = workspace:FindFirstChildWhichIsA("SpawnLocation")
	if spawn then
		spawn.Position = Vector3.new(0, 3, 30)
		spawn.Neutral = true
		spawn.Duration = 0
		spawn.Transparency = 1
		spawn.CanCollide = false
		spawn.CastShadow = false
		for _, child in ipairs(spawn:GetChildren()) do
			if child:IsA("Decal") then
				child:Destroy()
			end
		end
	end
end

function P.Assign(p)
	for _, plot in ipairs(P.Plots) do
		if not plot.Owner then
			plot.Owner = p
			P.Assigned[p] = plot
			plot.Model:SetAttribute("Owner", p.UserId)
			if plot.Crypt then plot.Crypt.Zone:SetAttribute("Owner", p.UserId) end
			plot.Label:SetAttribute("OwnerName", p.DisplayName)
			plot.LabelBack:SetAttribute("OwnerName", p.DisplayName)
			return plot
		end
	end
end

function P.Release(p)
	local plot = P.Assigned[p]
	if plot then
		plot.Owner = nil
		plot.Model:SetAttribute("Owner", nil)
		if plot.Crypt then plot.Crypt.Zone:SetAttribute("Owner", -1) end
		plot.Label:SetAttribute("OwnerName", nil)
		plot.LabelBack:SetAttribute("OwnerName", nil)
		for _, x in ipairs(plot.Model:GetChildren()) do
			if x.Name == "Grave" or x.Name == "Zombie" or x.Name == "Slots" then
				x:Destroy()
			end
		end
	end
	P.Assigned[p] = nil
end

function P.Position(p, zone, slot)
	local q = P.Assigned[p]
	if not q then
		return CFrame.new()
	end
	local Place = require(S.PlacementRules)
	local PC = require(S.Config.PlacementConfig)
	local x, z = 0, 0
	if zone == "Field" or zone == "Graves" or zone == "Guards" then
		-- Free placement: the profile holds each spot; the old cell is only a fallback.
		local d = require(script.Parent.DataService).Profiles[p]
		local spot
		for _, item in d and (zone == "Graves" and d.graves or d.zombies) or {} do
			if item.slot == slot and item.pos and (zone == "Graves" or item.zone == zone) then
				spot = item.pos
				break
			end
		end
		spot = spot or (zone=="Guards" and {x=PC.Guards[math.clamp(slot,1,#PC.Guards)].X,z=PC.Guards[math.clamp(slot,1,#PC.Guards)].Z}) or (zone=="Graves" and PC.GraveSpots[slot]) or Place.Legacy(zone, slot)
		x, z = spot.x, spot.z
	elseif zone == "Guards" then
		local post = PC.Guards[math.clamp(slot, 1, #PC.Guards)]
		x, z = post.X, post.Z
	else
		-- Crypt zombies are invisible stand-ins inside the crypt building.
		x, z = PC.Crypt.X, PC.Crypt.Z
	end
	return q.Base * CFrame.new(x, .6, z)
end

function P.Near(p, position, distance)
	local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	return r and (r.Position - position).Magnitude <= distance
end

function P.Inside(p, plot)
	local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	if not r then
		return false
	end
	local v = plot.Base:PointToObjectSpace(r.Position)
	return math.abs(v.X) <= C.FarmHalf + 1 and v.Z >= -C.FarmHalf - 1 and v.Z <= C.FarmHalf + 1
end

-- Players arrive just inside the gate, looking at their own farm instead of back at the plaza.
function P.Home(p)
	local q = P.Assigned[p]
	if q and p.Character then
		p.Character:PivotTo(q.Base * CFrame.new(0, 5, -20) * CFrame.Angles(0, math.pi, 0))
		if typeof(p) == "Instance" then
			p:SetAttribute("InHouse", false)
		end
	end
end

-- Set only by the server, when a player goes through their own door.
function P.InHouse(p)
	local plot=P.Assigned[p];local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
 if not plot or not root then return false end
 local v=plot.Base:PointToObjectSpace(root.Position)
 local hc=require(S.Config.HouseConfig);local scale=hc.Scale
 local hv=(CFrame.new(hc.RoomX,0,hc.RoomZ)*CFrame.Angles(0,math.rad(hc.RoomYaw or 0),0)):PointToObjectSpace(v)
 return math.abs(hv.X)<hc.RoomWidth*scale/2 and math.abs(hv.Z)<hc.RoomDepth*scale/2 and v.Y>hc.RoomY and v.Y<hc.RoomY+hc.Looks[plot.Look or 1].Tall*scale
end

return P
