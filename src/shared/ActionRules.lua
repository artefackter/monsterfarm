local C=require(script.Parent.Config.ShovelConfig)
local R={}
function R.Best(d) for i=#C.Order,1,-1 do local id=C.Order[i];if d.shovels and d.shovels[id] then return id end end;return C.Order[1] end
function R.Migrate(d)
 d.shovels=d.shovels or {}
 -- the shovels became melee weapons (2026-11-16): an owned shovel is the weapon in its place (ShovelConfig.Legacy)
 for old,new in C.Legacy do if d.shovels[old] then d.shovels[old]=nil;d.shovels[new]=true end end
 if C.Legacy[d.equippedShovel or ''] then d.equippedShovel=C.Legacy[d.equippedShovel] end
 d.shovels[C.Order[1]]=true
 if not d.equippedShovel or not d.shovels[d.equippedShovel] or not C[d.equippedShovel] then d.equippedShovel=R.Best(d) end
 -- 0 is empty hands (2026-11-13)
 d.activeSlot=(d.activeSlot==0 or d.activeSlot==2 or d.activeSlot==3 or d.activeSlot==4) and d.activeSlot or 1;d.showRanges=d.showRanges~=false;d.slowMode=d.slowMode==true
 return d
end
function R.InRadius(origin,target,range)
 return (target-origin).Magnitude<=range
end
function R.InSector(origin,forward,target,range)
 local delta=target-origin;local flat=Vector3.new(delta.X,0,delta.Z);local look=Vector3.new(forward.X,0,forward.Z)
 return delta.Magnitude<=range and (flat.Magnitude<.01 or look.Magnitude>.01 and look.Unit:Dot(flat.Unit)>=math.cos(math.rad(C.HalfAngle)))
end
return R
