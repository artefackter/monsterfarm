-- Signs in the player's own language, swaying crops, waving grave hands, drifting clouds.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local S = game.ReplicatedStorage:WaitForChild("Shared")
local L = require(S.Locale)

local lang = L.lang()
local isRussian = string.sub(lang, 1, 2) == "ru"

local function applyText(label)
	label.AutoLocalize=false
	label.Text = L.text(label:GetAttribute("LocKey"), lang, {n=label:GetAttribute("LocDistance")})
	-- FredokaOne has no Cyrillic glyphs, GothamBlack has both.
	label.Font = isRussian and Enum.Font.GothamBlack or Enum.Font.FredokaOne
end
local function applyPlate(label)
	label.AutoLocalize=false
	local name = label:GetAttribute("OwnerName")
	label.Text = name and L.text("owner", lang, { name = name }) or L.text("unclaimed", lang)
	label.Font = isRussian and Enum.Font.GothamBlack or Enum.Font.FredokaOne
end
local function applyStatue(label)
	label.AutoLocalize=false
	local name, kind = label:GetAttribute("ChampName"), label:GetAttribute("ChampType")
	label.Text = name and kind and L.text("statuePlaque", lang, { name = name, zombie = L.text(kind, lang) }) or L.text("statueEmpty", lang)
	label.Font = Enum.Font.GothamBlack
end
local function applyNumber(label)
 label.AutoLocalize=false;label.Text=(label:GetAttribute("CompactPrefix") or "")..L.compact(label:GetAttribute("CompactValue") or 0,lang)
end
local function checkText(d)
 if d:IsA("TextLabel") then
  d:GetAttributeChangedSignal("LocDistance"):Connect(function() if d:GetAttribute("LocKey") then applyText(d) end end)
  d:GetAttributeChangedSignal("CompactValue"):Connect(function() if d:GetAttribute("CompactValue")~=nil then applyNumber(d) end end)
		if d:GetAttribute("CompactValue")~=nil then
            applyNumber(d)
        elseif d:GetAttribute("StatuePlate") then
			applyStatue(d)
			for _, attr in ipairs({ "ChampName", "ChampType" }) do
				d:GetAttributeChangedSignal(attr):Connect(function()
					applyStatue(d)
				end)
			end
		elseif d:GetAttribute("LocKey") then
			applyText(d)
		elseif d:GetAttribute("OwnerPlate") then
			applyPlate(d)
			d:GetAttributeChangedSignal("OwnerName"):Connect(function()
				applyPlate(d)
			end)
		end
	end
end
workspace.DescendantAdded:Connect(checkText)
game.Players.LocalPlayer:GetAttributeChangedSignal("Language"):Connect(function()
	lang = L.lang()
	isRussian = string.sub(lang, 1, 2) == "ru"
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("TextLabel") then
			if d:GetAttribute("CompactValue")~=nil then
            applyNumber(d)
        elseif d:GetAttribute("StatuePlate") then
				applyStatue(d)
			elseif d:GetAttribute("LocKey") then
				applyText(d)
			elseif d:GetAttribute("OwnerPlate") then
				applyPlate(d)
			end
		end
	end
end)
for _, d in ipairs(workspace:GetDescendants()) do
	checkText(d)
end

-- The server teleports the character home after spawning; bring the camera around behind them.
local function lookHome(character)
	local root = character:WaitForChild("HumanoidRootPart", 5)
	task.wait(0.45)
	if root and root.Parent then
		local camera = workspace.CurrentCamera
		local focus = root.Position + Vector3.new(0, 2, 0)
		camera.CFrame = CFrame.lookAt(focus - root.CFrame.LookVector * 14 + Vector3.new(0, 7, 0), focus)
	end
end
local localPlayer = game:GetService("Players").LocalPlayer
localPlayer.CharacterAdded:Connect(lookHome)
if localPlayer.Character then
	task.spawn(lookHome, localPlayer.Character)
end

local RANGE = 110
local tracked = {}
local function track(tag, kind)
	local function add(part)
		if part:IsA("BasePart") then
			tracked[part] = { kind = kind, rest = part.CFrame, phase = math.random() * 6, height = part.Size.Y }
		end
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(add)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(function(part)
		tracked[part] = nil
	end)
	for _, part in ipairs(CollectionService:GetTagged(tag)) do
		add(part)
	end
end
track("ArtSway", "sway")
track("ArtWave", "wave")
track("ArtCloud", "cloud")
track("ArtBob", "bob")

RunService.RenderStepped:Connect(function()
	local now = os.clock()
	local camera = workspace.CurrentCamera.CFrame.Position
	local parts, frames = {}, {}
	for part, data in pairs(tracked) do
		local t = now + data.phase
		local cf
		if data.kind == "cloud" then
			cf = data.rest * CFrame.new(math.sin(t * 0.03) * 22, math.sin(t * 0.2) * 1.6, 0)
		elseif data.kind == "bob" then
			-- balloons: a gentle float and drift
			cf = data.rest * CFrame.new(math.sin(t * 0.7) * 0.25, math.sin(t * 1.4) * 0.35, math.cos(t * 0.6) * 0.25)
		elseif (data.rest.Position - camera).Magnitude < RANGE and part.Transparency < 1 then
			local base = CFrame.new(0, -data.height / 2, 0)
			local tilt = data.kind == "sway" and CFrame.Angles(math.sin(t * 1.3) * 0.06, 0, math.cos(t * 1.1) * 0.06)
				or CFrame.Angles(0, 0, math.sin(t * 7) * 0.32)
			cf = data.rest * base * tilt * base:Inverse()
		end
		if cf then
			table.insert(parts, part)
			table.insert(frames, cf)
		end
	end
	if #parts > 0 then
		workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
	end
end)

-- Plaza show-pieces: the giant hand waves from its wrist, the mascots hop and turn to the music.
local shows = {}
local function trackModel(tag, kind)
	local function add(model)
		if model:IsA("Model") and model.PrimaryPart or model:IsA("Model") and model:FindFirstChildWhichIsA("BasePart") then
			shows[model] = { kind = kind, rest = model:GetPivot(), phase = model:GetAttribute("DancePhase") or math.random() * 6 }
		end
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(add)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(function(model)
		shows[model] = nil
	end)
	for _, model in CollectionService:GetTagged(tag) do
		add(model)
	end
end
trackModel("ArtGiantWave", "wave")
trackModel("ArtDance", "dance")
RunService.RenderStepped:Connect(function()
	local now = os.clock()
	local camera = workspace.CurrentCamera.CFrame.Position
	for model, data in shows do
		if not model.Parent then
			shows[model] = nil
		elseif (data.rest.Position - camera).Magnitude < 160 then
			local t = now + data.phase
			if data.kind == "wave" then
				model:PivotTo(data.rest * CFrame.Angles(math.sin(t * 0.7) * 0.05, 0, math.sin(t * 1.15) * 0.17))
			else
				local hop = math.abs(math.sin(t * 4))
				model:PivotTo(data.rest * CFrame.new(0, hop * 0.7, 0) * CFrame.Angles(0, math.sin(t * 1.3) * 0.7, math.sin(t * 4) * 0.09))
			end
		end
	end
end)

-- Only the local display name changes; server scripts retain the stable Income/s identifier.
local players=game:GetService("Players")
local function localizeStat(value)
 if value:IsA("NumberValue") and value.Name=="Income/s" and value.Parent and value.Parent.Name=="leaderstats" then
  value.Name=L.text("incomeStat",lang)
 end
end
local function watchPlayer(player)
 player.DescendantAdded:Connect(localizeStat)
 for _,value in ipairs(player:GetDescendants()) do localizeStat(value) end
end
players.PlayerAdded:Connect(watchPlayer)
for _,player in ipairs(players:GetPlayers()) do watchPlayer(player) end
