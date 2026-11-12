-- Compact procedural props: a wooden bat with grip tape and a readable, blunt trap.
local Tween=game:GetService("TweenService")
local M={}
local function part(parent,name,size,cf,color,shape)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cf;p.Color=Color3.fromHex(color);p.Material=Enum.Material.SmoothPlastic
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Massless=true
 if shape then p.Shape=shape end;p.Parent=parent;return p
end
function M.Swing(player)
 local ch=player.Character;local hand=ch and (ch:FindFirstChild("RightHand") or ch:FindFirstChild("Right Arm"));if not hand then return end
 local m=Instance.new("Model");m.Name="RoadBat"
 local handle=part(m,"Handle",Vector3.new(.32,1.3,.32),CFrame.new(),"593E35")
 part(m,"Barrel",Vector3.new(.8,2.5,.8),CFrame.new(0,1.7,0),"CB9555",Enum.PartType.Cylinder).CFrame=CFrame.new(0,1.7,0)*CFrame.Angles(0,0,math.pi/2)
 -- Cylinders run along X: size uses X for barrel length.
 m.Barrel.Size=Vector3.new(2.5,.8,.8)
 part(m,"Tip",Vector3.one*.8,CFrame.new(0,2.95,0),"DFB773",Enum.PartType.Ball)
 for i=0,4 do part(m,"GripTape",Vector3.new(.37,.09,.37),CFrame.new(0,-.45+i*.2,0),"E4DDD2") end
 for _,p in ipairs(m:GetChildren()) do if p~=handle then local w=Instance.new("WeldConstraint");w.Part0=handle;w.Part1=p;w.Parent=p end;p.Anchored=false end
 local weld=Instance.new("Weld");weld.Part0=hand;weld.Part1=handle;weld.C0=CFrame.new(0,-.4,-.3)*CFrame.Angles(math.rad(-55),0,math.rad(65));weld.Parent=handle
 m.Parent=ch
 Tween:Create(weld,TweenInfo.new(.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{C0=CFrame.new(0,-.4,-.8)*CFrame.Angles(math.rad(-100),0,math.rad(-70))}):Play()
 game.Debris:AddItem(m,.42)
end
function M.Trap(parent,cf)
 local m=Instance.new('Model');m.Name='RoadTrap'
 local parts=require(script.Parent.ArtKit).Spawn('V3_Trap',m,cf)
 parts.JawL.Name='Jaw1';parts.JawR.Name='Jaw-1'
 m.PrimaryPart=parts.Base;m:SetAttribute('Origin',cf);m:SetAttribute('ArtAsset','V3_Trap');m.Parent=parent;return m
end
function M.ArmTrap(m) m.Light.Color=Color3.fromHex("FF655B") end
function M.CloseTrap(m)
 local origin=m:GetAttribute('Origin')
 for _,side in {-1,1} do
  local jaw=m:FindFirstChild('Jaw'..side)
  if jaw then local goal=origin*CFrame.new(side*.3,1.3,0)*CFrame.Angles(0,0,-side*.8)*require(script.Parent.ArtKit).ImportRotation;Tween:Create(jaw,TweenInfo.new(.12),{CFrame=goal}):Play() end
 end
 m.Light.Color=Color3.fromHex('FFFFFF')
end
return M
