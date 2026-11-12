-- All game audio. Every id belongs to Roblox's licensed libraries (ProSoundEffects 7462895450, APMOfficial 7462718749), which any
-- experience may use. Do not swap in user uploads: audio is often private or ripped from other games.
-- To change a sound, replace its Id here. Volume is 0..1, Speed is pitch and tempo together.
return {
 -- ProSoundEffects Creator Store verified 2026-11-07; spatial training loops.
 TreadmillMotor={Id=9112890980,Volume=.08,Speed=1},
 TreadmillWind={Id=9114057104,Volume=.06,Speed=1},

 -- Real firearm recordings (owner, 2026-11-12: the toy ray guns were too cartoonish). All ProSoundEffects, the same
 -- licensed library as every other sound here; ids checked on the Creator Store 2026-11-12, titles in comments.
 -- Library gaps: no MP5, M249 or double-barrel recordings, so the Mini Uzi, a slowed AK and a Savage 12 ga stand in.
 FireDeagle={Id=9117397964,Volume=.5,Speed=1}, -- Pistol Single Shots 10: Grizzly Win Mag .45
 FireAK={Id=9114727865,Volume=.34,Speed=1}, -- Gun Single Shots 28: AK-47
 FireM4={Id=9113177553,Volume=.34,Speed=1.05}, -- Assault Rifle 2: Steyr AUG .223
 FireMP5={Id=9114728793,Volume=.3,Speed=1.05}, -- Gun Single Shots 1: Mini Uzi
 FireM249={Id=9114727742,Volume=.36,Speed=.88}, -- Gun Single Shots 25: AK-47, slowed for a heavier gun
 FireDouble={Id=9112912936,Volume=.55,Speed=1}, -- 12 Gauge Shotgun 101: Savage, direct
 FirePump={Id=9114706610,Volume=.55,Speed=1}, -- Gun Live Ammunition 6: Mossberg 12 ga
 FireAWP={Id=9118173999,Volume=.6,Speed=1}, -- Rifle Single Shots 2: Barrett .50
 ReloadDeagle={Id=9113104509,Volume=.45,Speed=1.3}, -- Ammo Magazine 3: pistol magazine out/in
 ReloadAK={Id=9116347811,Volume=.45,Speed=1}, -- Machine Gun 15: AK-47 magazine handling
 ReloadM4={Id=9116347422,Volume=.45,Speed=1}, -- Machine Gun 8: rifle magazine handling
 ReloadMP5={Id=9116344412,Volume=.45,Speed=1.2}, -- Machine Gun 1: SMG cocking and loading
 ReloadM249={Id=9116361515,Volume=.45,Speed=1}, -- Machine Gun Chamber 1
 ReloadDouble={Id=9113027690,Volume=.45,Speed=1.2}, -- 470 Rifle 3: break open, two shells, close
 ReloadPump={Id=9112913305,Volume=.45,Speed=1}, -- 12 Gauge Shotgun 5: pump rack
 ReloadAWP={Id=9116357348,Volume=.45,Speed=1.1}, -- Machine Gun Bolt 1: bolt open and close
 EmptyDeagle={Id=9117396156,Volume=.3,Speed=1.4}, -- Pistol Clip 2, a dry metal click (no dry-fire take exists)
 EmptyAK={Id=9117396156,Volume=.3,Speed=1.2},
 EmptyM4={Id=9117396156,Volume=.3,Speed=1.25},
 EmptyMP5={Id=9117396156,Volume=.3,Speed=1.35},
 EmptyM249={Id=9117396156,Volume=.3,Speed=1.1},
 EmptyDouble={Id=9117396156,Volume=.3,Speed=1.15},
 EmptyPump={Id=9117396156,Volume=.3,Speed=1.15},
 EmptyAWP={Id=9117396156,Volume=.3,Speed=1.1},
 WeaponReload={Id=9116347811,Volume=.45,Speed=1}, -- Machine Gun 15
 WeaponEmpty={Id=9117396156,Volume=.3,Speed=1.3}, -- Pistol Clip 2
 -- Monsters: real creature recordings in place of the squeeze toy and the chimp.
 ImpHit={Id=9114482141,Volume=.3,Speed=1.1}, -- Flesh Hits 2: low thud, no gore
 ImpLaugh={Id=9113989720,Volume=.35,Speed=1}, -- Creature Vocal Spider Growls 2: short growl on spawn
 ImpBite={Id=9113138343,Volume=.3,Speed=1.35}, -- Apple Chew 1
 ImpDeath={Id=9113987782,Volume=.4,Speed=1.1}, -- Creature Vocal Pterodactyl Death Shriek 1
 BossRoar={Id=9113980644,Volume=.6,Speed=1}, -- Creature Mix Giant Crab Monster Roar Growl 4: boss appears / falls
 BossScream={Id=9116967966,Volume=.7,Speed=.9}, -- Monster Vocals 6: the boss scream attack
 BossCharge={Id=9113973520,Volume=.5,Speed=1}, -- Creature Growls Pit Bull 4: wind-up of a charge

	-- Farm actions
	Dig = { Id = 9114083260, Volume = 0.8 }, -- Dirt Dig, shovel throw, 0.9 s
	Reveal = { Id = 1848287311, Volume = 0.3 }, -- The Little Things - Hit, friendly plucked hit, 2.7 s
	RareReveal = { Id = 1841976890, Volume = 0.3 }, -- Balloon Cartoon (sting), 6.1 s: matches the reveal card
	Coins = { Id = 9113849583, Volume = 0.45 }, -- Coin Throws, 2.2 s
	Buy = { Id = 9113728049, Volume = 0.5 }, -- Cash Register, 1.7 s
	Caught = { Id = 9119198132, Volume = 0.8 }, -- Slide Whistle, classic cartoon riff, 1.5 s
	-- Interface
	Click = { Id = 9119717523, Volume = 0.45 }, -- Switch click, 0.2 s
	Error = { Id = 9113085764, Volume = 0.2 }, -- Alarm Buzzer, 1 s: deliberately quiet, it can fire often
	-- Pets
	PetHatchSound = { Id = 9116385087, Volume = 0.7 }, -- Magic Burst, 2.3 s
	PetDigSound = { Id = 9114083746, Volume = 0.6, Speed = 1.3 }, -- Dirt Dig, 0.8 s, pitched up for a small pet
	PetAlarmSound = { Id = 9113956178, Volume = 0.7 }, -- Coyotes, gruff barking, 1.1 s (no licensed dog bark found)
	-- Music: looped and cross-faded by EffectsController
	DayMusic = { Id = 1836295994, Volume = 0.035 }, -- Quiet spooky background; country track removed.
	NightMusic = { Id = 1836295994, Volume = 0.035 }, -- Spooky Wooky 59, 64 s. Alt: 1839908929 Collywobbles
}
