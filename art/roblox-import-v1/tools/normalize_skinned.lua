-- Moves imported skinned GLB models from ServerStorage.ArtImportSkinned into ReplicatedStorage.ArtSkinned the way
-- MutantModel wants them (2026-11-15): one Model per monster, its MeshParts flat under it with their Bone trees inside
-- (out of the import's package; a model of several meshes keeps its bones in a separate invisible RootPart, which
-- comes along), anchored, colours from the vertex colours (part colour white), the pivot on the ground
-- under the Root bone facing the monster's front (the importer leaves the mesh's LookVector on glTF +Z, its front),
-- and its height in the Height attribute. NAMES (filled in by the caller): the models to move.
-- HEADS (optional, name -> Vector3; rig_bosses.json's "head"): how far the middle of the head is from the Head bone,
-- in the model's own axes; kept as the HeadCentre attribute in the bone's frame (ShovelMotion.BossHead). It may be
-- given for a model that is already in ArtSkinned.
local NAMES = __NAMES__
local HEADS = __HEADS__
local F = game.ServerStorage:FindFirstChild("ArtImportSkinned")
local dest = game.ReplicatedStorage:FindFirstChild("ArtSkinned")
if not dest then
	dest = Instance.new("Folder")
	dest.Name = "ArtSkinned"
	dest.Parent = game.ReplicatedStorage
end
local report = {}
for _, name in NAMES do
	local src = F and F:FindFirstChild(name)
	if not src then
		table.insert(report, name .. ": not imported")
		continue
	end
	local parts, main = {}, nil
	for _, p in src:GetDescendants() do
		if p:IsA("BasePart") then
			table.insert(parts, p)
			if p:FindFirstChildWhichIsA("Bone") then
				main = main or p
			end
		end
	end
	if not main then
		table.insert(report, name .. ": no bones")
		continue
	end
	local mesh = src:FindFirstChildWhichIsA("MeshPart", true)
	local R = mesh.CFrame.Rotation
	local lo, hi = Vector3.one * 1e9, -Vector3.one * 1e9
	for _, p in parts do
		if p:IsA("MeshPart") then
			local c = R:PointToObjectSpace(p.Position)
			lo, hi = lo:Min(c - p.Size / 2), hi:Max(c + p.Size / 2)
		end
	end
	local rootBone = main:FindFirstChildWhichIsA("Bone")
	local feet = R:PointToObjectSpace(rootBone.WorldPosition)
	local m = Instance.new("Model")
	m.Name = name
	local bones = 0
	for _, p in parts do
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, true
		-- a mesh named "..._Glow" (tools/rig_bosses.py: a face or eyes that glow) is Neon
		p.Material = p.Name:find("Glow") and Enum.Material.Neon or Enum.Material.SmoothPlastic
		p.Color = Color3.new(1, 1, 1)
		if not p:IsA("MeshPart") then
			p.Transparency, p.CastShadow = 1, false -- the bones' holder
		end
		pcall(function()
			p.CollisionFidelity = Enum.CollisionFidelity.Box
		end)
		for _, b in p:GetDescendants() do
			if b:IsA("Bone") then
				bones += 1
			end
		end
		p.Parent = m
	end
	-- no PrimaryPart: with one the model's pivot is that part's own (the mesh's middle, not its feet)
	m.WorldPivot = CFrame.new(R:PointToWorldSpace(Vector3.new(feet.X, lo.Y, feet.Z))) * R
	m:SetAttribute("Height", hi.Y - lo.Y)
	local old = dest:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	m.Parent = dest
	src:Destroy()
	local size = hi - lo
	table.insert(report, string.format("%s: %d mesh parts (%s), %d bones, %.1f x %.1f x %.1f", name, #parts, main.Name, bones, size.X, size.Y, size.Z))
end
for name, offset in HEADS or {} do
	local m = dest:FindFirstChild(name)
	local bone = m and m:FindFirstChild("Head", true)
	if bone and bone:IsA("Bone") then
		m:SetAttribute("HeadCentre", bone.WorldCFrame:VectorToObjectSpace(m:GetPivot():VectorToWorldSpace(offset)))
		table.insert(report, string.format("%s: head centre %s", name, tostring(m:GetAttribute("HeadCentre"))))
	else
		table.insert(report, name .. ": no Head bone")
	end
end
game:GetService("ChangeHistoryService"):SetWaypoint("Grow a Monster: imported skinned models into ArtSkinned")
return table.concat(report, "\n")
