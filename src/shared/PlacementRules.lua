-- Graves can be placed freely within the cemetery, clear of the crypt. Every placed monster earns income anywhere in the yard.
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
 -- Turned buildings: the house across the corner (the crypt left the yard for the cemetery on 2026-11-14)
 for _,box in C.Rotated or {} do
  local yaw=math.rad(box.Yaw or 0)
  local dx,dz=point.x-box.X,point.z-box.Z
  local x=math.cos(yaw)*dx-math.sin(yaw)*dz
  local z=math.sin(yaw)*dx+math.cos(yaw)*dz
  local nearX=math.max(math.abs(x)-box.HalfX,0)
  local nearZ=math.max(math.abs(z)-box.HalfZ,0)
  if nearX*nearX+nearZ*nearZ<=radius*radius then return false end
 end
	return true
end

local function overlaps(b,p,r)
 return p.x+r>b.MinX and p.x-r<b.MaxX and p.z+r>b.MinZ and p.z-r<b.MaxZ
end
-- Inside the round cemetery's wall, off the crypt and the walk up to its steps (PlacementConfig, 2026-11-14).
function R.InCemetery(p,r)
 local c=C.Cemetery;local dx,dz=p.x-c.X,p.z-c.Z
 if math.sqrt(dx*dx+dz*dz)+r>c.Radius-c.Wall then return false end
 return not overlaps(C.Crypt.Keep,p,r) and not overlaps(C.Walk,p,r)
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

-- nil when the spot is fine, otherwise a reason key for the player. Monsters may stand in one another (owner,
-- 2026-11-14: finding a free spot was too hard; they have no collisions either); `spaced` keeps them apart, for
-- automatic placement (FindFree).
function R.Check(d, kind, point, object, spaced)
	if not point or not number(point.x) or not number(point.z) then
		return "placeBad"
	end
	local radius = R.Radius(kind,object)
 if kind=="Grave" then -- graves: only in the cemetery yard beside the farm (2026-11-14)
  if not R.InCemetery(point,radius) then return "placeCemetery" end
 elseif not R.InYard(point, radius) then return "placeOutside" end
	for _, other in R.Occupied(d, object and object.id) do
		if kind ~= "Grave" and other[3] == "Zombie" and not spaced then
			continue
		end
		local dx, dz = point.x - other[1].x, point.z - other[1].z
		if math.sqrt(dx * dx + dz * dz) < (radius + other[2]) * C.Overlap then
			return "placeCrowded"
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
 if d.farmLayoutVersion==47 then return d end
 -- 46 (2026-11-14): the cemetery moved out to its own yard beside the farm; 47 (the same day): it turned round, with
 -- the crypt in its middle. Graves that no longer fit move to a free spot in it.
 if d.farmLayoutVersion==45 or d.farmLayoutVersion==46 then
  for _,g in d.graves or {} do if not g.pos or R.Check(d,"Grave",g.pos,g) then g.pos=nil end end
  for _,g in d.graves or {} do if not g.pos then g.pos=R.FindFree(d,"Grave",g) end end
  d.farmLayoutVersion=47;return d
 end
 local graves=d.graves or {};local zombies=d.zombies or {}
 if d.farmLayoutVersion~=43 and d.farmLayoutVersion~=44 then
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
 d.farmLayoutVersion=47
 return d
end

-- A free spot near the front of the yard, for migration and for things the server places itself.
function R.FindFree(d,kind,object)
 if kind=="Grave" then
  local c=C.Cemetery;local reach=c.Radius-c.Wall-C.GraveRadius
  for z=c.Z-reach,c.Z+reach,1 do for x=c.X-reach,c.X+reach,1 do
   local p={x=x,z=z};if not R.Check(d,"Grave",p,object) then return p end
  end end
  return nil
 end
 local y=C.Yard
 for z=y.MinZ+2,y.MaxZ-2,4.4 do for x=y.MinX+2,y.MaxX-2,4.4 do
  local p=R.Point(x,z)
  if not R.Check(d,"Zombie",p,object,true) then return p end
 end end
end
return R
