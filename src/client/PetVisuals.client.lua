local Players=game:GetService("Players");local Run=game:GetService("RunService");local RS=game:GetService("ReplicatedStorage");local C=require(RS.Shared.Config.PetConfig);local Model=require(RS.Shared.PetModel);local L=require(RS.Shared.Locale);local me=Players.LocalPlayer
local rem=RS:WaitForChild("Remotes");local folder=Instance.new("Folder",workspace);folder.Name="ClientPets";local models,lists,fx,connections={},{},{},{}
local function update(p) local ok,list=pcall(game.HttpService.JSONDecode,game.HttpService,p:GetAttribute("EquippedPets") or "[]");lists[p]=ok and list or {} end
local function watch(p) update(p);connections[p]=p:GetAttributeChangedSignal("EquippedPets"):Connect(function() update(p) end) end
Players.PlayerAdded:Connect(watch);Players.PlayerRemoving:Connect(function(p) lists[p]=nil;if connections[p] then connections[p]:Disconnect();connections[p]=nil end end);for _,p in ipairs(Players:GetPlayers()) do watch(p) end
rem:WaitForChild("PetDigFx").OnClientEvent:Connect(function(owner,id,slot,position) fx[id]={at=os.clock(),target=position+Vector3.new(0,1,0)} end)
local Sfx=require(RS:WaitForChild("Shared"):WaitForChild("Sfx"));local function sound(name) Sfx.play(name) end
rem:WaitForChild("PetAlarm").OnClientEvent:Connect(function(id)
 local thief=type(id)=="number" and Players:GetPlayerByUserId(id);if thief and thief.Character then local h=Instance.new("Highlight");h.FillColor=Color3.fromRGB(255,90,90);h.Parent=thief.Character;game.Debris:AddItem(h,C.AlarmCooldown) end
 sound("PetAlarmSound")
 for _,pet in ipairs(lists[me] or {}) do if pet.species=="GuardDog" then fx[pet.id]={at=os.clock(),alarm=true} end end
end)
Run.RenderStepped:Connect(function(dt)
 local alive={};local origin=workspace.CurrentCamera.CFrame.Position
 for p,pets in pairs(lists) do local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
 if root and (p==me or (root.Position-origin).Magnitude<=C.ViewDistance) then
 for i,pet in ipairs(pets) do if i>C.MaxSlots then break end;alive[pet.id]=true
 local m=models[pet.id];if not m then m=Model.Build(pet,folder);m:PivotTo(root.CFrame);models[pet.id]=m end
 local angle=(i-(#pets+1)/2)*.65;local target=root.CFrame*CFrame.new(math.sin(angle)*4,-2,3+math.cos(angle)*2)
 local effect=fx[pet.id];local bob=math.sin(os.clock()*5+i)*.12
 if effect then local age=os.clock()-effect.at
 if effect.alarm then bob+=math.abs(math.sin(age*10))*.8;if age>2 then fx[pet.id]=nil end
 elseif age<C.DigTravel*3 then local blend=age<C.DigTravel and age/C.DigTravel or age<C.DigTravel*2 and 1 or 1-(age-C.DigTravel*2)/C.DigTravel;target=target:Lerp(CFrame.new(effect.target),blend);bob+=math.abs(math.sin(age*18))*.2
 if age>=C.DigTravel and not effect.dirt then effect.dirt=true;sound("PetDigSound");local e=Instance.new("ParticleEmitter");e.Color=ColorSequence.new(Color3.fromHex("8B5A3C"));e.Lifetime=NumberRange.new(.5);e.Speed=NumberRange.new(3,5);e.Rate=0;e.Parent=m.PrimaryPart;e:Emit(12);game.Debris:AddItem(e,1) end
 else fx[pet.id]=nil end end
 target+=Vector3.new(0,bob,0);m:PivotTo((m:GetPivot().Position-target.Position).Magnitude>C.TeleportDistance and target or m:GetPivot():Lerp(target,1-math.exp(-C.FollowSpeed*dt)))
 local badge=m:FindFirstChild("Status")
 local text=effect and effect.alarm and "!" or pet.species=="FarmerCat" and p:GetAttribute("PetCryptFull") and L.text("petCryptFull",L.lang()) or ""
 if text~="" and not badge then badge=Instance.new("BillboardGui");badge.Name="Status";badge.Size=UDim2.fromOffset(150,32);badge.StudsOffset=Vector3.new(0,3,0);badge.Adornee=m.PrimaryPart;badge.Parent=m;local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.TextColor3=Color3.new(1,1,1);label.Font=Enum.Font.BuilderSansBold;label.TextScaled=true;label.Parent=badge end
 if badge then badge.TextLabel.Text=text end
 end end end
 for id,m in pairs(models) do if not alive[id] then m:Destroy();models[id]=nil;fx[id]=nil end end
end)
