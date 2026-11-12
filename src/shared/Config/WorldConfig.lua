-- Shared interval boundaries for visuals, spawning and location notifications.
-- Order and look follow the owner's reference: each location darker than the one before.
local P=require(script.Parent.RoadProgression)
local themes={
 {Name="roadForest",Floor="7FB33A",Path="B9824F",Wall={"D6CFE6","C9C1DC","DED8EC"},Cap="9B8CC9",Fog="E2EAB0",Density=.03},
 {Name="roadDarkForest",Floor="3E4A35",Path="7A5838",Wall={"A49DB5","9890AA","AEA7BE"},Cap="6E6390",Fog="8FA090",Density=.1},
 {Name="roadHospital",Floor="D9DDD6",Path="C7CCC4",Wall={"E9ECEE","DDE2E4","F2F4F5"},Cap="7FC6B6",Fog="CFEDE5",Density=.07},
 {Name="roadVillage",Floor="A88F70",Path="C9AE86",Wall={"D2C2A2","C5B391","DCCDAE"},Cap="8E6E4C",Fog="D9BB9B",Density=.08},
 {Name="roadCave",Floor="4F4650",Path="6C6170",Wall={"7A707F","6C6372","877D8C"},Cap="4A3F52",Fog="9C7F8F",Density=.14},
 {Name="roadFactory",Floor="7E7A74",Path="9A958D",Wall={"B5694F","A65E46","C27558"},Cap="5E5A55",Fog="C8B49A",Density=.12},
}
for i,d in P.Districts do
 local t=themes[i];t.From=d.From;t.To=d.To;t.At=d.From+30;t.RecommendedSpeed=d.RecommendedSpeed
 t.Title="location"..d.Id
 t.Emoji=({Forest="🌲",DarkForest="🌑",Hospital="🏥",Village="🏚️",Cave="🕯️",Factory="🏭"})[d.Id]
end
return {StudTexture='rbxassetid://124290005827914',StudTile=4,Districts=themes}
