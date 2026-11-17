-- Graves can be placed freely within the cemetery, clear of the crypt; a monster anywhere on the farm. Nothing gets in
-- anything's way (Check). Every placed monster earns income wherever it stands.
-- Positions are farm-local (x, z) in studs: -z faces the plaza, +z the house. The server checks every
-- placement with these rules; the client uses the same rules to colour the preview.
local C = require(script.Parent.Config.PlacementConfig)
local R = {}

local function number(v)
	return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

function R.Point(x, z)
	if not number(x) or not number(z) then
		return nil
	end
	return { x = math.floor(x / C.Snap + 0.5) * C.Snap, z = math.floor(z / C.Snap + 0.5) * C.Snap }
end

-- How much room something needs around its centre.
function R.Radius(kind,object)
 if kind=="Grave" then return C.GraveRadius end
 local asset=object and require(script.Parent.MonsterCollection).Asset(object.type)
 if asset then
  local Art=require(script.Parent.ArtKit);local scale,lo,hi=Art.MonsterScale(asset)
  return math.max(hi.X-lo.X,hi.Z-lo.Z)*scale*.42*require(script.Parent.MergeRules).Size(object)
 end
 return C.ZombieRadius
end

-- Inside the yard and clear of buildings, the treadmill and the walkway.
function R.InYard(point, radius)
	radius = radius or 0
	local y = C.Yard
	if point.x - radius < y.MinX or point.x + radius > y.MaxX or point.z - radius < y.MinZ or point.z + radius > y.MaxZ then
		return false
	end
	for _, b in C.Blocked do
		if point.x + radius > b.MinX and point.x - radius < b.MaxX and point.z + radius > b.MinZ and point.z - radius < b.MaxZ then
			return false
		end
	end
	-- garden beds (the outer ring since 2026-11-13)
	for _, b in C.Beds or {} do
		if math.abs(point.x - b.X) < b.W / 2 + radius + .3 and math.abs(point.z - b.Z) < b.D / 2 + radius + .3 then
			return false
		end
	end
 -- Turned buildings: the house across the corner
 for _,box in C.Rotated or {} do
  if R.InTurned(box,point,radius) then return false end
 end
 -- the round cemetery over the back corner (2026-11-15)
 local c=C.Cemetery;local dx,dz=point.x-c.X,point.z-c.Z
 if math.sqrt(dx*dx+dz*dz)<c.Radius+radius+.5 then return false end
	return true
end

-- Whether a circle of `radius` at `point` touches a box turned by Yaw degrees ({X, Z, Yaw, HalfX, HalfZ}).
function R.InTurned(box,point,radius)
 local yaw=math.rad(box.Yaw or 0)
 local dx,dz=point.x-box.X,point.z-box.Z
 local x=math.cos(yaw)*dx-math.sin(yaw)*dz
 local z=math.sin(yaw)*dx+math.cos(yaw)*dz
 local nearX=math.max(math.abs(x)-box.HalfX,0)
 local nearZ=math.max(math.abs(z)-box.HalfZ,0)
 return nearX*nearX+nearZ*nearZ<=radius*radius
end
-- Inside the round cemetery's fence, off the crypt and the walk up to its steps (PlacementConfig).
function R.InCemetery(p,r)
 local c=C.Cemetery;local dx,dz=p.x-c.X,p.z-c.Z
 if math.sqrt(dx*dx+dz*dz)+r>c.Radius-c.Wall then return false end
 return not R.InTurned(C.Crypt.Keep,p,r) and not R.InTurned(C.Walk,p,r)
end
function R.Role(point) return "Field" end
function R.GravePoint(x,z)
 if not number(x) or not number(z) then return nil end
 return {x=x,z=z}
end

-- Everything already standing on the farm, as {point, radius}; `skip` is the id being moved.
function R.Occupied(d, skip)
	local list = {}
	for _, g in d.graves or {} do
		if g.pos and (skip == nil or g.id ~= skip) and not g.carriedBy then
			table.insert(list, { g.pos, C.GraveRadius, "Grave" })
		end
	end
	for _, z in d.zombies or {} do
		if (z.zone == "Field" or z.zone == "Guards") and z.pos and (skip == nil or z.id ~= skip) and not z.carriedBy then
			table.insert(list, { z.pos, R.Radius("Zombie",z), "Zombie" })
		end
	end
	return list
end

-- Any point of the farm's yard. Not the cemetery over its corner: that is the graves' ground (owner, 2026-11-15:
-- "graves only in the cemetery, monsters only on the farm").
function R.OnFarm(point)
	local y = C.Yard
	if point.x < y.MinX or point.x > y.MaxX or point.z < y.MinZ or point.z > y.MaxZ then
		return false
	end
	local c = C.Cemetery
	local dx, dz = point.x - c.X, point.z - c.Z
	return math.sqrt(dx * dx + dz * dz) >= c.Radius
end

-- nil when the spot is fine, otherwise a reason key for the player.
-- Nothing collides when you place by hand (owner, 2026-11-15: "a monster must go anywhere at all, a grave too, even
-- into one another - no collision whatever; and where it may go must not depend on the monster's size"): a monster
-- may stand at any point of the farm's yard - in a building, in another monster, but not in the cemetery - and a
-- grave anywhere in the cemetery clear of the crypt and the walk up to it, in another grave if you like. (Monsters kept clear of one
-- another until 2026-11-14, and of the buildings and the yard's edge by their own size until now; graves kept
-- clear of one another.) `spaced` asks for the old room round it as well - the yard's buildings and whatever stands
-- there: what the server places by itself (FindFree) still goes where there is room.
function R.Check(d, kind, point, object, spaced)
	if not point or not number(point.x) or not number(point.z) then
		return "placeBad"
	end
	if kind == "Grave" then -- graves: only in the cemetery (2026-11-14)
		if not R.InCemetery(point, C.GraveRadius) then
			return "placeCemetery"
		end
	elseif not R.OnFarm(point) then
		return "placeOutside"
	end
	if spaced then
		local radius = R.Radius(kind, object)
		if kind ~= "Grave" and not R.InYard(point, radius) then
			return "placeOutside"
		end
		for _, other in R.Occupied(d, object and object.id) do
			local dx, dz = point.x - other[1].x, point.z - other[1].z
			if math.sqrt(dx * dx + dz * dz) < (radius + other[2]) * C.Overlap then
				return "placeCrowded"
			end
		end
	end
	return nil
end

-- The old cell layout, used once to give existing graves and zombies a spot of their own.
function R.Legacy(zone, slot)
	slot = math.max(1, slot or 1)
	if zone == "Field" then
		local cell = C.LegacyField
		return R.Point(cell.X + ((slot - 1) % cell.Columns) * cell.DX, cell.Z + math.floor((slot - 1) / cell.Columns) * cell.DZ)
	end
	local q=C.GraveSpots[math.clamp(slot,1,#C.GraveSpots)]
	return {x=q.x,z=q.z}
end

-- Every planted grave and field zombie gets a spot; ones that no longer fit move to a free one.
function R.Migrate(d)
 if d.farmLayoutVersion==49 then return d end
 -- 46 (2026-11-14): the cemetery moved out to its own yard beside the farm; 47 (the same day): it turned round, with
 -- the crypt in its middle; 48 (2026-11-15): it moved into the farm's back corner and the farm grew to 100 x 100;
 -- 49 (the same day): it sits over that corner, sticking out past the fences. Graves and monsters that no longer fit
 -- move to a free spot.
 local graves=d.graves or {};local zombies=d.zombies or {};local v=d.farmLayoutVersion
 if type(v)=="number" and v>=43 and v<=48 then
  for _,g in graves do if not g.pos or R.Check(d,"Grave",g.pos,g) then g.pos=nil end end
  for _,g in graves do if not g.pos then g.pos=R.FindFree(d,"Grave",g) end end
 else
 for _,g in graves do g.pos=nil end
 for _,z in zombies do z.pos=nil end
 for i,g in graves do local q=C.GraveSpots[i];if q then g.pos={x=q.x,z=q.z} end end
 for _,g in graves do if not g.pos then g.pos=R.FindFree(d,"Grave",g) end end
 for _,z in zombies do
  if z.zone=="Field" then z.pos=R.FindFree(d,"Worker",z)
  elseif z.zone=="Guards" then z.pos=R.FindFree(d,"Defender",z) end
  if (z.zone=="Field" or z.zone=="Guards") and not z.pos then z.zone="Crypt";z.slot=0 end
 end
 end
 for _,z in zombies do
  if (z.zone=="Field" or z.zone=="Guards") and (not z.pos or R.Check(d,"Zombie",z.pos,z)) then
   z.pos=R.FindFree(d,z.zone=="Field" and "Worker" or "Defender",z)
   if not z.pos then z.zone="Crypt";z.slot=0 end
  end
 end
 d.farmLayoutVersion=49
 return d
end

-- A free spot for something the server places itself (the crypt's "Place best", migration).
-- A monster goes as near the middle of the farm as there is room (owner, 2026-11-15: "let it place them nearer the
-- farm's centre"; it was the first free cell of a 4.4-stud grid from the front corner, in rows): the yard's points
-- in rings outward from the middle (every Auto.Step studs), the first that is in the yard and clear of what stands
-- there. When the yard has no such room left the spacing is eased step by step (Auto.Ease, down to none: monsters
-- may stand in one another, as they may when placed by hand), so a monster that fits the yard always gets a spot -
-- "Place best" used to stop at the first one that found none and leave the rest in the crypt.
local rings
local function yardPoints()
 if not rings then
  rings={}
  local y=C.Yard;local step=C.Auto.Step
  for z=y.MinZ+2,y.MaxZ-2,step do for x=y.MinX+2,y.MaxX-2,step do table.insert(rings,R.Point(x,z)) end end
  table.sort(rings,function(a,b)
   local da,db=a.x*a.x+a.z*a.z,b.x*b.x+b.z*b.z
   if da~=db then return da<db end
   if a.z~=b.z then return a.z<b.z end
   return a.x<b.x
  end)
 end
 return rings
end
function R.FindFree(d,kind,object)
 if kind=="Grave" then
  local c=C.Cemetery;local reach=c.Radius-c.Wall-C.GraveRadius
  for z=c.Z-reach,c.Z+reach,1 do for x=c.X-reach,c.X+reach,1 do
   local p={x=x,z=z};if not R.Check(d,"Grave",p,object,true) then return p end
  end end
  return nil
 end
 local radius=R.Radius("Zombie",object);local others=R.Occupied(d,object and object.id)
 local open={} -- where it may stand at all, nearest the middle first
 for _,q in ipairs(yardPoints()) do if R.InYard(q,radius) then table.insert(open,q) end end
 for _,ease in ipairs(C.Auto.Ease) do
  for _,q in ipairs(open) do
   local clear=true
   for _,other in ipairs(others) do
    local dx,dz=q.x-other[1].x,q.z-other[1].z
    if math.sqrt(dx*dx+dz*dz)<(radius+other[2])*C.Overlap*ease then clear=false;break end
   end
   if clear then return {x=q.x,z=q.z} end
  end
 end
 return nil
end
return R
