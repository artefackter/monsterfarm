local Run=game:GetService('RunService');local Lighting=game:GetService('Lighting')
local S=game.ReplicatedStorage:WaitForChild('Shared');local C=require(S.Config.RoadConfig);local districts=require(S.Config.WorldConfig).Districts
local L=require(S.Locale);local Notices=require(S.Notifications);local Progression=require(S.Config.RoadProgression)
local pending,enteredAt,announced
local function announce(d)
 local lang=L.lang()
 local title=d.Emoji.." "..L.text(d.Title,lang)
 Notices.Location(title,L.text("locationSpeed",lang,{speed=L.compact(d.RecommendedSpeed,lang)}))
end
game.Players.LocalPlayer:GetAttributeChangedSignal('Language'):Connect(function()
 if announced then announce(announced) end
end)
local tint=Instance.new('ColorCorrectionEffect');tint.Name='RoadDistrictTint';tint.Parent=Lighting
local base=CFrame.lookAt(C.Dir.Unit*C.Rim,C.Dir.Unit*(C.Rim+1));local current
-- Atmosphere is managed by DayNightService. Small local fog particles give each
-- district its own haze without overwriting the replicated day/night settings.
local holder=Instance.new('Part');holder.Name='LocalDistrictMist';holder.Size=Vector3.new(75,10,75);holder.Anchored=true;holder.Transparency=1;holder.CanCollide=false;holder.CanQuery=false;holder.CanTouch=false;holder.Parent=workspace
local mist=Instance.new('ParticleEmitter');mist.Name='Mist';mist.Texture='rbxasset://textures/particles/smoke_main.dds';mist.Rate=0;mist.Lifetime=NumberRange.new(4,6);mist.Speed=NumberRange.new(.4,1);mist.SpreadAngle=Vector2.new(180,180);mist.Size=NumberSequence.new(12,18);mist.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.3,.97),NumberSequenceKeypoint.new(1,1)});mist.LightEmission=.25;mist.Parent=holder
Run.Heartbeat:Connect(function(dt)
 local root=game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
 local v=root and base:PointToObjectSpace(root.Position);local selected
 if v and math.abs(v.X)<C.Width/2 and -v.Z>=0 and -v.Z<=C.Length then for _,d in districts do if -v.Z>=d.From and -v.Z<d.To then selected=d;break end end end
 -- a boss arena (and its corridor) belongs to its location: stepping back out is not a new arrival (2026-11-14)
 if v and not selected then local i=Progression.PocketAt(-v.Z,v.X,4);if i then selected=districts[i] end end
 local goal=selected and Color3.new(1,1,1):Lerp(Color3.fromHex(selected.Fog),.18) or Color3.new(1,1,1)
 tint.TintColor=tint.TintColor:Lerp(goal,1-math.exp(-dt*2));tint.Saturation=selected and .06 or 0
 -- off the road the tint is plain white: switch the pass off (2026-11-15, performance) once it has faded out
 tint.Enabled=selected~=nil or (Vector3.new(tint.TintColor.R,tint.TintColor.G,tint.TintColor.B)-Vector3.one).Magnitude>.01
 if selected~=current then current=selected;mist.Rate=selected and selected.Density*40 or 0;if selected then mist.Color=ColorSequence.new(Color3.fromHex(selected.Fog)) else mist:Clear() end end
 -- Announce only once after crossing into a zone; a brief dwell avoids boundary flicker.
 if selected~=pending then pending=selected;enteredAt=os.clock() end
 if not selected then
  if announced then Notices.ClearLocation();announced=nil end
 elseif selected~=announced and os.clock()-enteredAt>=.18 then
  announced=selected;announce(selected)
 end
 if root then holder.Position=root.Position+Vector3.new(0,2,-8) end
end)
