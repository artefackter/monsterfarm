-- Which monsters come out of a location's graves (owner, 2026-11-14: "a location has its own set — the forest gives the
-- deer and the cave dweller, and so on"). Indexed like RoadProgression.Districts. A family brings all six of its
-- looks (Farmer ... King); SirenHead and BuckshotDealer are specials with their own tiers (ZombieConfig.Types).
-- (Until 2026-11-15 the sets followed the old locations: forest, dark forest, hospital, village, cultist cave, factory.)
-- A grave remembers where it was dug (item.location); graves from anywhere else (the shop, the Blood Moon, the starter)
-- may give anything.
local Collection = require(script.Parent.Parent.MonsterCollection)
local ZC = require(script.Parent.ZombieConfig)

local L = {
	-- The road reskin (owner, 2026-11-15): a location's graves give the monsters that roam it, and its boss's family.
	Sets = {
		{ "Deer", "Verity", "Stalker" }, -- Dark forest (boss: the Horned Alpha, a deer)
		{ "Longmaw", "RingMaw", "SirenHead" }, -- Backrooms (boss: RingMaw)
		{ "HoodedStranger", "Slenderman", "Mimic" }, -- Abandoned city (boss: the Stranger)
		{ "Granny", "Grandfather", "SpiderMom", "Slendrina" }, -- Abandoned village (boss: Slendrina)
		{ "AssimilatedAdventurer", "Dredge", "AdaptedViscera", "Parasite" }, -- Parasitown (boss: Patient Zero, a parasite)
		{ "CaveDweller", "PrimitiveSummoner", "BuckshotDealer" }, -- Abandoned cave (boss: the Cave Dweller)
	},
}

local function member(set, id)
	local family = Collection.Family(id)
	for _, f in set do
		if f == family or f == id then
			return true
		end
	end
	return false
end

-- The monster types of this tier a grave from `location` may give (every type when the location is unknown, or when
-- none of its set has that tier).
function L.Types(location, tier)
	local all = ZC.Types[tier] or ZC.Types[1]
	local set = L.Sets[location]
	if not set then
		return all
	end
	local list = {}
	for _, id in all do
		if member(set, id) then
			table.insert(list, id)
		end
	end
	return #list > 0 and list or all
end

-- Everything a location can give, for the Monsterdex: catalog entries in the dex's order.
function L.Catalog(location)
	local set = L.Sets[location]
	local list = {}
	for _, e in Collection.Catalog do
		-- the Chief comes only from the last boss's main grave: it is listed with the factory
		local chief = e.Id == Collection.BossType
		if set and (chief and location == #L.Sets or not chief and member(set, e.Id)) then
			table.insert(list, e)
		end
	end
	return list
end

return L
