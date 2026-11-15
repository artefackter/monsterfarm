-- The families added on 2026-11-14 (owner: "new monsters - Granny, Grandpa, Slendrina, Slenderman, Slendrina's Mom,
-- new parasites, Longmaw, the Stranger, the Mimic - with their icons and all their looks"). Unlike the first six
-- families (whose Miner, Knight and King are outfits over another look), each of these has a model of its own for every
-- rarity: art/*-optimized-v1, made rigid by art/roblox-import-v1 (ReplicatedStorage.ArtModels, named like the id).
-- The new parasites are the SRP four (art/srp-optimized-v1). Pure data: MonsterCollection, ZombieConfig and Locale
-- read it.
local F = {}

-- dex order
F.Order = {
	"Granny", "Grandfather", "Slenderman", "Slendrina", "SpiderMom", "Longmaw", "HoodedStranger", "Mimic",
	"AdaptedViscera", "AssimilatedAdventurer", "Dredge", "PrimitiveSummoner",
}

-- one look per rarity, Common .. Mythic; the Mythic look is a Princess for the women
F.Looks = { "Farmer", "Miner", "Punk", "Knight", "Assassin", "King" }
F.Princess = { Granny = true, Slendrina = true, SpiderMom = true, Longmaw = true, Mimic = true }

-- names, English and Russian (the owner's names where given)
F.Names = {
	Granny = { "Granny", "Гренни" },
	Grandfather = { "Grandpa", "Дед" },
	Slenderman = { "Slenderman", "Слендермен" },
	Slendrina = { "Slendrina", "Слендерина" },
	SpiderMom = { "Slendrina's Mom", "Мама Слендерины" },
	Longmaw = { "Longmaw", "Длиннорот" },
	HoodedStranger = { "Stranger", "Незнакомец" },
	Mimic = { "Mimic", "Мимик" },
	AdaptedViscera = { "Viscera", "Висцера" },
	AssimilatedAdventurer = { "Assimilant", "Ассимилянт" },
	Dredge = { "Dredge", "Дредж" },
	PrimitiveSummoner = { "Summoner", "Призыватель" },
}
F.LookNames = {
	Farmer = { "Farmer", "Фермер" },
	Miner = { "Miner", "Шахтёр" },
	Punk = { "Punk", "Нефор" },
	Knight = { "Knight", "Рыцарь" },
	Assassin = { "Assassin", "Убийца" },
	King = { "King", "Король" },
	Princess = { "Princess", "Принцесса" },
}

function F.Look(family, tier)
	local look = F.Looks[tier]
	if look == "King" and F.Princess[family] then
		return "Princess"
	end
	return look
end

function F.Id(family, tier)
	return family .. F.Look(family, tier)
end

-- every new id of a rarity, in dex order
function F.Tier(tier)
	local list = {}
	for _, family in F.Order do
		table.insert(list, F.Id(family, tier))
	end
	return list
end

return F
