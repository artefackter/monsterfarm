-- The ruins road, dressed after the owner's reference picture (2026-11-09): one long walled corridor, a path
-- down the middle and six locations in a row, each with its own look. Since the reskin of 2026-11-15 (owner): dark
-- forest, backrooms, abandoned city, abandoned village, Parasitown, abandoned cave (the blood mine), after
-- art/road-reskin-screenshot-concepts-v5. The walls are the island's block wall, recoloured per location.
-- Physical floors and gameplay colliders belong to RoadService; everything here is decoration except a few solid
-- building blocks that players (not mutants) bump into.
-- Revision 5 (owner, 2026-11-13): every location's boss waits in a round pocket beside the road near its end (left and
-- right in turn), through an arched opening in the road wall with the boss's name over it; the road runs on past it.
local S = game.ReplicatedStorage.Shared
local Art = require(S.ArtKit)
local WA = require(S.WorldArt)
local Progression = require(S.Config.RoadProgression)
local A = {}

local function hex(h)
	return Color3.fromHex(h)
end

function A.Build(world, at, C, districts, P)
	local root = Instance.new("Model")
	root.Name = "RoadArt"
	root:SetAttribute("Revision", 6)
	root.Parent = world
	local rng = Random.new(9032)
	local W = C.Width
	local half = W / 2
	local toLocal = at(0, 0, 0):Inverse()
	-- Round the opening to the boss pocket (on its side of the road only) scenery is left out: the wall over the opening
	-- itself, and a wider stretch for buildings and props so they never stand in the way in.
	local skipS, skipSide, skipGap
	local function skipped(s, x)
		-- nothing of the road's scenery stands inside a boss arena (they are big since 2026-11-13: radius 100), the part
		-- of it reaching into the road included (2026-11-15) - save the path and the lines down the road's middle
		if x and math.abs(x) > 34 and Progression.PocketAt(s, x, 12) then
			return true
		end
		if not skipS or not x or x * skipSide < 15 then
			return false
		end
		return math.abs(s - skipS) < (x * skipSide >= half - 1 and skipGap or skipGap + 28)
	end
	local function localOf(cf)
		local v = (toLocal * cf).Position
		return -v.Z, v.X
	end

	local function part(parent, name, size, cf, color, material, shape)
		if skipped(localOf(cf)) then
			return nil
		end
		local q = Instance.new("Part")
		q.Name = name
		q.Size = size
		q.CFrame = cf
		q.Color = color
		q.Material = material or Enum.Material.SmoothPlastic
		q.Anchored, q.CanCollide, q.CanQuery, q.CanTouch = true, false, false, false
		q.TopSurface, q.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		if shape then
			q.Shape = shape
		end
		q.Parent = parent
		return q
	end
	-- Keep scenery off the graves and the rubble.
	local function busy(s, x, r)
		for _, spot in C.Spots do
			if math.abs(spot.S - s) < r + 6 and math.abs(spot.X - x) < r + 6 then
				return true
			end
		end
		for _, q in C.Walls do
			if math.abs(q.S - s) < r + q.D and math.abs(q.X - x) < r + q.W / 2 then
				return true
			end
		end
		for _, g in C.Graveyards or {} do -- the mini cemeteries (2026-11-15)
			if Vector2.new(g.S - s, g.X - x).Magnitude < g.Radius + r + 4 then
				return true
			end
		end
		return false
	end

	-- A location's mini cemetery (owner, 2026-11-15: "mini cemeteries like the players' farms"; RoadConfig.Graveyards,
	-- whose ring of grave spots RoadService fills): the farm's round purple patch at its size and tint, ringed by the
	-- farm's weathered fence with an opening towards the road's middle and a post either side of it. Scenery only: the
	-- fence has no collider, so it never gets in the way of a chase.
	local FENCE_TINT = Color3.fromRGB(150, 126, 108)
	local function buildGraveyard(g)
		local m = Instance.new("Model")
		m.Name = "RoadGraveyard"
		m:SetAttribute("Location", g.Location)
		m.Parent = root
		local function loose(parts)
			for _, q in parts or {} do
				if typeof(q) == "Instance" and q:IsA("BasePart") then
					q.CanCollide, q.CanQuery, q.CanTouch = false, false, false
				end
			end
		end
		local toward = g.Side > 0 and math.pi or 0 -- the opening's direction (the road's middle), as an angle in s, x
		if Art.Has("Cemetery_Round") then
			-- the patch was made 24 studs round with its entrance on its -X side
			local k = g.Radius / 24
			loose(Art.Spawn("Cemetery_Round", m, at(g.S, g.X, 0) * CFrame.Angles(0, g.Side > 0 and 0 or math.pi, 0), { scale = Vector3.new(k, 1, k), tints = { Main = Color3.fromRGB(173, 145, 204) } }))
		end
		local gap = math.asin(4 / g.Radius) -- an 8-stud way in
		local a0, a1 = toward + gap, toward + 2 * math.pi - gap
		local n = math.max(3, math.ceil((a1 - a0) * g.Radius / 8))
		local function point(a)
			return at(g.S + math.sin(a) * g.Radius, g.X + math.cos(a) * g.Radius, 0).Position
		end
		for k = 0, n - 1 do
			local p0, p1 = point(a0 + (a1 - a0) * k / n), point(a0 + (a1 - a0) * (k + 1) / n)
			local v, q = p1 - p0, (p0 + p1) / 2
			loose(Art.Spawn("W_Fence", m, CFrame.lookAt(q, q + Vector3.new(v.Z, 0, -v.X)), { scale = Vector3.new(v.Magnitude / 8, 1, 1), tints = { Main = FENCE_TINT } }))
		end
		for _, a in { a0, a1 } do
			loose(Art.Spawn("W_FencePost", m, CFrame.new(point(a)), { tints = { Main = FENCE_TINT } }))
		end
	end
	for _, g in C.Graveyards or {} do
		buildGraveyard(g)
	end

	-- The amphitheatre at the end of every location ------------------------------------------------------------------
	-- Floor: sand in a dark rim with a ring and the seal. Sides: a low podium wall on the corridor line, then an oval
	-- bowl of stepped stands that rises outside the walls (only the parts beyond the corridor are built, so both ends
	-- stay open for the road). Gates with the boss's name close the arena at both ends.
	-- v5 (owner, 2026-11-13): the arena is a round pocket beside the road (RoadProgression.PocketAt), not across it. Sand
	-- floor with the seal, a full bowl of stands round it (open only towards the road), columns with fire, braziers,
	-- and an arch over the opening in the road wall with the boss's name on it.
	-- v6 (owner, 2026-11-15): no corridor; the round reaches into the road and is open to it along its arc, with a
	-- pillar at each end of the opening and the boss's name on a board over the far side.
	local function buildPocket(d, parent)
		local pd = Progression.Districts[d.Index]
		local model = Instance.new("Model")
		model.Name = "BossPocket"
		model:SetAttribute("Boss", d.Index)
		model.Parent = parent
		local side, c, px, R, gap = pd.PocketSide, pd.PocketS, pd.PocketX, Progression.PocketRadius, Progression.PocketGap / 2
		local stone = hex(d.Wall[1])
		local dark = stone:Lerp(Color3.new(0, 0, 0), 0.4)
		local sand = hex(d.Path):Lerp(hex("E8D3A4"), 0.45)
		local function piece(name, size, cf, color, material, shape)
			local q = Instance.new("Part")
			q.Name = name
			q.Size = size
			q.CFrame = cf
			q.Color = color
			q.Material = material or Enum.Material.SmoothPlastic
			q.Anchored, q.CanCollide, q.CanQuery, q.CanTouch = true, false, false, false
			q.TopSurface, q.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
			if shape then
				q.Shape = shape
			end
			q.Parent = model
			return q
		end
		local function disc(name, radius, y, color, material)
			local q = piece(name, Vector3.new(0.06, radius * 2, radius * 2), at(c, px, y) * CFrame.Angles(0, 0, math.pi / 2), color, material, Enum.PartType.Cylinder)
			q.CastShadow = false
			return q
		end
		disc("ArenaRim", R + 2, 0.04, dark)
		local sandFloor = disc("ArenaSand", R, 0.05, sand, Enum.Material.Sand)
		disc("ArenaLine", R * 0.58, 0.06, dark)
		local sandInner = disc("ArenaSandInner", R * 0.58 - 0.9, 0.07, sand, Enum.Material.Sand)
		Art.Spawn("MR_ArenaSeal", model, at(c, px, 0.06), { scale = Vector3.new(3.2, 0.4, 3.2) })
		-- (no corridor since 2026-11-15: the floor's dark rim draws the circle's arc across the road where it is open)
		local function facesRoad(ds, dx, margin) -- on the road's side, where the arena is open
			return Progression.FacesDoor(d.Index, ds, dx, margin or 4)
		end
		-- Each boss's own look (owner, 2026-11-13: "style the amphitheatres after the boss; drop steps 1-3, keep 4 and 5"):
		-- only the two tall back tiers stand round the floor now, in the boss's colours, with its emblem on the columns.
		-- The road reskin (owner, 2026-11-15; art/road-reskin-screenshot-concepts-v5): each arena in its location's look.
		local THEMES = {
			{ stand = { "3F4A33", "35402B" }, cap = "6B5A3A", sand = "56603F", motif = "antlers" }, -- dark forest (the Horned Alpha): mossy stone, antlers
			{ stand = { "3A3226", "2E281E" }, cap = "E07A1F", sand = "4A4236", motif = "candles", floor = "Fabric" }, -- backrooms (RingMaw): dark carpet, an orange rim, candles
			{ stand = { "6E6E6C", "5E5E5C" }, cap = "B3262E", sand = "8A8A88", motif = "banners", floor = "Concrete" }, -- city (the Stranger): concrete, red banners
			{ stand = { "B98A5A", "A87A4C" }, cap = "8A6038", sand = "B49C7C", motif = "candles" }, -- village (Slendrina): a ring of planks, candles
			{ stand = { "4A4446", "3E383A" }, cap = "7A1E26", sand = "6E6668", motif = "tentacles", floor = "Concrete" }, -- Parasitown (Patient Zero): tentacles, red growth
			{ stand = { "5E5256", "4E4448" }, cap = "7A6A5E", sand = "7A6A6E", motif = "torches", floor = "Slate" }, -- the cave (the Cave Dweller): rock, torches, ore
		}
		local theme = THEMES[d.Index] or THEMES[1]
		local capColor = hex(theme.cap)
		sandFloor.Color = hex(theme.sand)
		sandInner.Color = hex(theme.sand)
		if theme.floor then
			sandFloor.Material, sandInner.Material = Enum.Material[theme.floor], Enum.Material[theme.floor]
		end
		-- The stands: the old fourth and fifth tiers, now right behind the floor's edge
		-- Performance (2026-11-14): 32 stand segments, 16 columns, 8 floor props and 6 braziers (3 of them lit) per arena;
		-- they were 80, 36, 16 and 10, all lit.
		-- No holes (owner, 2026-11-15: "every boss arena has holes"): each row runs exactly from where its circle meets
		-- the road's wall line on one side round to the other, so it closes on the pillars and the road's walls; it
		-- stopped well short of them before and the void showed through.
		local segments = 32
		local rows = { { r = R + 5, seat = 17.2 }, { r = R + 12.6, seat = 20.6 } }
		local tRoad = side > 0 and math.pi or 0 -- the angle that points from the arena's middle at the road
		for k, row in rows do
			local r, height = row.r, row.seat + 14
			local edge = math.acos(math.clamp((math.abs(px) - (Progression.RoadHalf + 2)) / r, -1, 1))
			local from, arc = tRoad + edge, 2 * math.pi - 2 * edge
			local n = math.max(1, math.floor(segments * arc / (2 * math.pi) + 0.5))
			for step = 0, n - 1 do
				local t0, t1 = from + arc * step / n, from + arc * (step + 1) / n
				local tm = (t0 + t1) / 2
				local ds, dx = math.sin(tm) * r, math.cos(tm) * r
				do
					local p0, p1 = at(c + math.sin(t0) * r, px + math.cos(t0) * r, 0).Position, at(c + math.sin(t1) * r, px + math.cos(t1) * r, 0).Position
					local mid = at(c + ds, px + dx, row.seat - height / 2).Position
					local look = CFrame.lookAt(mid, mid + (p1 - p0))
					piece("Stand", Vector3.new(7.6, height, (p1 - p0).Magnitude + 0.5), look, hex(theme.stand[k]))
					piece("StandTrim", Vector3.new(7.8, 0.6, (p1 - p0).Magnitude + 0.5), look * CFrame.new(0, height / 2 + 0.3, 0), capColor)
					if theme.motif == "tentacles" and k == 1 and step % 3 == 0 then -- dark red growth creeping over the inner face
						piece("Growth", Vector3.new(0.3, height * 0.6, (p1 - p0).Magnitude * 0.5), look * CFrame.new(-3.85, height * 0.1, 0), hex("5A1218"))
					end
				end
			end
		end
		-- Columns along the top with the boss's emblem
		local rTop = R + 17
		local topY = 20.6
		local bone = hex("E6DCC4")
		local columns = 16
		for n = 0, columns - 1 do
			local t = (n + 0.5) / columns * math.pi * 2
			local ds, dx = math.sin(t) * rTop, math.cos(t) * rTop
			if not facesRoad(ds, dx, 20) then
				local tall = 12
				local base = at(c + ds, px + dx, topY + tall / 2)
				piece("Column", Vector3.new(2.6, tall, 2.6), base, hex(theme.stand[1]):Lerp(Color3.new(1, 1, 1), 0.2))
				local headY = topY + tall
				piece("ColumnCap", Vector3.new(3.8, 1, 3.8), at(c + ds, px + dx, headY + 0.5), capColor)
				local headAt = at(c + ds, px + dx, headY + 1).Position
				local head = CFrame.lookAt(headAt, at(c, px, headY + 1).Position) -- -Z looks into the arena
				if theme.motif == "antlers" then
					piece("Skull", Vector3.new(2, 1.8, 2.2), head * CFrame.new(0, 1, 0), bone, nil, Enum.PartType.Ball)
					for _, e in { -1, 1 } do
						piece("Antler", Vector3.new(0.5, 4, 0.5), head * CFrame.new(e * 1.2, 3, 0) * CFrame.Angles(0, 0, -e * 0.5), bone)
						piece("AntlerTine", Vector3.new(0.4, 2, 0.4), head * CFrame.new(e * 2.2, 4.4, 0) * CFrame.Angles(0, 0, e * 0.4), bone)
					end
				elseif theme.motif == "candles" then
					-- a thick candle on every column, its flame glowing
					piece("Candle", Vector3.new(1.1, 2.6, 1.1), head * CFrame.new(0, 1.3, 0), hex("EDE3C8"))
					piece("CandleFlame", Vector3.new(0.7, 1.1, 0.7), head * CFrame.new(0, 3.1, 0), hex("FFB04A"), Enum.Material.Neon, Enum.PartType.Ball)
				elseif theme.motif == "banners" then
					-- a red banner with a yellow diamond hanging into the arena, like the island's
					piece("Banner", Vector3.new(3, 8, 0.3), head * CFrame.new(0, -5, -1.6), hex("B3262E"))
					piece("Diamond", Vector3.new(1.6, 1.6, 0.35), head * CFrame.new(0, -4, -1.8) * CFrame.Angles(0, 0, math.pi / 4), hex("F2C744"))
				elseif theme.motif == "tentacles" then
					-- a bone spike crusted with red growth
					piece("Spike", Vector3.new(0.9, 4, 0.9), head * CFrame.new(0, 2.2, 0), hex("E6DCC4"))
					piece("SpikeGrowth", Vector3.new(1.5, 1.6, 1.5), head * CFrame.new(0, 0.8, 0), hex("7A1E26"), nil, Enum.PartType.Ball)
				elseif theme.motif == "torches" then
					piece("TorchFlame", Vector3.new(1.6, 2.2, 1.6), head * CFrame.new(0, 1.4, 0), hex("FF8A3D"), Enum.Material.Neon, Enum.PartType.Ball)
				end
			end
		end
		-- Round the floor: bones for the Horned Alpha, tentacles in Parasitown, ore in the cave, rubble in the city
		local props = 8
		for n = 0, props - 1 do
			local t = (n + 0.5) / props * math.pi * 2
			local ds, dx = math.sin(t) * (R - 3), math.cos(t) * (R - 3)
			if not facesRoad(ds, dx, 10) then
				local spot = at(c + ds, px + dx, 0)
				-- turned to face the middle of the arena
				local inward = spot * CFrame.Angles(0, math.atan2(math.cos(t), -math.sin(t)), 0)
				if theme.motif == "antlers" then
					piece("Bones", Vector3.new(0.5, 0.5, 3), spot * CFrame.new(0, 0.25, 0) * CFrame.Angles(0, t, 0), bone)
				elseif theme.motif == "tentacles" and Art.Has("PT_ArenaTentacleTall") then
					-- the tentacles stand round the arena only (the concept keeps the road itself clear of them)
					Art.Spawn(n % 2 == 0 and "PT_ArenaTentacleTall" or "PT_ArenaTentacleHook", model, inward, { scale = 1.2 })
				elseif theme.motif == "torches" and Art.Has("BM_OreCluster") then
					Art.Spawn("BM_OreCluster", model, inward, { scale = 1.3 })
				elseif theme.motif == "banners" and Art.Has("SH_Rubble") then
					Art.Spawn("SH_Rubble", model, inward, { scale = 1.2 })
				end
			end
		end
		-- Braziers round the floor, away from the way in
		local braziers = 6
		for n = 0, braziers - 1 do
			local t = (n + 0.5) / braziers * math.pi * 2
			local ds, dx = math.sin(t) * (R - 6), math.cos(t) * (R - 6)
			if not facesRoad(ds, dx, 10) then
				piece("BrazierStand", Vector3.new(1.4, 5, 1.4), at(c + ds, px + dx, 2.5), dark)
				piece("BrazierBowl", Vector3.new(1.2, 3.6, 3.6), at(c + ds, px + dx, 5.4) * CFrame.Angles(0, 0, math.pi / 2), dark, nil, Enum.PartType.Cylinder)
				-- the flame only glows: the braziers lost their light on 2026-11-15 (performance); the pillar torches light the arena
				piece("BrazierFlame", Vector3.new(2.2, 2.2, 2.2), at(c + ds, px + dx, 6.6), hex("FF8A3D"), Enum.Material.Neon, Enum.PartType.Ball)
			end
		end
		-- The arena is open to the road (2026-11-15): a pillar with a torch where each end of the road wall meets the
		-- circle, and the boss's name on a board high over the far side, facing the road across the arena.
		local ax = side * (half + 2)
		local door, dw = pd.DoorS, Progression.DoorWidth / 2
		for _, e in { -1, 1 } do
			piece("ArchPillar", Vector3.new(6, 26, 6), at(door + e * (dw + 3), ax, 13), stone:Lerp(dark, 0.15))
			piece("ArchPillarCap", Vector3.new(7.4, 1.4, 7.4), at(door + e * (dw + 3), ax, 26.7), hex(d.Cap))
			local torch = piece("ArchTorch", Vector3.new(1.6, 1.6, 1.6), at(door + e * (dw + 3), ax - side * 3.4, 15), hex("FF8A3D"), Enum.Material.Neon, Enum.PartType.Ball)
			local light = Instance.new("PointLight")
			light.Color, light.Range, light.Brightness, light.Shadows = hex("FFA34D"), 22, 1, false
			light.Parent = torch
		end
		local backX = px + side * (R + 21)
		for _, e in { -1, 1 } do
			piece("NamePost", Vector3.new(2, 24, 2), at(c + e * 30, backX + side * 0.6, 32), stone:Lerp(dark, 0.3))
		end
		piece("NameBoard", Vector3.new(1, 10, 76), at(c, backX + side * 0.6, 42), stone:Lerp(dark, 0.3))
		piece("NameBoardTrim", Vector3.new(1.2, 0.8, 78), at(c, backX + side * 0.6, 47.4), hex(d.Cap))
		local boss = require(S.RoadMonsterRules).Bosses[d.Index]
		local label = P.SignText(model, at(c, backX, 42) * CFrame.Angles(0, side * math.pi / 2, 0), Vector3.new(72, 8, 0.1), boss and boss.Name or "Chief", hex("FFE7A3"))
		label.Parent.PixelsPerStud = 12
		local stroke = Instance.new("UIStroke")
		stroke.Color, stroke.Thickness = hex("2A1240"), 3
		stroke.Parent = label
	end

	for i, d in districts do
		local folder = Instance.new("Model")
		folder.Name = d.Name
		folder:SetAttribute("RecommendedSpeed", d.RecommendedSpeed)
		folder.Parent = root
		local length = d.To - d.From
		local pd = Progression.Districts[i]
		skipS, skipSide, skipGap = pd.DoorS, pd.PocketSide, Progression.DoorWidth / 2 + 1
		local function put(asset, s, x, scale, yaw, y)
			if skipped(s, x) then
				return {}
			end
			for _, g in C.Graveyards or {} do -- nothing grows out of a mini cemetery (2026-11-15)
				if Vector2.new(g.S - s, g.X - x).Magnitude < g.Radius + 5 then
					return {}
				end
			end
			return Art.Spawn(asset, folder, at(s, x, y or 0) * CFrame.Angles(0, math.rad(yaw or 0), 0), { scale = scale or 1 })
		end
		-- A solid block inside a building: players bump into it, mutants (not queried) path past it.
		local function block(s, x, size)
			if skipped(s, x) then
				return nil
			end
			local q = P.Solid(folder, "BuildingBlock", size, at(s, x, size.Y / 2))
			q.CanQuery = false
			return q
		end
		-- Long strips (coping, pipes, lane lines) run in two pieces either side of the pocket's opening, on its side.
		local function strip(name, width, height, x, y, color, material, shape, rotate)
			local spans = x * skipSide >= 15 and { { d.From, skipS - skipGap }, { skipS + skipGap, d.To } } or { { d.From, d.To } }
			for _, span in spans do
				local a, b = math.max(span[1], d.From), math.min(span[2], d.To)
				if b - a > 0.5 then
					local cf = at((a + b) / 2, x, y)
					if rotate then
						cf *= rotate
					end
					local size = rotate and Vector3.new(b - a, height, width) or Vector3.new(width, height, b - a)
					local saved = skipS
					skipS = nil
					part(folder, name, size, cf, color, material, shape)
					skipS = saved
				end
			end
		end
		-- Only every fourth lantern and torch carries a real light (every other since 2026-11-14, every fourth since
		-- 2026-11-15: phones run hot); the rest just glow.
		local lampCount = 0
		local function lamp(s, x, y, color, range, always)
			lampCount += 1
			if lampCount % 4 ~= 1 then
				return
			end
			local anchor = part(folder, "LampLight", Vector3.one * 0.2, at(s, x, y), hex("FFFFFF"))
			if not anchor then
				return
			end
			anchor.Transparency = 1
			local light = Instance.new("PointLight")
			light.Color, light.Range, light.Brightness, light.Shadows = color, range or 22, always and 0.8 or 1.2, false
			light.Parent = anchor
			if not always then
				WA.NightLight(light)
			end
		end

		-- The path down the middle, with darker edges
		local pathColor = hex(d.Path)
		for a = d.From, d.To - 1, 40 do
			local b = math.min(a + 40, d.To)
			part(folder, "Path", Vector3.new(18, 0.06, b - a), at((a + b) / 2, 0, 0.03), pathColor)
			for _, side in { -1, 1 } do
				part(folder, "PathEdge", Vector3.new(1.4, 0.07, b - a), at((a + b) / 2, side * 9.4, 0.035), pathColor:Lerp(Color3.new(0, 0, 0), 0.18))
			end
		end

		-- The island's block wall, recoloured for this location, with buttresses and a coping
		-- Big blocks since 2026-11-14 (performance: the road wall was 3,100 parts): two courses of 10 x 20, was four of 5 x 10.
		local course, rows, blockLen = 10, 2, 20
		for _, side in { -1, 1 } do
			local x = side * (half + 2)
			for row = 0, rows - 1 do
				local shift = row % 2 == 1 and blockLen / 2 or 0
				local a = d.From - shift
				while a < d.To do
					local s0, s1 = math.max(a, d.From), math.min(a + blockLen, d.To)
					if s1 - s0 > 0.5 then
						part(folder, "WallBlock", Vector3.new(4 + rng:NextNumber(-0.2, 0.2), course - 0.15, s1 - s0 - 0.18), at((s0 + s1) / 2, x, row * course + course / 2), hex(d.Wall[rng:NextInteger(1, #d.Wall)]))
					end
					a += blockLen
				end
			end
			strip("WallCoping", 4.8, 0.8, x, rows * course + 0.4, hex(d.Cap))
			for s = d.From + 20, d.To - 5, 40 do
				part(folder, "Buttress", Vector3.new(5, rows * course + 2.4, 5), at(s, side * (half + 3.5), (rows * course + 2.4) / 2), hex(d.Wall[1]):Lerp(Color3.new(0, 0, 0), 0.08))
				part(folder, "ButtressCap", Vector3.new(6, 1, 6), at(s, side * (half + 3.5), rows * course + 2.9), hex(d.Cap))
			end
		end

		-- Location and recommended speed are announced by the client on entry.
		task.wait()

		local function scatter(asset, count, minX, maxX, minScale, maxScale, avoid)
			for _ = 1, count do
				local s = rng:NextNumber(d.From + 6, d.To - 6)
				local x = (rng:NextNumber() < 0.5 and -1 or 1) * rng:NextNumber(minX, maxX)
				if not busy(s, x, avoid or 3) then
					put(asset, s, x, rng:NextNumber(minScale, maxScale), rng:NextInteger(0, 359))
				end
			end
		end

		-- The road reskin (owner, 2026-11-15; art/road-reskin-screenshot-concepts-v5, props from
		-- art/biome-models-optimized-v1 as ArtModels): long shallow buildings and walls stand along the road's walls,
		-- the middle stays clear and readable, a few props lie about. The wall models face -Z with their back on the pivot.
		local function hasArt(asset)
			return Art.Has(asset)
		end
		-- the stretch of the road's own wall a building may stand against: clear of the boss pocket's opening
		local doorFrom, doorTo = skipS - skipGap - 6, skipS + skipGap + 6
		local function wallFree(s0, s1, side)
			if side == skipSide and s1 > doorFrom and s0 < doorTo then
				return false
			end
			return s0 >= d.From + 2 and s1 <= d.To - 2
		end
		-- Buildings end to end along both walls: `assets` in turn, `length` long each, `gap` between them. Each gets a
		-- solid block so players don't walk into it (`depth` deep, `height` tall).
		local function alongWalls(assets, length, depth, height, gap, offset)
			for _, side in { -1, 1 } do
				local n = side > 0 and 1 or 0
				local s = d.From + 2 + (offset or 0) * (side > 0 and 1 or 0)
				while s + length <= d.To - 2 do
					if wallFree(s, s + length, side) then
						n += 1
						local asset = assets[n % #assets + 1]
						local mid = s + length / 2
						if hasArt(asset) then
							Art.Spawn(asset, folder, at(mid, side * (half - 0.3), 0) * CFrame.Angles(0, math.rad(side < 0 and -90 or 90), 0), {})
						end
						local q = P.Solid(folder, "BuildingBlock", Vector3.new(depth, height, length - 1), at(mid, side * (half - depth / 2), height / 2))
						q.CanQuery = false
					end
					s += length + gap
				end
			end
		end
		-- the bushes are gameplay (RoadConfig.Bushes): keep scenery that stands in the road off them
		local function nearBush(s, x, r)
			for _, b in C.Bushes do
				if math.abs(b.S - s) < r + 8 and math.abs(b.X - x) < r + 8 then
					return true
				end
			end
			return false
		end
		local function prop(asset, s, x, yaw, scale, r)
			if not hasArt(asset) or busy(s, x, r or 4) or nearBush(s, x, r or 4) then
				return {}
			end
			return put(asset, s, x, scale or 1, yaw or rng:NextInteger(0, 359))
		end
		local function scatterProps(assets, count, minX, maxX, r)
			for k = 1, count do
				local s = rng:NextNumber(d.From + 10, d.ArenaFrom - 10)
				local x = (rng:NextNumber() < 0.5 and -1 or 1) * rng:NextNumber(minX, maxX)
				prop(assets[(k - 1) % #assets + 1], s, x, nil, 1, r)
			end
		end

		if d.Name == "roadDarkForest" then
			-- Round dark-green trees and bare twisted ones down both sides, lanterns hanging over the path, blue
			-- mushrooms, grey rocks and a fallen log (the concept's dark forest)
			local k = 0
			for s = d.From + 12, d.To - 8, 30 do
				for _, side in { -1, 1 } do
					k += 1
					local round = k % 3 ~= 0
					put(round and "MR_ForestTree" or "MR_TwistedTree", s + rng:NextNumber(-6, 6), side * rng:NextNumber(48, 62), round and rng:NextNumber(2.2, 2.7) or rng:NextNumber(1.8, 2.3), rng:NextInteger(0, 359))
				end
			end
			scatter("MR_TwistedTree", 3, 26, 40, 1.3, 1.7, 6)
			scatter("MR_Mushrooms", 6, 14, 44, 1.6, 2.4, 2)
			scatter("MR_Rocks", 4, 14, 50, 1.6, 2.8)
			scatter("MR_GrassClump", 10, 10, 66, 1.2, 2, 1)
			for s = d.From + 30, d.To - 10, 90 do
				for _, side in { -1, 1 } do
					put("MR_HangingLantern", s, side * 12, 1.7, side < 0 and 0 or 180)
					lamp(s, side * 10.5, 10, hex("FFB146"), 24)
				end
			end
		elseif d.Name == "roadBackrooms" then
			-- Yellow wallpapered walls with fluorescent tubes, doorway partitions and short corner pieces jutting out
			-- from the walls, free-standing pillars; the carpet's lighter strip down the middle is the path
			alongWalls({ "BR_WallPanel" }, 32.2, 1.8, 14, 0)
			for _, side in { -1, 1 } do
				for s = d.From + 20 + (side > 0 and 32 or 0), d.To - 10, 64 do
					if wallFree(s - 4, s + 4, side) and hasArt("BR_Fluorescent") then
						put("BR_Fluorescent", s, side * (half - 2.2), 1, side < 0 and -90 or 90, 11)
						lamp(s, side * (half - 4), 11, hex("FFF4CC"), 26, true)
					end
				end
				-- a doorway partition every so often, square to the wall, and an L-shaped corner piece in between
				for s = d.From + 60 + (side > 0 and 55 or 0), d.ArenaFrom - 20, 110 do
					if wallFree(s - 2, s + 2, side) and not nearBush(s, side * (half - 14), 14) and hasArt("BR_DoorPartition") then
						put("BR_DoorPartition", s, side * (half - 14), 1, 0)
						local q = P.Solid(folder, "BuildingBlock", Vector3.new(28, 14, 1.7), at(s, side * (half - 14), 7))
						q.CanQuery = false
					end
					local c = s + 55
					if c < d.ArenaFrom - 20 and wallFree(c - 6, c + 6, side) and not nearBush(c, side * (half - 10), 10) and hasArt("BR_CornerPartition") then
						put("BR_CornerPartition", c, side * (half - 10), 1, side < 0 and 0 or 180)
					end
				end
			end
			for s = d.From + 45, d.ArenaFrom - 20, 70 do
				local x = (math.floor((s - d.From) / 70) % 2 == 0 and -1 or 1) * rng:NextNumber(30, 44)
				if hasArt("BR_Pillar") and not busy(s, x, 3) and not nearBush(s, x, 3) then
					put("BR_Pillar", s, x, 1, 0)
					local q = P.Solid(folder, "BuildingBlock", Vector3.new(3.9, 16, 3.9), at(s, x, 8))
					q.CanQuery = false
				end
			end
		elseif d.Name == "roadCity" then
			-- Asphalt with a yellow dashed middle line and edge lines, long grey facades along both walls, wrecked
			-- cars, street lights, trees in planters, rubble, crates and barrels
			for s = d.From + 5, d.To - 5, 14 do
				part(folder, "LaneDash", Vector3.new(1, 0.07, 7), at(s, 0, 0.04), hex("E8C33A"))
			end
			for _, side in { -1, 1 } do
				strip("LaneEdge", 1, 0.07, side * 30, 0.04, hex("E8C33A"))
			end
			alongWalls({ "AC_FacadeLongA", "AC_FacadeLongB" }, 64.7, 7.7, 22, 2)
			for _, side in { -1, 1 } do
				for s = d.From + 30 + (side > 0 and 40 or 0), d.To - 20, 80 do
					if wallFree(s - 4, s + 4, side) and hasArt("AC_Streetlight") then
						-- the lamp's arm reaches over the road
						put("AC_Streetlight", s, side * (half - 12), 1, side < 0 and 0 or 180)
						lamp(s, side * (half - 17), 17, hex("FFE3A0"), 28)
					end
				end
				for s = d.From + 70 + (side > 0 and 60 or 0), d.ArenaFrom - 20, 120 do
					if wallFree(s - 6, s + 6, side) then
						prop("AC_PlanterTree", s, side * (half - 15), side < 0 and -90 or 90, 1, 6)
					end
				end
			end
			for k = 1, 6 do
				local s = rng:NextNumber(d.From + 20, d.ArenaFrom - 20)
				local x = (k % 2 == 0 and -1 or 1) * rng:NextNumber(18, 44)
				prop(k % 2 == 0 and "AC_CarBlue" or "AC_CarRust", s, x, rng:NextInteger(-25, 25) + (k % 3 == 0 and 180 or 0), 1, 7)
			end
			scatterProps({ "SH_Rubble", "SH_Crate", "SH_Barrel", "SH_Rubble" }, 10, 16, 50, 3)
		elseif d.Name == "roadVillage" then
			-- Long timbered houses along both walls with gaps between, carts, wells, dead trees, broken fences,
			-- crates and barrels; lanterns over the path
			alongWalls({ "AV_HouseLongA", "AV_HouseLongB" }, 60.8, 8.5, 20, 18, 30)
			for k = 1, 3 do
				prop("AV_Well", rng:NextNumber(d.From + 40, d.ArenaFrom - 30), (k % 2 == 0 and -1 or 1) * rng:NextNumber(22, 34), nil, 1, 6)
				prop("AV_Cart", rng:NextNumber(d.From + 40, d.ArenaFrom - 30), (k % 2 == 1 and -1 or 1) * rng:NextNumber(22, 40), nil, 1, 8)
			end
			scatterProps({ "AV_DeadTree", "AV_FenceBroken", "SH_Crate", "SH_Barrel", "AV_DeadTree", "SH_Barrel" }, 14, 18, 50, 4)
			for s = d.From + 30, d.To - 10, 90 do
				for _, side in { -1, 1 } do
					put("MR_HangingLantern", s, side * 13, 1.6, side < 0 and 0 or 180)
					lamp(s, side * 11.5, 9.5, hex("FFC46B"), 24)
				end
			end
		elseif d.Name == "roadParasitown" then
			-- Grey checkered paving with a lighter lane down the middle, charcoal facades eaten by dark red growth along
			-- both walls, a few flat infected patches close to them; nothing grows out into the road (the tentacles are
			-- the boss arena's alone)
			for s = d.From + 6, d.To - 6, 12 do
				for x = -half + 6, half - 6, 12 do
					if (math.floor(s / 12) + math.floor(x / 12)) % 2 == 0 and math.abs(x) > 10 then
						part(folder, "Tile", Vector3.new(11.9, 0.04, 11.9), at(s, x, 0.02), hex("9C9A9A"))
					end
				end
			end
			alongWalls({ "PT_InfectedFacadeA", "PT_InfectedFacadeB" }, 65, 8.6, 21, 2)
			for _, side in { -1, 1 } do
				for s = d.From + 50 + (side > 0 and 90 or 0), d.ArenaFrom - 20, 180 do
					if wallFree(s - 6, s + 6, side) then
						prop("PT_InfectionPatch", s, side * (half - 12), side < 0 and -90 or 90, 1, 5)
					end
				end
			end
			for s = d.From + 30, d.To - 10, 90 do
				for _, side in { -1, 1 } do
					put("MR_HangingLantern", s, side * 12, 1.6, side < 0 and 0 or 180)
					lamp(s, side * 10.5, 9.5, hex("DDE8E6"), 22)
				end
			end
		elseif d.Name == "roadCave" then
			-- The blood mine, kept readable: grey-brown rock walls with mine mouths (a red glow inside the open ones),
			-- carts on broken rails, ore, timber, rubble and torches that always burn
			alongWalls({ "BM_RockWall", "BM_EntranceOpen", "BM_RockWall", "BM_EntranceBoarded" }, 56.5, 7.5, 16, 1)
			for k = 1, 5 do
				local s = rng:NextNumber(d.From + 30, d.ArenaFrom - 30)
				local x = (k % 2 == 0 and -1 or 1) * rng:NextNumber(20, 40)
				if not busy(s, x, 8) and not nearBush(s, x, 8) then
					prop("BM_RailBroken", s, x, rng:NextInteger(-10, 10), 1, 7)
					prop("BM_Minecart", s + 3, x, rng:NextInteger(-15, 15), 1, 0)
				end
			end
			scatterProps({ "BM_OreCluster", "BM_TimberPile", "SH_Rubble", "BM_OreCluster", "SH_Rubble" }, 16, 16, 52, 4)
			for s = d.From + 25, d.To - 10, 70 do
				for _, side in { -1, 1 } do
					if hasArt("BM_Torch") then
						put("BM_Torch", s, side * 13, 1, 0)
					end
					lamp(s, side * 13, 8, hex("FF8A3D"), 20, true)
				end
			end
		end
		skipS = nil
		buildPocket(d, folder)
		task.wait()
	end

	-- The far end: the same block wall across the road
	local cap = P.Solid(world, "RoadEndWall", Vector3.new(W + 8, 44, 4), at(C.Length + 2, 0, 20))
	cap.CanQuery = true
	local last = districts[#districts]
	for row = 0, 1 do
		for x = -half - 2, half + 2, 20 do
			part(root, "WallBlock", Vector3.new(19.8, 9.85, 4), at(C.Length + 1, x + (row % 2) * 10, row * 10 + 5), hex(last.Wall[rng:NextInteger(1, #last.Wall)]))
		end
	end
	part(root, "WallCoping", Vector3.new(W + 10, 0.8, 4.8), at(C.Length + 1, 0, 20.4), hex(last.Cap))
end

-- The entrance (owner, 2026-11-12: "improve the gate to the ruins, make it presentable and fitting"). Two castle
-- towers in the island wall's stone stand where that wall meets the road and close its ends; a battlemented
-- bridge spans the road between them with the big sign hanging on chains under it, banners either side.
-- Iron gate leaves stand swung open against the towers, and a paved threshold covers the
-- seam between the island lawn and the road.
function A.BuildEntrance(world, at, C, P)
	local m = Instance.new("Model")
	m.Name = "RoadEntrance"
	m.Parent = world
	local half = C.Width / 2
	-- Gloomy since 2026-11-15 (owner: "the purple gate and walls no longer fit the game"): weathered dark stone, slate
	-- roofs, tarnished brass and dark wood; no lights on it (no torches, lanterns or lit windows).
	local stones = { hex("5B5760"), hex("524E57"), hex("635F68"), hex("4A4750") }
	local coping, merlonColor, inner = hex("3A3640"), hex("45414B"), hex("2B2830")
	local roof, roofDark, iron, gold, wood = hex("3A3342"), hex("2A2530"), hex("26232B"), hex("8F7A44"), hex("4A3527")
	local rng = Random.new(512)
	local function piece(name, size, cf, color, material, shape)
		local q = Instance.new("Part")
		q.Name = name
		q.Size = size
		q.CFrame = cf
		q.Color = color
		q.Material = material or Enum.Material.SmoothPlastic
		q.Anchored, q.CanCollide, q.CanQuery, q.CanTouch = true, false, false, false
		q.TopSurface, q.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		if shape then
			q.Shape = shape
		end
		q.Parent = m
		return q
	end
	-- Paved threshold over the seam: cobbles from the lawn into the road
	piece("Threshold", Vector3.new(C.Width + 30, 0.2, 18), at(0, 0, -0.02), hex("6E6A70"), Enum.Material.Cobblestone)
	for _, s in { -8.6, 8.6 } do
		piece("ThresholdKerb", Vector3.new(C.Width + 30, 0.3, 1.2), at(s, 0, 0.03), hex("55515A"), Enum.Material.Slate)
	end

	-- Towers: block rows like the island wall, battlements, a purple spire with a pennant
	-- Taller since 2026-11-13 (owner: "make the gate to the ruins higher"): towers 56 high, the bridge at 40.
	local T, tall = 16, 56
	for _, side in { -1, 1 } do
		local x = side * (half + T / 2 - 1)
		local core = P.Solid(m, "TowerCore", Vector3.new(T - 0.6, tall, T - 0.6), at(2, x, tall / 2))
		core.CanQuery = false
		core.Transparency, core.Color, core.Material = 0, inner, Enum.Material.SmoothPlastic
		local rows = math.floor(tall / 3.2)
		for row = 0, rows - 1 do
			local y = row * 3.2 + 1.6
			-- staggered courses: four whole blocks, then three and two halves
			local course = row % 2 == 0 and { { -6, 3.95 }, { -2, 3.95 }, { 2, 3.95 }, { 6, 3.95 } } or { { -7, 1.95 }, { -4, 3.95 }, { 0, 3.95 }, { 4, 3.95 }, { 7, 1.95 } }
			for face = 0, 3 do
				local yaw = face * math.pi / 2
				for _, b in course do
					piece("TowerBlock", Vector3.new(b[2], 3.08, 1.2), at(2, x, y) * CFrame.Angles(0, yaw, 0) * CFrame.new(b[1], 0, -T / 2 + 0.55), stones[rng:NextInteger(1, #stones)])
				end
			end
		end
		piece("TowerPlinth", Vector3.new(T + 1.6, 1.4, T + 1.6), at(2, x, 0.7), inner, Enum.Material.Slate)
		piece("TowerCoping", Vector3.new(T + 2, 1.2, T + 2), at(2, x, tall + 0.6), coping)
		for face = 0, 3 do
			for k = -1, 1, 2 do
				piece("TowerMerlon", Vector3.new(3.4, 3, 1.6), at(2, x, tall + 2.7) * CFrame.Angles(0, face * math.pi / 2, 0) * CFrame.new(k * 4.6, 0, -T / 2 - 0.2), merlonColor)
			end
			-- arrow slits and a dark window on every face (they glowed until 2026-11-15)
			piece("TowerSlit", Vector3.new(1, 4.5, 0.4), at(2, x, 20) * CFrame.Angles(0, face * math.pi / 2, 0) * CFrame.new(0, 0, -T / 2 - 0.1), iron)
			piece("TowerWindow", Vector3.new(3.2, 4.4, 0.3), at(2, x, 40) * CFrame.Angles(0, face * math.pi / 2, 0) * CFrame.new(0, 0, -T / 2 - 0.12), hex("1C1A20"))
			piece("TowerWindowArch", Vector3.new(4.2, 0.8, 0.5), at(2, x, 42.5) * CFrame.Angles(0, face * math.pi / 2, 0) * CFrame.new(0, 0, -T / 2 - 0.15), coping)
		end
		-- spire: stacked discs narrowing upwards
		for k, r in { 15, 12.4, 9.8, 7.2, 4.8, 2.6 } do
			local disc = piece("TowerSpire", Vector3.new(2.6, r, r), at(2, x, tall + 4.4 + (k - 1) * 2.4) * CFrame.Angles(0, 0, math.pi / 2), k % 2 == 0 and roofDark or roof, nil, Enum.PartType.Cylinder)
			disc:SetAttribute("Spire", true)
		end
		piece("SpireFinial", Vector3.new(1.4, 1.4, 1.4), at(2, x, tall + 19.4), gold, Enum.Material.Metal, Enum.PartType.Ball)
		piece("FlagPole", Vector3.new(0.35, 6, 0.35), at(2, x, tall + 22.4), gold, Enum.Material.Metal)
		piece("Pennant", Vector3.new(0.15, 2.4, 4.2), at(2, x, tall + 24.2) * CFrame.new(0, 0, side * 2.2), hex("7A1A2A"))
		-- (no torches on the towers since 2026-11-15)
		-- The shutter (owner, 2026-11-13: "on a Blood Moon, gate shutters that close the way to the ruins"): a great
		-- leaf of planks and iron, hinged at the tower. It is built shut, across its half of the road, then swung open
		-- against the road's edge; FarmGateVisuals swings it shut on the client while workspace.RoadClosed is set.
		-- Only a picture: the Blood Moon barrier (RoadService.SetClosed) is what stops people.
		local hinge = 2 + T / 2
		local leafLen, leafTall = half - 1.2, 26
		local shutter = Instance.new("Model")
		shutter.Name = "RuinsShutter"
		shutter:SetAttribute("Side", side)
		local pivot = piece("Hinge", Vector3.one * 0.3, at(hinge, side * (half - 1.2), 0), iron)
		pivot.Transparency = 1
		pivot.Parent = shutter
		shutter.PrimaryPart = pivot
		local function onLeaf(t, y, z) return pivot.CFrame * CFrame.new(-side * t, y, z or 0) end -- t runs from the hinge inward
		local planks = math.ceil(leafLen / 4.6)
		for k = 0, planks - 1 do
			local w = leafLen / planks
			piece("ShutterPlank", Vector3.new(w - 0.12, leafTall - (k % 2) * 0.8, 1.2), onLeaf((k + 0.5) * w, 0.4 + (leafTall - (k % 2) * 0.8) / 2), k % 2 == 0 and wood or hex("3D2B20"), Enum.Material.WoodPlanks).Parent = shutter
		end
		for _, y in { 3, leafTall / 2, leafTall - 2.5 } do
			piece("ShutterBand", Vector3.new(leafLen - 0.4, 1.1, 1.5), onLeaf(leafLen / 2, y), iron, Enum.Material.Metal).Parent = shutter
			for k = 1, 7 do
				piece("ShutterRivet", Vector3.new(0.6, 0.6, 1.7), onLeaf(k * leafLen / 8, y), gold, Enum.Material.Metal).Parent = shutter
			end
		end
		-- a diagonal brace and a top row of spikes
		local brace = piece("ShutterBrace", Vector3.new(1.4, math.sqrt(leafLen ^ 2 + (leafTall - 7) ^ 2), 1.4), onLeaf(leafLen / 2, leafTall / 2, -0.5), iron, Enum.Material.Metal)
		brace.CFrame = brace.CFrame * CFrame.Angles(0, 0, side * math.atan2(leafLen, leafTall - 7))
		brace.Parent = shutter
		for k = 0, planks - 1 do
			piece("ShutterSpike", Vector3.new(1, 1, 1), onLeaf((k + 0.5) * leafLen / planks, leafTall + 0.7) * CFrame.Angles(0, 0, math.pi / 4), iron, Enum.Material.Metal).Parent = shutter
		end
		piece("ShutterSkull", Vector3.new(3, 3, 1.8), onLeaf(leafLen - 3, leafTall / 2 + 4, -0.8), hex("F3EBDD"), Enum.Material.SmoothPlastic, Enum.PartType.Ball).Parent = shutter
		shutter.Parent = m
		shutter:PivotTo(pivot.CFrame * CFrame.Angles(0, -side * math.pi / 2, 0)) -- open: along the road's edge
	end

	-- The bridge between the towers: a stone span with battlements on both edges and a dark arch band underneath
	local span = C.Width - 1
	local y0, depth = 40, 8
	local seg = span / 20
	for k = 0, 19 do
		local x = -span / 2 + seg * (k + 0.5)
		piece("BridgeBlock", Vector3.new(seg - 0.12, 5, depth), at(2, x, y0 + 2.5), stones[k % #stones + 1])
	end
	piece("BridgeArch", Vector3.new(span, 1, depth + 0.4), at(2, 0, y0 - 0.2), inner)
	piece("BridgeCoping", Vector3.new(span + 1, 0.9, depth + 1.2), at(2, 0, y0 + 5.4), coping)
	for k = 0, 19 do
		local x = -span / 2 + seg * (k + 0.5)
		if k % 2 == 0 then
			for _, e in { -1, 1 } do
				piece("BridgeMerlon", Vector3.new(seg - 0.6, 2.6, 1.4), at(2 + e * (depth / 2), x, y0 + 7.1), merlonColor)
			end
		end
	end

	-- The sign: a framed purple board on two chains, the name on both faces (home side and ruins side)
	local signY, signW, signH = 30, 64, 9
	piece("SignBoard", Vector3.new(signW, signH, 1.2), at(2, 0, signY), wood, Enum.Material.WoodPlanks)
	for _, e in { -1, 1 } do
		piece("SignFrame", Vector3.new(signW + 1.6, 0.9, 1.6), at(2, 0, signY + e * (signH / 2 + 0.2)), gold, Enum.Material.Metal)
		piece("SignFrame", Vector3.new(0.9, signH + 1.4, 1.6), at(2, e * (signW / 2 + 0.3), signY), gold, Enum.Material.Metal)
		for c = 0, 3 do
			piece("Chain", Vector3.new(0.5, 1.2, 0.5), at(2, e * (signW / 2 - 6), signY + signH / 2 + 0.9 + c * 1.25) * CFrame.Angles(0, c % 2 * math.pi / 2, 0), iron, Enum.Material.Metal)
		end
		-- a skull at each end of the board
		local skull = at(2, e * (signW / 2 + 4.4), signY)
		piece("Skull", Vector3.new(4.6, 4.6, 4.6), skull, hex("F3EBDD"), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		piece("SkullJaw", Vector3.new(3.2, 1.6, 3.4), skull * CFrame.new(0, -2.2, 0), hex("E6DCCB"))
		for _, f in { 0, math.pi } do
			for _, ex in { -0.95, 0.95 } do
				piece("SkullEye", Vector3.new(1.3, 1.3, 1.3), skull * CFrame.Angles(0, f, 0) * CFrame.new(ex, 0.3, -1.85), hex("1A181C"), nil, Enum.PartType.Ball) -- dark hollows (they glowed green until 2026-11-15)
			end
		end
	end
	for _, face in { { math.pi, "signRoad" }, { 0, "signRoadHome" } } do
		local label = P.SignText(m, at(2, 0, signY) * CFrame.Angles(0, face[1], 0) * CFrame.new(0, 0, -0.66), Vector3.new(signW - 6, signH - 2.4, 0.1), face[2], hex("FFE7A3"))
		-- big letters: scaled text tops out at 100 px, so the board gets fewer pixels per stud
		label.Parent.PixelsPerStud = 15
		local stroke = Instance.new("UIStroke")
		stroke.Color, stroke.Thickness = hex("2A1240"), 3
		stroke.Parent = label
	end

	-- Banners hanging from the bridge (its two lanterns went on 2026-11-15)
	for _, x in { -46, 46 } do
		for _, e in { -1, 1 } do
			piece("Banner", Vector3.new(6, 13, 0.3), at(2 + e * (depth / 2 + 0.25), x, y0 - 6.6), hex("8E1F35"))
			piece("BannerSigil", Vector3.new(2.6, 2.6, 0.35), at(2 + e * (depth / 2 + 0.3), x, y0 - 5) * CFrame.Angles(0, 0, math.rad(45)), gold)
			piece("BannerTail", Vector3.new(6, 1.2, 0.32), at(2 + e * (depth / 2 + 0.25), x, y0 - 13.4), hex("6B1427"))
		end
	end
	return m
end

return A
