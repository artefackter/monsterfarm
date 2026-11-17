-- The chainsaw of the chainsaw finisher (owner, 2026-11-15: "one of the finishers must be with a chainsaw - I hope
-- you can generate it"). Built here out of plain parts, nothing imported: a rear handle, the engine with its starter
-- and muffler, the front handle and hand guard, the guide bar and a chain of teeth that really runs round it.
-- The model's pivot is the middle of the rear handle; the bar runs along its LookVector (-Z), up is +Y.
--   M.Build(parent)        the model, its parts welded to the Handle (its PrimaryPart), massless, no collisions
--   M.Run(model, distance) moves the chain's teeth `distance` studs round the bar
-- In it: Handle.Cut (an attachment where the chain bites, with the Sparks and Chips emitters) and Muffler.Exhaust
-- (with Smoke); ActionVisuals turns them on and off and gives it its engine sound.
-- Since 2026-11-16 the chainsaw is also a melee weapon of its own, and so is the chainsword (owner: "a saw-sword,
-- like in Warhammer"; M.BuildSword): a long two-hand hilt, a guard, a boxy engine housing and a wide bar whose chain
-- runs bare along its cutting edge and round its nose (the return run is under the spine's casing). Same frame as
-- the saw - the hilt at the pivot, the blade along -Z, the cutting edge up (+Y) - same Run, same Cut and Exhaust.
local M = {}

-- A chain's loop: the bar's middle line (X, Y), where it leaves the engine (From) and the middle of its round nose
-- (To), the teeth's distance from that line (Rim).
local SAW = { X = 0.2, Y = -0.06, From = -1.25, To = -3.85, Rim = 0.25, Teeth = 18 }
local SWORD = { X = 0, Y = 0.04, From = -1.3, To = -3.75, Rim = 0.36, Teeth = 20 }
for _, s in { SAW, SWORD } do
	s.Straight = s.From - s.To
	s.Loop = 2 * s.Straight + 2 * math.pi * s.Rim
end
local SPECS = { Saw = SAW, Sword = SWORD }

local function part(model, name, size, cf, color, material, shape)
	local q = Instance.new("Part")
	q.Name = name
	q.Size = size
	q.CFrame = cf
	q.Color = Color3.fromHex(color)
	q.Material = material or Enum.Material.SmoothPlastic
	if shape then
		q.Shape = shape
	end
	q.TopSurface, q.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	q.Anchored, q.CanCollide, q.CanQuery, q.CanTouch, q.Massless = false, false, false, false, true
	q.Parent = model
	return q
end

-- A tooth `along` studs round the loop `s`: out along the top of the bar, round its nose, back underneath.
local function toothAt(s, along)
	along %= s.Loop
	local straight, rim = s.Straight, s.Rim
	if along < straight then
		return CFrame.new(s.X, s.Y + rim, s.From - along)
	elseif along < straight + math.pi * rim then
		local a = (along - straight) / rim
		return CFrame.new(s.X, s.Y + rim * math.cos(a), s.To - rim * math.sin(a)) * CFrame.Angles(-a, 0, 0)
	elseif along < 2 * straight + math.pi * rim then
		return CFrame.new(s.X, s.Y - rim, s.To + (along - straight - math.pi * rim)) * CFrame.Angles(math.pi, 0, 0)
	end
	local a = (along - 2 * straight - math.pi * rim) / rim
	return CFrame.new(s.X, s.Y - rim * math.cos(a), s.From + rim * math.sin(a)) * CFrame.Angles(math.pi - a, 0, 0)
end

-- The teeth, each on a weld of its own so the chain can run (M.Run), and what the chain does where it bites: the
-- Cut attachment (at `cutAt`) with its sparks and chips, and the muffler's smoke.
local function chain(m, handle, s, toothSize, toothColor, cutAt, muffler, exhaustAt)
	for i = 1, s.Teeth do
		local tooth = part(m, "Tooth", toothSize, toothAt(s, (i - 1) / s.Teeth * s.Loop), toothColor, Enum.Material.Metal)
		local w = Instance.new("Weld")
		w.Name = "Run"
		w.Part0, w.Part1 = handle, tooth
		w.C0 = toothAt(s, (i - 1) / s.Teeth * s.Loop)
		w.Parent = tooth
		tooth:SetAttribute("Along", (i - 1) / s.Teeth * s.Loop)
	end
	local cut = Instance.new("Attachment")
	cut.Name = "Cut"
	cut.CFrame = cutAt
	cut.Parent = handle
	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "Sparks"
	sparks.Enabled = false
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Color = ColorSequence.new(Color3.fromHex("FFF1B0"), Color3.fromHex("FF8A2B"))
	sparks.LightEmission, sparks.LightInfluence = 1, 0
	sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.32), NumberSequenceKeypoint.new(1, 0) })
	sparks.Lifetime = NumberRange.new(0.18, 0.42)
	sparks.Rate = 110
	sparks.Speed = NumberRange.new(14, 30)
	sparks.SpreadAngle = Vector2.new(32, 32)
	sparks.Acceleration = Vector3.new(0, -55, 0)
	sparks.Drag = 2
	sparks.EmissionDirection = Enum.NormalId.Top
	sparks.Parent = cut
	local chips = Instance.new("ParticleEmitter")
	chips.Name = "Chips"
	chips.Enabled = false
	chips.Color = ColorSequence.new(Color3.fromHex("8A55C2"), Color3.fromHex("4A2C74"))
	chips.LightEmission, chips.LightInfluence = 0.1, 0.4
	chips.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.34), NumberSequenceKeypoint.new(1, 0.08) })
	chips.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	chips.Lifetime = NumberRange.new(0.35, 0.7)
	chips.Rate = 55
	chips.Speed = NumberRange.new(8, 18)
	chips.SpreadAngle = Vector2.new(40, 40)
	chips.Acceleration = Vector3.new(0, -70, 0)
	chips.Rotation = NumberRange.new(0, 360)
	chips.RotSpeed = NumberRange.new(-260, 260)
	chips.EmissionDirection = Enum.NormalId.Top
	chips.Parent = cut
	local exhaust = Instance.new("Attachment")
	exhaust.Name = "Exhaust"
	exhaust.CFrame = exhaustAt
	exhaust.Parent = muffler
	local smoke = Instance.new("ParticleEmitter")
	smoke.Name = "Smoke"
	smoke.Enabled = false
	smoke.Color = ColorSequence.new(Color3.fromHex("8C8C92"), Color3.fromHex("4F4F55"))
	smoke.LightEmission, smoke.LightInfluence = 0, 0.6
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 1.3) })
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1) })
	smoke.Lifetime = NumberRange.new(0.5, 0.95)
	smoke.Rate = 22
	smoke.Speed = NumberRange.new(2, 5)
	smoke.SpreadAngle = Vector2.new(22, 22)
	smoke.Acceleration = Vector3.new(0, 5, 0)
	smoke.Rotation = NumberRange.new(0, 360)
	smoke.EmissionDirection = Enum.NormalId.Top
	smoke.Parent = exhaust
end

local function weldAll(m, handle)
	for _, p in m:GetChildren() do
		if p ~= handle then
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = handle, p
			w.Parent = p
		end
	end
end

function M.Build(parent)
	local m = Instance.new("Model")
	m.Name = "ChainsawVisual"
	local s = SAW
	local dark, body, steel = "26262B", "D2552A", "B9BDC4"
	local handle = part(m, "Handle", Vector3.new(0.24, 0.26, 0.62), CFrame.new(0, 0, 0), dark)
	m.PrimaryPart = handle
	-- the rear handle's loop, and the trigger under the grip
	part(m, "HandleBack", Vector3.new(0.22, 0.5, 0.12), CFrame.new(0, -0.14, 0.34), dark)
	part(m, "HandleBase", Vector3.new(0.22, 0.12, 0.8), CFrame.new(0, -0.36, 0), dark)
	part(m, "Trigger", Vector3.new(0.1, 0.1, 0.2), CFrame.new(0, -0.16, -0.12), "E9B43A")
	-- the engine
	part(m, "Engine", Vector3.new(0.66, 0.62, 0.92), CFrame.new(0, 0.02, -0.8), body)
	part(m, "EngineTop", Vector3.new(0.54, 0.16, 0.62), CFrame.new(0, 0.4, -0.74), "B2401C")
	part(m, "EngineNose", Vector3.new(0.5, 0.44, 0.22), CFrame.new(-0.06, -0.05, -1.34), "B2401C")
	part(m, "Stripe", Vector3.new(0.68, 0.1, 0.94), CFrame.new(0, -0.16, -0.8), "F2E9D5")
	-- the starter on the left, with its cord's grip
	part(m, "Starter", Vector3.new(0.1, 0.5, 0.5), CFrame.new(-0.36, 0.02, -0.8), "3A3A41", nil, Enum.PartType.Cylinder)
	part(m, "StarterHub", Vector3.new(0.14, 0.2, 0.2), CFrame.new(-0.38, 0.02, -0.8), "1C1C20", nil, Enum.PartType.Cylinder)
	part(m, "Cord", Vector3.new(0.16, 0.1, 0.24), CFrame.new(-0.46, 0.24, -0.72), "1C1C20")
	-- the muffler on the right
	local muffler = part(m, "Muffler", Vector3.new(0.14, 0.3, 0.36), CFrame.new(0.4, 0.14, -0.62), "777A82", Enum.Material.Metal)
	-- the front handle: a bar across the top, down both sides
	part(m, "FrontHandle", Vector3.new(0.92, 0.13, 0.13), CFrame.new(0, 0.74, -0.8), dark, nil, Enum.PartType.Cylinder)
	part(m, "FrontHandleL", Vector3.new(0.13, 0.78, 0.13), CFrame.new(-0.4, 0.38, -0.8), dark)
	part(m, "FrontHandleR", Vector3.new(0.13, 0.5, 0.13), CFrame.new(0.4, 0.52, -0.8), dark)
	-- the hand guard ahead of it, tipped forward
	part(m, "Guard", Vector3.new(0.56, 0.5, 0.07), CFrame.new(0, 0.52, -1.18) * CFrame.Angles(-0.35, 0, 0), dark)
	-- the bar and its nose, the cover that clamps it to the engine, and the chain's band round it
	local mid = (s.From + 0.5 + s.To) / 2
	part(m, "Bar", Vector3.new(0.07, 0.34, s.Straight + 0.5), CFrame.new(s.X, s.Y, mid), steel, Enum.Material.Metal)
	part(m, "BarNose", Vector3.new(0.07, 0.34, 0.34), CFrame.new(s.X, s.Y, s.To), steel, Enum.Material.Metal, Enum.PartType.Cylinder)
	part(m, "Chain", Vector3.new(0.04, 0.44, s.Straight + 0.5), CFrame.new(s.X, s.Y, mid), "2B2B30", Enum.Material.Metal)
	part(m, "ChainNose", Vector3.new(0.04, 0.44, 0.44), CFrame.new(s.X, s.Y, s.To), "2B2B30", Enum.Material.Metal, Enum.PartType.Cylinder)
	part(m, "BarCover", Vector3.new(0.12, 0.46, 0.7), CFrame.new(0.3, -0.06, -1.0), "3A3A41")
	part(m, "BarNut", Vector3.new(0.08, 0.12, 0.12), CFrame.new(0.37, -0.06, -0.9), steel, Enum.Material.Metal, Enum.PartType.Cylinder)
	part(m, "BarNut", Vector3.new(0.08, 0.12, 0.12), CFrame.new(0.37, -0.06, -1.14), steel, Enum.Material.Metal, Enum.PartType.Cylinder)
	weldAll(m, handle)
	-- where the chain bites: the underside of the bar near its nose; the sparks fly back and down from it
	chain(m, handle, s, Vector3.new(0.09, 0.09, 0.15), "D9DCE2", CFrame.new(s.X, s.Y - s.Rim, s.To + 0.7) * CFrame.Angles(math.rad(-125), 0, 0), muffler, CFrame.new(0.08, 0, -0.1) * CFrame.Angles(0, 0, math.rad(-60)))
	m:SetAttribute("Bar", "Saw")
	handle.PivotOffset = CFrame.identity
	m.Parent = parent
	return m
end

-- The chainsword: the hilt's middle at the pivot (the right hand; the left takes the hilt a stud behind it), the
-- blade along -Z, its cutting edge - the bare chain - up.
function M.BuildSword(parent)
	local m = Instance.new("Model")
	m.Name = "ChainswordVisual"
	local s = SWORD
	local dark, red, deep, brass, steel = "23242B", "A8222C", "7A1820", "CDA349", "B9BDC4"
	local handle = part(m, "Handle", Vector3.new(0.2, 0.25, 0.9), CFrame.new(0, 0, 0), dark)
	m.PrimaryPart = handle
	part(m, "HiltRear", Vector3.new(0.19, 0.24, 0.92), CFrame.new(0, 0, 0.9), dark)
	part(m, "HiltBand", Vector3.new(0.23, 0.28, 0.07), CFrame.new(0, 0, 0.45), brass, Enum.Material.Metal)
	part(m, "HiltBand", Vector3.new(0.23, 0.28, 0.07), CFrame.new(0, 0, -0.42), brass, Enum.Material.Metal)
	part(m, "Pommel", Vector3.new(0.3, 0.36, 0.22), CFrame.new(0, 0, 1.45), brass, Enum.Material.Metal)
	-- the guard: a bar across the blade's plane, with a knuckle bow down to the pommel
	part(m, "Guard", Vector3.new(0.26, 1.25, 0.17), CFrame.new(0, 0, -0.56), brass, Enum.Material.Metal)
	part(m, "GuardTip", Vector3.new(0.22, 0.2, 0.3), CFrame.new(0, 0.6, -0.68), brass, Enum.Material.Metal)
	part(m, "Bow", Vector3.new(0.1, 0.09, 1.95), CFrame.new(0, -0.58, 0.42), dark)
	part(m, "BowEnd", Vector3.new(0.1, 0.5, 0.09), CFrame.new(0, -0.36, 1.38), dark)
	-- the engine housing at the blade's root, its hub and vents, two exhaust stubs behind the spine
	part(m, "Housing", Vector3.new(0.5, 0.92, 0.72), CFrame.new(0, 0.02, -1.02), red)
	part(m, "HousingTrim", Vector3.new(0.54, 0.12, 0.74), CFrame.new(0, -0.3, -1.02), deep)
	part(m, "Hub", Vector3.new(0.58, 0.46, 0.46), CFrame.new(0, 0.06, -1.02), brass, Enum.Material.Metal, Enum.PartType.Cylinder)
	part(m, "HubCap", Vector3.new(0.62, 0.2, 0.2), CFrame.new(0, 0.06, -1.02), dark, nil, Enum.PartType.Cylinder)
	part(m, "Vent", Vector3.new(0.52, 0.05, 0.4), CFrame.new(0, 0.3, -1.02), dark)
	part(m, "Vent", Vector3.new(0.52, 0.05, 0.4), CFrame.new(0, 0.4, -1.02), dark)
	local muffler = part(m, "Muffler", Vector3.new(0.3, 0.13, 0.13), CFrame.new(0.14, -0.56, -0.86) * CFrame.Angles(0, 0, math.rad(90)), "777A82", Enum.Material.Metal, Enum.PartType.Cylinder)
	part(m, "Muffler2", Vector3.new(0.3, 0.13, 0.13), CFrame.new(-0.14, -0.56, -1.14) * CFrame.Angles(0, 0, math.rad(90)), "777A82", Enum.Material.Metal, Enum.PartType.Cylinder)
	-- the bar, its nose, the chain's band, and the casing over the spine (the chain's return run goes under it)
	local mid = (s.From + 0.25 + s.To) / 2
	part(m, "Bar", Vector3.new(0.09, 0.5, s.Straight + 0.25), CFrame.new(s.X, s.Y, mid), steel, Enum.Material.Metal)
	part(m, "BarNose", Vector3.new(0.09, 0.5, 0.5), CFrame.new(s.X, s.Y, s.To), steel, Enum.Material.Metal, Enum.PartType.Cylinder)
	part(m, "Chain", Vector3.new(0.05, 0.64, s.Straight + 0.25), CFrame.new(s.X, s.Y, mid), "2B2B30", Enum.Material.Metal)
	part(m, "ChainNose", Vector3.new(0.05, 0.64, 0.64), CFrame.new(s.X, s.Y, s.To), "2B2B30", Enum.Material.Metal, Enum.PartType.Cylinder)
	part(m, "Spine", Vector3.new(0.2, 0.3, s.Straight - 0.1), CFrame.new(s.X, s.Y - s.Rim - 0.02, mid + 0.1), red)
	part(m, "SpineTrim", Vector3.new(0.22, 0.08, s.Straight - 0.3), CFrame.new(s.X, s.Y - s.Rim - 0.18, mid + 0.15), brass, Enum.Material.Metal)
	part(m, "Fuller", Vector3.new(0.11, 0.12, s.Straight - 0.5), CFrame.new(s.X, s.Y + 0.02, mid), deep)
	weldAll(m, handle)
	-- it bites with the top run near the nose; the sparks fly up and back from there
	chain(m, handle, s, Vector3.new(0.11, 0.15, 0.2), "E3E6EC", CFrame.new(s.X, s.Y + s.Rim, s.To + 0.8) * CFrame.Angles(math.rad(-55), 0, 0), muffler, CFrame.new(0.16, 0, 0))
	m:SetAttribute("Bar", "Sword")
	handle.PivotOffset = CFrame.identity
	m.Parent = parent
	return m
end

function M.Run(model, distance)
	local s = SPECS[model:GetAttribute("Bar") or "Saw"] or SAW
	for _, tooth in model:GetChildren() do
		local weld = tooth.Name == "Tooth" and tooth:FindFirstChild("Run")
		if weld then
			weld.C0 = toothAt(s, (tooth:GetAttribute("Along") or 0) + distance)
		end
	end
end

return M
