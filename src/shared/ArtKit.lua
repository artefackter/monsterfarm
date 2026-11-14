-- Builds every visual from the imported mesh library. Runs on server (world, farms) and client (UI previews).
-- The server creates one template per mesh into ReplicatedStorage.ArtLib; clones are then instant.
-- If a mesh ever fails to load, a coloured box of the same size stands in, so the game never breaks.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Manifest = table.clone(require(script.Parent.ArtManifest))
for name,parts in require(script.Parent.ArtManifestV3) do Manifest[name]=parts end
for name,parts in require(script.Parent.ArtManifestEnvironment) do Manifest[name]=parts end

for name,parts in require(script.Parent.ArtManifestMonsters) do Manifest[name]=parts end
for name,parts in require(script.Parent.ArtManifestRoadV2) do Manifest[name]=parts end
for name,parts in require(script.Parent.ArtManifestCollectionV2) do Manifest[name]=parts end
for name,parts in require(script.Parent.ArtManifestRelease) do Manifest[name]=parts end
for name,parts in require(script.Parent.ArtManifestHorror) do Manifest[name]=parts end
for name,parts in require(script.Parent.ArtManifestRoadRoots) do Manifest[name]=parts end
-- Farmers keep their hands and harvest props, but no longer carry farming tools.
-- Filter the effective 3D manifest so spawning, previews and bounds agree; source art stays intact.
for name,parts in Manifest do
 if name:match("_Farmer$") or name:match("_Farmer_") then
  local visible={}
  for _,part in parts do if part.part~="HandItem" then table.insert(visible,part) end end
  Manifest[name]=visible
 end
end
-- Models built in Studio from uploaded GLBs (ReplicatedStorage.ArtModels, 2026-11-14: the V3 graves, the reviewed
-- RingMaw and Parasite): each is an asset whose parts are cloned straight from the model, with their own colours and
-- full orientation; the model's pivot is the asset's origin (on the ground, facing -Z).
do
 local models=ReplicatedStorage:FindFirstChild("ArtModels") or (RunService:IsClient() and ReplicatedStorage:WaitForChild("ArtModels",10)) or nil
 for _,model in models and models:GetChildren() or {} do
  if model:IsA("Model") then
   local origin=model:GetPivot();local parts={}
   for _,p in model:GetChildren() do
    if p:IsA("BasePart") then
     local rel=origin:ToObjectSpace(p.CFrame);local h=p.Size/2;local r=rel.Rotation
     local x,y,z=r.RightVector*h.X,r.UpVector*h.Y,r.LookVector*h.Z
     local box=Vector3.new(math.abs(x.X)+math.abs(y.X)+math.abs(z.X),math.abs(x.Y)+math.abs(y.Y)+math.abs(z.Y),math.abs(x.Z)+math.abs(y.Z)+math.abs(z.Z))*2
     table.insert(parts,{part=p.Name,source=p,offset=rel.Position,rot=r,size=p.Size,box=box,material=p.Material.Name,transparency=p.Transparency,cast=p.CastShadow,attach=p:GetAttribute("Attach"),avg=p.Color:ToHex()})
    end
   end
   Manifest[model.Name]=parts
  end
 end
 -- the reviewed looks replace the old road meshes and the RingMaw boss (owner, 2026-11-14); the rigs stay the same
 for old,new in {RingMaw_Aggressive="RingMaw_V2",RingMaw_Passive="RingMaw_V2",Parasite_Root_Aggressive="Parasite_V2"} do
  if Manifest[new] then Manifest[old]=Manifest[new] end
 end
end
local Collection=require(script.Parent.MonsterCollection)
local Rig=require(script.Parent.MonsterRig)
local Art = {}

-- Studio's glTF importer turns the mesh data 180 degrees around Y (+Z forward to -Z forward).
-- Every clone is turned back here, so authoring and placement stay in one coordinate system.
Art.ImportRotation = CFrame.Angles(0, math.pi, 0)

local LIB_NAME = "ArtLib"
local PRELOAD_TIMEOUT = 25

local function library()
	if RunService:IsServer() then
		local lib = ReplicatedStorage:FindFirstChild(LIB_NAME)
		if not lib then
			lib = Instance.new("Folder")
			lib.Name = LIB_NAME
			lib.Parent = ReplicatedStorage
		end
		return lib
	end
	return ReplicatedStorage:WaitForChild(LIB_NAME)
end

local function createTemplate(key, id, lib)
	for attempt = 1, 3 do
		local ok, part = pcall(function()
			return AssetService:CreateMeshPartAsync(Content.fromUri("rbxassetid://" .. id), {
				CollisionFidelity = Enum.CollisionFidelity.Box,
				RenderFidelity = Enum.RenderFidelity.Automatic,
			})
		end)
		if ok and part then
			part.Name = key
			part.Anchored = true
			part.Parent = lib
			return true
		end
		if attempt == 3 then
			warn("[ArtKit] mesh failed to load:", key, part)
		end
		task.wait(attempt)
	end
	return false
end

-- Server only. Yields until the library is ready (about a second) or the timeout passes.
function Art.Preload()
	local lib = library()
	local pending, failed, started = 0, 0, os.clock()
	for assetName, parts in pairs(Manifest) do
		for _, meta in ipairs(parts) do
			local key = assetName .. "." .. meta.part
			if meta.id and not lib:FindFirstChild(key) then
				pending += 1
				task.spawn(function()
					if not createTemplate(key, meta.id, lib) then
						failed += 1
					end
					pending -= 1
				end)
			end
		end
	end
	while pending > 0 and os.clock() - started < PRELOAD_TIMEOUT do
		task.wait(0.05)
	end
	lib:SetAttribute("Ready", true)
	print(string.format("[ArtKit] %d meshes ready in %.2fs, %d failed", #lib:GetChildren(), os.clock() - started, failed))
end

function Art.WaitUntilReady()
	local lib = library()
	while not lib:GetAttribute("Ready") do
		lib:GetAttributeChangedSignal("Ready"):Wait()
	end
end

-- Spawn an asset. opts: scale (number or Vector3), tints {PartName = Color3}, skip {PartName = true},
-- prefix (added to part names), collide (keep collisions on).
function Art.Has(assetName)
	return Manifest[assetName] ~= nil
end

local boundsCache={}
function Art.Bounds(assetName)
 local cached=boundsCache[assetName];if cached then return cached[1],cached[2] end
 local lo=Vector3.new(math.huge,math.huge,math.huge);local hi=-lo
 for _,p in Manifest[assetName] or {} do
  if p.transparency<1 then
  local box=p.box or p.size;local a,b=p.offset-box*.5,p.offset+box*.5
  lo=Vector3.new(math.min(lo.X,a.X),math.min(lo.Y,a.Y),math.min(lo.Z,a.Z))
  hi=Vector3.new(math.max(hi.X,b.X),math.max(hi.Y,b.Y),math.max(hi.Z,b.Z))
  end
 end
 assert(lo.Y<hi.Y,"Missing monster bounds: "..tostring(assetName));boundsCache[assetName]={lo,hi};return lo,hi
end
function Art.MonsterScale(assetName)
 local lo,hi=Art.Bounds(assetName);return require(script.Parent.Config.MonsterSize).MinimumHeight/(hi.Y-lo.Y),lo,hi
end
-- Graves without a model of their own (owner, 2026-11-14: Emo, Military and Ghost, between Golden and Lunar): a V3
-- grave recoloured, with a few plain parts that say what it is — a pink star on a black stone, an army helmet and dog
-- tags, a pale see-through stone with a wisp over it.
local DERIVED = {
	Grave_V3_Emo = { base = "Grave_V3_Marble", color = Color3.fromHex("2E2536"), accent = Color3.fromHex("FF4FB3") },
	Grave_V3_Military = { base = "Grave_V3_Stone", color = Color3.fromHex("5F6E3B"), accent = Color3.fromHex("C9B27A") },
	Grave_V3_Ghost = { base = "Grave_V3_Lunar", color = Color3.fromHex("CFF4FF"), accent = Color3.fromHex("8FE8FF"), ghost = true },
}
function Art.Has(assetName) -- (again: derived graves count too)
	return Manifest[assetName] ~= nil or (DERIVED[assetName] ~= nil and Manifest[DERIVED[assetName].base] ~= nil)
end
local function extra(parent, out, name, size, cf, color, material, shape)
	local q = Instance.new("Part")
	q.Name = name
	q.Size = size
	q.CFrame = cf
	q.Color = color
	q.Material = material or Enum.Material.SmoothPlastic
	q.Anchored, q.CanCollide, q.CanTouch, q.CanQuery, q.Massless, q.CastShadow = true, false, false, false, true, false
	if shape then
		q.Shape = shape
	end
	q.Parent = parent
	out[name] = q
	return q
end
local function spawnDerived(look, assetName, parent, cf, opts)
	local out = Art.Spawn(look.base, parent, cf, opts)
	-- the stone's extent in its own frame, to put the extras on it whatever its scale
	local lo, hi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	for name, p in out do
		p:SetAttribute("ArtAsset", assetName)
		-- the stone takes the new colour; the face, the grass and the little ornaments keep theirs
		local stone = name:find("^Headstone") or name:find("^Stone") or name:find("rock")
		if stone then
			p.Color = look.color:Lerp(p.Color, 0.2)
		end
		if look.ghost and stone then
			p.Material = Enum.Material.Glass
			p.Transparency = math.max(p.Transparency, 0.35)
		end
		local c = cf:PointToObjectSpace(p.Position)
		local h = p.Size / 2
		lo = lo:Min(c - h)
		hi = hi:Max(c + h)
	end
	if lo.X == math.huge then
		return out
	end
	local w, top, front = hi.X - lo.X, hi.Y, lo.Z
	local mid = cf * CFrame.new((lo.X + hi.X) / 2, 0, 0)
	if assetName == "Grave_V3_Emo" then
		extra(parent, out, "EmoStar", Vector3.new(w * 0.2, w * 0.2, 0.12), mid * CFrame.new(w * 0.26, top * 0.86, front - 0.04) * CFrame.Angles(0, 0, math.rad(45)), look.accent, Enum.Material.Neon)
		extra(parent, out, "EmoBand", Vector3.new(w * 0.92, top * 0.08, 0.1), mid * CFrame.new(0, top * 0.32, front - 0.03), look.accent)
	elseif assetName == "Grave_V3_Military" then
		extra(parent, out, "Helmet", Vector3.new(w * 0.5, w * 0.5, w * 0.5), mid * CFrame.new(0, top + w * 0.02, (lo.Z + hi.Z) / 2), Color3.fromHex("4E5A2E"), Enum.Material.Metal, Enum.PartType.Ball)
		extra(parent, out, "HelmetRim", Vector3.new(w * 0.07, w * 0.6, w * 0.6), mid * CFrame.new(0, top - w * 0.08, (lo.Z + hi.Z) / 2) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromHex("3E4824"), Enum.Material.Metal, Enum.PartType.Cylinder)
		for _, e in { -1, 1 } do
			extra(parent, out, "DogTag", Vector3.new(w * 0.14, w * 0.2, 0.06), mid * CFrame.new(e * w * 0.09, top * 0.55, front - 0.05) * CFrame.Angles(0, 0, e * 0.15), look.accent, Enum.Material.Metal)
		end
	elseif assetName == "Grave_V3_Ghost" then
		extra(parent, out, "Wisp", Vector3.new(w * 0.22, w * 0.22, w * 0.22), mid * CFrame.new(0, top + w * 0.3, (lo.Z + hi.Z) / 2), look.accent, Enum.Material.Neon, Enum.PartType.Ball).Transparency = 0.2
	end
	return out
end

-- Performance (owner, 2026-11-14: "optimise the models"): the V3 graves are 36 parts and 14k triangles each, and a
-- farm holds many. Their smallest bits are left out: the two dimples (508-triangle spheres a tenth of a stud wide),
-- the ten grass blades at the foot, the little crack and the tiny cubes. The eyes keep their glints.
local GRAVE_TRIM = { "^Grass /", "dimple", "^Stone / little crack", "^Cube%.00[78]" }
local trimmed = {}
local function trim(assetName, part)
	if not assetName:find("^Grave_V3_") then
		return false
	end
	local key = assetName .. "|" .. part
	if trimmed[key] == nil then
		trimmed[key] = false
		for _, pattern in GRAVE_TRIM do
			if part:find(pattern) then
				trimmed[key] = true
				break
			end
		end
	end
	return trimmed[key]
end

function Art.Spawn(assetName, parent, cf, opts)
	opts = opts or {}
	local look = DERIVED[assetName]
	if look and not Manifest[assetName] and Manifest[look.base] then
		return spawnDerived(look, assetName, parent, cf, opts)
	end
	local parts = Manifest[assetName]
	assert(parts, "Unknown art asset: " .. tostring(assetName))
	local lib, scale, out = library(), opts.scale or 1, {}
	for _, meta in ipairs(parts) do
		if not (opts.skip and opts.skip[meta.part]) and not trim(assetName, meta.part) then
			local template = meta.source or (meta.id and lib:FindFirstChild(assetName .. "." .. meta.part))
			local p = template and template:Clone() or Instance.new("Part")
			p.Name = (opts.prefix or "") .. meta.part
            p:SetAttribute("ArtAsset",assetName)
			p.Anchored = true
			p.CanCollide = opts.collide == true
			p.CanTouch = false
			p.CanQuery = opts.collide == true
			p.Massless = true
			p.CastShadow = meta.cast
			p.Material = template and Enum.Material[meta.material] or Enum.Material.SmoothPlastic
			p.Transparency = meta.transparency
			p.Size = meta.size * scale
			p.CFrame = cf * CFrame.new(meta.offset * scale) * (meta.rot or Art.ImportRotation)
			if meta.yaw then
				p.CFrame *= CFrame.Angles(0, meta.yaw, 0)
			end
			local tint = opts.tints and opts.tints[meta.part]
			p.Color = tint or (meta.source and meta.source.Color) or (template and Color3.new(1, 1, 1)) or Color3.fromHex(meta.avg)
			if meta.attach then
				p:SetAttribute("Attach", meta.attach)
			end
			p.Parent = parent
			out[meta.part] = p
		end
	end
	return out
end

-- ---- Zombies --------------------------------------------------------------------------------------
local Palette = require(script.Parent.Palette)
local ZombieConfig = require(script.Parent.Config.ZombieConfig)

Art.PivotHeight = 2.25 -- model pivot above the feet; keeps the old "pivot = body" placement in the services

local OUTFIT = {
	Pajama = "8ED8FF", Gardener = "FFE08A", Postman = "6FA8FF", Skater = "7BE8C5", Pirate = "FBF4E4", Cowboy = "E7A862",
	Knight = "9AA8C4", DJ = "29C5F6", King = "8C4BFF", Astronaut = "FFFFFF", Dragon = "B65CFF",
}
local SKINS = { "9BE36B", "8EDC82", "B7E46A" }
local SHOW_BRAIN = { DJ = true, Skater = true } -- hatless enough for the brain to be on display

local function hash(id)
	local h = 0
	for i = 1, #id do
		h = (h * 31 + string.byte(id, i)) % 9973
	end
	return h
end

function Art.SkinColor(z)
	if z.mutation == "Golden" then
		return Color3.fromHex("FFD23F")
	elseif z.mutation == "Lunar" then
		return Color3.fromHex("9FF5D2")
	end
	return Color3.fromHex(SKINS[hash(z.id or z.type) % #SKINS + 1])
end

-- The rotation's outfits (owner, 2026-11-13): the Miner, the Knight and the King wear the Farmer's, the Punk's and the
-- Assassin's bodies with pieces built on top. Each piece rides the limb it belongs to (Attach), so it walks, waves
-- and hops with the monster. Sizes follow the head, so every family's outfit fits its own build.
local HAT_SINK = { Deer = 0.4, Parasite = 0.14, Stalker = 0.12, Verity = 0.14, RingMaw = 0.15, CaveDweller = 0.16 } -- antlers make the deer's head box tall
local function piece(model, name, attach, size, cf, color, material, shape)
	local p = Instance.new("Part")
	p.Name = "Outfit_" .. name
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.Massless, p.CastShadow = true, false, false, false, true, false
	p.Size, p.CFrame, p.Color = size, cf, Color3.fromHex(color)
	p.Material = material or Enum.Material.SmoothPlastic
	if shape then
		p.Shape = shape
	end
	if attach then
		p:SetAttribute("Attach", attach)
	end
	p.Parent = model
	return p
end
function Art.Dress(model, outfit, parts, feet, family)
	-- headwear and body pieces only: nothing in the hands (owner, 2026-11-13: "remove the pickaxes, staffs and so on")
	local head, body = parts.Head, parts.Body
	if not (head and body) then
		return
	end
	local rot, up, look = feet.Rotation, feet.UpVector, feet.LookVector
	local w = math.min(head.Size.X, head.Size.Z)
	local top = head.Position + up * head.Size.Y * (0.5 - (HAT_SINK[family] or 0.15))
	local ball, cyl, metal = Enum.PartType.Ball, Enum.PartType.Cylinder, Enum.Material.Metal
	local flat = CFrame.Angles(0, 0, math.pi / 2) -- a cylinder standing up
	if outfit == "Miner" then
		piece(model, "HatDome", "Head", Vector3.new(w * 0.95, w * 0.55, w * 0.95), CFrame.new(top + up * w * 0.12) * rot, "E8B52A", nil, ball)
		piece(model, "HatBrim", "Head", Vector3.new(w * 0.1, w * 1.12, w * 1.12), CFrame.new(top - up * w * 0.08) * rot * flat, "C99A1E", nil, cyl)
		local lamp = CFrame.new(top + up * w * 0.14) * rot * CFrame.new(0, 0, -w * 0.46)
		piece(model, "HatLampRim", "Head", Vector3.new(w * 0.14, w * 0.3, w * 0.3), lamp * CFrame.Angles(0, math.pi / 2, 0), "5A5148", metal, cyl)
		piece(model, "HatLamp", "Head", Vector3.new(w * 0.06, w * 0.22, w * 0.22), lamp * CFrame.new(0, 0, -w * 0.06) * CFrame.Angles(0, math.pi / 2, 0), "FFF2B0", Enum.Material.Neon, cyl)
	elseif outfit == "Knight" then
		piece(model, "Helmet", "Head", Vector3.new(w * 1.02, w * 0.78, w * 1.02), CFrame.new(top + up * w * 0.05) * rot, "A9B0B8", metal, ball)
		piece(model, "HelmetBand", "Head", Vector3.new(w * 0.16, w * 1.06, w * 1.06), CFrame.new(top - up * w * 0.12) * rot * flat, "7E868F", metal, cyl)
		piece(model, "Visor", "Head", Vector3.new(w * 0.62, w * 0.12, w * 0.08), CFrame.new(top - up * w * 0.05) * rot * CFrame.new(0, 0, -w * 0.5), "1E1E24", metal)
		piece(model, "Plume", "Head", Vector3.new(w * 0.14, w * 0.5, w * 0.7), CFrame.new(top + up * w * 0.5) * rot * CFrame.new(0, 0, w * 0.1), "B3202C", Enum.Material.Fabric)
	elseif outfit == "King" then
		local crown = CFrame.new(top + up * w * 0.12) * rot
		piece(model, "CrownBand", "Head", Vector3.new(w * 0.3, w * 0.86, w * 0.86), crown * flat, "E4B83A", metal, cyl)
		for n = 0, 5 do
			local a = n / 6 * math.pi * 2
			local tip = crown * CFrame.Angles(0, a, 0) * CFrame.new(0, w * 0.24, -w * 0.38)
			piece(model, "CrownPoint", "Head", Vector3.new(w * 0.16, w * 0.26, w * 0.08), tip * CFrame.Angles(0, 0, math.pi / 4), "E4B83A", metal)
			piece(model, "CrownGem", "Head", Vector3.new(w * 0.11, w * 0.11, w * 0.11), crown * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -w * 0.44), n % 2 == 0 and "D6264A" or "3FA0E0", Enum.Material.Neon, ball)
		end
		local back = body.Position - look * body.Size.Z * 0.48
		piece(model, "Cape", nil, Vector3.new(body.Size.X * 1.05, body.Size.Y * 1.05, w * 0.07), CFrame.new(back - up * body.Size.Y * 0.08) * rot * CFrame.Angles(-0.08, 0, 0), "7A1630", Enum.Material.Fabric)
		piece(model, "CapeCollar", nil, Vector3.new(body.Size.X * 1.1, w * 0.22, w * 0.32), CFrame.new(back + up * body.Size.Y * 0.44) * rot, "F2EEE6", Enum.Material.Fabric)
		piece(model, "Medallion", nil, Vector3.new(w * 0.06, w * 0.3, w * 0.3), CFrame.new(body.Position + look * body.Size.Z * 0.5 + up * body.Size.Y * 0.2) * rot * CFrame.Angles(0, math.pi / 2, 0), "E4B83A", metal, cyl)
	end
end

-- Assemble a zombie whose feet stand at `feet`. Returns the Body part (use it as PrimaryPart).
function Art.BuildZombie(model, feet, z)
 local asset=Collection.Asset(z.type,z.form)
 if asset then
  local scale,lo,hi=Art.MonsterScale(asset)
  local outfit=Collection.Outfits[z.type]
  local parts=Art.Spawn(asset,model,feet*CFrame.new(0,-lo.Y*scale,0),{scale=scale,skip=outfit and {Headwear=true,HandItem=true,HatBrim=true,HatCrown=true,HatBand=true,Hood=true} or nil})
  if outfit then Art.Dress(model,outfit,parts,feet,Collection.Family(z.type)) end
  model:SetAttribute("MonsterHeight",(hi.Y-lo.Y)*scale)
  model:SetAttribute("MonsterLabelHeight",(hi.Y-lo.Y)*scale-(parts.Body.Position.Y-feet.Position.Y))
  model:SetAttribute("MonsterRadius",math.max(hi.X-lo.X,hi.Z-lo.Z)*scale*.5)
  model:SetAttribute("MonsterAsset",asset)
  model:SetAttribute("Floating",Collection.Floating[z.type]==true)
  for name,point in Rig[asset] do model:SetAttribute("Joint_"..name,point*scale-Vector3.new(0,Art.PivotHeight+lo.Y*scale,0)) end
  model.PrimaryPart=parts.Body
  parts.Body.PivotOffset=parts.Body.CFrame:ToObjectSpace(feet*CFrame.new(0,Art.PivotHeight,0))
  return parts.Body
 end
	local skin = Art.SkinColor(z)
	local tierName = ZombieConfig.Tiers[z.tier]
	local parts = Art.Spawn("Z_Base", model, feet, {
		skip = { Hair = true, Brain = not SHOW_BRAIN[z.type] or nil },
		tints = {
			Head = skin, ArmL = skin, ArmR = skin,
			Body = Color3.fromHex(OUTFIT[z.type] or "FFFFFF"),
			Ring = Palette[tierName],
		},
	})
	if z.tier >= 5 then
		-- Legendary and Mythic rings glow only at night, like every other light (PlotService.SetNight)
		game:GetService("CollectionService"):AddTag(parts.Ring, "NightGlow")
		parts.Ring.Material = workspace:GetAttribute("IsNight") == true and Enum.Material.Neon or Enum.Material.SmoothPlastic
	end
	Art.Spawn("Z_" .. z.type, model, feet, { prefix = "Acc_" })
	model.PrimaryPart = parts.Body
	parts.Body.PivotOffset = parts.Body.CFrame:ToObjectSpace(feet * CFrame.new(0, Art.PivotHeight, 0))
	return parts.Body
end

return Art
