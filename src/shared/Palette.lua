local p = {}
for k, v in pairs({
	-- Interface: candy colours on warm cream, chunky aubergine outlines
	Panel = "FFF3D6", PanelDark = "F4DDAE", Stroke = "3A2366", Highlight = "8C4BFF", Accent = "FFD93B", Text = "FFFFFF", Ink = "3A2366",
	Mint = "5ED98A", Pink = "FF6FA8", Orange = "FF9A2E", Sky2 = "4AA8FF", Violet = "8C4BFF", Red = "FF5468",
	-- Rarities
	Common = "AEB9C9", Uncommon = "5BD16B", Rare = "4AA8FF", Epic = "B067FF", Legendary = "FFB627", Mythic = "FF4FA3",
	-- World
	Skin = "9BE36B", Grass = "7BDC4B", Earth = "8A5A3B", Stone = "B7C3DA", Pumpkin = "FF8A1F", Sky = "BFE8FF", Night = "4B3A9A", Fog = "7B69D6", Glow = "7DFFB2",
	Sea = "2AAFDC", Slime = "7CFF5B",
}) do
	p[k] = Color3.fromHex(v)
end
return p
