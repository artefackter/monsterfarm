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
			if not lib:FindFirstChild(key) then
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
  local a,b=p.offset-p.size*.5,p.offset+p.size*.5
  lo=Vector3.new(math.min(lo.X,a.X),math.min(lo.Y,a.Y),math.min(lo.Z,a.Z))
  hi=Vector3.new(math.max(hi.X,b.X),math.max(hi.Y,b.Y),math.max(hi.Z,b.Z))
  end
 end
 assert(lo.Y<hi.Y,"Missing monster bounds: "..tostring(assetName));boundsCache[assetName]={lo,hi};return lo,hi
end
function Art.MonsterScale(assetName)
 local lo,hi=Art.Bounds(assetName);return require(script.Parent.Config.MonsterSize).MinimumHeight/(hi.Y-lo.Y),lo,hi
end
function Art.Spawn(assetName, parent, cf, opts)
	opts = opts or {}
	local parts = Manifest[assetName]
	assert(parts, "Unknown art asset: " .. tostring(assetName))
	local lib, scale, out = library(), opts.scale or 1, {}
	for _, meta in ipairs(parts) do
		if not (opts.skip and opts.skip[meta.part]) then
			local template = lib:FindFirstChild(assetName .. "." .. meta.part)
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
			p.CFrame = cf * CFrame.new(meta.offset * scale) * Art.ImportRotation
			if meta.yaw then
				p.CFrame *= CFrame.Angles(0, meta.yaw, 0)
			end
			local tint = opts.tints and opts.tints[meta.part]
			p.Color = tint or (template and Color3.new(1, 1, 1)) or Color3.fromHex(meta.avg)
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

-- Assemble a zombie whose feet stand at `feet`. Returns the Body part (use it as PrimaryPart).
function Art.BuildZombie(model, feet, z)
 local asset=Collection.Asset(z.type,z.form)
 if asset then
  local scale,lo,hi=Art.MonsterScale(asset)
  local parts=Art.Spawn(asset,model,feet*CFrame.new(0,-lo.Y*scale,0),{scale=scale})
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
