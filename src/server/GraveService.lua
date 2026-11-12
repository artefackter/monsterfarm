local S=game.ReplicatedStorage.Shared;local G=require(S.Config.GraveConfig);local C=require(S.Config.ZoneConfig);local SC=require(S.Config.ShopConfig);local P=require(script.Parent.PlotService);local Z=require(script.Parent.ZombieService);local Pal=require(S.Palette);local Art=require(S.ArtKit)
local CollectionService=game:GetService("CollectionService")
local V={Models={},Held=setmetatable({},{__mode="k"})}
function V.IsHeld(p,slot) local h=V.Held[p];return h and h[slot] and os.clock()-h[slot]<require(S.Config.PetConfig).HoldExpiry end
local timers=setmetatable({},{__mode="k"})
-- Where the epitaph sits on each headstone: height, depth, width and height of the text area.
local SCALE=.72 -- twelve graves share the plot now
local EPITAPH={Wooden={1.72,1.72,2.2,1.2},Stone={2.0,1.4,2.5,1.6,-5},Marble={2.2,1.56,2.3,1.9},Golden={2.15,1.52,2.5,1.9}}
function V.Boost(d) return math.min(require(S.Config.PetConfig).GraveCap,require(script.Parent.PetService).ForData(d).graveSpeedPct) end
function V.Progress(d,g) return math.clamp((os.time()-g.plantedAt)/math.max(1,G[g.type].Seconds*(1-V.Boost(d))),0,1) end
function V.Remaining(d,g) return math.max(0,math.ceil(G[g.type].Seconds*(1-V.Boost(d))-(os.time()-g.plantedAt))) end
function V.Slot(d) for i=1,Z.Cap(d,"Graves") do local found=false;for _,g in ipairs(d.graves) do if g.slot==i then found=true end end;if not found then return i end end end
function V.New(kind,progress) return {id=game.HttpService:GenerateGUID(false),type=kind,progress=progress or 0} end
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
 if not d.tutorialDone and d.tutorialStep==3 and grave.fromRoad then d.tutorialDone=true;d.tutorialStep=4;require(script.Parent.PetService).Starter(p) end
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
 Art.Spawn("G_Mound",m,cf,{scale=SCALE})
 local stone=Art.Spawn("G_"..g.type,m,cf,{scale=SCALE})
 local head=stone.Headstone
 local hand=Art.Spawn("G_Hand",m,cf*CFrame.new(.3*SCALE,-.1*SCALE,-1.1*SCALE),{tints={Hand=Pal.Skin},scale=SCALE}).Hand
 hand.Transparency=1;CollectionService:AddTag(hand,"ArtWave")
 local spot=EPITAPH[g.type]
 if spot then
  local label=P.SignText(m,cf*CFrame.new(0,spot[1]*SCALE,spot[2]*SCALE)*CFrame.Angles(math.rad(spot[5] or 0),0,0),Vector3.new(spot[3]*SCALE,spot[4]*SCALE,.05),"epitaph"..((g.slot*3+g.plantedAt)%8+1),g.type=="Wooden" and Pal.Ink or Color3.fromHex("3C3350"))
  label.Parent.LightInfluence=.6
 end
 if g.type=="Golden" then sparkle(head,Pal.Accent) elseif g.type=="Lunar" then
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
 m.Parent=P.Assigned[p].Model;models[g.slot]=m
 timers[m]={timerLabel(head),hand}
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

