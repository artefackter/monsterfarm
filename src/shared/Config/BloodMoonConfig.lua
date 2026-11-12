-- Blood Moon (owner, 2026-11-12). Every few nights the moon turns red, the road to the ruins shuts behind a red
-- barrier and a giant (one of the ruins' bosses, ten times a player's height) breaks out onto the island. Kill it
-- before the time runs out and graves rain down where it falls; otherwise it walks back into the ruins.
return {
 Every=3,Offset=2,      -- a Blood Moon night: DayNightService cycle % Every == Offset
 StartAfter=20,         -- seconds into that night before the giant breaks out
 Duration=150,          -- seconds to kill it
 Height=55,             -- studs tall (a player is about 5.5)
 Speed=13,Reach=16,     -- walking speed, how close it walks up to its target
 IslandRadius=170,      -- it never walks further than this from the island's centre
 HealthPerPlayer=6000,ExtraPlayerHealth=4500,MaxHealth=80000, -- health for one player, each further player adds
 RewardMult=25,         -- times the usual kill reward, paid to everyone who hit it (MutantService.Damage)
 -- Its blows knock players down (Stun seconds) and fling them (Fling studs); they never cost anything.
 Attacks={
  {Name="Roar",Pose="Scream",Range=45,Radius=45,Windup=1.4,Cooldown=14,Stun=1,Fling=10},
  {Name="Stomp",Pose="Stomp",Range=24,Radius=26,Windup=1.3,Cooldown=5,Stun=2,Fling=22},
  {Name="Smash",Pose="Slam",MinRange=16,Range=110,Radius=13,Windup=1.2,Cooldown=3.5,Stun=2,Fling=14},
 },
 -- The graves that rain down: PerPlayer for each player who hit it (within Min..Max), at most PerPickup each.
 Graves={PerPlayer=3,Min=4,Max=14,PerPickup=3,Lifetime=120,Pool={Stone=10,Marble=40,Golden=38,Lunar=12}},
}
