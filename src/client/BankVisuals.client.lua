-- The zombucks heap on every farm (server: BankService). Shows how much lies in it, pops a green "+$N" each time
-- the farm earns, and marks the local player's own heap with a house icon that is visible from anywhere,
-- so home is easy to find and it is clear where the money waits.
local Players=game:GetService("Players");local Tween=game:GetService("TweenService");local Debris=game:GetService("Debris")
local p=Players.LocalPlayer;local S=game.ReplicatedStorage:WaitForChild("Shared")
local L=require(S:WaitForChild("Locale"));local Icons=require(S:WaitForChild("Icons"))
local GREEN=Color3.fromRGB(96,255,84);local INK=Color3.fromRGB(10,40,14)
local piles={}
local function money(n) return "$"..L.compact(n,L.lang()) end
local function outlined(label,size,color)
 label.BackgroundTransparency=1;label.Font=Enum.Font.GothamBlack;label.TextSize=size;label.TextColor3=color;label.AutoLocalize=false
 local st=Instance.new("UIStroke");st.Color=INK;st.Thickness=3;st.LineJoinMode=Enum.LineJoinMode.Round;st.Parent=label
 return st
end
local function pop(pile,amount)
 local heap=pile.heap;if not heap.Parent then return end
 if (heap.Position-workspace.CurrentCamera.CFrame.Position).Magnitude>140 then return end
 local radius=pile.model:GetAttribute("Radius") or 2
 local angle=math.random()*math.pi*2
 local from=heap.Position+Vector3.new(math.cos(angle)*radius*.8,radius*(.25+math.random()*.5),math.sin(angle)*radius*.8)
 local q=Instance.new("Part");q.Name="BankGain";q.Size=Vector3.one*.1;q.Transparency=1;q.Anchored=true;q.CanCollide=false;q.CanQuery=false;q.CanTouch=false;q.Position=from;q.Parent=workspace
 local b=Instance.new("BillboardGui");b.Size=UDim2.fromOffset(180,40);b.LightInfluence=0;b.MaxDistance=140;b.Parent=q
 local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.Text="+"..money(amount);t.Parent=b
 local st=outlined(t,30,GREEN)
 Tween:Create(q,TweenInfo.new(1.1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=from+Vector3.new(0,2.6,0)}):Play()
 task.delay(.6,function() if t.Parent then Tween:Create(t,TweenInfo.new(.5),{TextTransparency=1}):Play();Tween:Create(st,TweenInfo.new(.5),{Transparency=1}):Play() end end)
 Debris:AddItem(q,1.15)
end
local function add(m)
 if not m:IsA("Model") or m.Name~="MoneyPile" or piles[m] then return end
 local heap=m:WaitForChild("Heap",5);if not heap then return end
 local pile={model=m,heap=heap,amount=m:GetAttribute("Amount") or 0}
 piles[m]=pile
 local mine=m:GetAttribute("Owner")==p.UserId
 -- the sum, above the heap
 local b=Instance.new("BillboardGui");b.Name="BankAmount";b.Adornee=heap;b.Size=UDim2.fromOffset(240,44);b.LightInfluence=0;b.MaxDistance=120;b.ResetOnSpawn=false;b.Parent=p:WaitForChild("PlayerGui")
 local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.Parent=b;outlined(t,34,GREEN)
 pile.gui=b;pile.text=t
 if mine then
  -- the house: drawn over everything, right on the heap, from any distance
  local h=Instance.new("BillboardGui");h.Name="HomeIcon";h.Adornee=heap;h.Size=UDim2.fromOffset(58,58);h.AlwaysOnTop=true;h.LightInfluence=0;h.MaxDistance=2000;h.ResetOnSpawn=false;h.Parent=p.PlayerGui
  local img=Instance.new("ImageLabel");img.BackgroundTransparency=1;img.Size=UDim2.fromScale(1,1);img.Image=Icons.house or "";img.Parent=h
  pile.home=h
 end
 local function refresh()
  local amount=m:GetAttribute("Amount") or 0;local radius=m:GetAttribute("Radius") or 1
  t.Text=money(amount);b.Enabled=amount>=1 -- online income goes to the wallet: only offline earnings wait here
  b.StudsOffsetWorldSpace=Vector3.new(0,radius+1.4,0)
  if pile.home then pile.home.StudsOffsetWorldSpace=Vector3.new(0,radius*.45,0) end
  if amount>pile.amount then pop(pile,amount-pile.amount) end
  pile.amount=amount
 end
 m:GetAttributeChangedSignal("Amount"):Connect(refresh);m:GetAttributeChangedSignal("Radius"):Connect(refresh);refresh()
 m.Destroying:Connect(function() piles[m]=nil;b:Destroy();if pile.home then pile.home:Destroy() end end)
end
workspace.DescendantAdded:Connect(function(m) task.spawn(add,m) end)
for _,m in workspace:GetDescendants() do task.spawn(add,m) end
