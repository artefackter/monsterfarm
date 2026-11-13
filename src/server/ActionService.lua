-- Server-owned equipment, knockout, immunity and digging state. Attributes are presentation only.
local S=game.ReplicatedStorage.Shared;local C=require(S.Config.ShovelConfig);local Rules=require(S.ActionRules)
local D=require(script.Parent.DataService);local P=require(script.Parent.PlotService)
local A={States={},Requests={}}
function A.State(p) local s=A.States[p];if not s then s={};A.States[p]=s end;return s end
function A.Blocked(p) return os.clock()<(A.State(p).knockout or 0) end
function A.CanAct(p)
 local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
 return D.Profiles[p]~=nil and h and h.Health>0 and not A.Blocked(p)
end
function A.Ready(p) return A.CanAct(p) and os.clock()>=(A.State(p).switch or 0) and not A.State(p).dig end
function A.Push(p)
 local d=D.Profiles[p];if not d then return end
 p:SetAttribute('ActiveSlot',d.activeSlot);p:SetAttribute('EquippedShovel',d.equippedShovel);p:SetAttribute('SlowMode',d.slowMode);p:SetAttribute('ShowRanges',d.showRanges)
 p:SetAttribute('SpeedPoints',d.speedPoints or 0)
end
function A.Dig(p,duration)
 if not A.CanAct(p) then return false end
 local s=A.State(p);s.dig=os.clock()+duration+3
 p:SetAttribute('DiggingGrave',true);p:SetAttribute('DigStartedAt',workspace:GetServerTimeNow());p:SetAttribute('DigDuration',duration)
 p:SetAttribute('CombatAimUntil',0);return true
end
function A.CancelDig(p) A.State(p).dig=nil;p:SetAttribute('DiggingGrave',false) end
function A.Slow(p)
 local s=A.State(p);local c=require(S.Config.RoadConfig);s.slow=os.clock()+c.HitSlowDuration
 p:SetAttribute('MutantSlowUntil',workspace:GetServerTimeNow()+c.HitSlowDuration)
end
function A.Knockout(p,duration,direction,distance)
 if not A.CanAct(p) then return false end
 local s=A.State(p);local now=os.clock();if now<(s.immune or 0) then return false end
 local ch=p.Character;local root=ch:FindFirstChild('HumanoidRootPart');local h=ch:FindFirstChildOfClass('Humanoid');if not root then return false end
 s.knockout=now+duration;s.immune=s.knockout+C.Immunity;local token={};s.token=token
 require(script.Parent.RoadService).CancelPickup(p);A.CancelDig(p)
 p:SetAttribute('KnockedOutAt',workspace:GetServerTimeNow());p:SetAttribute('KnockedOutUntil',workspace:GetServerTimeNow()+duration);p:SetAttribute('KnockImmuneUntil',workspace:GetServerTimeNow()+duration+C.Immunity);p:SetAttribute('RoadStunnedUntil',workspace:GetServerTimeNow()+duration)
 p:SetAttribute('CombatAimUntil',0);p:SetAttribute('Training',false)
 s.jumpPower=h.JumpPower;s.jumpHeight=h.JumpHeight;s.autoRotate=h.AutoRotate
 h.Jump=false;h.WalkSpeed=0;h.JumpPower=0;h.JumpHeight=0;h.AutoRotate=false;h.PlatformStand=true
 local flat=Vector3.new(direction.X,0,direction.Z);flat=flat.Magnitude>.01 and flat.Unit or Vector3.new(0,0,-1)
 pcall(function() root:SetNetworkOwner(nil) end)
 local attachment=Instance.new('Attachment',root);local v=Instance.new('LinearVelocity');v.Attachment0=attachment;v.RelativeTo=Enum.ActuatorRelativeTo.World;v.VectorVelocity=flat*(distance/C.KnockFlight)+Vector3.new(0,9,0);v.ForceLimitsEnabled=false;v.Parent=root
 game.Debris:AddItem(v,C.KnockFlight);game.Debris:AddItem(attachment,C.KnockFlight+.02)
 task.delay(duration,function()
  if s.token~=token or p.Character~=ch or not h.Parent then return end
  h.PlatformStand=false;h.AutoRotate=s.autoRotate~=false;h.JumpPower=s.jumpPower;h.JumpHeight=s.jumpHeight;h:ChangeState(Enum.HumanoidStateType.GettingUp)
  pcall(function() root:SetNetworkOwner(p) end)
 end)
 return true
end
-- Slot 0 is empty hands (owner, 2026-11-13). Picking any slot puts a monster you were carrying back in the crypt.
function A.Select(p,slot)
 if not A.CanAct(p) or (slot~=0 and slot~=1 and slot~=2 and slot~=3 and slot~=4) then return false end
 local Z=require(script.Parent.ZombieService);if Z.Holding[p] then Z.Drop(p) end
 local d=D.Profiles[p];if d.activeSlot==slot then return true end
 require(script.Parent.RoadService).CancelPickup(p);local s=A.State(p);s.switch=os.clock()+C.Switch
 -- Slot 3 holds graves, slot 4 traps: each has its own key and button.
 if slot==4 then d.selectedItem='trap';d.selectedGrave=nil;p:SetAttribute('SelectedGrave',nil);p:SetAttribute('SelectedItem','trap')
 elseif d.selectedItem=='trap' then d.selectedItem=nil;p:SetAttribute('SelectedItem',nil) end
 d.activeSlot=slot;p:SetAttribute('WeaponDrawUntil',workspace:GetServerTimeNow()+C.Switch);p:SetAttribute('CombatAimUntil',0)
 local W=require(script.Parent.WeaponService);W.Session(p).holstered=slot~=2;W.Push(p);A.Push(p);return true
end
-- Taking a monster in your arms empties your hands (ZombieService.Hold): the gun goes on your back.
function A.Empty(p)
 local d=D.Profiles[p];if not d or d.activeSlot==0 then return end
 require(script.Parent.RoadService).CancelPickup(p)
 if d.selectedItem=='trap' then d.selectedItem=nil;p:SetAttribute('SelectedItem',nil) end
 d.activeSlot=0;p:SetAttribute('CombatAimUntil',0)
 local W=require(script.Parent.WeaponService);W.Session(p).holstered=true;W.Push(p);A.Push(p)
end
function A.ChooseShovel(p,id,buy)
 local d=D.Profiles[p];local cfg=C[id];if not A.CanAct(p) or not cfg or not table.find(C.Order,id) or not require(script.Parent.InterfaceService).NearZone(p,"traps") then return false end
 if buy then if not cfg.Price or d.shovels[id] or d.coins<cfg.Price then return false end;d.coins-=cfg.Price;d.shovels[id]=true;d.equippedShovel=Rules.Best(d)
 else if not d.shovels[id] then return false end;d.equippedShovel=id end
 A.Push(p);return true
end
function A.Init()
 local function watch(p)
  p.CharacterAdded:Connect(function() A.States[p]=nil;p:SetAttribute('KnockedOutUntil',0);p:SetAttribute('KnockImmuneUntil',0);p:SetAttribute('RoadStunnedUntil',0);p:SetAttribute('MutantSlowUntil',0);A.CancelDig(p);A.Push(p) end)
 end
 game.Players.PlayerAdded:Connect(watch);for _,p in game.Players:GetPlayers() do watch(p) end
 local rem=game.ReplicatedStorage.Remotes;local event=Instance.new('RemoteEvent');event.Name='EquipmentAction';event.Parent=rem
 event.OnServerEvent:Connect(function(p,op,arg,...)
  if select('#',...)>0 or type(op)~='string' or #op>20 or (arg~=nil and type(arg)~='string') or (arg and #arg>30) then return end
  local now=os.clock();if now-(A.Requests[p] or -100)<.15 then return end;A.Requests[p]=now
  local d=D.Profiles[p];if not d or not A.CanAct(p) then return end
  if op=='slot' then A.Select(p,tonumber(arg))
  elseif op=='slow' then d.slowMode=not d.slowMode;A.Push(p)
  elseif op=='ranges' then d.showRanges=not d.showRanges;d.settings.ShowRanges=d.showRanges;A.Push(p)
  elseif op=='buyShovel' then A.ChooseShovel(p,arg,true)
  elseif op=='shovel' then A.ChooseShovel(p,arg,false) end
 end)
 game.Players.PlayerRemoving:Connect(function(p) A.States[p]=nil;A.Requests[p]=nil end)
end
return A
