-- One client-owned surface for transient messages and persistent gameplay guides.
local Players = game:GetService("Players")
local L = require(script.Parent.Locale)
local N = {}
N.Colors = {
 info = Color3.fromRGB(240, 240, 255),
 guide = Color3.fromRGB(95, 220, 255),
 success = Color3.fromRGB(115, 255, 105),
 reward = Color3.fromRGB(255, 218, 65),
 rare = Color3.fromRGB(210, 0, 255),
 warning = Color3.fromRGB(255, 157, 55),
 error = Color3.fromRGB(255, 85, 105),
}
local types = {}
local groups = {
 success = {"ok","roadStored","roadDelivered","trapBought","trapPlaced","houseDone","mutantNewbie"},
 reward = {"questDone","inviteReward","inviteWelcome","killToast","chiefGraveDropped","bossGraveDropped","petDug","offlineHeap","bloodMoonGrave","prestigeDone"},
 rare = {"rare","starRare","petRare","roadRare","bossDefeated","bloodMoonWin","prestigeAll"},
 warning = {"bossArena","mutantWave","mutantStolen","petAlarm","caught","roadDropped","roadLost","roadFaint","roadFell","roadNight","roadPickupInterrupted","trapCaught","trapCaughtDrop","bloodMoonRise","bloodMoonLost","roadClosed","bloodMoonEnough"},
 guide = {"giftHint","petStarter","placeHint","placeCemetery","placeWorker","placeDefender","roadBatHint","mergeHint"},
 error = {"error","prestigeBusy","weaponDenied","inviteUnavailable","mergeNeedThree","giftGroupRequired","roadGearDenied","roadBossFirst","batCarryDenied","trapEmpty","trapFull","trapPlacedFull","trapVisitShop","trapStockFull","trapNoCoins","trapBadSpot","petBusy","petUnequipFirst","petSlotsFull","petShopDistance","petNightOnly","petMaxSlots","petNoCoins","petFull","placeFar","placeCrowded","placeGravesFull","placeOutside","placeGuardsFull","placeBad","placeNoGrave","placeFieldFull","homeKO","homeTrap","homeCooldown","homeDig","homeCarry","homeUnavailable","homeRoad"},
}
for kind, keys in pairs(groups) do for _, key in ipairs(keys) do types[key] = kind end end
function N.Type(key) return types[key] or "info" end

local layer, player
local messages, guides = {}, {}
local layout
local function font()
 return L.lang():sub(1, 2) == "ru" and Enum.Font.GothamBlack or Enum.Font.FredokaOne
end
local function init()
 if layer then return end
 player = Players.LocalPlayer
 assert(player, "Notifications is client-only")
 layer = Instance.new("ScreenGui")
 layer.Name = "Notifications"
 layer.ResetOnSpawn = false
 layer.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
 layer.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
 layer.DisplayOrder = 25
 layer.Parent = player:WaitForChild("PlayerGui")
 layer:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() layout() end)
 player:GetAttributeChangedSignal("Language"):Connect(function()
  for _, x in ipairs(layer:GetDescendants()) do
   if x:IsA("TextLabel") or x:IsA("TextButton") then x.Font = font() end
  end
 end)
end
local function outline(label)
 local stroke = Instance.new("UIStroke")
 stroke.Color = Color3.fromRGB(12, 8, 18)
 stroke.Thickness = 2.5
 stroke.LineJoinMode = Enum.LineJoinMode.Round
 stroke.Parent = label
end
local function create(name)
 init()
 local frame = Instance.new(name=="Location" and "CanvasGroup" or "Frame")
 frame.Name = name
 frame.AnchorPoint = Vector2.new(0.5, 0)
 frame.BackgroundColor3 = Color3.new(0, 0, 0)
 frame.BackgroundTransparency = 0.7
 frame.BorderSizePixel = 0
 frame.Visible = false
 frame.Parent = layer
 local fade = Instance.new("UIGradient")
 fade.Transparency = NumberSequence.new({
  NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.25, 0.25),
  NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(0.75, 0.25),
  NumberSequenceKeypoint.new(1, 1),
 })
 fade.Parent = frame
 local label = Instance.new("TextLabel")
 label.Name = "Message"
 label.BackgroundTransparency = 1
 label.Position = UDim2.fromOffset(14, 3)
 label.Size = UDim2.new(1, -28, 1, -6)
 label.Font = font()
 label.TextScaled = true
 label.TextWrapped = true
 label.AutoLocalize = false
 label.Parent = frame
 local limit = Instance.new("UITextSizeConstraint")
 limit.MinTextSize = 12
 limit.MaxTextSize = 48
 limit.Parent = label
 outline(label)
 return {frame = frame, label = label}
end
layout = function()
 if not layer then return end
 local v = layer.AbsoluteSize
 local scale = math.clamp(math.min(v.X / 1000, v.Y / 560), 0.52, 1.1)
 local width = math.max(1, math.min(1100, v.X - 16))
 local height = 64 * scale
 local y = 0 -- highest position below Roblox's safe-area inset
 local function place(entry)
  local entryHeight=entry.location and height*1.35 or height
  entry.frame.Size = UDim2.fromOffset(entry.location and math.min(width,660*scale) or width, entryHeight)
  entry.frame.Position = UDim2.new(0.5, 0, 0, y)
  entry.frame.Visible = true
  y += entryHeight + 3
 end
 for _, entry in ipairs(messages) do place(entry) end
 local best
 for _, entry in pairs(guides) do
  entry.frame.Visible = false
  if entry.enabled and (not best or entry.priority > best.priority) then best = entry end
 end
 if best then place(best) end
end
local function remove(entry)
 local i = table.find(messages, entry)
 if not i then return end
 table.remove(messages, i)
 entry.frame:Destroy()
 layout()
end
function N.Show(text, kind, duration, key)
 init()
 kind = kind or "info"
 local identity = (key or kind) .. ":" .. text
 -- Identical concurrent events share a single banner and timer.
 for _, entry in ipairs(messages) do if entry.identity == identity then return end end
 local entry = create("Notification")
 entry.identity = identity
 entry.label.Text = text
 entry.label.TextColor3 = N.Colors[kind] or N.Colors.info
 entry.frame:SetAttribute("NotificationType", kind)
 table.insert(messages, entry)
 if #messages > 2 then remove(messages[1]) end
 layout()
 task.delay(duration or 3.5, function() remove(entry) end)
end
function N.ClearLocation()
 for i=#messages,1,-1 do if messages[i].location then remove(messages[i]) end end
end
function N.Location(title, subtitle)
 init()
 N.ClearLocation()
 local entry=create("Location")
 entry.location=true
 entry.label.Text=title
 entry.label.TextColor3=Color3.fromRGB(255,244,211)
 entry.label.Position=UDim2.new(0,14,.035,0)
 entry.label.Size=UDim2.new(1,-28,.50,0)
 entry.label.UITextSizeConstraint.MaxTextSize=34
 local detail=entry.label:Clone()
 detail.Name="RecommendedSpeed"
 detail.Position=UDim2.new(0,14,.55,0)
 detail.Size=UDim2.new(1,-28,.39,0)
 detail.Text=subtitle
 detail.TextColor3=Color3.fromRGB(255,225,130)
 detail.UITextSizeConstraint.MinTextSize=10
 detail.UITextSizeConstraint.MaxTextSize=23
 detail.Parent=entry.frame
 entry.frame.GroupTransparency=1
 table.insert(messages,1,entry)
 if #messages>2 then remove(messages[#messages]) end
 layout()
 game:GetService("TweenService"):Create(entry.frame,TweenInfo.new(.18),{GroupTransparency=0}):Play()
 task.delay(4.5,function()
  if not table.find(messages,entry) then return end
  game:GetService("TweenService"):Create(entry.frame,TweenInfo.new(.22),{GroupTransparency=1}):Play()
  task.delay(.22,function() remove(entry) end)
 end)
end
function N.Guide(id, text, kind, enabled, priority, actionText, callback)
 init()
 local entry = guides[id]
 if not entry and not enabled then return end
 if not entry then entry = create(id);guides[id] = entry end
 entry.label.Text = text or ""
 entry.label.TextColor3 = N.Colors[kind or "guide"] or N.Colors.guide
 entry.priority = priority or 0
 local changed = entry.enabled ~= enabled
 entry.enabled = enabled
 if actionText and not entry.action then
  local action = Instance.new("TextButton")
  action.Name = "GuideAction"
  action.AnchorPoint = Vector2.new(1, 0.5)
  action.Position = UDim2.new(1, -14, 0.5, 0)
  action.Size = UDim2.new(0.25, 0, 1, -8)
  action.BackgroundTransparency = 1
  action.Font = font()
  action.TextScaled = true
  action.TextWrapped = true
  action.AutoLocalize = false
  action.TextColor3 = N.Colors.guide
  action.Parent = entry.frame
  local limit = Instance.new("UITextSizeConstraint", action)
  limit.MaxTextSize = 24
  outline(action)
  action.Activated:Connect(function() if entry.callback then entry.callback() end end)
  entry.action = action
 end
 if entry.action then entry.action.Visible = actionText ~= nil;entry.action.Text = actionText or "" end
 entry.callback = callback
 entry.label.Size = actionText and UDim2.new(0.73, -28, 1, -6) or UDim2.new(1, -28, 1, -6)
 if changed then layout() end
end
return N
