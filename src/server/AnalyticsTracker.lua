local A={};local service=game:GetService("AnalyticsService")
function A.Step(p,n) pcall(function() service:LogOnboardingFunnelStepEvent(p,n,"Step"..n) end) end
function A.Economy(p,delta,balance,item,origin)
 if delta~=0 and item~="FarmIncome" and game.ReplicatedStorage.Remotes:FindFirstChild("InterfaceAction") then local ui=require(script.Parent.InterfaceService);if ui.Push then ui.Refresh(p);ui.Push(p) end end
 if delta~=0 and item~="FarmIncome" then local e=game.ReplicatedStorage.Remotes:FindFirstChild("EconomyFX");local r=p.Character and p.Character:FindFirstChild("HumanoidRootPart");if e then e:FireClient(p,delta,item,origin or r and r.Position) end end
 pcall(function() service:LogEconomyEvent(p,delta>0 and Enum.AnalyticsEconomyFlowType.Source or Enum.AnalyticsEconomyFlowType.Sink,"Coins",math.abs(delta),balance,Enum.AnalyticsEconomyTransactionType.Gameplay.Name,item) end) end
return A
