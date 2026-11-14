-- Things players kept missing (owner's playtest, 2026-11-10):
--  * what the night means and how to defend: a card at nightfall, and any time by tapping the day clock;
--  * a finished quest: a gold reminder above the clock and a "!" over the Quests board until the reward is taken;
--  * an empty farm next door: a prompt at its gate that opens the invite window.
local Players=game:GetService("Players");local Tween=game:GetService("TweenService");local SocialService=game:GetService("SocialService")
local PromptService=game:GetService("ProximityPromptService")
local p=Players.LocalPlayer;local RS=game.ReplicatedStorage;local S=RS:WaitForChild("Shared");local rem=RS:WaitForChild("Remotes")
local L=require(S:WaitForChild("Locale"));local Icons=require(S:WaitForChild("Icons"));local QuestRules=require(S:WaitForChild("QuestRules"))
local dig=p:WaitForChild("PlayerGui"):WaitForChild("DigUI");local clock=dig:WaitForChild("DayClock")
local function t(key,args) return L.text(key,L.lang(),args) end
local INK=Color3.fromRGB(20,14,40)
local function text(parent,size,pos,textSize,color)
 local l=Instance.new("TextLabel");l.BackgroundTransparency=1;l.Size=size;l.Position=pos;l.Font=Enum.Font.GothamBlack;l.TextSize=textSize;l.TextColor3=color or Color3.new(1,1,1);l.TextWrapped=true;l.AutoLocalize=false;l.Parent=parent
 local st=Instance.new("UIStroke");st.Color=INK;st.Thickness=2.2;st.LineJoinMode=Enum.LineJoinMode.Round;st.Parent=l
 return l
end
local function round(f,r) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r);c.Parent=f end
local function image(parent,key,size,pos)
 local i=Instance.new("ImageLabel");i.BackgroundTransparency=1;i.Size=size;i.Position=pos;i.Image=Icons[key] or "";i.ScaleType=Enum.ScaleType.Fit;i.Parent=parent;return i
end

local gui=Instance.new("ScreenGui");gui.Name="HelpUI";gui.ResetOnSpawn=false;gui.DisplayOrder=15;gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets;gui.Parent=p.PlayerGui

-- Night information: native live controls over separately painted artwork. --------------------------------------------
local playerGui=p.PlayerGui
local now=workspace:GetServerTimeNow();local nightConfig=require(S.Config.NightConfig)
local night=workspace:GetAttribute("IsNight")==true
local phase={night=night,endsAt=now+math.max(0,(night and nightConfig.Day+nightConfig.Night or nightConfig.Day)-now%(nightConfig.Day+nightConfig.Night))}
local firstPhasePacket=true
local pendingNight=false
local preference=p:GetAttribute("ShowNightInfo")~=false
local preferenceRevision=0
local view
local function hideCard()
 -- the layer drops first: clearing the attribute can open the other window at once, which raises it again
 view:SetVisible(false);gui.DisplayOrder=15;playerGui:SetAttribute("NightHelpOpen",false)
end
local function showCard()
 if dig:GetAttribute("OtherModalOpen")==true or (dig:GetAttribute("ModalOpen")==true and not view.Root.Visible) then return false end
 view:Update(phase.night,math.max(0,phase.endsAt-workspace:GetServerTimeNow()))
 view:SetDontShow(not preference);gui.DisplayOrder=35;view:SetVisible(true)
 playerGui:SetAttribute("NightHelpOpen",true);return true
end
view=require(S:WaitForChild("NightInfoView")).Create(gui,{
 close=hideCard,
 preference=function(dontShow)
  preference=not dontShow;preferenceRevision+=1;local revision=preferenceRevision
  if dontShow then pendingNight=false end
  -- Coalesce fast clicks so the existing settings remote's rate limit never loses the final choice.
  task.delay(.25,function()
   if revision==preferenceRevision then rem.InterfaceAction:FireServer("setting","ShowNightInfo",preference) end
  end)
 end,
})
local function tryPending()
 if pendingNight and preference and phase.night and not view.Root.Visible then
  if showCard() then pendingNight=false end
 end
end
local function phaseChanged(night,left)
 local wasNight=phase.night
 phase.night=night;phase.endsAt=workspace:GetServerTimeNow()+math.max(0,left)
 if night and not wasNight then pendingNight=not view.Root.Visible end
 if not night then pendingNight=false;if wasNight and view.Root.Visible then hideCard() end end
 tryPending()
end
rem:WaitForChild("State").OnClientEvent:Connect(function(s)
 if type(s)=="table" and type(s.night)=="boolean" and type(s.left)=="number" then
  if firstPhasePacket then pendingNight=s.night;firstPhasePacket=false end
  phaseChanged(s.night,s.left)
 end
end)
workspace:GetAttributeChangedSignal("IsNight"):Connect(function()
 local night=workspace:GetAttribute("IsNight")==true
 if night~=phase.night then
  local cfg=require(S.Config.NightConfig);phaseChanged(night,night and cfg.Night or cfg.Day)
 end
end)
p:GetAttributeChangedSignal("ShowNightInfo"):Connect(function()
 preference=p:GetAttribute("ShowNightInfo")~=false;view:SetDontShow(not preference)
 if not preference then pendingNight=false end
end)
dig:GetAttributeChangedSignal("OtherModalOpen"):Connect(function()
 if dig:GetAttribute("OtherModalOpen")==true then
  if view.Root.Visible then hideCard() end
 else tryPending() end
end)
dig:GetAttributeChangedSignal("ModalOpen"):Connect(tryPending)
p:GetAttributeChangedSignal("Language"):Connect(function() view:Refresh() end)
-- The grave-heist tutorial (owner, 2026-11-14): walking into a sleeping boss's arena (the server's "bossAsleep"
-- notice) opens a painted window with the boss's three choices, the first time only.
do
 local heistPreference=p:GetAttribute("ShowHeistInfo")~=false;local heistRevision=0
 local heist
 local function hideHeist() heist:SetVisible(false);gui.DisplayOrder=view.Root.Visible and 35 or 15;playerGui:SetAttribute("HeistHelpOpen",false) end
 heist=require(S:WaitForChild("NightInfoView")).Create(gui,{
  close=hideHeist,
  preference=function(dontShow)
   heistPreference=not dontShow;heistRevision+=1;local revision=heistRevision
   task.delay(.25,function() if revision==heistRevision then rem.InterfaceAction:FireServer("setting","ShowHeistInfo",heistPreference) end end)
  end,
 },{name="HeistInfoModal",title="heistTitle",noTimer=true,skin="heist_frame",noDontShow=true,specs={
  {image="heist_sleep",fallback="moon",title="heistSleepTitle",body="heistSleepBody"},
  {image="heist_run",fallback="crypt",title="heistRunTitle",body="heistRunBody"},
  {image="heist_fight",fallback="pistol",title="heistFightTitle",body="heistFightBody"},
 }})
 rem:WaitForChild("Notice").OnClientEvent:Connect(function(key,args)
  if key~="bossAsleep" or not heistPreference or heist.Root.Visible or view.Root.Visible then return end
  if dig:GetAttribute("OtherModalOpen")==true or dig:GetAttribute("ModalOpen")==true then return end
  heist:SetSubtitle(type(args)=="table" and type(args.boss)=="string" and "heistArena" or nil,{boss=type(args)=="table" and args.boss or nil})
  heist:SetDontShow(false);gui.DisplayOrder=35;heist:SetVisible(true);playerGui:SetAttribute("HeistHelpOpen",true)
  -- Shown once (owner, 2026-11-14): the setting goes off at once; Settings can turn it back on.
  heistPreference=false;rem.InterfaceAction:FireServer("setting","ShowHeistInfo",false)
 end)
 p:GetAttributeChangedSignal("ShowHeistInfo"):Connect(function() heistPreference=p:GetAttribute("ShowHeistInfo")~=false;heist:SetDontShow(not heistPreference) end)
 p:GetAttributeChangedSignal("Language"):Connect(function() heist:Refresh() end)
end
-- Manual access remains available even after automatic reminders were disabled.
local ask=Instance.new("TextButton");ask.Name="NightHelp";ask.BackgroundTransparency=1;ask.Size=UDim2.fromScale(1,1);ask.Text="";ask.ZIndex=5;ask.Parent=clock
local badge=Instance.new("TextLabel");badge.Name="Hint";badge.Size=UDim2.fromOffset(24,24);badge.Position=UDim2.fromOffset(44,-4);badge.BackgroundColor3=Color3.fromRGB(255,196,64);badge.Text="?";badge.Font=Enum.Font.GothamBlack;badge.TextSize=18;badge.TextColor3=INK;badge.ZIndex=6;badge.AutoLocalize=false;badge.Parent=clock;round(badge,12)
ask.Activated:Connect(function() if view.Root.Visible then hideCard() else pendingNight=false;showCard() end end)
game:GetService("UserInputService").InputBegan:Connect(function(input,processed)
 if view.Root.Visible and not processed and (input.KeyCode==Enum.KeyCode.Escape or input.KeyCode==Enum.KeyCode.ButtonB) then hideCard() end
end)
task.spawn(function()
 while gui.Parent do
  if view.Root.Visible then view:Update(phase.night,math.max(0,phase.endsAt-workspace:GetServerTimeNow())) end
  task.wait(.2)
 end
end)

-- Finished quests -------------------------------------------------------------------------------------------------------
local pill=Instance.new("Frame");pill.Name="QuestReady";pill.AnchorPoint=Vector2.new(1,1);pill.Position=UDim2.new(1,0,0,-8);pill.Size=UDim2.fromOffset(330,58)
pill.BackgroundColor3=Color3.fromRGB(255,190,40);pill.Visible=false;pill.Parent=clock;round(pill,16)
local pillStroke=Instance.new("UIStroke");pillStroke.Color=Color3.fromRGB(120,70,0);pillStroke.Thickness=3;pillStroke.Parent=pill
local pillScale=Instance.new("UIScale");pillScale.Parent=pill
image(pill,"quests",UDim2.fromOffset(46,46),UDim2.fromOffset(6,6))
local pillText=text(pill,UDim2.new(1,-62,1,-6),UDim2.fromOffset(56,3),16);pillText.TextXAlignment=Enum.TextXAlignment.Left
local marker
local function boardMarker(on)
 local world=workspace:FindFirstChild("DigAZombie");local zones=world and world:FindFirstChild("MenuZones");local board=zones and zones:FindFirstChild("quests")
 if not on or not board then if marker then marker:Destroy();marker=nil end;return end
 if marker and marker.Parent then return end
 marker=Instance.new("BillboardGui");marker.Name="QuestMarker";marker.Adornee=board;marker.Size=UDim2.fromOffset(150,96);marker.StudsOffsetWorldSpace=Vector3.new(0,11,0);marker.AlwaysOnTop=true;marker.LightInfluence=0;marker.MaxDistance=1500;marker.ResetOnSpawn=false;marker.Parent=p.PlayerGui
 local dot=Instance.new("TextLabel");dot.AnchorPoint=Vector2.new(.5,0);dot.Position=UDim2.fromScale(.5,0);dot.Size=UDim2.fromOffset(58,58);dot.BackgroundColor3=Color3.fromRGB(255,190,40);dot.Text="!";dot.Font=Enum.Font.GothamBlack;dot.TextSize=44;dot.TextColor3=INK;dot.AutoLocalize=false;dot.Parent=marker;round(dot,29)
 local st=Instance.new("UIStroke");st.Color=Color3.fromRGB(120,70,0);st.Thickness=3;st.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;st.Parent=dot
 local caption=text(marker,UDim2.new(1,0,0,32),UDim2.fromOffset(0,62),20,Color3.fromRGB(255,226,110));caption.Text=t("quests")
 Tween:Create(dot,TweenInfo.new(.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Position=UDim2.new(.5,0,0,8)}):Play()
end
local claimable=0
local function questState(n,fresh)
 claimable=n
 pill.Visible=false -- no quest pill bottom right any more (owner, 2026-11-14); the "!" over the board stays
 pillText.Text=t("questReady",{n=n})
 boardMarker(n>0)
 if fresh and n>0 then pillScale.Scale=1.25;Tween:Create(pillScale,TweenInfo.new(.35,Enum.EasingStyle.Back),{Scale=1}):Play() end
end
rem:WaitForChild("State").OnClientEvent:Connect(function(s)
 if type(s)=="table" and type(s.quests)=="table" and type(s.quests.items)=="table" then
  local n=QuestRules.Claimable(s.quests);if n~=claimable then questState(n,n>claimable) end
 end
end)
rem:WaitForChild("Notice").OnClientEvent:Connect(function(key)
 if key=="questDone" then questState(math.max(claimable,1),true) end
end)
p:GetAttributeChangedSignal("Language"):Connect(function() questState(claimable,false) end)

-- Newcomer's boost ----------------------------------------------------------------------------------------------------
-- Top right, between the top-right icons and the right-hand column (owner, 2026-11-14).
local boost=Instance.new("Frame");boost.Name="NewbieBoost";boost.AnchorPoint=Vector2.new(1,1);boost.Size=UDim2.fromOffset(290,40)
boost.BackgroundColor3=Color3.fromRGB(90,220,90);boost.Visible=false;boost.Parent=dig;round(boost,14)
local boostScale=Instance.new("UIScale");boostScale.Parent=boost
do local st=Instance.new("UIStroke");st.Color=Color3.fromRGB(25,110,40);st.Thickness=3;st.Parent=boost end
image(boost,"hudZombucks",UDim2.fromOffset(32,32),UDim2.fromOffset(6,4))
local boostText=text(boost,UDim2.new(1,-48,1,-4),UDim2.fromOffset(44,2),17);boostText.TextXAlignment=Enum.TextXAlignment.Left;boostText.TextWrapped=false
task.spawn(function()
 while true do
  local mult=p:GetAttribute("NewbieBoost") or 1;local left=(p:GetAttribute("NewbieBoostEnds") or 0)-workspace:GetServerTimeNow()
  local column=dig:FindFirstChild("RightBox")
  boost.Visible=mult>1 and left>0 and column~=nil and column.Visible
  if boost.Visible then
   local k=column:FindFirstChildOfClass("UIScale");boostScale.Scale=k and k.Scale or 1
   local corner=column.AbsolutePosition+Vector2.new(column.AbsoluteSize.X,0)-dig.AbsolutePosition
   boost.Position=UDim2.fromOffset(corner.X,corner.Y-14*boostScale.Scale)
   boostText.Text=t("newbieBoost",{n=mult,time=string.format("%d:%02d",math.floor(left/60),math.floor(left%60))})
  end
  task.wait(.5)
 end
end)

-- Empty farms -----------------------------------------------------------------------------------------------------------
PromptService.PromptShown:Connect(function(pr)
 if pr.Name=="InviteFriend" then pr.AutoLocalize=false;pr.ActionText=t("inviteFriend");pr.ObjectText=t("emptyFarm") end
end)
local inviting=false
PromptService.PromptTriggered:Connect(function(pr,who)
 if pr.Name~="InviteFriend" or who~=p or inviting then return end
 inviting=true
 local ok,can=pcall(function() return SocialService:CanSendGameInviteAsync(p) end)
 local shown=ok and can and pcall(function() SocialService:PromptGameInvite(p) end)
 if not shown then require(S:WaitForChild("Notifications")).Show(t("inviteUnavailable"),"error",3,"inviteUnavailable") end
 task.delay(1,function() inviting=false end)
end)
