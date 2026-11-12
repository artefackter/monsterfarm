local S=game.ReplicatedStorage.Shared;local G=require(S.Config.GraveConfig);local C=require(S.Config.ShopConfig)
local Shop={}
function Shop.Stock(d,night)
 local n=math.floor(workspace:GetServerTimeNow()/C.Refresh);local rng=Random.new(n);local stock={}
 for _,name in ipairs(G.ShopOrder) do local c=G[name];local exists=rng:NextNumber()<c.Chance;local amount=rng:NextInteger(c.Min,c.Max);stock[name]=(exists and (not c.NightOnly or night)) and amount or 0 end
 if d.shopRotation~=n then d.shopRotation=n;d.shopUsed={} end
 for name,n in pairs(stock) do stock[name]=name=="Wooden" and 999 or math.max(0,n-(d.shopUsed[name] or 0)) end
 return stock,C.Refresh-workspace:GetServerTimeNow()%C.Refresh
end
return Shop
