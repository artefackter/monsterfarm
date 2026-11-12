-- The ruins road, dressed after the owner's reference picture (2026-11-09): one long walled corridor, a path
-- down the middle and six locations in a row — forest, dark forest, hospital, village, cultist cave, factory —
-- each with its own look, each a little darker. The walls are the island's block wall, recoloured
-- per location. Physical floors and gameplay colliders belong to RoadService; everything here is decoration
-- except a few solid building blocks that players (not mutants) bump into.
-- Revision 4 (owner, 2026-11-12): every location ends in an amphitheatre, its boss's arena. The regular dressing
-- keeps clear of it; the arena gets a sand floor, a low podium wall, curved stands rising outside the corridor
-- walls and a gate with the boss's name at each end.
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
	root:SetAttribute("Revision", 4)
	root.Parent = world
	local rng = Random.new(9032)
	local W = C.Width
	local half = W / 2
	local toLocal = at(0, 0, 0):Inverse()
	-- The arena of the location being dressed: regular scenery whose centre falls in it is left out.
	local skipFrom, skipTo
	local function skipped(s)
		return skipFrom ~= nil and s > skipFrom and s < skipTo
	end
	local function alongOf(cf)
		return -(toLocal * cf).Position.Z
	end

	local function part(parent, name, size, cf, color, material, shape)
		if skipped(alongOf(cf)) then
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
	local function inGap(s, margin)
		return s + margin > C.Gap.From and s - margin < C.Gap.To
	end
	-- Keep scenery off the graves, the rubble and the jump.
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
		return inGap(s, r + 4)
	end

	-- The amphitheatre at the end of every location ------------------------------------------------------------------
	-- Floor: sand in a dark rim with a ring and the seal. Sides: a low podium wall on the corridor line, then an oval
	-- bowl of stepped stands that rises outside the walls (only the parts beyond the corridor are built, so both ends
	-- stay open for the road). Gates with the boss's name close the arena at both ends.
	local function buildArena(d, parent)
		local model = Instance.new("Model")
		model.Name = "Amphitheatre"
		model:SetAttribute("Boss", d.Index)
		model.Parent = parent
		local c, R = d.Arena, Progression.ArenaRadius
		local stone = hex(d.Wall[1])
		local dark = stone:Lerp(Color3.new(0, 0, 0), 0.4)
		local sand = hex(d.Path):Lerp(hex("E8D3A4"), 0.45)
		local function disc(name, radius, y, color, material)
			local q = part(model, name, Vector3.new(0.06, radius * 2, radius * 2), at(c, 0, y) * CFrame.Angles(0, 0, math.pi / 2), color, material, Enum.PartType.Cylinder)
			q.CastShadow = false
			return q
		end
		disc("ArenaRim", R + 2.5, 0.04, dark)
		disc("ArenaSand", R, 0.05, sand, Enum.Material.Sand)
		disc("ArenaLine", R * 0.58, 0.06, dark)
		disc("ArenaSandInner", R * 0.58 - 0.9, 0.07, sand, Enum.Material.Sand)
		Art.Spawn("MR_ArenaSeal", model, at(c, 0, 0.06), { scale = Vector3.new(4.2, 0.4, 4.2) })

		-- Podium wall on the corridor line: low, so the stands behind it show
		for _, side in { -1, 1 } do
			local x = side * (half + 1.5)
			local s = d.ArenaFrom - 6
			while s < d.ArenaTo + 6 - 0.5 do
				local len = math.min(8, d.ArenaTo + 6 - s)
				part(model, "PodiumWall", Vector3.new(3, 6, len - 0.15), at(s + len / 2, x, 3), math.floor(s / 8) % 2 == 0 and stone or stone:Lerp(dark, 0.25))
				s += 8
			end
			part(model, "PodiumCoping", Vector3.new(4, 0.8, d.ArenaTo - d.ArenaFrom + 12), at(c, x, 6.4), hex(d.Cap))
		end

		-- The stands: six tiers of an oval bowl, each a ring of blocks standing from below the road up to its seat
		local tiers, segments = 6, 64
		for k = 0, tiers - 1 do
			local a, b = 80 + k * 7, 62 + k * 9
			local top = 7 + k * 3.4
			local height = top + 14
			local color = k % 2 == 0 and stone or stone:Lerp(dark, 0.2)
			for n = 0, segments - 1 do
				local t0, t1 = n / segments * math.pi * 2, (n + 1) / segments * math.pi * 2
				local x0, u0 = a * math.cos(t0), b * math.sin(t0)
				local x1, u1 = a * math.cos(t1), b * math.sin(t1)
				local xm, um = (x0 + x1) / 2, (u0 + u1) / 2
				if math.abs(xm) >= half + 5 then
					local p0, p1 = at(c + u0, x0, 0).Position, at(c + u1, x1, 0).Position
					local mid = at(c + um, xm, top - height / 2).Position
					part(model, "Stand", Vector3.new(7.6, height, (p1 - p0).Magnitude + 0.5), CFrame.lookAt(mid, mid + (p1 - p0)), color)
				end
			end
		end
		-- Columns with fire bowls along the top row
		local a, b = 80 + tiers * 7, 62 + tiers * 9
		local topY = 7 + (tiers - 1) * 3.4
		for n = 0, 27 do
			local t = (n + 0.5) / 28 * math.pi * 2
			local x, u = a * math.cos(t), b * math.sin(t)
			if math.abs(x) >= half + 8 then
				part(model, "Column", Vector3.new(2.6, 12, 2.6), at(c + u, x, topY + 6), stone:Lerp(Color3.new(1, 1, 1), 0.15))
				part(model, "ColumnCap", Vector3.new(3.8, 1, 3.8), at(c + u, x, topY + 12.5), hex(d.Cap))
				if n % 2 == 0 then
					part(model, "ColumnFlame", Vector3.new(1.8, 1.8, 1.8), at(c + u, x, topY + 13.6), hex("FF8A3D"), Enum.Material.Neon, Enum.PartType.Ball)
				end
			end
		end
		-- Fire bowls at the four corners of the floor
		for _, q in { { -1, -1 }, { -1, 1 }, { 1, -1 }, { 1, 1 } } do
			local s, x = c + q[1] * (R - 14), q[2] * (half - 3)
			part(model, "BrazierStand", Vector3.new(1.4, 5, 1.4), at(s, x, 2.5), dark)
			part(model, "BrazierBowl", Vector3.new(1.2, 3.6, 3.6), at(s, x, 5.4) * CFrame.Angles(0, 0, math.pi / 2), dark, nil, Enum.PartType.Cylinder)
			local flame = part(model, "BrazierFlame", Vector3.new(2.2, 2.2, 2.2), at(s, x, 6.6), hex("FF8A3D"), Enum.Material.Neon, Enum.PartType.Ball)
			local light = Instance.new("PointLight")
			light.Color, light.Range, light.Brightness, light.Shadows = hex("FFA34D"), 28, 1.1, false
			light.Parent = flame
		end

		-- No gates across the road (owner, 2026-11-12: "remove the other gates"): the stands alone mark the arena.
	end

	for i, d in districts do
		local folder = Instance.new("Model")
		folder.Name = d.Name
		folder:SetAttribute("RecommendedSpeed", d.RecommendedSpeed)
		folder.Parent = root
		local length = d.To - d.From
		skipFrom, skipTo = d.ArenaFrom - 6, d.ArenaTo + 6
		local function put(asset, s, x, scale, yaw, y)
			if skipped(s) then
				return {}
			end
			return Art.Spawn(asset, folder, at(s, x, y or 0) * CFrame.Angles(0, math.rad(yaw or 0), 0), { scale = scale or 1 })
		end
		-- A solid block inside a building: players bump into it, mutants (not queried) path past it.
		local function block(s, x, size)
			if skipped(s) then
				return nil
			end
			local q = P.Solid(folder, "BuildingBlock", size, at(s, x, size.Y / 2))
			q.CanQuery = false
			return q
		end
		-- Long strips (coping, pipes, lane lines) run in two pieces, either side of the arena.
		local function strip(name, width, height, x, y, color, material, shape, rotate)
			for _, span in { { d.From, skipFrom }, { skipTo, d.To } } do
				local a, b = math.max(span[1], d.From), math.min(span[2], d.To)
				if b - a > 0.5 then
					local cf = at((a + b) / 2, x, y)
					if rotate then
						cf *= rotate
					end
					local size = rotate and Vector3.new(b - a, height, width) or Vector3.new(width, height, b - a)
					local saved = skipFrom
					skipFrom = nil
					part(folder, name, size, cf, color, material, shape)
					skipFrom = saved
				end
			end
		end
		local function lamp(s, x, y, color, range, always)
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
			if not (a < C.Gap.To and b > C.Gap.From) then
				part(folder, "Path", Vector3.new(18, 0.06, b - a), at((a + b) / 2, 0, 0.03), pathColor)
				for _, side in { -1, 1 } do
					part(folder, "PathEdge", Vector3.new(1.4, 0.07, b - a), at((a + b) / 2, side * 9.4, 0.035), pathColor:Lerp(Color3.new(0, 0, 0), 0.18))
				end
			end
		end

		-- The island's block wall, recoloured for this location, with buttresses and a coping
		local course, rows, blockLen = 5, 4, 10
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

		if d.Name == "roadForest" then
			-- A bright, friendly forest: round trees down both sides, rocks, mushrooms, a fallen log
			for s = d.From + 10, d.To - 6, 18 do
				for _, side in { -1, 1 } do
					put("MR_ForestTree", s + rng:NextNumber(-5, 5), side * rng:NextNumber(48, 62), rng:NextNumber(2.3, 2.9), rng:NextInteger(0, 359))
				end
			end
			scatter("MR_Rocks", 10, 14, 44, 1.6, 2.6)
			scatter("MR_Mushrooms", 14, 12, 40, 1.8, 2.6)
			scatter("MR_GrassClump", 50, 10, 66, 1.4, 2.4, 1)
			put("MR_Log", d.From + 60, 22, 1.8, 80)
		elseif d.Name == "roadDarkForest" then
			-- Bare twisted trees, grey rocks and lanterns hanging over the path
			for s = d.From + 12, d.To - 8, 22 do
				for _, side in { -1, 1 } do
					put("MR_TwistedTree", s + rng:NextNumber(-6, 6), side * rng:NextNumber(46, 62), rng:NextNumber(1.8, 2.4), rng:NextInteger(0, 359))
				end
			end
			scatter("MR_TwistedTree", 5, 26, 40, 1.3, 1.7, 6)
			scatter("MR_Rocks", 14, 14, 50, 1.6, 2.8)
			scatter("MR_LeafLitter", 22, 10, 60, 2.2, 3.4, 1)
			scatter("MR_GrassClump", 30, 10, 66, 1.2, 2, 1)
			for s = d.From + 30, d.To - 10, 45 do
				for _, side in { -1, 1 } do
					put("MR_HangingLantern", s, side * 12, 1.7, side < 0 and 0 or 180)
					lamp(s, side * 10.5, 10, hex("FFB146"), 24)
				end
			end
		elseif d.Name == "roadHospital" then
			-- A tiled courtyard between white blocks with a teal stripe; hospital buildings stand behind them
			for s = d.From + 6, d.To - 6, 12 do
				for x = -half + 6, half - 6, 12 do
					if (math.floor(s / 12) + math.floor(x / 12)) % 2 == 0 and not inGap(s, 6) then
						part(folder, "Tile", Vector3.new(11.9, 0.04, 11.9), at(s, x, 0.02), hex("C6CCC4"))
					end
				end
			end
			for _, side in { -1, 1 } do
				for s = d.From + 40, d.To - 40, 120 do
					put("MR_Hospital", s, side * 54, 2.1, side < 0 and -90 or 90)
					block(s, side * 54, Vector3.new(30, 24, 48))
				end
				for s = d.From + 8, d.To - 8, 16 do
					if (s - d.From) % 120 > 20 and (s - d.From) % 120 < 100 then
						part(folder, "CourtWall", Vector3.new(2, 4, 15), at(s, side * 38, 2), hex("EEF1F1"))
						part(folder, "CourtStripe", Vector3.new(2.05, 0.9, 15.05), at(s, side * 38, 2.6), hex("7FC6B6"))
					end
				end
			end
			for s = d.From + 60, d.To - 30, 90 do
				if not busy(s, 0, 6) then
					part(folder, "HelipadRing", Vector3.new(0.05, 14, 14), at(s, 0, 0.06) * CFrame.Angles(0, 0, math.pi / 2), hex("BDE7DE"), nil, Enum.PartType.Cylinder)
					part(folder, "HelipadCore", Vector3.new(0.06, 10, 10), at(s, 0, 0.07) * CFrame.Angles(0, 0, math.pi / 2), hex("E9F2EF"), nil, Enum.PartType.Cylinder)
				end
			end
			scatter("MR_Cart", 10, 16, 34, 1.4, 1.7)
			scatter("MR_GrassClump", 30, 8, 36, 1, 1.6, 1)
			for s = d.From + 30, d.To - 10, 60 do
				for _, side in { -1, 1 } do
					put("MR_HangingLantern", s, side * 12, 1.6, side < 0 and 0 or 180)
					lamp(s, side * 10.5, 9.5, hex("CFF5EC"), 22)
				end
			end
		elseif d.Name == "roadVillage" then
			-- Paved square, timbered houses on both sides, a well and carts
			for s = d.From + 4, d.To - 4, 8 do
				for x = -half + 4, half - 4, 8 do
					if rng:NextNumber() < 0.22 and not inGap(s, 4) then
						part(folder, "Flagstone", Vector3.new(7.6, 0.05, 7.6), at(s, x, 0.025), hex(d.Floor):Lerp(Color3.new(1, 1, 1), rng:NextNumber(0.05, 0.16)))
					end
				end
			end
			for _, side in { -1, 1 } do
				for s = d.From + 30 + (side > 0 and 30 or 0), d.To - 25, 62 do
					put("MR_VillageHouse", s, side * 55, rng:NextNumber(1.8, 2.1), side < 0 and -90 or 90)
					block(s, side * 55, Vector3.new(26, 26, 28))
				end
			end
			for s = d.From + 70, d.To - 40, 130 do
				if not busy(s, -26, 5) then
					put("MR_Well", s, -26, 1.5)
				end
				if not busy(s + 50, 28, 6) then
					put("MR_Cart", s + 50, 28, 1.7, 25)
				end
			end
			scatter("MR_GrassClump", 40, 8, 44, 1.2, 2, 1)
			for s = d.From + 30, d.To - 10, 55 do
				for _, side in { -1, 1 } do
					put("MR_HangingLantern", s, side * 13, 1.6, side < 0 and 0 or 180)
					lamp(s, side * 11.5, 9.5, hex("FFC46B"), 24)
				end
			end
		elseif d.Name == "roadCave" then
			-- Rock arches along the walls, skulls, rune stones, red banners and torches that always burn
			for _, side in { -1, 1 } do
				for s = d.From + 40 + (side > 0 and 45 or 0), d.To - 30, 90 do
					put("MR_CultCave", s, side * 56, 2.4, side < 0 and -90 or 90)
					block(s, side * 58, Vector3.new(12, 20, 40))
				end
				for s = d.From + 10, d.To - 10, 40 do
					part(folder, "Banner", Vector3.new(0.3, 9, 5), at(s, side * (half - 0.3), 12), hex("8E1F35"))
					part(folder, "BannerSigil", Vector3.new(0.35, 2.4, 2.4), at(s, side * (half - 0.4), 12.5) * CFrame.Angles(math.rad(45), 0, 0), hex("E4B34A"))
				end
			end
			scatter("MR_CultSkulls", 22, 12, 40, 1.8, 2.6)
			scatter("MR_RuneStone", 14, 16, 46, 2, 2.8)
			scatter("MR_Rocks", 18, 14, 60, 2, 3.4)
			for s = d.From + 25, d.To - 10, 45 do
				for _, side in { -1, 1 } do
					put("MR_CultTorch", s, side * 13, 2.2)
					lamp(s, side * 13, 8, hex("FF8A3D"), 20, true)
				end
			end
		elseif d.Name == "roadFactory" then
			-- Concrete, yellow lines, brick factory halls, boilers, tanks, barrels and pipes along the walls
			for s = d.From + 5, d.To - 5, 14 do
				if not inGap(s, 7) then
					part(folder, "LaneDash", Vector3.new(1, 0.07, 7), at(s, 0, 0.04), hex("FFD23F"))
				end
			end
			for _, side in { -1, 1 } do
				strip("LaneEdge", 1, 0.07, side * 30, 0.04, hex("FFD23F"))
				for s = d.From + 60 + (side > 0 and 75 or 0), d.To - 60, 150 do
					put("MR_Factory", s, side * 54, 2.1, side < 0 and -90 or 90)
					block(s, side * 54, Vector3.new(32, 28, 46))
				end
				strip("Pipe", 2.4, 2.4, side * (half - 1.5), 14, hex("8D9AA3"), Enum.Material.Metal, Enum.PartType.Cylinder, CFrame.Angles(0, math.pi / 2, 0))
				for s = d.From + 20, d.To - 10, 60 do
					part(folder, "PipeDrop", Vector3.new(14, 1.6, 1.6), at(s, side * (half - 1.5), 7) * CFrame.Angles(0, 0, math.pi / 2), hex("6E7A82"), Enum.Material.Metal, Enum.PartType.Cylinder)
				end
			end
			scatter("MR_Boiler", 8, 34, 44, 1.6, 1.9, 6)
			scatter("MR_RustTank", 8, 34, 44, 1.5, 1.8, 6)
			for _ = 1, 26 do
				local s = rng:NextNumber(d.From + 8, d.To - 8)
				local x = (rng:NextNumber() < 0.5 and -1 or 1) * rng:NextNumber(32, 44)
				if not busy(s, x, 3) then
					part(folder, "Barrel", Vector3.new(3, 2.4, 2.4), at(s, x, 1.5) * CFrame.Angles(0, 0, math.pi / 2), hex(rng:NextNumber() < 0.5 and "4FAE5B" or "D9A62E"), nil, Enum.PartType.Cylinder)
				end
			end
			for s = d.From + 40, d.To - 10, 70 do
				for _, side in { -1, 1 } do
					put("MR_HangingLantern", s, side * 13, 1.6, side < 0 and 0 or 180)
					lamp(s, side * 11.5, 9.5, hex("FFE29A"), 26)
				end
			end
		end
		skipFrom, skipTo = nil, nil
		buildArena(d, folder)
		task.wait()
	end

	-- The far end: the same block wall across the road
	local cap = P.Solid(world, "RoadEndWall", Vector3.new(W + 8, 44, 4), at(C.Length + 2, 0, 20))
	cap.CanQuery = true
	local last = districts[#districts]
	for row = 0, 3 do
		for x = -half - 2, half + 2, 10 do
			part(root, "WallBlock", Vector3.new(9.8, 4.85, 4), at(C.Length + 1, x + (row % 2) * 5, row * 5 + 2.5), hex(last.Wall[rng:NextInteger(1, #last.Wall)]))
		end
	end
	part(root, "WallCoping", Vector3.new(W + 10, 0.8, 4.8), at(C.Length + 1, 0, 20.4), hex(last.Cap))
end

-- The entrance (owner, 2026-11-12: "improve the gate to the ruins, make it presentable and fitting"). Two castle
-- towers in the island wall's lavender stone stand where that wall meets the road and close its ends; a battlemented
-- bridge spans the road between them with the big sign hanging on chains under it, banners and lanterns either side.
-- Iron gate leaves stand swung open against the towers, torches burn on their faces, and a paved threshold covers the
-- seam between the island lawn and the road.
function A.BuildEntrance(world, at, C, P)
	local m = Instance.new("Model")
	m.Name = "RoadEntrance"
	m.Parent = world
	local half = C.Width / 2
	local stones = { hex("C2B5E2"), hex("CDC1EA"), hex("DCD2F2"), hex("E7DEF7") }
	local coping, merlonColor, inner = hex("8C6BD6"), hex("A58BE6"), hex("625474")
	local roof, roofDark, iron, gold, wood = hex("8C4BFF"), hex("6A2FD0"), hex("3B3150"), hex("FFD34D"), hex("6B3F8F")
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
	local function flame(cf, size, range)
		local f = piece("Flame", Vector3.one * size, cf, hex("FF9A3D"), Enum.Material.Neon, Enum.PartType.Ball)
		local light = Instance.new("PointLight")
		light.Color, light.Range, light.Brightness, light.Shadows = hex("FFB45C"), range or 18, 1.2, false
		light.Parent = f
		return f
	end

	-- Paved threshold over the seam: cobbles from the lawn into the road
	piece("Threshold", Vector3.new(C.Width + 30, 0.2, 18), at(0, 0, -0.02), hex("A79FC2"), Enum.Material.Cobblestone)
	for _, s in { -8.6, 8.6 } do
		piece("ThresholdKerb", Vector3.new(C.Width + 30, 0.3, 1.2), at(s, 0, 0.03), hex("8C83AA"), Enum.Material.Slate)
	end

	-- Towers: block rows like the island wall, battlements, a purple spire with a pennant
	local T, tall = 16, 38
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
			-- arrow slits and a glowing window on every face
			piece("TowerSlit", Vector3.new(1, 4.5, 0.4), at(2, x, 14) * CFrame.Angles(0, face * math.pi / 2, 0) * CFrame.new(0, 0, -T / 2 - 0.1), iron)
			piece("TowerWindow", Vector3.new(3.2, 4.4, 0.3), at(2, x, 27) * CFrame.Angles(0, face * math.pi / 2, 0) * CFrame.new(0, 0, -T / 2 - 0.12), hex("FFD98A"), Enum.Material.Neon)
			piece("TowerWindowArch", Vector3.new(4.2, 0.8, 0.5), at(2, x, 29.5) * CFrame.Angles(0, face * math.pi / 2, 0) * CFrame.new(0, 0, -T / 2 - 0.15), coping)
		end
		-- spire: stacked discs narrowing upwards
		for k, r in { 15, 12.4, 9.8, 7.2, 4.8, 2.6 } do
			local disc = piece("TowerSpire", Vector3.new(2.6, r, r), at(2, x, tall + 4.4 + (k - 1) * 2.4) * CFrame.Angles(0, 0, math.pi / 2), k % 2 == 0 and roofDark or roof, nil, Enum.PartType.Cylinder)
			disc:SetAttribute("Spire", true)
		end
		piece("SpireFinial", Vector3.new(1.4, 1.4, 1.4), at(2, x, tall + 19.4), gold, Enum.Material.Metal, Enum.PartType.Ball)
		piece("FlagPole", Vector3.new(0.35, 6, 0.35), at(2, x, tall + 22.4), gold, Enum.Material.Metal)
		piece("Pennant", Vector3.new(0.15, 2.4, 4.2), at(2, x, tall + 24.2) * CFrame.new(0, 0, side * 2.2), hex("FF5468"))
		-- torches on both faces, low enough to light the threshold and the road
		for _, f in { -1, 1 } do
			local face = at(2 + f * (T / 2 + 0.6), x - side * 3.5, 9)
			piece("TorchBracket", Vector3.new(0.6, 0.6, 1.4), face, iron)
			piece("TorchCup", Vector3.new(1.4, 1.2, 1.4), face * CFrame.new(0, 0.7, 0), iron)
			flame(face * CFrame.new(0, 1.8, 0), 1.6, 20)
		end
		-- the gate leaf stands open against the tower, along the road edge
		local hinge = 2 + T / 2
		local leafLen, leafTall = 14, 17
		local leafX = side * (half - 1.8)
		for _, y in { 1.2, leafTall / 2, leafTall - 0.6 } do
			piece("GateRail", Vector3.new(0.6, 0.7, leafLen), at(hinge + leafLen / 2, leafX, y), iron, Enum.Material.Metal)
		end
		for k = 0, 7 do
			local s = hinge + 0.6 + k * (leafLen - 1.2) / 7
			piece("GateBar", Vector3.new(0.35, leafTall, 0.35), at(s, leafX, leafTall / 2), iron, Enum.Material.Metal)
			piece("GateSpike", Vector3.new(0.8, 0.8, 0.8), at(s, leafX, leafTall + 0.5), gold, Enum.Material.Metal, Enum.PartType.Ball)
		end
	end

	-- The bridge between the towers: a stone span with battlements on both edges and a dark arch band underneath
	local span = C.Width - 1
	local y0, depth = 26, 8
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
	local signY, signW, signH = 18.5, 64, 9
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
				piece("SkullEye", Vector3.new(1.3, 1.3, 1.3), skull * CFrame.Angles(0, f, 0) * CFrame.new(ex, 0.3, -1.85), hex("8CFF5A"), Enum.Material.Neon, Enum.PartType.Ball)
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

	-- Banners and lanterns hanging from the bridge
	for _, x in { -46, -30, 30, 46 } do
		local banner = math.abs(x) == 46
		if banner then
			for _, e in { -1, 1 } do
				piece("Banner", Vector3.new(6, 13, 0.3), at(2 + e * (depth / 2 + 0.25), x, y0 - 6.6), hex("8E1F35"))
				piece("BannerSigil", Vector3.new(2.6, 2.6, 0.35), at(2 + e * (depth / 2 + 0.3), x, y0 - 5) * CFrame.Angles(0, 0, math.rad(45)), gold)
				piece("BannerTail", Vector3.new(6, 1.2, 0.32), at(2 + e * (depth / 2 + 0.25), x, y0 - 13.4), hex("6B1427"))
			end
		else
			piece("LanternChain", Vector3.new(0.4, 4, 0.4), at(2, x, y0 - 2.4), iron, Enum.Material.Metal)
			piece("LanternTop", Vector3.new(2.8, 0.6, 2.8), at(2, x, y0 - 4.2), iron, Enum.Material.Metal)
			piece("LanternBottom", Vector3.new(2.4, 0.5, 2.4), at(2, x, y0 - 7.2), iron, Enum.Material.Metal)
			flame(at(2, x, y0 - 5.7), 1.9, 26)
		end
	end
	return m
end

return A
