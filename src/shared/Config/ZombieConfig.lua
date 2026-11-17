-- Display rarity follows the archetype; existing income grades stay intact.
-- The rotation (owner, 2026-11-13): six rarities, one look each - Farmer (Common), Miner (Uncommon), Punk (Rare),
-- Knight (Epic), Assassin (Legendary), King (Mythic). Bigger rarities are much bigger (RaritySize).
-- The families of 2026-11-14 (MonsterFamilies) bring one look per rarity each (a Princess instead of a King for some).
local NF=require(script.Parent.MonsterFamilies)
local families={"Deer","Parasite","Stalker","Verity","RingMaw","CaveDweller"}
local function all(look,extra)
 local list={};for _,f in families do table.insert(list,f..look) end
 for _,id in extra or {} do table.insert(list,id) end
 local tier=table.find(NF.Looks,look)
 for _,id in NF.Tier(tier) do table.insert(list,id) end
 return list
end
return {Tiers={"Common","Uncommon","Rare","Epic","Legendary","Mythic"}, Income={1,4,15,60,250,1200},
 Types={all("Farmer"),all("Miner"),all("Punk"),all("Knight",{"SirenHead"}),all("Assassin",{"BuckshotDealer","SirenHead"}),all("King",{"BuckshotDealer"})},
 -- No mutations since 2026-11-15 (owner: "remove them, labels as agreed: Farmer Common, Miner Uncommon..."): the chances
 -- are 0 and ProfileV3 clears the ones already hatched; the multipliers stay for old code paths.
 Mutations={None=1,Golden=2,Lunar=3,Rainbow=10}, RainbowChance=0,LunarChance=0,GoldenChance=0,SaleSeconds=30,
 RaritySize={1,1.15,1.32,1.52,1.75,2.05},
 Stars={Max=3,Income={1,3.5,12},Power={1,1.5,2},Size={1,1.15,1.3}}} -- merging: income, guard and digger strength, model size per star
