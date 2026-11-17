-- Idempotent profile migration. DataStore names and existing balances/IDs stay intact.
local S=script.Parent;local H=game:GetService("HttpService")
local R={Version=9}
function R.Migrate(d)
 d.upgrades=d.upgrades or {};d.zombies=d.zombies or {};d.graves=d.graves or {};d.vouchers=d.vouchers or {}
 if not d.v3DiggersRefunded then
  local levels=tonumber(d.upgrades.Diggers) or 0;if levels~=levels then levels=0 end;levels=math.clamp(math.floor(levels),0,4);local refund=0
  for level=0,levels-1 do refund+=2500*3^level end
  d.coins=(d.coins or 0)+refund;d.diggerRefund=refund;d.v3DiggersRefunded=true
 end
 d.upgrades.Diggers=nil
 local used={};for _,z in d.zombies do if z.zone=="Crypt" then used[z.slot]=true end end
 for _,z in d.zombies do if z.zone=="Diggers" then local slot=1;while used[slot] do slot+=1 end;z.zone="Crypt";z.slot=slot;used[slot]=true end end
 require(S.WeaponRules).Migrate(d)
 d.shovels=type(d.shovels)=="table" and d.shovels or {} -- (the starter weapon and the old shovels: ActionRules.Migrate)
 d.dexClaims=type(d.dexClaims)=="table" and d.dexClaims or {};d.freeGiftClaimed=d.freeGiftClaimed==true;d.slowMode=d.slowMode==true
 if type(d.speedPoints)~="number" or d.speedPoints~=d.speedPoints or math.abs(d.speedPoints)==math.huge then
  local speed=tonumber(d.speed) or 16;if speed~=speed then speed=16 end;speed=math.clamp(speed,16,75);d.speedPoints=math.ceil(100*(10^((speed-16)/8.8)-1))
 end
 -- never below the starting speed (owner, 2026-11-15: 900, not 0); speed points only ever grow, so this lifts
 -- only profiles made before it
 d.speedPoints=math.max(require(S.Config.ShopConfig).StartingSpeed or 0,math.floor(d.speedPoints))
 -- no mutations any more (2026-11-15): Golden, Lunar and Rainbow monsters become plain ones
 for _,z in d.zombies do if z.mutation~=nil and z.mutation~="None" then z.mutation="None" end end
 d.graveInventory=type(d.graveInventory)=="table" and d.graveInventory or {}
 for _,list in {d.graves,d.graveInventory} do for _,g in list do g.id=g.id or H:GenerateGUID(false) end end
 -- steps 0-8 (4-8, the gunsmith, the workbench and three upgrades, since 2026-11-15: TutorialService); 9 is done
 if d.tutorialDone then d.tutorialStep=9 else d.tutorialStep=math.clamp(d.tutorialStep or 0,0,8) end
 if not d.tutorialDone and d.tutorialStep==3 then
  local delivered=false;for _,g in d.graveInventory do if g.fromRoad then delivered=true end end
  if not delivered then d.tutorialStep=2 end -- a disconnected carrier must be able to restart
 end
 if d.quests and d.quests.items then for _,q in d.quests.items do if q.id=="buy" or q.id=="buyGrave" then q.id="road" end end end
 require(S.ActionRules).Migrate(d)
 d.version=math.max(d.version or 1,R.Version);return d
end
return R
