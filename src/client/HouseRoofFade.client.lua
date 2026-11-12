-- Inside your own house the roof fades away, so the camera above you shows the room instead of tiles.
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local p = Players.LocalPlayer
local fade = 0
Run.RenderStepped:Connect(function(dt)
	local goal = p:GetAttribute("InHouse") == true and 1 or 0
	if math.abs(goal - fade) < 0.001 then
		return
	end
	fade += (goal - fade) * math.min(1, dt * 8)
	if math.abs(goal - fade) < 0.01 then
		fade = goal
	end
	local world = workspace:FindFirstChild("DigAZombie")
	if not world then
		return
	end
	for _, plot in world:GetChildren() do
		if plot:GetAttribute("Owner") == p.UserId then
			local house = plot:FindFirstChild("House")
			for _, q in house and house:GetDescendants() or {} do
				if q:IsA("BasePart") and (q:GetAttribute("HouseRoof") or q.Name == "Chimney" or q.Name == "ChimneyCap") then
					q.LocalTransparencyModifier = fade * 0.85
				end
			end
		end
	end
end)
