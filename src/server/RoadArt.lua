-- The ruins road, dressed after the owner's reference picture (2026-11-09): one long walled corridor, a path
-- down the middle and six locations in a row — forest, dark forest, hospital, village, cultist cave, factory —
-- each with its own look, each a little darker. The walls are the island's block wall, recoloured
-- per location. Physical floors and gameplay colliders belong to RoadService; everything here is decoration
-- except a few solid building blocks that players (not mutants) bump into.
local S = game.ReplicatedStorage.Shared
local Art = require(S.ArtKit)
local WA = require(S.WorldArt)
local A = {}

local function hex(h)
	return Color3.fromHex(h)
end

function A.Build(world, at, C, districts, P)
	local root = Instance.new("Model")
	root.Name = "RoadArt"
	root:SetAttribute("Revision", 3)
	root.Parent = world
	local rng = Random.new(9032)
	local W = C.Width
	local half = W / 2

	local function part(parent, name, size, cf, color, material, shape)
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

	for i, d in districts do
		local folder = Instance.new("Model")
		folder.Name = d.Name
		folder:SetAttribute("RecommendedSpeed", d.RecommendedSpeed)
		folder.Parent = root
		local length = d.To - d.From
		local function put(asset, s, x, scale, yaw, y)
			return Art.Spawn(asset, folder, at(s, x, y or 0) * CFrame.Angles(0, math.rad(yaw or 0), 0), { scale = scale or 1 })
		end
		-- A solid block inside a building: players bump into it, mutants (not queried) path past it.
		local function block(s, x, size)
			local q = P.Solid(folder, "BuildingBlock", size, at(s, x, size.Y / 2))
			q.CanQuery = false
			return q
		end
		local function lamp(s, x, y, color, range, always)
			local anchor = part(folder, "LampLight", Vector3.one * 0.2, at(s, x, y), hex("FFFFFF"))
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
			part(folder, "WallCoping", Vector3.new(4.8, 0.8, length), at(d.From + length / 2, x, rows * course + 0.4), hex(d.Cap))
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
				part(folder, "LaneEdge", Vector3.new(1, 0.07, length), at(d.From + length / 2, side * 30, 0.04), hex("FFD23F"))
				for s = d.From + 60 + (side > 0 and 75 or 0), d.To - 60, 150 do
					put("MR_Factory", s, side * 54, 2.1, side < 0 and -90 or 90)
					block(s, side * 54, Vector3.new(32, 28, 46))
				end
				part(folder, "Pipe", Vector3.new(length, 2.4, 2.4), at(d.From + length / 2, side * (half - 1.5), 14) * CFrame.Angles(0, math.pi / 2, 0), hex("8D9AA3"), Enum.Material.Metal, Enum.PartType.Cylinder)
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
			put("MR_ArenaSeal", C.Imps[#C.Imps].S, 0, 5, 0, 0.025)
		end
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

return A
