-- Stage 4: no community or paid product is enabled until the owner supplies its ID.
return {
 GroupId=0,FreeGift={Speed=10000,Grave="Marble"},
 HomeCooldown=5,BoardDistance=16,ZoneRadius=7,ZoneDelay=.2,RemoteInterval=.2,
 Settings={AutoFire=true,ShowRanges=true,GuideArrows=true,ShiftSlow=true,CameraShake=true,MusicVolume=.7,SfxVolume=1},
 Pages={"None","Golden","Lunar","Rainbow"},Thresholds={1,3,4},
 DexCoins={5000,50000,500000,5000000},DexSpeed={5000,50000,500000,5000000},DexShovels={"Bone","Golden","Lunar","Rainbow"},
 -- Each product buys one persistent upgrade credit. A credit waits safely if a house limit blocks use.
 Products={House={Id=0,Price=0},Field={Id=0,Price=0},Graves={Id=0,Price=0},Guards={Id=0,Price=0},Crypt={Id=0,Price=0},PetSlots={Id=0,Price=0},Treadmill={Id=0,Price=0}},
 -- Positions are the actual entry circles. Props sit slightly toward the outer edge.
 Zones={
  weapons={Position=Vector3.new(-18,0,-25),Color="53C7FF",Title="weapons",Radius=6.4},
  traps={Position=Vector3.new(0,0,-30),Color="FFD85A",Title="traps",Radius=6.4},
  pumpkins={Position=Vector3.new(18,0,-25),Color="C58AFF",Title="pumpkins",Radius=6.4},
  -- the merge table lives in every player's house now (HouseService)
  quests={Position=Vector3.new(0,0,30),Color="CA7AFF",Title="quests",Radius=6.4},
  rewards={Position=Vector3.new(18,0,25),Color="FF8DB6",Title="rewards",Radius=6.4},
  info={Position=Vector3.new(31,0,-5),Color="FFD85A",Title="info",Radius=6},
  freeGift={Position=Vector3.new(-31,0,-5),Color="6DF095",Title="freeGift",Radius=6},
 },
 -- Upgrade boards, spread out: the four place boards stand in a row along the right fence facing the yard.
 Boards={House={X=3,Z=9,Yaw=-45},Treadmill={X=37,Z=-24,Yaw=90},PetSlots={X=7,Z=39},Lock={X=-12,Z=-39}}, -- no place boards: graves and pen zombies are unlimited
}
