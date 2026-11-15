-- Client-side life for the monsters on the farms. Purely local: the server only places each model at rest.
-- A working monster lives a little life of its own: it stands and breathes, looks around, strolls a few steps
-- around its spot (legs and arms really walk), turns to the player who comes close and waves. A coin pops over it
-- when it earns, with no hop since 2026-11-13: every monster earns on the same beat, so the whole yard jumped at once.
-- Over its head: its name, what it earns per second and how rare it is. Far from the camera everything holds still.
local RunService = game:GetService("RunService")
local Pal = require(game.ReplicatedStorage.Shared.Palette)
local L = require(game.ReplicatedStorage.Shared.Locale)
local ZC = require(game.ReplicatedStorage.Shared.Config.ZombieConfig)
local Players = game:GetService("Players")

local ANIMATE_RANGE = 130
local NECK = Vector3.new(0, 0.42, -0.1)
local JOINTS = {
	ArmL = Vector3.new(0.92, 0.05, -0.05),
	ArmR = Vector3.new(-0.92, 0.05, -0.05),
	WingL = Vector3.new(0.56, -0.15, 0.86),
	WingR = Vector3.new(-0.56, -0.15, 0.86),
	Head = NECK,
}

-- Each family moves its own way (owner, 2026-11-13: "different animations for the monsters"). speed: stroll pace;
-- gait: step rate; bob: bounce per step; lean: forward hunch; sway: side roll at rest; jitter: twitchiness;
-- emotes: what it does now and then (the rotation's outfits add their own: the Miner digs, the Knight salutes,
-- the King waves like a king).
local Collection = require(game.ReplicatedStorage.Shared.MonsterCollection)
local STYLE = {
	Deer = { speed = 1.25, gait = 7, bob = 0.1, lean = -0.04, sway = 0.02, jitter = 0, emotes = { "rear", "rear", "spin" } },
	Parasite = { speed = 1.9, gait = 11.5, bob = 0.12, lean = 0.12, sway = 0.05, jitter = 0.035, emotes = { "shiver", "shiver", "skitter" } },
	Stalker = { speed = 1.05, gait = 6, bob = 0.1, lean = 0.22, sway = 0.015, jitter = 0, emotes = { "peek", "peek", "spin" } },
	Verity = { speed = 1.5, gait = 8.5, bob = 0.1, lean = 0.02, sway = 0.02, jitter = 0, emotes = { "glitch", "glitch", "spin" } },
	RingMaw = { speed = 2.3, gait = 13, bob = 0.06, lean = 0.06, sway = 0.05, jitter = 0.01, emotes = { "snap", "snap", "skitter" } },
	CaveDweller = { speed = 0.95, gait = 5.5, bob = 0.12, lean = 0.1, sway = 0.035, jitter = 0, emotes = { "stretch", "stretch", "spin" } },
	SirenHead = { speed = 0.85, gait = 4.5, bob = 0.08, lean = 0, sway = 0.03, jitter = 0, emotes = { "siren", "siren", "spin" } },
	-- the families of 2026-11-14 (Config.MonsterFamilies)
	Granny = { speed = 0.8, gait = 5, bob = 0.06, lean = 0.18, sway = 0.02, jitter = 0, emotes = { "peek", "peek", "spin" } },
	Grandfather = { speed = 0.85, gait = 5, bob = 0.08, lean = 0.14, sway = 0.02, jitter = 0, emotes = { "stretch", "stretch", "spin" } },
	Slenderman = { speed = 1.0, gait = 4, bob = 0.03, lean = 0, sway = 0.01, jitter = 0, emotes = { "glitch", "glitch", "peek" } },
	Slendrina = { speed = 1.1, gait = 5, bob = 0.05, lean = 0.04, sway = 0.02, jitter = 0.02, emotes = { "glitch", "peek", "spin" } },
	SpiderMom = { speed = 1.6, gait = 12, bob = 0.05, lean = 0, sway = 0.03, jitter = 0.02, emotes = { "skitter", "skitter", "spin" } },
	Longmaw = { speed = 1.4, gait = 7, bob = 0.1, lean = 0.05, sway = 0.03, jitter = 0, emotes = { "snap", "snap", "stretch" } },
	HoodedStranger = { speed = 1.0, gait = 5.5, bob = 0.06, lean = 0.08, sway = 0.015, jitter = 0, emotes = { "peek", "peek", "spin" } },
	Mimic = { speed = 1.3, gait = 7.5, bob = 0.1, lean = 0.02, sway = 0.04, jitter = 0, emotes = { "wave", "snap", "spin" } },
	AdaptedViscera = { speed = 1.5, gait = 10, bob = 0.08, lean = 0, sway = 0.05, jitter = 0.03, emotes = { "shiver", "skitter", "shiver" } },
	AssimilatedAdventurer = { speed = 1.2, gait = 7, bob = 0.1, lean = 0.15, sway = 0.03, jitter = 0.02, emotes = { "shiver", "stretch", "spin" } },
	Dredge = { speed = 1.1, gait = 6, bob = 0.05, lean = 0.05, sway = 0.06, jitter = 0, emotes = { "snap", "stretch", "spin" } },
	PrimitiveSummoner = { speed = 1.6, gait = 9, bob = 0.08, lean = 0, sway = 0.04, jitter = 0.02, emotes = { "snap", "skitter", "snap" } },
}
local DEFAULT_STYLE = { speed = 1.5, gait = 8.5, bob = 0.14, lean = 0, sway = 0, jitter = 0, emotes = { "hop", "spin" } }
-- the old families' outfits, and the new families' looks of the same name (their Princess waves like a King)
local OUTFIT_EMOTE = { Miner = "dig", Knight = "salute", King = "regal", Princess = "regal" }
local EMOTE_TIME = { hop = 1.1, spin = 1.1, wave = 1.7, rear = 1.4, shiver = 1.0, peek = 2.0, glitch = 0.9, snap = 1.2, skitter = 1.4, stretch = 1.8, siren = 1.4, dig = 1.8, salute = 1.6, regal = 2.0 }
local function styleOf(m, data)
	if not data.style then
		local id = m:GetAttribute("Type") or ""
		data.style = STYLE[Collection.Family(id)] or DEFAULT_STYLE
		local family = Collection.Family(id)
		data.outfitEmote = OUTFIT_EMOTE[Collection.Outfits[id] or (STYLE[family] and family ~= id and id:sub(#family + 1)) or ""]
	end
	return data.style
end

local models = {}

local function add(m)
	if m:IsA("Model") and m:GetAttribute("ZombieId") then
		models[m] = { last = os.clock(), born = os.clock(), phase = math.random() * 6 }
	end
end
workspace.DescendantAdded:Connect(add)
for _, m in ipairs(workspace:GetDescendants()) do
	add(m)
end

-- Rest offsets are captured once per part, before that part is ever animated. Parts can replicate
-- over several frames, so late arrivals are added without re-measuring the ones already moving.
local function rig(m, data)
	data.pivot = data.pivot or m:GetPivot()
	data.known = data.known or {}
	local parts, offsets, groups = {}, {}, {}
	for _, child in ipairs(m:GetChildren()) do
		if child:IsA("BasePart") then
			data.known[child] = data.known[child] or data.pivot:ToObjectSpace(child.CFrame)
			table.insert(parts, child)
			table.insert(offsets, data.known[child])
			table.insert(groups, child:GetAttribute("Attach") or "Body")
		end
	end
	data.parts, data.offsets, data.groups, data.count = parts, offsets, groups, #m:GetChildren()
end

local function around(point, rotation)
	return CFrame.new(point) * rotation * CFrame.new(-point)
end

local function floatIncome(m, data, now)
	if (m:GetAttribute("MutantBiting") or m:GetAttribute("MutantStunned") or m:GetAttribute("Carried")) or m:GetAttribute("Zone") ~= "Field" or now - data.last < 3 or not m.PrimaryPart then
		return
	end
	data.last = now
	local b = Instance.new("BillboardGui")
	local v = workspace.CurrentCamera.ViewportSize
	local k = math.clamp(math.min(v.X / 1000, v.Y / 560), 0.62, 1) -- smaller on phones
	b.Size = UDim2.fromOffset(130 * k, 42 * k)
	b.StudsOffset = Vector3.new(0, (m:GetAttribute("MonsterLabelHeight") or 4.4)*(m:GetAttribute("VisualSize") or 1), 0)
	b.Parent = m.PrimaryPart
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Text = "💰+" .. require(game.ReplicatedStorage.Shared.Locale).compact(m:GetAttribute("Income") or 0,require(game.ReplicatedStorage.Shared.Locale).lang())
	l.TextColor3 = Pal.Accent
	l.TextStrokeColor3 = Pal.Stroke
	l.TextStrokeTransparency = 0
	l.Font = Enum.Font.GothamBlack
	l.TextSize = math.floor(24 * k)
	l.Parent = b
	game.TweenService:Create(b, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { StudsOffset = Vector3.new(0, (m:GetAttribute("MonsterLabelHeight") or 4.4)*(m:GetAttribute("VisualSize") or 1)+2.6, 0) }):Play()
	game.TweenService:Create(l, TweenInfo.new(1.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	game.Debris:AddItem(b, 1.5)
end


-- Name, income per second and rarity over a monster, in the bold outlined style of the owner's reference.
local LABEL_RANGE = 50
-- Phones have few screen points, so the labels over the monsters shrink there (owner, 2026-11-14).
local function labelScale()
	local v = workspace.CurrentCamera.ViewportSize
	return math.clamp(math.min(v.X / 1000, v.Y / 560), 0.62, 1)
end
local function line(parent, y, height, size, color)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.new(1, 0, 0, height)
	l.Position = UDim2.fromOffset(0, y)
	l.Font = Enum.Font.GothamBlack
	l.TextSize = size
	l.TextColor3 = color
	l.AutoLocalize = false
	l.Parent = parent
	local st = Instance.new("UIStroke")
	st.Color = Color3.fromRGB(14, 10, 22)
	st.Thickness = 2.6
	st.LineJoinMode = Enum.LineJoinMode.Round
	st.Parent = l
	return l
end
local MUTATION_COLOR = { Golden = Color3.fromRGB(255, 214, 64), Lunar = Color3.fromRGB(150, 255, 200), Rainbow = Color3.fromRGB(255, 120, 220) }
local function label(m, data)
	local b = Instance.new("BillboardGui")
	b.Name = "MonsterStats"
	local k = labelScale()
	b.Size = UDim2.fromOffset(260 * k, 78 * k)
	b.LightInfluence = 0
	b.MaxDistance = LABEL_RANGE
	b.Adornee = m.PrimaryPart
	b.Parent = m.PrimaryPart
	data.gui = b
	data.nameLine = line(b, 0, 28 * k, math.floor(24 * k), Color3.new(1, 1, 1))
	data.rateLine = line(b, 27 * k, 28 * k, math.floor(24 * k), Color3.fromRGB(196, 255, 62))
	data.rareLine = line(b, 54 * k, 22 * k, math.floor(18 * k), Color3.new(1, 1, 1))
end
local function fillLabel(m, data)
	local lang = L.lang()
	local sig = lang .. tostring(m:GetAttribute("Type")) .. tostring(m:GetAttribute("Income")) .. tostring(m:GetAttribute("Tier")) .. tostring(m:GetAttribute("Mutation")) .. tostring(m:GetAttribute("Zone"))
	if data.labelSig == sig then
		return
	end
	data.labelSig = sig
	local ru = lang:sub(1, 2) == "ru"
	data.nameLine.Text = L.text(m:GetAttribute("Type") or "", lang)
	local earns = m:GetAttribute("Zone") == "Field"
	data.rateLine.Text = earns and ("$" .. L.compact(m:GetAttribute("Income") or 0, lang) .. (ru and "/с" or "/s")) or L.text("guardLabel", lang)
	data.rateLine.TextColor3 = earns and Color3.fromRGB(196, 255, 62) or Color3.fromRGB(120, 200, 255)
	local tier = ZC.Tiers[m:GetAttribute("Tier") or 1] or ZC.Tiers[1]
	local mutation = m:GetAttribute("Mutation")
	data.rareLine.Text = L.text(tier, lang) .. ((mutation and mutation ~= "None") and (" · " .. L.text(mutation, lang)) or "")
	data.rareLine.TextColor3 = MUTATION_COLOR[mutation] or Pal[tier] or Color3.new(1, 1, 1)
end

-- What a working monster is doing right now. Returns where it stands (offset and facing around its spot) and how
-- much it is walking; the pose is built from that in the render loop.
local function turn(from, to, k)
	local d = (to - from + math.pi) % (2 * math.pi) - math.pi
	return from + d * k
end
local function behave(m, data, now, dt, k, playerPos)
	if not data.state then
		data.x, data.z, data.yaw, data.walk, data.gait = 0, 0, 0, 0, 0
		data.state, data.until_ = "idle", now + 1 + math.random() * 4
	end
	local home = data.pivot
	local near = false
	if playerPos then
		local v = home:PointToObjectSpace(playerPos)
		near = (Vector3.new(v.X, 0, v.Z)).Magnitude < 13
		if near and data.state ~= "emote" then
			data.faceYaw = math.atan2(-(v.X - data.x), -(v.Z - data.z))
		end
	end
	local walking = 0
	if data.state == "walk" then
		local dx, dz = data.tx - data.x, data.tz - data.z
		local left = math.sqrt(dx * dx + dz * dz)
		if left < 0.08 or now > data.until_ then
			data.state, data.until_ = "idle", now + 2 + math.random() * 4
		else
			local speed = data.style.speed * math.sqrt(k)
			local step = math.min(left, speed * dt)
			data.x += dx / left * step
			data.z += dz / left * step
			data.yaw = turn(data.yaw, math.atan2(-dx, -dz), 1 - math.exp(-dt * 8))
			walking = 1
		end
	elseif data.state == "emote" then
		if now > data.until_ then
			data.state, data.emote, data.until_ = "idle", nil, now + 1.5 + math.random() * 3
		end
	else
		if near and data.faceYaw then
			data.yaw = turn(data.yaw, data.faceYaw, 1 - math.exp(-dt * 5))
			if now > (data.nextWave or 0) then
				data.nextWave = now + 7 + math.random() * 6
				data.state, data.emote, data.emoteAt, data.until_ = "emote", "wave", now, now + 1.7
			end
		end
		if data.state == "idle" and now > data.until_ then
			local roll = math.random()
			if roll < 0.6 and not near then
				local angle, reach = math.random() * math.pi * 2, 0.5 + math.random() * 0.9
				data.tx, data.tz = math.cos(angle) * reach, math.sin(angle) * reach
				data.state, data.until_ = "walk", now + 4
			elseif roll < 0.8 then
				local list = data.style.emotes
				local emote = data.outfitEmote and math.random() < 0.45 and data.outfitEmote or list[math.random(#list)]
				data.state, data.emote, data.emoteAt, data.until_ = "emote", emote, now, now + (EMOTE_TIME[emote] or 1.1)
			else
				data.until_ = now + 2 + math.random() * 3
			end
		end
	end
	data.walk += (walking - data.walk) * (1 - math.exp(-dt * 10))
	data.gait += dt * data.style.gait * data.walk
end

RunService.RenderStepped:Connect(function(dt)
	dt = math.min(dt, 0.1)
	local now = os.clock()
	local camera = workspace.CurrentCamera.CFrame.Position
	local me = Players.LocalPlayer.Character
	local playerRoot = me and me:FindFirstChild("HumanoidRootPart")
	local playerPos = playerRoot and playerRoot.Position
	local bulkParts, bulkFrames = {}, {}
	for m, data in pairs(models) do
		if not m.Parent then
			models[m] = nil
		elseif not m:GetAttribute("Carried") then
			local zone = m:GetAttribute("Zone")
			if zone ~= "Crypt" and (not data.parts or data.count ~= #m:GetChildren()) and m.PrimaryPart then
				rig(m, data)
			end
			if zone ~= "Crypt" and m.PrimaryPart and not m:GetAttribute("Held") then
				if not data.gui then
					label(m, data)
				end
				fillLabel(m, data)
				data.gui.StudsOffsetWorldSpace = Vector3.new(0, (m:GetAttribute("MonsterLabelHeight") or 3.3) * (m:GetAttribute("VisualSize") or 1) + 1.2, 0)
			end
			if zone ~= "Crypt" and data.parts and (data.pivot.Position - camera).Magnitude < ANIMATE_RANGE*math.max(1,m:GetAttribute("VisualSize") or 1) then
				local t = now + data.phase
				local body
				local alive = false
				if workspace:GetServerTimeNow()<(m:GetAttribute("PanicUntil") or 0) then
                    body=CFrame.new(math.sin(t*40)*.15,math.abs(math.sin(t*25))*.3,0)*CFrame.Angles(0,0,math.sin(t*30)*.15)
                elseif m:GetAttribute("MutantStunned") then
                    body=CFrame.Angles(0,math.sin(t)*.08,.16)
                elseif zone == "Diggers" then
					body = CFrame.new(0, math.abs(math.sin(t * 3)) * 0.25, 0) * CFrame.Angles(math.sin(t * 3) * 0.28, math.sin(t * 0.7) * 0.2, 0)
				elseif zone == "Guards" then
					body = CFrame.new(0, math.sin(t * 2) * 0.08, 0) * CFrame.Angles(0, math.sin(t * 0.6) * 0.75, math.sin(t * 2) * 0.05)
				elseif zone == "Clerk" then
					body = CFrame.Angles(0, math.sin(t * 0.5) * 0.3, 0)
				else
					alive = true
					local st = styleOf(m, data)
					behave(m, data, now, dt, m:GetScale(), playerPos)
					local w = data.walk
					local e = data.emote
					local emoteT = e and (now - data.emoteAt) or 0
					local env = e and math.sin(math.clamp(emoteT / (EMOTE_TIME[e] or 1.1), 0, 1) * math.pi) or 0 -- in, hold, out
					-- the emote's whole-body move (a positive pitch leans back, a negative one forward)
					local jump, pitch, roll, turnBy, ox, oz = 0, 0, 0, 0, 0, 0
					if e == "hop" then
						jump = math.abs(math.sin(emoteT * math.pi * 2 / 1.1)) * 0.7
					elseif e == "rear" then -- the deer rears up
						pitch, jump = 0.38 * env, 0.35 * env
					elseif e == "shiver" then
						ox, roll = math.sin(now * 9) * 0.03 * env, math.sin(now * 7) * 0.05 * env -- a slow shudder, nothing sharp
					elseif e == "glitch" then -- drifts off its spot and back, like a picture slipping
						ox, oz = math.noise(now * 1.3, data.phase) * 0.3 * env, math.noise(now * 1.3, data.phase + 5) * 0.3 * env
						turnBy = math.noise(now * 1.1, data.phase + 9) * 0.45 * env
					elseif e == "skitter" then -- a quick shuffle left and right on the spot
						turnBy = math.sin(emoteT * math.pi * 2 / 1.4) * 0.6 * env
					elseif e == "stretch" then
						pitch, jump = 0.14 * env, 0.18 * env
					elseif e == "snap" then -- the RingMaw lunges in to snap its jaws
						pitch = -0.12 * env
					elseif e == "dig" then
						pitch = -0.1 * env
					end
					local spin = e == "spin" and math.clamp(emoteT / 1.0, 0, 1) * math.pi * 2 or 0
					local twitch = st.jitter > 0 and math.noise(now * 1.5, data.phase) * st.jitter * 2 or 0
					body = CFrame.new(data.x + ox, (math.abs(math.sin(data.gait)) * st.bob * w + math.sin(t * 1.8) * 0.035 * (1 - w) + jump) * m:GetScale(), data.z + oz)
						* CFrame.Angles(0, data.yaw + spin + turnBy, 0)
						* CFrame.Angles(-(st.lean + 0.1 * w) + pitch + math.sin(t * 1.8) * 0.015 + twitch, 0, math.sin(data.gait) * 0.05 * w + math.sin(t * 0.9) * st.sway * (1 - w) + roll + twitch)
				end
				local floating=m:GetAttribute("Floating")==true
				if floating and alive then
					body=CFrame.new(data.x,(.5+math.sin(t*1.8)*.18)*m:GetScale(),data.z)
						* CFrame.Angles(-.05*data.walk,data.yaw,math.sin(t*1.1)*.025)
				end
				local hop = math.sin(math.clamp((now - data.born) / 0.6, 0, 1) * math.pi) * 3
				local base = data.pivot * CFrame.new(0, hop, 0) * body
				local aim=m:GetAttribute("GuardAim")
				if zone=="Guards" and typeof(aim)=="Vector3" and workspace:GetServerTimeNow()-(m:GetAttribute("GuardShotAt") or 0)<1 then
				 local flat=Vector3.new(aim.X,data.pivot.Position.Y,aim.Z);if (flat-data.pivot.Position).Magnitude>.1 then base=CFrame.lookAt(data.pivot.Position,flat)*CFrame.new(0,hop,0) end
				end
				local k = m:GetScale()
                local function joint(name,fallback) return m:GetAttribute("Joint_"..name) or fallback end
				local w = alive and data.walk or 0
				local gaitSwing = alive and math.sin(data.gait) or 0
				local headYaw = alive and (math.sin(t * 0.6) * 0.4 + math.sin(t * 1.7) * 0.1) * (1 - w) or math.sin(t * 1.3) * 0.12
				-- the emote's head turn (a positive pitch throws the head back)
				local e = alive and data.emote or nil
				local env = e and math.sin(math.clamp((now - data.emoteAt) / (EMOTE_TIME[e] or 1.1), 0, 1) * math.pi) or 0
				local hp, hy, hr = 0, 0, 0
				if e == "peek" then
					hy, hr = 0.5 * env, 0.6 * env
				elseif e == "siren" then
					hy = math.sin(now * 3) * 0.4 * env -- a slow sweep, as if listening
				elseif e == "rear" then
					hp = 0.3 * env
				elseif e == "glitch" then
					hr, hy = math.noise(now * 1.4, data.phase + 2) * 0.35 * env, math.noise(now * 1.2, data.phase + 4) * 0.35 * env
				elseif e == "shiver" then
					hr = math.sin(now * 6) * 0.06 * env
				elseif e == "regal" then
					hp = 0.18 * env
				elseif e == "snap" then -- the head thrusts forward and back, unhurried
					hp = -(0.12 + (0.5 + 0.5 * math.sin(now * 4)) * 0.1) * env
				end
				if alive and data.style and data.style.jitter > 0 then
					hr += math.noise(now * 1.8, data.phase + 3) * data.style.jitter * 3
				end
				local head = around(joint("Head",NECK) * k, CFrame.Angles(math.sin(t * 2.6) * 0.07 + 0.06 * w - hp, headYaw + hy, math.sin(t * 1.9) * 0.06 + hr))
				local swing = zone == "Diggers" and 0.75 or 0.12
				local jArmL, jArmR = joint("ArmL",JOINTS.ArmL), joint("ArmR",JOINTS.ArmR)
				local armL = around(jArmL * k, CFrame.Angles(math.sin(t * (zone == "Diggers" and 6 or 1.6)) * swing * (1 - w) - gaitSwing * 0.6 * w, 0, 0))
				local armR = around(jArmR * k, CFrame.Angles(math.sin(t * (zone == "Diggers" and 6 or 1.6) + 1.8) * swing * (1 - w) + gaitSwing * 0.6 * w, 0, 0))
				if zone=="Guards" then armR=around(JOINTS.ArmR*k,CFrame.Angles(-.55,0,0));armL=around(JOINTS.ArmL*k,CFrame.Angles(-.45,0,-.2)) end
				if alive and data.emote == "wave" then
					-- one arm up and out, wiggling hello
					local side = jArmR.X >= 0 and 1 or -1
					armR = around(jArmR * k, CFrame.Angles(0, 0, side * (2.45 + math.sin(now * 6) * 0.3)))
				elseif alive and data.emote == "hop" then
					local sideL, sideR = jArmL.X >= 0 and 1 or -1, jArmR.X >= 0 and 1 or -1
					armL = around(jArmL * k, CFrame.Angles(0, 0, sideL * 2.6))
					armR = around(jArmR * k, CFrame.Angles(0, 0, sideR * 2.6))
				elseif e == "rear" or e == "stretch" then
					local sideL, sideR = jArmL.X >= 0 and 1 or -1, jArmR.X >= 0 and 1 or -1
					local up, forward = (e == "stretch" and 2.9 or 2.2) * env, (e == "rear" and 0.5 or 0) * env
					armL = around(jArmL * k, CFrame.Angles(forward, 0, sideL * up))
					armR = around(jArmR * k, CFrame.Angles(forward, 0, sideR * up))
				elseif e == "dig" then -- the Miner's pickaxe comes down, again and again
					armR = around(jArmR * k, CFrame.Angles((1.4 + math.sin((now - data.emoteAt) * 5) * 1.1) * env, 0, 0))
				elseif e == "salute" then
					local sideR = jArmR.X >= 0 and 1 or -1
					armR = around(jArmR * k, CFrame.Angles(2.3 * env, 0, -sideR * 0.5 * env))
				elseif e == "regal" then -- a slow royal wave
					local sideR = jArmR.X >= 0 and 1 or -1
					armR = around(jArmR * k, CFrame.Angles(1.2 * env, 0, sideR * (0.35 + math.sin(now * 4) * 0.25) * env))
				elseif e == "shiver" then
					armL = armL * CFrame.new(0, math.sin(now * 8) * 0.03 * k * env, 0)
					armR = armR * CFrame.new(0, math.sin(now * 7) * 0.03 * k * env, 0)
				end
				if floating then
					armL=CFrame.new(.12*math.sin(t*1.4)*k,.18*math.sin(t*2+1)*k,0)*around(jArmL*k,CFrame.Angles(.08,0,.10))
					armR=CFrame.new(-.12*math.sin(t*1.4+2)*k,.18*math.sin(t*2-1)*k,0)*around(jArmR*k,CFrame.Angles(.08,0,-.10))
				end
				local legL = alive and around(joint("LegL", Vector3.new(-0.35, -0.95, 0)) * k, CFrame.Angles(gaitSwing * 0.6 * w, 0, 0)) or nil
				local legR = alive and around(joint("LegR", Vector3.new(0.35, -0.95, 0)) * k, CFrame.Angles(-gaitSwing * 0.6 * w, 0, 0)) or nil
				local wing = math.sin(t * 3.4) * 0.42
				for i, part in ipairs(data.parts) do
					local group = data.groups[i]
					local extra = group == "Head" and head or group == "ArmL" and armL or group == "ArmR" and armR
						or group == "LegL" and legL or group == "LegR" and legR
						or (group == "TendrilL" or group == "TendrilR") and around(joint(group,Vector3.zero)*k,CFrame.Angles(math.sin(t*1.8+(group=="TendrilL" and 0 or 2))*.14,0,math.sin(t*1.2)*.10))
						or group == "WingL" and around(JOINTS.WingL * k, CFrame.Angles(0, -wing, 0))
						or group == "WingR" and around(JOINTS.WingR * k, CFrame.Angles(0, wing, 0)) or nil
					table.insert(bulkParts, part)
					table.insert(bulkFrames, extra and base * extra * data.offsets[i] or base * data.offsets[i])
				end
			end
			if m:GetAttribute("Mutation") == "Rainbow" then
				local color = Color3.fromHSV(now * 0.15 % 1, 0.65, 1)
				for _, name in ipairs({ "Head", "ArmL", "ArmR" }) do
					local part = m:FindFirstChild(name)
					if part then
						part.Color = color
					end
				end
			end
			floatIncome(m, data, now)
		end
	end
	if #bulkParts > 0 then
		workspace:BulkMoveTo(bulkParts, bulkFrames, Enum.BulkMoveMode.FireCFrameChanged)
	end
end)
