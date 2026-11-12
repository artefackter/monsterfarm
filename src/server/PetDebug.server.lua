if not game:GetService("RunService"):IsStudio() then return end
local Pet=require(script.Parent.PetService);local D=require(script.Parent.DataService);local C=require(game.ReplicatedStorage.Shared.Config.PetConfig)
local function execute(p,command,arg,value)
 local d=D.Profiles[p];if not d then return false end
 if command=="pet" and C.Power[arg] then local tier=tonumber(value) or 1;if tier%1==0 and tier>=1 and tier<=#C.Tiers then Pet.Grant(p,arg,tier) else return false end
 elseif command=="coins" then local n=tonumber(arg);if n and n==n then d.coins+=math.clamp(n,0,C.DebugMaxCoins) else return false end
 elseif command=="ripe" then for _,g in ipairs(d.graves) do g.plantedAt=os.time()-require(game.ReplicatedStorage.Shared.Config.GraveConfig)[g.type].Seconds end
 elseif command=="phase" and (arg=="day" or arg=="night") then workspace:SetAttribute("DebugPhase",arg)
 else return false end
 Pet.Push(p);return true
end
local function connect(p) p.Chatted:Connect(function(message) local a=string.split(message," ");if a[1]:sub(1,1)=="/" then execute(p,a[1]:sub(2),a[2],a[3]) end end) end
game.Players.PlayerAdded:Connect(connect);for _,p in ipairs(game.Players:GetPlayers()) do connect(p) end
-- Server-only Studio Command Bar entry point; absent from published servers and invisible to clients.
local command=Instance.new("BindableFunction");command.Name="PetDebugCommand";command.OnInvoke=execute;command.Parent=game.ServerStorage
