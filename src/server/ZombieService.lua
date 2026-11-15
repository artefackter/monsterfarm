local S=game.ReplicatedStorage.Shared;local C=require(S.Config.ZombieConfig);local ZC=require(S.Config.ZoneConfig);local U=require(S.Config.UpgradeConfig);local R=require(S.Config.RewardConfig);local P=require(script.Parent.PlotService);local Pal=require(S.Palette);local Art=require(S.ArtKit)
local Z={Models={}};local rng=Random.new()
function Z.Cap(d,zone)
 if zone=="Field" then return require(S.HouseRules).FieldCap(d) end -- the house level sets it (HouseConfig)
 return math.min(ZC[zone].Max,ZC[zone].Start+(d.upgrades[zone] or 0)*U[zone].Step)
end
-- The crypt never runs out of slots (2026-11-14): it takes every monster, as digging always did.
function Z.Slot(d,zone)
 local used={};for _,z in ipairs(d.zombies) do if z.zone==zone and type(z.slot)=="number" then used[z.slot]=true end end
 local last=zone=="Crypt" and #d.zombies+1 or Z.Cap(d,zone)
 for i=1,last do if not used[i] then return i end end
end
function Z.Find(d,id) for i,z in ipairs(d.zombies) do if z.id==id then return z,i end end end
function Z.Bonus(d) local types={} for key in pairs(d.zombiedex) do types[string.split(key,":")[1]]=true end;local count=0;for _ in pairs(types) do count+=1 end;return 1+count*R.DexBonus end
function Z.Rate(z) return require(S.MergeRules).Rate(z) end
function Z.Income(d,ignoreSuppression) local v=0;for _,z in ipairs(d.zombies) do if z.zone=="Field" and not z.carriedBy and not z.pendingTransfer and (ignoreSuppression or not Z.IsIncomeBlocked or not Z.IsIncomeBlocked(d,z)) then v+=Z.Rate(z) end end;return v*Z.Bonus(d)*(1+require(script.Parent.PetService).ForData(d).incomePct)*require(script.Parent.PetService).ForData(d).incomeMult*require(S.PrestigeRules).Mult(d) end
function Z.Roll(weights,night,starter,luck,minTier,location) -- location: where the grave was dug (LocationMonsters)
 luck=luck or 1
 local tier=1;local roll=rng:NextNumber()*100;for i,w in ipairs(weights) do roll-=w;if roll<=0 then tier=i;break end end
 tier=math.max(tier,minTier or 1) -- the grave's floor (GraveConfig.MinTier)
 local mut="None";if rng:NextNumber()<C.RainbowChance*luck then mut="Rainbow" elseif night and rng:NextNumber()<C.LunarChance*luck then mut="Lunar" elseif rng:NextNumber()<C.GoldenChance*luck then mut="Golden" end
 local types=require(S.Config.LocationMonsters).Types(location,tier);return {id=game.HttpService:GenerateGUID(false),type=starter and "DeerMiner" or types[rng:NextInteger(1,#types)],tier=starter and 2 or tier,mutation=starter and "None" or mut,zone="Crypt",slot=0}
end
-- Both pen and yard share the same grass level.
-- Bigger zombies are scaled around their middle, so the pivot rises to keep their feet on the ground.
local function rest(cf,zone,z) return cf*CFrame.new(0,1.15+(zone=="Crypt" and 0 or (require(S.MergeRules).Size(z)-1)*Art.PivotHeight),0) end
local function starBadge(body,stars,size)
 local Icons=require(S.Icons)
 local b=Instance.new("BillboardGui");b.Name="Stars";b.Size=UDim2.fromOffset(26*stars,26);b.StudsOffsetWorldSpace=Vector3.new(0,(body.Parent:GetAttribute("MonsterLabelHeight") or 3.3)*size+1,0);b.MaxDistance=50;b.LightInfluence=0;b.Parent=body
 for i=1,stars do local img=Instance.new("ImageLabel");img.BackgroundTransparency=1;img.Size=UDim2.fromOffset(26,26);img.Position=UDim2.fromOffset((i-1)*26,0);img.Image=Icons.star;img.Parent=b end
end
function Z.Model(z,cf,parent)
 local m=Instance.new("Model");m.Name="Zombie";m:SetAttribute("ZombieId",z.id);m:SetAttribute("Mutation",z.mutation);m:SetAttribute("Type",z.type);m:SetAttribute("Zone",z.zone);m:SetAttribute("Income",Z.Rate(z));m:SetAttribute("Tier",z.tier)
 local stars=require(S.MergeRules).Stars(z);m:SetAttribute("Stars",stars)
 local pivot=rest(cf,z.zone,z)
 if z.zone=="Crypt" then
  -- Crypt zombies are behind walls: a farm can hold 60, so only an invisible stand-in is created.
  local body=P.Part(m,"Body",Vector3.new(1,1,1),pivot,Pal.Skin);body.Transparency=1;body.CanCollide=false;body.CanQuery=false;body.CanTouch=false;body.CastShadow=false;m.PrimaryPart=body
 else
  local body=Art.BuildZombie(m,pivot*CFrame.new(0,-Art.PivotHeight,0),z)
  local size=require(S.MergeRules).Size(z);m:ScaleTo(size);m:SetAttribute("VisualSize",size)
  if stars>1 then
   starBadge(body,stars,size)
   if stars>=C.Stars.Max then local e=Instance.new("ParticleEmitter");e.Rate=5;e.Lifetime=NumberRange.new(.7,1.3);e.Speed=NumberRange.new(.5,1.5);e.SpreadAngle=Vector2.new(180,180);e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.55),NumberSequenceKeypoint.new(1,0)});e.LightEmission=.6;e.Color=ColorSequence.new(Pal.Accent);e.Parent=body end
  end
  if z.mutation=="Lunar" then local light=Instance.new("PointLight");light.Color=Pal.Glow;light.Brightness=2;light.Range=14;light.Parent=body;require(S.WorldArt).NightLight(light);local h=Instance.new("Highlight");h.FillColor=Pal.Glow;h.FillTransparency=.75;h.OutlineTransparency=.4;h.OutlineColor=Pal.Glow;h.DepthMode=Enum.HighlightDepthMode.Occluded;h.Enabled=workspace:GetAttribute("IsNight")==true;game:GetService("CollectionService"):AddTag(h,"NightLight");h.Parent=m end
  if z.mutation=="Golden" or z.mutation=="Rainbow" then local e=Instance.new("ParticleEmitter");e.Rate=4;e.Lifetime=NumberRange.new(.6,1.2);e.Speed=NumberRange.new(.5,1.5);e.SpreadAngle=Vector2.new(180,180);e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.5),NumberSequenceKeypoint.new(1,0)});e.LightEmission=.6;e.Color=ColorSequence.new(z.mutation=="Golden" and Pal.Accent or Pal.Pink);e.Parent=body end
 end
 for _,part in m:GetDescendants() do if part:IsA("BasePart") then part.CanCollide=false;part.CanTouch=false end end
 m.Parent=parent;return m
end
function Z.Render(p,d)
 local held=Z.Holding[p];if held and not Z.Find(d,held.id) then Z.Drop(p) end
 for _,z in ipairs(d.zombies) do
 if z.pendingTransfer then continue end
 local m=Z.Models[z.id]
 if not m or not m.Parent then m=Z.Model(z,P.Position(p,z.zone,z.slot),P.Assigned[p].Model);Z.Models[z.id]=m;if Z.OnModel then Z.OnModel(p,z,m) end end
 if not z.carriedBy then local target=rest(P.Position(p,z.zone,z.slot),z.zone,z);if (m:GetPivot().Position-target.Position).Magnitude>.05 then m:PivotTo(target) end end
 m:SetAttribute("Zone",z.zone);m:SetAttribute("Carried",z.carriedBy~=nil)
 end
end
function Z.Remove(id) local m=Z.Models[id];if m then m:Destroy() end Z.Models[id]=nil end
-- Holding a zombie: it rides above the player's head until it is put down anywhere in the yard.
-- While held it counts as stored (zone "Crypt"), so it earns nothing and nobody else can touch it.
Z.Holding={}
local function heldVisual(p,z)
 local ch=p.Character;local root=ch and ch:FindFirstChild("HumanoidRootPart");if not root then return nil end
 local look=table.clone(z);look.zone="Hand"
 local m=Z.Model(look,root.CFrame,nil);m.Name="HeldZombie";m:SetAttribute("Held",true)
 local size=require(S.MergeRules).Size(z);if size>1.3 then m:ScaleTo(1.3) end
 local cf,box=m:GetBoundingBox();m:PivotTo(m:GetPivot()+Vector3.new(0,root.Position.Y+2.7-(cf.Position.Y-box.Y/2),0))
 local main=m.PrimaryPart
 for _,part in m:GetDescendants() do if part:IsA("BasePart") then part.Anchored=false;part.CanCollide=false;part.CanQuery=false;part.CanTouch=false;part.Massless=true;if part~=main then local w=Instance.new("WeldConstraint");w.Part0=main;w.Part1=part;w.Parent=part end end end
 local grip=Instance.new("Motor6D");grip.Name="HoldGrip";grip.Part0=root;grip.Part1=main;grip.C0=root.CFrame:ToObjectSpace(main.CFrame);grip.Parent=root
 m.Destroying:Connect(function() grip:Destroy() end)
 m.Parent=ch;return m
end
function Z.Drop(p)
 local h=Z.Holding[p];Z.Holding[p]=nil
 if h and h.model then h.model:Destroy() end
 if p.Parent then p:SetAttribute("HoldingZombie",nil) end
end
function Z.Hold(p,d,id)
 local z=Z.Find(d,id);local plot=P.Assigned[p]
 if not z or z.carriedBy or z.pendingTransfer or not plot or not P.Inside(p,plot) or p:GetAttribute("CarryingGrave") then return false end
 if Z.Holding[p] then Z.Drop(p) end
 if z.zone~="Crypt" then z.zone="Crypt";z.slot=Z.Slot(d,"Crypt") or 0;z.pos=nil;Z.Remove(z.id) end
 local model=heldVisual(p,z);if not model then return false end
 Z.Holding[p]={id=z.id,model=model};p:SetAttribute("HoldingZombie",z.id)
 require(script.Parent.ActionService).Empty(p) -- a monster in your arms, nothing else in your hands
 return true
end
-- The crypt's two buttons (owner, 2026-11-14). "Place best": the farm ends up holding the best earners there are -
-- weaker monsters on the farm go back into the crypt to make room for better ones from it, until the house's limit.
-- "Store all": every monster on the farm goes back into the crypt. The crypt has no limit (2026-11-14): digging always
-- filled it past its old cap, and a cap there only stranded monsters outside.
function Z.PlaceBest(p,d)
 local Place=require(S.PlacementRules);local pool={};local locked=0
 for _,z in ipairs(d.zombies) do
  local free=not z.carriedBy and not z.pendingTransfer
  if (z.zone=="Crypt" or z.zone=="Field") and free then table.insert(pool,z) elseif z.zone=="Field" then locked+=1 end
 end
 -- equal earners keep the one already out, so a second press changes nothing
 table.sort(pool,function(a,b) local ra,rb=Z.Rate(a),Z.Rate(b);if ra~=rb then return ra>rb end;return a.zone=="Field" and b.zone~="Field" end)
 local room=math.max(0,Z.Cap(d,"Field")-locked);local best={}
 for i=1,math.min(room,#pool) do best[pool[i]]=true end
 local changed=0
 local function store(z)
  if Z.Holding[p] and Z.Holding[p].id==z.id then Z.Drop(p) end
  z.zone="Crypt";z.slot=Z.Slot(d,"Crypt");z.pos=nil;Z.Remove(z.id);changed+=1
 end
 for _,z in ipairs(pool) do if z.zone=="Field" and not best[z] then store(z) end end
 for _,z in ipairs(pool) do if z.zone=="Crypt" and best[z] then
  local point=Place.FindFree(d,"Worker",z);if not point then break end
  if Z.Holding[p] and Z.Holding[p].id==z.id then Z.Drop(p) end
  z.zone="Field";z.slot=Z.Slot(d,"Field") or #d.zombies;z.pos=point;Z.Remove(z.id);changed+=1
 end end
 if changed>0 then Z.Render(p,d) end
 return changed>0
end
function Z.StoreAll(p,d)
 local moved=0
 for _,z in ipairs(d.zombies) do if (z.zone=="Field" or z.zone=="Guards") and not z.carriedBy and not z.pendingTransfer then
  if Z.Holding[p] and Z.Holding[p].id==z.id then Z.Drop(p) end
  z.zone="Crypt";z.slot=Z.Slot(d,"Crypt");z.pos=nil;Z.Remove(z.id);moved+=1
 end end
 if moved>0 then Z.Render(p,d) end
 return moved>0
end
function Z.Place(p,d,x,zz)
 local h=Z.Holding[p];local plot=P.Assigned[p];if not h or not plot or not P.Inside(p,plot) then return false end
 local z=Z.Find(d,h.id);if not z then Z.Drop(p);return false end
 local Place=require(S.PlacementRules);local point=Place.Point(x,zz)
 local role=Place.Role(point);local count=0;for _,other in ipairs(d.zombies) do if other.zone==role then count+=1 end end
 if count>=Z.Cap(d,role) then return false,role=="Guards" and "placeGuardsFull" or "placeFieldFull" end
 local reason=Place.Check(d,"Zombie",point,z);if reason then return false,reason end
 if not P.Near(p,(plot.Base*CFrame.new(point.x,0,point.z)).Position,require(S.Config.PlacementConfig).PlaceDistance) then return false,"placeFar" end
 z.zone=role;z.slot=Z.Slot(d,role) or count+1;z.pos=point;Z.Remove(z.id);Z.Drop(p);Z.Render(p,d)
 return true
end
return Z

