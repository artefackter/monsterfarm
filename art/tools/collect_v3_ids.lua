-- Read-only: run in Studio Edit after the owner's manual import, via execute_luau.
local root=workspace:FindFirstChild('GrowAZombie_WorldV3') or game.ServerStorage:FindFirstChild('ArtImportBackups') and game.ServerStorage.ArtImportBackups:FindFirstChild('GrowAZombie_WorldV3')
assert(root,'Import GrowAZombie_WorldV3.glb into Workspace first')
local ids={};local duplicates={};local missingIds={}
for _,part in root:GetDescendants() do
 if part:IsA('MeshPart') and part.Name:match('^V3_') then
  local asset,component=part.Name:gsub('__','.'):match('^(V3_.+)%.(.+)$')
  if asset then
   local key=asset..'.'..component
   local id=tonumber(part.MeshId:match('%d+'))
   if ids[key] then table.insert(duplicates,key) end
   if not id or id<=0 then table.insert(missingIds,key) else ids[key]=id end
  end
 end
end
assert(#duplicates==0,'Duplicate import names: '..table.concat(duplicates,', '))
assert(#missingIds==0,'Meshes not uploaded: '..table.concat(missingIds,', '))
local count=0;for _ in ids do count+=1 end
assert(count==157,'Expected 157 meshes; found '..count)
return game.HttpService:JSONEncode(ids)
