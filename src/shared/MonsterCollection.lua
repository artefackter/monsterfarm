local C={Scale=.58,Models={},Forms={},Catalog={},BossType="DeerChief",BossTier=6}
C.Models.DeerFarmer="Deer_Farmer_Passive"
C.Forms.DeerFarmer={Passive="Deer_Farmer_Passive",Aggressive="Deer_Farmer_Aggressive"}
table.insert(C.Catalog,{Id="DeerFarmer",Tier=1})
C.Models.DeerPunk="Deer_Punk_Passive"
C.Forms.DeerPunk={Passive="Deer_Punk_Passive",Aggressive="Deer_Punk_Aggressive"}
table.insert(C.Catalog,{Id="DeerPunk",Tier=3})
C.Models.DeerAssassin="Deer_Assassin_Passive"
C.Forms.DeerAssassin={Passive="Deer_Assassin_Passive",Aggressive="Deer_Assassin_Aggressive"}
table.insert(C.Catalog,{Id="DeerAssassin",Tier=5})
C.Models.DeerChief="Deer_Chief_Passive"
C.Forms.DeerChief={Passive="Deer_Chief_Passive",Aggressive="Deer_Chief_Aggressive"}
table.insert(C.Catalog,{Id="DeerChief",Tier=6})
C.Models.ParasiteFarmer="Parasite_Farmer_Passive"
C.Forms.ParasiteFarmer={Passive="Parasite_Farmer_Passive",Aggressive="Parasite_Farmer_Aggressive"}
table.insert(C.Catalog,{Id="ParasiteFarmer",Tier=1})
C.Models.ParasitePunk="Parasite_Punk_Passive"
C.Forms.ParasitePunk={Passive="Parasite_Punk_Passive",Aggressive="Parasite_Punk_Aggressive"}
table.insert(C.Catalog,{Id="ParasitePunk",Tier=3})
C.Models.ParasiteAssassin="Parasite_Assassin_Passive"
C.Forms.ParasiteAssassin={Passive="Parasite_Assassin_Passive",Aggressive="Parasite_Assassin_Aggressive"}
table.insert(C.Catalog,{Id="ParasiteAssassin",Tier=5})
C.Models.StalkerFarmer="Stalker_Farmer_Passive"
C.Forms.StalkerFarmer={Passive="Stalker_Farmer_Passive",Aggressive="Stalker_Farmer_Aggressive"}
table.insert(C.Catalog,{Id="StalkerFarmer",Tier=1})
C.Models.StalkerPunk="Stalker_Punk_Passive"
C.Forms.StalkerPunk={Passive="Stalker_Punk_Passive",Aggressive="Stalker_Punk_Aggressive"}
table.insert(C.Catalog,{Id="StalkerPunk",Tier=3})
C.Models.StalkerAssassin="Stalker_Assassin_Passive"
C.Forms.StalkerAssassin={Passive="Stalker_Assassin_Passive",Aggressive="Stalker_Assassin_Aggressive"}
table.insert(C.Catalog,{Id="StalkerAssassin",Tier=5})
C.Models.VerityFarmer="Verity_Farmer"
table.insert(C.Catalog,{Id="VerityFarmer",Tier=1})
C.Models.VerityPunk="Verity_Punk"
table.insert(C.Catalog,{Id="VerityPunk",Tier=3})
C.Models.VerityAssassin="Verity_Assassin"
table.insert(C.Catalog,{Id="VerityAssassin",Tier=5})
C.Models.RingMawFarmer="RingMaw_Farmer_Passive"
C.Forms.RingMawFarmer={Passive="RingMaw_Farmer_Passive",Aggressive="RingMaw_Farmer_Aggressive"}
table.insert(C.Catalog,{Id="RingMawFarmer",Tier=1})
C.Models.RingMawPunk="RingMaw_Punk_Passive"
C.Forms.RingMawPunk={Passive="RingMaw_Punk_Passive",Aggressive="RingMaw_Punk_Aggressive"}
table.insert(C.Catalog,{Id="RingMawPunk",Tier=3})
C.Models.RingMawAssassin="RingMaw_Assassin_Passive"
C.Forms.RingMawAssassin={Passive="RingMaw_Assassin_Passive",Aggressive="RingMaw_Assassin_Aggressive"}
table.insert(C.Catalog,{Id="RingMawAssassin",Tier=5})
C.Models.CaveDwellerFarmer="CaveDweller_Farmer_Passive"
C.Forms.CaveDwellerFarmer={Passive="CaveDweller_Farmer_Passive",Aggressive="CaveDweller_Farmer_Aggressive"}
table.insert(C.Catalog,{Id="CaveDwellerFarmer",Tier=1})
C.Models.CaveDwellerPunk="CaveDweller_Punk_Passive"
C.Forms.CaveDwellerPunk={Passive="CaveDweller_Punk_Passive",Aggressive="CaveDweller_Punk_Aggressive"}
table.insert(C.Catalog,{Id="CaveDwellerPunk",Tier=3})
C.Models.CaveDwellerAssassin="CaveDweller_Assassin_Passive"
C.Forms.CaveDwellerAssassin={Passive="CaveDweller_Assassin_Passive",Aggressive="CaveDweller_Assassin_Aggressive"}
table.insert(C.Catalog,{Id="CaveDwellerAssassin",Tier=5})
C.FarmForms={RingMawFarmer="Aggressive",RingMawPunk="Aggressive",RingMawAssassin="Aggressive"}
C.Floating={BuckshotDealer=true}
for _,row in {{"SirenHead",4},{"BuckshotDealer",5}} do
 local id,tier=table.unpack(row);C.Forms[id]={Passive=id.."_Passive",Aggressive=id.."_Aggressive"};C.Models[id]=id.."_Passive";table.insert(C.Catalog,{Id=id,Tier=tier})
end
-- The rotation (owner, 2026-11-13): the Miner wears the Farmer's body, the Knight the Punk's, the King the Assassin's,
-- each with an outfit on top (ArtKit.Dress): a hard hat and a pickaxe; a helmet, a shield and a sword; a crown and a cape.
C.Outfits={};C.Base={}
C.Families={"Deer","Parasite","Stalker","Verity","RingMaw","CaveDweller"}
for _,family in C.Families do
 for _,row in {{"Miner","Farmer",2},{"Knight","Punk",4},{"King","Assassin",6}} do
  local id,from=family..row[1],family..row[2]
  C.Models[id]=C.Models[from];C.Forms[id]=C.Forms[from];C.FarmForms[id]=C.FarmForms[from];C.Outfits[id]=row[1];C.Base[id]=from
  table.insert(C.Catalog,{Id=id,Tier=row[3]})
 end
end
-- The families of 2026-11-14 (Config.MonsterFamilies): a model of their own for every rarity, no outfits.
do
 local NF=require(script.Parent.Config.MonsterFamilies)
 for _,family in NF.Order do
  table.insert(C.Families,family)
  for tier=1,#NF.Looks do local id=NF.Id(family,tier);C.Models[id]=id;table.insert(C.Catalog,{Id=id,Tier=tier}) end
 end
end
function C.Family(id)
 for _,f in C.Families do if id:sub(1,#f)==f then return f end end
 return id
end
-- The dex reads family by family, rarity by rarity (the specials last).
do
 local order,pos={},{};for i,f in C.Families do order[f]=i end;for i,e in C.Catalog do pos[e]=i end
 table.sort(C.Catalog,function(a,b)
  local fa,fb=order[C.Family(a.Id)] or 99,order[C.Family(b.Id)] or 99
  if fa~=fb then return fa<fb end
  if a.Tier~=b.Tier then return a.Tier<b.Tier end
  return pos[a]<pos[b]
 end)
end
-- Use a painted portrait whenever it is registered, including Miner/Knight/King outfits.
-- A missing asset keeps the existing 3D fallback.
function C.Icon(id,icons)
 return icons["modal_monster_"..id]
end
-- Saves from before the rotation keep their monsters but take the new look of their rarity: an Uncommon Farmer
-- becomes a Miner, an Epic Punk a Knight, a Mythic Assassin a King (and is known in the dex as such).
local PROMOTE={[2]={"Farmer","Miner"},[4]={"Punk","Knight"},[6]={"Assassin","King"}}
function C.Promote(z,dex)
 local row=PROMOTE[z.tier];if not row or type(z.type)~="string" then return end
 local family=C.Family(z.type)
 if z.type==family..row[1] and C.Models[family..row[2]] then
  z.type=family..row[2]
  if dex then dex[z.type..":"..(z.mutation or "None")]=true end
 end
end
function C.Asset(id,form)
 local pair=C.Forms[id];local state=form=="Aggressive" and "Aggressive" or form=="Passive" and "Passive" or C.FarmForms[id] or "Passive"
 return pair and pair[state] or C.Models[id]
end
return C
