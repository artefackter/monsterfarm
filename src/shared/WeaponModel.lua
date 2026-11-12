-- Approved WorldV3 firearms; separated moving parts remain available for animation.
local Art=require(script.Parent.ArtKit);local World=require(script.Parent.WorldArt)
local C=require(script.Parent.Config.WeaponConfig)
local W={}
local Skins=require(script.Parent.WeaponSkins)
function W.Build(id,parent,cf,skin)
 assert(C[id],'Unknown firearm');cf=cf or CFrame.identity
 local asset=Skins.Asset(id,skin);local m=Instance.new('Model');m.Name='WeaponVisual';m:SetAttribute('ArtAsset',asset)
 local parts=Art.Spawn(asset,m,cf);local main=parts.Main;m.PrimaryPart=main
 m:SetAttribute('OriginOffset',cf:ToObjectSpace(main.CFrame))
 for name,p in parts do
  p.Anchored=false
  if p~=main then local joint=Instance.new('Motor6D');joint.Name=name..'Joint';joint.Part0=main;joint.Part1=p;local pivotName=({Barrels='Hinge',Foregrip='Hinge',Magazine='MagazinePivot',Bolt='BoltPivot',Pump='PumpPivot'})[name];local anchors=require(script.Parent.WeaponArtAnchors)[asset];local point=anchors and pivotName and anchors[pivotName];local pivot=point and cf*CFrame.new(point) or p.CFrame;joint.C0=main.CFrame:ToObjectSpace(pivot);joint.C1=p.CFrame:ToObjectSpace(pivot);joint.Parent=main end
 end
 for _,name in {'Muzzle','Grip','SupportHand'} do
  local a=Instance.new('Attachment');a.Name=name;a.CFrame=main.CFrame:ToObjectSpace(cf*CFrame.new(World.Anchor(asset,name)));if name=='SupportHand' then a.CFrame*=CFrame.new(0,-.3,0)*CFrame.Angles(0,0,math.pi/2) end;a.Parent=main
 end
 m.Parent=parent;return m
end
return W
