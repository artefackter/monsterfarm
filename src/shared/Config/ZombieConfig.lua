-- Display rarity follows the archetype; existing income grades stay intact.
-- The rotation (owner, 2026-11-13): six rarities, one look each - Farmer (Common), Miner (Uncommon), Punk (Rare),
-- Knight (Epic), Assassin (Legendary), King (Mythic). Bigger rarities are much bigger (RaritySize).
local families={"Deer","Parasite","Stalker","Verity","RingMaw","CaveDweller"}
local function all(look,extra)
 local list={};for _,f in families do table.insert(list,f..look) end
 for _,id in extra or {} do table.insert(list,id) end
 return list
end
return {Tiers={"Common","Uncommon","Rare","Epic","Legendary","Mythic"}, Income={1,4,15,60,250,1200},
 Types={all("Farmer"),all("Miner"),all("Punk"),all("Knight",{"SirenHead"}),all("Assassin",{"BuckshotDealer","SirenHead"}),all("King",{"BuckshotDealer"})},
 Mutations={None=1,Golden=2,Lunar=3,Rainbow=10}, RainbowChance=.005,LunarChance=.1,GoldenChance=.05,SaleSeconds=30,
 RaritySize={1,1.15,1.32,1.52,1.75,2.05},
 Stars={Max=3,Income={1,3.5,12},Power={1,1.5,2},Size={1,1.15,1.3}}} -- merging: income, guard and digger strength, model size per star
