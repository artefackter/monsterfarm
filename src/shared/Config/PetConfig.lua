-- Pets v3 (owner, 2026-11-12): the old pets are gone, and pets no longer follow the player — each lives on the farm
-- its own way (PetVisuals):
--   DragonHead  patrols the farm and breathes fire on whatever attacks it (PetService; Power = damage a breath)
--   BedBanker   sits by the zombucks heap and multiplies the farm's income (Power = multiplier)
--   FacepalmCat everyone's starter: walks along the top of the fence and is cute. Takes no slot, can't be released.
-- Pumpkins hatch the Order species with Weights; Removed species are refunded at their Release price on load.
return {
 Version=3,StartSlots=2,MaxSlots=4,Inventory=30,
 IncomeCap=.6,GraveCap=.7,GuardCap=.9,LuckCap=2,MinCarryPenalty=.05,
 Poll=.2,RemoteInterval=.2,ViewDistance=220,
 Release={500,2000,8000,30000,120000},
 Order={"DragonHead","BedBanker"},Weights={55,45},
 Starter="FacepalmCat",
 Priority={DragonHead=1,BedBanker=2,FacepalmCat=3},
 Tiers={"Common","Uncommon","Rare","Epic","Legendary"},
 Power={DragonHead={14,22,34,52,80},BedBanker={1.1,1.13,1.17,1.22,1.3},FacepalmCat={0,0,0,0,0}},
 DragonCooldown=2,DragonReach=14, -- seconds between breaths; how far beyond the fence it still reaches
 Removed={FarmerCat=true,DiggerMole=true,CoinHen=true,LuckyOwl=true,GuardDog=true,BanditBat=true},
 DebugMaxCoins=100000000,SoundVolume=.4,
}
