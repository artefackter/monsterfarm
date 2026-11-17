-- One-shot sounds on the client. Silent if a sound is missing, and a sound fired twice within
-- minGap seconds plays once, so rapid events can't stack into noise.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Sfx = {}
local lastPlayed = {}

-- scale (optional) multiplies the volume; Sfx.at gives a scale that falls off with distance from the camera.
function Sfx.at(position, fullWithin, silentAt)
	local camera = workspace.CurrentCamera
	if not camera or typeof(position) ~= "Vector3" then
		return 1
	end
	local distance = (position - camera.CFrame.Position).Magnitude
	fullWithin, silentAt = fullWithin or 20, silentAt or 140
	return math.clamp(1 - (distance - fullWithin) / (silentAt - fullWithin), 0, 1) ^ 1.5
end

function Sfx.play(name, minGap, scale)
	if scale and scale <= 0.02 then
		return
	end
	local folder = ReplicatedStorage:FindFirstChild("Sounds")
	local alias={FireM249="FireAK",FireMP5="FireM4",FireDouble="FireAWP",FirePump="FireAWP"}
	local source = folder and (folder:FindFirstChild(name) or folder:FindFirstChild(alias[name] or name))
	if not source or source.SoundId == "" then
		return
	end
	local now = os.clock()
	if now - (lastPlayed[name] or -math.huge) < (minGap or 0.05) then
		return
	end
	lastPlayed[name] = now
	local sound = source:Clone()
	sound.Volume *= (game.Players.LocalPlayer:GetAttribute("SfxVolume") or 1) * (scale or 1)
	sound.Parent = SoundService
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	sound:Play()
	game:GetService("Debris"):AddItem(sound, 15)
	return sound
end

-- The reveal jingles, one at a time (owner, 2026-11-16: "dig several graves and music starts" - every grave played
-- its own, 2.7 s or 6.1 s long, on top of the last). While one sounds, another of its rank or a lower one is not
-- started; a higher one (a rare monster's) stops it and plays instead.
local JINGLES = { Reveal = { 1, 2.7 }, RareReveal = { 2, 6.1 } }
local jingle
function Sfx.jingle(name, scale)
	local rank = (JINGLES[name] or JINGLES.Reveal)[1]
	local now = os.clock()
	if jingle and jingle.sound.Parent and now < jingle.untilAt then
		if rank <= jingle.rank then
			return
		end
		jingle.sound:Stop()
		jingle.sound:Destroy()
	end
	jingle = nil
	local sound = Sfx.play(name, 0, scale)
	if sound then
		jingle = { sound = sound, rank = rank, untilAt = now + (JINGLES[name] or JINGLES.Reveal)[2] }
	end
end

return Sfx
