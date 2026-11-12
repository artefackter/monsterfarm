-- Free placement on your own farm. With a grave selected (slot 3) or a zombie in your hands, a ghost follows
-- the pointer over the yard: green means the spot is fine, red that it isn't. A click or a tap puts it there;
-- the server checks the same PlacementRules again. Graves stolen back by guards still fly home in an arc.
local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local Run = game:GetService("RunService")
local p = Players.LocalPlayer
local Shared = game.ReplicatedStorage:WaitForChild("Shared")
local Place = require(Shared:WaitForChild("PlacementRules"))
local PC = require(Shared.Config:WaitForChild("PlacementConfig"))
local L = require(Shared:WaitForChild("Locale"))
local gui = p.PlayerGui:WaitForChild("DigUI")
local intent = game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Intent")

local GOOD, BAD = Color3.fromRGB(120, 255, 120), Color3.fromRGB(255, 90, 90)

-- Ghost: a ring on the ground and a translucent stand-in for what is being placed.
local ghost = Instance.new("Model")
ghost.Name = "PlacementGhost"
local function ghostPart(name, size, shape)
	local q = Instance.new("Part")
	q.Name = name
	q.Size = size
	q.Shape = shape or Enum.PartType.Block
	q.Anchored, q.CanCollide, q.CanQuery, q.CanTouch, q.CastShadow = true, false, false, false, false
	q.Material = Enum.Material.Neon
	q.Transparency = 0.45
	q.Parent = ghost
	return q
end
local ring = ghostPart("Ring", Vector3.new(0.12, 4.4, 4.4), Enum.PartType.Cylinder)
local stone = ghostPart("Stone", Vector3.new(1.8, 2.3, 0.55))
local body = ghostPart("Body", Vector3.new(1.7, 3.4, 1.3))

local Notifications = require(Shared:WaitForChild("Notifications"))
local function dropHeldZombie() intent:FireServer("dropZombie") end
local function placementGuide(text, kind, enabled, invalid)
 Notifications.Guide("PlacementHint", text, invalid and "error" or "guide", enabled, 10,
  kind == "Zombie" and L.text("dropZombie", L.lang()) or nil, dropHeldZombie)
end

local function myPlot()
	local world = workspace:FindFirstChild("DigAZombie")
	if not world then
		return nil
	end
	for _, plot in world:GetChildren() do
		if plot:GetAttribute("Owner") == p.UserId and plot:GetAttribute("BasePosition") then
			return plot
		end
	end
end
local function baseOf(plot)
	return CFrame.new(plot:GetAttribute("BasePosition")) * CFrame.Angles(0, plot:GetAttribute("BaseYaw") or 0, 0)
end

-- What already stands in the yard, read from the world, in the shape PlacementRules expects.
local function occupancy(plot, base)
	local d = { graves = {}, zombies = {} }
	for _, x in plot:GetChildren() do
		if x:IsA("Model") and (x.Name == "Grave" or x.Name == "Zombie") then
			local v = base:PointToObjectSpace(x:GetPivot().Position)
			if x.Name == "Grave" then
				table.insert(d.graves, { id = x:GetAttribute("GraveId"), pos = { x = v.X, z = v.Z } })
			elseif x:GetAttribute("Zone") == "Field" or x:GetAttribute("Zone") == "Guards" then
				table.insert(d.zombies, { id = x:GetAttribute("ZombieId"),type=x:GetAttribute("Type"),tier=x:GetAttribute("Tier") or 1,stars=x:GetAttribute("Stars") or 1, zone = x:GetAttribute("Zone"), pos = { x = v.X, z = v.Z } })
			end
		end
	end
	return d
end

local function heldObject()
 local model=p.Character and p.Character:FindFirstChild("HeldZombie")
 return {id=p:GetAttribute("HoldingZombie"),type=model and model:GetAttribute("Type"),tier=model and model:GetAttribute("Tier") or 1,stars=model and model:GetAttribute("Stars") or 1}
end
local function mode()
	if p:GetAttribute("HoldingZombie") then
		return "Zombie"
	elseif p:GetAttribute("ActiveSlot") == 3 and p:GetAttribute("SelectedGrave") then
		return "Grave"
	end
end

local function menuOpen()
	local menu = gui:FindFirstChild("Menu")
	return gui:GetAttribute("ModalOpen")==true or menu and menu.Visible or gui:FindFirstChild("Reveal")~=nil or gui:FindFirstChild("PetHatch")~=nil
end

-- Screen point -> farm-local spot and whether it is free.
local function probe(screen, viewport)
	local plot = myPlot()
	if not plot then
		return nil
	end
	local base = baseOf(plot)
	local camera = workspace.CurrentCamera
	local ray = viewport and camera:ViewportPointToRay(screen.X, screen.Y) or camera:ScreenPointToRay(screen.X, screen.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude = { ghost }
	for _, who in Players:GetPlayers() do
		if who.Character then
			table.insert(exclude, who.Character)
		end
	end
	params.FilterDescendantsInstances = exclude
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 600, params)
	if not hit then
		return nil
	end
	local v = base:PointToObjectSpace(hit.Position)
	local point = p:GetAttribute("HoldingZombie") and Place.Point(v.X,v.Z) or Place.GravePoint(v.X,v.Z)
	local kind = mode()
	local reason = "placeBad"
	if point then reason = Place.Check(occupancy(plot, base), kind, point, heldObject()) end
	return point, reason, base
end

local lastPoint, lastReason
Run.RenderStepped:Connect(function()
	local kind = mode()
	local lang = L.lang()
	placementGuide(L.text("placeHint", lang), kind, kind ~= nil and not menuOpen())
	if not kind or menuOpen() then
		ghost.Parent = nil
		lastPoint = nil
		return
	end
	-- On a phone there is no pointer: the ghost waits in front of the player until the ground is tapped.
	local screen
	if Input.MouseEnabled then
		screen = Input:GetMouseLocation()
	else
		local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end
		local ahead = workspace.CurrentCamera:WorldToViewportPoint(root.Position + root.CFrame.LookVector * 5 - Vector3.new(0, 2.5, 0))
		screen = Vector2.new(ahead.X, ahead.Y)
	end
	local point, reason, base = probe(screen, true)
	lastPoint, lastReason = point, reason
	if not point then
		ghost.Parent = nil
		return
	end
	placementGuide(L.text(reason or (kind == "Grave" and "placeCemetery" or "placeHint"), lang), kind, true, reason ~= nil)
	local color = reason and BAD or GOOD
	local radius = Place.Radius(kind,heldObject())
	ring.Size = Vector3.new(0.12, radius * 2, radius * 2)
	local cf = base * CFrame.new(point.x, -0.35, point.z)
	ring.CFrame = cf * CFrame.Angles(0, 0, math.pi / 2)
	stone.CFrame = cf * CFrame.new(0, 1.15, 0)
	body.CFrame = cf * CFrame.new(0, 1.7, 0)
	stone.Transparency = kind == "Grave" and 0.45 or 1
	body.Transparency = kind == "Zombie" and 0.55 or 1
	for _, q in { ring, stone, body } do
		q.Color = color
	end
	ghost.Parent = workspace
end)

local function place(screen)
	local kind = mode()
	if not kind or menuOpen() then
		return
	end
	local point = probe(screen, false)
	if not point then
		return
	end
	-- Sent even when the ghost is red: the server re-checks and tells the player why it can't go there.
	local arg = string.format("%.1f,%.1f", point.x, point.z)
	intent:FireServer(kind == "Grave" and "plantAt" or "placeZombie", arg)
end

Input.InputBegan:Connect(function(input, processed)
	if not processed and input.UserInputType == Enum.UserInputType.MouseButton1 then
		place(Vector2.new(input.Position.X, input.Position.Y))
	end
end)
Input.TouchTapInWorld:Connect(function(point, processed)
	if not processed then
		place(point)
	end
end)

-- Graves caught back by guards fly home in an arc.
local returns = {}
local function track(v)
	if v:IsA("Model") and v.Name == "Grave" then
		v:GetAttributeChangedSignal("ReturnAt"):Connect(function()
			local from = v:GetAttribute("ReturnFrom")
			if typeof(from) == "Vector3" then
				returns[v] = { to = v:GetPivot(), from = from, at = workspace:GetServerTimeNow() }
			end
		end)
	end
end
workspace.DescendantAdded:Connect(track)
for _, v in workspace:GetDescendants() do
	track(v)
end
Run.RenderStepped:Connect(function()
	local now = workspace:GetServerTimeNow()
	for model, r in returns do
		if not model.Parent then
			returns[model] = nil
		else
			local t = math.clamp((now - r.at) / 0.65, 0, 1)
			local point = r.from:Lerp(r.to.Position, t) + Vector3.new(0, math.sin(t * math.pi) * 7, 0)
			model:PivotTo(CFrame.new(point) * r.to.Rotation)
			if t >= 1 then
				returns[model] = nil
			end
		end
	end
end)
