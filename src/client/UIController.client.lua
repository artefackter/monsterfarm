-- Grow a Zombie: shared illustrated modal theme; independent desktop/mobile HUD.
-- Everything is laid out in pixels at 1280x720 and scaled to the device by one factor.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local p = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local S = RS:WaitForChild("Shared")
local rem = RS:WaitForChild("Remotes")
local Pal = require(S.Palette)
local L = require(S.Locale)
local ZC = require(S.Config.ZombieConfig)
local GC = require(S.Config.GraveConfig)
local RC = require(S.Config.RewardConfig)
local UC = require(S.Config.UpgradeConfig)
local Art = require(S.ArtKit)
local Sfx = require(S.Sfx)
local QuestRules = require(S.QuestRules)
local Icons = require(S.Icons)
local Style=require(S.UIStyle);local InterfaceC=require(S.Config.InterfaceConfig);local InterfaceRules=require(S.InterfaceRules)
local Merge = require(S.MergeRules)
local HouseC = require(S.Config.HouseConfig)
local HouseRules = require(S.HouseRules)
local RoadC = require(S.Config.RoadConfig)
local ZoneC = require(S.Config.ZoneConfig)
local SocialService = game:GetService("SocialService")

local WeaponC=require(S.Config.WeaponConfig);local weaponState
local PetC=require(S.Config.PetConfig);local Pumpkins=require(S.Config.PumpkinConfig);local PetModel=require(S.PetModel)
local showPetHatch;local starterShown=false
local petState;local releaseId;local petStarterHint=false
local lang = L.lang()
local isRussian = string.sub(lang, 1, 2) == "ru"
local function t(k, a)
	return L.text(k, lang, a)
end

-- FredokaOne is the friendliest face but has no Cyrillic; GothamBlack keeps Russian equally chunky.
local FONT_TITLE = isRussian and Enum.Font.GothamBlack or Enum.Font.FredokaOne
local FONT_BODY = isRussian and Enum.Font.BuilderSansExtraBold or Enum.Font.FredokaOne

local ICON = {
	pets="🐾", pumpkins="🎃", quests="📋", top="🏆", invite="👥", inventory="🎒", settings="⚙️", house="🏠", backpack="🎒", daily="🎁", shop = "🛒", crypt = "⚰️", dex = "📖", rewards = "🎁", lock = "🔒",
	Pajama = "🛏️", Gardener = "🌱", Postman = "✉️", Skater = "🛹", Pirate = "🏴‍☠️", Cowboy = "🤠",
	Knight = "🥖", DJ = "🎧", King = "👑", Astronaut = "🚀", Dragon = "🐲",
	Wooden = "🌲", Stone = "🗿", Marble = "🏛️", Golden = "🏆", Emo = "🖤", Military = "🎖️", Ghost = "👻", Lunar = "🌙",
	Field = "🌾", Graves = "⚰️", Diggers = "⛏️", Guards = "🛡️", Crypt = "⚰️",
}

local gui = Instance.new("ScreenGui")
gui.Name = "DigUI"
gui.ResetOnSpawn = false
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder=20
gui.Parent = p:WaitForChild("PlayerGui")
-- Full-screen, non-interactive mobile statistics, matching the outer-left reference.
local mobileStats=Instance.new('ScreenGui');mobileStats.Name='MobileStats';mobileStats.ResetOnSpawn=false
mobileStats.ScreenInsets=Enum.ScreenInsets.None;mobileStats.ClipToDeviceSafeArea=false;mobileStats.DisplayOrder=20;mobileStats.Parent=p.PlayerGui

local function darker(c, k)
	return Color3.new(c.R * k, c.G * k, c.B * k)
end

local function candy(f,color,radius) return Style.Panel(f,color,radius) end

local function isModal(parent)
 while parent do
  if parent:GetAttribute('ModalSurface') or parent.Name=='Menu' or parent.Name=='Reveal' or parent.Name=='PetHatch' then return true end
  parent=parent.Parent
 end
 return false
end
local function label(parent, text, size, pos, opts)
	opts = opts or {}
	local l = Instance.new("TextLabel")
	l.Size = size
	l.Position = pos or UDim2.new()
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = opts.color or Pal.Ink
	l.Font = opts.title and FONT_TITLE or FONT_BODY
	l.TextSize = opts.textSize or 18
 l.TextScaled = true
 local textLimit=Instance.new("UITextSizeConstraint")
 textLimit.MinTextSize=12;textLimit.MaxTextSize=l.TextSize;textLimit.Parent=l
	l.TextWrapped = true
	l.AutoLocalize = false
	l.TextXAlignment = opts.align or Enum.TextXAlignment.Center
	if opts.stroke then
		l.TextStrokeColor3 = Pal.Stroke
		l.TextStrokeTransparency = 0
	end
	l.Parent = parent
 if isModal(parent) then Style.ModalText(l,parent:GetAttribute('MarketHeader')==true) end
	return l
end

local function bounce(scale, base)
	scale.Scale = base * 0.86
	TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = base }):Play()
end

local function button(parent, text, callback, size, pos, color)
	local b = Instance.new("TextButton")
	b.Size = size or UDim2.new(1, -12, 0, 44)
	b.Position = pos or UDim2.new()
	b.Text = text
	b.TextColor3 = Pal.Text
	b.TextStrokeColor3 = Pal.Stroke
	b.TextStrokeTransparency = 0.15
	b.Font = FONT_TITLE
	b.TextScaled = true
	b.AutoLocalize = false
	b.TextWrapped = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = 9
	limit.MaxTextSize = 18
	limit.Parent = b
	candy(b, color or Pal.Mint, 14);Style.Shadow(b)
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft, padding.PaddingRight = UDim.new(0, 8), UDim.new(0, 8)
	padding.PaddingTop, padding.PaddingBottom = UDim.new(0, 2), UDim.new(0, 2)
	padding.Parent = b
	local pop = Instance.new("UIScale")
	pop.Parent = b
	b.Activated:Connect(function()
		Sfx.play("Click")
		bounce(pop, 1)
		callback()
	end)
	if RunService:IsStudio() then
		-- Studio's test scripts press a button by firing this (their mouse does not reach the interface)
		local press = Instance.new("BindableEvent")
		press.Name = "DebugPress"
		press.Event:Connect(callback)
		press.Parent = b
	end
	b.Parent = parent
 if isModal(parent) then Style.ModalButton(b,(color==Pal.Accent or color==Pal.Orange) and Style.ModalColors.Gold or color==Pal.Red and Style.ModalColors.Red or color==Pal.Common and Color3.fromRGB(100,107,142) or (color==Pal.Sky2 or color==Pal.Panel or color==Pal.PanelDark) and Style.ModalColors.Cream or Style.ModalColors.Green) end
	return b
end

local function send(op, a, z)
	rem.Intent:FireServer(op, a, z)
end

local function short(n) return L.compact(n,lang) end

-- ---- Always-visible HUD -------------------------------------------------------------------------
local scaled = {} -- UIScale per top-level element, updated together on resize
local function scaledBy(frame)
	local s = Instance.new("UIScale")
	s.Parent = frame
	table.insert(scaled, s)
 frame.Destroying:Connect(function() local i=table.find(scaled,s);if i then table.remove(scaled,i) end end)
	return frame
end

local function iconImage(parent, name, size, pos)
	local img = Instance.new("ImageLabel")
	img.Name = "Icon"
	img.BackgroundTransparency = 1
	img.ScaleType = Enum.ScaleType.Fit
	img.Size = size
	img.Position = pos or UDim2.new()
	img.Image = Icons[name] or ""
	img.Parent = parent
	return img
end

local function modalTitle(card,text,close)
 local bar=Style.ModalHeader(Instance.new('Frame'),true);bar.Name='ModalHeader';bar.Size=UDim2.new(1,-12,0,52);bar.Position=UDim2.fromOffset(6,6);bar.ZIndex=3;bar.Parent=card
 local title=label(bar,text,UDim2.new(1,-72,1,0),UDim2.fromOffset(12,0),{title=true,textSize=26,align=Enum.TextXAlignment.Left})
 local x=button(bar,'×',close or function() card:Destroy() end,UDim2.fromOffset(42,42),UDim2.new(1,-47,0,5),Pal.Red);x.Name='CloseModal';Style.ModalClose(x)
 return title
end

local function iconButton(parent, name, callback, size, pos, color)
	local b = button(parent, Icons[name] and "" or (ICON[name] or "?"), callback, size, pos, color or Pal.Panel)
	local img = iconImage(b, name, UDim2.fromScale(1, 1))
	img.Active = false
	return b
end

-- Coins and the clock share the strip with Roblox's own buttons, which frees a whole row on a phone.
local topGui = Instance.new("ScreenGui")
topGui.Name = "DigTop"
topGui.ResetOnSpawn = false
topGui.ScreenInsets = Enum.ScreenInsets.TopbarSafeInsets
topGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
topGui.Parent = p:WaitForChild("PlayerGui")
local TOP_HEIGHT, TOP_ICONS, HUD_WIDTH = 58, 6, 134 -- gifts and home joined the right row (2026-11-14)
local topScaled = {}
local function topScale(frame)
	local s = Instance.new("UIScale")
	s.Parent = frame
	table.insert(topScaled, s)
	return frame
end

local hud = topScale(Instance.new('Frame'));hud.Name='Hud';hud.Size=UDim2.fromOffset(134,46);hud.AnchorPoint=Vector2.new(.5,.5);hud.Position=UDim2.fromScale(.5,.5);hud.BackgroundTransparency=1;hud.Parent=topGui
local clockBox=candy(Instance.new('Frame'),Pal.Sky2,14);clockBox.Name='Clock';clockBox.Size=UDim2.fromScale(1,1);clockBox.Parent=hud
local clockIcon=iconImage(clockBox,'sun',UDim2.fromOffset(34,34),UDim2.fromOffset(5,6))
local clock=label(clockBox,'',UDim2.new(1,-44,1,0),UDim2.fromOffset(42,0),{textSize=24})
hud.Visible=false -- the day clock lives bottom-right now
local dayClock=scaledBy(Instance.new('Frame'));dayClock.Name='DayClock';dayClock.Size=UDim2.fromOffset(170,64);dayClock.AnchorPoint=Vector2.new(1,1);dayClock.Position=UDim2.new(1,-12,1,-12);dayClock.BackgroundTransparency=1;dayClock.Parent=gui
local dayIcon=iconImage(dayClock,'sun',UDim2.fromOffset(62,62),UDim2.fromOffset(0,1))
local dayText=label(dayClock,'',UDim2.fromOffset(102,60),UDim2.fromOffset(68,2),{title=true,textSize=28,color=Pal.Text,align=Enum.TextXAlignment.Left})
do local st=Instance.new('UIStroke',dayText);st.Color=Color3.fromRGB(18,14,30);st.Thickness=3 end
local metrics=scaledBy(Instance.new('Frame'));metrics.Name='Metrics';metrics.Size=UDim2.fromOffset(340,170);metrics.BackgroundTransparency=1;metrics.Parent=gui
local COIN_PREFIX='$'
-- As in the reference: huge numbers with a thick outline, a shoe for speed and a wad of cash for Zombucks.
local function bigNumber(name,y,height,color,strokeColor)
 local l=label(metrics,'',UDim2.fromOffset(270,height),UDim2.fromOffset(70,y),{title=true,textSize=height,color=color,align=Enum.TextXAlignment.Left});l.Name=name
 local st=Instance.new('UIStroke',l);st.Color=strokeColor;st.Thickness=height>40 and 4 or 3;st.LineJoinMode=Enum.LineJoinMode.Round
 return l
end
iconImage(metrics,'hudSpeed',UDim2.fromOffset(66,58),UDim2.fromOffset(0,0))
iconImage(metrics,'hudZombucks',UDim2.fromOffset(66,58),UDim2.fromOffset(0,62))
local speedText=bigNumber('Speed',2,54,Color3.new(1,1,1),Color3.fromRGB(18,14,30))
local coins=bigNumber('Coins',64,54,Color3.fromRGB(110,255,90),Color3.fromRGB(20,70,20))
-- The third row (owner, 2026-11-12): what is in your hands, big — the shovel, or the gun once you take it out — with
-- its damage now (upgrades included), and your mutagen beside it.
local damageText=bigNumber('Damage',124,40,Color3.new(1,1,1),Color3.fromRGB(18,14,30));damageText.Size=UDim2.fromOffset(96,40);damageText.Position=UDim2.fromOffset(82,124)
local mutagenIcon=Style.ModalArt(metrics,'mutagen',nil,UDim2.fromOffset(46,50),UDim2.fromOffset(180,120));mutagenIcon.Name='MutagenIcon'
local mutagenText=bigNumber('Mutagen',126,36,Color3.fromRGB(184,247,73),Color3.fromRGB(30,60,10));mutagenText.Size=UDim2.fromOffset(110,36);mutagenText.Position=UDim2.fromOffset(228,126)
local toolKey,toolArt
-- Road status shares the metrics block: one heart + count, then the carried grave.
local roadStatus=Instance.new('Frame');roadStatus.Name='RoadStatus';roadStatus.BackgroundTransparency=1;roadStatus.Size=UDim2.fromOffset(214,62);roadStatus.Position=UDim2.fromOffset(0,-66);roadStatus.Visible=false;roadStatus.Parent=metrics
local heartIcon=iconImage(roadStatus,'hudHeart',UDim2.fromOffset(66,58));heartIcon.Name='HeartIcon'
local healthText=bigNumber('RoadHearts',2,54,Color3.new(1,1,1),Color3.fromRGB(18,14,30));healthText.Parent=roadStatus;healthText.Size=UDim2.fromOffset(64,54)
local carryIcon=iconImage(roadStatus,'hudCoffin',UDim2.fromOffset(66,62),UDim2.fromOffset(138,0));carryIcon.Name='CarriedGraveIcon';carryIcon.Visible=false
local income=Instance.new('TextLabel') -- income is displayed overhead, not in the HUD
local slowTimer=label(metrics,'',UDim2.fromOffset(70,26),UDim2.fromOffset(250,16),{textSize=20,stroke=true,color=Pal.Red})
RunService.Heartbeat:Connect(function()
 local weapon=p:GetAttribute('ActiveSlot')==2 and (p:GetAttribute('EquippedWeapon') or 'Deagle');local shovel=p:GetAttribute('EquippedShovel') or 'Chainsaw'
 local skin=p:GetAttribute('EquippedWeaponSkin') or 'Default'
 local key=weapon and ('weapon:'..weapon..':'..skin) or ('shovel:'..shovel)
 if key~=toolKey then
  toolKey=key;if toolArt then toolArt:Destroy() end
  toolArt=weapon and Style.ModalArt(metrics,'weapon',weapon,UDim2.fromOffset(96,72),UDim2.fromOffset(-14,108),skin) or Style.ModalArt(metrics,'shovel',shovel,UDim2.fromOffset(84,80),UDim2.fromOffset(-6,102))
  toolArt.Name='ToolIcon'
 end
 damageText.Text=weapon and tostring(math.floor((p:GetAttribute('WeaponDamage') or WeaponC[weapon].Damage)+.5)) or tostring(require(S.Config.ShovelConfig)[shovel].Damage)
 mutagenText.Text=short(p:GetAttribute('Mutagen') or 0)
 local left=math.max(0,(p:GetAttribute('MutantSlowUntil') or 0)-workspace:GetServerTimeNow());speedText.Text=short(p:GetAttribute('SpeedPoints') or 0);speedText.TextColor3=left>0 and Pal.Red or Pal.Text;slowTimer.Text=left>0 and string.format('◷ %.1f',left) or ''
end)

local topRight = topScale(Instance.new("Frame"))
topRight.Name = "TopRight"
topRight.BackgroundTransparency = 1
topRight.AnchorPoint = Vector2.new(1, 0.5)
topRight.Size = UDim2.fromOffset(TOP_ICONS * TOP_HEIGHT + (TOP_ICONS - 1) * 8, TOP_HEIGHT)
-- Close to the screen's right edge (owner, 2026-11-14): its own layer inside the device's safe area only, since the
-- topbar's safe area kept a wide empty margin on the right on phones; it stays level with Roblox's buttons (layoutTop).
local topRightGui = Instance.new("ScreenGui")
topRightGui.Name = "DigTopRight"
topRightGui.ResetOnSpawn = false
topRightGui.IgnoreGuiInset = true
topRightGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
topRightGui.Parent = p:WaitForChild("PlayerGui")
topRight.Position = UDim2.new(1, -6, 0, 0)
topRight.Parent = topRightGui
local topList = Instance.new("UIListLayout")
topList.FillDirection = Enum.FillDirection.Horizontal
topList.HorizontalAlignment = Enum.HorizontalAlignment.Left
topList.VerticalAlignment = Enum.VerticalAlignment.Center
topList.SortOrder = Enum.SortOrder.LayoutOrder
topList.Padding = UDim.new(0, 8)
topList.Parent = topRight

-- TopbarSafeInsets starts this row after Roblox's system buttons.
local topLeft = topScale(Instance.new("Frame"))
topLeft.Name = "TopLeft"
topLeft.BackgroundTransparency = 1
topLeft.AnchorPoint = Vector2.new(0, 0.5)
topLeft.Size = UDim2.fromOffset(TOP_HEIGHT * 2 + 6, TOP_HEIGHT)
topLeft.Position = UDim2.new(0, 8, 0.5, 0)
topLeft.Parent = topGui
local leftTopList = topList:Clone()
leftTopList.Parent = topLeft

local Notifications = require(S:WaitForChild("Notifications"))
local function flash(text, isError, duration, kind, key)
 Notifications.Show(text, isError and "error" or kind or "info", duration, key)
end

-- Roblox shows its own friend picker. The friend is credited on arrival through ReferredByPlayerId, on the server.
local inviting = false
local function invite()
	if inviting then
		return
	end
	inviting = true
	task.spawn(function()
		local ok, can = pcall(SocialService.CanSendGameInviteAsync, SocialService, p)
		local shown = false
		if ok and can then
			local options = Instance.new("ExperienceInviteOptions")
			options.PromptMessage = t("invitePrompt")
			shown = pcall(SocialService.PromptGameInvite, SocialService, p, options)
		end
		if not shown then
			Sfx.play("Error", 0.4)
			flash(t("inviteUnavailable"), true)
		end
		inviting = false
	end)
end

local tutorialText = ""

local nav = scaledBy(Instance.new("Frame"))
nav.Name = "Nav"
nav.AnchorPoint = Vector2.new(0, 1) -- sits just above the middle of the screen; the slow-mode switch is just below
nav.Size = UDim2.fromOffset(84, 192) -- quests, then Monsterdex; slow mode stays just below
nav.Position = UDim2.new(0, 10, 0.5, -8)
nav.BackgroundTransparency = 1
nav.Parent = gui
local navList = Instance.new("UIGridLayout")
navList.CellSize = UDim2.fromOffset(84, 84)
navList.CellPadding = UDim2.fromOffset(24, 24) -- more room between the Monsterdex and the quests (owner, 2026-11-14)
navList.FillDirectionMaxCells = 1
navList.SortOrder = Enum.SortOrder.LayoutOrder
navList.Parent = nav

local rightBox = scaledBy(Instance.new("Frame"))
rightBox.Name = "RightBox"
rightBox.AnchorPoint = Vector2.new(1, 0.5)
rightBox.Size = UDim2.fromOffset(84, 288)
rightBox.Position = UDim2.new(1, -10, 0.5, 0)
rightBox.BackgroundTransparency = 1
rightBox.Parent = gui
local rightList = Instance.new("UIListLayout")
rightList.FillDirection = Enum.FillDirection.Vertical
rightList.SortOrder = Enum.SortOrder.LayoutOrder
rightList.Padding = UDim.new(0, 18)
rightList.Parent = rightBox

-- Windows: deep navy body, bright blue title bar, red close button; tiles sit on the navy.
local panel = scaledBy(Style.ModalWindow(Instance.new("Frame")))
panel.Name = "Menu"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Size = UDim2.fromOffset(780, 530)
panel.Position = UDim2.new(0.56, 0, 0.5, 42)
panel.Visible = false
panel.ZIndex = 10
panel.Parent = gui
local panelScale = panel:FindFirstChildOfClass("UIScale")

local header = Style.ModalHeader(Instance.new("Frame"))
header.Name="ModalHeader"
header.Size = UDim2.new(1, -32, 0, 76)
header.Position = UDim2.fromOffset(16, 8)
header.Parent = panel
local headingIcon = iconImage(header, "", UDim2.fromOffset(92, 92), UDim2.fromOffset(6, -12))
headingIcon.ZIndex=3
local heading = label(header, "", UDim2.new(1, -178, 1, 0), UDim2.fromOffset(104, 0), { title = true, textSize = 72, color = Pal.Text, stroke = true, align = Enum.TextXAlignment.Left })
local closeButton=button(header, "×", function()
	panel.Visible = false
end, UDim2.fromOffset(58, 58), UDim2.new(1, -68, 0, 9), Pal.Red)
closeButton.Name="CloseModal";Style.ModalClose(closeButton)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -24, 1, -86)
scroll.Position = UDim2.fromOffset(12, 76)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 8
scroll.ScrollBarImageColor3 = Pal.Violet
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new()
scroll.Parent = panel
-- The crypt's buttons at the window's foot (owner, 2026-11-14): "Place best" and "Store all"
local cryptFooter=Instance.new("Frame");cryptFooter.Name="CryptFooter";cryptFooter.BackgroundTransparency=1;cryptFooter.Size=UDim2.new(1,-48,0,56);cryptFooter.Position=UDim2.new(0,24,1,-80);cryptFooter.Visible=false;cryptFooter.Parent=panel
local shopTabs=Instance.new("Frame");shopTabs.Name="ShopCategories";shopTabs.Size=UDim2.fromOffset(98,430);shopTabs.Position=UDim2.fromOffset(10,78);shopTabs.BackgroundTransparency=1;shopTabs.Visible=false;shopTabs.Parent=panel
local list = Instance.new("UIListLayout")
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Padding = UDim.new(0, 10)
list.Parent = scroll
local listPad = Instance.new("UIPadding")
listPad.PaddingLeft, listPad.PaddingRight, listPad.PaddingTop, listPad.PaddingBottom = UDim.new(0, 4), UDim.new(0, 14), UDim.new(0, 4), UDim.new(0, 6)
listPad.Parent = scroll

local uiFactor = 1
local modalLayouts={}
local tutorialWanted=true
local backdrop=Instance.new('ScreenGui');backdrop.Name='ModalBackdrop';backdrop.ResetOnSpawn=false;backdrop.ScreenInsets=Enum.ScreenInsets.None;backdrop.ClipToDeviceSafeArea=false;backdrop.DisplayOrder=19;backdrop.Parent=p.PlayerGui
local shade=Instance.new('TextButton');shade.Name='ModalShade';shade.Text='';shade.Size=UDim2.fromScale(1,1);shade.BackgroundColor3=Color3.new(0,0,0);shade.BackgroundTransparency=.4;shade.AutoButtonColor=false;shade.Visible=false;shade.Active=true;shade.ZIndex=1;shade.Parent=backdrop
-- (A phone layout was tried on 2026-11-14 and rolled back the same day at the owner's request: the windows scale as
-- they always did.)
local function fitModal(frame)
 local v=gui.AbsoluteSize;local size=frame.Size
 local k=math.min(1.4,(v.X-40)/(size.X.Offset+48),(v.Y-24)/(size.Y.Offset+72))
 frame.Position=UDim2.new(.5,0,.5,30*k)
 frame:FindFirstChildOfClass('UIScale').Scale=math.max(.1,k)
 return math.max(.1,k)
end
local savedTouchGuiEnabled
local function refreshModal()
 local otherOpened=panel.Visible or p.PlayerGui:GetAttribute("UpgradeModalOpen")==true or gui:FindFirstChild('Reveal')~=nil or gui:FindFirstChild('PetHatch')~=nil
 gui:SetAttribute("OtherModalOpen",otherOpened)
 local opened=otherOpened or p.PlayerGui:GetAttribute("NightHelpOpen")==true or p.PlayerGui:GetAttribute("HeistHelpOpen")==true
 gui:SetAttribute('ModalOpen',opened);shade.Visible=opened
 local touchGui=p.PlayerGui:FindFirstChild('TouchGui')
 if touchGui then
  if opened then
   if savedTouchGuiEnabled==nil then savedTouchGuiEnabled=touchGui.Enabled end
   touchGui.Enabled=false
  elseif savedTouchGuiEnabled~=nil then touchGui.Enabled=savedTouchGuiEnabled;savedTouchGuiEnabled=nil end
 end
 metrics.Visible=not opened;nav.Visible=not opened;rightBox.Visible=not opened;topRight.Visible=not opened;topLeft.Visible=not opened;dayClock.Visible=not opened
 Notifications.Guide("Tutorial", tutorialText, "guide", tutorialWanted and not opened, 0)
end
panel:GetPropertyChangedSignal('Visible'):Connect(refreshModal)
panel:GetPropertyChangedSignal('Visible'):Connect(function() if not panel.Visible then panel:SetAttribute('MergePicker',nil) end end)
p.PlayerGui:GetAttributeChangedSignal('UpgradeModalOpen'):Connect(refreshModal)
p.PlayerGui:GetAttributeChangedSignal('NightHelpOpen'):Connect(refreshModal)
p.PlayerGui:GetAttributeChangedSignal('HeistHelpOpen'):Connect(refreshModal)
p.PlayerGui.ChildAdded:Connect(function(child) if child.Name=='TouchGui' then refreshModal() end end)
gui.ChildAdded:Connect(function() refreshModal() end)
gui.ChildRemoved:Connect(function(child) modalLayouts[child]=nil;refreshModal() end)
local function responsive()
 local v=gui.AbsoluteSize;if v.X<1 or v.Y<1 then v=workspace.CurrentCamera.ViewportSize end
 local touch=game.UserInputService.TouchEnabled
 uiFactor=math.clamp(math.min(v.X/1000,v.Y/560)*(touch and .8 or 1),touch and .44 or .52,1.1) -- phones: smaller icons (owner, 2026-11-14)
 for _,scale in scaled do if scale.Parent then scale.Scale=uiFactor end end
 panel.Position=UDim2.fromScale(.5,.5);fitModal(panel)
 -- Metrics and road status share one scale and the same safe-area anchor.
 local viewport=workspace.CurrentCamera.ViewportSize
 local metricScale=math.clamp(math.min(viewport.X/1280,viewport.Y/720)*(touch and .78 or 1),touch and .38 or .48,1.25)
 metrics:FindFirstChildOfClass('UIScale').Scale=metricScale
 local statsParent=touch and mobileStats or gui
 if metrics.Parent~=statsParent then metrics.Parent=statsParent end
 metrics.Position=UDim2.new(0,touch and 18 or 14,1,-182*metricScale)
 local centerShift=touch and (mobileStats.AbsolutePosition.Y-gui.AbsolutePosition.Y+(mobileStats.AbsoluteSize.Y-v.Y)/2) or 0
 nav.AnchorPoint=Vector2.new(0,1);nav.Position=UDim2.new(0,10,.5,-8+centerShift+(touch and 13*uiFactor or 0))
 rightBox.AnchorPoint=Vector2.new(1,.5);rightBox.Position=UDim2.new(1,-10,.5,centerShift)
 rightBox.Size=UDim2.fromOffset(84,288) -- pets, crypt, auto-fire
 rightList.FillDirection=Enum.FillDirection.Vertical;rightList.Padding=UDim.new(0,18)
 local clockRight=12
 if touch then
  local jump=p.PlayerGui:FindFirstChild('JumpButton',true)
  clockRight=jump and jump.Visible and math.max(12,gui.AbsolutePosition.X+v.X-jump.AbsolutePosition.X+12) or 100
 end
 dayClock.AnchorPoint=Vector2.new(1,1);dayClock.Position=UDim2.new(1,-clockRight,1,-12)
 for card,layout in modalLayouts do if card.Parent then layout();fitModal(card) end end
 refreshModal()
end
-- The strip is as tall as Roblox's own buttons. The coins stay centred until the icons on the right would touch them.
local function layoutTop()
	local area = topGui.AbsoluteSize
	if area.Y <= 0 then
		return
	end
	local k = math.min(math.max(uiFactor,.76), area.Y / TOP_HEIGHT, area.X / 194)
	for _, s in ipairs(topScaled) do
		s.Scale = k
	end
	local iconsWidth = (TOP_ICONS * TOP_HEIGHT + (TOP_ICONS - 1) * 8) * k
	-- the right row: level with the middle of the topbar
	topRight.Position = UDim2.new(1, -6, 0, topGui.AbsolutePosition.Y + area.Y / 2 - topRightGui.AbsolutePosition.Y)
	local half = HUD_WIDTH * k / 2
	hud.Position = UDim2.new(0, math.max(half, math.min(area.X / 2, area.X - iconsWidth - 10 - half)), 0.5, 0)
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	responsive()
	layoutTop()
end)
topGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutTop);topGui:GetPropertyChangedSignal("AbsolutePosition"):Connect(layoutTop);topRightGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutTop)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(responsive)
mobileStats:GetPropertyChangedSignal("AbsoluteSize"):Connect(responsive)
game.UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(function() responsive();layoutTop() end)
p.PlayerGui.DescendantAdded:Connect(function(c) if c.Name=="JumpButton" then task.defer(responsive) end end)
responsive()
layoutTop()

local coinDisplay = Instance.new("NumberValue")
local coinTween
coinDisplay.Changed:Connect(function(n)
	coins.Text = COIN_PREFIX .. short(n)
end)

local state
local menu = "weapons"
local cardId
local filter = "Crypt"
local signature = ""
-- This script's main chunk stands at Luau's limit of 200 local variables a function, so what was added on 2026-11-16
-- lives in this one table and not in new locals. ADD TO IT rather than declaring more locals at the top level (a
-- script over the limit does not compile: "Out of local registers").
--   sellSel, sellArmedUntil  the crypt's Sell button (owner: "a Sell button in the crypt, showing the sum of the
--                            monsters chosen"): a tap on a monster's card marks it; the ids marked, and the moment
--                            until which a second press of the button confirms the sale
--   blink                    the nav icons that flash because they have something to take: dex - a Monsterdex reward
--                            to claim, crypt - a grave to plant. Set with every State, drawn by the tutorial's pulse
--                            loop (navStroke: each icon's own outline, to give back)
--   showPetCase, caseWaiting the pet pumpkin's case window (below, by showPetHatch)
local More = { sellSel = {}, sellArmedUntil = 0, SELL_MAX = 60, blink = {}, navStroke = {}, dexReadyCount = 0 }
-- A grave's name on its card: the one place to change when graves get more to say (their monster family).
function More.graveTitle(g)
 -- with whose it is (GraveService.Family, 2026-11-16): "Stone grave · Deer"
 return t("grave_" .. g.type) .. (g.family and " · " .. t("roadName_" .. g.family) or "")
end
-- Everything the crypt's Graves tab shows, as one string: the tab is rebuilt when it changes (the timers tick in place).
function More.graveSig(s)
 local sig = {}
 for _, g in ipairs(s.graves or {}) do table.insert(sig, g.slot .. g.type .. (g.remaining == 0 and "r" or "")) end
 for _, g in ipairs(s.graveInventory or {}) do if not g.pendingTransfer then table.insert(sig, "i" .. tostring(g.id)) end end
 for name, n in pairs(s.vouchers or {}) do if n > 0 then table.insert(sig, "v" .. name .. n) end end
 table.sort(sig)
 return table.concat(sig, ",")
end
-- Is there a grave to plant, and room for it in the cemetery? (the crypt icon flashes while there is)
function More.plantable(s)
 if not s or #(s.graves or {}) >= (s.graveCap or math.huge) then return false end
 for _, g in ipairs(s.graveInventory or {}) do if not g.pendingTransfer then return true end end
 for _, n in pairs(s.vouchers or {}) do if n > 0 then return true end end
 return false
end
-- How many monsters wait with a Monsterdex reward: found and not claimed, counted as the Monsterdex window lists them
-- (renderDex). Counted again only when the dex or the claims grew.
function More.dexReady(s)
 local a, b = 0, 0
 for _ in pairs(s.dex or {}) do a += 1 end
 for _ in pairs(s.dexClaims or {}) do b += 1 end
 local key = a .. "/" .. b
 if key ~= More.dexReadyKey then
  local n = 0
  local LM = require(S.Config.LocationMonsters);local claims = s.dexClaims or {};local data = {zombiedex = s.dex}
  for li = 1, #LM.Sets do
   for _, e in LM.Catalog(li) do if not claims["mon:" .. e.Id] and InterfaceRules.Known(data, e.Id) then n += 1 end end
  end
  More.dexReadyKey, More.dexReadyCount = key, n
 end
 return More.dexReadyCount
end
-- A crypt card marked for sale: a gold rim and a tick in its corner.
function More.sellMark(f, on, tierName)
 if on then Style.ModalSelected(f) else f.UIStroke.Transparency = 0;f.UIStroke.Color = Pal[tierName];f.UIStroke.Thickness = 2.5 end
 local c = f:FindFirstChild("SellCheck")
 if on and not c then
  c = Instance.new("Frame");c.Name = "SellCheck";c.Size = UDim2.fromOffset(28, 25);c.Position = UDim2.fromOffset(7, 56);c.BackgroundColor3 = Color3.fromRGB(70, 139, 15);c.BorderSizePixel = 0;c.ZIndex = 6;c.Parent = f
  Instance.new("UICorner", c).CornerRadius = UDim.new(0, 8)
  local st = Instance.new("UIStroke", c);st.Color = Style.ModalColors.Gold;st.Thickness = 2
  local mark = label(c, "✓", UDim2.fromScale(1, 1), nil, {title = true, textSize = 20});mark.TextColor3 = Color3.new(1, 1, 1);mark.ZIndex = 7
 end
 if c then c.Visible = on == true end
end
-- The crypt's foot: Place best and Store all share it with Sell once a monster is marked. The sum is the server's
-- own price for each (Main.server: its income a second, MergeRules.Rate, times ZombieConfig.SaleSeconds).
function More.sellFooter()
 local sell = cryptFooter:FindFirstChild("SellSelected")
 if not sell or not state then return end
 local n, sum = 0, 0
 for _, z in ipairs(state.zombies) do if More.sellSel[z.id] then n += 1;sum += Merge.Rate(z) * ZC.SaleSeconds end end
 local three = filter ~= "Graves" and n > 0
 sell.Visible = three
 sell.Text = os.clock() < More.sellArmedUntil and t("cryptSellSure") or t("cryptSell", {n = n, sum = "$" .. L.compact(math.floor(sum + .5), lang)})
 local w = three and 1 / 3 or .5
 cryptFooter.PlaceBest.Size = UDim2.new(w, -6, 1, 0)
 cryptFooter.StoreAll.Size = UDim2.new(w, -6, 1, 0);cryptFooter.StoreAll.Position = UDim2.new(w, three and 3 or 6, 0, 0)
end

local function row(height,color)
 local f=Style.ModalSurface(Instance.new('Frame'),color or Style.ModalColors.Blue,16);f.Size=UDim2.new(1,0,0,height);f.Parent=scroll;return f
end

local function badge(parent, text, color, pos, width)
	local b = Style.ModalSurface(Instance.new("TextLabel"),color==Style.ModalColors.Green and Color3.fromRGB(70,139,15) or Style.ModalColors.Purple,10,false)
	b.UIStroke.Thickness = 2.5
	b.Size = UDim2.fromOffset(width or 120, 26)
	b.Position = pos
	b.Text = text
	b.Font = FONT_TITLE
	b.TextScaled = true
	b.TextColor3 = Pal.Text
	b.TextStrokeColor3 = Pal.Stroke
	b.TextStrokeTransparency = 0.2
	b.AutoLocalize = false
	b.Parent = parent
 Style.ModalText(b,true)
	return b
end

-- ---- Tiles --------------------------------------------------------------------------------------------
-- Every shop and list is a grid of picture cards for kids: the picture says what it is, one short name,
-- one button. A green button works now; a red one says what is missing when pressed.
local TILE_W, TILE_H = 172, 252
local tileOrder = 0
local function tileGrid(width, height)
	tileOrder += 1
	local holder = Instance.new("Frame")
	holder.Name = "TileGrid"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(1, -6, 0, 0)
	holder.AutomaticSize = Enum.AutomaticSize.Y
	holder.LayoutOrder = tileOrder
	holder.Parent = scroll
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(width or TILE_W, height or TILE_H)
	grid.CellPadding = UDim2.fromOffset(12, 12)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
 grid.HorizontalAlignment=Enum.HorizontalAlignment.Center
	grid.Parent = holder
	return holder
end
local function tile(grid, opts)
	local f = Style.ModalSurface(Instance.new("Frame"), opts.color or Style.ModalColors.Blue,18)
	f.Name = opts.name or "Tile"
	f.LayoutOrder = opts.order or 0
	local gradient = f:FindFirstChildOfClass("UIGradient")
	gradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(150,170,235))
	if opts.selected then
		Style.ModalSelected(f)
	end
	f.Parent = grid
	label(f, opts.title or "", UDim2.new(1, -12, 0, 30), UDim2.fromOffset(6, 5), { title = true, textSize = 25, color = Pal.Text, stroke = true })
	local pic = Instance.new("Frame")
	pic.Name = "Picture"
	pic.BackgroundTransparency = 1
	pic.Size = UDim2.new(1, -12, 1, opts.action and -78 or -40)
	pic.Position = UDim2.fromOffset(6, 36)
	pic.Parent = f
 -- (opts.chip = {text, color}: the same strip under the title with any words - a grave's monster family)
 if opts.rarity or opts.chip then
  local chipColor = opts.chip and opts.chip.color or Pal[opts.rarity]
  pic.Position = UDim2.fromOffset(6, 54)
  pic.Size = UDim2.new(1,-12,1,opts.action and -98 or -62)
  local rarity = Instance.new("Frame")
  rarity.Name = "Rarity"
  rarity.Size = UDim2.new(.56,0,0,17)
  rarity.Position = UDim2.new(.22,0,0,35)
  rarity.BackgroundColor3 = chipColor
  rarity.BorderSizePixel = 0
  rarity.ZIndex = 3
  rarity.Parent = f
  Instance.new("UICorner",rarity).CornerRadius=UDim.new(0,6)
  local stroke=Instance.new("UIStroke",rarity);stroke.Color=chipColor:Lerp(Color3.new(0,0,0),.5);stroke.Thickness=1.5
  if opts.chip then rarity.Size = UDim2.new(.8,0,0,17);rarity.Position = UDim2.new(.1,0,0,35) end
  local caption=label(rarity,opts.chip and opts.chip.text or t(opts.rarity),UDim2.fromScale(1,1),nil,{title=true,textSize=15})
  caption.Name="RarityName";caption.TextColor3=Color3.new(1,1,1);caption.ZIndex=4
  local outline=caption:FindFirstChild("ModalTextOutline");if outline then outline.Color=Color3.fromRGB(25,18,35);outline.Transparency=0;outline.Thickness=1 end
  f.UIStroke.Transparency=0;f.UIStroke.Color=Pal[opts.rarity];f.UIStroke.Thickness=2.5
 end
	if opts.art then
  if menu=="weapons" or menu=="pumpkins" or menu=="traps" then Style.ModalShelf(pic) end
		opts.art(pic)
	end
	if opts.badge then
		badge(f, opts.badge, opts.badgeColor or Pal.Stroke, opts.badgeRight and UDim2.new(1,-(opts.badgeWidth or 96)-8,1,-65) or UDim2.new(0, 8, 1, opts.action and -65 or -30), opts.badgeWidth or 96).Name = "Badge"
	end
	if opts.corner then
		local c = label(f, opts.corner, UDim2.fromOffset(60, 30), UDim2.new(1, -66, 0, opts.rarity and 64 or 36), { title = true, textSize = 24, color = Pal.Text, stroke = true, align = Enum.TextXAlignment.Right })
		c.Name = "Corner"
	end
	if opts.action then
		local a = opts.action
		local b = button(f, a.text, function()
			if a.enabled == false then
				if a.reason then
					flash(a.reason, true)
				end
			else
				a.callback()
			end
		end, UDim2.new(1, -14, 0, 32), UDim2.new(0, 7, 1, -39), a.enabled == false and Pal.Common or (a.color or Pal.Mint))
		b.Name = a.name or "Action"
	end
	-- a tap on the card itself (2026-11-16: a pumpkin opens its case, a crypt monster is marked for sale): the picture
	-- and the name, not the buttons - those stay above it
	local tap
	if opts.tap then
		tap = Instance.new("TextButton")
		tap.Name = "Tap"
		tap.Text = ""
		tap.AutoLocalize = false
		tap.BackgroundTransparency = 1
		tap.Size = UDim2.new(1, 0, 1, opts.action and -42 or 0)
		tap.ZIndex = 5
		tap.Parent = f
		tap.Activated:Connect(function()
			Sfx.play("Click")
			opts.tap(f)
		end)
		if RunService:IsStudio() then
			local press = Instance.new("BindableEvent")
			press.Name = "DebugPress"
			press.Event:Connect(function() opts.tap(f) end)
			press.Parent = tap
		end
	end
	if opts.small then
		local s2 = button(f, opts.small.text, opts.small.callback, UDim2.fromOffset(28, 25), UDim2.new(1, -35, 0, opts.rarity and 56 or 36), opts.small.color or Pal.Red)
		s2.Name = opts.small.name or "Small"
		if tap then s2.ZIndex = math.max(s2.ZIndex, 6) end
	end
	return f
end
-- Pumpkin art from blocks: the bigger and rarer, the fancier.
local PUMPKIN_LOOK = { Pumpkin = { "FF8A1F", 1 }, BigPumpkin = { "FF7A12", 1.3 }, GoldenPumpkin = { "FFD34D", 1.2 }, LunarPumpkin = { "9C7BFF", 1.2 } }
local function pumpkinArt(parent, name)
 if Icons["modal_pumpkin_"..name] then return iconImage(parent,"modal_pumpkin_"..name,UDim2.fromScale(1,1)) end
	local v = Instance.new("ViewportFrame")
	v.BackgroundTransparency = 1
	v.Size = UDim2.fromScale(1, 1)
	v.Ambient = Color3.fromRGB(200, 200, 210)
	v.LightColor = Color3.new(1, 1, 1)
	v.Parent = parent
	local look = PUMPKIN_LOOK[name] or PUMPKIN_LOOK.Pumpkin
	local k = look[2]
	local body = Instance.new("Part")
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(2.3, 2.3, 2.3) * k
	body.Color = Color3.fromHex(look[1])
	body.Parent = v
	for i = 0, 3 do
		local rib = Instance.new("Part")
		rib.Size = Vector3.new(0.14, 2.15 * k, 2.2 * k) -- inside the ball (a Ball is as wide as its smallest side)
		rib.CFrame = CFrame.Angles(0, i * math.pi / 4, 0)
		rib.Color = body.Color:Lerp(Color3.new(0, 0, 0), 0.18)
		rib.Parent = v
	end
	local stem = Instance.new("Part")
	stem.Size = Vector3.new(0.35, 0.8, 0.35) * k
	stem.CFrame = CFrame.new(0, 1.3 * k, 0) * CFrame.Angles(0, 0, 0.2)
	stem.Color = Color3.fromHex("4F8A2E")
	stem.Parent = v
	local camera = Instance.new("Camera")
	camera.FieldOfView = 34
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 1.8, -7.2) * math.max(k, 1), Vector3.new(0, 0.1, 0))
	camera.Parent = v
	v.CurrentCamera = camera
	return v
end
local function petArt(parent, pet)
	local v = Instance.new("ViewportFrame")
	v.BackgroundTransparency = 1
	v.Size = UDim2.fromScale(1, 1)
	v.Ambient = Color3.fromRGB(200, 200, 210)
	v.LightColor = Color3.new(1, 1, 1)
	v.Parent = parent
	local camera = Instance.new("Camera")
	camera.FieldOfView = 34
	camera.Parent = v
	v.CurrentCamera = camera
	local ok, model = pcall(PetModel.Build, pet, v)
	local target = Vector3.new(0, 1, 0)
	local radius = 3
	if ok and typeof(model) == "Instance" and model:IsA("Model") then
		local cf, size = model:GetBoundingBox()
		target, radius = cf.Position, math.max(size.X, size.Y, size.Z)
	end
	camera.CFrame = CFrame.lookAt(target + Vector3.new(radius * 0.35, radius * 0.25, -radius * 1.9), target)
	return v
end

-- All collection cards and reveals share the same portrait renderer.
local function zombieStage(parent,z,size,pos,silhouette,prefer3D)
 return require(S.MonsterPortrait).Create(parent,z,size,pos,{silhouette=silhouette,prefer3D=prefer3D})
end

local function petAbility(pet)
 local n=PetC.Power[pet.species] and PetC.Power[pet.species][pet.tier] or 0
 if pet.species=="BedBanker" then n=L.number(n,lang,2) end -- a multiplier; the dragon's is damage, the cat has none
 return t("petAbility_"..pet.species,{n=n})
end
local function petSend(op,id) rem:WaitForChild(op):FireServer(id) end

local LEFT = Enum.TextXAlignment.Left
local RIGHT = Enum.TextXAlignment.Right
local MENU_ICON = { quests="quests", rewards="daily", inventory="backpack", weapons="modal_weapon_Deagle", pumpkins="modal_pumpkin_Pumpkin", traps="modal_shovel_Steel", info="quests", zombieCard="dex", freeGift="daily" }
local function rateText(z)
	local rate = Merge.Rate(z)
	return L.number(rate, lang, rate % 1 == 0 and 0 or 1)
end
local function starRow(parent, n, size, pos, anchor)
	local f = Instance.new("Frame")
	f.Name = "Stars"
	f.BackgroundTransparency = 1
	f.AnchorPoint = anchor or Vector2.new()
	f.Size = UDim2.fromOffset(n * size + (n - 1) * 2, size)
	f.Position = pos
	local l = Instance.new("UIListLayout")
	l.FillDirection = Enum.FillDirection.Horizontal
	l.Padding = UDim.new(0, 2)
	l.Parent = f
	for _ = 1, n do
		iconImage(f, "star", UDim2.fromOffset(size, size))
	end
	f.Parent = parent
	return f
end
local mergeSel = {}
local function mutationColor(m)
	return m == "Golden" and Pal.Legendary or m == "Lunar" and Pal.Violet or Pal.Pink
end
local function mergeCard(parent, x, width, z, color, tap)
	local c = Style.ModalSurface(Instance.new("Frame"), color, 16)
 if color==Pal.Accent then Style.ModalSelected(c) end
	c.UIStroke.Thickness = 3
	c.Size = UDim2.fromOffset(width, 206)
	c.Position = UDim2.fromOffset(x, 8)
	c.Parent = parent
	if not z then
		label(c, tap and "+" or "?", UDim2.fromScale(1, 1), nil, { title = true, textSize = 56 })
		if tap then -- an empty cell opens the picker
			local b = Instance.new("TextButton");b.Size = UDim2.fromScale(1, 1);b.BackgroundTransparency = 1;b.Text = "";b.AutoLocalize = false;b.ZIndex = 3;b.Parent = c
			b.Activated:Connect(function() Sfx.play("Click");tap() end)
		end
		return c
	end
	zombieStage(c, z, UDim2.fromOffset(width-12, 170), UDim2.fromOffset(6, 6))
	if Merge.Stars(z) > 0 then
		starRow(c, Merge.Stars(z), 22, UDim2.new(0.5, 0, 1, -29), Vector2.new(0.5, 0))
	end
	if z.mutation ~= "None" then
		badge(c, t(z.mutation), mutationColor(z.mutation), UDim2.fromOffset(6, 6), 96)
	end
	if tap then
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromScale(1, 1)
		b.BackgroundTransparency = 1
		b.Text = ""
		b.AutoLocalize = false
		b.ZIndex = 3
		b.Parent = c
		b.Activated:Connect(tap)
	end
	return c
end
local boardState
local function renderInventory()
 label(row(70), t("roadBatHint"), UDim2.fromScale(1,1), nil, {textSize=18})
 label(row(50), t("trapShop",{n=p:GetAttribute("RoadTraps") or 0,max=RoadC.Trap.MaxStock}), UDim2.fromScale(1,1), nil, {title=true,textSize=22})
	label(row(44, Pal.PanelDark), t("inventoryWeapons"), UDim2.new(1, -28, 1, 0), UDim2.fromOffset(14, 0), { title = true, textSize = 24, align = LEFT })
	for _, id in ipairs(WeaponC.Order) do
		if weaponState and weaponState.owned[id] then
			local cfg = WeaponC[id]
			local inHand = weaponState.equipped == id
			local f = row(104, inHand and Pal.Accent or nil)
			Style.ModalArt(f, "weapon", id, UDim2.fromOffset(170, 92), UDim2.fromOffset(8, 6),weaponState.skins and weaponState.skins[id])
			label(f, t(id), UDim2.new(1, -390, 0, 40), UDim2.fromOffset(186, 10), { title = true, textSize = 26, align = LEFT })
			label(f, t("weaponStats", { damage = cfg.Damage, pellets = cfg.Pellets, rate = cfg.FireRate, range = cfg.Range }), UDim2.new(1, -390, 0, 40), UDim2.fromOffset(186, 52), { textSize = 17, align = LEFT })
			if inHand then
				label(f, t("inHand"), UDim2.fromOffset(170, 80), UDim2.new(1, -182, 0, 12), { title = true, textSize = 22 })
			else
				button(f, t("weaponOwned"), function()
					rem.WeaponAction:FireServer("equip", id)
				end, UDim2.fromOffset(170, 80), UDim2.new(1, -182, 0, 12), Pal.Orange)
			end
		end
	end
 for _,g in state.graveInventory or {} do if not g.pendingTransfer then
  local f=row(80);Style.ModalArt(f,"coffin",g.type,UDim2.fromOffset(64,64),UDim2.fromOffset(10,8))
  label(f,t("grave_"..g.type),UDim2.new(.55,-84,1,0),UDim2.fromOffset(84,0),{title=true,align=LEFT})
  button(f,t("selectGrave"),function() send("selectGrave",g.id);panel.Visible=false end,UDim2.fromScale(.43,.8),UDim2.fromScale(.56,.1))
 end end
	local any = false
	for _, name in ipairs(GC.Order) do
		any = any or (state.vouchers[name] or 0) > 0
	end
	label(row(any and 44 or 70, Pal.PanelDark), t(any and "inventoryGraves" or "inventoryNoGraves"), UDim2.new(1, -28, 1, 0), UDim2.fromOffset(14, 0), { title = true, textSize = 20, align = LEFT })
	for _, name in ipairs(GC.Order) do
		local n = state.vouchers[name] or 0
		if n > 0 then
			local f = row(72)
			Style.ModalArt(f, "grave", name, UDim2.fromOffset(60, 60), UDim2.fromOffset(10, 6))
			label(f, t("grave_" .. name), UDim2.new(1, -380, 1, 0), UDim2.fromOffset(84, 0), { title = true, textSize = 24, align = LEFT })
			label(f, "× " .. n, UDim2.fromOffset(90, 72), UDim2.new(1, -290, 0, 0), { title = true, textSize = 28, align = RIGHT })
			button(f, t("selectGrave"), function()
				send("plantVoucher", name);panel.Visible=false
			end, UDim2.fromOffset(180, 56), UDim2.new(1, -190, 0, 8), Pal.Mint)
		end
	end
end
local function renderSettings()
 -- SmallMonsters (2026-11-16) is the one that is off unless turned on: your own farm monsters pet-sized, on your screen only
 for _,key in {'AutoFire','GuideArrows','ShiftSlow','CameraShake','ShowNightInfo','ShowHeistInfo','SmallMonsters'} do
 local value=p:GetAttribute(key)~=false;if key=='SmallMonsters' then value=p:GetAttribute(key)==true end
 button(row(58),t(key)..(value and ' ✓' or ' —'),function() rem.InterfaceAction:FireServer('setting',key,not value) end,UDim2.new(1,-12,1,-12),UDim2.fromOffset(6,6),value and Pal.Mint or Pal.Common)
 end
 for _,key in {'MusicVolume','SfxVolume'} do
 local f=row(70);label(f,t(key),UDim2.fromScale(.4,1),nil,{textSize=22})
 for i,value in {0,.25,.5,.75,1} do button(f,tostring(math.floor(value*100))..'%',function() rem.InterfaceAction:FireServer('setting',key,value) end,UDim2.fromScale(.11,.8),UDim2.fromScale(.41+(i-1)*.115,.1),(p:GetAttribute(key) or 1)==value and Pal.Mint or Pal.Panel) end
 end


	local f = row(136)
	label(f, t("language"), UDim2.new(1, -28, 0, 44), UDim2.fromOffset(14, 8), { title = true, textSize = 26, align = LEFT })
	local current = state.language or "auto"
	for i, code in ipairs({ "auto", "en", "ru" }) do
		button(f, t("language_" .. code), function()
			send("language", code)
		end, UDim2.new(1 / 3, -14, 0, 68), UDim2.new((i - 1) / 3, 7, 0, 56), current == code and Pal.Orange or Pal.Sky2)
	end
end
local questBars = {}
local referenceView
local questTimer
local function progressText(item)
	return short(QuestRules.Show(item, item.progress)) .. " / " .. short(QuestRules.Show(item, item.goal))
end
local function resetText()
	local left = QuestRules.SecondsLeft()
	return t("questReset", { h = math.floor(left / 3600), m = math.floor(left % 3600 / 60) })
end
local function rounded(f, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = f
end
local QUEST_ICON = { dig = "⛏️", plant = "🌱", time = "⏰", earn = "💰", dawn = "🌅", upgrade = "⬆️", kill = "👹", rare = "💎", hatch = "🎃", road = "🛣️" }
local function questTile(grid, item, order)
	local done = item.progress >= item.goal
	local f = tile(grid, {
		order = order,
		name = "Quest_" .. item.id,
		title = t("quest_" .. item.id, { n = short(QuestRules.Show(item, item.goal)) }),
		color = item.claimed and Pal.Common or done and Pal.Mint or Pal.Sky2,
		art = function(pic)
			label(pic, QUEST_ICON[item.kind or item.id] or QUEST_ICON[(item.id or ""):match("^%a+")] or "⭐", UDim2.new(1, 0, 1, -30), nil, { textSize = 64 })
			local track = Instance.new("Frame")
			track.Size = UDim2.new(1, -8, 0, 24)
			track.Position = UDim2.new(0, 4, 1, -26)
			track.BackgroundColor3 = Pal.Stroke
			track.BorderSizePixel = 0
			rounded(track, 10)
			track.Parent = pic
			local fill = Instance.new("Frame")
			fill.Size = UDim2.fromScale(math.clamp(item.progress / item.goal, 0, 1), 1)
			fill.BackgroundColor3 = Pal.Accent
			fill.BorderSizePixel = 0
			rounded(fill, 10)
			fill.Parent = track
			local count = label(track, progressText(item), UDim2.fromScale(1, 1), nil, { textSize = 16, color = Pal.Text, stroke = true })
			questBars[item.id] = { fill = fill, count = count }
		end,
		badge = "$" .. short(item.reward),
		badgeWidth = 90,
		action = item.claimed and { text = "✓", enabled = false, callback = function() end }
			or done and { text = t("claim"), color = Pal.Orange, callback = function() send("quest", item.id) end }
			or { text = progressText(item), enabled = false, reason = t("questNotYet"), callback = function() end },
	})
	return f
end
local function renderQuests()
	questBars = {}
	local q = state.quests
	if not q then
		return
	end
	local grid = tileGrid(180, 230)
	for i, item in ipairs(q.items) do
		questTile(grid, item, i)
	end
	local ready = not q.bonusClaimed
	for _, item in ipairs(q.items) do
		ready = ready and item.claimed
	end
	tile(grid, {
		order = 10,
		name = "QuestBonus",
		title = t("questBonus"),
		color = q.bonusClaimed and Pal.Common or ready and Pal.Pink or Pal.Violet,
		art = function(pic)
			Style.ModalArt(pic, "grave", q.bonus.grave)
		end,
		badge = "×" .. q.bonus.count,
		badgeWidth = 60,
		action = q.bonusClaimed and { text = "✓", enabled = false, callback = function() end }
			or { text = t("claim"), enabled = ready, reason = t("questNotYet"), color = Pal.Pink, callback = function() send("quest", "bonus") end },
	})
	questTimer = label(row(44), resetText(), UDim2.fromScale(1, 1), nil, { textSize = 18 })
end
local MEDAL = { "🥇", "🥈", "🥉" }
local function renderTop()
	local entries = boardState and boardState.entries or {}
	local mine
	for i, e in ipairs(entries) do
		if e.id == p.UserId then
			mine = i
			break
		end
	end
	local me = row(64, Pal.Accent)
	label(me, mine and t("topYou", { n = mine }) or t("topNotYet"), UDim2.new(0.5, -14, 1, 0), UDim2.fromOffset(14, 0), { title = true, textSize = 24, align = LEFT })
	label(me, t("topPeak", { n = short(state.peak or 0) }), UDim2.new(0.5, -14, 1, 0), UDim2.fromScale(0.5, 0), { textSize = 20, align = RIGHT })
	local inv = row(96)
	label(inv, t("inviteInfo"), UDim2.new(1, -230, 1, -8), UDim2.fromOffset(14, 4), { textSize = 18, align = LEFT })
	button(inv, ICON.invite .. " " .. t("invite"), invite, UDim2.fromOffset(190, 64), UDim2.new(1, -202, 0, 16), Pal.Mint)
	if #entries == 0 then
		label(row(70), t("topEmpty"), UDim2.fromScale(1, 1), nil, { title = true, textSize = 22 })
	end
	for i, e in ipairs(entries) do
		local f = row(56, e.id == p.UserId and Pal.Accent or nil)
		label(f, MEDAL[i] or ("#" .. i), UDim2.fromOffset(60, 56), UDim2.fromOffset(6, 0), { title = true, textSize = i <= 3 and 30 or 22 })
		local head = Instance.new("ImageLabel")
		head.Size = UDim2.fromOffset(44, 44)
		head.Position = UDim2.fromOffset(70, 6)
		head.BackgroundColor3 = Pal.Panel
		head.BorderSizePixel = 0
		head.Image = e.id > 0 and ("rbxthumb://type=AvatarHeadShot&id=" .. e.id .. "&w=48&h=48") or ""
		rounded(head, 10)
		head.Parent = f
		label(f, e.name, UDim2.new(1, -340, 1, 0), UDim2.fromOffset(124, 0), { textSize = 22, align = LEFT })
		label(f, "💰 " .. short(e.value) .. t("perSecond"), UDim2.fromOffset(200, 56), UDim2.new(1, -212, 0, 0), { title = true, textSize = 22, align = RIGHT })
	end
end
local render
local houseTimer
local treadmillText
local function treadmillLine()
	local level = RoadC.Treadmill[state.treadmill or 1]
	return t("treadmillLine", { speed = L.compact(state.speed or 0, lang), rate = L.number(level.Rate, lang, 2) })
end
local function clockText(left)
	return string.format("%d:%02d", math.floor(left / 60), left % 60)
end
local function renderHouse()
	houseTimer = nil
	local level = state.house or 1
	local current, nextLevel = HouseC.Levels[level], HouseC.Levels[level + 1]
	local top = row(nextLevel and 186 or 112, Pal.Accent)
	iconImage(top, "house", UDim2.fromOffset(96, 96), UDim2.fromOffset(8, 8))
	label(top, t("houseLevel", { n = level }), UDim2.new(1, -130, 0, 40), UDim2.fromOffset(112, 8), { title = true, textSize = 28, align = LEFT })
	if nextLevel then
		local parts = {}
		for _, zone in ipairs(HouseC.Zones) do
			if current.Limits[zone] ~= nextLevel.Limits[zone] then
				table.insert(parts, t(zone) .. " " .. current.Limits[zone] .. " → " .. nextLevel.Limits[zone])
			end
		end
		label(top, table.concat(parts, " · "), UDim2.new(1, -130, 0, 60), UDim2.fromOffset(112, 50), { textSize = 18, align = LEFT })
		if (state.houseLeft or 0) > 0 then
			houseTimer = label(top, t("houseBuilding", { time = clockText(state.houseLeft) }), UDim2.new(1, -24, 0, 56), UDim2.fromOffset(12, 120), { title = true, textSize = 26 })
		else
			button(top, t("houseGo", { price = short(nextLevel.Price), time = t("timeMin", { n = math.ceil(nextLevel.Seconds / 60) }) }), function()
				send("houseUpgrade")
			end, UDim2.new(1, -24, 0, 56), UDim2.fromOffset(12, 120), Pal.Pink)
		end
	else
		label(top, t("houseMax"), UDim2.new(1, -130, 0, 50), UDim2.fromOffset(112, 50), { textSize = 18, align = LEFT })
	end
	local tm = row(80)
	label(tm, t("treadmill"), UDim2.fromOffset(340, 34), UDim2.fromOffset(14, 4), { title = true, textSize = 22, align = LEFT })
	treadmillText = label(tm, treadmillLine(), UDim2.fromOffset(390, 38), UDim2.fromOffset(14, 38), { textSize = 17, align = LEFT })
	local tmNext = RoadC.Treadmill[(state.treadmill or 1) + 1]
	if tmNext then
		button(tm, "➕ 💰 " .. short(tmNext.Price), function()
			send("treadmill")
		end, UDim2.fromOffset(300, 56), UDim2.new(1, -310, 0, 12), Pal.Orange)
	else
		label(tm, t("zoneMax"), UDim2.fromOffset(300, 80), UDim2.new(1, -310, 0, 0), { textSize = 20 })
	end
	local profile = { upgrades = state.upgrades, houseLevel = level }
	for _, zone in ipairs(HouseC.Zones) do
		local cap = HouseRules.Cap(profile, zone)
		local need = HouseRules.Need(profile, zone)
		local f = row(66)
		label(f, (ICON[zone] or "") .. " " .. t(zone), UDim2.fromOffset(250, 66), UDim2.fromOffset(14, 0), { title = true, textSize = 22, align = LEFT })
		label(f, cap .. " / " .. current.Limits[zone], UDim2.fromOffset(110, 66), UDim2.fromOffset(264, 0), { title = true, textSize = 24 })
		if cap >= ZoneC[zone].Max then
			label(f, t("zoneMax"), UDim2.fromOffset(300, 66), UDim2.new(1, -310, 0, 0), { textSize = 20 })
		elseif need then
			label(f, t("houseNeed", { n = need }), UDim2.fromOffset(300, 66), UDim2.new(1, -310, 0, 0), { textSize = 20 })
		else
			local c = UC[zone]
			button(f, "➕ 💰 " .. short(c.Price * c.Factor ^ (state.upgrades[zone] or 0)), function()
				send("upgrade", zone)
			end, UDim2.fromOffset(300, 54), UDim2.new(1, -310, 0, 6), Pal.Orange)
		end
	end
end
local function renderMerge()
	local byId = {}
	for _, z in ipairs(state.zombies) do
		byId[z.id] = z
	end
	local sel = {}
	for _, id in ipairs(mergeSel) do
		local z = byId[id]
		if z and Merge.Free(z) and (not sel[1] or Merge.Match(sel[1], z)) then
			table.insert(sel, z)
		end
	end
	mergeSel = {}
	for _, z in ipairs(sel) do
		table.insert(mergeSel, z.id)
	end
	local top = Style.ModalRow(row(222, Pal.PanelDark))
	for i = 1, 3 do
		local z = sel[i]
		-- a full cell gives its monster back; an empty one opens the picture picker (owner, 2026-11-13)
		mergeCard(top, 6 + (i - 1) * 174, 142, z, z and Pal.Panel or Pal.PanelDark, z and function()
			Sfx.play("Click")
			table.remove(mergeSel, i)
			render()
		end or function()
			panel:SetAttribute("MergePicker", true)
			render()
		end)
	end
	for _,x in ipairs({148,322}) do label(top,"+",UDim2.fromOffset(32,206),UDim2.fromOffset(x,8),{title=true,textSize=40}) end
 Style.ModalArrow(top,UDim2.fromOffset(40,40),UDim2.fromOffset(496,91))
	local result
	if sel[1] then
		result = Merge.Result(sel)
	end
	local card = mergeCard(top, 542, 162, result, Pal.Accent)
	if result then
		label(card, t("incomeShort", { n = rateText(result) }), UDim2.fromOffset(100, 26), UDim2.new(1, -104, 0, 6), { title = true, textSize = 20, align = RIGHT })
	end
	local ready = #sel == 3
	button(Style.ModalRow(row(64)), t("mergeGo"), function()
		if #mergeSel == 3 then
			rem.Merge:FireServer(mergeSel[1], mergeSel[2], mergeSel[3])
			mergeSel = {}
		else
			Sfx.play("Error", 0.4)
			flash(t("mergeNeedThree"), true)
		end
	end, UDim2.new(1, -12, 0, 52), UDim2.fromOffset(6, 6), ready and Pal.Mint or Pal.Common)
 local controls=Style.ModalRow(row(54))
 button(controls,t("mergeClear"),function() mergeSel={};render() end,UDim2.new(.5,-8,0,44),UDim2.fromOffset(4,4),Pal.Sky2)
 button(controls,"← "..t("crypt"),function() menu="crypt";scroll.CanvasPosition=Vector2.zero;render() end,UDim2.new(.5,-8,0,44),UDim2.new(.5,4,0,4),Pal.Mint)
	-- The choices are picture cards (owner, 2026-11-13: "show a choice of monster icons, not a list"): with a monster
	-- chosen, every one that matches it; before that, one card per kind that can still gain a star, and a tap on a
	-- kind with three or more fills all three cells. The same cards fill the picker that an empty cell opens.
	local function pick(z)
		table.insert(mergeSel, z.id)
		panel:SetAttribute("MergePicker", nil)
		render()
	end
	local function fill(grid)
		local n = 0
		local function mutationMark(z)
			return z.mutation ~= "None" and (z.mutation == "Golden" and "✨" or z.mutation == "Lunar" and "🌙" or "🌈") or nil
		end
		if sel[1] then
			for _, z in ipairs(Merge.SortByIncome(state.zombies)) do
				if Merge.Free(z) and Merge.Match(sel[1], z) and not table.find(mergeSel, z.id) then
					n += 1
					local tierName = ZC.Tiers[z.tier]
					tile(grid, { order = n, name = "MergePick_" .. z.id, title = t(z.type), color = Pal[tierName], rarity = tierName,
						art = function(f) zombieStage(f, z, UDim2.fromScale(1, 1));starRow(f, Merge.Stars(z), 16, UDim2.new(0, 1, 1, -17)) end,
						corner = mutationMark(z), badge = t(z.zone), badgeWidth = 84,
						action = #mergeSel < 3 and { text = t("mergePick"), callback = function() pick(z) end } or { text = "✓", enabled = false, callback = function() end } })
				end
			end
		else
			for _, g in ipairs(Merge.Groups(state.zombies)) do
				n += 1
				local count, tierName = #g.members, ZC.Tiers[g.tier]
				local look = { type = g.type, tier = g.tier, stars = g.stars, mutation = "None" }
				tile(grid, { order = n, name = "MergeKind_" .. g.type .. g.tier .. g.stars, title = t(g.type), color = Pal[tierName], rarity = tierName,
					selected = count >= 3,
					art = function(f) zombieStage(f, look, UDim2.fromScale(1, 1));starRow(f, g.stars, 16, UDim2.new(0, 1, 1, -17)) end,
					badge = "× " .. count, badgeWidth = 64,
					action = count >= 3 and { text = t("mergePick"), callback = function()
						mergeSel = {}
						for _, z in ipairs(Merge.Pick(g.members)) do table.insert(mergeSel, z.id) end
						panel:SetAttribute("MergePicker", nil)
						render()
					end } or { text = t("mergeNeed", { n = 3 - count }), enabled = false, reason = t("mergeNeed", { n = 3 - count }), callback = function() end } })
			end
		end
		return n
	end
	if fill(tileGrid(150, 236)) == 0 then
		label(row(70), t("mergeNone"), UDim2.fromScale(1, 1), nil, { title = true, textSize = 22 })
	end
	-- The picker over the window, opened by an empty cell
	if panel:GetAttribute("MergePicker") then
		local o = Style.ModalSurface(Instance.new("Frame"), Style.ModalColors.Blue, 18)
		o.Name = "MergePicker";o.Size = UDim2.new(1, -36, 1, -110);o.Position = UDim2.fromOffset(18, 94);o.ZIndex = 20;o.Active = true;o.Parent = panel
		label(o, t("mergeChoose"), UDim2.new(1, -90, 0, 42), UDim2.fromOffset(16, 8), { title = true, textSize = 28, color = Pal.Text, stroke = true, align = LEFT })
		local x = button(o, "×", function() panel:SetAttribute("MergePicker", nil);render() end, UDim2.fromOffset(46, 46), UDim2.new(1, -56, 0, 6), Pal.Red)
		Style.ModalClose(x)
		local sf = Instance.new("ScrollingFrame")
		sf.BackgroundTransparency = 1;sf.BorderSizePixel = 0;sf.Size = UDim2.new(1, -16, 1, -64);sf.Position = UDim2.fromOffset(8, 58)
		sf.AutomaticCanvasSize = Enum.AutomaticSize.Y;sf.CanvasSize = UDim2.new();sf.ScrollBarThickness = 8;sf.ScrollBarImageColor3 = Pal.Violet;sf.Parent = o
		local holder = Instance.new("Frame");holder.BackgroundTransparency = 1;holder.Size = UDim2.new(1, -10, 0, 0);holder.AutomaticSize = Enum.AutomaticSize.Y;holder.Parent = sf
		local g = Instance.new("UIGridLayout");g.CellSize = UDim2.fromOffset(150, 236);g.CellPadding = UDim2.fromOffset(10, 10);g.SortOrder = Enum.SortOrder.LayoutOrder
		g.HorizontalAlignment = Enum.HorizontalAlignment.Center;g.Parent = holder
		if fill(holder) == 0 then label(o, t("mergeNone"), UDim2.new(1, -24, 0, 60), UDim2.fromOffset(12, 120), { title = true, textSize = 24, color = Pal.Text, stroke = true }) end
		local keepY = panel:GetAttribute("MergePickerY") or 0
		if keepY > 0 then -- the picker is rebuilt with the window: keep its place too
			task.spawn(function()
				for _ = 1, 4 do
					if not sf.Parent then return end
					sf.CanvasPosition = Vector2.new(0, keepY)
					game:GetService("RunService").Heartbeat:Wait()
				end
			end)
		end
	end
end

-- Monsterdex v2 (owner, 2026-11-12: "refactor it visually, use the 2D icons"). Picture cards: every monster is its
-- painted portrait; one still unknown is a dark silhouette with a question mark, so you can see what you hunt.
-- The page tint is the mutation (gold, moonlight, a rainbow shimmer). The big card shows the selected monster with
-- its rarity and income; the progress bar carries the milestone gifts, their buttons sit under the big card.
local DEX_TINT={Golden=Color3.fromRGB(255,215,120),Lunar=Color3.fromRGB(185,170,255)}
local function dexPortrait(parent,id,known,page,size,pos)
 if not require(S.MonsterCollection).Icon(id,Icons) then -- missing painted assets keep the 3D fallback
  local v=require(S.MonsterPortrait).Create(parent,{id=id,type=id,tier=1,mutation='None'},size,pos,{silhouette=not known});v.Name='DexPortrait';v.ZIndex=3
  if known and DEX_TINT[page] then v.ImageColor3=DEX_TINT[page] end
  return v
 end
 local img=Instance.new('ImageLabel');img.Name='DexPortrait';img.BackgroundTransparency=1;img.ScaleType=Enum.ScaleType.Fit;img.Active=false
 img.Image=Icons['modal_monster_'..id] or '';img.Size=size;img.Position=pos or UDim2.new();img.ZIndex=3;img.Parent=parent
 if not known then
  img.ImageColor3=Color3.fromRGB(44,26,74)
 elseif DEX_TINT[page] then img.ImageColor3=DEX_TINT[page]
 elseif page=='Rainbow' then
  local g=Instance.new('UIGradient');g.Rotation=25;g.Parent=img
  g.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,150,150)),ColorSequenceKeypoint.new(.25,Color3.fromRGB(255,235,140)),ColorSequenceKeypoint.new(.5,Color3.fromRGB(150,255,170)),ColorSequenceKeypoint.new(.75,Color3.fromRGB(150,200,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(230,160,255))})
  TweenService:Create(g,TweenInfo.new(2.4,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Offset=Vector2.new(.35,0)}):Play()
 end
 return img
end
-- The white question mark over a silhouette
local function dexMark(parent,size,pos)
 local q=Instance.new('TextLabel');q.Name='Unknown';q.BackgroundTransparency=1;q.Text='?';q.Font=FONT_TITLE;q.TextScaled=true;q.AutoLocalize=false
 q.TextColor3=Color3.new(1,1,1);q.Size=size;q.Position=pos;q.ZIndex=5;q.Parent=parent
 local st=Instance.new('UIStroke',q);st.Color=Color3.fromRGB(42,18,72);st.Thickness=3
 return q
end
-- A soft light behind the portrait
local function dexGlow(parent,size,pos,color)
 local g=Instance.new('Frame');g.Name='Glow';g.BackgroundColor3=color;g.BackgroundTransparency=.35;g.BorderSizePixel=0;g.Size=size;g.Position=pos;g.ZIndex=2;g.Parent=parent
 Instance.new('UICorner',g).CornerRadius=UDim.new(1,0)
 local gr=Instance.new('UIGradient',g);gr.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.7,.35),NumberSequenceKeypoint.new(1,1)});gr.Rotation=90
 return g
end
-- The Monsterdex by location (owner, 2026-11-14, after the reference "pet list"; no tabs since the same day: "the
-- scroll does it"): every location one after another, its card on the left (name, found/total, "Claim all") and the
-- monsters it can give on the right (found ones in their rarity's colour, the rest a dark silhouette with "???"). A
-- found monster's one-time reward is taken from its own card. Which monsters: LocationMonsters.
local function renderDex()
 local LM=require(S.Config.LocationMonsters);local districts=require(S.Config.WorldConfig).Districts
 local claims=state.dexClaims or {};local data={zombiedex=state.dex}
 local width=math.max(400,scroll.AbsoluteSize.X/math.max(.1,panel:FindFirstChildOfClass('UIScale').Scale)-16)
 local lw,cw,ch,gap=150,104,138,6
 local cols=math.max(2,math.floor((width-lw-12)/(cw+gap)))
 for li=1,#LM.Sets do
  local dd=districts[li];local list=LM.Catalog(li)
  local found,ready=0,0
  for _,e in list do if InterfaceRules.Known(data,e.Id) then found+=1;if not claims['mon:'..e.Id] then ready+=1 end end end
  local gridH=math.max(1,math.ceil(#list/cols))*(ch+gap)
  local body=row(math.max(gridH+8,190));Style.ModalRow(body);body.Name='DexLocation_'..li
  -- the location
  local tint=dd and Color3.fromHex(dd.Fog) or Style.ModalColors.Blue
  local place=Style.ModalSurface(Instance.new('Frame'),tint:Lerp(Color3.new(1,1,1),.15),14);place.Name='Location';place.Size=UDim2.new(0,lw,1,-8);place.Position=UDim2.fromOffset(4,4);place.Parent=body
  label(place,dd and dd.Emoji or '',UDim2.new(1,0,0,46),UDim2.fromOffset(0,6),{textSize=40})
  label(place,dd and t(dd.Title) or '',UDim2.new(1,-10,0,46),UDim2.fromOffset(5,52),{title=true,textSize=20})
  local bar=candy(Instance.new('Frame'),Color3.fromRGB(30,24,40),8);bar.Name='Found';bar.Size=UDim2.new(1,-16,0,26);bar.Position=UDim2.fromOffset(8,104);bar.Parent=place
  local fill=Instance.new('Frame',bar);fill.BorderSizePixel=0;fill.Size=UDim2.new(#list>0 and found/#list or 0,0,1,0);fill.BackgroundColor3=Pal.Mint;Instance.new('UICorner',fill).CornerRadius=UDim.new(0,8)
  local tally=label(bar,found..'/'..#list,UDim2.fromScale(1,1),nil,{title=true,textSize=18,color=Color3.new(1,1,1)});tally.ZIndex=4
  local ts=Instance.new('UIStroke',tally);ts.Color=Color3.fromRGB(20,14,30);ts.Thickness=2
  if ready>0 then
   button(place,t('dexClaimAll',{n=ready}),function() rem.InterfaceAction:FireServer('dexAll',tostring(li)) end,UDim2.new(1,-16,0,38),UDim2.fromOffset(8,138),Pal.Mint)
  end
  -- its monsters
  for i,entry in list do
   local id,tier=entry.Id,entry.Tier;local known=InterfaceRules.Known(data,id);local claimed=claims['mon:'..id]
   local x,y=lw+12+((i-1)%cols)*(cw+gap),4+math.floor((i-1)/cols)*(ch+gap)
   local rarity=Pal[ZC.Tiers[tier]] or Pal.Common
   local card=Style.ModalSurface(Instance.new('Frame'),known and rarity:Lerp(Color3.new(1,1,1),.2) or rarity:Lerp(Color3.fromRGB(40,30,60),.55),14,false)
   card.Name='DexCard_'..id;card.Size=UDim2.fromOffset(cw,ch);card.Position=UDim2.fromOffset(x,y);card.Parent=body
   dexGlow(card,UDim2.fromOffset(78,78),UDim2.fromOffset(13,22),known and Color3.new(1,1,1) or Color3.fromRGB(70,52,104))
   dexPortrait(card,id,known,'None',UDim2.fromOffset(86,86),UDim2.fromOffset(9,18))
   if not known then dexMark(card,UDim2.fromOffset(40,46),UDim2.fromOffset(32,36)) end
   local caption=label(card,known and t(id) or '???',UDim2.new(1,-6,0,20),UDim2.fromOffset(3,2),{title=true,textSize=15,color=Color3.new(1,1,1)});caption.ZIndex=4;caption.UITextSizeConstraint.MinTextSize=8
   local cs=Instance.new('UIStroke',caption);cs.Color=Color3.fromRGB(30,18,46);cs.Thickness=2
   local reward=InterfaceRules.MonsterReward(id) or {coins=0,speed=0}
   if known and not claimed then
    local b=button(card,'$'..short(reward.coins),function() rem.InterfaceAction:FireServer('dexMon',id) end,UDim2.new(1,-8,0,30),UDim2.new(0,4,1,-34),Pal.Mint);b.ZIndex=8
    local gift=iconImage(card,'daily',UDim2.fromOffset(26,26),UDim2.new(1,-28,0,20));gift.ZIndex=8
   elseif known then
    local done=label(card,'✓',UDim2.fromOffset(26,26),UDim2.new(1,-28,1,-28),{title=true,textSize=22,color=Color3.fromRGB(150,255,90)});done.ZIndex=8
   end
  end
 end
end
render = function()
	if not state then
		return
	end
	-- A re-render on a state tick keeps the reader's place (owner, 2026-11-13: "scrolling the merge window throws you
	-- back to the top"): the window is rebuilt, so the canvas shrinks for a frame and the position snaps to zero.
	-- A deliberate jump (a new tab, a filter) zeroes CanvasPosition before calling render, so nothing is kept then.
	local keep = scroll:GetAttribute("RenderedMenu") == menu and scroll.CanvasPosition or Vector2.zero
	scroll:SetAttribute("RenderedMenu", menu)
	if keep.Y > 0 then
		task.spawn(function()
			for _ = 1, 4 do
				if scroll:GetAttribute("RenderedMenu") ~= menu then return end
				scroll.CanvasPosition = keep
				game:GetService("RunService").Heartbeat:Wait()
			end
		end)
	end
	for _, c in ipairs(scroll:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
 headingIcon.Size=UDim2.fromOffset(92,92);headingIcon.Position=UDim2.fromOffset(6,-12)
 local oldReference=panel:FindFirstChild('ReferenceContent');if oldReference then oldReference:Destroy() end
 referenceView=nil
 scroll.Visible=true
 header.Position=UDim2.fromOffset(16,8);header.Size=UDim2.new(1,-32,0,76);header.ZIndex=1
 header.MarketCanopy.Position=UDim2.fromOffset(-24,-72);header.MarketCanopy.Size=UDim2.new(1,48,0,174);header.MarketCanopy.ZIndex=1
 panel.MarketSkin.ZIndex=1;heading.ZIndex=3;headingIcon.ZIndex=3;closeButton.ZIndex=1
 local oldPicker=panel:FindFirstChild("MergePicker")
 if oldPicker then local sf=oldPicker:FindFirstChildWhichIsA("ScrollingFrame");panel:SetAttribute("MergePickerY",sf and sf.CanvasPosition.Y or 0);oldPicker:Destroy() else panel:SetAttribute("MergePickerY",0) end
 if menu~="merge" then panel:SetAttribute("MergePicker",nil) end
 local isShop=menu=="weapons" or menu=="pumpkins" or menu=="traps"
 -- Each stall sells one thing now, so the window is all tiles: no category column.
 local single=menu=="weapons" or menu=="pumpkins" or menu=="weaponSkins"
 panel.Size=UDim2.fromOffset(isShop and 800 or 780,single and (menu=="weapons" and 500 or menu=="weaponSkins" and 580 or 432) or menu=="traps" and (game.UserInputService.TouchEnabled and 490 or 660) or menu=="pets" and 490 or menu=="rewards" and 584 or 560)
 if menu=="weapons" then panel.Size=UDim2.fromOffset(800,640)
 elseif menu=="crypt" then panel.Size=UDim2.fromOffset(800,686)
 elseif menu=="merge" then panel.Size=UDim2.fromOffset(780,550) end
 TILE_H=menu=="weapons" and 212 or menu=="crypt" and 236 or single and 280 or 252;TILE_W=(isShop or menu=="crypt") and 172 or 166
 fitModal(panel)
 scroll.Position=UDim2.fromOffset(24,108);scroll.Size=UDim2.new(1,-48,1,-132)
 cryptFooter.Visible=menu=="crypt";if menu=="crypt" then scroll.Size=UDim2.new(1,-48,1,-196) end -- the monster buttons, or Dig all on the Graves tab
 shopTabs.Visible=false
 for _,c in ipairs(shopTabs:GetChildren()) do c:Destroy() end
 if false then
  for i,entry in ipairs({{menu,menu=="weapons" and "pistol" or menu=="pumpkins" and "pets" or "lock","⚙"}}) do
   local key,icon,symbol=table.unpack(entry)
   local b=button(shopTabs,"",function() menu=key;scroll.CanvasPosition=Vector2.zero;render() end,UDim2.fromOffset(96,94),UDim2.fromOffset(0,(i-1)*104),menu==key and Pal.Orange or Pal.PanelDark)
   b.Name="Category_"..key
   if key=="traps" then
    local view=Instance.new("ViewportFrame");view.BackgroundTransparency=1;view.Size=UDim2.fromOffset(64,56);view.Position=UDim2.fromOffset(16,0);view.Ambient=Color3.new(1,1,1);view.LightColor=Color3.new(1,1,1);view.Parent=b
    require(S.RoadGearModel).Trap(view,CFrame.identity)
    local camera=Instance.new("Camera");camera.CFrame=CFrame.lookAt(Vector3.new(5,6,6),Vector3.new(0,.3,0));camera.Parent=view;view.CurrentCamera=camera
   elseif Icons[icon] then iconImage(b,icon,UDim2.fromOffset(52,52),UDim2.fromOffset(22,3)) else label(b,symbol,UDim2.fromOffset(96,52),nil,{textSize=35}) end
   label(b,t(key=="shop" and "shopGraves" or key=="pumpkins" and "pets" or key),UDim2.fromOffset(92,32),UDim2.fromOffset(2,57),{textSize=15})
  end
 end
	local headIcon = Icons[MENU_ICON[menu] or menu]
	headingIcon.Image = headIcon or ""
	heading.Position = UDim2.fromOffset(headIcon and 104 or 16, 0)
	heading.Text = (headIcon and "" or ((ICON[menu] or "") .. " ")) .. t(menu)
 local oldPurse=header:FindFirstChild("ShopPurse");if oldPurse then oldPurse:Destroy() end
 heading.Size=UDim2.new(1,menu=="weapons" and -360 or -178,1,0)
 if menu=="weapons" then
  local purse=badge(header,"$"..short(state.coins),Pal.Violet,UDim2.new(1,-248,0,20),170);purse.Name="ShopPurse";purse.Size=UDim2.fromOffset(170,38);purse.ZIndex=3
 end
 if menu=='quests' or menu=='rewards' then
  panel.Size=UDim2.fromOffset(850,820);fitModal(panel);scroll.Visible=false
  panel.MarketSkin.ZIndex=11;header.ZIndex=12
  header.Position=UDim2.fromOffset(16,55);header.Size=UDim2.new(1,-32,0,90)
  header.MarketCanopy.Position=UDim2.fromOffset(-24,-87);header.MarketCanopy.Size=UDim2.new(1,48,0,190);header.MarketCanopy.ZIndex=13
  heading.Position=UDim2.fromOffset(120,0);heading.Size=UDim2.new(1,-210,1,0);heading.ZIndex=15
  heading.UITextSizeConstraint.MaxTextSize=64;heading.TextScaled=true
  headingIcon.Position=UDim2.fromOffset(12,-12);headingIcon.Size=UDim2.fromOffset(100,100);headingIcon.ZIndex=15
  closeButton.ZIndex=16
  for _,o in closeButton:GetDescendants() do if o:IsA('GuiObject') then o.ZIndex=17 end end
  referenceView=require(S.QuestRewardView).Create(panel,menu,state,send,lang)
  return
 end
 if menu=="zombieCard" then
  local selected;for _,z in state.zombies do if z.id==cardId then selected=z end end
  if selected then
   local f=row(260);zombieStage(f,selected,UDim2.fromOffset(300,250));label(f,t(selected.type).." · "..t(ZC.Tiers[selected.tier]),UDim2.new(1,-310,1,0),UDim2.fromOffset(305,0),{title=true})
   button(row(60),t("holdZombie"),function() send("move",selected.id,"Field");panel.Visible=false end)
   for _,zone in {"Crypt"} do button(row(60),t("move_"..zone),function() send("move",selected.id,zone) end) end
   button(row(60),t("sell"),function() send("sell",selected.id);panel.Visible=false end)
  end
elseif menu=="info" then
 label(row(75),t('hubInfoIntro'),UDim2.fromScale(1,1),nil,{textSize=20})
 for _,lesson in require(S.Config.GuideConfig) do
  local f=row(154)
  label(f,t(lesson.Title),UDim2.new(1,-24,0,40),UDim2.fromOffset(12,6),{title=true,textSize=24})
  label(f,t(lesson.Text),UDim2.new(1,-24,0,100),UDim2.fromOffset(12,48),{textSize=18})
 end
elseif menu=="pets" then
 if not petState then petSend("PetSync");return end
 local ps=petState;local equipped=0;for _,pet in ipairs(ps.pets) do if pet.equipped and pet.species~=PetC.Starter then equipped+=1 end end
 local top=row(62,Pal.Panel)
 label(top,"🐾 "..equipped.." / "..ps.slots,UDim2.fromOffset(180,62),UDim2.fromOffset(10,0),{title=true,textSize=30})
 button(top,t("petBest"),function() petSend("PetEquipBest") end,UDim2.fromOffset(230,48),UDim2.new(1,-240,0,7),Pal.Mint)
 if #ps.pets==0 then
  local empty=row(268);empty.Name='PetEmpty'
  iconImage(empty,'modal_petEmpty',UDim2.fromOffset(250,190),UDim2.new(.5,-125,0,0))
  label(empty,(t('petEmpty'):gsub(', ', ',\n'):gsub('tutorial ', 'tutorial\n')),UDim2.fromOffset(560,72),UDim2.new(.5,-280,1,-78),{title=true,textSize=32})
 end
 local grid=tileGrid()
 for i,pet in ipairs(ps.pets) do
  local tierName=PetC.Tiers[pet.tier]
  if pet.species==PetC.Starter then
   -- the farm cat: always out on the farm, no slot, can't be let go
   tile(grid,{order=0,title=t(pet.species),color=Pal[tierName],selected=true,art=function(f) petArt(f,pet) end,badge=t(tierName),
    action={text=t("petOnFarm"),enabled=false,reason=t("petStarterStays"),callback=function() end}})
  else
  tile(grid,{order=i,title=t(pet.species),color=Pal[tierName],selected=pet.equipped,art=function(f) petArt(f,pet) end,badge=t(tierName),
   action={text=t(pet.equipped and "petUnequip" or "petEquip"),color=pet.equipped and Pal.Orange or Pal.Mint,callback=function() petSend(pet.equipped and "PetUnequip" or "PetEquip",pet.id);petStarterHint=false end},
   small={name="Release",text=releaseId==pet.id and "✓" or "✕",callback=function() if releaseId==pet.id then petSend("PetRelease",pet.id);releaseId=nil else releaseId=pet.id;render() end end}})
  end
 end
 elseif menu=="pumpkins" then
 local grid=tileGrid()
 for i,name in ipairs(Pumpkins.Order) do local pumpkin=Pumpkins[name]
  local reason=petState and #petState.pets>=PetC.Inventory and "petFull" or state.coins<pumpkin.Price and "petNoCoins" or pumpkin.NightOnly and not state.night and "petNightOnly"
  local best=1;for k,w in ipairs(pumpkin.Weights) do if w>0 then best=k end end
  tile(grid,{order=i,name="Pumpkin_"..name,title=t(name),color=({Pumpkin=Style.ModalColors.Blue,BigPumpkin=Pal.Violet,GoldenPumpkin=Style.ModalColors.Gold,LunarPumpkin=Style.ModalColors.Purple})[name],art=function(f) pumpkinArt(f,name) end,badge=pumpkin.NightOnly and "🌙" or nil,badgeWidth=44,
   -- a pumpkin is a case (2026-11-16): its card and its price button open the case window (More.showPetCase), which buys
   tap=function() More.showPetCase(name) end,
   action={name="Hatch_"..name,text="$"..short(pumpkin.Price),color=reason and Pal.Common or nil,callback=function() More.showPetCase(name) end}})
 end
 elseif menu=="weaponSkins" then
 button(row(48),t("backWeapons"),function() menu="weapons";render() end)
 label(row(60),t("skinOwnedHint"),UDim2.fromScale(1,1),nil,{textSize=18})
 local grid=tileGrid();local owned=weaponState and weaponState.owned.AK
 for i,finish in ipairs(require(S.WeaponSkins).Order) do
  local selected=(weaponState and weaponState.skins and weaponState.skins.AK or "Default")==finish
  tile(grid,{order=i,name="Skin_"..finish,title=t(finish=="Default" and "skinDefault" or finish),selected=selected,
   art=function(f) Style.Icon(f,"weapon","AK",nil,nil,finish) end,
   action={text=t(selected and "skinSelected" or "skinSelect"),color=selected and Pal.Accent or Pal.Mint,enabled=owned,reason=t("skinOwnedHint"),callback=function() if not selected then rem.WeaponAction:FireServer("skin","AK:"..finish) end end}})
 end
 elseif menu=="weapons" then

 local grid=tileGrid()
 -- Guns are earned, not bought (owner, 2026-11-13): each one comes with enough kills in its ruins location.
 local districts=require(S.Config.WorldConfig).Districts
 for i,id in ipairs(WeaponC.Order) do local cfg=WeaponC[id];local owned=weaponState and weaponState.owned[id];local equipped=weaponState and weaponState.equipped==id
  local unlock=WeaponC.Unlock[id];local place=unlock and districts[unlock.Location]
  local have=unlock and weaponState and weaponState.kills and weaponState.kills[unlock.Location] or 0
  -- the tutorial's last step hands the Double over for free (WeaponService.TutorialGun, 2026-11-15)
  local tutorialGun=not owned and state and not state.tutorialDone and state.step==4 and id==WeaponC.TutorialGun
  if tutorialGun then have=unlock and unlock.Kills or have end
  tile(grid,{order=i,name="Weapon_"..id,title=t(id),color=Style.ModalColors.Blue,selected=equipped,art=function(f) Style.ModalArt(f,'weapon',id,nil,nil,weaponState and weaponState.skins and weaponState.skins[id]) end,badge="⚔ "..cfg.Damage*(cfg.Pellets or 1),badgeWidth=70,
   corner=not owned and place and place.Emoji or nil,
   action=owned and {text=equipped and t("inHand") or t("choose"),color=equipped and Pal.Accent or Pal.Mint,callback=function() if not equipped then rem.WeaponAction:FireServer("equip",id) end end}
    or unlock and have>=unlock.Kills and {text=t("weaponTake"),color=Pal.Orange,callback=function() rem.WeaponAction:FireServer("buy",id) end}
    or {text="💀 "..math.min(have,unlock and unlock.Kills or 0).."/"..(unlock and unlock.Kills or 0),enabled=false,reason=place and t("weaponNeedKills",{n=unlock.Kills,place=t(place.Title)}) or "",callback=function() end}})
 end
 local footer=Style.ModalRow(row(48));footer.LayoutOrder=1000
 local upgrade=button(footer,t("weaponUpgrade"),function()
  local combat=p.PlayerGui:FindFirstChild("CombatUI");local bridge=combat and combat:FindFirstChild("OpenUpgrades")
  if bridge then panel.Visible=false;bridge:Fire() end
 end,UDim2.new(.72,-6,0,40),UDim2.fromOffset(3,4),Pal.Violet)
 Style.ModalButton(upgrade,Style.ModalColors.Purple);upgrade.Name="OpenUpgrades"
 button(footer,t("weaponSkins"),function() menu="weaponSkins";scroll.CanvasPosition=Vector2.zero;render() end,UDim2.new(.28,-6,0,40),UDim2.new(.72,3,0,4),Pal.Sky2)
 elseif menu == "traps" then
 local grid=tileGrid();local have=p:GetAttribute("RoadTraps") or 0
 tile(grid,{order=0,name="TrapTile",title=t("trap"),color=Style.ModalColors.Blue,art=function(f) Style.ModalArt(f,'trap') end,corner="×"..have,
  action={name="BuyRoadTrap",text="$"..short(RoadC.Trap.Price),enabled=state.coins>=RoadC.Trap.Price and have<RoadC.Trap.MaxStock,reason=have>=RoadC.Trap.MaxStock and t("trapFull") or t("petNoCoins"),callback=function() rem:WaitForChild("RoadAction"):FireServer("buyTrap") end}})
 local shovels=require(S.Config.ShovelConfig)
 for i,id in ipairs(shovels.Order) do
  local cfg=shovels[id];local owned=state.shovels and state.shovels[id];local selected=state.equippedShovel==id
  local action
  if selected then action={name='Shovel_'..id,text=t('inHand'),color=Pal.Accent,callback=function() end}
  elseif owned then action={name='Shovel_'..id,text=t('choose'),callback=function() rem.EquipmentAction:FireServer('shovel',id) end}
  elseif cfg.Price then action={name='Shovel_'..id,text="$"..short(cfg.Price),enabled=state.coins>=cfg.Price,reason=t("petNoCoins"),callback=function() rem.EquipmentAction:FireServer('buyShovel',id) end}
  else action={name='Shovel_'..id,text="📖",enabled=false,reason=t('dexReward'),callback=function() end} end
  tile(grid,{order=i,name="ShovelTile_"..id,title=t('shovel_'..id),color=Style.ModalColors.Blue,selected=selected,art=function(f) Style.ModalArt(f,'shovel',id) end,badge=t('shovelStats',{d=cfg.Damage,s=L.number(cfg.Knockout,lang,1),m=cfg.Distance}),badgeWidth=154,action=action})
 end
	elseif menu == "crypt" then
  if not cryptFooter:FindFirstChild("PlaceBest") then
   local a=button(cryptFooter,"",function() send("placeBest") end,UDim2.new(.5,-6,1,0),UDim2.fromOffset(0,0),Pal.Mint);a.Name="PlaceBest"
   local b=button(cryptFooter,"",function() send("storeAll") end,UDim2.new(.5,-6,1,0),UDim2.new(.5,6,0,0),Pal.Orange);b.Name="StoreAll"
   -- the Graves tab's one button (owner, 2026-11-15): dig every ripe grave at once
   local c=button(cryptFooter,"",function() send("digAll") end,UDim2.new(1,0,1,0),UDim2.fromOffset(0,0),Pal.Mint);c.Name="DigAll"
   -- Sell (owner, 2026-11-16): the monsters marked by a tap on their cards, with what they fetch; the first press
   -- asks "Sell for sure?", a second one within 3 s sells (Main.server: sellMany)
   local s=button(cryptFooter,"",function()
    local ids={};for _,z in ipairs(state.zombies) do if More.sellSel[z.id] and #ids<More.SELL_MAX then table.insert(ids,z.id) end end
    if #ids==0 then return end
    if os.clock()<More.sellArmedUntil then
     More.sellArmedUntil=0;table.clear(More.sellSel);send("sellMany",table.concat(ids,","));More.sellFooter()
    else
     More.sellArmedUntil=os.clock()+3;More.sellFooter()
     task.delay(3.05,function() if os.clock()>=More.sellArmedUntil then More.sellFooter() end end)
    end
   end,UDim2.new(1/3,-6,1,0),UDim2.new(2/3,6,0,0),Pal.Red);s.Name="SellSelected"
   for _,o in cryptFooter:GetDescendants() do if o:IsA("GuiObject") then o.ZIndex=math.max(o.ZIndex,scroll.ZIndex+1) end end
  end
  cryptFooter.PlaceBest.Text=t("cryptPlaceBest");cryptFooter.StoreAll.Text=t("cryptStoreAll");cryptFooter.DigAll.Text=t("digAll")
  cryptFooter.PlaceBest.Visible=filter~="Graves";cryptFooter.StoreAll.Visible=filter~="Graves";cryptFooter.DigAll.Visible=filter=="Graves"
  -- a monster sold, merged or gone some other way is no longer marked
  do local have={};for _,z in ipairs(state.zombies) do have[z.id]=true end;for id in pairs(More.sellSel) do if not have[id] then More.sellSel[id]=nil end end end
  More.sellFooter()
  local chips = Style.ModalRow(row(48, Pal.Panel))
  local chipIcons = {all="dex", Field="house", Crypt="crypt", Graves="modal_grave_Stone"}
  local tabs = {"all", "Field", "Crypt", "Graves"}
  for i, key in ipairs(tabs) do
   local chip = button(chips, "", function()
    filter = key;scroll.CanvasPosition = Vector2.zero;render()
   end, UDim2.new(1/#tabs, -8, 0, 40), UDim2.new((i-1)/#tabs, 4, 0, 4), filter == key and Pal.Accent or Pal.Sky2)
   chip.Name = "CryptTab_" .. key
   iconImage(chip, chipIcons[key], UDim2.fromOffset(36,36), UDim2.fromOffset(8,4))
   label(chip, t(key), UDim2.new(1,-54,1,0), UDim2.fromOffset(48,0), {title=true,textSize=24})
  end
  -- The Graves tab (owner, 2026-11-15): the graves growing on the farm, the time each has left, and a Dig button that
  -- digs a ripe one from wherever you are, the monster at once. The timers tick with the state (every second).
  if filter == "Graves" then
   local graves = table.clone(state.graves or {})
   table.sort(graves, function(a, b) if a.remaining ~= b.remaining then return a.remaining < b.remaining end;return a.slot < b.slot end)
   scroll:SetAttribute("GraveSig", More.graveSig(state))
   -- the graves not planted yet come first (owner, 2026-11-16: the crypt icon flashes while there is one to plant, and
   -- this is where it leads): those brought home and the vouchers, each with the inventory's own Select button
   local loose = {}
   for _, g in ipairs(state.graveInventory or {}) do if not g.pendingTransfer then table.insert(loose, {grave = g}) end end
   for _, name in ipairs(GC.Order) do local n = state.vouchers and state.vouchers[name] or 0;if n > 0 then table.insert(loose, {voucher = name, n = n}) end end
   if #graves == 0 and #loose == 0 then label(row(80), t("placeCemetery"), UDim2.new(1,-28,1,0), UDim2.fromOffset(14,0), {title=true,textSize=22}) end
   for _, item in ipairs(loose) do -- rows like the inventory's own, with its button
    local g, name = item.grave, item.voucher
    local f = row(80);f.Name = g and "LooseGrave_" .. tostring(g.id) or "VoucherGrave_" .. name
    Style.ModalArt(f, g and "coffin" or "grave", g and g.type or name, UDim2.fromOffset(64, 64), UDim2.fromOffset(10, 8))
    label(f, More.graveTitle(g or {type = name}) .. (name and "  × " .. item.n or ""), UDim2.new(.55, -84, 1, 0), UDim2.fromOffset(84, 0), {title = true, align = LEFT})
    button(f, t("selectGrave"), function()
     if g then send("selectGrave", g.id) else send("plantVoucher", name) end
     panel.Visible = false
    end, UDim2.fromScale(.43, .8), UDim2.fromScale(.56, .1)).Name = "SelectGrave"
   end
   local grid = tileGrid()
   for i, g in ipairs(graves) do
    local ready = g.remaining == 0
    -- (the family on a strip of its own: "Marble · Longmaw" does not fit a card's title)
    tile(grid, {order = i, name = "GraveTile_" .. g.slot, title = t("grave_" .. g.type), color = Style.ModalColors.Blue,
     chip = g.family and {text = t("roadName_" .. g.family), color = Color3.fromRGB(112, 92, 156)} or nil,
     art = function(f) Style.ModalArt(f, "grave", g.type) end,
     badge = ready and t("ready") or "⏳ " .. clockText(g.remaining), badgeColor = ready and Style.ModalColors.Green or nil, badgeWidth = 120,
     action = {name = "DigGrave", text = t("dig"), enabled = ready, callback = function() send("digGrave", tostring(g.slot)) end}})
   end
   return
  end
  local shown = 0
  for _, z in ipairs(state.zombies) do if filter == "all" or filter == z.zone then shown += 1 end end
  if shown == 0 then label(row(80), t("empty"), UDim2.fromScale(1,1), nil, {title=true,textSize=22}) end
		local grid = tileGrid()
		for i, z in ipairs(Merge.SortByIncome(state.zombies)) do
			if filter == "all" or filter == z.zone then
				local tierName = ZC.Tiers[z.tier]
				local stars = Merge.Stars(z)
				local card
				card = tile(grid, {
					order = i,
					name = "Zombie_" .. z.id,
					title = t(z.type),
					color = Pal[tierName],
     rarity = tierName,
     -- a tap on the card marks the monster for the Sell button (2026-11-16)
     tap = function(f)
      if not More.sellSel[z.id] then
       local n = 0;for _ in pairs(More.sellSel) do n += 1 end
       if n >= More.SELL_MAX then Sfx.play("Error", 0.4);return end
      end
      More.sellSel[z.id] = not More.sellSel[z.id] or nil;More.sellArmedUntil = 0
      More.sellMark(f, More.sellSel[z.id], tierName);More.sellFooter()
     end,
					art = function(f)
						zombieStage(f, z, UDim2.fromScale(1, 1))
						if stars > 0 then
							starRow(f, stars, 16, UDim2.new(0, 1, 1, -17))
						end
					end,
					badge = "$" .. rateText(z)..t("perSecond"),
     badgeColor=Style.ModalColors.Green, badgeRight=true,
					badgeWidth = 75,
					corner = z.mutation ~= "None" and (z.mutation == "Golden" and "✨" or z.mutation == "Lunar" and "🌙" or "🌈") or nil,
					action = { name = "Take", text = t("holdZombie"), callback = function()
						send("move", z.id, "Field")
						panel.Visible = false -- in hand now: go and put it down
					end },
					small = { name = "Card", text = "...", color = Pal.Sky2, callback = function()
						cardId = z.id
						menu = "zombieCard"
						render()
					end },
				})
				if More.sellSel[z.id] then More.sellMark(card, true, tierName) end
			end
		end
	elseif menu == "dex" then
  renderDex()
 elseif menu=='freeGift' then
  if InterfaceC.GroupId>0 then
   local f=row(100);Style.ModalArt(f,'shoe',nil,UDim2.fromOffset(100,90));label(f,t('giftReward'),UDim2.new(1,-120,1,0),UDim2.fromOffset(110,0),{title=true,textSize=28})
   button(row(60),t('giftLike'),function() flash(t('giftHint'), false, nil, "guide") end)
   button(row(60),t('giftFavorite'),function() pcall(function() game:GetService('AvatarEditorService'):PromptSetFavorite(game.PlaceId,Enum.AvatarItemType.Asset,true) end) end)
   button(row(60),t('giftJoin'),function() task.spawn(function() pcall(function() game:GetService('GroupService'):PromptJoinAsync(InterfaceC.GroupId) end) end) end)
   label(row(65),t('giftHint'),UDim2.fromScale(1,1),nil,{textSize=17})
   button(row(60),t(state.freeGiftClaimed and 'dexClaimed' or 'claim'),function() rem.InterfaceAction:FireServer('gift') end)
  end
	elseif menu == "house" then
		renderHouse()
	elseif menu == "merge" then
		renderMerge()
	elseif menu == "inventory" then
		renderInventory()
	elseif menu == "settings" then
		renderSettings()
	elseif menu == "quests" then
		renderQuests()
	elseif menu == "top" then
		renderTop()
	elseif menu == "rewards" then
		-- Offline income is no longer claimed here: it piles up on the farm heap (IncomeService.Offline).
		local grid = tileGrid(162, 208)
		local today = state.dailyNext or state.dailyStreak
		for i, prize in ipairs(RC.Daily) do
   if i==5 then grid=tileGrid(162,208) end
			local claimable = i == today and state.dailyReady == true
			tile(grid, {
				order = i,
				name = "Day" .. i,
				title = t("daily", { n = i }),
				color = Style.ModalColors.Blue,
    selected = i==7 or i==today,
				art = function(f)
					if prize.Coins then
						Style.ModalArt(f, "cash")
					else
						Style.ModalArt(f, "grave", prize.Grave)
					end
				end,
				badge = prize.Coins and ("$" .. short(prize.Coins)) or ("×" .. prize.Count),
				badgeWidth = 80,
				action = claimable and { text = t("claim"), callback = function() send("daily") end }
					or { text = (i < today or i == today and state.dailyReady ~= true) and "✓" or t("daily", { n = i }), enabled = false, reason = t("dailyLater"), callback = function() end },
			})
		end
	end
end

-- One fixed text size down the column; scaled text would make short labels look shouty.
local navButtons = {}
local function openMenu(key, fromIcon)
 -- the crypt opens on its monsters; from its icon while that flashes for a grave to plant, on the graves (2026-11-16).
 -- Nothing stays marked for sale from the last visit.
 if key == "crypt" then filter = fromIcon and More.blink.crypt and "Graves" or "Crypt";scroll.CanvasPosition = Vector2.zero;table.clear(More.sellSel);More.sellArmedUntil = 0 end
	menu = key
	panel.Visible = true
	render()
	bounce(panelScale, fitModal(panel))
end
local function menuIcon(parent, key, size, order)
	local b = iconButton(parent, MENU_ICON[key] or key, function()
		openMenu(key, true)
	end, size)
	b.Name = "Nav_" .. key
	b.LayoutOrder = order
	navButtons[key] = b
	return b
end
local BIG, SMALL = UDim2.fromOffset(84,84), UDim2.fromOffset(TOP_HEIGHT,TOP_HEIGHT)
-- The Monsterdex button is its book icon only, like the buttons on the right (owner, 2026-11-12: no caption).
local dex=menuIcon(nav,'dex',BIG,2)
navButtons.invite=iconButton(topRight,'invite',invite,SMALL);navButtons.invite.LayoutOrder=1
menuIcon(topRight,'settings',SMALL,2);menuIcon(topRight,'top',SMALL,4)
-- The language switch sits in the row with the settings (owner, 2026-11-13): a tap flips Russian and English.
navButtons.language=button(topRight,'',function()
 local now=state and state.language or (isRussian and 'ru' or 'en')
 if now=='auto' then now=isRussian and 'ru' or 'en' end
 send('language',now=='ru' and 'en' or 'ru')
end,SMALL);navButtons.language.Name='Nav_language';navButtons.language.LayoutOrder=3
navButtons.language.UITextSizeConstraint.MaxTextSize=24
navButtons.language.Text=isRussian and 'RU' or 'EN'
-- Gifts and home lead the top-right row (owner, 2026-11-14; they followed Roblox's buttons before); quests lead the left column.
menuIcon(topRight,'rewards',SMALL,-2);menuIcon(nav,'quests',BIG,1)
menuIcon(rightBox,'pets',BIG,1);menuIcon(rightBox,'crypt',BIG,2)
navButtons.home=iconButton(topRight,'house',function() rem.InterfaceAction:FireServer('home') end,SMALL);navButtons.home.Name='Nav_home';navButtons.home.LayoutOrder=-1
-- out in the ruins the way home is the gate or a portal: the button only gets in the way there (owner, 2026-11-14)
local function homeShown() navButtons.home.Visible=p:GetAttribute('OnRoad')~=true end
p:GetAttributeChangedSignal('OnRoad'):Connect(homeShown);homeShown()
-- Reference look: saturated fills, a darker thick outline, a soft top-to-bottom shine
local function paint(b,fill,edge)
 b.BackgroundColor3=fill;local st=b:FindFirstChildOfClass('UIStroke');if st then st.Color=edge;st.Thickness=4 end
 local g=b:FindFirstChildOfClass('UIGradient');if g then g.Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(205,205,205)) end
 b:SetAttribute('Fill',fill)
end
paint(dex,Color3.fromRGB(47,205,255),Color3.fromRGB(20,90,170))
paint(navButtons.pets,Color3.fromRGB(255,150,40),Color3.fromRGB(150,70,10))
paint(navButtons.crypt,Color3.fromRGB(160,95,255),Color3.fromRGB(70,30,140))
paint(navButtons.home,Color3.fromRGB(90,220,90),Color3.fromRGB(25,110,40))
paint(navButtons.rewards,Color3.fromRGB(255,110,160),Color3.fromRGB(150,30,80))
-- Gifts and home are round like the rest of the top-right row, in their own colours (owner, 2026-11-14)
for _,b in {navButtons.home,navButtons.rewards} do
 local c=b:FindFirstChildOfClass('UICorner') or Instance.new('UICorner',b);c.CornerRadius=UDim.new(1,0)
 local st=b:FindFirstChildOfClass('UIStroke');if st then st.Thickness=2.5 end
end
paint(navButtons.quests,Color3.fromRGB(255,200,60),Color3.fromRGB(150,95,10))
-- Auto-fire on/off (owner, 2026-11-14): the third button on the right, under the pets and the crypt; green while it
-- fires on its own, grey when you shoot by tapping. The same setting as in Settings.
do
 local auto=iconButton(rightBox,'auto_on',function() rem.InterfaceAction:FireServer('setting','AutoFire',p:GetAttribute('AutoFire')==false) end,BIG)
 auto.Name='Nav_autofire';auto.LayoutOrder=3;navButtons.autofire=auto
 local function show()
  local on=p:GetAttribute('AutoFire')~=false;local icon=auto:FindFirstChild('Icon')
  if icon then icon.Image=Icons[on and 'auto_on' or 'auto_off'] or '' end
  if on then paint(auto,Color3.fromRGB(110,220,90),Color3.fromRGB(30,110,30)) else paint(auto,Color3.fromRGB(150,148,166),Color3.fromRGB(70,68,90)) end
 end
 p:GetAttributeChangedSignal('AutoFire'):Connect(show);show()
end
for _,key in {'invite','settings','language','top'} do local b=navButtons[key];if b then b.BackgroundColor3=Color3.fromRGB(28,30,44);b.BackgroundTransparency=.25;local st=b:FindFirstChildOfClass('UIStroke');if st then st.Color=Color3.fromRGB(70,74,96);st.Thickness=2 end;local g=b:FindFirstChildOfClass('UIGradient');if g then g.Enabled=false end;local c=b:FindFirstChildOfClass('UICorner');if c then c.CornerRadius=UDim.new(1,0) end end end
RunService.Heartbeat:Connect(function() navButtons.home.BackgroundColor3=p:GetAttribute('HomeReason') and Pal.Common or navButtons.home:GetAttribute('Fill') end)
local menuBridge=Instance.new('BindableEvent');menuBridge.Name='ZoneMenu';menuBridge.Parent=gui
menuBridge.Event:Connect(function(key,opening)
 -- the farm's workbench (PlotService) opens the weapon upgrade bench, which lives in CombatController
 if key=='upgrades' then
  local combat=p.PlayerGui:FindFirstChild('CombatUI');local open=combat and combat:FindFirstChild('OpenUpgrades');local bench=combat and combat:FindFirstChild('UpgradeBench')
  if opening then panel.Visible=false;if open and not (bench and bench.Visible) then open:Fire() end;gui:SetAttribute('ZoneMenuKey',key)
  elseif gui:GetAttribute('ZoneMenuKey')==key then if bench then bench.Visible=false end;gui:SetAttribute('ZoneMenuKey',nil) end
  return
 end
 if opening then openMenu(key);gui:SetAttribute('ZoneMenuKey',key)
 elseif gui:GetAttribute('ZoneMenuKey')==key then panel.Visible=false;gui:SetAttribute('ZoneMenuKey',nil) end
end)

-- Icons have no captions, so the tutorial makes the one it means flash. Since 2026-11-16 an icon also flashes while
-- it has something to take (More.blink: the Monsterdex with a reward to claim, the crypt with a grave to plant) - only
-- once the tutorial is over, and never beside the tutorial's own hint. An icon that stops flashing gets back the
-- outline it was painted with (it was left in the plain one before).
local pulseTarget, pulsing
RunService.Heartbeat:Connect(function()
	local any = pulseTarget ~= nil or next(More.blink) ~= nil
	if not any and not pulsing then
		return
	end
	pulsing = any
	local on = os.clock() % 0.8 < 0.4
	for key, b in pairs(navButtons) do
		local st = b:FindFirstChildOfClass("UIStroke")
		if st then
			local base = More.navStroke[b]
			if not base then
				base = { st.Color, st.Thickness }
				More.navStroke[b] = base
			end
			local lit = (key == pulseTarget or (not pulseTarget and More.blink[key])) and on
			st.Color = lit and Pal.Accent or base[1]
			st.Thickness = lit and 7 or base[2]
		end
	end
end)

-- A little counter on the quests button, because a finished quest is easy to miss from across the farm.
local questDot = candy(Instance.new("TextLabel"), Pal.Red, 13)
questDot.Name = "QuestDot"
questDot.AnchorPoint = Vector2.new(0.5, 0.5)
questDot.Size = UDim2.fromOffset(28, 28)
questDot.Position = UDim2.new(1, -4, 0, 4)
questDot.Font = FONT_TITLE
questDot.TextSize = 18
questDot.TextColor3 = Pal.Text
questDot.AutoLocalize = false
questDot.Visible = false
questDot.UIStroke.Thickness = 2.5
questDot.Parent = navButtons.quests
local mergeDot = questDot:Clone()
mergeDot.Name = "MergeDot"
mergeDot.Parent = navButtons.crypt
local dailyDot = questDot:Clone()
dailyDot.Name = "DailyDot";dailyDot.Text = "!"
dailyDot.Parent = navButtons.rewards
-- how many monsters wait with a Monsterdex reward (owner, 2026-11-16: "a notice on the Monsterdex icon, and flashing")
More.dexDot = questDot:Clone()
More.dexDot.Name = "DexDot"
More.dexDot.Parent = navButtons.dex

-- Health stays visible everywhere; the grave indicator follows the carrying state.
local function refreshRoadHud()
 local carrying=p:GetAttribute("CarryingGrave")==true
 roadStatus.Visible=true
 heartIcon.Visible=true;healthText.Visible=true
 healthText.Text=tostring(math.max(0,p:GetAttribute("RoadHearts") or RoadC.Hearts))
 carryIcon.Visible=carrying
 carryIcon.Position=UDim2.fromOffset(138,0)
end
for _,attribute in ipairs({"RoadHearts","CarryingGrave"}) do
 p:GetAttributeChangedSignal(attribute):Connect(refreshRoadHud)
end
refreshRoadHud()
-- In a hiding bush: a green tag beside the hearts, and your own body goes see-through (only on your screen).
local hiddenTag=Style.ModalSurface(Instance.new('TextLabel'),Color3.fromRGB(70,150,60),12,false);hiddenTag.Name='HiddenInBush'
hiddenTag.Size=UDim2.fromOffset(196,34);hiddenTag.Position=UDim2.fromOffset(70,-38);hiddenTag.Font=FONT_TITLE;hiddenTag.TextScaled=true;hiddenTag.TextColor3=Pal.Text;hiddenTag.AutoLocalize=false;hiddenTag.Visible=false;hiddenTag.Parent=roadStatus
Style.ModalText(hiddenTag,true)
local function refreshHidden()
 local hidden=p:GetAttribute("HiddenInBush")==true
 hiddenTag.Text=t('bushHidden');hiddenTag.Visible=hidden
 for _,q in p.Character and p.Character:GetDescendants() or {} do if q:IsA('BasePart') or q:IsA('Decal') then q.LocalTransparencyModifier=hidden and .45 or 0 end end
end
p:GetAttributeChangedSignal("HiddenInBush"):Connect(refreshHidden)
responsive()

-- Settings can change the language mid-game: everything built from t() on the next render picks it up.
p:GetAttributeChangedSignal("Language"):Connect(function()

	local oldTitle, oldBody = FONT_TITLE, FONT_BODY
	lang = L.lang()
 coins.Text=COIN_PREFIX..short(coinDisplay.Value)
	isRussian = string.sub(lang, 1, 2) == "ru"
	navButtons.language.Text = isRussian and "RU" or "EN"
	FONT_TITLE = isRussian and Enum.Font.GothamBlack or Enum.Font.FredokaOne
	FONT_BODY = isRussian and Enum.Font.BuilderSansExtraBold or Enum.Font.FredokaOne
	for _, root in ipairs({ gui, topGui }) do
		for _, x in ipairs(root:GetDescendants()) do
			if x:IsA("TextLabel") or x:IsA("TextButton") then
				if x.Font == oldTitle then
					x.Font = FONT_TITLE
				elseif x.Font == oldBody then
					x.Font = FONT_BODY
				end
			end
		end
	end
	if panel.Visible then
		render()
	end
end)

task.spawn(function()
	rem:WaitForChild("Board").OnClientEvent:Connect(function(board)
		boardState = board
		if panel.Visible and menu == "top" then
			render()
		end
	end)
end)

rem.State.OnClientEvent:Connect(function(s)
	local first = not state
	-- A jump bigger than a second or two of income means a sale, a reward or a purchase rather than the farm ticking.
	-- The tick pays the newcomer's boost on top (IncomeService.Tick) while s.income is without it: counted in here, or
	-- every tick under the x3 boost sounded like a sale (2026-11-15).
	if not first then
		local change = s.coins - state.coins
		if change > math.max(s.income * (p:GetAttribute("NewbieBoost") or 1) * 2.5, 1) then
			Sfx.play("Coins", 0.5)
		elseif change < 0 then
			Sfx.play("Buy", 0.3)
		end
	end
	state = s
 local purse=header:FindFirstChild("ShopPurse");if purse then purse.Text="$"..short(s.coins) end
	local rt = scroll:FindFirstChild("RefreshTimer", true)
	if rt then
		rt.Text = t("refresh", { n = math.ceil(s.refresh) })
	end
	if first then
		coinDisplay.Value = s.coins
		coins.Text = COIN_PREFIX .. short(s.coins)
	else
		if coinTween then
			coinTween:Cancel()
		end
		coinTween = TweenService:Create(coinDisplay, TweenInfo.new(0.6, Enum.EasingStyle.Quad), { Value = s.coins })
		coinTween:Play()
	end
	income.Text = t("incomeShort", { n = s.income >= 10000 and short(s.income) or L.number(s.income, lang, s.income >= 100 and 0 or 1) })
	clock.Text = (Icons.sun and "" or (s.night and "🌙 " or "☀️ ")) .. string.format("%02d:%02d", math.floor(s.left / 60), math.floor(s.left % 60))
	clockIcon.Image = Icons[s.night and "moon" or "sun"] or ""
	clockBox.BackgroundColor3 = s.night and Pal.Violet or Pal.Sky2
	dayIcon.Image = Icons[s.night and "sun" or "moon"] or ""
	dayText.Text = string.format("%d:%02d", math.floor(s.left / 60), math.floor(s.left % 60)) -- the sun or moon icon says which; no "night in" words (owner, 2026-11-14)
 tutorialText=t(({"tutorialDig","tutorialField","tutorialRoad","tutorialPlant","tutorialGunsmith","tutorialWeaponUpgrade","tutorialTreadmill","tutorialGate","tutorialHouse"})[(s.step or 0)+1] or "tutorialDone")
 tutorialWanted=not s.tutorialDone;refreshModal()
 gui:SetAttribute("TutorialStep",s.tutorialDone and 9 or s.step)
 pulseTarget=not s.tutorialDone and s.step==1 and "crypt" or nil
	gui:SetAttribute("Night", s.night)
 if panel.Visible and menu=="pumpkins" then render() end
 -- the crypt's Graves tab: the timers tick in place; a grave planted, dug or ripe rebuilds the tab
 if panel.Visible and menu=="crypt" and filter=="Graves" then
  if More.graveSig(s)~=scroll:GetAttribute("GraveSig") then render()
  else for _,g in ipairs(s.graves or {}) do local f=scroll:FindFirstChild("GraveTile_"..g.slot,true);local b=f and f:FindFirstChild("Badge");if b and g.remaining>0 then b.Text="⏳ "..clockText(g.remaining) end end end
 end
	if treadmillText and treadmillText.Parent then
		treadmillText.Text = treadmillLine()
	end
	if houseTimer and houseTimer.Parent then
		houseTimer.Text = t("houseBuilding", { time = clockText(s.houseLeft or 0) })
	end
	local readyToMerge = Merge.Ready(s.zombies)
	mergeDot.Text = tostring(readyToMerge)
	mergeDot.Visible = readyToMerge > 0
	dailyDot.Visible = s.dailyReady == true
	-- the icons that flash while they have something to take (2026-11-16), once the tutorial is over
	local ready = More.dexReady(s)
	More.dexDot.Text = tostring(ready)
	More.dexDot.Visible = ready > 0
	More.blink.dex = s.tutorialDone and ready > 0 or nil
	More.blink.crypt = s.tutorialDone and More.plantable(s) or nil
	local questSig = ""
	if s.quests then
		local claimable = QuestRules.Claimable(s.quests)
		questDot.Text = tostring(claimable)
		questDot.Visible = claimable > 0
		questSig = s.quests.day .. tostring(s.quests.bonusClaimed)
		for _, item in ipairs(s.quests.items) do
			questSig ..= item.id .. (item.claimed and "c" or item.progress >= item.goal and "d" or "")
			-- Progress moves every second for some quests: update the bar in place so the list never jumps.
			local bar = questBars[item.id]
			if bar and bar.fill.Parent then
				bar.fill.Size = UDim2.fromScale(math.clamp(item.progress / item.goal, 0, 1), 1)
				bar.count.Text = progressText(item)
			end
		end
		if questTimer and questTimer.Parent then
			questTimer.Text = resetText()
		end
	end
 if referenceView and referenceView.Root.Parent then referenceView:Update(s) end
	local sig = game.HttpService:JSONEncode({ s.zombies, s.upgrades, s.dailyStreak, s.dailyReady, s.offline, s.stock, questSig, s.language, s.vouchers, s.house, (s.houseLeft or 0) > 0, s.treadmill,s.equippedShovel,s.shovels,s.showRanges,s.settings,s.dex,s.dexClaims,s.freeGiftClaimed })
	if sig ~= signature and panel.Visible then
		signature = sig
		render()
	end

end)

-- Illustrated reveal: shared portrait, explicit close, no per-frame model animation.
local function revealCard(z)
 local tierName=ZC.Tiers[z.tier]
 local old=gui:FindFirstChild('Reveal')
 local previousMenu=old and old:GetAttribute('RestoreMenu') or (panel.Visible and menu or nil)
 if old then old:SetAttribute('Replaced',true);old:Destroy() end
 panel.Visible=false
 local card=scaledBy(Style.ModalWindow(Instance.new('Frame')))
 card.Name='Reveal';card.AnchorPoint=Vector2.new(.5,.5);card.Size=UDim2.fromOffset(760,440);card.ZIndex=10;card.Parent=gui
 card:SetAttribute('RestoreMenu',previousMenu)
 card.Destroying:Connect(function()
  if not card:GetAttribute('Replaced') and previousMenu and not gui:FindFirstChild('PetHatch') then menu=previousMenu;panel.Visible=true;render() end
 end)
 local titleLabel=modalTitle(card,t(z.merged and 'mergeDone' or 'reveal'))
 titleLabel.UITextSizeConstraint.MaxTextSize=52
 local portrait=Instance.new('Frame');portrait.Name='Portrait';portrait.BackgroundTransparency=1;portrait.Parent=card
 local glowColor=tierName=='Common' and Color3.fromRGB(255,225,125) or Pal[tierName]
 for i=1,12 do
  local glow=Instance.new('Frame');glow.Name='Glow';glow.AnchorPoint=Vector2.new(.5,.5);glow.Position=UDim2.fromScale(.5,.5)
  local k=1-i*.045;glow.Size=UDim2.fromScale(k,k);glow.BackgroundColor3=glowColor;glow.BackgroundTransparency=.965-i*.002;glow.BorderSizePixel=0;glow.Parent=portrait
  Instance.new('UICorner',glow).CornerRadius=UDim.new(1,0)
 end
 local stage=zombieStage(portrait,z,UDim2.fromScale(.86,.94),UDim2.fromScale(.07,.01))
 stage.Name='MonsterPortrait';stage.ZIndex=2
 for i,point in {{.13,.19},{.86,.42},{.12,.77},{.77,.08}} do
  local spark=iconImage(portrait,'star',UDim2.fromOffset(i%2==0 and 14 or 20,i%2==0 and 14 or 20),UDim2.fromScale(point[1],point[2]));spark.Name='Sparkle';spark.ImageTransparency=.22;spark.ZIndex=3
 end
 local portraitScale=Instance.new('UIScale',stage);portraitScale.Scale=.92
 stage.ImageTransparency=1
 TweenService:Create(stage,TweenInfo.new(.28),{ImageTransparency=0}):Play()
 TweenService:Create(portraitScale,TweenInfo.new(.35,Enum.EasingStyle.Back),{Scale=1}):Play()
 local stars=starRow(card,Merge.Stars(z),28,UDim2.new(),Vector2.new(.5,0))
 local details=Instance.new('Frame');details.Name='Details';details.BackgroundTransparency=1;details.Parent=card
 local nameLabel=label(details,t(z.type),UDim2.new(1,0,0,60),UDim2.new(),{title=true,textSize=36});nameLabel.Name='MonsterName';nameLabel.TextWrapped=false;nameLabel.UITextSizeConstraint.MaxTextSize=64
 local rarityBadge=badge(details,t(tierName),Pal[tierName],UDim2.new(.5,-95,0,72),190);rarityBadge.Name='Rarity';rarityBadge.Size=UDim2.fromOffset(190,34)
 rarityBadge.BackgroundColor3=Pal[tierName]:Lerp(Style.ModalColors.Cream,.65);Style.ModalText(rarityBadge,false)
 if z.mutation and z.mutation~='None' then
  local mutation=badge(details,t(z.mutation),mutationColor(z.mutation),UDim2.new(.5,-90,0,116),180);mutation.Name='Mutation';mutation.Size=UDim2.fromOffset(180,28)
 end
 local income=Style.ModalSurface(Instance.new('Frame'),Style.ModalColors.Cream,16,false);income.Name='Income';income.Size=UDim2.new(1,-12,0,76);income.Position=UDim2.fromOffset(6,158);income.Parent=details
 Style.ModalArt(income,'cash',nil,UDim2.fromOffset(64,58),UDim2.fromOffset(10,9))
 label(income,t('revealIncome'),UDim2.new(.45,-70,1,0),UDim2.fromOffset(78,0),{title=true,textSize=36})
 local value=label(income,'$'..rateText(z)..t('perSecond'),UDim2.new(.55,-12,1,0),UDim2.new(.45,4,0,0),{title=true,textSize=42});value.UITextSizeConstraint.MaxTextSize=64;value.Name='Value';value.TextColor3=Color3.fromRGB(28,135,17)
 local confirm=button(details,t('nice'),function() card:Destroy() end,UDim2.new(1,-12,0,68),UDim2.fromOffset(6,254),Pal.Mint);confirm.Name='ConfirmReveal';confirm.UITextSizeConstraint.MaxTextSize=68
 modalLayouts[card]=function()
  local wide=gui.AbsoluteSize.X>gui.AbsoluteSize.Y*1.25
  card.Size=UDim2.fromOffset(wide and 760 or 450,wide and 440 or 684)
  portrait.Size=UDim2.fromOffset(wide and 290 or 270,wide and 302 or 266);portrait.Position=UDim2.fromOffset(wide and 24 or 90,78)
  stars.Position=UDim2.fromOffset(wide and 169 or 225,wide and 388 or 336)
  details.Size=UDim2.fromOffset(wide and 406 or 402,322);details.Position=UDim2.fromOffset(wide and 328 or 24,wide and 84 or 368)
  if not wide then income.Position=UDim2.fromOffset(6,146);confirm.Position=UDim2.fromOffset(6,232) else income.Position=UDim2.fromOffset(6,158);confirm.Position=UDim2.fromOffset(6,254) end
 end
 modalLayouts[card]();bounce(card:FindFirstChildOfClass('UIScale'),fitModal(card));refreshModal()
end

gui:GetAttributeChangedSignal("OpenCryptAt"):Connect(function() openMenu("crypt") end)
rem.Notice.OnClientEvent:Connect(function(key, args)
 -- Mutagen from a kill flies into the counter, as the Zombucks do (owner, 2026-11-14: no "+1 mutagen" text).
 if key=="mutagenDrop" then
 local pos=type(args)=="table" and typeof(args.pos)=="Vector3" and args.pos
 local icon=metrics:FindFirstChild('MutagenIcon');if not icon then return end
 local host=metrics.Parent
 local target=icon.AbsolutePosition+icon.AbsoluteSize/2-host.AbsolutePosition
 local start
 if pos then local q,on=workspace.CurrentCamera:WorldToScreenPoint(pos);if on then start=Vector2.new(q.X,q.Y)-host.AbsolutePosition end end
 start=start or host.AbsoluteSize/2
 for i=1,math.clamp(math.floor(tonumber(args and args.n) or 1),1,6) do
  local f=Style.ModalArt(host,'mutagen',nil,UDim2.fromOffset(34,38),UDim2.fromOffset(start.X+math.random(-30,30)-17,start.Y+math.random(-20,20)-19));f.Name='FlyingMutagen';f.ZIndex=30
  TweenService:Create(f,TweenInfo.new(.6+i*.05,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=UDim2.fromOffset(target.X-8,target.Y-9),Size=UDim2.fromOffset(16,18)}):Play()
  game:GetService("Debris"):AddItem(f,1.1)
 end
 task.delay(.65,function() local s=icon:FindFirstChildOfClass('UIScale') or Instance.new('UIScale',icon);s.Scale=1.25;TweenService:Create(s,TweenInfo.new(.25,Enum.EasingStyle.Back),{Scale=1}):Play() end)
  return
 end
 if key=="openCrypt" then openMenu("crypt");return elseif key=="zombieCard" then cardId=args.id;openMenu("zombieCard");return end
 -- No toasts for these (owner, 2026-11-14: visual noise): a grave brought home only plays a soft hit; a sleeping
 -- boss is explained once by the heist window (HelpController).
 if key=="roadStoredQuiet" then Sfx.jingle("Reveal");return end
 if key=="bossAsleep" then return end
	if key == "error" then
		Sfx.play("Error", 0.4)
	elseif key == "caught" then
		Sfx.play("Caught")
	elseif key == "questDone" then
		Sfx.play("PetHatchSound", 1)
		args = { name = t("quest_" .. args.id, { n = short(args.goal) }) }
	elseif key == "roadDelivered" or key == "roadStored" then
		Sfx.jingle("Reveal") -- a short soft hit: the long fanfare was too loud for something done every minute
	elseif key == "inviteWelcome" or key == "inviteReward" or key == "houseDone" then
		Sfx.jingle("RareReveal") -- (Sfx.jingle: the reveal jingles never sound on top of one another, 2026-11-16)
	end
 if key=="petDug" then return end

	if key == "reveal" then
		revealCard(args)
	else
		if key == "starRare" then args.type=t(args.type) end
		if key == "roadRare" or key == "roadDelivered" or key == "roadStored" or key == "bloodMoonGrave" then args.grave=t("grave_"..args.grave) end
		if key == "portalDowngrade" then args.from=t("grave_"..tostring(args.from));args.to=t("grave_"..tostring(args.to)) end
		if type(args) == "table" and type(args.boss) == "string" then args.boss=t(args.boss) end -- every boss notice (sleeping-boss ones too)
		if key == "petDug" then args.rarity=t(args.rarity);args.type=t(args.type) elseif key=="petRare" then args.rarity=t(args.rarity);args.species=t(args.species) elseif key == "rare" then
			args.rarity = t(args.rarity)
			args.type = t(args.type)
		end
		flash(t(key, args), false, nil, Notifications.Type(key), key)
	end
end)

local promptService = game:GetService("ProximityPromptService")
promptService.PromptTriggered:Connect(function(pr)
	if pr.Name == "HouseMenu" then
		openMenu(pr:GetAttribute("Menu"))
	end
end)
promptService.PromptShown:Connect(function(pr)
	local key=({DigPrompt="dig",StealGrave="stealGrave",PlantGrave="plant",ShooPrompt="shoo",LockPrompt="lock",ExpandPrompt="expand",HouseEnter="houseEnter",HouseExit="houseExit",RoadGrab="roadGrab",RepairGate="repairGate",PortalHome="portalHome"})[pr.Name] or (pr.Name=="HouseMenu" and "house_"..tostring(pr:GetAttribute("Menu")))
 if not key then return end
 pr.AutoLocalize=false
 pr.ActionText=t(key)
 if pr.Name == "RoadGrab" then
  local grave=t("grave_" .. tostring(pr:GetAttribute("Grave")))
  -- with whose it is (the grave model's Family, 2026-11-17): "Stone grave · Deer"
  local family=pr.Parent.Parent:GetAttribute("Family");if family then grave=grave.." · "..t("roadName_"..family) end
  pr.ObjectText=pr.Parent.Parent:GetAttribute("Dropped") and t("roadDroppedObject",{grave=grave}) or grave
 end
 -- no "loses 1 rarity" line over the portal: a carried grave goes through as it is since 2026-11-14 (owner, 2026-11-15)
 if pr.Name == "PortalHome" then pr.ObjectText = "" end
 if pr.Name == "ExpandPrompt" then pr.ObjectText = t(pr:GetAttribute("Zone")) .. " · 💰 " .. short(pr:GetAttribute("Price") or 0) end
	if pr.Name == "DigPrompt" then
		local m = pr.Parent.Parent
		pr.ObjectText = t("grave_" .. (m:GetAttribute("GraveType") or "Wooden")) .. " · " .. ((m:GetAttribute("Remaining") or 0) == 0 and t("ready") or t("waiting", { n = m:GetAttribute("Remaining") }))
	end
end)

-- Prompts are tracked as they appear: scanning the now much richer world twice a second would be wasteful.
local prompts = {}
local function trackPrompt(d)
	if d:IsA("ProximityPrompt") and (d.Name == "StealGrave" or d.Name=="RepairGate" or d.Name=="PortalHome" or d.Name=="DigPrompt" or d.Name=="PlantGrave" or d.Name == "ShooPrompt" or d.Name == "LockPrompt" or d.Name == "ExpandPrompt" or d.Name == "HouseEnter" or d.Name == "RoadGrab") then
		prompts[d] = true
	end
end
workspace.DescendantAdded:Connect(trackPrompt)
for _, d in ipairs(workspace:GetDescendants()) do
	trackPrompt(d)
end
task.spawn(function()
	-- After shoving someone on the road, lifting graves takes longer (RoadConfig.HitPenalty): the prompt's hold stretches.
	local function slowHold(pr)
		local base = pr:GetAttribute("BaseHold") or pr.HoldDuration
		pr:SetAttribute("BaseHold", base)
		pr.HoldDuration = base * (workspace:GetServerTimeNow() < (p:GetAttribute("PickupSlowUntil") or 0) and RoadC.HitPenalty.Hold or 1)
	end
	while task.wait(0.5) do
		for pr in pairs(prompts) do
			-- with streaming a prompt can outlive its model on the client for a moment: drop it
			if not pr.Parent or not pr.Parent.Parent or not pr:IsDescendantOf(workspace) then
				prompts[pr] = nil
			else
				local owner = pr:GetAttribute("Owner")
				if pr.Name == "StealGrave" then
					local m = pr.Parent.Parent
					pr.Enabled = owner ~= p.UserId and state ~= nil and state.night and not m:GetAttribute("Starter") and not p:GetAttribute("CarryingGrave") and (p:GetAttribute("NewbieBoost") or 1) <= 1 -- newcomers don't steal
					slowHold(pr)
				elseif pr.Name=="DigPrompt" then pr.Enabled=pr.Parent.Parent:GetAttribute("Owner")==p.UserId
                elseif pr.Name=="PlantGrave" then pr.Enabled=game.UserInputService.GamepadEnabled and owner==p.UserId and p:GetAttribute("ActiveSlot")==3 and p:GetAttribute("SelectedGrave")~=nil
                elseif pr.Name=="RepairGate" then pr.Enabled=owner==p.UserId and pr:GetAttribute("Needed")==true
                elseif pr.Name=="PortalHome" then pr.Enabled=p:GetAttribute("PortalBoss")==pr:GetAttribute("Boss") -- only for those who beat the boss
                elseif pr.Name == "RoadGrab" then
					pr.Enabled = not p:GetAttribute("CarryingGrave") and not p:GetAttribute("CarryingZombie") and workspace:GetServerTimeNow()>=(p:GetAttribute("RoadStunnedUntil") or 0)
					slowHold(pr)
				else
					pr.Enabled = owner == p.UserId
				end
			end
		end
	end
end)

send("sync")


rem:WaitForChild("PetState").OnClientEvent:Connect(function(data)
 local changed=not petState or game.HttpService:JSONEncode({petState.pets,petState.slots,petState.bonuses,menu=="pumpkins" and petState.coins})~=game.HttpService:JSONEncode({data.pets,data.slots,data.bonuses,menu=="pumpkins" and data.coins})
 petState=data;for _,pet in ipairs(data.pets) do if pet.equipped then petStarterHint=false;break end end;if data.starterPet and not starterShown and showPetHatch then starterShown=true;showPetHatch({pet=data.starterPet,starter=true}) end;if panel.Visible and (menu=="pets" or menu=="pumpkins") and changed then render() end
end)
-- MutantService emits one Notice per wave; PetAlarm only drives dog sound/animation for mutants.
rem:WaitForChild("PetAlarm").OnClientEvent:Connect(function(_,kind)
 if kind ~= "mutant" then flash(t("petAlarm"), false, 4, "warning", "petAlarm") end
end)
-- The pet that came out, on its card: its picture, a burst in its rarity's colour, then its name, its rarity and what
-- it does. Both the starter's pumpkin and a pumpkin's case end with it. Yields: call it from a thread of its own.
function More.petReveal(card,vp,result)
 petArt(vp,result.pet)
 for i=1,20 do local f=Instance.new("Frame");f.Size=UDim2.fromScale(.018,.018);f.Position=UDim2.fromScale(.5,.4);f.BackgroundColor3=Pal[PetC.Tiers[result.pet.tier]];f.ZIndex=10;f.Parent=card;TweenService:Create(f,TweenInfo.new(.8),{Position=UDim2.fromScale(math.random(),1),Rotation=math.random(-180,180),BackgroundTransparency=1}):Play();game.Debris:AddItem(f,.9) end
 label(card,t(result.pet.species),UDim2.fromScale(1,.11),UDim2.fromScale(0,.58),{title=true,textSize=34})
 task.wait(.25);if not card.Parent then return end;label(card,t(PetC.Tiers[result.pet.tier]),UDim2.fromScale(1,.08),UDim2.fromScale(0,.69),{textSize=26,color=Pal[PetC.Tiers[result.pet.tier]]})
 task.wait(.25);if not card.Parent then return end;label(card,petAbility(result.pet),UDim2.fromScale(1,.07),UDim2.fromScale(0,.77),{textSize=24})
 Sfx.play("PetHatchSound",.5)
end
-- The starter pet's pumpkin (and any pet that arrives with no case window open): it rocks, then the pet.
showPetHatch=function(result)
 local old=gui:FindFirstChild("PetHatch");if old then old:Destroy() end
 local previousMenu=panel.Visible and menu or nil
 panel.Visible=false
 if result.starter then petStarterHint=true end
 local card=scaledBy(Style.ModalWindow(Instance.new("Frame")));card.Name="PetHatch";card.Size=UDim2.fromOffset(480,440);card.AnchorPoint=Vector2.new(.5,.5);card.Position=UDim2.fromScale(.5,.5);card.ZIndex=20;card.Parent=gui;fitModal(card);modalLayouts[card]=function() end;refreshModal()
 local function closeHatch()
  card:Destroy()
  if result.starter or previousMenu then menu=result.starter and "pets" or previousMenu;panel.Visible=true;render() end
 end
 modalTitle(card,t("pets"),closeHatch)
 local vp=Instance.new("Frame");vp.Size=UDim2.fromScale(.8,.43);vp.Position=UDim2.fromScale(.1,.15);vp.BackgroundTransparency=1;vp.Parent=card
 local pumpkin=iconImage(vp,'modal_pumpkin_Pumpkin',UDim2.fromScale(.8,.95),UDim2.fromScale(.1,0))
 task.spawn(function()
 for i=1,3 do
  if not card.Parent then return end
  local tween=TweenService:Create(pumpkin,TweenInfo.new(.18,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,1,true),{Rotation=15});tween:Play();tween.Completed:Wait()
 end
 if not card.Parent then return end;pumpkin:Destroy();More.petReveal(card,vp,result)
 end)
 button(card,t("close"),closeHatch,UDim2.fromScale(.4,.08),UDim2.fromScale(.3,.85))
end
-- Pet pumpkins are cases (owner, 2026-11-16: "it isn't clear that the pets' pumpkins are cases - maybe a tap should
-- open an interface like CS:GO's"). A pumpkin's card opens its case: every pet that can be inside with its chance
-- (the kind's weight times the rarity's, PetConfig and PumpkinConfig - the server's own dice), and an Open button with
-- the price. The purchase is the old one (PetHatch); the server's answer (PetHatched) spins a strip of pets under a
-- marker, slowing down to stop on the one that hatched, and then shows it as before. Closing the window mid-spin
-- loses nothing: the pet is in the inventory from the moment the server answered.
function More.caseOdds(name)
 local pumpkin=Pumpkins[name];local list={};local kinds,tiers=0,0
 for _,w in ipairs(PetC.Weights) do kinds+=w end;for _,w in ipairs(pumpkin.Weights) do tiers+=w end
 for tier,tw in ipairs(pumpkin.Weights) do if tw>0 then
  for i,species in ipairs(PetC.Order) do local kw=PetC.Weights[i] or 0;if kw>0 then table.insert(list,{species=species,tier=tier,chance=kw/kinds*tw/tiers}) end end
 end end
 return list
end
function More.casePick(odds)
 local r=math.random()
 for _,o in ipairs(odds) do r-=o.chance;if r<=0 then return o end end
 return odds[#odds]
end
-- one pet of a case: its picture on its rarity's colour, and under it the chance (the list) or the rarity (the strip)
function More.caseCard(parent,pet,size,pos,chance)
 local tierName=PetC.Tiers[pet.tier] or PetC.Tiers[1];local color=Pal[tierName]
 local c=Style.ModalSurface(Instance.new("Frame"),color:Lerp(Color3.new(1,1,1),.35),12,false);c.Name="CasePet";c.Size=size;c.Position=pos or UDim2.new();c.Parent=parent
 c.UIStroke.Color=color:Lerp(Color3.new(0,0,0),.35);c.UIStroke.Thickness=2.5
 local pic=Instance.new("Frame");pic.Name="Picture";pic.BackgroundTransparency=1;pic.Size=UDim2.new(1,-8,1,-34);pic.Position=UDim2.fromOffset(4,4);pic.Parent=c
 petArt(pic,{species=pet.species,tier=pet.tier})
 local bar=Instance.new("Frame");bar.Name="Rarity";bar.Size=UDim2.new(1,-8,0,24);bar.Position=UDim2.new(0,4,1,-28);bar.BackgroundColor3=color;bar.BorderSizePixel=0;bar.ZIndex=3;bar.Parent=c
 Instance.new("UICorner",bar).CornerRadius=UDim.new(0,8)
 local st=Instance.new("UIStroke",bar);st.Color=color:Lerp(Color3.new(0,0,0),.5);st.Thickness=1.5
 local text=chance and L.number(chance*100,lang,(chance*100)%1<.05 and 0 or 1).."%" or t(tierName)
 local caption=label(bar,text,UDim2.fromScale(1,1),nil,{title=true,textSize=17});caption.Name="Caption";caption.TextColor3=Color3.new(1,1,1);caption.ZIndex=4
 local outline=caption:FindFirstChild("ModalTextOutline");if outline then outline.Color=Color3.fromRGB(25,18,35);outline.Transparency=0;outline.Thickness=1 end
 return c
end
More.showPetCase=function(name)
 local pumpkin=Pumpkins[name];if not pumpkin or not state then return end
 local old=gui:FindFirstChild("PetHatch");if old then old:Destroy() end
 local previousMenu=panel.Visible and menu or nil
 panel.Visible=false
 local card=scaledBy(Style.ModalWindow(Instance.new("Frame")));card.Name="PetHatch";card.Size=UDim2.fromOffset(640,540);card.AnchorPoint=Vector2.new(.5,.5);card.Position=UDim2.fromScale(.5,.5);card.ZIndex=20;card.Parent=gui;fitModal(card);modalLayouts[card]=function() end;refreshModal()
 local function closeCase()
  if More.caseWaiting and More.caseWaiting.card==card then More.caseWaiting=nil end
  card:Destroy()
  if previousMenu then menu=previousMenu;panel.Visible=true;render() end
 end
 modalTitle(card,t(name),closeCase)
 local odds=More.caseOdds(name)
 -- what is inside
 local body=Instance.new("Frame");body.Name="Contents";body.BackgroundTransparency=1;body.Size=UDim2.new(1,0,1,-64);body.Position=UDim2.fromOffset(0,64);body.Parent=card
 local art=pumpkinArt(body,name);art.Size=UDim2.fromOffset(76,76);art.Position=UDim2.fromOffset(24,0)
 -- walked away from the pet shop with the case still shut: the window goes with the shop's menu (a spin plays out)
 local left=gui:GetAttributeChangedSignal("ZoneMenuKey"):Connect(function()
  if gui:GetAttribute("ZoneMenuKey")~="pumpkins" and card.Parent and not card:GetAttribute("Spinning") then previousMenu=nil;closeCase() end
 end)
 card.Destroying:Connect(function() left:Disconnect() end)
 label(body,t("caseContains"),UDim2.new(1,-134,0,60),UDim2.fromOffset(110,8),{title=true,textSize=28,align=LEFT})
 local grid=Instance.new("Frame");grid.Name="Pets";grid.BackgroundTransparency=1;grid.Size=UDim2.new(1,-40,0,290);grid.Position=UDim2.fromOffset(20,84);grid.Parent=body
 local layout=Instance.new("UIGridLayout");layout.CellSize=UDim2.fromOffset(#odds>8 and 110 or 138,#odds>8 and 90 or 138);layout.CellPadding=UDim2.fromOffset(10,10);layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.HorizontalAlignment=Enum.HorizontalAlignment.Center;layout.VerticalAlignment=Enum.VerticalAlignment.Center;layout.Parent=grid
 for i,o in ipairs(odds) do More.caseCard(grid,o,UDim2.new(),nil,o.chance).LayoutOrder=i end
 local function blocked() return petState and #petState.pets>=PetC.Inventory and "petFull" or state.coins<pumpkin.Price and "petNoCoins" or pumpkin.NightOnly and not state.night and "petNightOnly" or nil end
 local waitingSince
 local open=button(body,t("caseOpen",{price="$"..short(pumpkin.Price)}),function()
  local reason=blocked()
  if reason then flash(t(reason),true);return end
  if waitingSince and os.clock()-waitingSince<3 then return end -- one purchase a press: the answer is on its way
  waitingSince=os.clock();More.caseWaiting={card=card,name=name,spin=function(result) More.caseSpin(card,body,name,odds,result,closeCase) end}
  petSend("PetHatch",name)
 end,UDim2.new(1,-200,0,64),UDim2.new(0,100,1,-86),blocked() and Pal.Common or Pal.Mint)
 open.Name="OpenCase";open.UITextSizeConstraint.MaxTextSize=30
end
-- The spin: the pets of the case run past the marker and slow down; the one in WIN's place is the pet that hatched.
function More.caseSpin(card,body,name,odds,result,close)
 if not card.Parent then return end
 card:SetAttribute("Spinning",true);body:ClearAllChildren()
 local N,WIN,CW,GAP,SECONDS=40,35,132,8,4.6;local pitch=CW+GAP;local width=600
 local window=Style.ModalSurface(Instance.new("Frame"),Style.ModalColors.Purple,14,false);window.Name="Roulette";window.Size=UDim2.fromOffset(width,176);window.Position=UDim2.fromOffset(20,96);window.ClipsDescendants=true;window.Parent=body
 local strip=Instance.new("Frame");strip.Name="Strip";strip.BackgroundTransparency=1;strip.Size=UDim2.fromOffset(N*pitch,152);strip.Position=UDim2.fromOffset(0,12);strip.Parent=window
 for i=1,N do More.caseCard(strip,i==WIN and result.pet or More.casePick(odds),UDim2.fromOffset(CW,152),UDim2.fromOffset((i-1)*pitch,0)).LayoutOrder=i end
 for _,y in {0,1} do -- the marker: a gold line down the middle with a notch at each end
  local notch=Instance.new("Frame");notch.Name="Notch";notch.AnchorPoint=Vector2.new(.5,.5);notch.Size=UDim2.fromOffset(18,18);notch.Position=UDim2.new(.5,0,y,0);notch.Rotation=45;notch.BackgroundColor3=Style.ModalColors.Gold;notch.BorderSizePixel=0;notch.ZIndex=8;notch.Parent=window
 end
 local marker=Instance.new("Frame");marker.Name="Marker";marker.AnchorPoint=Vector2.new(.5,0);marker.Size=UDim2.new(0,4,1,0);marker.Position=UDim2.fromScale(.5,0);marker.BackgroundColor3=Style.ModalColors.Gold;marker.BorderSizePixel=0;marker.ZIndex=8;marker.Parent=window
 -- it starts with the first cards in view and stops with the marker somewhere on the winner's card, not dead centre
 local stop=(WIN-1)*pitch+CW/2+(math.random()-.5)*CW*.7-width/2
 local tween=TweenService:Create(strip,TweenInfo.new(SECONDS,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Position=UDim2.fromOffset(-stop,12)});tween:Play()
 task.spawn(function()
  -- a click as each card passes the marker
  local last=0;local started=os.clock()
  while card.Parent and os.clock()-started<SECONDS do
   local index=math.floor((width/2-strip.Position.X.Offset)/pitch)
   if index~=last then last=index;Sfx.play("Click",.04,.45) end
   RunService.Heartbeat:Wait()
  end
  if not card.Parent then return end
  task.wait(.35);if not card.Parent then return end
  local won=nil;for _,c in strip:GetChildren() do if c.LayoutOrder==WIN then won=c end end
  if won then won.UIStroke.Color=Style.ModalColors.Gold;TweenService:Create(won.UIStroke,TweenInfo.new(.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Thickness=6}):Play() end
  task.wait(.75);if not card.Parent then return end
  body:Destroy()
  local vp=Instance.new("Frame");vp.Size=UDim2.fromScale(.8,.43);vp.Position=UDim2.fromScale(.1,.15);vp.BackgroundTransparency=1;vp.Parent=card
  button(card,t("close"),close,UDim2.fromScale(.4,.08),UDim2.fromScale(.3,.85))
  More.petReveal(card,vp,result)
 end)
end
rem:WaitForChild("PetHatched").OnClientEvent:Connect(function(result)
 local case=More.caseWaiting;More.caseWaiting=nil
 if case and case.card.Parent and case.name==result.pumpkin and not result.starter then case.spin(result) else showPetHatch(result) end
end)
petSend("PetSync")

rem:WaitForChild("WeaponState").OnClientEvent:Connect(function(data) local changed=not weaponState or weaponState.equipped~=data.equipped or game.HttpService:JSONEncode(weaponState.owned)~=game.HttpService:JSONEncode(data.owned) or game.HttpService:JSONEncode(weaponState.skins or {})~=game.HttpService:JSONEncode(data.skins or {});weaponState=data;if changed and panel.Visible and (menu=="weapons" or menu=="inventory" or menu=="weaponSkins") then render() end end)

-- Force the interrupted prompt to reset its local hold ring immediately.
p:GetAttributeChangedSignal("RoadPickupInterruptedAt"):Connect(function()
 for pr in pairs(prompts) do if pr.Parent and pr.Name=="RoadGrab" then pr.Enabled=false end end
end)
p:GetAttributeChangedSignal("RoadTraps"):Connect(function()
 if panel.Visible and (menu=="traps" or menu=="inventory") then render() end
end)
