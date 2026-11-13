-- Prestige (PrestigeRules): the farm starts over, the income multiplier grows for good. Refused while anything is
-- in flight (a carried grave or monster, a raid), so nothing can be lost halfway.
local Players=game:GetService("Players");local RS=game.ReplicatedStorage;local S=RS.Shared
local PR=require(S.PrestigeRules);local GC=require(S.Config.GraveConfig);local SC=require(S.Config.ShopConfig)
local D=require(script.Parent.DataService)
local Pr={}
local function notice(p,key,args) RS.Remotes.Notice:FireClient(p,key,args) end
function Pr.Busy(p,d)
 local Road=require(script.Parent.RoadService);local Raid=require(script.Parent.RaidService);local Z=require(script.Parent.ZombieService)
 if Road.Carriers[p] or Raid.Carriers[p] or Z.Holding[p] then return true end
 for _,r in Raid.Active do if r.owner==p then return true end end
 for _,z in d.zombies do if z.carriedBy or z.pendingTransfer then return true end end
 for _,g in d.graveInventory or {} do if g.pendingTransfer then return true end end
 return false
end
function Pr.Do(p)
 local d=D.Profiles[p];if not d then return false end
 local UI=require(script.Parent.InterfaceService)
 local q=UI.Quote(p,"Prestige");if not q or not q.afford then return false end
 if Pr.Busy(p,d) then return false,"prestigeBusy" end
 local Z=require(script.Parent.ZombieService);local G=require(script.Parent.GraveService);local M=require(script.Parent.MutantService)
 -- the farm goes: monsters, graves, coffins, the heap, the house and the treadmill back to level 1
 M.ClearOwner(p)
 for _,z in d.zombies do Z.Remove(z.id);D.Claims[z.id]=nil end
 d.zombies={}
 d.graves={{type="Wooden",slot=1,plantedAt=os.time()-GC.Wooden.Seconds,starter=true}}
 d.graveInventory={};d.vouchers={};d.selectedGrave=nil;p:SetAttribute("SelectedGrave",nil)
 d.coins=SC.StartingCoins;d.farmBank=0;d.offlinePending=0
 d.houseLevel=1;d.houseEnds=nil;d.treadmill=1;d.upgrades={};d.fenceLevel=1
 d.prestige=PR.Level(d)+1
 -- redraw everything that showed the old farm
 G.Render(p,d);Z.Render(p,d);require(script.Parent.SlotService).Render(p,d)
 require(script.Parent.BankService).Add(p,d,0)
 require(script.Parent.HouseService).Refresh(p,d);require(script.Parent.FenceService).Join(p,d)
 D.Save(p)
 local n=d.prestige;local mult=PR.Mult(d)
 notice(p,"prestigeDone",{n=n,m=mult})
 for _,other in Players:GetPlayers() do if other~=p then notice(other,"prestigeAll",{name=p.DisplayName,n=n}) end end
 pcall(function() game:GetService("AnalyticsService"):LogCustomEvent(p,"Prestige",n) end)
 return true
end
return Pr
