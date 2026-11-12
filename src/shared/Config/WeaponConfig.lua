return {
 Version=10, Order={"Deagle","Double","AK","MP5","M4","Pump","M249","AWP"}, RateTolerance=.015, ActionInterval=.15, RequestInterval=.035,
 AutoAimAngle=55, AimWarmup=.15, UpperBodyYaw=1.2, -- radians the torso twists toward a target before the whole body turns
 PoseHold=1.2, TargetScan=.08, TracerSeconds=.09, AimLimit=1000000,
 GuardWeapons={Pajama="Deagle",Gardener="Deagle",Postman="Deagle",Skater="Deagle",Pirate="AK",Cowboy="AK",Knight="M4",DJ="M4",King="M4",Astronaut="M4",Dragon="AWP"},
 Deagle={Price=0,Damage=20,Pellets=1,FireRate=2.5,Range=32,Spread=1,Magazine=7,Reload=1.3,Automatic=false,Recoil=.65,Muzzle=Vector3.new(0,.15,-1.17),Color=Color3.fromHex("B9C5CE")},
 AK={Price=25000,Damage=7,Pellets=1,FireRate=9,Range=42,Spread=3,Magazine=30,Reload=2,Automatic=true,Recoil=.35,Muzzle=Vector3.new(0,.13,-1.77),Color=Color3.fromHex("956B45")},
 M4={Price=150000,Damage=8,Pellets=1,FireRate=11,Range=46,Spread=2,Magazine=30,Reload=1.8,Automatic=true,Recoil=.3,Muzzle=Vector3.new(0,.15,-1.77),Color=Color3.fromHex("536A65")},
 Double={ArtAsset="GunDouble",Price=10000,Damage=9,Pellets=8,FireRate=1.8,Range=22,Spread=8,Magazine=2,Reload=2.4,Automatic=false,Recoil=1.1,Muzzle=Vector3.new(0,.192,-2.293),Color=Color3.fromHex("AE8155")},
 MP5={ArtAsset="GunMP5",Price=75000,Damage=6,Pellets=1,FireRate=12,Range=34,Spread=3.5,Magazine=30,Reload=1.65,Automatic=true,Recoil=.25,Muzzle=Vector3.new(0,.174,-1.747),Color=Color3.fromHex("76889C")},
 Pump={ArtAsset="GunPump",Price=350000,Damage=14,Pellets=8,FireRate=1.05,Range=29,Spread=6,Magazine=6,Reload=2.8,Automatic=false,Recoil=1.2,Muzzle=Vector3.new(0,.204,-2.352),Color=Color3.fromHex("B97A4A")},
 M249={ArtAsset="GunM249",Price=650000,Damage=10,Pellets=1,FireRate=10,Range=43,Spread=4,Magazine=100,Reload=4.2,Automatic=true,Recoil=.5,Muzzle=Vector3.new(0,.205,-2.322),Color=Color3.fromHex("939861")},
 AWP={Price=1000000,Damage=90,Pellets=1,FireRate=.7,Range=75,Spread=.3,Magazine=5,Reload=3,Automatic=false,Recoil=1.2,Muzzle=Vector3.new(0,.18,-2.32),Color=Color3.fromHex("4D704C")},
}
