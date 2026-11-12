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
function C.Asset(id,form)
 local pair=C.Forms[id];local state=form=="Aggressive" and "Aggressive" or form=="Passive" and "Passive" or C.FarmForms[id] or "Passive"
 return pair and pair[state] or C.Models[id]
end
return C
