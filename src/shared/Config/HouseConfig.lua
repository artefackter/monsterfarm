-- The player's house, as in Clash of Clans: its level sets how far everything else on the farm can be upgraded.
-- Building takes real time and carries on while the player is away.
-- Field: how many monsters may stand out on the farm (owner, 2026-11-12: "limit the monsters you can place, the
-- house upgrade raises it"). Crypt and Guards keep their own upgrades up to these caps; graves are unlimited.
return {
 Levels={
  {Look=1,Limits={Field=8,Graves=5,Guards=2,Crypt=30}},
  {Look=2,Price=5000,Seconds=60,Limits={Field=11,Graves=7,Guards=3,Crypt=40}},
  {Look=3,Price=50000,Seconds=300,Limits={Field=14,Graves=9,Guards=3,Crypt=50}},
  {Look=4,Price=500000,Seconds=1200,Limits={Field=17,Graves=11,Guards=4,Crypt=60}},
  {Look=5,Price=5000000,Seconds=3600,Limits={Field=20,Graves=12,Guards=4,Crypt=60}},
  {Look=6,Price=25000000,Seconds=7200,Limits={Field=24,Graves=12,Guards=4,Crypt=60}},
  {Look=7,Price=100000000,Seconds=14400,Limits={Field=28,Graves=12,Guards=4,Crypt=60}},
 },
 Zones={"Guards","Crypt"}, -- the upgradeable zones the house caps; Field is the house's own limit (HouseRules.FieldCap)
 -- A monster base after the owner's reference (2026-11-12): graphite walls, cream corner pillars, a glass storefront.
 -- Each level adds to it: awning and neon, a showroom floor with your best monsters, a rooftop billboard with your
 -- name, gold and a beacon, a third floor, a crown. Tall bounds the room for "is the player inside".
 Looks={
  {W=32,D=27,Wall=12,Floors=1,FloorHeight=10,Tall=17},
  {W=32,D=27,Wall=12,Floors=1,FloorHeight=10,Tall=17,Awning=true,Neon=true,Planters=true},
  {W=32,D=27,Wall=12,Floors=2,FloorHeight=10,Tall=27,Awning=true,Neon=true,Planters=true},
  {W=32,D=27,Wall=12,Floors=2,FloorHeight=10,Tall=27,Awning=true,Neon=true,Planters=true,Billboard=true},
  {W=32,D=27,Wall=12,Floors=2,FloorHeight=10,Tall=27,Awning=true,Neon=true,Planters=true,Billboard=true,Gold=true,Beacon=true},
  {W=32,D=27,Wall=12,Floors=3,FloorHeight=10,Tall=37,Awning=true,Neon=true,Planters=true,Billboard=true,Gold=true,Beacon=true},
  {W=32,D=27,Wall=12,Floors=3,FloorHeight=10,Tall=37,Awning=true,Neon=true,Planters=true,Billboard=true,Gold=true,Beacon=true,Crown=true},
 },
 Spot={X=20,Z=-17.5},Depth=17,Width=20, -- where it stands on the plot; the door looks at the farm's central path
 -- The house stands across the back-right corner at 45 degrees: its back corners touch both fences, so it
 -- closes the corner like a piece of the fence, and its door looks at the farm centre.
 Scale=1,FloorY=.7,RoomX=-18.73,RoomY=-.5,RoomZ=18.73,RoomYaw=-45,RoomWidth=32,RoomDepth=27,RoomHeight=38, -- the room is directly under the plot, so it still counts as being on the farm
}
