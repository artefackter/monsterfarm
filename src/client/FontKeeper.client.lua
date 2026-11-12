-- One typeface everywhere, menus and world signs alike: Nunito Heavy. It has the chunky rounded letters of
-- popular Roblox simulators and, unlike Fredoka One or Luckiest Guy, real Cyrillic (those fall back to a thin
-- system font for Russian). Applied as text appears, so no script has to know about it.
local Players = game:GetService("Players")
local FACE = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Heavy)

-- Roblox's own chat measures text with the old Font enum, so its windows and bubbles are left alone.
local SKIP = { Chat = true, BubbleChat = true, ExperienceChat = true, TextChatService = true }
local function foreign(x)
	local gui = x:FindFirstAncestorWhichIsA("LayerCollector")
	while gui do
		if SKIP[gui.Name] then
			return true
		end
		gui = gui.Parent and gui.Parent:FindFirstAncestorWhichIsA("LayerCollector")
	end
	return x:FindFirstAncestor("Chat") ~= nil or x:FindFirstAncestor("BubbleChat") ~= nil
end
local function apply(x)
	if not (x:IsA("TextLabel") or x:IsA("TextButton") or x:IsA("TextBox")) or foreign(x) then
		return
	end
	if x.FontFace ~= FACE then
		x.FontFace = FACE
	end
	-- Scripts that pick a font later (re-renders, language changes) are put back on the same face.
	x:GetPropertyChangedSignal("FontFace"):Connect(function()
		if x.FontFace ~= FACE then
			x.FontFace = FACE
		end
	end)
end

local function watch(root)
	for _, x in root:GetDescendants() do
		apply(x)
	end
	root.DescendantAdded:Connect(apply)
end

watch(Players.LocalPlayer:WaitForChild("PlayerGui"))
watch(workspace)
