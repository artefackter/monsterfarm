-- Visual-only garden surfaces; gameplay colliders and placement bounds stay in PlotService.
local Garden = {}
Garden.GrassImage = "rbxassetid://132213762657371"
function Garden.ApplyGrass(part)
 part.Color = Color3.new(1,1,1)
 local texture = Instance.new("Texture")
 texture.Name = "GardenLawnTexture"
 texture.Texture = Garden.GrassImage
 -- Cylinders use their local X axis; PlotService turns +X upward.
 texture.Face = Enum.NormalId.Right
 texture.StudsPerTileU, texture.StudsPerTileV = 16, 16
 texture.Parent = part
 return part
end
function Garden.Lawn(parent, radius, top)
 local part = Instance.new("Part")
 part.Name = "GardenGrassSurface"
 part.Shape = Enum.PartType.Cylinder
 part.Size = Vector3.new(.04, radius*2, radius*2)
 part.CFrame = CFrame.new(0,top-.02,0)*CFrame.Angles(0,0,math.pi/2)
 part.Anchored = true
 part.CanCollide, part.CanTouch, part.CanQuery, part.CastShadow = false,false,false,false
 part.Material = Enum.Material.SmoothPlastic
 Garden.ApplyGrass(part)
 part.Parent = parent
 return part
end
function Garden.Promenade(Art, parent, top)
 for row=0,3 do
  local radius=26.45+row*4.1
  local count=math.ceil(2*math.pi*radius/4)
  local width=2*math.pi*radius/count*.98
  for i=0,count-1 do
   local angle=(i+row*.5)*2*math.pi/count
   local pos=Vector3.new(math.sin(angle)*radius,top+.05,math.cos(angle)*radius)
   local parts=Art.Spawn("ENV_Tile"..(1+(i+row)%3),parent,CFrame.lookAt(pos,Vector3.new(0,pos.Y,0)),{
    scale=Vector3.new(width/3.8,.55,4/3.8),prefix="Promenade_"})
   for _,part in parts do part.CastShadow=false end
  end
 end
end
return Garden
