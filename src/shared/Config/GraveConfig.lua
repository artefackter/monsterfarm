-- Graves and what hatches from them. Weights are the chances of the six monster tiers (ZombieConfig: 1-2 farmers,
-- Common; 3-4 punks, Rare; 5-6 assassins, Epic). MinTier is the floor (owner, 2026-11-13: "minimum drops by rarity,
-- a rare grave can give a farmer now"): a Marble (rare) grave gives at least a punk, a Lunar (epic) one an assassin.
return {
    ShopOrder={},
    -- Emo, Military and Ghost (owner, 2026-11-14): more kinds between Golden and Lunar, each a little likelier to give
    -- the rarer tiers than the one before.
    Order={"Wooden","Stone","Marble","Golden","Emo","Military","Ghost","Lunar"},
    Wooden={Price=100,Seconds=60,Weights={70,25,5,0,0,0},MinTier=1,Chance=1,Min=999,Max=999},
    Stone={Price=1500,Seconds=300,Weights={0,80,15,5,0,0},MinTier=2,Chance=.8,Min=1,Max=3},
    Marble={Price=20000,Seconds=1200,Weights={0,0,62,30,7,1},MinTier=3,Chance=.35,Min=1,Max=2},
    Golden={Price=300000,Seconds=3600,Weights={0,0,0,62,30,8},MinTier=4,Chance=.08,Min=1,Max=1},
    Emo={Price=400000,Seconds=4200,Weights={0,0,0,52,38,10},MinTier=4,Chance=.07,Min=1,Max=1},
    Military={Price=550000,Seconds=5000,Weights={0,0,0,42,45,13},MinTier=4,Chance=.06,Min=1,Max=1},
    Ghost={Price=750000,Seconds=6000,Weights={0,0,0,30,52,18},MinTier=4,Chance=.05,Min=1,Max=1},
    Lunar={Price=1000000,Seconds=7200,Weights={0,0,0,0,78,22},MinTier=5,Chance=.25,Min=1,Max=1,NightOnly=true},
}
