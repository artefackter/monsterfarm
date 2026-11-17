-- Imported art is optional until the creator approves and imports the new GLB.
local Art=require(script.Parent.ArtKit)
local Rig=require(script.Parent.MonsterRig)
local C=require(script.Parent.Config.MutantConfig)
local M={}
function M.Build(kind,cf,variant)
 local spec=C.Types[kind];local m=Instance.new("Model");m.Name=kind
 local root=Instance.new("Part");root.Name="Hitbox";root.Size=C.HitboxSize;root.Transparency=1
 root.Anchored=true;root.CanCollide=false;root.CanTouch=false;root.CanQuery=true;root.CFrame=cf;root.Parent=m;m.PrimaryPart=root
 local pieces
 local asset=variant and variant.Asset or spec.Model;local visualScale=1
 if Art.Has(asset) then
  local scale,lo,hi=Art.MonsterScale(asset);visualScale=scale
  -- A skinned monster (owner, 2026-11-15: "the monsters are built of rigid parts - fix it"; bosses first): its model
  -- from ReplicatedStorage.ArtSkinned (art/roblox-import-v1/tools/skinned_srgb.py, normalize_skinned.lua), sized to
  -- the rigid asset's height, its feet on the floor. Every part of it hangs on the root by a "Skin" joint (the whole
  -- body's movement); MutantAnimation bends the bones inside.
  local skins=variant and variant.Skinned and game:GetService("ReplicatedStorage"):FindFirstChild("ArtSkinned")
  local skin=skins and skins:FindFirstChild(variant.Skinned)
  if skin then
   local fit=(hi.Y-lo.Y)*scale/(skin:GetAttribute("Height") or (hi.Y-lo.Y)*scale)
   local body=skin:Clone();body:ScaleTo(fit);body:PivotTo(cf*CFrame.new(0,-C.RootHeight,0))
   -- where the middle of its head is from the Head bone (a finisher aims there: ShovelMotion.BossHead)
   local centre=skin:GetAttribute("HeadCentre");if centre then m:SetAttribute("HeadCentre",centre*fit) end
   pieces={};local n=0
   for _,p in body:GetChildren() do if p:IsA("BasePart") then n+=1;p:SetAttribute("Attach","Skin");p.Parent=m;pieces["Skin"..n]=p end end
   body:Destroy();m:SetAttribute("Skinned",true)
  else
   pieces=Art.Spawn(asset,m,cf*CFrame.new(0,-C.RootHeight-lo.Y*scale,0),{scale=scale})
  end
  local size=(hi-lo)*scale;root.Size=Vector3.new(math.clamp(size.X*.6,3,9),size.Y,math.clamp(size.Z*.6,3,9))
  m:SetAttribute("MonsterHeight",size.Y);m:SetAttribute("ArtAsset",asset);m:SetAttribute("CollectionType",variant and variant.Id or "DeerChief")
  m:SetAttribute("Family",variant and variant.Family or "Deer")
  m:SetAttribute("Floating",(variant and variant.Floating) or require(script.Parent.MonsterCollection).Floating[variant and variant.Id or "DeerChief"]==true)
  local limits=require(script.Parent.Config.MonsterSize)
  m:SetAttribute("NavigationRadius",math.clamp(math.max(size.X,size.Z)*.38,limits.NavigationRadiusMin,limits.NavigationRadiusMax))
 else
  pieces={}
  for name,v in pairs({Body={Vector3.new(1.4,1.1,2.1),Vector3.new(0,-.2,0)},Head={Vector3.new(1.8,1.2,1.3),Vector3.new(0,-.1,-1.1)},ArmL={Vector3.new(.45,1.8,.5),Vector3.new(1,-.7,-.5)},ArmR={Vector3.new(.8,2,.7),Vector3.new(-1.1,-.6,-.5)},Legs={Vector3.new(1.3,.7,.8),Vector3.new(0,-1.4,.8)},Tail={Vector3.new(.3,.3,1.7),Vector3.new(0,0,1.6)},EyesGlow={Vector3.new(1.2,.15,.1),Vector3.new(0,.25,-1.8)}}) do
   local p=Instance.new("Part");p.Name=name;p.Size=v[1];p.CFrame=cf*CFrame.new(v[2]);p.Color=name=="EyesGlow" and Color3.fromHex("D7FF3E") or spec.Color;p.Parent=m;pieces[name]=p
  end
  if kind~="Imp" then
   pieces.Legs:Destroy();pieces.Legs=nil
   for _,side in ipairs({-1,1}) do local leg=Instance.new("Part");leg.Name=side<0 and "LegL" or "LegR";leg.Size=Vector3.new(.5,1.2,.65);leg.CFrame=cf*CFrame.new(side*.45,-1.5,0);leg.Color=Color3.fromHex("43334B");leg.Parent=m;pieces[leg.Name]=leg end
  end
  m:SetAttribute("TemporaryArt",true)
 end
 for name,p in pairs(pieces) do
  p.Anchored=false;p.Massless=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
  if name=="EyesGlow" then p.Material=Enum.Material.Neon end
  local joint=Instance.new("Motor6D");joint.Name=name; joint.Part0=root;joint.Part1=p;local center=cf:PointToObjectSpace(p.Position)
  local pivot=center
  if name=="ArmL" or name=="ArmR" or name=="LegL" or name=="LegR" then pivot+=Vector3.new(0,p.Size.Y*.4,0)
  elseif name=="Head" or name=="EyesGlow" then local head=pieces.Head;pivot=cf:PointToObjectSpace(head.Position)-Vector3.new(0,head.Size.Y*.25,0) end
  local group=p:GetAttribute("Attach") or name
  local authored=Rig[asset] and Rig[asset][group]
  if authored then local lo=Art.Bounds(asset);pivot=authored*visualScale-Vector3.new(0,C.RootHeight+lo.Y*visualScale,0) end
  joint:SetAttribute("PoseGroup",group)
  joint.C0=CFrame.new(pivot);joint.C1=p.CFrame:ToObjectSpace(cf*joint.C0);joint.Parent=root
 end
 return m
end
return M
