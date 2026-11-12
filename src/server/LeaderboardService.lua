-- The global top farmers and the golden statue of the leader's best zombie.
-- Scores only ever come from profiles this server computed. Ranked by the best income per second ever reached,
-- so a bite, a theft or a sale never knocks anyone down the table.
local DSS=game:GetService("DataStoreService");local Players=game:GetService("Players");local UserService=game:GetService("UserService")
local RS=game.ReplicatedStorage;local S=RS.Shared
local Social=require(S.Config.SocialConfig);local C=Social.Board;local SC=Social.Statue
local Art=require(S.ArtKit);local Manifest=require(S.ArtManifest);local Pal=require(S.Palette);local ZC=require(S.Config.ZombieConfig)
local D=require(script.Parent.DataService);local Z=require(script.Parent.ZombieService);local P=require(script.Parent.PlotService)
local B={Entries={},Names={},Published={},Best={}}
local rem;local rows={};local empty;local plaque;local statue;local feet;local figureKey
local ordered=not D.Memory and DSS:GetOrderedDataStore(C.Store)
-- Every outside call goes through here, so a test can stand in for the cloud.
B.Source={
 Top=function()
  if not ordered then return {} end
  local out={}
  for _,row in ipairs(ordered:GetSortedAsync(false,C.Fetch,1):GetCurrentPage()) do
   local id=tonumber(row.key);if id then table.insert(out,{id=id,value=row.value}) end
  end
  return out
 end,
 Publish=function(id,value)
  if ordered then ordered:UpdateAsync(tostring(id),function(old) return math.max(tonumber(old) or 0,value) end) end
 end,
 Names=function(ids)
  local map={};for _,info in ipairs(UserService:GetUserInfosByUserIdsAsync(ids)) do map[info.Id]=info.DisplayName end;return map
 end,
 Profile=D.Peek,
}
local function compact(n) return require(S.Locale).compact(n,"en") end
function B.Observe(d,income) if income>(d.peakIncome or 0) then d.peakIncome=income end end
local function publish(userId,peak)
 local value=math.floor(peak or 0)
 if userId<=0 or value<1 or value<=(B.Published[userId] or 0) then return end
 B.Published[userId]=value
 local ok,err=pcall(B.Source.Publish,userId,value)
 if not ok then B.Published[userId]=nil;warn("Leaderboard publish failed",err) end
end
function B.Flush(p)
 local d=D.Profiles[p];if d then publish(p.UserId,d.peakIncome) end
end
function B.Forget(userId) B.Published[userId]=nil end
-- ---- World board ---------------------------------------------------------------------------------
local function text(parent,size,pos,color,align)
 local l=Instance.new("TextLabel");l.Size=size;l.Position=pos;l.BackgroundTransparency=1;l.TextColor3=color or Pal.Ink
 l.Font=Enum.Font.GothamBlack;l.TextScaled=true;l.AutoLocalize=false;l.TextXAlignment=align or Enum.TextXAlignment.Left;l.Text="";l.Parent=parent;return l
end
local function corner(f,r) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r);c.Parent=f end
local function buildBoard(w)
 local y=Vector3.new(0,P.PlazaTop,0);local at=CFrame.lookAt(C.At+y,C.FaceAt+y)
 Art.Spawn("V3_QuestBoard",w,at,{scale=Vector3.new(2.2,2.5,1.4)})
 P.Solid(w,"BoardCollider",Vector3.new(16.8,18,1.2),at*CFrame.new(0,9,0))
 local carrier=P.Part(w,"TopFarmersBoard",Vector3.new(15.4,8.6,.05),at*CFrame.new(0,12.5,-.96),Pal.Panel)
 carrier.Transparency=1;carrier.CanCollide,carrier.CanTouch,carrier.CanQuery,carrier.CastShadow=false,false,false,false
 local gui=Instance.new("SurfaceGui");gui.Face=Enum.NormalId.Front;gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;gui.PixelsPerStud=42;gui.LightInfluence=.3;gui.Parent=carrier
 local paper=Instance.new("Frame");paper.Size=UDim2.fromScale(1,1);paper.BackgroundColor3=Pal.Panel;paper.BorderSizePixel=0;corner(paper,18);paper.Parent=gui
 local stroke=Instance.new("UIStroke");stroke.Color=Pal.Stroke;stroke.Thickness=6;stroke.Parent=paper
 local bar=Instance.new("Frame");bar.Size=UDim2.new(1,-14,0,52);bar.Position=UDim2.fromOffset(7,7);bar.BackgroundColor3=Pal.Violet;bar.BorderSizePixel=0;corner(bar,12);bar.Parent=paper
 local title=text(bar,UDim2.new(1,-20,1,-8),UDim2.fromOffset(10,4),Pal.Text,Enum.TextXAlignment.Center);title:SetAttribute("LocKey","boardTitle");title.Parent=bar
 local rowHeight=29
 for i=1,C.WorldRows do
  local f=Instance.new("Frame");f.Size=UDim2.new(1,-20,0,rowHeight);f.Position=UDim2.fromOffset(10,64+(i-1)*rowHeight);f.BackgroundTransparency=1;f.Parent=paper
  local rank=text(f,UDim2.fromOffset(50,rowHeight-3),UDim2.new(),Pal.Ink,Enum.TextXAlignment.Center);rank.Text=({"🥇","🥈","🥉"})[i] or tostring(i)
  local head=Instance.new("ImageLabel");head.Size=UDim2.fromOffset(rowHeight-3,rowHeight-3);head.Position=UDim2.fromOffset(54,0);head.BackgroundColor3=Pal.PanelDark;corner(head,8);head.Parent=f
  local name=text(f,UDim2.new(1,-220,0,rowHeight-5),UDim2.fromOffset(88,1))
  local value=text(f,UDim2.fromOffset(125,rowHeight-5),UDim2.new(1,-128,0,1),Color3.fromHex("C96F00"),Enum.TextXAlignment.Right)
  rows[i]={frame=f,head=head,name=name,value=value}
 end
 empty=text(paper,UDim2.new(1,-40,0,70),UDim2.fromOffset(20,150),Pal.Ink,Enum.TextXAlignment.Center);empty:SetAttribute("LocKey","topEmpty")
end
local function renderBoard()
 for i,row in ipairs(rows) do
  local e=B.Entries[i]
  row.frame.Visible=e~=nil
  if e then
   row.name.Text=e.name;row.value.Text="💰 "..compact(e.value);row.value:SetAttribute("CompactPrefix","💰 ");row.value:SetAttribute("CompactValue",e.value)
   row.head.Image=e.id>0 and ("rbxthumb://type=AvatarHeadShot&id="..e.id.."&w=48&h=48") or ""
  end
 end
 if empty then empty.Visible=#B.Entries==0 end
end
-- ---- Statue --------------------------------------------------------------------------------------
local function cylinder(parent,name,radius,height,at,color,material)
 local part=P.Part(parent,name,Vector3.new(height,radius*2,radius*2),at*CFrame.new(0,height/2,0)*CFrame.Angles(0,0,math.pi/2),color,Enum.PartType.Cylinder)
 part.Material=material or Enum.Material.SmoothPlastic;return part
end
local function buildStatue(w)
 statue=Instance.new("Model");statue.Name="ChampionStatue";statue.Parent=w
 local y=Vector3.new(0,P.PlazaTop,0);local at=CFrame.lookAt(SC.At+y,SC.FaceAt+y);local gold=Color3.fromHex(SC.Gold)
 cylinder(statue,"Plinth",5.6,1.4,at,Pal.Stone)
 cylinder(statue,"Column",4,3.5,at*CFrame.new(0,1.4,0),Pal.Panel)
 cylinder(statue,"Trim",4.5,.5,at*CFrame.new(0,4.9,0),gold,Enum.Material.Metal)
 feet=at*CFrame.new(0,5.4,0)
 local plate=P.Part(statue,"Plaque",Vector3.new(6.8,2.3,.3),at*CFrame.new(0,3.2,-4.05),gold);plate.Material=Enum.Material.Metal
 plaque=P.SignText(statue,at*CFrame.new(0,3.2,-4.22),Vector3.new(6.4,2,.05),"statueEmpty",Pal.Ink)
 plaque:SetAttribute("StatuePlate",true)
end
local function clearFigure()
 local old=statue and statue:FindFirstChild("Figure");if old then old:Destroy() end
 figureKey=nil
end
local function gild(model)
 local gold=Color3.fromHex(SC.Gold)
 for _,part in ipairs(model:GetDescendants()) do
  if part:IsA("BasePart") then part.Color=gold;part.Material=Enum.Material.Metal;part.Transparency=0 end
 end
 local glow=Instance.new("Highlight");glow.FillColor=gold;glow.FillTransparency=.38;glow.OutlineColor=Color3.fromHex(SC.GoldDark);glow.OutlineTransparency=.1;glow.DepthMode=Enum.HighlightDepthMode.Occluded;glow.Parent=model
end
-- No ZombieId on purpose: ZombieVisuals animates only models that have one, and a statue stands still.
local function buildFigure(z)
 local m=Instance.new("Model");m.Name="Figure"
 local body=Art.BuildZombie(m,feet,{id="statue",type=z.type,tier=z.tier,mutation="None"})
 local ring=m:FindFirstChild("Ring");if ring then ring:Destroy() end
 m.Parent=statue;m:ScaleTo(SC.Scale);m:PivotTo(feet*CFrame.new(0,Art.PivotHeight*SC.Scale,0));gild(m)
 local e=Instance.new("ParticleEmitter");e.Rate=5;e.Lifetime=NumberRange.new(.7,1.4);e.Speed=NumberRange.new(.5,1.5);e.SpreadAngle=Vector2.new(180,180)
 e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.6),NumberSequenceKeypoint.new(1,0)});e.LightEmission=.6;e.Color=ColorSequence.new(Pal.Accent);e.Parent=body
 local light=Instance.new("PointLight");light.Color=Color3.fromHex(SC.Gold);light.Brightness=1;light.Range=16;light.Parent=body;require(S.WorldArt).NightLight(light)
end
local function setChampion(entry,z)
 if not statue then return end
 if not z then clearFigure();plaque:SetAttribute("ChampName",nil);plaque:SetAttribute("ChampType",nil);return end
 plaque:SetAttribute("ChampName",entry.name);plaque:SetAttribute("ChampType",z.type)
 local key=z.type..":"..z.tier
 if key==figureKey then return end
 clearFigure()
 local ok,err=pcall(buildFigure,z)
 if ok then figureKey=key else warn("Statue build failed",err);clearFigure() end
end
-- Saved data is not trusted to match today's art or config: a broken zombie is simply skipped.
function B.BestZombie(d)
 local best,bestRate=nil,-1
 for _,z in ipairs(type(d)=="table" and type(d.zombies)=="table" and d.zombies or {}) do
  if type(z)=="table" and type(z.tier)=="number" and ZC.Income[z.tier] and (require(S.MonsterCollection).Models[z.type] or Manifest["Z_"..tostring(z.type)]) then
   local rate=Z.Rate(z);if rate>bestRate then best,bestRate=z,rate end
  end
 end
 return best
end
local function bestFor(entry)
 local online=Players:GetPlayerByUserId(entry.id);local d=online and D.Profiles[online]
 if d then return B.BestZombie(d) end
 local cached=B.Best[entry.id]
 if cached and os.clock()-cached.at<C.ProfileReread then return cached.zombie end
 local ok,profile=pcall(B.Source.Profile,entry.id)
 if not ok then warn("Champion read failed",profile);return cached and cached.zombie end
 local z=B.BestZombie(profile);B.Best[entry.id]={zombie=z,at=os.clock()};return z
end
function B.UpdateStatue()
 for i=1,math.min(C.ChampionCandidates,#B.Entries) do
  local z=bestFor(B.Entries[i])
  if z then setChampion(B.Entries[i],z);return end
 end
 setChampion(nil,nil)
end
-- ---- Refresh -------------------------------------------------------------------------------------
function B.Refresh()
 local ok,top=pcall(B.Source.Top)
 if ok then B.Stored=top else warn("Leaderboard read failed",top) end
 local best={}
 for _,row in ipairs(B.Stored or {}) do best[row.id]=row.value end
 -- Players here count at once, without waiting for the store to catch up.
 for p,d in pairs(D.Profiles) do
  local value=math.floor(d.peakIncome or 0)
  if value>=1 then best[p.UserId]=math.max(best[p.UserId] or 0,value);B.Names[p.UserId]=p.DisplayName end
 end
 local missing={};local gone={}
 for id in pairs(best) do if not B.Names[id] then table.insert(missing,id) end end
 if #missing>0 then
  local found,map=pcall(B.Source.Names,missing)
  if found then for _,id in ipairs(missing) do if map[id] then B.Names[id]=map[id] else gone[id]=true end end
  else warn("Leaderboard names failed",map) end
 end
 local list={}
 for id,value in pairs(best) do if not gone[id] then table.insert(list,{id=id,name=B.Names[id] or ("#"..id),value=value}) end end
 table.sort(list,function(a,b) if a.value~=b.value then return a.value>b.value end return a.id<b.id end)
 for i=#list,C.Fetch+1,-1 do list[i]=nil end
 B.Entries=list;renderBoard();B.UpdateStatue()
 if rem then rem:FireAllClients({entries=list}) end
end
function B.Push(p) if rem then rem:FireClient(p,{entries=B.Entries}) end end
function B.Init()
 rem=Instance.new("RemoteEvent");rem.Name="Board";rem.Parent=RS.Remotes
 buildBoard(P.World);buildStatue(P.World);renderBoard()
 task.spawn(function()
  task.wait(C.FirstRefresh)
  while true do
   for p in pairs(D.Profiles) do task.spawn(B.Flush,p) end
   local ok,err=pcall(B.Refresh);if not ok then warn("Leaderboard refresh failed",err) end
   task.wait(C.Refresh)
  end
 end)
end
return B
