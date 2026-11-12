local Art=require(script.Parent.ArtKit)
local C=require(script.Parent.Config.ShovelConfig)
local M={}
function M.Build(id,parent)
 if not C[id or ''] then id='Rusty' end
 local m=Instance.new('Model');m.Name='ShovelVisual';m:SetAttribute('ArtAsset','V3_Shovel'..id)
 local parts=Art.Spawn('V3_Shovel'..id,m,CFrame.identity)
 local handle=parts.Handle;m.PrimaryPart=handle
 -- Pivot is the authored hand position, not the centre of the mesh's bounding box.
 handle.PivotOffset=handle.CFrame:Inverse()
 for _,p in parts do p.Anchored=false;if p~=handle then local w=Instance.new('WeldConstraint');w.Part0=handle;w.Part1=p;w.Parent=p end end
 m.Parent=parent;return m
end
return M
