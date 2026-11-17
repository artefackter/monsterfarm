local S=game.ReplicatedStorage.Shared;local G=require(S.Config.GraveConfig);local C=require(S.Config.ZoneConfig);local SC=require(S.Config.ShopConfig);local P=require(script.Parent.PlotService);local Z=require(script.Parent.ZombieService);local Pal=require(S.Palette);local Art=require(S.ArtKit)
local CollectionService=game:GetService("CollectionService")
local V={Models={},Held=setmetatable({},{__mode="k"})}
function V.IsHeld(p,slot) local h=V.Held[p];return h and h[slot] and os.clock()-h[slot]<require(S.Config.PetConfig).HoldExpiry end
local timers=setmetatable({},{__mode="k"})
-- Where the epitaph sits on each headstone: height, depth, width and height of the text area.
local SCALE=.72 -- twelve graves share the plot now
function V.Boost(d) return math.min(require(S.Config.PetConfig).GraveCap,require(script.Parent.PetService).ForData(d).graveSpeedPct) end
function V.Progress(d,g) return math.clamp((os.time()-g.plantedAt)/math.max(1,G[g.type].Seconds*(1-V.Boost(d))),0,1) end
function V.Remaining(d,g) return math.max(0,math.ceil(G[g.type].Seconds*(1-V.Boost(d))-(os.time()-g.plantedAt))) end
function V.Slot(d) for i=1,Z.Cap(d,"Graves") do local found=false;for _,g in ipairs(d.graves) do if g.slot==i then found=true end end;if not found then return i end end end
function V.New(kind,progress) return {id=game.HttpService:GenerateGUID(false),type=kind,progress=progress or 0} end
-- Whose grave it is (owner, 2026-11-16: "it should be clear from a grave which mob drops - a coffin with horns, then
-- a deer; with a smile, Verity; its rarity is the random part"; the next day: "that was about the graves in the
-- ruins - so that you see on them which monster family drops"): the monster family it will give, g.family. A grave
-- of the ruins has it from the moment it appears there and keeps it all the way to the farm (RoadService: the spot's
-- Family, the carrier's, the bag's); any other is decided
-- once, the first time anyone asks, by the odds a dig always had - a rarity by the grave's Weights, then any of its
-- location's monsters of that rarity (LocationMonsters): that monster's family. The dig then rolls the rarity afresh
-- within the family (ZombieService.Roll).
function V.Family(g)
 if g.family then return g.family end
 local Col=require(S.MonsterCollection)
 if g.monsterType then g.family=Col.Family(g.monsterType)
 elseif g.starter then g.family="Deer"
 else
  local cfg=G[g.type];local tier=1;local roll=math.random()*100
  for i,w in ipairs(cfg.Weights) do roll-=w;if roll<=0 then tier=i;break end end
  tier=math.max(tier,cfg.MinTier or 1)
  local types=require(S.Config.LocationMonsters).Types(g.location,tier)
  g.family=Col.Family(types[math.random(#types)])
 end
 return g.family
end
-- The family's mark on a grave: its monster's head (the parts of one of its looks that go with the Head; all of it
-- for one that has none), `size` studs at its largest (EMBLEM on the farm's own graves), sitting on the headstone.
-- Returns how far it rises above. The ruins' graves and the one on a carrier's back wear it too (RoadService).
-- The look is the rarity LOOK's (the punk: the farmer's straw hat, the same on every family, hid half of each head),
-- or the family's nearest to it.
local EMBLEM,LOOK=1.9,3
function V.Emblem(m,head,cf,family,size)
 local Col=require(S.MonsterCollection);local ZC=require(S.Config.ZombieConfig)
 local id,tier
 for step=0,#ZC.Types do
  for _,t in ipairs({LOOK-step,LOOK+step}) do
   for _,kind in ipairs(ZC.Types[t] or {}) do if Col.Family(kind)==family then id,tier=kind,t;break end end
   if id then break end
  end
  if id then break end
 end
 if not id then return 0 end
 local tmp=Instance.new("Model");local ok=pcall(function() Art.BuildZombie(tmp,cf,{type=id,tier=tier,mutation="None"}) end)
 local mark=Instance.new("Model");mark.Name="Family"
 if ok then
  local headed=false
  for _,q in tmp:GetChildren() do if q:IsA("BasePart") and q:GetAttribute("Attach")=="Head" then headed=true;break end end
  for _,q in tmp:GetChildren() do
   -- (no hats: the look's outfit says nothing about the family)
   if q:IsA("BasePart") and (not headed or q:GetAttribute("Attach")=="Head") and not (q.Name=="Headwear" or q.Name=="Hood" or q.Name:sub(1,3)=="Hat") then q.Parent=mark end
  end
 end
 tmp:Destroy()
 if #mark:GetChildren()==0 then mark:Destroy();return 0 end
 local _,box=mark:GetBoundingBox()
 mark:ScaleTo((size or EMBLEM)/math.max(box.X,box.Y,box.Z))
 local at,now=mark:GetBoundingBox()
 local top=head.Position+Vector3.new(0,head.Size.Y/2,0)
 mark:PivotTo(mark:GetPivot()+(top+Vector3.new(0,now.Y*.4,0)-at.Position))
 for _,q in mark:GetChildren() do q.Anchored=true;q.CanCollide=false;q.CanQuery=false;q.CanTouch=false;q.CastShadow=false end
 mark.Parent=m
 return now.Y*.9
end
function V.Select(p,id)
 if not require(script.Parent.ActionService).CanAct(p) then return false end
 local d=require(script.Parent.DataService).Profiles[p];if not d or type(id)~="string" then return false end
 for _,g in d.graveInventory do if g.id==id and not g.pendingTransfer then d.selectedItem="grave";require(script.Parent.ActionService).Select(p,3);p:SetAttribute("SelectedItem","grave");d.selectedGrave=id;p:SetAttribute("SelectedGrave",id);return true end end
 if G[id] and (d.vouchers[id] or 0)>0 then d.selectedItem="grave";require(script.Parent.ActionService).Select(p,3);p:SetAttribute("SelectedItem","grave");d.selectedGrave="voucher:"..id;p:SetAttribute("SelectedGrave",d.selectedGrave);return true end
 return false
end
function V.Store(p,g)
 local d=require(script.Parent.DataService).Profiles[p];if not d then return false end
 table.insert(d.graveInventory,g);V.Select(p,g.id);return true
end
-- Plant the selected grave at a farm-local spot (free placement). Returns ok, reason.
function V.PlantAt(p,x,z)
 local d=require(script.Parent.DataService).Profiles[p];local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart");local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
 local plot=P.Assigned[p]
 if not d or not plot or d.activeSlot~=3 or not root or not h or h.Health<=0 or p:GetAttribute("CarryingGrave") or p:GetAttribute("HoldingZombie") or workspace:GetServerTimeNow()<(p:GetAttribute("RoadStunnedUntil") or 0) or not P.Inside(p,plot) then return false end
 local Place=require(S.PlacementRules);local point=Place.GravePoint(x,z)
 local slot=V.Slot(d);if not slot then return false,"placeGravesFull" end
 local reason=Place.Check(d,"Grave",point);if reason then return false,reason end
 if not P.Near(p,(plot.Base*CFrame.new(point.x,0,point.z)).Position,require(S.Config.PlacementConfig).PlaceDistance) then return false,"placeFar" end
 local id=d.selectedGrave;local grave,index
 for i,g in d.graveInventory do if g.id==id and not g.pendingTransfer then grave,index=g,i;break end end
 if not grave and type(id)=="string" and id:sub(1,8)=="voucher:" then local kind=id:sub(9);if G[kind] and (d.vouchers[kind] or 0)>0 then d.vouchers[kind]-=1;grave=V.New(kind) end end
 if not grave then return false,"placeNoGrave" end
 if index then table.remove(d.graveInventory,index) end
 grave.slot=slot;grave.pos=point;grave.plantedAt=os.time()-(grave.progress or 0)*G[grave.type].Seconds*(1-V.Boost(d));grave.progress=nil
 table.insert(d.graves,grave);d.selectedGrave=nil;p:SetAttribute("SelectedGrave",nil)
 require(script.Parent.QuestService).Track(p,"plant",1)
 -- the road grave planted: on to the tutorial's last step, the gunsmith (WeaponService.FinishTutorial, 2026-11-15)
 if not d.tutorialDone and d.tutorialStep==3 and grave.fromRoad then d.tutorialStep=4;require(script.Parent.WeaponService).TutorialStep(p,d) end
 V.Render(p,d);return true
end
-- Old entry point: plant at the spot the given cell used to have (kept for scripts that still speak in cells).
function V.Plant(p,slot)
 if type(slot)~="number" then return false end
 local point=require(S.PlacementRules).Legacy("Graves",slot)
 return (V.PlantAt(p,point.x,point.z))
end
local function timerLabel(head)
 local b=Instance.new("BillboardGui");b.Name="Timer";b.Size=UDim2.fromOffset(78,28);b.StudsOffsetWorldSpace=Vector3.new(0,head.Size.Y/2+1.2,0);b.MaxDistance=70;b.Parent=head
 local l=Instance.new("TextLabel");l.Size=UDim2.fromScale(1,1);l.BackgroundColor3=Pal.Panel;l.TextColor3=Pal.Ink;l.Font=Enum.Font.GothamBlack;l.TextSize=20;l.Parent=b
 Instance.new("UICorner",l).CornerRadius=UDim.new(1,0)
 local s=Instance.new("UIStroke");s.Color=Pal.Stroke;s.Thickness=3;s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;s.Parent=l
 return l
end
local function sparkle(part,color)
 local e=Instance.new("ParticleEmitter");e.Rate=3;e.Lifetime=NumberRange.new(.8,1.4);e.Speed=NumberRange.new(.4,1);e.SpreadAngle=Vector2.new(180,180);e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.7),NumberSequenceKeypoint.new(1,0)});e.LightEmission=.7;e.Color=ColorSequence.new(color);e.Parent=part
end
function V.Render(p,d)
 local models=V.Models[p] or {};V.Models[p]=models;local alive={}
 for _,g in ipairs(d.graves) do
 if g.carriedBy then continue end
 alive[g.slot]=true;local m=models[g.slot]
 if not m then
 m=Instance.new("Model");m.Name="Grave";local cf=P.Position(p,"Graves",g.slot)*CFrame.new(0,-.97,0)
 -- the cartoon V3 graves (2026-11-14): stele, face, stone base and grass in one model; no mound under it
 local stone=Art.Spawn("Grave_V3_"..g.type,m,cf,{scale=SCALE})
 local head=stone.Headstone
 local hand=Art.Spawn("G_Hand",m,cf*CFrame.new(.3*SCALE,-.1*SCALE,-1.8*SCALE),{tints={Hand=Pal.Skin},scale=SCALE}).Hand
 hand.Transparency=1;CollectionService:AddTag(hand,"ArtWave")
 if g.type=="Golden" then sparkle(head,Pal.Accent) elseif g.type=="Emo" then sparkle(head,Color3.fromHex("FF4FB3")) elseif g.type=="Ghost" then sparkle(head,Color3.fromHex("8FE8FF")) elseif g.type=="Lunar" then
  sparkle(head,Color3.fromHex("BDA6FF"));local light=Instance.new("PointLight");light.Color=Color3.fromHex("BDA6FF");light.Range=16;light.Brightness=1.5;light.Parent=head
 end
 local prompt=Instance.new("ProximityPrompt");prompt.Name="DigPrompt";prompt.ActionText="dig";prompt.ObjectText=g.type;prompt.HoldDuration=SC.DigHold;prompt.MaxActivationDistance=10;prompt.RequiresLineOfSight=false;prompt.Parent=head
 local held={}
 prompt.PromptButtonHoldBegan:Connect(function(player) if player==p and P.Near(player,head.Position,SC.DigDistance) then held[player]=os.clock();V.Held[p]=V.Held[p] or {};V.Held[p][g.slot]=os.clock() end end)
 prompt.PromptButtonHoldEnded:Connect(function(player) if V.Held[player] then V.Held[player][g.slot]=nil end end)
 prompt.Triggered:Connect(function(player) local start=held[player];held[player]=nil;if player==p and start and os.clock()-start>=SC.DigHold-SC.HoldTolerance and V.OnDig then V.OnDig(p,g.slot) end end)
 m:SetAttribute("Owner",p.UserId);m:SetAttribute("GraveId",g.id);m:SetAttribute("Starter",g.starter==true)
 local click=Instance.new("ClickDetector");click.MaxActivationDistance=SC.DigDistance;click.Parent=head
 click.MouseClick:Connect(function(who) if who==p and V.OnDig then V.OnDig(p,g.slot) end end)
 if V.OnModel then V.OnModel(p,g,m,head) end
 -- whose grave it is: that monster's head on the headstone (the timer rides above it)
 local family=V.Family(g);m:SetAttribute("Family",family)
 local rise=V.Emblem(m,head,cf,family)
 m.Parent=P.Assigned[p].Model;models[g.slot]=m
 local timer=timerLabel(head);timer.Parent.StudsOffsetWorldSpace+=Vector3.new(0,rise,0)
 timers[m]={timer,hand}
 end
 local remaining=V.Remaining(d,g)
 m:SetAttribute("MonsterType",g.monsterType);m:SetAttribute("Remaining",remaining);m:SetAttribute("GraveType",g.type)
 local t=timers[m]
 if t then
  t[1].Text=remaining>0 and string.format("%d:%02d",math.floor(remaining/60),remaining%60) or "⛏"
  t[1].BackgroundColor3=remaining>0 and Pal.Panel or Pal.Mint
  t[2].Transparency=remaining>0 and 1 or 0
 end
 end
 for slot,m in pairs(models) do if not alive[slot] then m:Destroy();models[slot]=nil end end
end
return V

