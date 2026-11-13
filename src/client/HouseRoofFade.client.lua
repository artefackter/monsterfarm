-- Inside your own house everything above you fades, so the camera above you shows the room instead of the roof.
-- Since the floors got stairs (2026-11-13) it is "above you", not "above the ground floor": upstairs, that floor's
-- slab and walls stay solid and only the floors higher up fade.
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local p = Players.LocalPlayer
local fade = 0
local nextScan = 0
local faded = {}
Run.RenderStepped:Connect(function(dt)
	local inside = p:GetAttribute("InHouse") == true
	local goal = inside and 1 or 0
	fade += (goal - fade) * math.min(1, dt * 8)
	if math.abs(goal - fade) < 0.01 then
		fade = goal
	end
	if fade == 0 and not next(faded) then
		return
	end
	if os.clock() < nextScan and fade == goal then
		return
	end
	nextScan = os.clock() + 0.15
	local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	local feet = root and root.Position.Y - 2 or -math.huge
	local world = workspace:FindFirstChild("DigAZombie")
	if not world then
		return
	end
	local seen = {}
	for _, plot in world:GetChildren() do
		if plot:GetAttribute("Owner") == p.UserId then
			local house = plot:FindFirstChild("House")
			for _, q in house and house:GetDescendants() or {} do
				if q:IsA("BasePart") and (q:GetAttribute("HouseRoof") or q.Name == "Chimney" or q.Name == "ChimneyCap") then
					local bottom = q.Position.Y - q.Size.Y / 2
					local above = bottom > feet + 2.5
					q.LocalTransparencyModifier = above and fade * 0.85 or 0
					if above and fade > 0 then
						seen[q] = true
					end
				end
			end
		end
	end
	for q in faded do
		if not seen[q] and q.Parent then
			q.LocalTransparencyModifier = 0
		end
	end
	faded = seen
end)
