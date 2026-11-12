-- A faster start (owner's playtest, 2026-11-10): for the first hour of play the farm earns more, so the first
-- graves, the first gun and the first treadmill come quickly. Counted in played time, so it cannot be waited out
-- offline. Only what the farm pays into the heap is multiplied; prices, kill rewards and offline income are not.
return {
 Stages={
  {Until=1800,Income=3}, -- the first 30 minutes
  {Until=3600,Income=2}, -- up to an hour
 },
}
