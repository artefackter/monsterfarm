-- Bright but not glaring (owner, 2026-11-13: "still dark", then 2026-11-14: "now too bright"): a sunny day with a
-- touch of haze and a colourful violet night, between the moody try and the over-bright one.
local C = require(game.ReplicatedStorage.Shared.Config.NightConfig)
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local D = {}

local LOOK = {
	day = {
		Clock = 14.2, Brightness = 1.7, Exposure = 0.05,
		Ambient = Color3.fromRGB(132, 132, 148), Outdoor = Color3.fromRGB(145, 144, 162), Shift = Color3.fromRGB(255, 244, 228),
		Fog = Color3.fromRGB(195, 225, 240), Density = 0.08, Haze = 0.3, AtmosphereColor = Color3.fromRGB(205, 228, 240),
		Tint = Color3.fromRGB(252, 250, 246), Saturation = 0.06, Contrast = 0.06,
	},
	night = {
		Clock = 23.6, Brightness = 1.25, Exposure = 0.12,
		Ambient = Color3.fromRGB(145, 130, 195), Outdoor = Color3.fromRGB(158, 142, 210), Shift = Color3.fromRGB(190, 185, 255),
		Fog = Color3.fromRGB(120, 105, 200), Density = 0.12, Haze = 0.4, AtmosphereColor = Color3.fromRGB(135, 115, 220),
		Tint = Color3.fromRGB(240, 236, 255), Saturation = 0.15, Contrast = 0.03,
	},
	-- Blood Moon (BloodMoonService): the purple night turns crimson while the giant is out
	blood = {
		Clock = 0, Brightness = 0.95, Exposure = 0.05,
		Ambient = Color3.fromRGB(160, 80, 95), Outdoor = Color3.fromRGB(185, 90, 105), Shift = Color3.fromRGB(255, 120, 120),
		Fog = Color3.fromRGB(130, 20, 40), Density = 0.3, Haze = 1.4, AtmosphereColor = Color3.fromRGB(210, 40, 60),
		Tint = Color3.fromRGB(255, 205, 210), Saturation = 0.25, Contrast = 0.1,
	},
}
D.Blood = false
function D.SetBlood(on)
	D.Blood = on == true
end

local function ensure(class)
	local e = Lighting:FindFirstChildOfClass(class)
	if not e then
		e = Instance.new(class)
		e.Parent = Lighting
	end
	return e
end

local atmosphere, correction, bloom, sky

local function setup()
	atmosphere, correction, bloom, sky = ensure("Atmosphere"), ensure("ColorCorrectionEffect"), ensure("BloomEffect"), ensure("Sky")
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.35
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.EnvironmentSpecularScale = 0.1
	Lighting.GeographicLatitude = 28
	Lighting.FogEnd = 100000
	bloom.Intensity, bloom.Size, bloom.Threshold = 0.12, 24, 1.9
	sky.SunAngularSize = 16
	sky.MoonAngularSize = 24
	sky.StarCount = 4000
	atmosphere.Offset, atmosphere.Glare, atmosphere.Decay = 0.2, 0, Color3.fromRGB(120, 160, 220)
	local look = LOOK[D.State() and "night" or "day"]
	Lighting.ClockTime = look.Clock
end

function D.State()
	-- Studio only: set workspace attribute DebugPhase to "day" or "night" to look at either one.
	local debugPhase = RunService:IsStudio() and workspace:GetAttribute("DebugPhase")
	if debugPhase then
		return debugPhase == "night", 120, 0
	end
	local t = workspace:GetServerTimeNow() % (C.Day + C.Night)
	return t >= C.Day, (t >= C.Day and C.Day + C.Night or C.Day) - t, math.floor(workspace:GetServerTimeNow() / (C.Day + C.Night))
end

local function lerp(a, b, k)
	return a + (b - a) * k
end

-- Called once a second. Everything eases toward the current look, so dusk and dawn play out on their own.
function D.Update()
	if not atmosphere then
		setup()
	end
	local night, left = D.State()
	local look, k = LOOK[night and (D.Blood and "blood" or "night") or "day"], 0.08
	Lighting.ClockTime = lerp(Lighting.ClockTime, look.Clock, k)
	Lighting.Brightness = lerp(Lighting.Brightness, look.Brightness, k)
	Lighting.ExposureCompensation = lerp(Lighting.ExposureCompensation, look.Exposure, k)
	Lighting.Ambient = Lighting.Ambient:Lerp(look.Ambient, k)
	Lighting.OutdoorAmbient = Lighting.OutdoorAmbient:Lerp(look.Outdoor, k)
	Lighting.ColorShift_Top = Lighting.ColorShift_Top:Lerp(look.Shift, k)
	Lighting.FogColor = Lighting.FogColor:Lerp(look.Fog, k)
	atmosphere.Density = lerp(atmosphere.Density, look.Density, k)
	atmosphere.Haze = lerp(atmosphere.Haze, look.Haze, k)
	atmosphere.Color = atmosphere.Color:Lerp(look.AtmosphereColor, k)
	correction.TintColor = correction.TintColor:Lerp(look.Tint, k)
	correction.Saturation = lerp(correction.Saturation, look.Saturation, k)
	correction.Contrast = lerp(correction.Contrast, look.Contrast, k)
	return night, left
end

return D

