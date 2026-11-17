-- The tutorial's steps after the first road grave is planted (owner, 2026-11-15): 4 take the Double barrel at the
-- gunsmith, 5 upgrade a gun at the workbench, 6 upgrade the treadmill, 7 upgrade the gate, 8 upgrade the house;
-- 9 is done. Steps 0-3 (dig, place a monster, dig on the road, plant it) move on where they happen. Each of these
-- upgrades is free once, on its own step; finishing the tutorial brings the starter cat.
local T={Done=9,Gunsmith=4,Weapon=5,Board={Treadmill=6,Fence=7,House=8}}

-- Move on from step `from` (nothing if the profile is elsewhere in the tutorial, or past it).
function T.Advance(p,d,from)
 if not d or d.tutorialDone or d.tutorialStep~=from then return end
 d.tutorialStep=from+1
 if d.tutorialStep>=T.Done then d.tutorialDone=true;require(script.Parent.PetService).Starter(p) end
 -- the boards show the next free upgrade at once, the workbench drops its "free"
 require(script.Parent.InterfaceService).Refresh(p);require(script.Parent.WeaponService).Push(p)
end
-- Is the upgrade board `key` (InterfaceService) free right now?
function T.FreeBoard(d,key)
 return d~=nil and not d.tutorialDone and T.Board[key]~=nil and T.Board[key]==d.tutorialStep
end
-- Is one gun upgrade at the workbench free right now?
function T.FreeWeaponUpgrade(d)
 return d~=nil and not d.tutorialDone and d.tutorialStep==T.Weapon
end
return T
