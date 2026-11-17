local RS=game:GetService("ReplicatedStorage");local rem=RS:WaitForChild("Remotes");local rng=Random.new();local Sfx=require(RS:WaitForChild("Shared"):WaitForChild("Sfx"))
game:GetService("ProximityPromptService").PromptButtonHoldBegan:Connect(function(prompt) if prompt.Name=="DigPrompt" and prompt.Parent.Parent:GetAttribute("Remaining")==0 then Sfx.play("Dig") end end)
rem.Notice.OnClientEvent:Connect(function(key,z) if key~="reveal" then return end
 Sfx.jingle(z.tier>=3 and "RareReveal" or "Reveal") -- one at a time (2026-11-16): several graves dug no longer stack them
 local p=game.Players.LocalPlayer;local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart");if root then for i=1,18 do local part=Instance.new("Part");part.Shape=Enum.PartType.Ball;local d=rng:NextNumber(.3,.8);part.Size=Vector3.new(d,d,d);part.Color=Color3.fromHex(i%3==0 and "6E4429" or "8A5A3B");part.Material=Enum.Material.SmoothPlastic;part.CanCollide=false;part.CanQuery=false;part.CanTouch=false;part.Anchored=true;part.Position=root.Position+root.CFrame.LookVector*3;part.Parent=workspace;local top=part.Position+Vector3.new(rng:NextNumber(-4,4),rng:NextNumber(3,7),rng:NextNumber(-4,4));local up=game.TweenService:Create(part,TweenInfo.new(.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=top});up:Play();up.Completed:Connect(function() if part.Parent then game.TweenService:Create(part,TweenInfo.new(.4,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=top-Vector3.new(0,7,0),Size=Vector3.new(.05,.05,.05)}):Play() end end);game.Debris:AddItem(part,.8) end end
 if z.tier>=3 then local gui=p.PlayerGui:WaitForChild("DigUI");for i=1,28 do local f=Instance.new("Frame");f.Size=UDim2.fromOffset(rng:NextInteger(10,18),rng:NextInteger(10,18));f.Position=UDim2.fromScale(.5,.35);f.BorderSizePixel=0;f.ZIndex=30;f.BackgroundColor3=Color3.fromHSV(rng:NextNumber(),.75,1);Instance.new("UICorner",f).CornerRadius=UDim.new(0,3);f.Parent=gui;game.TweenService:Create(f,TweenInfo.new(1.3),{Position=UDim2.fromScale(rng:NextNumber(),1.1),Rotation=rng:NextNumber(-300,300),BackgroundTransparency=1}):Play();game.Debris:AddItem(f,1.4) end end
end)

local music={};local musicVolume={};local player=game.Players.LocalPlayer
local sounds=RS:WaitForChild("Sounds")
for _,name in ipairs({"DayMusic","NightMusic"}) do local source=sounds:WaitForChild(name);local sound=source:Clone();musicVolume[name]=source.Volume;sound.Volume=0;sound.Looped=true;sound.Parent=game:GetService("SoundService");music[name]=sound;if sound.SoundId~="" then sound:Play() end end
local gui=player.PlayerGui:WaitForChild("DigUI")
-- Music only on the player's own farm (owner, 2026-11-15): its square, the cemetery bulging past it, or the house; it
-- fades out on the plaza, the road and other farms.
local PlC=require(RS:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PlacementConfig"))
local onFarm=false
local function homeFarm()
 if player:GetAttribute("InHouse") then return true end
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart");local world=workspace:FindFirstChild("DigAZombie")
 if not root or not world then return false end
 for _,plot in world:GetChildren() do
  if plot:GetAttribute("Owner")==player.UserId then
   local lawn=plot:FindFirstChild("Lawn");if not lawn then return false end
   local v=lawn.CFrame:PointToObjectSpace(root.Position);local half=lawn.Size.X/2+1
   if math.abs(v.X)<=half and math.abs(v.Z)<=half and math.abs(v.Y)<60 then return true end
   local c=PlC.Cemetery;return Vector2.new(v.X-c.X,v.Z-c.Z).Magnitude<=c.Radius+1 and math.abs(v.Y)<60
  end
 end
 return false
end
local function mix() local night=gui:GetAttribute("Night");for name,sound in pairs(music) do game.TweenService:Create(sound,TweenInfo.new(3),{Volume=(onFarm and (name=="NightMusic")==night) and musicVolume[name]*(player:GetAttribute("MusicVolume") or .7) or 0}):Play() end end
gui:GetAttributeChangedSignal("Night"):Connect(mix);player:GetAttributeChangedSignal("MusicVolume"):Connect(mix);mix()
task.spawn(function() while true do local now=homeFarm();if now~=onFarm then onFarm=now;mix() end;task.wait(.5) end end)

-- No footstep sounds (owner, 2026-11-15: "remove the walking sounds"): Roblox's own character sounds play a looped
-- "Running" sound in every character's root part; it is kept silent here, for every character. Jumps and landings stay.
local function muteSteps(character)
 local function mute(s)
  if s:IsA("Sound") and s.Name=="Running" then
   s.Volume=0;s:GetPropertyChangedSignal("Volume"):Connect(function() if s.Volume~=0 then s.Volume=0 end end)
  end
 end
 for _,d in character:GetDescendants() do mute(d) end
 character.DescendantAdded:Connect(mute)
end
local function watchSteps(who) if who.Character then muteSteps(who.Character) end;who.CharacterAdded:Connect(muteSteps) end
for _,who in game.Players:GetPlayers() do watchSteps(who) end;game.Players.PlayerAdded:Connect(watchSteps)
