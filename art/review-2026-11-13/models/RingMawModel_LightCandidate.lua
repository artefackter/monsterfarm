-- REVIEW ONLY. Do not sync until owner approval. Geometry unchanged.
-- The RingMaw, rebuilt from parts (owner, 2026-11-13: "the RingMaw looks poor and far from the original; it should be
-- the second boss"). Our own take on the gourd-headed horror: a ribbed orange gourd for a head that splits down the
-- middle into two halves (MawL, MawR). They swing open like doors on a hinge at the back of the head and uncover a
-- round maw: rings of teeth round a glowing throat. A dark hunched body stands on six long, thin, high-kneed legs.
-- The front pair are its "arms" (ArmL, ArmR), the back pair its "legs" (LegL, LegR), the middle pair moves with
-- the body. Each look is a manifest entry that ArtKit treats like an imported mesh, so the farm, the road and the
-- boss arena all build it the same way; the joints go into MonsterRig.
-- Coordinates: feet at y = 0, the face toward -Z, +X is the monster's right (as in the imported rigs).
local R = { Assets = {}, Rig = {} }

local H = Vector3.new(0, 9.3, -3.5) -- the head's centre
local NECK = Vector3.new(0, 6.9, -1.5)

-- Looks: Farmer, Punk and Assassin for the farm; Wild for the dark forest's pouncers; Boss for the arena.
local LOOKS = {
	Farmer = { gourd = { "D9772B", "C4621E" }, body = "66546F", legs = "594C64", glow = "E8552A", hat = true, scarf = true },
	Punk = { gourd = { "C25E2A", "A44C22" }, body = "67537D", legs = "59496D", glow = "FF4FA3", spikes = true, collar = true },
	Assassin = { gourd = { "C66A39", "A6512C" }, body = "584C67", legs = "4D445B", glow = "FF3B3B", hood = true, blades = true },
	Wild = { gourd = { "C8692A", "AD571F" }, body = "665870", legs = "594D66", glow = "FF6A2A" },
	Boss = { gourd = { "E07A26", "C25F1A" }, body = "64516B", legs = "584C67", glow = "FF3B2A", spikes = true, extraRing = true, veins = true, backSpikes = true },
}
local ASSETS = {
	RingMaw_Farmer_Passive = "Farmer", RingMaw_Farmer_Aggressive = "Farmer",
	RingMaw_Punk_Passive = "Punk", RingMaw_Punk_Aggressive = "Punk",
	RingMaw_Assassin_Passive = "Assassin", RingMaw_Assassin_Aggressive = "Assassin",
	RingMaw_Passive = "Wild", RingMaw_Aggressive = "Wild", RingMaw_Boss = "Boss",
}

local function absolute(v)
	return Vector3.new(math.abs(v.X), math.abs(v.Y), math.abs(v.Z))
end

local function build(look)
	local list, used = {}, {}
	local function add(name, attach, size, cf, color, shape, material)
		-- names stay unique: ArtKit.Spawn and MutantModel find the parts by name
		used[name] = (used[name] or 0) + 1
		if used[name] > 1 then
			name ..= used[name]
		end
		local r = cf.Rotation
		local half = size / 2
		local box = (absolute(r.RightVector) * half.X + absolute(r.UpVector) * half.Y + absolute(r.LookVector) * half.Z) * 2
		table.insert(list, { part = name, attach = attach, size = size, offset = cf.Position, rot = r, box = box, avg = color,
			shape = shape or "Block", material = material or "SmoothPlastic", transparency = 0, cast = true, procedural = true })
	end
	-- a cylinder from a to b (a cylinder's axis is its X)
	local function rod(name, attach, a, b, thick, color, material)
		local mid = (a + b) / 2
		local cf = CFrame.lookAt(mid, b) * CFrame.Angles(0, math.pi / 2, 0)
		add(name, attach, Vector3.new((b - a).Magnitude, thick, thick), cf, color, "Cylinder", material)
	end

	-- Body: a hunched thorax and a raised abdomen, spines along the back
	add("Body", nil, Vector3.new(4.2, 3.3, 5), CFrame.new(0, 6.1, 0.7) * CFrame.Angles(-0.12, 0, 0), look.body, "Ellipsoid")
	add("Abdomen", nil, Vector3.new(3.8, 3.2, 4.6), CFrame.new(0, 6.7, 4.3) * CFrame.Angles(0.3, 0, 0), look.body, "Ellipsoid")
	local spike = look.backSpikes and Vector3.new(0.7, 2.3, 0.7) or Vector3.new(0.45, 1.3, 0.45)
	for _, at in { Vector3.new(0, 7.85, -0.6), Vector3.new(0, 8.05, 1), Vector3.new(0, 8.3, 2.8), Vector3.new(0, 8.25, 4.6) } do
		add("Spine", nil, spike, CFrame.new(at) * CFrame.Angles(0.55, 0, 0), look.backSpikes and "5A1E22" or "897499")
	end

	-- Neck and the head's core: dark flesh, the pit of the maw, rings of teeth, the glowing throat
	rod("Neck", "Head", NECK, H + Vector3.new(0, -1.1, 1.0), 1.1, look.body)
	add("Head", "Head", Vector3.new(3.4, 3.6, 3.4), CFrame.new(H), "863B44", "Ellipsoid")
	add("MawPit", "Head", Vector3.new(0.3, 3, 3), CFrame.new(H + Vector3.new(0, 0, -1.25)) * CFrame.Angles(0, math.pi / 2, 0), "28161F", "Cylinder")
	local rings = { { r = 1.32, n = 11, z = -1.55, s = 0.62 }, { r = 0.9, n = 8, z = -1.42, s = 0.5 }, { r = 0.5, n = 5, z = -1.32, s = 0.38 } }
	if look.extraRing then
		table.insert(rings, 1, { r = 1.68, n = 14, z = -1.62, s = 0.72 })
	end
	for k, ring in rings do
		for i = 0, ring.n - 1 do
			local a = (i + (k % 2) * 0.5) / ring.n * math.pi * 2
			local at = H + Vector3.new(math.cos(a) * ring.r, math.sin(a) * ring.r, ring.z)
			add("Tooth", "Head", Vector3.new(ring.s * 0.48, ring.s, ring.s * 0.48), CFrame.new(at) * CFrame.Angles(0, 0, a + math.pi / 2), "EDE3C6", "Ellipsoid")
		end
	end
	add("MawGlow", "Head", Vector3.new(0.85, 0.85, 0.85), CFrame.new(H + Vector3.new(0, 0, -1)), look.glow, "Ball", "Neon")

	-- The gourd: ribbed staves round the core. The left ones open with MawL, the right ones with MawR; the back
	-- stave and the stem stay with the head.
	for i, deg in { 20, 58, 98, 140, -20, -58, -98, -140, 180 } do
		local a = math.rad(deg)
		local attach = deg == 180 and "Head" or deg > 0 and "MawR" or "MawL"
		local cf = CFrame.new(H + Vector3.new(math.sin(a) * 1.5, 0, -math.cos(a) * 1.5)) * CFrame.Angles(0, -a, 0)
		add("Stave", attach, Vector3.new(2, 4.3, 1.55), cf, look.gourd[i % 2 + 1], "Ellipsoid")
		if look.veins and deg ~= 180 then
			add("Vein", attach, Vector3.new(0.14, 3.2, 0.14), cf * CFrame.new(0, 0, -0.74), "FF3B2A", "Block", "Neon")
		end
		if look.spikes and math.abs(deg) <= 60 then
			add("StaveSpike", attach, Vector3.new(0.38, 1.2, 0.38), cf * CFrame.new(0, 2.1, -0.2) * CFrame.Angles(-0.3, 0, 0), look.extraRing and "E6DCC4" or "D9D9E0", "Block", look.extraRing and "SmoothPlastic" or "Metal")
		end
	end
	if look.hat then -- a battered straw hat
		local up = CFrame.Angles(0, 0, math.pi / 2)
		add("HatBrim", "Head", Vector3.new(0.2, 5.6, 5.6), CFrame.new(H + Vector3.new(0, 2.1, 0.1)) * up * CFrame.Angles(0.06, 0, 0), "D8B66A", "Cylinder", "Fabric")
		add("HatCrown", "Head", Vector3.new(1.4, 2.7, 2.7), CFrame.new(H + Vector3.new(0, 2.8, 0.1)) * up, "CFAA5C", "Cylinder", "Fabric")
		add("HatBand", "Head", Vector3.new(0.4, 2.8, 2.8), CFrame.new(H + Vector3.new(0, 2.35, 0.1)) * up, "8C3B2A", "Cylinder", "Fabric")
	else
		add("Stem", "Head", Vector3.new(1.1, 0.55, 0.55), CFrame.new(H + Vector3.new(0, 2.25, 0.2)) * CFrame.Angles(0, 0, math.pi / 2), "4E3B22", "Cylinder", "Wood")
		add("StemCurl", "Head", Vector3.new(0.35, 0.35, 0.9), CFrame.new(H + Vector3.new(0, 2.8, 0.55)) * CFrame.Angles(0.6, 0, 0), "4E3B22", "Block", "Wood")
	end
	if look.scarf then
		add("Scarf", "Head", Vector3.new(2.2, 0.9, 1.8), CFrame.new(NECK + Vector3.new(0, 0.7, -0.5)), "A8322E", "Ellipsoid", "Fabric")
	end
	if look.collar then
		local mid = NECK + Vector3.new(0, 0.6, -0.4)
		add("Collar", "Head", Vector3.new(0.6, 2, 2), CFrame.lookAt(mid, mid + Vector3.new(0, 1.1, -1)) * CFrame.Angles(0, math.pi / 2, 0), "202020", "Cylinder", "Leather")
		for i = 0, 3 do
			local a = i / 4 * math.pi * 2
			add("CollarStud", "Head", Vector3.new(0.3, 0.3, 0.3), CFrame.new(mid + Vector3.new(math.cos(a) * 1, math.sin(a) * 0.7, 0)), "D9D9E0", "Ball", "Metal")
		end
	end
	if look.hood then
		add("Hood", "Head", Vector3.new(4.9, 4.8, 4.2), CFrame.new(H + Vector3.new(0, 0.45, 0.75)), "1A1620", "Ellipsoid", "Fabric")
	end

	-- Six legs: thigh up to a high knee, shin down, a thin tip to the ground
	local legs = {
		{ group = "Arm", hip = Vector3.new(1.5, 6.3, -0.9), knee = Vector3.new(4, 9.8, -2.4), ankle = Vector3.new(5.6, 4.2, -4.4), tip = Vector3.new(5.9, 0.1, -5) },
		{ group = "Mid", hip = Vector3.new(1.9, 6, 0.9), knee = Vector3.new(4.8, 9.2, 1.1), ankle = Vector3.new(6.6, 3.8, 1.6), tip = Vector3.new(6.9, 0.1, 1.8) },
		{ group = "Leg", hip = Vector3.new(1.6, 6.2, 2.9), knee = Vector3.new(4.2, 9.4, 4.9), ankle = Vector3.new(5.4, 4, 6.9), tip = Vector3.new(5.6, 0.1, 7.6) },
	}
	for _, leg in legs do
		for _, side in { 1, -1 } do
			local s = Vector3.new(side, 1, 1)
			local name = leg.group .. (side > 0 and "R" or "L")
			local attach = leg.group ~= "Mid" and name or nil
			rod(name, attach, leg.hip * s, leg.knee * s, 0.62, look.legs)
			add(name .. "Knee", attach, Vector3.new(0.85, 0.85, 0.85), CFrame.new(leg.knee * s), look.legs, "Ball")
			rod(name .. "Shin", attach, leg.knee * s, leg.ankle * s, 0.48, look.legs)
			add(name .. "Ankle", attach, Vector3.new(0.58, 0.58, 0.58), CFrame.new(leg.ankle * s), look.legs, "Ball")
			if look.blades then
				rod(name .. "Tip", attach, leg.ankle * s, leg.tip * s, 0.36, "C9CED6", "Metal")
			else
				rod(name .. "Tip", attach, leg.ankle * s, leg.tip * s, 0.3, look.legs)
			end
		end
	end
	return list
end

local RIG = {
	Head = NECK,
	MawR = H + Vector3.new(0.35, 0, 1.5), MawL = H + Vector3.new(-0.35, 0, 1.5), -- the hinges at the back of the head
	ArmR = Vector3.new(1.5, 6.3, -0.9), ArmL = Vector3.new(-1.5, 6.3, -0.9),
	LegR = Vector3.new(1.6, 6.2, 2.9), LegL = Vector3.new(-1.6, 6.2, 2.9),
}
local built = {}
for asset, lookName in ASSETS do
	built[lookName] = built[lookName] or build(LOOKS[lookName])
	R.Assets[asset] = built[lookName]
	R.Rig[asset] = RIG
end
return R
