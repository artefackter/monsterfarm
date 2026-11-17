-- Grave theft between farms was taken out (owner, 2026-11-13): nothing starts a raid any more; what is left returns
-- graves still in flight from older servers and backs the shared carry checks (Raid.Carriers). Grave-only theft; recipient intent and the existing ownership journal survive interrupted transfers.
local S=game.ReplicatedStorage.Shared
local D=require(script.Parent.DataService);local P=require(script.Parent.PlotService);local G=require(script.Parent.GraveService);local Day=require(script.Parent.DayNightService)
local C=require(S.Config.NightConfig);local Zone=require(S.Config.ZoneConfig);local Rules=require(S.RoadRules)
local Pets=require(script.Parent.PetService);local PC=require(S.Config.PetConfig)
local R={Carriers={},Active={},Cooldown={},Shields={},Locks={},LockCooldown={},Pending={}};local rng=Random.new()
local function road() return require(script.Parent.RoadService) end
local function root(p) return p.Character and p.Character:FindFirstChild("HumanoidRootPart") end
function R.CanStart(p,owner,g)
 local td,od=D.Profiles[p],D.Profiles[owner];local night,_,cycle=Day.State()
 if require(script.Parent.IncomeService).IsNewbie(td) then return false end
 if not td or not od or p==owner or not night or R.Carriers[p] or p:GetAttribute("CarryingGrave") or road().Blocked(p) or g.starter or g.carriedBy or g.pendingTransfer or not table.find(od.graves,g) or od.playTime<C.Newbie or R.Shields[owner]==cycle or (R.Cooldown[p] or 0)>os.clock() or (R.Locks[owner] or 0)>os.clock() then return false end
 for _,r in R.Active do if r.owner==owner then return false end end
 local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
 return h and h.Health>0 and P.Near(p,P.Position(owner,"Graves",g.slot).Position,C.Distance) and not P.InHouse(p)
end
-- Newcomers (the boost, IncomeService.IsNewbie) can't steal graves (owner, 2026-11-13).
local function newbie(p) return require(script.Parent.IncomeService).IsNewbie(D.Profiles[p]) end
function R.Begin(p,owner,g)
 do return false end -- theft between farms is off (2026-11-13)
 if newbie(p) then game.ReplicatedStorage.Remotes.Notice:FireClient(p,"stealNewbie");return false end
 if not R.CanStart(p,owner,g) then return false end
 local need=road().HoldFor(p,C.StealHold) -- slower after shoving someone on the road
 R.Pending[p]={owner=owner,g=g,began=os.clock(),need=need};require(script.Parent.ActionService).Dig(p,need);return true
end
function R.Cancel(p) R.Pending[p]=nil;require(script.Parent.ActionService).CancelDig(p) end
function R.End(p) local h=R.Pending[p];if h then h.ended=os.clock() end end
function R.Complete(p,owner,g)
 local h=R.Pending[p];R.Cancel(p)
 if not h or h.owner~=owner or h.g~=g or (h.ended or os.clock())-h.began<(h.need or C.StealHold)-.15 or (h.ended and os.clock()-h.ended>.2) then return false end
 return R.Start(p,owner,g)
end
function R.Adopt(p,r)
 if not R.Active[r.g.id] or r.transferring or R.Carriers[p] or road().Carriers[p] then return false end
 r.holder=p;r.drop=nil;r.taken=os.clock();r.from=root(p).Position;r.last=r.from;r.lastAt=r.taken;r.checked=false
 R.Carriers[p]=r;r.g.carriedBy=p.UserId;road().Carry(p,r.g.type,r);return true
end
function R.Start(p,owner,g)
 if not R.CanStart(p,owner,g) then return false end
 local r={owner=owner,g=g,progress=G.Progress(D.Profiles[owner],g)};R.Active[g.id]=r
 R.Adopt(p,r);G.Render(owner,D.Profiles[owner]);return true
end
function R.ReturnRecord(r)
 if not r or r.transferring or not R.Active[r.g.id] then return false end
 local from=r.holder and root(r.holder) and root(r.holder).Position
 if r.holder then local p=r.holder;R.Carriers[p]=nil;road().Release(p);R.Cancel(p) end
 if r.drop then road().Drops[r.drop]=nil;if r.drop.Model then r.drop.Model:Destroy();r.drop.Model=nil end end
 r.g.carriedBy=nil;R.Active[r.g.id]=nil
 if D.Profiles[r.owner] and P.Assigned[r.owner] then
  G.Render(r.owner,D.Profiles[r.owner]);local m=G.Models[r.owner] and G.Models[r.owner][r.g.slot]
  if m and from then m:SetAttribute("ReturnFrom",from);m:SetAttribute("ReturnAt",workspace:GetServerTimeNow()) end
 end
 return true
end
function R.Return(p) return R.ReturnRecord(R.Carriers[p]) end
function R.Detach(p,spot)
 local r=R.Carriers[p];if not r then return end
 R.Carriers[p]=nil;r.holder=nil;r.drop=spot;r.g.carriedBy=0;spot.Farm=r
end
function R.Transfer(p,r)
 local td,od=D.Profiles[p],D.Profiles[r.owner];local rr=root(p)
 if r.transferring or R.Carriers[p]~=r or not td or not od or not rr or not P.Assigned[p] or not P.Near(p,P.Assigned[p].Gate.Position,Zone.GateRadius) then return false end
 if r.invalid or not Rules.HonestTrip((rr.Position-r.from).Magnitude,Rules.Speed(td),r.g.type,os.clock()-r.taken) then R.Return(p);return false end
 r.transferring=true
 local copy={id=r.g.id,type=r.g.type,monsterType=r.g.monsterType,location=r.g.location,family=r.g.family,progress=r.progress,pendingTransfer=true};table.insert(td.graveInventory,copy)
 if not D.Save(r.owner) or not D.Save(p) or not D.SetOwner("grave_"..copy.id,r.owner.UserId,p.UserId) then
  table.remove(td.graveInventory,table.find(td.graveInventory,copy));r.transferring=false;R.Return(p);return false
 end
 local i=table.find(od.graves,r.g);if i then table.remove(od.graves,i) end
 copy.pendingTransfer=nil;r.g.carriedBy=nil;R.Carriers[p]=nil;R.Active[r.g.id]=nil;road().Release(p)
 local _,_,cycle=Day.State();R.Shields[r.owner]=cycle
 G.Select(p,copy.id);G.Render(r.owner,od);require(script.Parent.SlotService).Forget(r.owner)
 D.Save(p);D.Save(r.owner);return true
end
function R.GuardChance(owner)
 local d=D.Profiles[owner];if not d then return 0 end
 local chance=0 -- Collection monsters produce income; pet bonuses still apply.
 return math.min(PC.GuardCap,chance+Pets.GetBonuses(owner).guardPct)
end
function R.Catch(p)
 if not R.Carriers[p] then return false end
 R.Return(p);road().Stun(p,1);R.Cooldown[p]=os.clock()+C.RaidCooldown
 game.ReplicatedStorage.Remotes.Notice:FireClient(p,"caught");return true
end
function R.Tick()
 local night=Day.State();local now=os.clock()
 for p,h in R.Pending do if not R.CanStart(p,h.owner,h.g) or now-h.began>C.StealHold+3 or h.ended and now-h.ended>.2 then R.Cancel(p) end end
 for _,r in R.Active do
  local p=r.holder
  if not night or not D.Profiles[r.owner] then R.ReturnRecord(r)
  elseif p and not r.transferring then
   local rr=root(p);local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
   if not rr or not h or h.Health<=0 or not D.Profiles[p] then R.Return(p)
   else
    local elapsed=now-(r.lastAt or r.taken);local speed=Rules.Speed(D.Profiles[p])
    if (rr.Position-r.last).Magnitude>speed*math.max(.1,elapsed)*1.8+8 then r.invalid=true end;r.last=rr.Position;r.lastAt=now
    if r.invalid then R.Return(p);continue end
    if not r.checked and not P.Inside(p,P.Assigned[r.owner]) then r.checked=true;if rng:NextNumber()<R.GuardChance(r.owner) then R.Catch(p) end end
    if R.Carriers[p] and P.Near(p,P.Assigned[p].Gate.Position,Zone.GateRadius) then task.spawn(R.Transfer,p,r) end
   end
  end
 end
end
function R.Leave(p)
 R.Cancel(p);R.Return(p);for _,r in R.Active do if r.owner==p then R.ReturnRecord(r) end end
 while true do local busy=false;for _,r in R.Active do if r.transferring and (r.holder==p or r.owner==p) then busy=true end end;if not busy then break end;task.wait(.1) end
end
return R
