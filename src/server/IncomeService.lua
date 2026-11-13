local Z=require(script.Parent.ZombieService);local R=require(game.ReplicatedStorage.Shared.Config.RewardConfig)
local I={}
-- Income earned while away goes onto the heap on the farm (owner, 2026-11-12), the same money the farm piles up
-- online: no claim button in the rewards menu any more. An old unclaimed offlinePending moves onto the heap once.
-- Returns what the absence earned, so the join can tell the player where the money waits.
function I.Offline(d)
 local seconds=math.clamp(os.time()-(d.lastSeenAt or os.time()),0,R.OfflineCap)
 local earned=math.floor(Z.Income(d,true)*seconds*R.OfflineRate)
 local carried=type(d.offlinePending)=="number" and d.offlinePending==d.offlinePending and math.max(0,d.offlinePending) or 0
 local bank=type(d.farmBank)=="number" and d.farmBank==d.farmBank and math.max(0,d.farmBank) or 0
 d.farmBank=bank+earned+carried;d.offlinePending=0;d.lastSeenAt=os.time()
 return earned+carried
end
-- While the owner plays, income goes straight into the wallet (owner, 2026-11-13: "money should drip onto the
-- account, not pile up by the house"). Only what the farm made while they were away waits on the heap (BankService).
-- The newcomer's boost (NewbieConfig): the multiplier now and the played seconds until it steps down or ends.
function I.Boost(d)
 local played=d.playTime or 0
 for _,stage in ipairs(require(game.ReplicatedStorage.Shared.Config.NewbieConfig).Stages) do
  if played<stage.Until then return stage.Income,stage.Until-played end
 end
 return 1,0
end
function I.Tick(d) local n=Z.Income(d)*I.Boost(d);d.coins+=n;d.playTime+=1;d.lastSeenAt=os.time();return n end
return I
