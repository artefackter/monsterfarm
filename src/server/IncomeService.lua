local Z=require(script.Parent.ZombieService);local R=require(game.ReplicatedStorage.Shared.Config.RewardConfig)
local I={}
function I.Offline(d) local seconds=math.clamp(os.time()-(d.lastSeenAt or os.time()),0,R.OfflineCap);d.offlinePending=(d.offlinePending or 0)+math.floor(Z.Income(d,true)*seconds*R.OfflineRate);d.lastSeenAt=os.time() end
-- Income goes to the heap on the farm (BankService), not to the wallet: the owner collects it there.
-- The newcomer's boost (NewbieConfig): the multiplier now and the played seconds until it steps down or ends.
function I.Boost(d)
 local played=d.playTime or 0
 for _,stage in ipairs(require(game.ReplicatedStorage.Shared.Config.NewbieConfig).Stages) do
  if played<stage.Until then return stage.Income,stage.Until-played end
 end
 return 1,0
end
function I.Tick(d) local n=Z.Income(d)*I.Boost(d);d.farmBank=(d.farmBank or 0)+n;d.playTime+=1;d.lastSeenAt=os.time();return n end
return I

