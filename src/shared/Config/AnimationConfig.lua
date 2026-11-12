-- Character animation. Clips are Roblox's own Cartoony pack, so they play in any experience without uploading.
-- Natural = studs per second the clip covers at playback speed 1, measured on an R15 rig in Studio.
return {
	Idle = { { Id = 742637544, Weight = 9 }, { Id = 742638445, Weight = 1 } },
	Walk = { Id = 742640026, Natural = 8.3 },
	Run = { Id = 742638842, Natural = 17 },
	Jump = 742637942,
	Fall = 742637151,
	Climb = 742636889,
	Swim = 742639220,
	SwimIdle = 742639812,
	Sit = 2506281703,
	-- Between these speeds the walk hands over to the run; slow mode always walks.
	RunFrom = 11,
	RunFull = 14,
	-- Playback speed limits: past them the feet glide instead of spinning into a blur.
	WalkWarp = { 0.55, 1.45 },
	RunWarp = { 0.8, 1.85 },
	-- Treadmill: the run plays in place, faster on better treadmills.
	TreadmillWarp = { Base = 1.05, PerLevel = 0.12 },
	JumpTime = 0.32,
	Blend = 12, -- how fast weights follow their targets, per second
	Emotes = { wave = 507770239, point = 507770453, dance = 507771019, dance2 = 507776043, dance3 = 507777268, laugh = 507770818, cheer = 507770677 },
}
