-- All game audio. Every id belongs to Roblox's licensed libraries (ProSoundEffects, APMOfficial), which any
-- experience may use. Do not swap in user uploads: audio is often private or ripped from other games.
-- To change a sound, replace its Id here. Volume is 0..1, Speed is pitch and tempo together.
return {
 -- ProSoundEffects Creator Store verified 2026-11-07; spatial training loops.
 TreadmillMotor={Id=9112890980,Volume=.08,Speed=1},
 TreadmillWind={Id=9114057104,Volume=.06,Speed=1},
 ReloadDeagle={Id=9118828055,Volume=.4,Speed=1.3},
 EmptyDeagle={Id=9119717523,Volume=.25,Speed=1.3},
 ReloadAK={Id=9118828055,Volume=.4,Speed=0.9},
 EmptyAK={Id=9119717523,Volume=.25,Speed=0.9},
 ReloadM4={Id=9118828055,Volume=.4,Speed=1.15},
 EmptyM4={Id=9119717523,Volume=.25,Speed=1.15},
 ReloadAWP={Id=9118828055,Volume=.4,Speed=0.75},
 EmptyAWP={Id=9119717523,Volume=.25,Speed=0.75},

 -- ProSoundEffects Creator Store results verified 2026-11-05. Toy Ray Gun variations, not firearm recordings.
 FireAWP={Id=9120221105,Volume=.6,Speed=.85},
 FireDeagle={Id=9120221621,Volume=.45,Speed=1.35}, -- Toy Ray Gun 9
 FireAK={Id=9120221370,Volume=.26,Speed=1.65}, -- Toy Ray Gun 5
 FireM4={Id=9120221105,Volume=.6,Speed=1.15}, -- Toy Ray Gun 1
 WeaponReload={Id=9118828055,Volume=.45,Speed=1.3}, -- Scissors Snap 13, mechanical toy latch
 WeaponEmpty={Id=9119717523,Volume=.3,Speed=1.25}, -- Switch click, existing licensed source
 ImpHit={Id=9125994570,Volume=.35,Speed=1.6}, -- Squeeze Toy
 ImpLaugh={Id=9125439346,Volume=.4,Speed=1.6}, -- Chimpanzee chatter, comic creature giggle substitute
 ImpBite={Id=9113138343,Volume=.3,Speed=1.35}, -- Apple Chew 1
 ImpDeath={Id=9125994570,Volume=.6,Speed=1.8}, -- Squeeze Toy squeak

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
