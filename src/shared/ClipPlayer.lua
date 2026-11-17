-- Animation clips the game plays itself (owner, 2026-11-15: "let's adapt the pack's animations to our game in
-- general"). shared/Clips/<Name> holds a clip as joint transforms (art/roblox-import-v1/tools/finisher_clips.py, from
-- Quaternius' Universal Animation Library 2, CC0): a player's R15 joints take them as they are (CombatPose.PlayClip)
-- and a skinned monster's bones take the same turns (MutantAnimation). No Animation assets, nothing to publish.
--   Heavy                    a boss finisher: the four-hit combo
--   Dash, Combo              another: a rush with a cut, then four quick cuts on the spot
--   SlashA, SlashB, Reap, Chop, Overhand, Cross, Hook, HookRec, Lunge, Leap, LeapLand, Jump, Roll
--                            the pieces the melee weapons' finishers are put together from (2026-11-16;
--                            RoadConfig.Boss.Finisher.Kinds says what each is)
--   Knock, GetUp             knocked off your feet, and getting up again
--   ZombieWalk, ZombieIdle, ZombieScratch   a skinned monster's walk, stand and claw
local P = {}
local cache = {}

function P.Get(name)
	local clip = cache[name]
	if clip == nil then
		local module = script.Parent:FindFirstChild("Clips") and script.Parent.Clips:FindFirstChild(name)
		clip = module and require(module) or false
		if clip then
			clip.Index = {}
			local at = 1
			for _, part in ipairs(clip.Parts) do
				clip.Index[part] = at
				at += clip.Pos[part] and 7 or 4
			end
		end
		cache[name] = clip
	end
	return clip or nil
end

-- One joint's transform `t` seconds into the clip (looped, or held at its ends).
function P.Pose(clip, t, part, loop)
	local at = clip.Index[part]
	if not at then
		return CFrame.identity
	end
	local last = #clip.Frames
	local f = (loop and t % clip.Length or math.clamp(t, 0, clip.Length)) * clip.Rate
	local i = math.floor(f)
	local a, b = clip.Frames[math.min(i + 1, last)], clip.Frames[math.min(i + 2, last)]
	local moved = clip.Pos[part]
	local from = CFrame.new(moved and a[at + 4] or 0, moved and a[at + 5] or 0, moved and a[at + 6] or 0, a[at], a[at + 1], a[at + 2], a[at + 3])
	local to = CFrame.new(moved and b[at + 4] or 0, moved and b[at + 5] or 0, moved and b[at + 6] or 0, b[at], b[at + 1], b[at + 2], b[at + 3])
	return from:Lerp(to, f - i)
end

return P
