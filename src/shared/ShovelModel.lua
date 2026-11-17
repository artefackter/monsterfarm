-- What is held in slot 1: a melee weapon (ShovelConfig; shovels until 2026-11-16), or the plain shovel graves are
-- dug with ("Dig"). M.Build(id, parent) returns its model, parts welded to its PrimaryPart.
-- Every model's PIVOT is one frame, the one the motions speak (ShovelMotion): the right hand at its origin, the
-- working end - blade, head - along -Y, the cutting edge towards -Z; a two-hand weapon's other grip is a stud
-- towards +Y. The imported ones (ReplicatedStorage.ArtModels: Melee_<id>, art/roblox-import-v1/weapons) are authored
-- in that frame; the two built from parts (ChainsawModel) have their own - the grip at the pivot, the bar along -Z,
-- the cutting edge up - and are turned into it here (their PrimaryPart keeps the saw's own frame, which the chainsaw
-- finisher's coded pose speaks: ShovelMotion's saw).
-- The butterfly knife's blade and second handle turn on Motor6Ds (Flip): M.Flip(model, t) flips it open and shut.
local Art=require(script.Parent.ArtKit)
local C=require(script.Parent.Config.ShovelConfig)
local Saw=require(script.Parent.ChainsawModel)
local M={}
local SAW_FRAME=CFrame.Angles(-math.pi/2,0,0) -- the saw's own frame in the motions' frame: its bar (-Z) is -Y there, its top -Z
local ASSET={Scythe='Melee_Scythe',Katana='Melee_Katana',Dagger='Melee_Dagger',Butterfly='Melee_Butterfly',Pickaxe='Melee_Pickaxe'}
local SHOVEL='V3_ShovelSteel'
local SCALE={Dagger=1.3,Butterfly=1.35} -- the knives a little bigger than modelled: they have to read from the camera behind the back
function M.Build(id,parent)
 if id~='Dig' and not C[id or ''] then id=C.Order[1] end
 if id=='Chainsaw' or id=='Chainsword' then
  local m=id=='Chainsaw' and Saw.Build(nil) or Saw.BuildSword(nil)
  m.PrimaryPart.PivotOffset=SAW_FRAME:Inverse();m:SetAttribute('Melee',id);m.Parent=parent;return m
 end
 local asset=ASSET[id];if not asset or not Art.Has(asset) then asset=SHOVEL end
 local m=Instance.new('Model');m.Name='ShovelVisual';m:SetAttribute('ArtAsset',asset);m:SetAttribute('Melee',id)
 local scale=asset~=SHOVEL and SCALE[id] or 1
 local parts=Art.Spawn(asset,m,CFrame.identity,{scale=scale})
 local handle=parts.Handle;m.PrimaryPart=handle
 -- Pivot is the authored hand position, not the centre of the mesh's bounding box.
 handle.PivotOffset=handle.CFrame:Inverse()
 for _,p in parts do
  p.Anchored=false
  if p~=handle then
   -- the butterfly knife: where this piece turns (the asset's frame), and on what - the blade on the handle in
   -- the hand, the second handle on the blade
   local hinge=p:GetAttribute('Hinge')
   if typeof(hinge)=='Vector3' then
    local base=parts[p:GetAttribute('HingeParent') or ''] or handle;local at=CFrame.new(hinge*scale)
    local j=Instance.new('Motor6D');j.Name='Flip';j.Part0=base;j.Part1=p
    j.C0=base.CFrame:ToObjectSpace(at);j.C1=p.CFrame:ToObjectSpace(at);j.Parent=p
   else
    local w=Instance.new('WeldConstraint');w.Part0=handle;w.Part1=p;w.Parent=p
   end
  end
 end
 m.Parent=parent;return m
end
-- The butterfly knife flipping: `t` runs 0..1 over one trick - the blade goes right round on the handle in the hand
-- while the second handle whips round on the blade the other way, and both come back to the open knife. The hinges
-- turn about the asset's X (the knife opens in its flat plane: Y is its length, Z its edge).
function M.Flip(model,t)
 t=math.clamp(t,0,1);local k=t*t*(3-2*t)
 for _,p in model:GetChildren() do
  local j=p:IsA('BasePart') and p:FindFirstChild('Flip')
  if j then j.Transform=CFrame.Angles(math.pi*2*(p.Name=='Blade' and 1 or -2)*k,0,0) end
 end
end
return M
