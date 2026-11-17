-- The boss finisher (owner, 2026-11-15: "at some point the boss is stunned and you finish it like in an AAA game: the
-- player pulls the shovel from behind the back and drives it into the monster's head, fully animated, with an action
-- camera; a target pulses on the boss with 'Finish it'"). RoadService staggers the boss at its health thresholds and
-- owns the damage (RoadConfig.Boss.Stagger, Finisher); this script is the player's side of it:
--   the target   a pulsing button over a staggered boss while you stand within reach; tapping asks the server
--   the scene    the walk up, holding you in front of it and the camera (below: "The cinematic"); the body
--                plays the pack's clips (ClipPlayer) and holds the shovel as a blade, or works the chainsaw
--                (ShovelMotion.Finisher, CombatPose). Which of the finishers it is comes with it: the player's
--                FinisherKind attribute (RoadConfig.Boss.Finisher.Kinds).
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local S = RS:WaitForChild("Shared")
local C = require(S.Config.RoadConfig)
local L = require(S.Locale)
local Icons = require(S.Icons)
local Sfx = require(S.Sfx)
local p = Players.LocalPlayer
local rem = RS:WaitForChild("Remotes")
local folder = workspace:WaitForChild("Mutants")
local F, ST = C.Boss.Finisher, C.Boss.Stagger
local ShovelMotion = require(S.ShovelMotion)
local Rules = require(S.RoadMonsterRules)
local UP = Vector3.yAxis

local function smooth(t)
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end
local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end

-- The target ---------------------------------------------------------------------------------------------------------
local board = Instance.new("BillboardGui")
board.Name = "BossFinishTarget"
board.Size = UDim2.fromOffset(120, 120)
board.AlwaysOnTop = true
board.LightInfluence = 0
board.Active = true
board.ResetOnSpawn = false
board.Enabled = false
board.Parent = p:WaitForChild("PlayerGui")
local button = Instance.new("ImageButton")
button.Name = "Target"
button.BackgroundTransparency = 1
button.AnchorPoint = Vector2.new(0.5, 0.5)
button.Position = UDim2.fromScale(0.5, 0.4)
button.Size = UDim2.fromOffset(64, 64)
button.Image = Icons.auto_on or ""
button.ImageColor3 = Color3.fromRGB(255, 214, 90)
button.Parent = board
local ring = Instance.new("Frame")
ring.Name = "Ring"
ring.AnchorPoint = Vector2.new(0.5, 0.5)
ring.Position = UDim2.fromScale(0.5, 0.5)
ring.Size = UDim2.fromScale(1.15, 1.15)
ring.BackgroundTransparency = 1
ring.Parent = button
Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
local ringStroke = Instance.new("UIStroke", ring)
ringStroke.Color = Color3.fromRGB(255, 226, 120)
ringStroke.Thickness = 3
local caption = Instance.new("TextLabel")
caption.Name = "Caption"
caption.BackgroundTransparency = 1
caption.AnchorPoint = Vector2.new(0.5, 0)
caption.Position = UDim2.new(0.5, 0, 0.72, 0)
caption.Size = UDim2.fromOffset(120, 24)
caption.Font = Enum.Font.GothamBlack
caption.TextScaled = true
caption.TextColor3 = Color3.fromRGB(255, 240, 200)
caption.TextStrokeTransparency = 0
caption.TextStrokeColor3 = Color3.fromRGB(80, 10, 20)
caption.AutoLocalize = false
caption.Parent = board
local pulse = Instance.new("UIScale")
pulse.Parent = button
local busyUntil, running = 0, false
button.Activated:Connect(function()
	if os.clock() < busyUntil or running then
		return
	end
	busyUntil = os.clock() + 1
	Sfx.play("Click")
	rem.RoadAction:FireServer("finisher")
end)

local staggered, scanAt = nil, 0
Run.Heartbeat:Connect(function()
	local now = workspace:GetServerTimeNow()
	if os.clock() >= scanAt then -- which boss is down, checked ten times a second
		scanAt = os.clock() + 0.1
		staggered = nil
		local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
		if root and h and h.Health > 0 then
			for _, m in folder:GetChildren() do
				local untilAt = m:GetAttribute("StaggeredUntil")
				if untilAt and now < untilAt and not m:GetAttribute("FinisherUserId") and m.PrimaryPart and flat(root.Position - m.PrimaryPart.Position).Magnitude <= ST.Reach then
					staggered = m
					break
				end
			end
		end
	end
	local show = staggered ~= nil and staggered.Parent ~= nil and not running
	board.Enabled = show
	if not show then
		board.Adornee = nil
		return
	end
	if board.Adornee ~= staggered.PrimaryPart then
		board.Adornee = staggered.PrimaryPart
		board.StudsOffsetWorldSpace = Vector3.new(0, 1, 0)
	end
	local t = os.clock()
	pulse.Scale = 1 + math.sin(t * 6) * 0.16
	ringStroke.Transparency = (t * 1.6) % 1
	ring.Size = UDim2.fromScale(1.1 + ((t * 1.6) % 1) * 0.6, 1.1 + ((t * 1.6) % 1) * 0.6)
	caption.Text = L.text("bossFinishButton", L.lang())
end)

-- The cinematic ------------------------------------------------------------------------------------------------------
-- v3 (owner, the same day: "I've put animations in the project folder, let's try them", The Legion's memento mori for
-- the look): the player walks up to the front of the boss on its knees and plays the clips (shared/Clips, on the
-- whole body: CombatPose) with the shovel held as a blade; the boss shudders at every hit (MutantAnimation). This
-- script walks you there, holds you in place, and shoots it: moving shots with depth of field, a darker grade, a
-- tilted horizon and black bars, the interface hidden.
--   the walk       low behind you, the boss ahead
--   between hits   the two of you in profile, pushing in; then over your shoulder at its head, turning slowly
--   every hit      close on its head: a shake, a flash, red
--   the last blow  low from beside the boss looking up at you, then its head, then pulling away
-- The chainsaw (K.Saw) is shot its own way: low beside the boss's head looking up at you while you start the saw and
-- raise it, then close on the two of you from the side for as long as it grinds, creeping round to the front.
-- A boss's limb now and then gets between the lens and the two of you (an arm flung out by a blow, a leg in the
-- air): the camera rises over it and comes back down when it is clear. What is in the way is judged from the boss's
-- joints (a skinned boss's bones, a rigid one's pieces), since its parts answer no raycast.
-- The other monsters in the arena (a boss's summoned ones) are not drawn for you while it runs: they can't touch you
-- meanwhile (RoadService), and one of them standing in front of the lens would hide the whole thing.
-- Studio: the workspace attribute FinisherPreview holds the camera still in profile (to look at a clip).
local bars = Instance.new("ScreenGui")
bars.Name = "FinisherBars"
bars.IgnoreGuiInset = true
bars.ResetOnSpawn = false
bars.DisplayOrder = 60
bars.Enabled = false
bars.Parent = p.PlayerGui
local function bar(top)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = Color3.new(0, 0, 0)
	f.BorderSizePixel = 0
	f.AnchorPoint = Vector2.new(0, top and 0 or 1)
	f.Position = UDim2.fromScale(0, top and 0 or 1)
	f.Size = UDim2.fromScale(1, 0)
	f.Parent = bars
	return f
end
local barTop, barBottom = bar(true), bar(false)
local flash = Instance.new("Frame")
flash.BackgroundColor3 = Color3.new(1, 1, 1)
flash.BorderSizePixel = 0
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundTransparency = 1
flash.Parent = bars

local function play(boss, startedAt, K)
	local ch = p.Character
	local root = ch and ch:FindFirstChild("HumanoidRootPart")
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not root or not hum or not boss.PrimaryPart or running then
		return
	end
	running = true
	local cam = workspace.CurrentCamera
	local oldType, oldFov, oldRotate = cam.CameraType, cam.FieldOfView, hum.AutoRotate
	local scale = boss:GetScale()
	local bossAt = boss.PrimaryPart.Position
	local front = flat(boss.PrimaryPart.CFrame.LookVector)
	front = front.Magnitude > 0.1 and front.Unit or Vector3.new(0, 0, -1)
	local right = front:Cross(UP)
	local groundY = root.Position.Y
	local bossGround = Vector3.new(bossAt.X, groundY, bossAt.Z)
	-- the camera keeps to the arena's inner side, away from its wall
	local center = boss:GetAttribute("ArenaCenter")
	local lens = (typeof(center) == "Vector3" and flat(center - bossAt):Dot(right) < 0) and -right or right
	local reach = (boss:GetAttribute("NavigationRadius") or 2) * scale
	local aside = right * (K.Side or 0) -- some finishers pass beside its head, not through it
	local rule = Rules.Bosses[boss:GetAttribute("Boss") or 0]
	local off = K.Stand + (rule and rule.FinisherOff or 0) -- (a boss with a wide head is finished from further off)
	local stand = bossGround + front * (reach + off) + aside -- until its head is down: then that far in front of it
	local headAt = bossAt + UP * 2 * scale + front * reach * 0.6
	local function head() -- the middle of its head now (kept if the boss is gone: the last blow kills it)
		local now = boss.Parent and ShovelMotion.BossHead(boss)
		if now then
			headAt = headAt:Lerp(now, 0.3)
		end
		return headAt
	end
	local controls
	pcall(function()
		controls = require(p:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 2)):GetControls()
	end)
	if controls then
		controls:Disable()
	end
	hum.AutoRotate = true
	hum:MoveTo(stand)
	-- From far off it begins with a run-up (RoadConfig.Boss.Stagger.Run: the clock `sec` is negative that long): you
	-- sprint to the boss - as fast as it takes to be there when the walk is over.
	local run = math.max(0, startedAt - workspace:GetServerTimeNow())
	local oldSpeed = hum.WalkSpeed
	if run > 0 then
		hum.WalkSpeed = math.max(oldSpeed, flat(stand - root.Position).Magnitude / (run + K.Walk - 0.15))
	end
	cam.CameraType = Enum.CameraType.Scriptable
	bars.Enabled = true
	-- nothing of the interface over the shots: every screen that was showing comes back afterwards
	local hidden = {}
	for _, g in p.PlayerGui:GetChildren() do
		if g:IsA("ScreenGui") and g ~= bars and g.Enabled then
			hidden[g] = true
			g.Enabled = false
		end
	end
	local focus = Instance.new("DepthOfFieldEffect")
	focus.Name = "FinisherFocus"
	focus.FarIntensity, focus.NearIntensity, focus.InFocusRadius = 0.5, 0.25, 7
	focus.Parent = cam
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "FinisherGrade"
	grade.Contrast, grade.Saturation = 0.16, -0.18
	grade.Parent = cam
	-- the boss's joints, to tell when a limb is in the lens's way
	local bones, pieces = {}, {}
	for _, d in boss:GetDescendants() do
		if d:IsA("Bone") then
			table.insert(bones, { bone = d, from = d.Parent:IsA("Bone") and d.Parent or nil, leaf = d:FindFirstChildWhichIsA("Bone") == nil })
		end
	end
	if #bones == 0 then
		for _, d in boss:GetChildren() do
			if d:IsA("BasePart") and d ~= boss.PrimaryPart then
				table.insert(pieces, d)
			end
		end
	end
	local function inTheWay(from, look)
		local line = from - look
		local length = line:Dot(line)
		local function near(q)
			local t = (q - look):Dot(line) / length
			return t > 0.2 and t < 1.05 and (q - (look + line * t)).Magnitude < 0.9 * scale * (0.5 + t)
		end
		for _, b in bones do
			local at = b.bone.TransformedWorldCFrame.Position
			if near(at) then
				return true
			end
			if b.from then
				local base = b.from.TransformedWorldCFrame.Position
				-- a limb goes on past its last joint about as far again (a hand, a weapon in it)
				if near(at:Lerp(base, 0.5)) or (b.leaf and (near(at + (at - base) * 0.5) or near(at + (at - base)))) then
					return true
				end
			end
		end
		for _, part in pieces do
			local reach = part.CFrame:VectorToWorldSpace(Vector3.new(0, part.Size.Y / 3, 0))
			if near(part.Position) or near(part.Position + reach) or near(part.Position - reach) then
				return true
			end
		end
		return false
	end
	local lift = 0
	local unseen, unseenAt = {}, 0
	local function hideOthers(now)
		if now < unseenAt then
			return
		end
		unseenAt = now + 0.25
		for _, m in folder:GetChildren() do
			if m ~= boss and not unseen[m] then
				unseen[m] = true
				for _, q in m:GetDescendants() do
					if q:IsA("BasePart") then
						q.LocalTransparencyModifier = 1
					end
				end
			end
		end
	end
	local facing = CFrame.lookAt(Vector3.zero, -front) -- towards the boss
	local seed = math.random() * 100
	local walk, last, saw = K.Walk, K.Impact, K.Saw
	local settled, settleFrom, settleFacing
	local at = root.Position
	while true do
		local dt = Run.RenderStepped:Wait()
		local sec = workspace:GetServerTimeNow() - startedAt
		if sec >= K.Seconds or not root.Parent or hum.Health <= 0 then
			break
		end
		local top = head()
		hideOthers(os.clock())
		-- You: walking up (to in front of its head, which sinks as you come), then held on your spot for the clips
		if sec < walk then
			stand = Vector3.new(top.X, groundY, top.Z) + front * off + aside
			if sec > 0.3 or run > 0 then
				hum:MoveTo(stand)
			end
			at = root.Position
		else
			if not settled then
				settled, settleFrom, settleFacing = true, root.Position, root.CFrame.Rotation
				hum.WalkSpeed = oldSpeed
				root.Anchored = true
				hum.AutoRotate = false
			end
			local k = smooth((sec - walk) / 0.25)
			at = settleFrom:Lerp(Vector3.new(stand.X, settleFrom.Y, stand.Z), k)
			root.CFrame = CFrame.new(at) * settleFacing:Lerp(facing, k)
			root.AssemblyLinearVelocity = Vector3.zero
		end
		-- how hard the nearest hit is shaking things, and how long since it
		local since, heavy = math.huge, false
		for _, h in K.Hits do
			if sec >= h and sec - h < since then
				since, heavy = sec - h, h == last
			end
		end
		local nextHit = math.huge
		for _, h in K.Hits do
			if h > sec and h < nextHit then
				nextHit = h
			end
		end
		-- where your body really is (the clips carry it off the spot it is held on), and the point between the two of you
		local torso = ch:FindFirstChild("UpperTorso")
		local chest = torso and torso.Position or at + UP * 1.2
		local between = chest:Lerp(top, 0.5)
		local apart = (flat(top - chest)).Magnitude
		local from, look, fov, roll
		if workspace:GetAttribute("FinisherPreview") then
			from, look, fov, roll = stand - front * 2 + lens * 13 + UP * 1.2, stand - front * 2 + UP * 0.6, 60, 0
		elseif sec < walk then
			-- the walk: low behind you, the boss ahead
			local k = smooth(sec / walk)
			local toBoss = flat(bossAt - at)
			toBoss = toBoss.Magnitude > 0.1 and toBoss.Unit or -front
			from = at - toBoss * (8 - 1.5 * k) + lens * 3 + UP * (0.3 + 0.6 * k)
			look = chest:Lerp(top, 0.45)
			fov, roll = 62 - 6 * k, -0.05
		elseif sec >= last + 0.5 then
			-- after the last blow: wide, pulling up and away
			local k = smooth((sec - last - 0.5) / math.max(0.2, K.Seconds - last - 0.55))
			from = between + lens * (12 + 2 * scale + 4 * k) + front * (5 + 3 * k) + UP * (1.5 + 4 * k)
			look = between
			fov, roll = 52 + (oldFov - 52) * k, 0.03 * (1 - k)
		elseif saw and sec < saw.Cut - 0.1 then
			-- the saw being started and raised: low beside its head, looking up at you
			local k = smooth((sec - walk) / (saw.Cut - walk))
			from = top + lens * (5.5 + 1.2 * scale - 1.2 * k) - front * (1.5 - 1.5 * k) - UP * (1 + 0.3 * k)
			look = chest:Lerp(top, 0.15) + UP * 0.7
			fov, roll = 58 - 8 * k, 0.05
		elseif saw and sec < saw.Rip then
			-- the saw in its head: the two of you from the side, close, creeping round to the front
			local k = (sec - saw.Cut) / (saw.Rip - saw.Cut)
			from = between + lens * (7 + 1.2 * scale + apart * 0.5 - 1.5 * k) + front * (0.5 + 3 * k) + UP * (0.2 + 0.5 * k)
			look = between:Lerp(chest, 0.35)
			fov = 48 - 4 * k + 5 * math.exp(-since * 9)
			roll = 0.05 * math.sin(sec * 1.3)
		elseif since < 0.5 then
			-- a hit: the two of you from the side, close, the blade and its head in the frame
			local k = since / 0.5
			from = between + lens * (7.5 + 1.2 * scale + apart * 0.5 - 1 * k) + front * 1.5 + UP * (0.5 + 0.4 * k)
			look = between
			fov = (heavy and 44 or 50) + (heavy and 16 or 9) * math.exp(-since * 9)
			roll = heavy and 0.07 or -0.04
		elseif nextHit == last then
			-- the last blow winding up: low beside its head, looking up at you
			local k = smooth(math.clamp(1 - (nextHit - sec) / 0.6, 0, 1))
			from = top + lens * (6 + 1.2 * scale - 1 * k) - front * (2 - 2 * k) - UP * (1.4 + 0.4 * k)
			look = chest:Lerp(top, 0.25) + UP * 0.6
			fov, roll = 56 - 7 * k, 0.06 * (1 - k) + 0.02
		else
			-- between blows: behind your shoulder and well to the side, its head beyond you, drifting
			local k = smooth((sec - walk) / math.max(0.1, last - walk))
			from = chest + front * (6.5 + 1.5 * k) + lens * (5.5 - 1.5 * k) + UP * (1.6 + 0.8 * k)
			look = between
			fov, roll = 56 - 4 * k, -0.04
		end
		if not workspace:GetAttribute("FinisherPreview") then
			local blocked = boss.Parent ~= nil and inTheWay(from, look)
			lift += ((blocked and 1 or 0) - lift) * (1 - math.exp(-dt * (blocked and 9 or 2.5)))
			from += UP * lift * (3 + 2.5 * scale)
		end
		from = Vector3.new(from.X, math.max(from.Y, groundY - 2.4), from.Z) -- never under the floor
		if since < 1.2 then
			-- (the saw's grinding shakes all the while; only its last blow flashes)
			local grinding = saw and sec < saw.Rip
			local shake = grinding and 0.18 + 0.2 * math.exp(-since * 8) or math.exp(-since * 6) * (heavy and 0.8 or 0.4)
			from += Vector3.new(math.noise(seed, sec * 30), math.noise(seed + 9, sec * 30), math.noise(seed + 17, sec * 30)) * shake
			flash.BackgroundTransparency = grinding and 1 or math.clamp((heavy and 0.4 or 0.85) + since * 5, 0, 1)
			local red = math.exp(-since * (heavy and 3 or 6)) * (heavy and 1 or 0.5)
			grade.TintColor = Color3.new(1, 1 - 0.45 * red, 1 - 0.5 * red)
		else
			flash.BackgroundTransparency = 1
			grade.TintColor = Color3.new(1, 1, 1)
		end
		cam.CFrame = CFrame.lookAt(from, look) * CFrame.Angles(0, 0, roll)
		cam.FieldOfView = fov
		focus.FocusDistance = (look - from).Magnitude
		local open = math.min(smooth((sec + run) / 0.35), 1 - smooth((sec - (K.Seconds - 0.35)) / 0.35))
		barTop.Size = UDim2.fromScale(1, 0.12 * open)
		barBottom.Size = UDim2.fromScale(1, 0.12 * open)
	end
	flash.BackgroundTransparency = 1
	bars.Enabled = false
	for m in unseen do
		for _, q in m:GetDescendants() do
			if q:IsA("BasePart") then
				q.LocalTransparencyModifier = 0
			end
		end
	end
	focus:Destroy()
	grade:Destroy()
	for g in hidden do
		if g.Parent then
			g.Enabled = true
		end
	end
	cam.FieldOfView = oldFov
	cam.CameraType = oldType == Enum.CameraType.Scriptable and Enum.CameraType.Custom or oldType
	if root.Parent then
		-- the clips carried the body off its spot: the character itself goes there as the last one lets go
		if settled then
			root.CFrame = root.CFrame * CFrame.new(ShovelMotion.FinisherEnd(K))
		end
		root.Anchored = false
		root.AssemblyLinearVelocity = Vector3.zero
	end
	if hum.Parent then
		hum.AutoRotate = oldRotate
		if not settled then
			hum.WalkSpeed = oldSpeed
		end
		hum:Move(Vector3.zero)
	end
	if controls then
		controls:Enable()
	end
	running = false
end

p:GetAttributeChangedSignal("FinisherAt"):Connect(function()
	local startedAt = p:GetAttribute("FinisherAt")
	-- (FinisherUntil may not have arrived yet when this fires: the end is worked out from the start)
	if not startedAt then
		return
	end
	task.spawn(function()
		Run.Heartbeat:Wait() -- the attributes that came with it (which finisher, which boss) are all in by now
		local K = F.Of(p)
		if p:GetAttribute("FinisherAt") ~= startedAt or workspace:GetServerTimeNow() >= startedAt + K.Seconds then
			return
		end
		local id = p:GetAttribute("FinisherBoss")
		for _, m in folder:GetChildren() do
			if m:GetAttribute("MutantId") == id then
				play(m, startedAt, K)
				return
			end
		end
	end)
end)
