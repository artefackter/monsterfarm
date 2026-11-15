-- Moves imported GLB models from ServerStorage.ArtImportV5 into ReplicatedStorage.ArtModels the way ArtKit wants them:
-- parts flat under the model, pivot on the ground at the glTF origin facing -Z (the importer turns the meshes 180
-- degrees, so glTF (x, y, z) is asset (-x, y, -z)), colours from the vertex colours (part colour white), limb groups as
-- Attach attributes, the pivots of the groups as Joint_<group> attributes (ArtKit reads them into MonsterRig).
-- META (filled in by the caller): name -> {c = glTF bounds centre {x,y,z}, j = {group = {x,y,z}}, neon = {part = hex}}
local META = __META__
local F = game.ServerStorage:FindFirstChild("ArtImportV5")
local dest = game.ReplicatedStorage:FindFirstChild("ArtModels")
local report = {}
for name, meta in META do
	local src = F and F:FindFirstChild(name)
	if not src then
		table.insert(report, name .. ": not imported")
		continue
	end
	local parts = {}
	for _, p in src:GetDescendants() do
		if p:IsA("MeshPart") then
			table.insert(parts, p)
		end
	end
	local R = parts[1].CFrame.Rotation
	local lo, hi = Vector3.one * 1e9, -Vector3.one * 1e9
	for _, p in parts do
		local c = R:PointToObjectSpace(p.Position)
		lo, hi = lo:Min(c - p.Size / 2), hi:Max(c + p.Size / 2)
	end
	local c = meta.c
	local originR = (lo + hi) / 2 - Vector3.new(-c[1], c[2], -c[3])
	local m = Instance.new("Model")
	m.Name = name
	for _, p in parts do
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, true
		p.Material = Enum.Material.SmoothPlastic
		p.Color = Color3.new(1, 1, 1)
		pcall(function()
			p.CollisionFidelity = Enum.CollisionFidelity.Box
		end)
		local neon = meta.neon and meta.neon[p.Name]
		if neon then
			p.Material = Enum.Material.Neon
			p.Color = Color3.fromHex(neon)
		end
		if meta.j then
			p:SetAttribute("Attach", p.Name == "HeadFace" and "Head" or p.Name)
		end
		p.Parent = m
	end
	m.WorldPivot = CFrame.new(R:PointToWorldSpace(originR)) * R
	for group, v in meta.j or {} do
		m:SetAttribute("Joint_" .. group, Vector3.new(-v[1], v[2], -v[3]))
	end
	local old = dest:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	m.Parent = dest
	src:Destroy()
	local size = hi - lo
	table.insert(report, string.format("%s: %d parts, %.1f x %.1f x %.1f", name, #parts, size.X, size.Y, size.Z))
end
game:GetService("ChangeHistoryService"):SetWaypoint("Grow a Monster: imported models into ArtModels")
return table.concat(report, "\n")
