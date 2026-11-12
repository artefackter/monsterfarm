-- Farm income no longer drops straight into the wallet: it piles up on the farm as a heap of zombucks that grows
-- with every second, and the owner takes it by walking into the heap (owner, 2026-11-10). The heap is the same
-- money as before, just not yet in the pocket: it is saved with the profile and nobody else can take it.
local RS=game.ReplicatedStorage;local S=RS.Shared
local D=require(script.Parent.DataService);local P=require(script.Parent.PlotService);local Z=require(script.Parent.ZombieService)
local PC=require(S.Config.PlacementConfig)
local B={Piles={}}
local GREEN=Color3.fromRGB(40,188,70);local BILL=Color3.fromRGB(160,245,165);local BAND=Color3.fromRGB(248,252,244)
local UNIT=3 -- radius of the heap at scale 1
local GROUND=-.5 -- the grass, in farm-local studs

local function part(m,name,size,cf,color)
 local q=Instance.new("Part");q.Name=name;q.Size=size;q.CFrame=cf;q.Color=color;q.Material=Enum.Material.SmoothPlastic
 q.Anchored=true;q.CanCollide=false;q.CanQuery=false;q.CanTouch=false;q.CastShadow=false
 q.TopSurface=Enum.SurfaceType.Smooth;q.BottomSurface=Enum.SurfaceType.Smooth;q.Parent=m;return q
end
-- How big the heap is: it grows fast at first and keeps growing, slower, for hours of uncollected income.
function B.Radius(amount,rate)
 if amount<1 then return 1 end
 local seconds=amount/math.max(rate,1)
 return 1.4+4.6*math.clamp(math.log10(1+seconds)/math.log10(1+1800),0,1.3)
end
local function build(p,plot)
 local m=Instance.new("Model");m.Name="MoneyPile";m:SetAttribute("Owner",p.UserId);m:SetAttribute("Amount",0)
 local base=plot.Base*CFrame.new(PC.Bank.X,GROUND,PC.Bank.Z)
 local dome=part(m,"Heap",Vector3.one*UNIT*2,base,GREEN);dome.Shape=Enum.PartType.Ball;m.PrimaryPart=dome
 local rng=Random.new(p.UserId%100000+7)
 -- The heap is covered in bundles of banknotes (some banded, some printed with "$") and a few gold coins.
 for i=1,40 do
  local yaw=rng:NextNumber(0,math.pi*2);local tilt=math.acos(rng:NextNumber(.12,1)) -- spread evenly over the dome
  local cf=base*CFrame.Angles(0,yaw,0)*CFrame.Angles(tilt,0,0)*CFrame.new(0,UNIT+.05,0)*CFrame.Angles(0,rng:NextNumber(0,math.pi),0)
  local bill=part(m,"Bill",Vector3.new(1.5,.2,.78),cf,i%3==0 and BILL or BILL:Lerp(GREEN,.45))
  if i%3==0 then part(m,"Band",Vector3.new(.34,.22,.8),cf,BAND)
  elseif i%3==1 then
   local g=Instance.new("SurfaceGui");g.Face=Enum.NormalId.Top;g.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;g.PixelsPerStud=40;g.LightInfluence=1;g.Parent=bill
   local l=Instance.new("TextLabel");l.BackgroundTransparency=1;l.Size=UDim2.fromScale(1,1);l.Text="$";l.Font=Enum.Font.GothamBlack;l.TextScaled=true;l.TextColor3=Color3.fromRGB(240,255,240);l.Parent=g
  end
 end
 for i=1,7 do
  local yaw=rng:NextNumber(0,math.pi*2);local tilt=math.acos(rng:NextNumber(.2,.95))
  local cf=base*CFrame.Angles(0,yaw,0)*CFrame.Angles(tilt,0,0)*CFrame.new(0,UNIT+.12,0)*CFrame.Angles(0,0,math.pi/2)
  local coin=part(m,"Coin",Vector3.new(.22,.9,.9),cf,Color3.fromRGB(255,206,64));coin.Shape=Enum.PartType.Cylinder
 end
 m.Parent=plot.Model
 return {model=m,plot=plot,scale=1,center=base.Position}
end
local function show(p,d,pile)
 local amount=math.floor(d.farmBank or 0)
 local radius=B.Radius(amount,Z.Income(d,true))
 local scale=radius/UNIT
 if math.abs(scale-pile.scale)>pile.scale*.02 then pile.scale=scale;pile.model:ScaleTo(scale) end
 pile.radius=radius
 if pile.model:GetAttribute("Amount")~=amount then pile.model:SetAttribute("Amount",amount) end
 pile.model:SetAttribute("Radius",radius)
 if p:GetAttribute("FarmBank")~=amount then p:SetAttribute("FarmBank",amount) end
end
function B.Join(p,d)
 local plot=P.Assigned[p];if not plot or B.Piles[p] then return end
 d.farmBank=type(d.farmBank)=="number" and d.farmBank==d.farmBank and math.max(0,d.farmBank) or 0
 B.Piles[p]=build(p,plot);show(p,d,B.Piles[p])
end
function B.Forget(p)
 local pile=B.Piles[p];B.Piles[p]=nil
 if pile then pile.model:Destroy() end
end
-- Called once a second with the income the farm just made.
function B.Add(p,d,amount)
 d.farmBank=(d.farmBank or 0)+amount
 local pile=B.Piles[p];if pile then show(p,d,pile) end
 -- tell the client about the newcomer's boost (HelpController shows it by the clock)
 local mult,left=require(script.Parent.IncomeService).Boost(d)
 if p:GetAttribute("NewbieBoost")~=mult then p:SetAttribute("NewbieBoost",mult) end
 local ends=mult>1 and workspace:GetServerTimeNow()+left or 0
 if math.abs((p:GetAttribute("NewbieBoostEnds") or 0)-ends)>3 then p:SetAttribute("NewbieBoostEnds",ends) end
end
function B.Collect(p)
 local d=D.Profiles[p];local pile=B.Piles[p]
 if not d or not pile then return 0 end
 local amount=math.floor(d.farmBank or 0);if amount<1 then return 0 end
 d.farmBank-=amount;d.coins+=amount;show(p,d,pile)
 local ui=require(script.Parent.InterfaceService);if ui.Push then ui.Refresh(p);ui.Push(p) end
 local rem=RS.Remotes
 local e=rem:FindFirstChild("EconomyFX");if e then e:FireClient(p,amount,"FarmCollect",pile.center) end
 local fx=rem:FindFirstChild("MutantFX");if fx then fx:FireClient(p,"Reward","bank",pile.center+Vector3.new(0,2,0),p.UserId,amount) end
 return amount
end
function B.Init()
 game.Players.PlayerRemoving:Connect(B.Forget)
 task.spawn(function()
  while task.wait(.2) do
   for p,pile in pairs(B.Piles) do
    local d=D.Profiles[p];local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart");local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
    if d and root and h and h.Health>0 and (d.farmBank or 0)>=1 then
     local flat=Vector3.new(root.Position.X,pile.center.Y,root.Position.Z)
     if (flat-pile.center).Magnitude<=(pile.radius or 1)+2 and math.abs(root.Position.Y-pile.center.Y)<12 then B.Collect(p) end
    end
   end
  end
 end)
end
return B
