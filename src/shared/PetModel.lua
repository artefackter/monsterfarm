local C=require(script.Parent.Config.PetConfig);local Pal=require(script.Parent.Palette)
local Art=require(script.Parent.ArtKit);local Manifest=require(script.Parent.ArtManifest)
local M={}
function M.Build(pet,parent)
 local model=Instance.new("Model");model.Name=pet.id or pet.species
 if Manifest["Pet_"..pet.species] then
  local parts=Art.Spawn("Pet_"..pet.species,model,CFrame.new());local body=parts.Body;model.PrimaryPart=body
  body.PivotOffset=body.CFrame:ToObjectSpace(CFrame.new(0,.7,0))
  local badge=Instance.new("Part");badge.Name="RarityBadge";badge.Shape=Enum.PartType.Ball;badge.Size=Vector3.one*.22;badge.Color=Pal[C.Tiers[pet.tier]];badge.Anchored=true;badge.CanCollide=false;badge.CanQuery=false;badge.CanTouch=false;badge.Position=Vector3.new(0,.85,-.72);badge.Parent=model
  if pet.tier>=4 then local e=Instance.new("ParticleEmitter");e.Rate=2;e.Lifetime=NumberRange.new(.5);e.Speed=NumberRange.new(.5);e.Size=NumberSequence.new(.12);e.Color=ColorSequence.new(Pal[C.Tiers[pet.tier]]);e.Parent=body end
  if pet.tier==5 then local h=Instance.new("Highlight");h.FillTransparency=1;h.OutlineColor=Pal.Legendary;h.Parent=model end
  model.Parent=parent;return model
 end
 local skin=Color3.fromHex("91BFA0");local ink=Color3.fromHex("302A40")
 local function part(name,size,pos,color,shape)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=CFrame.new(pos);p.Color=color;p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false;p.Shape=shape or Enum.PartType.Block;p.Parent=model;return p end
 local body=part("Body",Vector3.new(1,.85,1.3),Vector3.new(0,.7,0),skin,Enum.PartType.Ball);model.PrimaryPart=body
 part("Head",Vector3.new(1.5,1.3,1.4),Vector3.new(0,1.5,-.45),skin,Enum.PartType.Ball)
 for _,x in ipairs({-.42,.42}) do part("Eye",Vector3.new(.35,.45,.15),Vector3.new(x,1.6,-1.1),ink,Enum.PartType.Ball) end
 part("Collar",Vector3.new(1.1,.18,1.1),Vector3.new(0,1.05,-.1),Pal[C.Tiers[pet.tier]])
 part("Stitch",Vector3.new(.08,.48,.05),Vector3.new(.15,1.45,-1.16),ink)
 local s=pet.species
 if s=="FarmerCat" then part("StrawHat",Vector3.new(2,.2,1.8),Vector3.new(0,2.15,-.4),Pal.Accent);part("Pitchfork",Vector3.new(.12,1.7,.12),Vector3.new(.9,.9,-.3),Pal.Earth);part("Fork",Vector3.new(.65,.4,.12),Vector3.new(.9,1.8,-.3),Pal.Stone)
 elseif s=="DiggerMole" then part("Helmet",Vector3.new(1.6,.55,1.5),Vector3.new(0,2,-.4),Pal.Accent,Enum.PartType.Ball);local lamp=part("Lamp",Vector3.new(.45,.45,.2),Vector3.new(0,2,-1.2),Pal.Text,Enum.PartType.Ball);lamp.Material=Enum.Material.Neon
 elseif s=="CoinHen" then part("Scarf",Vector3.new(1.7,.3,1.4),Vector3.new(0,2,-.4),Pal.Pumpkin);part("Beak",Vector3.new(.4,.3,.4),Vector3.new(0,1.35,-1.25),Pal.Accent)
 elseif s=="LuckyOwl" then for _,x in ipairs({-.42,.42}) do local glasses=part("Glasses",Vector3.new(.65,.65,.1),Vector3.new(x,1.6,-1.15),Pal.Accent,Enum.PartType.Ball);glasses.Transparency=.55 end
 elseif s=="GuardDog" then part("Cap",Vector3.new(1.8,.45,1.5),Vector3.new(0,2,-.4),Pal.Panel);part("Badge",Vector3.new(.4,.4,.1),Vector3.new(0,2,-1.2),Pal.Accent)
 elseif s=="BanditBat" then part("Mask",Vector3.new(1.4,.22,.12),Vector3.new(0,1.4,-1.15),ink);for _,x in ipairs({-1,1}) do part("Wing",Vector3.new(1.1,.7,.2),Vector3.new(x,.9,0),Pal.Epic) end end
 if pet.tier>=4 then local e=Instance.new("ParticleEmitter");e.Rate=2;e.Lifetime=NumberRange.new(.5);e.Speed=NumberRange.new(.5);e.Size=NumberSequence.new(.12);e.Color=ColorSequence.new(Pal[C.Tiers[pet.tier]]);e.Parent=body end
 if pet.tier==5 then local l=Instance.new("PointLight");l.Color=Pal.Legendary;l.Range=6;l.Brightness=.5;l.Parent=body;local h=Instance.new("Highlight");h.FillTransparency=.8;h.OutlineColor=Pal.Legendary;h.Parent=model end
 model.Parent=parent;return model
end
return M
