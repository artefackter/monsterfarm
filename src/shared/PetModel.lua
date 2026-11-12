-- Pets v3 models (owner's concept pictures, 2026-11-12), low-poly from blocks. Every model faces -Z, its feet at
-- y=0; the pivot sits 1 stud above the feet (PetVisuals places pivots). Parts tagged Swing belong to the facepalm
-- cat's tail (PetVisuals swings them round TailHinge).
local C=require(script.Parent.Config.PetConfig);local Pal=require(script.Parent.Palette)
local M={}
local function hex(h) return Color3.fromHex(h) end
local function maker(model)
 local function part(name,size,cf,color,material,shape)
  local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=material or Enum.Material.SmoothPlastic
  p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=true
  p.TopSurface,p.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
  if shape then p.Shape=shape end;p.Parent=model;return p
 end
 local function wedge(name,size,cf,color)
  local w=Instance.new("WedgePart");w.Name=name;w.Size=size;w.CFrame=cf;w.Color=color;w.Material=Enum.Material.SmoothPlastic
  w.Anchored=true;w.CanCollide=false;w.CanQuery=false;w.CanTouch=false;w.Parent=model;return w
 end
 return part,wedge
end

-- A purple dragon's head on stubby legs: horns, angry yellow eyes, a toothy grin, little green wings.
local function dragon(model)
 local part,wedge=maker(model)
 local purple,light,dark=hex("9B2FD6"),hex("B04BE8"),hex("6E1E9E")
 local cream,yellow,green,mouth=hex("F1E3C6"),hex("FFD21F"),hex("8BDB2E"),hex("3E0E5C")
 local body=part("Body",Vector3.new(2.6,2.2,2.4),CFrame.new(0,1.9,.25),purple)
 part("Snout",Vector3.new(2.5,1.05,1.7),CFrame.new(0,1.62,-1.5)*CFrame.Angles(math.rad(-5),0,0),light)
 part("Jaw",Vector3.new(2.3,.7,2),CFrame.new(0,.98,-1.2),dark)
 part("Mouth",Vector3.new(2.1,.42,1.6),CFrame.new(0,1.28,-1.42),mouth)
 for _,x in {-.8,-.27,.27,.8} do wedge("Tooth",Vector3.new(.3,.42,.2),CFrame.new(x,1.2,-2.27)*CFrame.Angles(0,0,math.pi),cream) end
 for _,x in {-.55,.55} do wedge("Fang",Vector3.new(.26,.32,.18),CFrame.new(x,1.4,-2.12),cream) end
 for _,side in {-1,1} do
  part("Brow",Vector3.new(1.05,.36,.55),CFrame.new(side*.62,2.62,-.98)*CFrame.Angles(0,0,side*-.32),dark)
  part("Eye",Vector3.new(.72,.38,.1),CFrame.new(side*.62,2.27,-1.08)*CFrame.Angles(0,0,side*-.22),yellow)
  part("Nostril",Vector3.new(.22,.3,.1),CFrame.new(side*.46,1.95,-2.38),mouth)
  part("Horn",Vector3.new(.55,.75,.55),CFrame.new(side*.85,3.25,.45)*CFrame.Angles(0,0,side*-.32),cream)
  part("HornTip",Vector3.new(.34,.55,.34),CFrame.new(side*1.05,3.78,.45)*CFrame.Angles(0,0,side*-.45),cream)
  wedge("Wing",Vector3.new(.12,.7,.95),CFrame.new(side*1.45,2.4,.45)*CFrame.Angles(0,0,side*-.75),green)
  part("Leg",Vector3.new(.6,.62,.65),CFrame.new(side*.62,.31,.45),dark)
 end
 part("Tail",Vector3.new(.42,.42,.85),CFrame.new(0,1.35,1.65)*CFrame.Angles(math.rad(28),0,0),purple)
 return body
end

-- A wooden bed on orange cat paws; under it a dark grin with glowing cat eyes, an orange tail behind.
local function bed(model)
 local part,wedge=maker(model)
 local wood,woodDark,blanket,fold=hex("A86F3E"),hex("8A5A30"),hex("8E5BA8"),hex("7A4A93")
 local pillow,dark,eye,paw,pawDark=hex("F3E9D2"),hex("1E1424"),hex("E4FF3A"),hex("F29A2E"),hex("D9811C")
 local body=part("Body",Vector3.new(1.9,.75,2.85),CFrame.new(0,.68,0),dark)
 for _,sx in {-1,1} do for _,sz in {-1,1} do
  local h=sz>0 and 2.15 or 1.45
  part("Post",Vector3.new(.38,h,.38),CFrame.new(sx*1,.35+h/2,sz*1.45),wood)
  part("Paw",Vector3.new(.58,.36,.7),CFrame.new(sx*1,.18,sz*1.45-.12),paw)
  for k=-1,1 do part("Toe",Vector3.new(.04,.2,.06),CFrame.new(sx*1+k*.14,.2,sz*1.45-.48),pawDark) end
 end end
 for _,sx in {-1,1} do part("Rail",Vector3.new(.22,.32,2.9),CFrame.new(sx*1,1.17,0),woodDark) end
 part("FootRail",Vector3.new(2.15,.32,.22),CFrame.new(0,1.17,-1.45),woodDark)
 part("HeadRail",Vector3.new(2.15,.3,.22),CFrame.new(0,2.05,1.45),wood)
 part("HeadRailLow",Vector3.new(2.15,.3,.22),CFrame.new(0,1.45,1.45),wood)
 part("Blanket",Vector3.new(1.85,.4,2.55),CFrame.new(0,1.47,-.15),blanket)
 part("BlanketFold",Vector3.new(1.87,.42,.12),CFrame.new(0,1.48,.55),fold)
 part("Pillow",Vector3.new(1.4,.32,.6),CFrame.new(0,1.78,1.05),pillow)
 for _,sx in {-1,1} do
  local e=part("Eye",Vector3.new(.06,.5,.62),CFrame.new(sx*.42,.78,-1.43)*CFrame.Angles(0,math.pi/2,0),eye,Enum.Material.Neon,Enum.PartType.Cylinder);e.CastShadow=false
  part("Pupil",Vector3.new(.08,.4,.06),CFrame.new(sx*.42,.78,-1.47),hex("111111"))
  wedge("Ear",Vector3.new(.1,.36,.36),CFrame.new(sx*.86,1.02,-1.42)*CFrame.Angles(0,math.pi/2*sx,0),dark)
 end
 for k=0,5 do wedge("Tooth",Vector3.new(.18,.22,.06),CFrame.new(-.65+k*.26,.44,-1.44),pillow) end
 part("Tail",Vector3.new(.3,.3,.7),CFrame.new(.75,.9,1.85)*CFrame.Angles(math.rad(25),0,0),paw)
 part("TailTip",Vector3.new(.32,.6,.32),CFrame.new(.75,1.4,2.1)*CFrame.Angles(math.rad(-20),0,0),paw)
 return body
end

-- A grumpy box cat; its tail ends in a second, very angry cat head (the facepalm happens with that).
local function cat(model)
 local part,wedge=maker(model)
 local cream,brown,brownDark,green,ink,red=hex("F6C98F"),hex("A85A2E"),hex("8C4723"),hex("A6D11A"),hex("3A2414"),hex("C83A3A")
 local body=part("Body",Vector3.new(2,1.3,1.5),CFrame.new(0,1.05,0),cream)
 part("Face",Vector3.new(1.65,1,.06),CFrame.new(0,1.08,-.77),brown)
 for _,sx in {-1,1} do
  part("Eye",Vector3.new(.42,.24,.06),CFrame.new(sx*.42,1.1,-.8),green)
  part("Lid",Vector3.new(.44,.11,.07),CFrame.new(sx*.42,1.2,-.81),brownDark)
  part("Pupil",Vector3.new(.1,.15,.07),CFrame.new(sx*.42,1.08,-.82),ink)
  part("Brow",Vector3.new(.55,.08,.07),CFrame.new(sx*.42,1.36,-.82),ink)
  wedge("Ear",Vector3.new(.14,.55,.5),CFrame.new(sx*.62,1.97,-.2)*CFrame.Angles(0,math.pi/2,0),brown)
  for _,sz in {-1,1} do part("Leg",Vector3.new(.36,.38,.36),CFrame.new(sx*.66,.19,sz*.48),cream) end
 end
 part("Nose",Vector3.new(.18,.1,.07),CFrame.new(0,.96,-.82),ink)
 part("Mouth",Vector3.new(.3,.05,.07),CFrame.new(0,.82,-.82)*CFrame.Angles(0,0,math.rad(8)),ink)
 -- the tail: segments rising from the back, then the angry head; all of it swings at the hinge
 local hinge=CFrame.new(0,1.45,.75)
 local hingePart=part("TailHinge",Vector3.new(.2,.2,.2),hinge,brown);hingePart.Transparency=1
 local function swing(q) q:SetAttribute("Swing",true);return q end
 for i,s in {{0,1.82,.95,-10},{0,2.32,1.0,5},{0,2.8,.85,25},{0,3.18,.55,45}} do
  swing(part("Tail",Vector3.new(.4,.56,.4),CFrame.new(s[1],s[2],s[3])*CFrame.Angles(math.rad(s[4]),0,0),i%2==0 and brownDark or brown))
 end
 local head=CFrame.new(0,3.55,.12)
 swing(part("TailHead",Vector3.new(.95,.82,.32),head,brown))
 swing(part("TailFace",Vector3.new(.7,.56,.04),head*CFrame.new(0,-.04,-.17),cream))
 for _,sx in {-1,1} do
  swing(wedge("TailEar",Vector3.new(.1,.3,.28),head*CFrame.new(sx*.33,.5,0)*CFrame.Angles(0,math.pi/2,0),brown))
  swing(part("TailEye",Vector3.new(.17,.12,.04),head*CFrame.new(sx*.17,.06,-.2),green))
  swing(part("TailBrow",Vector3.new(.22,.05,.05),head*CFrame.new(sx*.17,.17,-.21)*CFrame.Angles(0,0,sx*.45),ink))
 end
 swing(part("TailMouth",Vector3.new(.24,.18,.05),head*CFrame.new(0,-.17,-.2),red))
 return body
end

local BUILD={DragonHead=dragon,BedBanker=bed,FacepalmCat=cat}
function M.Build(pet,parent)
 local model=Instance.new("Model");model.Name=pet.id or pet.species;model:SetAttribute("Species",pet.species)
 local build=BUILD[pet.species]
 local body
 if build then body=build(model)
 else -- an unknown kind: a plain round placeholder
  body=Instance.new("Part");body.Name="Body";body.Shape=Enum.PartType.Ball;body.Size=Vector3.new(1.4,1.4,1.4);body.CFrame=CFrame.new(0,.7,0);body.Color=Pal.Common;body.Anchored=true;body.CanCollide=false;body.CanQuery=false;body.CanTouch=false;body.Parent=model
 end
 model.PrimaryPart=body;body.PivotOffset=body.CFrame:ToObjectSpace(CFrame.new(0,1,0))
 local tier=C.Tiers[pet.tier] and pet.tier or 1
 if tier>=4 then local e=Instance.new("ParticleEmitter");e.Rate=3;e.Lifetime=NumberRange.new(.6);e.Speed=NumberRange.new(.6);e.Size=NumberSequence.new(.16);e.Color=ColorSequence.new(Pal[C.Tiers[tier]]);e.Parent=body end
 if tier==5 then local h=Instance.new("Highlight");h.FillTransparency=.85;h.OutlineColor=Pal.Legendary;h.Parent=model end
 model.Parent=parent;return model
end
return M
