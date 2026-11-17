-- Shared interval boundaries for visuals, spawning and location notifications.
-- Order and look follow the owner's reference: each location darker than the one before.
local P=require(script.Parent.RoadProgression)
-- The road reskin (owner, 2026-11-15; art/road-reskin-screenshot-concepts-v5): dark forest, backrooms, abandoned city,
-- abandoned village (a little darker than its first draft), Parasitown, abandoned cave (the blood mine, kept readable:
-- mid grey-brown stone, red only in accents).
local themes={
 {Name="roadDarkForest",Floor="3E4A35",Path="7A5838",Wall={"A49DB5","9890AA","AEA7BE"},Cap="6E6390",Fog="8FA090",Density=.1},
 {Name="roadBackrooms",Floor="C9B27A",Path="DCCB98",Wall={"D8C46A","CDB95E","E0CD78"},Cap="B39A3E",Fog="E8DCA0",Density=.06},
 {Name="roadCity",Floor="6E6E6C",Path="7A7A78",Wall={"B8B8B4","ACACA8","C2C2BE"},Cap="8E8E8A",Fog="B8BCC0",Density=.08},
 {Name="roadVillage",Floor="8C7A63",Path="A8957A",Wall={"C2B092","B5A385","CBBB9E"},Cap="7E6248",Fog="CDB394",Density=.08},
 {Name="roadParasitown",Floor="8E8C8C",Path="B3B1B1",Wall={"5A5456","4E484A","625C5E"},Cap="6E1E24",Fog="A08A8E",Density=.1},
 {Name="roadCave",Floor="6D5D62",Path="95868A",Wall={"7A6E72","6E6266","84787C"},Cap="5A4A4E",Fog="9C8A8F",Density=.1},
}
for i,d in P.Districts do
 local t=themes[i];t.From=d.From;t.To=d.To;t.At=d.From+30;t.RecommendedSpeed=d.RecommendedSpeed
 t.Arena=d.Arena;t.ArenaFrom=d.ArenaFrom;t.ArenaTo=d.ArenaTo;t.Index=i
 t.Title="location"..d.Id
 t.Emoji=({DarkForest="🌑",Backrooms="💡",City="🏙️",Village="🏚️",Parasitown="🦠",Cave="⛏️"})[d.Id]
end
return {StudTexture='rbxassetid://124290005827914',StudTile=4,Districts=themes}
