-- Shared collection/reveal portrait. Presentation never depends on the open menu.
local Icons=require(script.Parent.Icons)
local Art=require(script.Parent.ArtKit)
local Merge=require(script.Parent.MergeRules)
local P={}
local cache={}
function P.Create(parent,z,size,pos,options)
 options=options or {};local silhouette=options.silhouette
 local texture=require(script.Parent.MonsterCollection).Icon(z.type,Icons)
 if texture and not silhouette and not options.prefer3D then
  local image=Instance.new("ImageLabel");image.Name="MonsterIllustration";image.BackgroundTransparency=1;image.Image=texture;image.ScaleType=Enum.ScaleType.Fit;image.Size=size;image.Position=pos or UDim2.new();image.Parent=parent
  return image
 end
	local v = Instance.new("ViewportFrame")
	v.Size = size
	v.Position = pos or UDim2.new()
	v.BackgroundTransparency = 1
	v.Ambient = Color3.fromRGB(190, 190, 205)
	v.LightColor = Color3.fromRGB(255, 250, 235)
	v.LightDirection = Vector3.new(-0.5, -1, 0.6)
	if silhouette then
		v.ImageColor3 = Color3.fromRGB(58, 35, 102)
		v.Ambient = Color3.new(0, 0, 0)
		v.LightColor = Color3.new(0, 0, 0)
	end
	-- One built model per look; each portrait is a clone of it (the dex and the merge window re-render often, and
	-- the rotation's monsters are 3D portraits).
	local key = table.concat({ tostring(z.type), tostring(z.form), tostring(z.tier), tostring(Merge.Stars(z)) }, "|")
	local template = cache[key]
	if not template then
		template = Instance.new("Model")
		template.Name = "Zombie"
		Art.BuildZombie(template, CFrame.new(), z)
		local ring = template:FindFirstChild("Ring")
		if ring then
			ring:Destroy()
		end
		template:ScaleTo(Merge.Size(z))
		cache[key] = template
	end
	local model = template:Clone()
	model.Parent = v
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
 local bounds,size3=model:GetBoundingBox();local target=bounds.Position;local radius=math.max(size3.X,size3.Y,size3.Z)
 camera.CFrame=CFrame.lookAt(target+Vector3.new(0,radius*.08,-radius*2.1),target)
	camera.Parent = v
	v.CurrentCamera = camera
	v.Parent = parent
	return v, model
end
return P
