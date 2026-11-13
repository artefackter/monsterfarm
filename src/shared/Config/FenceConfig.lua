-- The farm fence and its gate (owner, 2026-11-13: "a better fence, so fewer mutants get in at night; the mutants have
-- to break the player's gate before they climb in"). At night the gate is shut: raiders walk round to it and hammer
-- it until it breaks, and only then go for the monsters inside. A raider that can't break it in Patience seconds
-- gives up and runs. Upgrading the fence (the board by the gate) makes the gate tougher; from level 4 its spikes hurt
-- whoever hits it. A broken gate mends itself Repair seconds later, at dawn, or at once when its owner fixes it.
local F={
 Levels={
  {Hp=150,Look="Wood"}, -- three raiders (about 30 a second) get through in five seconds
  {Price=15000,Hp=400,Look="Planks"},
  {Price=150000,Hp=900,Look="Iron"}, -- about as long as their Patience: most give up
  {Price=1500000,Hp=1800,Spikes=4,Look="Spiked"},
  {Price=15000000,Hp=3500,Spikes=8,Look="Bone"},
 },
 Damage={Imp=8,Leaper=10,Bubble=14}, -- per blow, one blow a second; other kinds use Imp's
 Patience=30,
 Repair=45,
 RepairHold=1.5,
 OpenDistance=11, -- the leaves swing open for anyone this close, unless raiders are at them
}
function F.Level(d)
 local n=d and tonumber(d.fenceLevel) or 1
 return math.clamp(math.floor(n),1,#F.Levels)
end
return F
