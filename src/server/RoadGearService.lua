-- All prices, targets, placement and trap contacts are decided on the server.
local Players=game:GetService("Players")
local RS=game.ReplicatedStorage
local C=require(RS.Shared.Config.RoadConfig)
local SC=require(RS.Shared.Config.ShopConfig)
local D=require(script.Parent.DataService)
local P=require(script.Parent.PlotService)
local Road=require(script.Parent.RoadService)
local Raid=require(script.Parent.RaidService)
local W=require(script.Parent.WeaponService)
local A=require(script.Parent.AnalyticsTracker)
local Models=require(RS.Shared.RoadGearModel)
local Actions=require(script.Parent.ActionService);local Shovels=require(RS.Shared.Config.ShovelConfig);local ActionRules=require(RS.Shared.ActionRules)
local Gear={Traps={},NextBat={},Requests={},Previous={}}
local rem
local function root(p) return p.Character and p.Character:FindFirstChild("HumanoidRootPart") end
local function notice(p,key) rem.Notice:FireClient(p,key) end
function Gear.Push(p)
 local d=D.Profiles[p];if d then p:SetAttribute("RoadTraps",d.traps or 0) end
end
function Gear.Buy(p)
 local d=D.Profiles[p];local r=root(p);local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
 if not Actions.CanAct(p) or not d or not r or not h or h.Health<=0 or P.InHouse(p) or not require(script.Parent.InterfaceService).NearZone(p,"traps") then return false,"trapVisitShop" end
 if (d.traps or 0)>=C.Trap.MaxStock then return false,"trapStockFull" end
 if d.coins<C.Trap.Price then return false,"trapNoCoins" end
 d.coins-=C.Trap.Price;d.traps=(d.traps or 0)+1
 Gear.Push(p);A.Economy(p,-C.Trap.Price,d.coins,"TrapPurchase");notice(p,"trapBought");return true
end
local function insideHouse(p)
 local r=root(p);if not r then return false end
 for _,plot in P.Plots do local v=plot.Base:PointToObjectSpace(r.Position);if math.abs(v.X)<24 and v.Z>26 and v.Z<62 and v.Y>0 and v.Y<14 then return true end end
 return false
end
function Gear.CanHitPlayer(p,other)
 if p==other or insideHouse(p) or insideHouse(other) then return false end
 if Road.IsOnRoad(p) and Road.IsOnRoad(other) then return true end
 if not require(script.Parent.DayNightService).State() then return false end
 local r=Raid.Carriers[other] or Raid.Pending[other]
 return r and P.Assigned[r.owner] and P.Inside(p,P.Assigned[r.owner]) and P.Inside(other,P.Assigned[r.owner]) or false
end
function Gear.Bat(p)
 local d=D.Profiles[p];if not d or d.activeSlot~=1 or not Actions.CanAct(p) or os.clock()<(Actions.State(p).switch or 0) then return false,'actionBlocked' end
 local now=os.clock();if now<(Gear.NextBat[p] or 0) then return false end
 local cfg=table.clone(Shovels[d.equippedShovel or 'Rusty']);if Road.Carriers[p] then cfg.Damage*=Shovels.CarryDamage;cfg.Knockout*=Shovels.CarryKnockout;cfg.Distance*=Shovels.CarryDistance end;Gear.NextBat[p]=now+cfg.Cooldown;Road.CancelPickup(p)
 p:SetAttribute('RoadBatUntil',workspace:GetServerTimeNow()+Shovels.Swing);p:SetAttribute('RoadBatReadyAt',workspace:GetServerTimeNow()+cfg.Cooldown)
 local character=p.Character;local swingAt=workspace:GetServerTimeNow()
 p:SetAttribute('ShovelSwingAt',swingAt)
 task.delay(Shovels.Windup,function()
  local r=root(p);if not r or p.Character~=character or p:GetAttribute('ShovelSwingAt')~=swingAt or not Actions.CanAct(p) or d.activeSlot~=1 then return end
  local targets={}
  local blockers={}
  for part in W.Colliders do if part.Parent and part.CanCollide and part.CanQuery then table.insert(blockers,part) end end
  local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include;ray.FilterDescendantsInstances=blockers
  local function consider(who,pos,mutant)
   if not ActionRules.InRadius(r.Position,pos,cfg.Range) then return end
   local hit=workspace:Raycast(r.Position,pos-r.Position,ray)
   if not hit then
    table.insert(targets,{who=who,mutant=mutant})
   end
  end
  for _,other in Players:GetPlayers() do
   if Gear.CanHitPlayer(p,other) and Actions.CanAct(other) and os.clock()>=(Actions.State(other).immune or 0) then
    local rr=root(other);if rr then consider(other,rr.Position,false) end
   end
  end
  local M=require(script.Parent.MutantService)
  for _,enemy in M.Live do
   if enemy.state~='Spawning' and enemy.hp>0 and enemy.model.PrimaryPart then consider(enemy,enemy.model.PrimaryPart.Position,true) end
  end
  -- Snapshot first: damage/removal must not mutate the enumeration. Each target is hit once.
  for _,entry in targets do
   local target=entry.who
   if entry.mutant then
    target.attack=nil;target.stunnedUntil=os.clock()+cfg.Knockout;target.model:SetAttribute('StunnedUntil',workspace:GetServerTimeNow()+cfg.Knockout);M.State(target,'Stunned');M.Damage(target,cfg.Damage,p)
   else
    local rr=root(target)
    if rr then
     local direction=rr.Position-r.Position
     local farm=not Road.IsOnRoad(target);if farm then Raid.Return(target) else Road.Drop(target) end
     Road.CancelPickup(target);target:SetAttribute('RoadPickupInterruptedAt',workspace:GetServerTimeNow());Actions.Knockout(target,cfg.Knockout,direction,cfg.Distance)
    end
   end
  end
 end)
 return true
end
local function removeTrap(t)
 Gear.Traps[t]=nil;if t.model then t.model:Destroy() end
end
function Gear.Place(p,target)
 local d=D.Profiles[p]
 if not d or not Actions.CanAct(p) or (not Road.IsOnRoad(p) and (not P.Assigned[p] or not P.Inside(p,P.Assigned[p]) or P.InHouse(p))) or Road.Carriers[p] then return false,"roadGearDenied" end
 if (d.traps or 0)<=0 then return false,"trapEmpty" end
 local count=0;for t in pairs(Gear.Traps) do if t.owner==p then count+=1 end end
 if count>=C.Trap.MaxPlaced then return false,"trapPlacedFull" end
 local r=root(p);local ahead=target or (r.Position+r.CFrame.LookVector*4)
 if typeof(ahead)~="Vector3" or ahead.X~=ahead.X or ahead.Y~=ahead.Y or ahead.Z~=ahead.Z or (ahead-r.Position).Magnitude>12 then return false,"trapBadSpot" end
 local s,x=Road.ToRoad(ahead)
 local onRoad=Road.IsOnRoad(p)
 if onRoad and (s<C.GateLine+12 or s>C.Length-5 or math.abs(x)>C.Width/2-4 or (s>C.Gap.From-4 and s<C.Gap.To+4)) then return false,"trapBadSpot" end
 local floors={};local area=onRoad and P.World.Road or P.Assigned[p].Model
 for _,part in area:GetDescendants() do if part:IsA('BasePart') and part.CanCollide and part.CanQuery then table.insert(floors,part) end end
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances=floors
 local hit=workspace:Raycast(Vector3.new(ahead.X,P.PlazaTop+3,ahead.Z),Vector3.new(0,-5,0),params)
 if not hit then return false,"trapBadSpot" end
 local pos=hit.Position
 if not onRoad then local localPos=P.Assigned[p].Base:PointToObjectSpace(pos);local half=require(RS.Shared.Config.ZoneConfig).FarmHalf-2;if math.abs(localPos.X)>half or math.abs(localPos.Z)>half or math.abs(pos.Y-P.PlazaTop)>2 then return false,"trapBadSpot" end end
 -- Must be reachable on the ground; no throwing through walls or placing while jumping.
 if math.abs(r.Position.Y-pos.Y)>5 or W.Raycast(r.Position,Vector3.new(pos.X,r.Position.Y,pos.Z)-r.Position) then return false,"trapBadSpot" end
 local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Include;overlap.FilterDescendantsInstances={P.World};overlap.RespectCanCollide=true
 if #workspace:GetPartBoundsInBox(CFrame.new(pos+Vector3.new(0,1.6,0)),Vector3.new(5,3,5),overlap)>0 then return false,"trapBadSpot" end
 for t in pairs(Gear.Traps) do if (t.pos-pos).Magnitude<C.Trap.Spacing then return false,"trapBadSpot" end end
 local now=os.clock();local model=Models.Trap(area,CFrame.new(pos))
 model:SetAttribute("Owner",p.UserId);model:SetAttribute("Armed",false)
 local t={owner=p,pos=pos,model=model,farm=not onRoad and p or nil,armedAt=now+C.Trap.Arm,expires=now+C.Trap.Lifetime}
 d.traps-=1;Gear.Traps[t]=true;Gear.Push(p);Road.CancelPickup(p);notice(p,"trapPlaced");return true,t
end
function Gear.Trigger(t,p)
 if not Gear.Traps[t] or os.clock()<t.armedAt or os.clock()>=t.expires or t.owner==p or not Road.Carriers[p] or not Actions.CanAct(p) or os.clock()<(Actions.State(p).immune or 0) then return false end
 local r=root(p);local pos=r and r.Position
 if not pos then return false end
 -- Contact is checked in Tick; this function has no remote entry point.
 Gear.Traps[t]=nil
 Models.CloseTrap(t.model);game.Debris:AddItem(t.model,.6)
 local dropped=Road.Drop(p);Road.Stun(p,C.Trap.Stun);notice(p,dropped and "trapCaughtDrop" or "trapCaught")
 return true
end
function Gear.Tick()
 local now=os.clock()
 for t in pairs(Gear.Traps) do
  if now>=t.expires or not t.owner.Parent then removeTrap(t)
  elseif now>=t.armedAt then
   if not t.model:GetAttribute("Armed") then t.model:SetAttribute("Armed",true);Models.ArmTrap(t.model) end
   for _,p in ipairs(Players:GetPlayers()) do
    local r=root(p)
    if r and p~=t.owner and Road.Carriers[p] and Actions.CanAct(p) then
     local pos=r.Position;local prev=Gear.Previous[p] or pos
     if (pos-prev).Magnitude>24 then prev=pos end -- do not sweep teleports
     local delta=Vector3.new(pos.X-prev.X,0,pos.Z-prev.Z)
     local offset=Vector3.new(t.pos.X-prev.X,0,t.pos.Z-prev.Z)
     local alpha=delta:Dot(delta)>.001 and math.clamp(offset:Dot(delta)/delta:Dot(delta),0,1) or 1
     local nearest=prev:Lerp(pos,alpha)
     if math.abs(nearest.Y-t.pos.Y)<=4.2 and (Vector3.new(nearest.X,0,nearest.Z)-Vector3.new(t.pos.X,0,t.pos.Z)).Magnitude<=C.Trap.Radius then Gear.Trigger(t,p);break end
    end
   end
  end
 end
 for _,p in ipairs(Players:GetPlayers()) do local r=root(p);Gear.Previous[p]=r and r.Position;Gear.Push(p) end
end
-- The player puts the carried grave down (button or G): it lies there for anyone, like one dropped on a faint.
-- Only on the road or inside a farm; on the plaza it would just vanish, so there the player keeps carrying it.
function Gear.DropGrave(p)
 if not Road.Carriers[p] then return false end
 local inFarm=false
 for _,plot in P.Assigned do if P.Inside(p,plot) then inFarm=true;break end end
 if not Road.IsOnRoad(p) and not inFarm then return false,"roadDropHere" end
 return Road.Drop(p,false)~=false
end
function Gear.Forget(p)
 for t in pairs(Gear.Traps) do if t.owner==p then removeTrap(t) end end
 Gear.NextBat[p]=nil;Gear.Requests[p]=nil;Gear.Previous[p]=nil
end
function Gear.Init()
 rem=RS.Remotes
 local action=Instance.new("RemoteEvent");action.Name="RoadAction";action.Parent=rem
 action.OnServerEvent:Connect(function(p,op,target,...)
  if select('#',...)~=0 or type(op)~="string" or (op~="bat" and op~="placeTrap" and op~="buyTrap" and op~="dropGrave") then return end
  if target~=nil and (op~="placeTrap" or typeof(target)~="Vector3") then return end
  local now=os.clock();if now-(Gear.Requests[p] or -math.huge)<.2 then return end;Gear.Requests[p]=now
  if op=="placeTrap" then local d=D.Profiles[p];if not d or d.activeSlot~=4 then return end end
  local ok,reason
  if op=="dropGrave" then ok,reason=Gear.DropGrave(p) elseif op=="bat" then ok,reason=Gear.Bat(p) elseif op=="placeTrap" then ok,reason=Gear.Place(p,target) else ok,reason=Gear.Buy(p) end
  if not ok and type(reason)=="string" then notice(p,reason) end
 end)
 Players.PlayerRemoving:Connect(Gear.Forget)
 task.spawn(function() while task.wait(.05) do local ok,err=pcall(Gear.Tick);if not ok then warn("Road gear tick failed",err) end end end)
end
return Gear
