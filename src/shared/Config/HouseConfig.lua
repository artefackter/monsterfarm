-- The player's house, as in Clash of Clans: its level sets how far everything else on the farm can be upgraded.
-- Building takes real time and carries on while the player is away.
return {
 Levels={
  {Look=1,Limits={Field=8,Graves=5,Guards=2,Crypt=30}},
  {Look=2,Price=5000,Seconds=60,Limits={Field=11,Graves=7,Guards=3,Crypt=40}},
  {Look=3,Price=50000,Seconds=300,Limits={Field=14,Graves=9,Guards=3,Crypt=50}},
  {Look=4,Price=500000,Seconds=1200,Limits={Field=17,Graves=11,Guards=4,Crypt=60}},
  {Look=5,Price=5000000,Seconds=3600,Limits={Field=20,Graves=12,Guards=4,Crypt=60}},
 },
 Zones={"Guards","Crypt"}, -- graves and pen zombies have no limit: only the room on the farm counts
 -- A cottage built from blocks: cream walls, a purple gabled roof with flared eaves, a chimney, a lamp by the
 -- open door. Each level grows it: a porch, a second floor, a corner tower, then the golden manor.
 Looks={
  {W=32,D=27,Wall=12,Roof=10,Tall=24,Sign=10.8,Asset="V3_House1"},
  {W=32,D=27,Wall=12,Roof=10.5,Tall=25,Sign=10.8,Porch=true,Asset="V3_House2"},
  {W=32,D=27,Wall=18,Roof=11,Tall=32,Sign=10.8,Porch=true,Floors=2,Asset="V3_House3"},
  {W=32,D=27,Wall=18,Roof=11,Tall=38,Sign=10.8,Porch=true,Floors=2,Tower=true,Asset="V3_House4"},
  {W=32,D=27,Wall=20,Roof=12,Tall=42,Sign=10.8,Porch=true,Floors=2,Tower=true,Gold=true,Asset="V3_House5"},
 },
 Spot={X=20,Z=-17.5},Depth=17,Width=20, -- where it stands on the plot; the door looks at the farm's central path
 -- The house stands across the back-right corner at 45 degrees: its back corners touch both fences, so it
 -- closes the corner like a piece of the fence, and its door looks at the farm centre.
 Scale=1,FloorY=.7,RoomX=-18.73,RoomY=-.5,RoomZ=18.73,RoomYaw=-45,RoomWidth=32,RoomDepth=27,RoomHeight=38, -- the room is directly under the plot, so it still counts as being on the farm
}
