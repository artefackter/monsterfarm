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

-- Night card ------------------------------------------------------------------------------------------------------------
local card=Instance.new("Frame");card.Name="NightCard";card.AnchorPoint=Vector2.new(.5,0);card.Position=UDim2.new(.5,0,0,86);card.Size=UDim2.fromOffset(760,214)
card.BackgroundColor3=Color3.fromRGB(34,28,74);card.BackgroundTransparency=.06;card.Visible=false;card.Parent=gui;round(card,20)
local cardStroke=Instance.new("UIStroke");cardStroke.Color=Color3.fromRGB(150,130,255);cardStroke.Thickness=4;cardStroke.Parent=card
local cardScale=Instance.new("UIScale");cardScale.Parent=card
image(card,"moon",UDim2.fromOffset(46,46),UDim2.fromOffset(16,8))
local title=text(card,UDim2.new(1,-140,0,46),UDim2.fromOffset(70,8),30,Color3.fromRGB(255,226,110));title.TextXAlignment=Enum.TextXAlignment.Left;title.TextWrapped=false
local close=Instance.new("TextButton");close.Name="Close";close.AnchorPoint=Vector2.new(1,0);close.Position=UDim2.new(1,-10,0,10);close.Size=UDim2.fromOffset(44,44);close.BackgroundColor3=Color3.fromRGB(255,84,104);close.Text="X";close.Font=Enum.Font.GothamBlack;close.TextSize=26;close.TextColor3=Color3.new(1,1,1);close.AutoLocalize=false;close.Parent=card;round(close,12)
local tiles={}
for i,spec in ipairs({{icon="pistol",key="nightCard1",color=Color3.fromRGB(255,110,110)},{icon="lock",key="nightCard2",color=Color3.fromRGB(120,190,255)},{icon="star",key="nightCard3",color=Color3.fromRGB(190,140,255)}}) do
 local tile=Instance.new("Frame");tile.Size=UDim2.fromOffset(236,142);tile.Position=UDim2.fromOffset(14+(i-1)*248,60);tile.BackgroundColor3=Color3.fromRGB(20,16,48);tile.Parent=card;round(tile,14)
 local st=Instance.new("UIStroke");st.Color=spec.color;st.Thickness=3;st.Parent=tile
 image(tile,spec.icon,UDim2.fromOffset(54,54),UDim2.fromOffset(91,6))
 local l=text(tile,UDim2.new(1,-14,0,76),UDim2.fromOffset(7,62),17);l.TextYAlignment=Enum.TextYAlignment.Top
 tiles[i]={label=l,key=spec.key}
end
local shownAt=0
local function fit()
 local v=gui.AbsoluteSize;cardScale.Scale=math.clamp(math.min(v.X/900,v.Y/520),.5,1.1)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit);fit()
local function hideCard() card.Visible=false end
local function showCard(seconds)
 title.Text=t(workspace:GetAttribute("IsNight") and "nightCardTitle" or "nightCardDay")
 for _,tile in tiles do tile.label.Text=t(tile.key) end
 card.Visible=true;local base=cardScale.Scale;fit();base=cardScale.Scale;cardScale.Scale=base*.85
 Tween:Create(cardScale,TweenInfo.new(.2,Enum.EasingStyle.Back),{Scale=base}):Play()
 shownAt=os.clock();local mine=shownAt
 if seconds then task.delay(seconds,function() if shownAt==mine then hideCard() end end) end
end
close.Activated:Connect(hideCard)
-- the day clock is the "what is this?" button; a small "?" on it says so
local ask=Instance.new("TextButton");ask.Name="NightHelp";ask.BackgroundTransparency=1;ask.Size=UDim2.fromScale(1,1);ask.Text="";ask.ZIndex=5;ask.Parent=clock
local badge=Instance.new("TextLabel");badge.Name="Hint";badge.Size=UDim2.fromOffset(24,24);badge.Position=UDim2.fromOffset(44,-4);badge.BackgroundColor3=Color3.fromRGB(255,196,64);badge.Text="?";badge.Font=Enum.Font.GothamBlack;badge.TextSize=18;badge.TextColor3=INK;badge.ZIndex=6;badge.AutoLocalize=false;badge.Parent=clock;round(badge,12)
ask.Activated:Connect(function() if card.Visible then hideCard() else showCard(nil) end end)
local nights=0
workspace:GetAttributeChangedSignal("IsNight"):Connect(function()
 if workspace:GetAttribute("IsNight") then
  nights+=1
  -- the first nights explain themselves at length; later ones only flash the reminder
  if dig:GetAttribute("ModalOpen")~=true then showCard(nights<=3 and 10 or 4) end
 elseif card.Visible then hideCard() end
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
 pill.Visible=n>0
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
local boost=Instance.new("Frame");boost.Name="NewbieBoost";boost.AnchorPoint=Vector2.new(1,1);boost.Size=UDim2.fromOffset(330,40)
boost.BackgroundColor3=Color3.fromRGB(90,220,90);boost.Visible=false;boost.Parent=clock;round(boost,14)
do local st=Instance.new("UIStroke");st.Color=Color3.fromRGB(25,110,40);st.Thickness=3;st.Parent=boost end
image(boost,"hudZombucks",UDim2.fromOffset(32,32),UDim2.fromOffset(6,4))
local boostText=text(boost,UDim2.new(1,-48,1,-4),UDim2.fromOffset(44,2),17);boostText.TextXAlignment=Enum.TextXAlignment.Left;boostText.TextWrapped=false
task.spawn(function()
 while true do
  local mult=p:GetAttribute("NewbieBoost") or 1;local left=(p:GetAttribute("NewbieBoostEnds") or 0)-workspace:GetServerTimeNow()
  boost.Visible=mult>1 and left>0
  if boost.Visible then
   boost.Position=UDim2.new(1,0,0,pill.Visible and -74 or -8)
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
