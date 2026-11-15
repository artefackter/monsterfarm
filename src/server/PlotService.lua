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
 -- Round the island the wall is friendly: lilac blocks laid like bricks, a purple coping and battlements on top, a
 -- green tuft here and there. Taller since 2026-11-13 (owner: "raise the wall round the world"); a darker stone was
 -- tried the same day and taken back (owner: "bring back the old wall, at the new height").
 local stones = { Color3.fromHex("DCD2F2"), Color3.fromHex("CDC1EA"), Color3.fromHex("E7DEF7"), Color3.fromHex("C2B5E2") }
 -- Big stones since 2026-11-14 (performance: the wall was 3,500 parts): six courses of one block per segment (two
 -- halves on the shifted courses) instead of eleven courses of three; the same height.
 local COURSES = 6
 local course = 11 * 3.2 / COURSES
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
  local count = math.max(1, math.round(length / 12))
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
  local merlons = math.max(2, math.round(length / 4.4)) -- battlements keep their old rhythm
  local merlon = length / merlons
  for k = 0, merlons - 1, 2 do
   local z = -length / 2 + (k + 0.5) * merlon
   voxel("WallMerlon", Vector3.new(cfg.Thickness + 0.4, 2, merlon * 0.8), cf * CFrame.new(0, top + 1.7, z), Color3.fromHex("A58BE6"))
   if rng:NextNumber() < 0.25 then
    local tuft = voxel("WallTuft", Vector3.new(1.4, 1.4, 1.4), cf * CFrame.new(rng:NextNumber(-0.6, 0.6), top + 3, z), Color3.fromHex("7BDC4B"))
    tuft.Shape = Enum.PartType.Ball
   end
  end
 end
 local function point(angle)
  return (dir * math.cos(angle) + right * math.sin(angle)) * radius
 end
 -- A second opening right across from the road (2026-11-13): the walled bridge to the Blood Moon arena.
 local BM = require(S.Config.BloodMoonConfig)
 local g = BM.Arena.Gap + cfg.Thickness / 2
 local gapA = math.asin(g / radius)
 for _, range in { { opening, math.pi - gapA }, { math.pi + gapA, 2 * math.pi - opening } } do
  local n = math.max(1, math.round(cfg.Segments * (range[2] - range[1]) / (2 * math.pi)))
  for i = 1, n do
   segment(point(range[1] + (range[2] - range[1]) * (i - 1) / n), point(range[1] + (range[2] - range[1]) * i / n), true)
  end
 end
 -- the bridge's walls and the arena's round wall, open only towards the island
 local center = BM.ArenaCenter()
 local ring = BM.Arena.Radius + cfg.Thickness / 2
 local reach = center.Magnitude - math.sqrt(ring * ring - g * g)
 for _, side in ipairs({ -1, 1 }) do
  segment(-dir * math.sqrt(radius * radius - g * g) + right * g * side, -dir * reach + right * g * side, true)
 end
 local gb = math.asin(g / ring)
 local arenaSegments = 40
 for i = 1, arenaSegments do
  local a = gb + (2 * math.pi - 2 * gb) * (i - 1) / arenaSegments
  local b = gb + (2 * math.pi - 2 * gb) * i / arenaSegments
  -- colliders only: the arena's look is its amphitheatre of stands (buildBloodArena)
  segment(center + (dir * math.cos(a) + right * math.sin(a)) * ring, center + (dir * math.cos(b) + right * math.sin(b)) * ring, false)
 end
 wall:SetAttribute("BloodArena", center)
 local join = math.sqrt(radius * radius - half * half)
 local finish = road.Rim + road.Length + cfg.Thickness / 2
 for _, side in ipairs({-1, 1}) do
  -- Visible up to the road's first buildings, so there is no gap; past them the road's own walls show
  segment(dir * join + right * half * side, dir * road.Rim + right * half * side, true)
  -- Along the road: colliders in pieces. One 3900-stud part was clipped by Roblox to 2048 and, lying across the
  -- middle locations, shut the boss pockets there (owner, 2026-11-13: "you can't get to Patient Zero"); now each
  -- piece stays short, and there is a gap at every pocket on this side.
  local Pr = require(S.Config.RoadProgression)
  local cuts = {}
  for _, d in Pr.Districts do
   if d.PocketSide == side then table.insert(cuts, { d.DoorS - Pr.DoorWidth / 2, d.DoorS + Pr.DoorWidth / 2 }) end
  end
  table.sort(cuts, function(a, b) return a[1] < b[1] end)
  local s0 = 0
  local function run(a, b)
   local pieces = math.max(1, math.ceil((b - a) / 600))
   for k = 0, pieces - 1 do
    local p0, p1 = a + (b - a) * k / pieces, a + (b - a) * (k + 1) / pieces
    segment(dir * (road.Rim + p0) + right * half * side, dir * (road.Rim + p1) + right * half * side, false)
   end
  end
  for _, cut in cuts do
   if cut[1] > s0 then run(s0, cut[1]) end
   s0 = cut[2]
  end
  run(s0, finish - road.Rim)
 end
 segment(dir * finish - right * half, dir * finish + right * half, false)
end

-- The Blood Moon arena (owner, 2026-11-13): an amphitheatre of dark stone beyond the island wall, across from the
-- ruins road, reached over a cobbled bridge through a slot in its stands. A blood-red sand floor with the seal and
-- bone spikes round its edge, six tiers of stands rising all round, pale columns on top, and an arch over the
-- opening in the island wall with the arena's name. No lamps: the Blood Moon's own light is enough. Its colliders are
-- buildBoundary's; the giant appears in the middle and never leaves.
local function buildBloodArena(w)
 local BM = require(S.Config.BloodMoonConfig)
 local center = BM.ArenaCenter()
 local road = require(S.Config.RoadConfig)
 local dir = road.Dir.Unit
 local R, gap, tiers = BM.Arena.Radius, BM.Arena.Gap, BM.Arena.Tiers or 6
 local m = Instance.new("Model")
 m.Name = "BloodArena"
 m.Parent = w
 local function deco(name, size, cf, color, material, shape)
  local q = P.Part(m, name, size, cf, color, shape)
  q.Material = material or Enum.Material.SmoothPlastic
  q.CanCollide, q.CanQuery, q.CanTouch = false, false, false
  return q
 end
 local facing = CFrame.lookAt(center, center + dir) -- -Z looks back at the island
 local function at(x, y, z) return facing * CFrame.new(x, y, z) end
 -- The floors you walk on (solid, so navigation and grave drops find them). The bridge sits a little above the
 -- island's lawn surface: level with it, the two flickered against each other.
 local wallR = 170 * C.IslandScale - C.Boundary.Inset
 local from, to = wallR - 6, center.Magnitude - R + 4
 local bridge = P.Part(m, "BloodBridge", Vector3.new(gap * 2 + 4, 4, to - from), CFrame.lookAt(-dir * (from + to) / 2 + Vector3.new(0, ISLAND_TOP - 1.92, 0), -dir * to + Vector3.new(0, ISLAND_TOP - 1.92, 0)), Color3.fromHex("4A3F52"))
 bridge.Material = Enum.Material.Cobblestone
 local floor = solidDisc(m, "BloodFloor", R + 4, 4, CFrame.new(center.X, ISLAND_TOP - 1.92, center.Z))
 floor.Transparency = 0
 floor.Color = Color3.fromHex("3E2A33")
 floor.Material = Enum.Material.Slate
 local top = ISLAND_TOP + 0.08
 local function disc(name, radius, y, color, material)
  return deco(name, Vector3.new(0.06, radius * 2, radius * 2), CFrame.new(center.X, top + y, center.Z) * CFrame.Angles(0, 0, math.pi / 2), color, material, Enum.PartType.Cylinder)
 end
 disc("BloodRim", R + 2, 0.03, Color3.fromHex("2A1A22"))
 disc("BloodSand", R - 1, 0.05, Color3.fromHex("6B2A33"), Enum.Material.Sand)
 disc("BloodLine", R * 0.55, 0.06, Color3.fromHex("2A1A22"))
 disc("BloodSandInner", R * 0.55 - 1, 0.07, Color3.fromHex("7A303A"), Enum.Material.Sand)
 Art.Spawn("MR_ArenaSeal", m, CFrame.new(center.X, top + 0.08, center.Z), { scale = Vector3.new(6.5, 0.4, 6.5), tints = { Main = Color3.fromRGB(190, 60, 70) } })
 -- the way in faces the island (local -Z); stands and props keep out of it
 local function wayIn(x, z, margin)
  return z < 0 and math.abs(x) < gap + (margin or 4)
 end
 -- bone spikes in little clumps round the edge of the floor
 for k = 0, 13 do
  local a = (k + 0.5) / 14 * math.pi * 2
  local sx, sz = math.sin(a) * (R - 3), math.cos(a) * (R - 3)
  if not wayIn(sx, sz, 8) then
   for n = 0, 2 do
    deco("BoneSpike", Vector3.new(1.4, 8 - n * 1.8, 1.4), at(sx + (n - 1) * 1.8, top + (8 - n * 1.8) / 2, sz) * CFrame.Angles(0, 0, (n - 1) * 0.25), Color3.fromHex("E6DCC4"))
   end
  end
 end
 -- The stands: tiers of a round bowl, each a ring of blocks from below the floor up to its seat
 local stoneA, stoneB, cap = Color3.fromHex("4B3A55"), Color3.fromHex("3E2F48"), Color3.fromHex("6E2233")
 local segments = 32 -- was 64 (2026-11-14, performance)
 for k = 0, tiers - 1 do
  local r = R + 7 + k * 8
  local seat = 6 + k * 4
  local height = seat + 6
  for n = 0, segments - 1 do
   local t0, t1 = n / segments * math.pi * 2, (n + 1) / segments * math.pi * 2
   local tm = (t0 + t1) / 2
   local x, z = math.sin(tm) * r, math.cos(tm) * r
   local function clear(t) return not wayIn(math.sin(t) * r, math.cos(t) * r, 3 + k * 1.5) end -- ends too: long segments
   if clear(t0) and clear(tm) and clear(t1) then
    local p0, p1 = at(math.sin(t0) * r, 0, math.cos(t0) * r).Position, at(math.sin(t1) * r, 0, math.cos(t1) * r).Position
    local mid = at(x, top + seat - height / 2, z).Position
    deco("Stand", Vector3.new(8.6, height, (p1 - p0).Magnitude + 0.6), CFrame.lookAt(mid, mid + (p1 - p0)), k % 2 == 0 and stoneA or stoneB, Enum.Material.Slate)
    do
     local edge = at(math.sin(tm) * (r - 4.1), top + seat + 0.15, math.cos(tm) * (r - 4.1)).Position
     deco("StandEdge", Vector3.new(0.5, 0.3, (p1 - p0).Magnitude + 0.6), CFrame.lookAt(edge, edge + (p1 - p0)), cap)
    end
   end
  end
 end
 -- pale columns along the top row, a dark cap on each
 local rTop = R + 7 + tiers * 8
 local seatTop = 6 + (tiers - 1) * 4
 for n = 0, 15 do -- 16 columns, was 32 (2026-11-14)
  local t = (n + 0.5) / 16 * math.pi * 2
  local x, z = math.sin(t) * rTop, math.cos(t) * rTop
  if not wayIn(x, z, 14) then
   deco("Column", Vector3.new(3, 14, 3), at(x, top + seatTop + 7, z), Color3.fromHex("D9CFC0"), Enum.Material.Slate)
   deco("ColumnCap", Vector3.new(4.4, 1.2, 4.4), at(x, top + seatTop + 14.6, z), cap)
  end
 end
 -- the arch over the opening in the island wall, its name facing the island; set back from the wall so no face
 -- lies on a wall face (those flickered)
 local archAt = -dir * (wallR - 4.3)
 local archCF = CFrame.lookAt(archAt + Vector3.new(0, ISLAND_TOP, 0), archAt + dir + Vector3.new(0, ISLAND_TOP, 0)) -- -Z faces the island
 local stone, red = Color3.fromHex("4B3A55"), Color3.fromHex("8E1F35")
 for _, e in ipairs({ -1, 1 }) do
  deco("ArchTower", Vector3.new(8, 40, 8), archCF * CFrame.new(e * (gap + 6.3), 20, 0), stone, Enum.Material.Slate)
  deco("ArchTowerCap", Vector3.new(9.6, 1.6, 9.6), archCF * CFrame.new(e * (gap + 6.3), 40.8, 0), red)
  deco("ArchBanner", Vector3.new(5, 14, 0.3), archCF * CFrame.new(e * (gap + 6.3), 24, -4.2), red)
 end
 deco("ArchBeam", Vector3.new(gap * 2 + 20.6, 6, 8), archCF * CFrame.new(0, 34, 0), stone, Enum.Material.Slate)
 local label = signText(m, archCF * CFrame.new(0, 34, -4.06), Vector3.new(gap * 2 + 16, 4.4, 0.1), "bloodArenaSign", Color3.fromHex("FFD2D8"))
 label.Parent.PixelsPerStud = 16
 local stroke = Instance.new("UIStroke")
 stroke.Color, stroke.Thickness = Color3.fromHex("3A0010"), 3
 stroke.Parent = label
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
	disc('StoneBed',41,.65,PLAZA_TOP-.38,'8C7A66')
	Garden.Promenade(Art,folder,PLAZA_TOP)
	-- A flat shared collider lies beneath the lawn and paving; no raised lip to catch feet.
	Garden.ApplyGrass(disc('HubLawn',24.4,.15,PLAZA_TOP+.075,'91A62E'))
	for i=0,71 do
		local a=(i+.5)*math.pi*2/72
		local at=CFrame.new(math.sin(a)*40.8,PLAZA_TOP-.02,math.cos(a)*40.8)*CFrame.Angles(0,a,0)
		deco('StoneKerb',Vector3.new(3.48,.75,1.35),at,i%3==0 and 'A39684' or '8F8273')
	end
	local colors={'8E2F3A','A8843A','3F6B5A','5A4A7A','7A4A2A','2F4A5E'} -- muted since 2026-11-13 (the farm read as "too childish")
	local tops={}
	-- Offset the poles from the farm paths; cords stay above jumping players.
	for i=0,13 do
		local a=(i+.5)*math.pi*2/14
		local base=Vector3.new(math.sin(a)*40.1,PLAZA_TOP,math.cos(a)*40.1)
		deco('FestivalPole',Vector3.new(.55,8.5,.55),CFrame.new(base+Vector3.new(0,4.25,0)),'4A3A30')
		deco('PoleFoot',Vector3.new(.35,1.5,1.5),CFrame.new(base+Vector3.new(0,.15,0))*CFrame.Angles(0,0,math.pi/2),'3A2E26',Enum.PartType.Cylinder)
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
			deco('GarlandCord',Vector3.new(.07,.07,(point-previous).Magnitude),CFrame.lookAt((point+previous)/2,point),'4A4038')
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
	buildBloodArena(w)




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
		local bloodAlong = -roadAlong -- the way to the Blood Moon arena, across from the road
		if bloodAlong > 150 and (pos + roadDir * bloodAlong).Magnitude < 24 then
			return true
		end
		for i = 1, 6 do
			local a = math.rad(C.PlotAngles[i])
			local c = Vector3.new(math.sin(a) * C.PlotRadius, 0, math.cos(a) * C.PlotRadius)
			local v = CFrame.lookAt(c, Vector3.zero):PointToObjectSpace(pos)
			-- the farm and its round cemetery on the +x side (PlacementConfig.Cemetery)
			local cb = require(S.Config.PlacementConfig).Cemetery
			if math.abs(v.X) < C.FarmHalf + 3 and math.abs(v.Z) < C.FarmHalf + 3 or Vector2.new(v.X - cb.X, v.Z - cb.Z).Magnitude < cb.Radius + 5 then
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
	local function scatter(name, count, minR, maxR, minScale, maxScale, tint)
		local placed, tries = 0, 0
		while placed < count and tries < count * 40 do
			tries += 1
			local a, r = rng:NextNumber(0, math.pi * 2), rng:NextNumber(minR, maxR)
			local pos = Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
			if not insidePlot(pos) then
				local scale = rng:NextNumber(minScale, maxScale)
				Art.Spawn(name, w, CFrame.new(pos.X, ISLAND_TOP - 0.05, pos.Z) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0), { scale = scale, tints = tint and { Main = tint } or nil })
				placed += 1
			end
		end
	end
	local edge = 170 * grow - C.Boundary.Inset - 12
	-- Gloomier since 2026-11-13 (owner: the island looked "too childish" next to the ruins): darker greens, dead
	-- trees among the live ones. Thinned on 2026-11-14 (owner: too much detail, phones run hot): about half the trees
	-- and bushes, no mushrooms, rocks, pumpkins or fallen leaves.
	scatter("W_TreeA", 11, 60, edge, 0.85, 1.25, Color3.fromRGB(120, 138, 112))
	scatter("W_TreeB", 6, 60, edge, 0.85, 1.2, Color3.fromRGB(120, 132, 112))
	scatter("MR_TwistedTree", 6, 60, edge, 0.55, 0.85)
	task.wait()
	scatter("W_Bush", 14, 50, edge, 0.8, 1.3, Color3.fromRGB(125, 135, 110))
	scatter("W_Flowers", 6, 46, edge, 1.3, 2)
	scatter("W_Tuft", 24, 44, edge, 1, 1.8)
	-- Friendly spooky trees: placed by hand so their faces look toward the plaza.
	for i = 1, 6 do
		local a = (i - 0.5) * math.pi / 3
		for _, r in ipairs(i == 1 and {} or { 118 }) do -- the first gap is the road's; the inner ring went on 2026-11-14
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

-- The farm's outer ring (owner, 2026-11-13: "make the farm a bit bigger and add garden beds, a livelier farm"):
-- raised beds of planks and dark soil with cabbages, carrots, pumpkins, brain crops or withered stalks, two pumpkin
-- patches behind the cemetery, a scarecrow and a well in the front corners, a cart and crates at the back, dead trees,
-- glowing lamps on the fence and a low mist over the yard at night. None of it is solid; PlacementConfig keeps
-- monsters off it.
local function buildGarden(m,at,index,F)
 local PC=require(S.Config.PlacementConfig);local WA=require(S.WorldArt)
 local garden=Instance.new('Model');garden.Name='Garden';garden.Parent=m
 local rng=Random.new(4100+index)
 local WOOD,WOOD_DARK,SOIL=Color3.fromHex('5E4535'),Color3.fromHex('3B2B21'),Color3.fromHex('3A2A1F')
 local function piece(name,size,cf,color,material,shape)
  local q=P.Part(garden,name,size,cf,color,shape);q.Material=material or Enum.Material.SmoothPlastic
  q.CanCollide,q.CanQuery,q.CanTouch=false,false,false;return q
 end
 local function prop(asset,x,z,scale,yaw,tints)
  local parts=Art.Spawn(asset,garden,at(x,z)*CFrame.Angles(0,math.rad(yaw or 0),0),{scale=scale or 1,tints=tints})
  for _,q in parts do if typeof(q)=='Instance' and q:IsA('BasePart') then q.CanCollide,q.CanQuery,q.CanTouch=false,false,false end end
  return parts
 end
 local function ball(name,size,cf,color) return piece(name,size,cf,color,Enum.Material.SmoothPlastic,Enum.PartType.Ball) end
 -- The garden beds, the well, the crates, the dead trees, the fallen leaves, the yard mist and the fireflies went on
 -- 2026-11-14 (owner: too much detail, phones run hot); the scarecrow, the cart, the lamps and the workbench stay.
 -- a scarecrow in the front left corner, a cart at the back
 prop('W_Scarecrow',F-3.5,-F+3.5,.9,200,{Main=Color3.fromRGB(170,150,135)})
 -- The workbench (owner, 2026-11-13: "a bench on the farm to upgrade guns"; first in the far corner, then "too deep"):
 -- since 2026-11-13 (owner: "put the workbench to the right of the house door") against the house front, right of the
 -- door as you face it, turned to the path. The approved bench (WorkbenchModel, 2026-11-13): a heavy oak table with a
 -- vice, a rifle on a mat, mutagen bottles, a lantern and a tool rack; its spinning circle opens the weapon upgrades.
 local bench=Instance.new('Model');bench.Name='Workbench';bench.Parent=garden
 -- Since 2026-11-14 (owner, a screenshot with the player standing on the spot) in the front right corner (where the
 -- inside the cabbage and pumpkin beds, its back to the corner and its front (the corner frame's -Z) to the farm centre.
 local corner=at(-37,-35)*CFrame.Angles(0,math.rad(-135),0)
 -- the approved model (WorkbenchModel) faces +Z: turned round so its front faces the path like the corner's -Z
 local art=require(S.WorkbenchModel).Build(bench,corner*CFrame.Angles(0,math.pi,0))
 for _,q in art:GetDescendants() do
  if q:IsA('BasePart') and (q.Name=='LanternGlow' or q.Name=='MutagenLiquid') then
   local l=Instance.new('PointLight');l.Color=q.Color;l.Range=q.Name=='LanternGlow' and 12 or 7;l.Brightness=q.Name=='LanternGlow' and .6 or .4;l.Parent=q;WA.NightLight(l)
  end
 end
 local title=P.SignText(bench,corner*CFrame.new(0,6.6,1.35),Vector3.new(5,1.1,.1),'workbench',Color3.fromHex('FFE7A3'))
 title.Parent.PixelsPerStud=30;local st=Instance.new('UIStroke');st.Color=Color3.fromHex('2A1240');st.Thickness=2;st.Parent=title
 local benchZone=P.Part(bench,'WorkbenchZone',Vector3.one,corner*CFrame.new(0,.15,-3.8),Color3.fromHex('8CFF6A'))
 benchZone.Transparency,benchZone.CanCollide,benchZone.CanQuery,benchZone.CanTouch=1,false,false,false
 benchZone:SetAttribute('MenuZone','upgrades');benchZone:SetAttribute('Radius',3.4);benchZone:SetAttribute('Owner',-1)
 prop('MR_Cart',-6,F-3,.9,80)
 -- lamps on the fence: a glowing bulb on a dark post every so often, real light only by the gate and the corners
 local lit=0
 local function lamp(x,z,light)
  local post=piece('LampPost',Vector3.new(.45,4.6,.45),at(x,z,LAWN_TOP+2.3),WOOD_DARK,Enum.Material.Wood)
  piece('LampCap',Vector3.new(1,.25,1),post.CFrame*CFrame.new(0,2.4,0),Color3.fromHex('2B2420'),Enum.Material.Metal)
  local bulb=WA.NightGlow(ball('LampBulb',Vector3.new(.75,.75,.75),post.CFrame*CFrame.new(0,2.05,0),Color3.fromHex('FFB45C')))
  if light then lit+=1;local l=Instance.new('PointLight');l.Color=Color3.fromHex('FFB45C');l.Range=13;l.Brightness=.6;l.Parent=bulb;WA.NightLight(l) end
 end
 for _,q in {{-8.6,-F-.6,true},{8.6,-F-.6,true},{F-.6,-F+.6,true},{-F+.6,-F+.6,true},{F-.6,F-.6,true},{F-.6,-16},{F-.6,26},{-F+.6,-18},{-F+.6,4},{-F+28,-F+.6},{F-28,-F+.6},{20,F-.6}} do lamp(q[1],q[2],q[3]) end
 return garden,benchZone
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
 -- Cemetery (owner's picture, 2026-11-14: "a round yard, a continuation of the farm"): a circle beside the farm's +x
 -- fence (PlacementConfig.Cemetery), the crypt in its middle, the owner's graves all round, its opening facing the
 -- farm. 2026-11-15 (owner: "you lost the purple ground and changed the fence against the farm's"): the ground is the
 -- old purple patch made round (ArtModels.Cemetery_Round, art/roblox-import-v1/tools/cemetery_round.py: W_Graveyard's
 -- tiles, rim stones and colours under the same tint) and the ring is the farm's own fence (fence() below, so
 -- FenceService dresses it with the upgrades too); the three hanging lanterns the old cemetery kept hang outside it.
 local cb=PC.Cemetery;local cc=at(cb.X,cb.Z)
 local cemetery=Instance.new('Model');cemetery.Name='Cemetery';cemetery.Parent=m
 local cemeteryRing={} -- the fence's corners from one side of the opening all the way round to the other, farm-local
 do
  local WA=require(S.WorldArt)
  local round=Art.Has('Cemetery_Round')
  if round then Art.Spawn('Cemetery_Round',cemetery,cc,{tints={Main=Color3.fromRGB(173,145,204)}}) end
  -- a flat disc at the tiles' height for the placing ray (the patch takes no queries); seen only if the patch is missing
  local ground=P.Part(cemetery,'CemeteryGround',Vector3.new(.06,(cb.Radius-1)*2,(cb.Radius-1)*2),cc*CFrame.new(0,.12,0)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(84,61,127))
  ground.Shape=Enum.PartType.Cylinder;ground.Material=Enum.Material.SmoothPlastic
  ground.CanCollide,ground.CanTouch,ground.CastShadow=false,false,false;ground.Transparency=round and 1 or 0
  local gap=math.asin((cb.DoorTo-cb.DoorFrom)/2/cb.Radius);local n=18 -- stretches about as long as the farm's rails
  local a0,step=math.pi+gap,(2*math.pi-2*gap)/n
  for k=0,n do local a=a0+k*step;table.insert(cemeteryRing,Vector3.new(cb.X+math.cos(a)*cb.Radius,0,cb.Z+math.sin(a)*cb.Radius)) end
  local function lantern(a)
   local r=cb.Radius+1.6
   local parts=Art.Spawn('MR_HangingLantern',cemetery,at(cb.X+math.cos(a)*r,cb.Z+math.sin(a)*r)*CFrame.Angles(0,math.pi/2-a,0),{scale=.8})
   for _,q in parts do if typeof(q)=='Instance' and q:IsA('BasePart') then q.CanCollide=false;q.CanQuery=false;q.CanTouch=false end end
   local main=parts and (parts.Main or parts.Bulb or select(2,next(parts)));if not main then return end
   local anchor=P.Part(cemetery,'LampLight',Vector3.one*.1,CFrame.new(main.Position+Vector3.new(0,2.4,0)),Color3.fromHex('CDEBFF'))
   anchor.Transparency=1;anchor.CanCollide=false;anchor.CanQuery=false;anchor.CanTouch=false;anchor.CastShadow=false
   local l=Instance.new('PointLight');l.Color=Color3.fromHex('CDEBFF');l.Range=10;l.Brightness=.55;l.Parent=anchor;WA.NightLight(l)
  end
  for _,deg in {-55,0,55} do lantern(math.rad(deg)) end
 end
 -- The crypt (art/crypt-optimized-v1 as ArtModels.Crypt_V2, 2026-11-14) in the cemetery's middle, its steps (-Z) to
 -- the farm (-x). One invisible block keeps players out of the vault; its steps stay walkable. The menu ring lies on
 -- the walk in front of the steps.
 do
  local pc=PC.Crypt;local s=pc.Scale
  local cryptCf=at(pc.X,pc.Z)*CFrame.Angles(0,math.pi/2,0)
  local crypt=Instance.new('Model');crypt.Name='Crypt';crypt.Parent=cemetery
  if Art.Has('Crypt_V2') then Art.Spawn('Crypt_V2',crypt,cryptCf,{scale=s}) end
  solid(crypt,'CryptBlock',Vector3.new(10.4*s,8*s,6.6*s),cryptCf*CFrame.new(0,4*s,1.25*s))
  local glow=P.Part(crypt,'CryptGlow',Vector3.one*.1,cryptCf*CFrame.new(0,3*s,-6*s),Color3.fromHex('CDB8FF'))
  glow.Transparency,glow.CanCollide,glow.CanQuery,glow.CanTouch,glow.CastShadow=1,false,false,false,false
  local l=Instance.new('PointLight');l.Color=Color3.fromHex('CDB8FF');l.Range=16;l.Brightness=.9;l.Parent=glow;require(S.WorldArt).NightLight(l)
  local zone=P.Part(crypt,'CryptZone',Vector3.one,at(pc.Menu.X,pc.Menu.Z,LAWN_TOP+.15),Color3.fromHex('8CFF6A'))
  zone.Transparency,zone.CanCollide,zone.CanQuery,zone.CanTouch=1,false,false,false
  zone:SetAttribute('MenuZone','crypt');zone:SetAttribute('Radius',4);zone:SetAttribute('Owner',-1)
  plot.Crypt={Model=crypt,Zone=zone,Door=cryptCf*CFrame.new(0,1.65,-5*s)}
 end
 -- Weathered rails and posts (owner, 2026-11-13: the farm looked "too childish" next to the ruins): the fence mesh is
 -- tinted old grey wood. FenceService adds the upgrade looks along the same lines (plot.FenceLines, farm-local).
 local FENCE_TINT=Color3.fromRGB(150,126,108)
 plot.FenceLines={}
 local function fence(a,b)
  local v=b-a;local length=v.Magnitude;local center=(a+b)/2
  if length<.5 then return end
  table.insert(plot.FenceLines,{a,b})
  local n=math.max(1,math.ceil(length/8))
  for j=1,n do local q=a:Lerp(b,(j-.5)/n);Art.Spawn('W_Fence',m,base*CFrame.lookAt(q+Vector3.new(0,LAWN_TOP,0),q+Vector3.new(v.Z,LAWN_TOP,-v.X)),{scale=Vector3.new(length/n/8,1,1),tints={Main=FENCE_TINT}}) end
  solid(m,'Fence',Vector3.new(.6,3,length),base*CFrame.lookAt(center+Vector3.new(0,LAWN_TOP+1.5,0),b+Vector3.new(0,LAWN_TOP+1.5,0)))
 end
 local function seg(x1,z1,x2,z2) fence(Vector3.new(x1,0,z1),Vector3.new(x2,0,z2)) end
 local HC=require(S.Config.HouseConfig)
 -- The house closes the back-right corner at 45 degrees: both fences stop where its back corners touch them
 local cut=(HC.Looks[1].W+2)/math.sqrt(2)
 seg(7,-F,F,-F);seg(F,-F,F,cb.DoorFrom);seg(F,cb.DoorTo,F,F);seg(F,F,-F+cut,F);seg(-F,F-cut,-F,-F);seg(-F,-F,-7,-F)
 -- the short passage from the opening in the fence to the cemetery's, and the cemetery's ring (2026-11-14)
 local ring=cemeteryRing
 seg(F,cb.DoorFrom,ring[1].X,ring[1].Z);seg(F,cb.DoorTo,ring[#ring].X,ring[#ring].Z)
 for k=1,#ring-1 do fence(ring[k],ring[k+1]) end
 -- Each rail mesh includes its end post. Cap the two open starts only.
 for _,q in {{7,-F},{-F,F-cut},{-7,-F},{F,cb.DoorTo}} do Art.Spawn('W_FencePost',m,at(q[1],q[2]),{tints={Main=FENCE_TINT}}) end
 local pb=PC.Pen -- Preserve existing zombie income positions.
 -- Gate arch with the owner's name; its leaves are FenceService's (raiders break them at night)
 plot.Gate=P.Part(m,'Gate',Vector3.new(12,.1,5),at(0,-F+2,LAWN_TOP+.05),Color.Grass or Color3.fromHex('86CF4B'));plot.Gate.Transparency=1
 plot.Barrier=P.Part(m,'Barrier',Vector3.new(14,7,1),at(0,-F-1,3),Color.Pink);plot.Barrier.Material=Enum.Material.ForceField;plot.Barrier.Transparency=1;plot.Barrier.CanCollide=false
 plot.GateFrame=at(0,-F);plot.FenceF=F
 Art.Spawn('W_GateArch',m,at(0,-F),{scale=.85,tints={Main=Color3.fromRGB(128,98,90)}})
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
    for _,stone in parts do stone.Name='PathStone';stone.CastShadow=false;stone.Color=Color3.fromRGB(176,164,150) end -- worn, not bright
   end
  end
 end
 local doorReach=(HC.Looks[1].D/2+2.5)/math.sqrt(2)
 path(0,-F,0,0);path(0,0,HC.RoomX+doorReach,HC.RoomZ-doorReach);path(0,-24,21,-24)
 path(0,-2,F+1,cb.Z) -- to the cemetery's passage; no stones across the purple ground, as before
 local guideCemetery=P.Part(m,'GuideCemetery',Vector3.one,at(cb.X-cb.Radius+7,cb.Z,1),Color.Panel);guideCemetery.Transparency=1;guideCemetery.CanCollide=false;guideCemetery.CanQuery=false
 plot.BenchZone=select(2,buildGarden(m,at,i,F))
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
			if plot.BenchZone then plot.BenchZone:SetAttribute("Owner", p.UserId) end
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
		if plot.BenchZone then plot.BenchZone:SetAttribute("Owner", -1) end
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
	if math.abs(v.X) <= C.FarmHalf + 1 and v.Z >= -C.FarmHalf - 1 and v.Z <= C.FarmHalf + 1 then
		return true
	end
	-- the round cemetery beside it and the passage to it are the farm too (owner, 2026-11-14: "a continuation of the
	-- farm"); before this, planting a grave from inside the cemetery was refused
	local cb = require(S.Config.PlacementConfig).Cemetery
	return Vector2.new(v.X - cb.X, v.Z - cb.Z).Magnitude <= cb.Radius + 1
		or v.X >= C.FarmHalf and v.X <= cb.X and v.Z >= cb.DoorFrom - 1 and v.Z <= cb.DoorTo + 1
end

-- Players arrive on the path in front of their gate (owner, 2026-11-12), facing the arch and the farm behind it.
function P.Home(p)
	local q = P.Assigned[p]
	if q and p.Character then
		local spot = q.Base * CFrame.new(0, 5, -(C.FarmHalf + 8)) * CFrame.Angles(0, math.pi, 0)
		-- with streaming on, the farm may not be on the client yet (coming home from far down the road): load it first
		if typeof(p) == "Instance" then
			pcall(p.RequestStreamAroundAsync, p, spot.Position, 4)
		end
		if not p.Character then
			return
		end
		p.Character:PivotTo(spot)
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
