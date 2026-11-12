-- Procedural animation for the road and farm mutants, driven by real movement so nobody skates.
-- Running: legs stride from the hips with a little knee lift, arms pump against them, the upper body leans
-- into the run and bobs twice per stride. Standing: breathing, arms hanging and swaying, a slow look around.
-- Attacks: a clear wind-up (arms over the head, body leaning back) and a hard follow-through. Hits make them
-- flinch, stuns make them wobble, the parasite's tendrils never stop wriggling. Each kind moves its own way.
-- Signs (the rig faces -Z): a positive X angle swings a hanging limb forward, a negative one tips the body forward.
local A = {}

-- How each kind carries itself: stride swing, arm pump, run lean, body sway, bob height.
local STYLE = {
	Imp = { leg = 0.95, arm = 0.9, lean = 0.28, sway = 0.06, bob = 0.2, reach = 0.15 },
	Spitter = { leg = 0.8, arm = 0.45, lean = 0.2, sway = 0.04, bob = 0.15, reach = 0.6 }, -- keeps the gun up
	Bubble = { leg = 0.65, arm = 0.55, lean = 0.12, sway = 0.16, bob = 0.26, reach = 0.25 }, -- heavy, lumbering
	Chief = { leg = 0.7, arm = 0.6, lean = 0.14, sway = 0.12, bob = 0.3, reach = 0.2 },
}

local function smooth(t)
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

function A.New(model)
	return { last = model.PrimaryPart.Position, phase = 0, speed = 0, born = os.clock(), seed = math.random() * 10 }
end

function A.Step(model, data, dt)
	local root = model.PrimaryPart
	if not root then
		return
	end
	dt = math.clamp(dt, 1 / 240, 0.1)
	local scale = model:GetScale()
	local kind = model:GetAttribute("Kind") or model.Name
	local style = STYLE[kind] or STYLE.Imp
 local quadruped=model:GetAttribute("Family")=="RingMaw"
 local floating=model:GetAttribute("Floating")==true
	-- Speed from actual displacement, sampled so the server's 20 Hz updates don't make it stutter
	local delta = root.Position - data.last
	data.last = root.Position
	local distance = Vector3.new(delta.X, 0, delta.Z).Magnitude
	if distance > 12 * scale then
		distance = 0 -- a teleport or a spawn is not a stride
	end
	data.sampleDistance = (data.sampleDistance or 0) + distance
	data.sampleTime = (data.sampleTime or 0) + dt
	if data.sampleTime >= 0.1 then
		data.sampledSpeed = math.min(data.sampleDistance / data.sampleTime, 90)
		data.sampleTime, data.sampleDistance = 0, 0
	end
	data.speed += ((data.sampledSpeed or 0) - data.speed) * (1 - math.exp(-dt * 8))
	local moving = smooth(data.speed / (4 * scale))
	-- A stride covers about 6 studs times the size; fast mutants take quicker steps, capped so legs stay readable
	data.phase += dt * math.clamp(data.speed / (6 * scale) * math.pi, 0, 22)
	local phase = data.phase
	local step = math.sin(phase)

	local now = workspace:GetServerTimeNow()
	local state = model:GetAttribute("State")
	local age = math.max(0, now - (model:GetAttribute("StateStartedAt") or now))
	local windup = state == "Windup" and smooth(age / (model:GetAttribute("AttackDuration") or 1)) or 0
	local strike = 0
	if state == "Recovering" and age < 0.35 then
		strike = 1 - age / 0.35 -- road attacks land as the wind-up ends
	elseif state == "Attacking" then
		local strikeAge = now - (model:GetAttribute("StrikeAt") or -100)
		windup = age < 0.24 and smooth(age / 0.24) or 0
		if strikeAge >= 0 and strikeAge < 0.45 then
			strike = math.sin(strikeAge / 0.45 * math.pi)
			windup = 0
		elseif strikeAge > 0.6 then
			windup = smooth((strikeAge - 0.6) / 0.35) -- winding up for the next blow
		end
	end
	local biting = state == "Biting"
	local noticed = now - (model:GetAttribute("NoticedAt") or -100)
	local hop = noticed >= 0 and noticed < 0.4 and math.sin(noticed / 0.4 * math.pi) or 0
	local hitAge = now - (model:GetAttribute("HitAt") or -100)
	local flinch = hitAge >= 0 and hitAge < 0.3 and math.sin(hitAge / 0.3 * math.pi) or 0
	local stunned = now < (model:GetAttribute("StunnedUntil") or 0)
	if stunned then
		moving, windup, strike, hop = 0, 0, 0, 0
		biting = false
	end
	local idle = 1 - moving
	local breathe = math.sin(now * 2.1 + data.seed)

	-- Whole body (legs too): bob twice per stride, a hop when it spots you, crouch before a slam
	local bob = (math.abs(step) * style.bob * moving + breathe * 0.03 * idle + hop * 0.7 - windup * 0.25) * scale
	local body = CFrame.new(0, bob, (0.25 * flinch - 0.45 * strike) * scale)
		* CFrame.Angles(0, step * 0.1 * moving, step * style.sway * moving)
	if state == "Spawning" then
		local emerge = smooth(age / 0.9)
		body = CFrame.new(0, -3 * scale * (1 - emerge) ^ 2, 0) * body * CFrame.Angles(-(1 - emerge) * 0.5, 0, 0)
	end
	if stunned then
		body = body * CFrame.Angles(math.sin(now * 4) * 0.1, 0, math.sin(now * 6) * 0.16)
	end
	-- Upper body only: lean into the run, lean back to wind up, throw forward into the blow, rock back when hit
	local lean = -style.lean * moving + 0.32 * windup - 0.5 * strike + 0.35 * flinch + breathe * 0.02 * idle
	if biting then
		lean -= 0.25 + math.sin(now * 14) * 0.08
	end
	local upper = body * CFrame.Angles(lean, 0, 0)
	local lookAround = (math.sin(now * 0.5 + data.seed) * 0.55 + math.sin(now * 1.3 + data.seed * 2) * 0.15) * idle

	for _, j in root:GetChildren() do
		if j:IsA("Motor6D") then
			local name = j:GetAttribute("PoseGroup") or j.Name
			local pose = CFrame.identity
			local frame = upper
			if name == "ArmL" or name == "ArmR" then
				local sign = name == "ArmL" and 1 or -1
				-- pump against the legs; reach forward a little while running; hang and sway when still
				local swing = -step * style.arm * moving * sign + style.reach * moving
				local hang = math.sin(now * 1.7 + data.seed + sign) * 0.07 * idle
				pose = quadruped and CFrame.Angles(-step*sign*.45*moving,0,0) or CFrame.Angles(swing + hang, 0, -sign * (0.1 + 0.12 * moving))
				if kind == "Spitter" and (windup > 0 or strike > 0) then
					-- the hunter raises its weapon arm and fires
					local aim = math.max(windup, strike)
					if sign < 0 then
						pose = pose:Lerp(CFrame.Angles(1.55 + strike * 0.3, 0, 0.05), aim)
					else
						pose = pose:Lerp(CFrame.Angles(1.1, 0, 0.35), aim * 0.7) -- the other hand steadies it
					end
				elseif windup > 0 or strike > 0 then
					-- both arms up over the head, then slammed down in front
					pose = pose:Lerp(CFrame.Angles(2.75, 0, -sign * 0.25), windup)
					pose = pose:Lerp(CFrame.Angles(0.7, 0, -sign * 0.12), strike)
				end
				if biting then
					pose = CFrame.Angles(1.35 + math.sin(now * 14 + sign * 1.6) * 0.45, 0, -sign * 0.15)
				end
				if flinch > 0 then
					pose = pose * CFrame.Angles(-0.45 * flinch, 0, -sign * 0.45 * flinch)
				end
				if stunned then
					pose = CFrame.Angles(0.2 + math.sin(now * 5 + sign) * 0.35, 0, -sign * (0.55 + math.sin(now * 3) * 0.2))
				end
			elseif name == "LegL" or name == "LegR" then
				local sign = name == "LegL" and 1 or -1
				local swing = step * sign
				-- the swinging leg lifts a bit so the foot clears the floor
				local lift = math.max(0, math.cos(phase) * sign) * 0.25 * moving * scale
				pose = CFrame.new(0, lift, 0) * CFrame.Angles(swing * style.leg * moving, 0, 0)
				if windup > 0 then
					pose = pose * CFrame.Angles(0.3 * windup * sign, 0, -sign * 0.08 * windup) -- feet apart, braced
				end
				if stunned then
					pose = CFrame.Angles(math.sin(now * 5 + sign) * 0.15, 0, -sign * 0.12)
				end
				frame = body
			elseif name == "Legs" then
				pose = CFrame.Angles(-step * 0.7 * moving, 0, 0)
				frame = body
			elseif name == "Head" or name == "EyesGlow" or name == "ParasiteHead" then
				local nod = math.sin(now * 2.1 + data.seed) * 0.04 * idle + 0.12 * moving - lean * 0.4
				pose = CFrame.Angles(nod - 0.35 * windup + 0.3 * strike + 0.2 * flinch + 0.2 * hop, lookAround + step * 0.06 * moving, 0)
				if biting then
					pose = CFrame.Angles(0.25 + math.sin(now * 18) * 0.2, 0, 0)
				end
				if stunned then
					pose = CFrame.Angles(0.25, math.sin(now * 3) * 0.5, math.sin(now * 4) * 0.2)
				end
				if name == "ParasiteHead" then
					pose = pose * CFrame.new(0, math.sin(now * 4 + data.seed) * 0.12 * scale, 0)
				end
			elseif name == "TendrilL" or name == "TendrilR" then
				local sign = name == "TendrilL" and 1 or -1
				local agitated = 1 + windup * 2 + moving
				pose = CFrame.Angles(
					math.sin(now * 4.5 * agitated + sign) * 0.4 + windup * 0.8,
					math.sin(now * 3.1 + sign) * 0.3,
					sign * (0.15 + math.sin(now * 5.5 + sign) * 0.3)
				)
			elseif name == "Tail" then
				pose = CFrame.Angles(0, math.sin(phase + 1) * 0.4 * moving + math.sin(now * 2) * 0.1, 0)
				frame = body
			end
			if floating then
				-- The Dealer has no torso or legs. Its head and detached hands hover independently.
				frame=CFrame.new(0,(.5+math.sin(now*1.8+data.seed)*.18+hop*.25)*scale,(-.2*moving-.6*strike+.25*flinch)*scale)
					* CFrame.Angles(-.05*moving+.10*flinch,0,math.sin(now*1.1+data.seed)*.025)
				if name=="Head" then
					pose=CFrame.Angles(-.12*windup+.22*strike,lookAround*.4,math.sin(now*.9)*.025)
				elseif name=="ArmL" or name=="ArmR" then
					local sign=name=="ArmL" and 1 or -1
					pose=CFrame.new(sign*math.sin(now*1.4+sign)*.12*scale,math.sin(now*2+sign)*.18*scale,(-.8*strike+.25*windup)*scale)
						* CFrame.Angles(.25*moving+.7*strike-.2*windup,0,sign*.12)
				else pose=CFrame.identity end
				if stunned then frame*=CFrame.Angles(0,math.sin(now*3)*.06,math.sin(now*5)*.08) end
			end
			-- body movement in root space, moved into the joint's own pivot frame, then the joint's pose
			j.Transform = j.C0:Inverse() * frame * j.C0 * pose
		end
	end
	data.moving = moving
end

return A
