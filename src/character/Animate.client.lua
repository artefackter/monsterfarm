-- Replaces Roblox's default Animate. Same kind of Roblox-made clips (AnimationConfig), but:
-- the walk/run blend follows our speeds, slow mode really walks, the legs never spin into a blur
-- at high speed, and the treadmill plays the run in place. Arms for weapons, digging and the shovel
-- are layered on top by CombatPose after the Animator.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local C = require(Shared:WaitForChild("Config"):WaitForChild("AnimationConfig"))
local RoadConfig = require(Shared.Config:WaitForChild("RoadConfig"))

local Character = script.Parent
local Humanoid = Character:WaitForChild("Humanoid")
local Animator = Humanoid:WaitForChild("Animator")
local Root = Character:WaitForChild("HumanoidRootPart")
local player = Players:GetPlayerFromCharacter(Character)
local State = Enum.HumanoidStateType

-- The emote menu and "/e" chat commands look for this.
local playEmote = script:FindFirstChild("PlayEmote") or Instance.new("BindableFunction")
playEmote.Name = "PlayEmote"
playEmote.Parent = script

for _, track in Animator:GetPlayingAnimationTracks() do
	track:Stop(0)
end

local function load(id, looped, priority)
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://" .. id
	local track = Animator:LoadAnimation(animation)
	track.Looped = looped
	track.Priority = priority or Enum.AnimationPriority.Core
	return track
end

local tracks = {
	walk = load(C.Walk.Id, true),
	run = load(C.Run.Id, true),
	jump = load(C.Jump, false),
	fall = load(C.Fall, true),
	climb = load(C.Climb, true),
	swim = load(C.Swim, true),
	swimidle = load(C.SwimIdle, true),
	sit = load(C.Sit, true),
}
local idles, idleTotal = {}, 0
for i, entry in C.Idle do
	idles[i] = { track = load(entry.Id, true), weight = entry.Weight }
	idleTotal += entry.Weight
end
local function rollIdle()
	local roll = math.random() * idleTotal
	for _, entry in idles do
		roll -= entry.weight
		if roll <= 0 then
			return entry.track
		end
	end
	return idles[1].track
end
tracks.idle = rollIdle()

local weights = {}
local function setWeight(name, track, weight)
	if weight > 0.002 then
		if not track.IsPlaying then
			track:Play(0, 0.0001)
		end
		track:AdjustWeight(weight, 0)
	elseif track.IsPlaying then
		if name == "jump" then
			track:AdjustWeight(0.0001, 0) -- let the one-shot clip run out quietly
		else
			track:Stop(0)
		end
	end
	weights[name] = weight
end

local jumpStarted = -math.huge
Humanoid.Jumping:Connect(function(active)
	if active then
		jumpStarted = os.clock()
		tracks.jump:Stop(0)
		tracks.jump:Play(0.05)
	end
end)

local emoteTrack
local function stopEmote()
	if emoteTrack then
		emoteTrack:Stop(0.2)
		emoteTrack = nil
	end
end
local standing = true
playEmote.OnInvoke = function(emote)
	if not standing then
		return false
	end
	local animation
	if typeof(emote) == "Instance" and emote:IsA("Animation") then
		animation = emote
	elseif type(emote) == "string" and C.Emotes[emote] then
		animation = Instance.new("Animation")
		animation.AnimationId = "rbxassetid://" .. C.Emotes[emote]
	else
		return false
	end
	stopEmote()
	emoteTrack = Animator:LoadAnimation(animation)
	emoteTrack.Priority = Enum.AnimationPriority.Action
	emoteTrack:Play(0.1)
	return true, emoteTrack
end

local function treadmillWarp()
	local rate = player and player:GetAttribute("TreadmillRate") or 0
	local level = 1
	for i, entry in RoadConfig.Treadmill do
		if entry.Rate == rate then
			level = i
		end
	end
	return C.TreadmillWarp.Base + (level - 1) * C.TreadmillWarp.PerLevel
end

local smooth = {}
local wasMoving = false
local connection
connection = RunService.Stepped:Connect(function(_, dt)
	if not Character.Parent or not Humanoid.Parent then
		connection:Disconnect()
		return
	end
	dt = math.min(dt, 0.1)
	local state = Humanoid:GetState()
	local target = {}
	local velocity = Root.AssemblyLinearVelocity
	local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	local training = player and player:GetAttribute("Training") == true
	local slow = player and player:GetAttribute("SlowMode") == true
	local moving = Humanoid.MoveDirection.Magnitude > 0.05 and speed > 0.75

	if state == State.Dead or Humanoid.Health <= 0 then
		for name, track in tracks do
			setWeight(name, track, 0)
		end
		stopEmote()
		return
	elseif Humanoid.Sit or state == State.Seated then
		target.sit = 1
	elseif state == State.Swimming then
		if speed > 1 then
			target.swim = 1
			tracks.swim:AdjustSpeed(math.clamp(speed / 10, 0.6, 1.6))
		else
			target.swimidle = 1
		end
	elseif state == State.Climbing then
		target.climb = 1
		tracks.climb:AdjustSpeed(math.clamp(math.abs(velocity.Y) / 5, 0.2, 1.6))
	elseif (state == State.Freefall or state == State.Jumping) and not training then
		local jumping = os.clock() - jumpStarted < C.JumpTime
		target.jump = jumping and 1 or 0
		target.fall = jumping and 0 or 1
	else
		local move = (training or moving) and 1 or 0
		local run = training and 1 or (not slow and math.clamp((speed - C.RunFrom) / (C.RunFull - C.RunFrom), 0, 1) or 0)
		target.idle = 1 - move
		target.walk = move * (1 - run)
		target.run = move * run
		-- Facing a target while moving away from it: the clips play backwards, a backpedal instead of a moonwalk.
		local relative = Root.CFrame:VectorToObjectSpace(Humanoid.MoveDirection)
		local direction = (moving and not training and relative.Z > 0.35) and -1 or 1
		tracks.walk:AdjustSpeed(direction * math.clamp(speed / C.Walk.Natural, C.WalkWarp[1], C.WalkWarp[2]))
		tracks.run:AdjustSpeed(training and treadmillWarp() or direction * math.clamp(speed / C.Run.Natural, C.RunWarp[1], C.RunWarp[2]))
	end

	-- A new idle variant each time the character comes to rest.
	if moving ~= wasMoving then
		wasMoving = moving
		if not moving and #idles > 1 then
			local old = tracks.idle
			local new = rollIdle()
			if new ~= old then
				setWeight("idle", old, 0)
				tracks.idle = new
				smooth.idle = 0
			end
		end
	end

	standing = (target.idle or 0) > 0.5
	if emoteTrack and (not standing or moving) then
		stopEmote()
	end

	local k = 1 - math.exp(-dt * C.Blend)
	for name, track in tracks do
		local goal = target[name] or 0
		local current = smooth[name] or 0
		if name == "jump" then
			current = goal -- the jump snaps in; its clip already eases
		else
			current += (goal - current) * k
		end
		smooth[name] = current
		setWeight(name, track, current)
	end
end)
