-- Graves and what hatches from them. Weights are the chances of the six monster tiers (ZombieConfig: 1-2 farmers,
-- Common; 3-4 punks, Rare; 5-6 assassins, Epic). MinTier is the floor (owner, 2026-11-13: "minimum drops by rarity,
-- a rare grave can give a farmer now"): a Marble (rare) grave gives at least a punk, a Lunar (epic) one an assassin.
return {
    ShopOrder={},
    Order={"Wooden","Stone","Marble","Golden","Lunar"},
    Wooden={Price=100,Seconds=60,Weights={70,25,5,0,0,0},MinTier=1,Chance=1,Min=999,Max=999},
    Stone={Price=1500,Seconds=300,Weights={0,80,15,5,0,0},MinTier=2,Chance=.8,Min=1,Max=3},
    Marble={Price=20000,Seconds=1200,Weights={0,0,62,30,7,1},MinTier=3,Chance=.35,Min=1,Max=2},
    Golden={Price=300000,Seconds=3600,Weights={0,0,0,62,30,8},MinTier=4,Chance=.08,Min=1,Max=1},
    Lunar={Price=1000000,Seconds=7200,Weights={0,0,0,0,78,22},MinTier=5,Chance=.25,Min=1,Max=1,NightOnly=true},
}
