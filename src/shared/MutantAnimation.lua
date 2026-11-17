-- Procedural animation for the road and farm mutants, driven by real movement so nobody skates.
-- v2 (owner, 2026-11-12: "different animations for different enemies"): every family moves its own way.
--   Deer        long-legged trot, claws up, alert head-jerks when it stands
--   Stalker     low hunched sprint with the arms swept back, slow creepy sway at rest
--   Verity      erratic stutter-steps, flailing arms, sudden twitches
--   RingMaw     four-legged gallop with a flexing spine, sniffs the ground at rest
--   Parasite    heavy waddle, wide arms, deep breathing, tendrils that never stop
--   CaveDweller crouched lope, long arms dragged in front
--   SirenHead   slow giant strides, limp dangling arms, a tilted head
--   Cultist     marching robes, hands together, a chanting rock at rest
--   Dealer      a floating head with detached hands
-- Attacks read the server's AttackName (MutantConfig): Slam/Smash overhead blows, Shot aiming, Throw a wind-up
-- over the shoulder, Leap a crouch then a stretched dive, Charge head down, Scream head back and arms flung out,
-- Spit/Curse a lean back then a lunge, Summon arms raised, Stomp a raised leg. Bosses move with more weight.
-- Signs (the rig faces -Z): a positive X angle swings a hanging limb forward, a negative one tips the body forward.
-- v3 (owner, 2026-11-15: "the monsters' animations are clunky"): every joint eases to its pose instead of jumping to
-- it (a blow still snaps), the body leans into its speeding up and braking and banks into its turns, the head turns
-- first and follows the nearest player, and a blow settles instead of stopping dead. A staggered boss (RoadService)
-- sinks to its knees with its head hanging, and shudders when the finisher lands.
local A = {}
local Players = game:GetService("Players")
local Clip = require(script.Parent.ClipPlayer)
local FINISHER = require(script.Parent.Config.RoadConfig).Boss.Finisher

-- leg/arm: swing; lean: run lean; hunch: constant forward bend; sway: side roll; bob: bounce; stride: studs a step;
-- arms: how they are carried while running; idle: what it does standing.
local GAIT = {
	Deer = { leg = 1.0, arm = 0.55, lean = 0.3, hunch = 0.1, sway = 0.05, bob = 0.24, stride = 6.5, knee = 0.3, arms = "claw", idle = "alert" },
	Stalker = { leg = 0.9, arm = 0.2, lean = 0.55, hunch = 0.3, sway = 0.03, bob = 0.12, stride = 7, knee = 0.25, arms = "trail", idle = "sway" },
	Verity = { leg = 0.95, arm = 0.9, lean = 0.22, hunch = 0.06, sway = 0.09, bob = 0.18, stride = 5.5, knee = 0.3, arms = "flail", idle = "twitch", jitter = true },
	RingMaw = { quad = true, leg = 0.85, arm = 0.85, lean = 0.08, hunch = 0, sway = 0.04, bob = 0.26, stride = 7, knee = 0.2, arms = "quad", idle = "sniff" },
	Parasite = { leg = 0.6, arm = 0.45, lean = 0.12, hunch = 0.12, sway = 0.16, bob = 0.26, stride = 5, knee = 0.15, arms = "heavy", idle = "breath" },
	CaveDweller = { leg = 0.75, arm = 0.3, lean = 0.42, hunch = 0.35, sway = 0.06, bob = 0.16, stride = 6, knee = 0.25, arms = "drag", idle = "sway" },
	SirenHead = { leg = 0.55, arm = 0.25, lean = 0.08, hunch = 0, sway = 0.1, bob = 0.12, stride = 11, knee = 0.15, arms = "hang", idle = "tilt" },
	Cultist = { leg = 0.75, arm = 0.2, lean = 0.1, hunch = 0.08, sway = 0.04, bob = 0.1, stride = 5, knee = 0.12, arms = "robe", idle = "chant" },
	-- The families of 2026-11-14 on the road (reskin of 2026-11-15). Four-legged by their rigs (front legs are the
	-- "arms"): the Longmaw, Slendrina's Mom, the Viscera and the Summoner; the Dredge has no legs and heaves along.
	Longmaw = { quad = true, leg = 0.9, arm = 0.9, lean = 0.1, hunch = 0, sway = 0.04, bob = 0.2, stride = 8, knee = 0.2, arms = "quad", idle = "sniff" },
	SpiderMom = { quad = true, leg = 0.7, arm = 0.7, lean = 0, hunch = 0, sway = 0.03, bob = 0.08, stride = 4, knee = 0.2, arms = "quad", idle = "twitch", jitter = true },
	AdaptedViscera = { quad = true, leg = 0.8, arm = 0.8, lean = 0.05, hunch = 0, sway = 0.06, bob = 0.14, stride = 6, knee = 0.2, arms = "quad", idle = "breath" },
	PrimitiveSummoner = { quad = true, leg = 0.8, arm = 0.8, lean = 0.05, hunch = 0, sway = 0.05, bob = 0.12, stride = 6, knee = 0.2, arms = "quad", idle = "twitch", jitter = true },
	Dredge = { leg = 0.5, arm = 0.5, lean = 0.1, hunch = 0.15, sway = 0.18, bob = 0.2, stride = 5, knee = 0.1, arms = "heavy", idle = "breath" },
	Mimic = { leg = 0.9, arm = 0.7, lean = 0.2, hunch = 0.05, sway = 0.06, bob = 0.2, stride = 6, knee = 0.3, arms = "claw", idle = "alert" },
	HoodedStranger = { leg = 0.7, arm = 0.25, lean = 0.12, hunch = 0.12, sway = 0.03, bob = 0.1, stride = 6, knee = 0.2, arms = "hang", idle = "tilt" },
	Slenderman = { leg = 0.6, arm = 0.15, lean = 0.05, hunch = 0, sway = 0.02, bob = 0.06, stride = 9, knee = 0.15, arms = "hang", idle = "tilt" },
	Slendrina = { leg = 0.85, arm = 0.6, lean = 0.18, hunch = 0.05, sway = 0.06, bob = 0.12, stride = 5.5, knee = 0.25, arms = "flail", idle = "twitch", jitter = true },
	Granny = { leg = 0.7, arm = 0.4, lean = 0.3, hunch = 0.25, sway = 0.05, bob = 0.12, stride = 4.5, knee = 0.25, arms = "claw", idle = "sway" },
	Grandfather = { leg = 0.7, arm = 0.35, lean = 0.25, hunch = 0.2, sway = 0.04, bob = 0.12, stride = 5, knee = 0.2, arms = "heavy", idle = "breath" },
	AssimilatedAdventurer = { leg = 0.9, arm = 0.7, lean = 0.25, hunch = 0.1, sway = 0.08, bob = 0.18, stride = 6, knee = 0.3, arms = "flail", idle = "twitch", jitter = true },
}

local function smooth(t)
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

-- A skinned monster's skeleton (MutantModel: bosses, 2026-11-15). The art packs name their bones much the same; `rest`
-- is a bone's rest rotation in the root's frame (the rig faces -Z), so a turn given in that frame - the same angles
-- the rigid limb groups take - becomes the bone's own Transform (rest inverse * turn * rest). Returns false for a
-- monster of rigid parts.
local BONES = {
	spine = { "Spine", "Chest" }, neck = { "Neck" }, head = { "Head" },
	armL = { "ArmL", "UpperArmL" }, armR = { "ArmR", "UpperArmR" }, foreL = { "ForearmL" }, foreR = { "ForearmR" },
	legL = { "LegL", "ThighL" }, legR = { "LegR", "ThighR" }, shinL = { "ShinL" }, shinR = { "ShinR" }, footL = { "FootL" }, footR = { "FootR" },
	tendrilL = { "TendrilL" }, tendrilR = { "TendrilR" },
}
local function findRig(model, root, data)
	local byName = {}
	for _, b in model:GetDescendants() do
		if b:IsA("Bone") then
			byName[b.Name] = b
		end
	end
	if next(byName) == nil then
		return false
	end
	local held = {} -- each part's rest rotation in the root's frame, from its Skin joint
	for _, j in root:GetChildren() do
		if j:IsA("Motor6D") and j.Part1 then
			held[j.Part1] = (j.C0 * j.C1:Inverse()).Rotation
		end
	end
	local rig = { all = {} }
	for key, names in BONES do
		local list = {}
		for _, name in names do
			local b = byName[name]
			local part = b and b:FindFirstAncestorWhichIsA("BasePart")
			if b and part then
				local entry = { bone = b, rest = (held[part] or CFrame.identity) * part.CFrame:ToObjectSpace(b.WorldCFrame).Rotation }
				table.insert(list, entry)
				table.insert(rig.all, entry)
			end
		end
		rig[key] = list
	end
	-- how high the hips stand over the root, for kneeling and sitting (the rigid rigs read it off the leg joint)
	local hip = rig.legL[1]
	if hip then
		data.hipY = root.CFrame:PointToObjectSpace(hip.bone.WorldPosition).Y
	end
	-- An animation clip is made for limbs that hang straight down at rest; these stand in an A-pose. `down` takes
	-- a limb's rest line to straight down, so a clip's turn lands where it means to.
	for _, pair in { { rig.armL, rig.foreL }, { rig.armR, rig.foreR }, { rig.legL, rig.shinL }, { rig.legR, rig.shinR } } do
		local upper, lower = pair[1][1], pair[2][1]
		if upper and lower then
			local line = root.CFrame:VectorToObjectSpace(lower.bone.WorldPosition - upper.bone.WorldPosition)
			local axis = line.Magnitude > 0.01 and line.Unit:Cross(-Vector3.yAxis) or Vector3.zero
			upper.down = axis.Magnitude > 1e-3 and CFrame.fromAxisAngle(axis.Unit, math.acos(math.clamp(line.Unit:Dot(-Vector3.yAxis), -1, 1))) or CFrame.identity
		end
	end
	return rig
end

function A.New(model)
	return { last = model.PrimaryPart.Position, phase = 0, speed = 0, born = os.clock(), seed = math.random() * 10, look = 0 }
end

function A.Step(model, data, dt)
	local root = model.PrimaryPart
	if not root then
		return
	end
	dt = math.clamp(dt, 1 / 240, 0.1)
	local scale = model:GetScale()
	local kind = model:GetAttribute("Kind") or model.Name
	local family = model:GetAttribute("Family") or "Deer"
	local g = GAIT[family] or GAIT.Deer
	local quadruped = g.quad == true
	local floating = model:GetAttribute("Floating") == true
	local boss = model:GetAttribute("Boss") ~= nil
	local weight = boss and 1.35 or 1
	-- Speed from actual displacement: the smoothed position MutantVisuals draws (renderPos) when there is one, so the
	-- stride doesn't pulse with the server's 10 Hz steps; sampled over a tenth of a second
	local at = data.renderPos or root.Position
	local delta = at - data.last
	data.last = at
	local distance = Vector3.new(delta.X, 0, delta.Z).Magnitude
	if distance > 12 * scale then
		distance = 0 -- a teleport or a spawn is not a stride
	end
	data.sampleDistance = (data.sampleDistance or 0) + distance
	data.sampleTime = (data.sampleTime or 0) + dt
	-- how fast it turns (the server turns it in steps, so this is sampled over the same tenth of a second)
	local facing = root.CFrame.LookVector
	local yawNow = math.atan2(-facing.X, -facing.Z)
	local turned = yawNow - (data.lastYaw or yawNow)
	data.lastYaw = yawNow
	turned = (turned + math.pi) % (2 * math.pi) - math.pi
	data.sampleTurn = (data.sampleTurn or 0) + turned
	if data.sampleTime >= 0.1 then
		local speedNow = math.min(data.sampleDistance / data.sampleTime, 90)
		data.sampledAccel = (speedNow - (data.sampledSpeed or speedNow)) / data.sampleTime
		data.sampledSpeed = speedNow
		data.sampledTurn = math.clamp(data.sampleTurn / data.sampleTime, -6, 6)
		data.sampleTime, data.sampleDistance, data.sampleTurn = 0, 0, 0
	end
	data.speed += ((data.sampledSpeed or 0) - data.speed) * (1 - math.exp(-dt * 8))
	data.accel = (data.accel or 0) + ((data.sampledAccel or 0) - (data.accel or 0)) * (1 - math.exp(-dt * 5))
	data.turn = (data.turn or 0) + ((data.sampledTurn or 0) - (data.turn or 0)) * (1 - math.exp(-dt * 6))
	-- leaning into speeding up and out of braking; banking into a turn, the head leading it
	local surge = math.clamp(data.accel / (30 * scale), -1, 1) * 0.16 / weight
	local bank = math.clamp(data.turn * 0.07, -0.22, 0.22)
	local moving = smooth(data.speed / (4 * scale))
	local now = workspace:GetServerTimeNow()
	-- A stride covers the family's step times the size; Verity stutters, capped so legs stay readable
	local rate = data.speed / (g.stride * scale * (boss and 1.15 or 1)) * math.pi
	if g.jitter then
		rate *= 1 + 0.25 * math.noise(now * 1.2, data.seed) -- a slight stutter only (2026-11-13: no jerky moves)
	end
	data.phase += dt * math.clamp(rate, 0, 22)
	local phase = data.phase
	local step = math.sin(phase)

	local state = model:GetAttribute("State")
	local age = math.max(0, now - (model:GetAttribute("StateStartedAt") or now))
	local attack = model:GetAttribute("AttackName") or (kind == "Spitter" and "Shot" or "Slam")
	local duration = model:GetAttribute("AttackDuration") or 1
	local windup = state == "Windup" and smooth(age / duration) or 0
	local strike = 0
	local dash = state == "Dashing" and math.clamp(age / math.max(duration, 0.05), 0, 1) or nil
	local settle = 0
	if state == "Recovering" and age < 0.5 then
		-- road attacks land as the wind-up ends: the blow holds for a moment, eases out, and the body settles after it
		strike = 1 - smooth((age - 0.08) / 0.42)
		settle = math.sin(math.clamp(age / 0.5, 0, 1) * math.pi) * 0.12
	elseif state == "Attacking" then
		-- farm mutants: overhead blows on a zombie, one a second
		attack = "Slam"
		local strikeAge = now - (model:GetAttribute("StrikeAt") or -100)
		windup = age < 0.24 and smooth(age / 0.24) or 0
		if strikeAge >= 0 and strikeAge < 0.45 then
			strike = math.sin(strikeAge / 0.45 * math.pi)
			windup = 0
		elseif strikeAge > 0.6 then
			windup = smooth((strikeAge - 0.6) / 0.35) -- winding up for the next blow
		end
	end
	local dashing = dash ~= nil
	local biting = state == "Biting"
	local noticed = now - (model:GetAttribute("NoticedAt") or -100)
	local hop = noticed >= 0 and noticed < 0.4 and math.sin(noticed / 0.4 * math.pi) or 0
	local hitAge = now - (model:GetAttribute("HitAt") or -100)
	local flinch = hitAge >= 0 and hitAge < 0.3 and math.sin(hitAge / 0.3 * math.pi) / weight or 0
	local stunned = now < (model:GetAttribute("StunnedUntil") or 0)
	if stunned then
		moving, windup, strike, hop = 0, 0, 0, 0
		biting, dashing, dash = false, false, nil
	end
	-- A staggered boss (RoadService, 2026-11-15): down on its knees until it gets up or is finished. `kneel` eases it
	-- down, `jolt` is the finisher's blow landing (FinisherAt + Impact) and `yank` the shovel coming out.
	local staggered = state == "Staggered"
	-- `bowed`: someone is finishing it - it sinks lower, propped on its arms, the head offered to the blade; `jolt` is
	-- a blow landing (RoadConfig.Boss.Finisher.Hits; the one at Impact is the heaviest).
	local kneel, jolt, yank, ridden = 0, 0, 0, 0
	if staggered then
		moving, windup, strike, hop = 0, 0, 0, 0
		biting, dashing, dash = false, false, nil
		kneel = smooth(age / 0.55)
		local since = now - (model:GetAttribute("FinisherAt") or -100)
		local taking = FINISHER.Of(model) -- which finisher it is taking (its FinisherKind)
		if since >= 0 and since < taking.Seconds + 1 then
			ridden = smooth((since - taking.Walk * 0.5) / 0.6)
			for _, at in taking.Hits do
				local blow = since - at
				if blow >= 0 and blow < 0.8 then
					jolt = math.max(jolt, (at == taking.Impact and 1 or 0.7) * (1 - smooth(blow / 0.8)))
				end
			end
		end
	end
	local busy = math.max(windup, strike, dashing and 1 or 0, biting and 1 or 0)
	local idle = (1 - moving) * (1 - busy)
	local breathe = math.sin(now * 2.1 + data.seed)

	-- What the family does standing still: head, lean, roll, arm offsets
	local lookYaw, lookPitch, lookRoll, idleLean, idleRoll, idleArm, idleArmOut = 0, 0, 0, 0, 0, 0, 0
	if g.idle == "alert" then
		-- deer-like: holds still, then turns its head to a new direction (smoothly since 2026-11-13: no sharp moves)
		local slot = math.floor(now * 0.7 + data.seed)
		local target = math.noise(slot * 1.31, data.seed) * 2.2
		local ease = 1 - math.exp(-dt * 4)
		data.look += (target - data.look) * ease
		data.lookPitch = (data.lookPitch or 0) + (math.noise(slot * 0.77, data.seed + 3) * 0.3 - (data.lookPitch or 0)) * ease
		lookYaw, lookPitch = data.look, data.lookPitch
		idleArm = 0.35
	elseif g.idle == "twitch" then
		local spasm = math.max(0, math.noise(now * 1.7, data.seed * 3) - 0.2) * 3
		lookYaw = math.sin(now * 0.6 + data.seed) * 0.4 + spasm * math.sin(now * 5) * 0.2
		lookRoll = spasm * math.sin(now * 4) * 0.2 + 0.15
		idleRoll = spasm * math.sin(now * 3) * 0.06
		idleArm = spasm * math.sin(now * 4) * 0.3
	elseif g.idle == "sniff" then
		lookPitch = 0.3 + math.sin(now * 9 + data.seed) * 0.07
		lookYaw = math.sin(now * 0.8 + data.seed) * 0.5
		idleLean = -0.12
	elseif g.idle == "breath" then
		idleLean = breathe * 0.07
		lookYaw = math.sin(now * 0.4 + data.seed) * 0.4
		idleArmOut = 0.15 + breathe * 0.08
	elseif g.idle == "chant" then
		lookPitch = 0.38
		idleLean = -0.05 + math.sin(now * 1.6 + data.seed) * 0.07
		idleArm = 0.55 + math.sin(now * 1.6 + data.seed) * 0.12
	elseif g.idle == "tilt" then
		lookRoll = 0.25 + math.sin(now * 0.35 + data.seed) * 0.2
		lookYaw = math.sin(now * 0.3 + data.seed) * 0.6
		idleRoll = math.sin(now * 0.5 + data.seed) * 0.04
	else -- sway
		lookYaw = math.sin(now * 0.5 + data.seed) * 0.55 + math.sin(now * 1.3 + data.seed * 2) * 0.15
		lookRoll = math.sin(now * 0.45 + data.seed) * 0.18
		idleRoll = math.sin(now * 0.45 + data.seed) * 0.06
	end
	lookYaw *= idle
	lookPitch *= idle
	lookRoll *= idle
	-- The head follows the nearest player (checked five times a second), on top of what the family does standing, and
	-- turns into a turn before the body does.
	if now >= (data.trackAt or 0) then
		data.trackAt = now + 0.2
		local best, bestDistance = nil, 70 * scale
		for _, player in Players:GetPlayers() do
			local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local away = (hrp.Position - root.Position).Magnitude
				if away < bestDistance then
					best, bestDistance = hrp, away
				end
			end
		end
		data.trackPart = best
	end
	local trackYaw, trackPitch = 0, 0
	if data.trackPart and data.trackPart.Parent then
		local v = root.CFrame:PointToObjectSpace(data.trackPart.Position)
		if v.Z < 4 * scale then -- not someone right behind it
			trackYaw = math.clamp(math.atan2(-v.X, -v.Z), -0.9, 0.9)
			trackPitch = math.clamp(-math.atan2(v.Y, math.max(2, Vector3.new(v.X, 0, v.Z).Magnitude)), -0.35, 0.35)
		end
	end
	local follow = 1 - math.exp(-dt * 5)
	data.trackYaw = (data.trackYaw or 0) + (trackYaw - (data.trackYaw or 0)) * follow
	data.trackPitch = (data.trackPitch or 0) + (trackPitch - (data.trackPitch or 0)) * follow
	local tracking = (1 - busy) * (state == "Spawning" and 0 or 1)
	lookYaw = lookYaw * 0.4 + (data.trackYaw + math.clamp(data.turn * 0.1, -0.4, 0.4)) * tracking
	lookPitch += data.trackPitch * tracking
	-- A sleeping boss (RoadService, 2026-11-13): curled up in its bed, head down, breathing slowly
	local asleep = state == "Sleeping"
	if asleep then
		-- head down on its chest, slumped forward a little (a quadruped lies flat: no slump)
		lookYaw, lookPitch, lookRoll, idleLean, idleRoll, idleArm, idleArmOut = 0, 0.85, 0.15, quadruped and 0 or -0.3, 0, 0, 0
	end
	if staggered then
		-- the head hangs and rolls dizzily; the blow drives it down, the shovel coming out jerks it up
		lookYaw = math.sin(now * 1.3 + data.seed) * 0.25 * (1 - jolt) * (1 - 0.6 * ridden) + math.sin(now * 31) * 0.12 * jolt
		lookPitch = 0.7 * kneel + 0.35 * jolt - 0.75 * ridden * (1 - jolt) -- it lifts its face to whoever stands over it
		lookRoll = math.sin(now * 0.9 + data.seed) * 0.18 * (1 - jolt) + math.sin(now * 38) * 0.05 * jolt
		idleLean, idleRoll, idleArm, idleArmOut = 0, 0, 0, 0
	end

	-- Per-attack body motion: crouches, dives, lean-backs
	local crouch, rise, leanAdd, yawAdd, rollAdd = 0, 0, 0, 0, 0
	if attack == "Leap" then
		crouch = windup * 0.7
		leanAdd -= windup * 0.3
		if dashing then
			rise = math.sin(dash * math.pi) * 1.8
			leanAdd -= 0.6
		end
	elseif attack == "Charge" then
		crouch = windup * 0.35
		leanAdd -= windup * 0.45 + (dashing and 0.55 or 0)
		rollAdd += windup * math.sin(now * 18) * 0.05 -- pawing the ground
	elseif attack == "Scream" then
		leanAdd += 0.4 * windup - 0.3 * strike
		rollAdd += strike * math.sin(now * 10) * 0.05
	elseif attack == "Spit" or attack == "Curse" then
		leanAdd += 0.35 * windup - 0.55 * strike
	elseif attack == "Summon" then
		leanAdd += 0.3 * windup - 0.35 * strike
		rollAdd += windup * math.sin(now * 6) * 0.06
	elseif attack == "Throw" then
		yawAdd += 0.55 * windup - 0.75 * strike
		leanAdd += 0.15 * windup - 0.35 * strike
	elseif attack == "Stomp" then
		rollAdd += -0.12 * windup + 0.06 * strike
		leanAdd += 0.1 * windup - 0.2 * strike
	elseif attack == "Shot" or attack == "Buckshot" then
		leanAdd += 0.05 * windup + 0.15 * strike -- the kick of the shot
	else -- Slam, Smash: lean back to wind up, throw forward into the blow
		crouch = windup * 0.25
		leanAdd += 0.32 * windup - 0.5 * strike
	end

	-- Whole body (legs too): bob twice per stride, a hop when it spots you, crouch before an attack
	local bob = (math.abs(step) * g.bob * weight * moving + breathe * 0.03 * idle + hop * 0.7 - crouch + rise) * scale
	local body = CFrame.new(0, bob, (0.25 * flinch - 0.45 * strike) * scale)
		* CFrame.Angles(0, step * 0.1 * moving + yawAdd, step * g.sway * moving + idleRoll + rollAdd + bank * moving)
	if quadruped then
		-- a gallop flexes the spine: the body pitches with the stride
		body = body * CFrame.Angles(math.sin(phase * 2) * 0.08 * moving, 0, 0)
	end
	if state == "Spawning" then
		local emerge = smooth(age / (boss and 1.4 or 0.9))
		body = CFrame.new(0, -3 * scale * (1 - emerge) ^ 2, 0) * body * CFrame.Angles(-(1 - emerge) * 0.5, 0, 0)
	end
	if stunned then
		body = body * CFrame.Angles(math.sin(now * 4) * 0.1, 0, math.sin(now * 6) * 0.16)
	end
	if asleep then
		-- A sleeping boss (owner, 2026-11-13: "a real sleep, not just turned on its side"): a biped sits down on the
		-- floor with its legs out in front; a quadruped lies on its belly, front legs forward and hind legs back. The
		-- root stands RootHeight (6) above the floor, the hips data.hipY below the root; a slow breath lifts the body.
		if not data.hipY then
			for _, j in root:GetChildren() do
				if j:IsA("Motor6D") and (j:GetAttribute("PoseGroup") or j.Name) == "LegL" then
					data.hipY = j.C0.Position.Y
				end
			end
			data.hipY = data.hipY or -2.5 * scale
		end
		local hips = math.max(0, 6 * scale + data.hipY)
		local breath = (math.sin(now * 1.1 + data.seed) * 0.5 + 0.5) * 0.08 * scale
		if floating then
			body = CFrame.new(0, -0.6 * scale, 0)
		elseif quadruped then
			body = CFrame.new(0, -hips * 0.8 + breath, 0)
		else
			body = CFrame.new(0, -(hips - 0.45 * scale) + breath, 0)
		end
	end
	if staggered then
		-- down on its knees (a quadruped onto its belly), swaying; it shudders under the blow
		if not data.hipY then
			for _, j in root:GetChildren() do
				if j:IsA("Motor6D") and (j:GetAttribute("PoseGroup") or j.Name) == "LegL" then
					data.hipY = j.C0.Position.Y
				end
			end
			data.hipY = data.hipY or -2.5 * scale
		end
		local hips = math.max(0, 6 * scale + data.hipY)
		local drop = floating and 0.5 * scale or quadruped and hips * 0.62 or hips * 0.46
		local bounce = math.sin(math.clamp(age / 0.55, 0, 1) * math.pi) * 0.12 * scale -- the knees hitting the floor
		body = CFrame.new(0, -(drop + 0.3 * scale * jolt + 0.9 * scale * ridden) * kneel + bounce + math.sin(now * 46) * 0.06 * scale * jolt, (0.5 * jolt) * scale)
			* CFrame.Angles(0, math.sin(now * 0.8 + data.seed) * 0.05 * (1 - ridden), math.sin(now * 1.1 + data.seed) * 0.06 * (1 - jolt) + math.sin(now * 37) * 0.04 * jolt)
	end
	-- Upper body only: hunch, lean into the run, the attack's lean, rock back when hit
	local lean = -g.hunch * (0.6 + 0.4 * moving) - g.lean * moving + leanAdd + 0.35 * flinch + breathe * 0.02 * idle + idleLean * idle - surge * moving - settle
	if staggered then
		lean = quadruped and 0 or -(0.55 * kneel + 0.6 * ridden - 0.25 * jolt) + breathe * 0.04
	end
	if biting then
		lean -= 0.25 + math.sin(now * 14) * 0.08
	end
	local upper = body * CFrame.Angles(lean, 0, 0)

	local function armPose(sign)
		-- running: each family carries its arms its own way
		local swing = -step * g.arm * moving * sign
		local pose
		if g.arms == "trail" then
			pose = CFrame.Angles(-1.1 * moving + swing * 0.3 + math.sin(now * 13 + sign) * 0.05 * moving, 0, -sign * (0.15 + 0.2 * moving))
		elseif g.arms == "flail" then
			pose = CFrame.Angles(swing + math.sin(now * 9 + sign * 2) * 0.5 * moving, math.sin(now * 7 + sign) * 0.3 * moving, -sign * (0.2 + 0.35 * moving))
		elseif g.arms == "heavy" then
			pose = CFrame.Angles(swing * 0.8 + 0.2 * moving, 0, -sign * (0.35 + 0.15 * moving))
		elseif g.arms == "drag" then
			pose = CFrame.Angles(0.55 + swing * 0.5 + 0.15 * moving, 0, -sign * 0.08)
		elseif g.arms == "hang" then
			pose = CFrame.Angles(swing * 0.6 + math.sin(now * 1.1 + sign) * 0.08, 0, -sign * (0.05 + math.sin(now * 0.9 + sign) * 0.04))
		elseif g.arms == "robe" then
			pose = CFrame.Angles(0.6 + swing * 0.2, 0, sign * 0.25) -- hands together in front
		elseif g.arms == "quad" then
			-- front legs: the pair lands just after the hind pair
			pose = CFrame.Angles(-math.sin(phase + 1.2 + (sign > 0 and 0.35 or 0)) * g.arm * moving, 0, 0)
		else -- claw: arms up and forward, pumping
			pose = CFrame.Angles(swing + 0.35 * moving, 0, -sign * (0.1 + 0.12 * moving))
		end
		if not quadruped then
			-- standing: arms hang and sway, plus the idle's own gesture
			pose = pose * CFrame.Angles(math.sin(now * 1.7 + data.seed + sign) * 0.07 * idle + idleArm * idle, 0, -sign * idleArmOut * idle)
		end
		if kind == "Spitter" and not quadruped then
			-- the hunter keeps its rifle up at the ready while it runs
			pose = pose:Lerp(CFrame.Angles(sign < 0 and 1.2 or 0.9, 0, sign < 0 and 0.05 or 0.35), 0.6 * moving)
		end
		-- the attack
		if attack == "Shot" or attack == "Buckshot" then
			local aim = math.max(windup, strike)
			if sign < 0 then
				pose = pose:Lerp(CFrame.Angles(1.55 + strike * 0.3, 0, 0.05), aim)
			else
				pose = pose:Lerp(CFrame.Angles(1.1, 0, 0.35), aim * 0.7) -- the other hand steadies it
			end
		elseif attack == "Throw" then
			if sign < 0 then
				pose = pose:Lerp(CFrame.Angles(2.6, 0, -0.4), windup)
				pose = pose:Lerp(CFrame.Angles(0.9, 0, 0.1), strike)
			else
				pose = pose:Lerp(CFrame.Angles(0.7, 0, 0.3), math.max(windup, strike))
			end
		elseif attack == "Leap" then
			pose = pose:Lerp(CFrame.Angles(-0.9, 0, -sign * 0.3), windup)
			if dashing then
				pose = pose:Lerp(CFrame.Angles(1.7, 0, -sign * 0.35), 1)
			end
		elseif attack == "Charge" then
			pose = pose:Lerp(CFrame.Angles(-0.5, 0, -sign * 0.2), windup)
			if dashing then
				pose = CFrame.Angles(-step * 1.1 * sign - 0.2, 0, -sign * 0.25)
			end
		elseif attack == "Scream" then
			pose = pose:Lerp(CFrame.Angles(0.4, 0, -sign * 1.25), windup)
			pose = pose:Lerp(CFrame.Angles(0.6 + math.sin(now * 35 + sign) * 0.15, 0, -sign * 1.5), strike)
		elseif attack == "Spit" or attack == "Curse" then
			pose = pose:Lerp(CFrame.Angles(-0.35, 0, -sign * 0.5), windup)
			pose = pose:Lerp(CFrame.Angles(0.9, 0, -sign * 0.25), strike)
		elseif attack == "Summon" then
			pose = pose:Lerp(CFrame.Angles(2.9 + math.sin(now * 8 + sign) * 0.1, 0, -sign * 0.55), windup)
			pose = pose:Lerp(CFrame.Angles(1, 0, -sign * 0.3), strike)
		elseif attack == "Stomp" then
			pose = pose:Lerp(CFrame.Angles(0.3, 0, -sign * 0.7), math.max(windup, strike))
		elseif windup > 0 or strike > 0 then
			-- Slam / Smash: both arms up over the head, then slammed down in front
			pose = pose:Lerp(CFrame.Angles(2.75, 0, -sign * 0.25), windup)
			pose = pose:Lerp(CFrame.Angles(0.7, 0, -sign * 0.12), strike)
		end
		if biting then
			if family == "Stalker" or family == "CaveDweller" then
				-- raking claw swipes, one arm after the other
				local swipe = math.sin(now * 12 + sign * 1.6)
				pose = CFrame.Angles(1.2 + swipe * 0.5, swipe * 0.6 * sign, -sign * 0.3)
			elseif not quadruped then
				pose = CFrame.Angles(1.35 + math.sin(now * 14 + sign * 1.6) * 0.45, 0, -sign * 0.15)
			end
		end
		if flinch > 0 then
			pose = pose * CFrame.Angles(-0.45 * flinch, 0, -sign * 0.45 * flinch)
		end
		if asleep then -- resting: on its thighs while it sits, stretched forward when it lies
			pose = quadruped and CFrame.Angles(1.25, 0, -sign * 0.15) or CFrame.Angles(0.6, 0, -sign * 0.15)
		end
		if stunned then
			pose = CFrame.Angles(0.2 + math.sin(now * 5 + sign) * 0.35, 0, -sign * (0.55 + math.sin(now * 3) * 0.2))
		end
		if staggered then -- hanging limp (a quadruped's front legs splayed out), flung out by the blow
			local limp = quadruped and CFrame.Angles(1.1, 0, -sign * 0.35) or CFrame.Angles(0.45 + math.sin(now * 1.4 + sign) * 0.06, 0, -sign * 0.12)
			-- propped on them in front of it while it is finished, flung out by each blow
			pose = pose:Lerp(limp, kneel) * CFrame.Angles(0.9 * ridden * (1 - jolt) - 0.5 * jolt, 0, -sign * (0.25 * ridden + 0.6 * jolt))
		end
		return pose
	end

	local function legPose(sign)
		local pose
		if quadruped then
			-- hind legs drive the gallop
			pose = CFrame.Angles(math.sin(phase + (sign > 0 and 0.35 or 0)) * g.leg * moving, 0, 0)
		else
			local swing = step * sign
			-- the swinging leg lifts a bit so the foot clears the floor
			local lift = math.max(0, math.cos(phase) * sign) * g.knee * moving * scale
			pose = CFrame.new(0, lift, 0) * CFrame.Angles(swing * g.leg * moving, 0, 0)
		end
		if attack == "Leap" then
			pose = pose * CFrame.Angles(0.35 * windup, 0, -sign * 0.1 * windup)
			if dashing then
				pose = CFrame.Angles(-0.8 + sign * 0.15, 0, 0) -- stretched out behind
			end
		elseif attack == "Stomp" and sign < 0 then
			pose = pose:Lerp(CFrame.new(0, 0.6 * scale, 0) * CFrame.Angles(1.25, 0, 0), windup)
			pose = pose:Lerp(CFrame.Angles(-0.1, 0, 0), strike)
		elseif windup > 0 then
			pose = pose * CFrame.Angles(0.3 * windup * sign, 0, -sign * 0.08 * windup) -- feet apart, braced
		end
		if asleep then -- out in front while it sits, stretched back while it lies
			pose = quadruped and CFrame.Angles(-1.25, 0, sign * 0.1) or CFrame.Angles(1.45, 0, -sign * 0.12)
		end
		if stunned then
			pose = CFrame.Angles(math.sin(now * 5 + sign) * 0.15, 0, -sign * 0.12)
		end
		if staggered then -- folded back under it: on its knees (a quadruped's hind legs stretched back)
			pose = pose:Lerp(quadruped and CFrame.Angles(-1.15, 0, sign * 0.12) or CFrame.Angles(-1.0, 0, sign * 0.1), kneel)
		end
		return pose
	end

	local function headPose()
		local nod = math.sin(now * 2.1 + data.seed) * 0.04 * idle + 0.12 * moving - lean * 0.4 + lookPitch
		local pose = CFrame.Angles(nod - 0.35 * windup + 0.3 * strike + 0.2 * flinch + 0.2 * hop, lookYaw + step * 0.06 * moving, lookRoll)
		if attack == "Charge" then
			pose = pose * CFrame.Angles(0.55 * math.max(windup, dashing and 1 or 0), 0, 0) -- head down, horns first
		elseif attack == "Scream" then
			pose = CFrame.Angles(-0.7 * windup + 0.25 * strike, math.sin(now * 9) * 0.1 * strike, math.sin(now * 8) * 0.06 * strike)
		elseif attack == "Spit" or attack == "Curse" then
			pose = CFrame.Angles(-0.45 * windup + 0.55 * strike, 0, 0)
		elseif attack == "Summon" then
			pose = CFrame.Angles(-0.5 * windup + 0.3 * strike, 0, math.sin(now * 6) * 0.1 * windup)
		end
		if quadruped and moving > 0.1 then
			pose = pose * CFrame.Angles(math.sin(phase * 2 + 0.6) * 0.12 * moving, 0, 0)
		end
		if biting then
			pose = quadruped and CFrame.Angles(0.45 + math.sin(now * 8) * 0.2, 0, 0) or CFrame.Angles(0.25 + math.sin(now * 8) * 0.15, 0, 0)
		end
		if stunned then
			pose = CFrame.Angles(0.25, math.sin(now * 3) * 0.5, math.sin(now * 4) * 0.2)
		end
		return pose
	end

	-- A skinned monster walks, stands and claws by the pack's zombie clips (ClipPlayer, 2026-11-15), blended over the
	-- coded poses: the walk keeps step with the ground through the same stride phase, and the coded poses take over
	-- for an attack's wind-up and blow, a leap, kneeling and sleeping.
	local rig = data.rig
	if rig == nil then
		rig = findRig(model, root, data)
		data.rig = rig
	end
	local clipWeight, clipPose = 0, nil
	if rig and not floating then
		-- (not a four-legged one: the clips are a two-legged body's)
		clipWeight = (1 - math.max(windup, strike, dashing and 1 or 0, kneel, hop)) * ((asleep or state == "Spawning" or quadruped) and 0 or 1)
		local walk, stand, claw = Clip.Get("ZombieWalk"), Clip.Get("ZombieIdle"), Clip.Get("ZombieScratch")
		if clipWeight > 0.01 and walk and stand and claw then
			clipPose = function(part)
				if biting then
					return Clip.Pose(claw, now + data.seed, part, true)
				end
				local pose = Clip.Pose(stand, now + data.seed, part, true)
				if moving > 0.01 then
					pose = pose:Lerp(Clip.Pose(walk, phase / (2 * math.pi) * walk.Length, part, true), moving)
				end
				return pose
			end
		end
	end
	local head = headPose()
	for _, j in root:GetChildren() do
		if j:IsA("Motor6D") then
			local name = j:GetAttribute("PoseGroup") or j.Name
			local pose = CFrame.identity
			local frame = upper
			if name == "ArmL" or name == "ArmR" then
				pose = armPose(name == "ArmL" and 1 or -1)
				if quadruped then
					frame = body
				end
			elseif name == "LegL" or name == "LegR" then
				pose = legPose(name == "LegL" and 1 or -1)
				frame = body
			elseif name == "Legs" then
				pose = CFrame.Angles(-step * 0.7 * moving, 0, 0)
				frame = body
			elseif name == "Head" or name == "EyesGlow" or name == "ParasiteHead" then
				pose = head
				if name == "ParasiteHead" then
					pose = pose * CFrame.new(0, math.sin(now * 4 + data.seed) * 0.12 * scale, 0)
				end
			elseif name == "TendrilL" or name == "TendrilR" then
				local sign = name == "TendrilL" and 1 or -1
				local agitated = 1 + windup * 2 + moving + strike
				pose = CFrame.Angles(
					math.sin(now * 4.5 * agitated + sign) * 0.4 + windup * 0.8,
					math.sin(now * 3.1 + sign) * 0.3,
					sign * (0.15 + math.sin(now * 5.5 + sign) * 0.3)
				)
			elseif name == "Skin" then
				frame = body -- a skinned monster's whole mesh: the body's own movement, the bones do the rest (below)
				if clipPose then
					-- and the clip's hips, sized from R15's two-stud hip height to this monster's
					local hips = clipPose("LowerTorso")
					local size = math.max(0, 6 * scale + (data.hipY or -2.5 * scale)) / 2
					frame = body * CFrame.identity:Lerp(CFrame.new(hips.Position * size) * hips.Rotation, clipWeight)
				end
			elseif name == "Tail" then
				pose = CFrame.Angles(0, math.sin(phase + 1) * 0.4 * moving + math.sin(now * 2) * 0.1, 0)
				frame = body
			end
			if floating then
				-- The Dealer has no torso or legs. Its head and detached hands hover independently.
				local dashOffset = dashing and -1.2 or 0
				frame = CFrame.new(0, (0.5 + math.sin(now * 1.8 + data.seed) * 0.18 + hop * 0.25 - 0.3 * windup * (attack == "Smash" and -1 or 0)) * scale, (-0.2 * moving - 0.6 * strike + 0.25 * flinch + dashOffset) * scale)
					* CFrame.Angles(-0.05 * moving + 0.1 * flinch, 0, math.sin(now * 1.1 + data.seed) * 0.025)
				if name == "Head" then
					pose = CFrame.Angles(-0.12 * windup + 0.22 * strike, lookYaw * 0.4, math.sin(now * 0.9) * 0.025)
				elseif name == "ArmL" or name == "ArmR" then
					local sign = name == "ArmL" and 1 or -1
					local float = math.sin(now * 2 + sign) * 0.18 * scale
					if attack == "Smash" then
						-- both hands rise high, then crash down in front
						pose = CFrame.new(0, (float + 2.2 * windup - 1 * strike) * scale, (-0.6 * windup - 1.6 * strike) * scale)
							* CFrame.Angles(0.9 * windup + 1.2 * strike, 0, sign * 0.12)
					elseif attack == "Buckshot" then
						-- the hands come together in front and kick back with the shot
						pose = CFrame.new(-sign * 1.1 * math.max(windup, strike) * scale, float, (-1.2 * windup + 0.6 * strike) * scale)
							* CFrame.Angles(0.3 * windup - 0.5 * strike, 0, sign * 0.12)
					else
						pose = CFrame.new(sign * math.sin(now * 1.4 + sign) * 0.12 * scale, float, (-0.8 * strike + 0.25 * windup) * scale)
							* CFrame.Angles(0.25 * moving + 0.7 * strike - 0.2 * windup, 0, sign * 0.12)
					end
				else
					pose = CFrame.identity
				end
				if stunned then
					frame *= CFrame.Angles(0, math.sin(now * 3) * 0.06, math.sin(now * 5) * 0.08)
				end
				if asleep then -- sunk low, the head drooping, the hands resting on the floor
					frame = CFrame.new(0, (-0.7 + math.sin(now * 1.1 + data.seed) * 0.04) * scale, 0)
					if name == "Head" then
						pose = CFrame.Angles(0.5, 0, 0.1)
					elseif name == "ArmL" or name == "ArmR" then
						pose = CFrame.new(0, -1.1 * scale, -0.4 * scale)
					end
				end
			end
			-- body movement in root space, moved into the joint's own pivot frame, then the joint's pose; eased to
			-- rather than set (v3): the legs keep up with the stride, the head lags a little, a blow snaps
			local target = j.C0:Inverse() * frame * j.C0 * pose
			local rate = (name == "LegL" or name == "LegR" or name == "Legs") and 30 or (name == "Head" or name == "EyesGlow" or name == "ParasiteHead") and 13 or 20
			if strike > 0.25 or dashing or jolt > 0.5 then
				rate = 45
			end
			local eased = data.joints and data.joints[j]
			eased = eased and eased:Lerp(target, 1 - math.exp(-dt * rate)) or target
			data.joints = data.joints or {}
			data.joints[j] = eased
			j.Transform = eased
		end
	end
	-- A skinned monster: the same poses, on bones. The spine carries the lean, the neck and head the head's turn, the
	-- upper arm and thigh the limb's swing; elbows and knees bend with it, so nothing swings as one stiff piece. On
	-- its knees it really kneels - thighs down, shins folded back - and asleep it sits with its knees up.
	if rig then
		local ease = 1 - math.exp(-dt * ((strike > 0.25 or dashing or jolt > 0.5) and 45 or 20))
		local function turn(list, rotation)
			for _, entry in list do
				local target = entry.rest:Inverse() * rotation * entry.rest
				entry.eased = entry.eased and entry.eased:Lerp(target, ease) or target
				entry.bone.Transform = entry.eased
			end
		end
		-- the coded pose, or the clip's for that joint as far as the clips have the body just now
		local function mix(coded, part, upper)
			if not clipPose then
				return coded
			end
			local clip = clipPose(part).Rotation
			if upper and upper.down then
				clip = clip * upper.down
			end
			return coded:Lerp(clip, clipWeight)
		end
		local spine = math.max(1, #rig.spine)
		turn(rig.spine, CFrame.identity:Lerp(mix(CFrame.Angles(lean, 0, 0), "UpperTorso"), 1 / spine))
		local look = mix(head, "Head")
		if #rig.neck > 0 then
			turn(rig.neck, CFrame.identity:Lerp(look, 0.4))
			turn(rig.head, CFrame.identity:Lerp(look, 0.6))
		else
			turn(rig.head, look)
		end
		for _, side in { { 1, "Left", rig.armL, rig.foreL, rig.legL, rig.shinL, rig.footL }, { -1, "Right", rig.armR, rig.foreR, rig.legR, rig.shinR, rig.footR } } do
			local sign, name = side[1], side[2]
			local arm = armPose(sign).Rotation
			local swing = arm:ToEulerAnglesXYZ()
			turn(side[3], mix(arm, name .. "UpperArm", side[3][1]))
			-- A four-legged one (the RingMaw) stands on its front legs: no bend in them at rest; and lying - asleep or
			-- staggered - its legs are laid out straight, the way the coded poses put them, not knelt on.
			local lying = quadruped and (staggered or asleep)
			turn(side[4], mix(CFrame.Angles(lying and 0 or math.clamp((quadruped and 0 or 0.2) + 0.5 * math.abs(swing), 0, 1.4), 0, 0), name .. "LowerArm"))
			local thigh, knee, foot
			if staggered and not quadruped then
				thigh, knee, foot = CFrame.Angles(0.45 * kneel, 0, -sign * 0.08 * kneel), 1.9 * kneel, 0.9 * kneel
			elseif asleep and not quadruped then
				thigh, knee, foot = CFrame.Angles(1.45, 0, -sign * 0.12), 0.9, -0.3
			else
				thigh = legPose(sign).Rotation
				local stride = thigh:ToEulerAnglesXYZ()
				knee = lying and 0 or math.clamp(0.7 * math.abs(stride) + 0.25 * crouch, 0, 1.5)
				foot = (knee - stride) * 0.6
			end
			turn(side[5], mix(thigh, name .. "UpperLeg", side[5][1]))
			turn(side[6], mix(CFrame.Angles(-knee, 0, 0), name .. "LowerLeg"))
			turn(side[7], mix(CFrame.Angles(foot, 0, 0), name .. "Foot"))
		end
		-- the Parasite's tendrils whip about, as its rigid ones did
		for sign, list in { [1] = rig.tendrilL, [-1] = rig.tendrilR } do
			if #list > 0 then
				local agitated = 1 + windup * 2 + moving + strike
				turn(list, CFrame.Angles(math.sin(now * 4.5 * agitated + sign) * 0.4 + windup * 0.8, math.sin(now * 3.1 + sign) * 0.3, sign * (0.15 + math.sin(now * 5.5 + sign) * 0.3)))
			end
		end
	end
	data.moving = moving
end

return A
