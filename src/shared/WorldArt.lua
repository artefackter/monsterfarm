-- Shared assembly helpers; gameplay collisions are explicit, separate from visual meshes.
local Art=require(script.Parent.ArtKit)
local Data=require(script.Parent.ArtMetadataV3)
local WeaponAnchors=require(script.Parent.WeaponArtAnchors)
local W={}
function W.Anchor(asset,name)
 local authored=WeaponAnchors[asset] and WeaponAnchors[asset][name];if authored then return authored end
 local p=Data.anchors[asset] and Data.anchors[asset][name];return p and Vector3.new(table.unpack(p)) or Vector3.zero
end
function W.Surface(p)
 p.Material=Enum.Material.SmoothPlastic
 if game.MaterialService:FindFirstChild('GrowVoxelV3') then p.MaterialVariant='GrowVoxelV3' end
 return p
end
function W.Colliders(asset,parent,cf)
 local out={}
 for _,c in Data.colliders[asset] or {} do
  local p=Instance.new('Part');p.Name='Collision_'..c.name;p.Size=Vector3.new(table.unpack(c.size));p.CFrame=cf*CFrame.new(table.unpack(c.center));p.Anchored=true;p.Transparency=1;p.CastShadow=false;p.CanTouch=false;p.CanCollide=true;p.CanQuery=true;p.Parent=parent;out[c.name]=p
 end
 return out
end
function W.Model(asset,parent,cf,opts)
 local m=Instance.new('Model');m.Name=asset;m:SetAttribute('ArtAsset',asset)
 Art.Spawn(asset,m,cf,opts);m.Parent=parent;return m
end
-- Lamps light up only at night: by day a PointLight on shiny plastic leaves hard highlights.
-- PlotService.SetNight flips everything tagged here; new lights start in the current state.
local CS=game:GetService('CollectionService')
function W.NightLight(l) CS:AddTag(l,'NightLight');l.Enabled=workspace:GetAttribute('IsNight')==true;l.Shadows=false;return l end
-- Lamp bulbs and lit windows glow (Neon) only at night; by day they are plain coloured plastic.
function W.NightGlow(p) CS:AddTag(p,'NightGlow');p.Material=workspace:GetAttribute('IsNight')==true and Enum.Material.Neon or Enum.Material.SmoothPlastic;return p end
function W.Light(parent,cf,color,range,brightness)
 local p=Instance.new('Part');p.Name='LightAnchor';p.Size=Vector3.one*.1;p.CFrame=cf;p.Anchored=true;p.Transparency=1;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.Parent=parent
 local l=Instance.new('PointLight');l.Color=color;l.Range=range or 20;l.Brightness=brightness or .7;l.Shadows=false;l.Parent=p;return W.NightLight(l)
end
return W
