-- One timeline drives the hand targets, tool orientation and body turn.
-- The tool is a melee weapon (ShovelConfig; shovels until 2026-11-16) - or, digging a grave, the plain shovel
-- (`tool='Dig'`). Its frame (ShovelModel): the hand at the origin, the working end along -Y, the edge towards -Z.
local C=require(script.Parent.Config.ShovelConfig)
local M={}
local function smooth(t) t=math.clamp(t,0,1);return t*t*(3-2*t) end
local ready=CFrame.new(1.25,-.25,-.9)*CFrame.Angles(0,0,math.pi)
local sweep=CFrame.new(1.1,.05,-1.3)*CFrame.Angles(0,0,math.pi/2)
local load=CFrame.new(.65,0,-1.2)*CFrame.Angles(-.1,0,.8)
local lift=CFrame.new(.65,.3,-1.25)*CFrame.Angles(-.3,0,.8)
local plant=CFrame.new(.65,-.45,-1.3)*CFrame.Angles(.08,0,.8)
local lever=CFrame.new(.65,-.2,-1.2)*CFrame.Angles(-.18,0,.8)
local CHAINED={Chainsaw=true,Chainsword=true} -- they have an engine: it revs through a swing
-- `weapon`: whose swing or ready hold it is (a one-hand weapon keeps the left hand off it).
function M.Sample(kind,t,weapon)
 t=math.clamp(t or 0,0,1)
 local frame,spin,left,lean=ready,0,0,0
 local two=kind=='dig' or (C[weapon or ''] and C[weapon].Hands or 2)==2
 local engine
 if kind=='swing' then
  local extend=smooth(t/.2)*(1-smooth((t-.8)/.2))
  frame=ready:Lerp(sweep,extend);left=two and extend or 0
  spin=math.pi*2*smooth((t-.18)/.62)
  if CHAINED[weapon or ''] then engine=extend end
 elseif kind=='dig' then
  local cycle=t*3%1
  if cycle<.25 then frame=load:Lerp(lift,smooth(cycle/.25))
  elseif cycle<.52 then frame=lift:Lerp(plant,smooth((cycle-.25)/.27))
  elseif cycle<.75 then frame=plant:Lerp(lever,smooth((cycle-.52)/.23))
  else frame=lever:Lerp(load,smooth((cycle-.75)/.25)) end
  local blend=smooth(t/.1)*(1-smooth((t-.92)/.08))
  frame=ready:Lerp(frame,blend);left=blend
  lean=.1*math.sin(cycle*math.pi)*blend
 end
 return {frame=frame,spin=spin,left=left,lean=lean,kind=kind,phase=t,tool=kind=='dig' and 'Dig' or weapon,engine=engine,cutting=0}
end
-- The boss finisher (owner, 2026-11-15; RoadConfig.Boss.Finisher.Kinds - the server picks one of the weapon's two,
-- the player's and the boss's FinisherKind attribute; K.Tool is the weapon). Two ways of playing one:
--   clips   K.Clips, entries in turn, each from its At: the player walks up with empty hands (nothing from here
--           until the first entry), then
--             Name   a clip of shared/Clips on the whole body (CombatPose.PlayClip), the weapon held in the right
--                    hand like a sword - its blade out along the hand's forward, where the pack's wrist carries one,
--                    the edge down. Grip holds it another way: "Reverse" point down from the fist (a plunge),
--                    "Point" straight on from the forearm (a stab: the pack's punches and its shield bash push the
--                    fist out, and a sword held the first way would stand upright in it). Rate plays the clip
--                    faster or slower, From starts it that far in, Hold={t, s} freezes it at clip time t for s
--                    seconds. The last entry's end is held until the finisher is over.
--             Code   'spin': the coded swing's spin, Turns times round in Seconds, the weapon out to the side;
--                    'flourish': the knife held out in front and flipped (ShovelModel.Flip), Flips times
--           K.Moves carry the body besides (root space, eased): Forward and Side studs between From and To, and Up -
--           the top of a jump's arc (a jump goes forward evenly). `offset` is where all that, and the clips before
--           this one, have put the body, so each entry starts where the last left it.
--           K.Engine={from, to} runs the chainsword's engine, K.Soft={from, to} is its grinding (sparks).
--   the saw (K.Saw; the chainsaw's two, below) a coded two-hand pose.
-- `sec` is seconds since it began.
local F=require(script.Parent.Config.RoadConfig).Boss.Finisher
local Clip=require(script.Parent.ClipPlayer)
local blade=CFrame.Angles(math.pi/2,0,-.2)*CFrame.Angles(math.pi/2,0,0)*CFrame.Angles(0,math.pi,0)
local GRIPS={Reverse=CFrame.Angles(math.pi/2,0,-.2)*CFrame.Angles(-math.pi/2,0,0),Point=CFrame.Angles(math.pi/2,0,-.2)}
-- Where an entry's clip is `dt` seconds after the entry began.
local function clipTime(c,dt)
 local r=c.Rate or 1;local x=dt*r
 local h=c.Hold;if h and x>h[1] then x=math.max(h[1],(dt-h[2])*r) end
 return x+(c.From or 0)
end
local function flat(v) return Vector3.new(v.X,0,v.Z) end
local function hipsAt(c,t)
 local clip=c.Name and Clip.Get(c.Name)
 if not clip or not clip.Pos.LowerTorso then return Vector3.zero end
 return flat(Clip.Pose(clip,t,'LowerTorso').Position)
end
-- How far an entry has carried the body across the ground `dt` seconds after it began.
local function travelOf(c,dt) return hipsAt(c,clipTime(c,dt))-hipsAt(c,c.From or 0) end
local function moved(K,sec)
 local sum=Vector3.zero
 for _,m in ipairs(K.Moves or {}) do
  local u=math.clamp((sec-m.From)/(m.To-m.From),0,1);local e=m.Up and u or smooth(u)
  sum+=Vector3.new((m.Side or 0)*e,(m.Up or 0)*4*u*(1-u),-(m.Forward or 0)*e)
 end
 return sum
end
-- Where the entries that are over by `sec`, and the Moves, have put the body (root space).
function M.FinisherTravel(K,sec)
 local sum=moved(K,sec)
 for i,c in ipairs(K.Clips or {}) do
  local nextAt=K.Clips[i+1] and K.Clips[i+1].At
  if nextAt and sec>=nextAt then sum+=travelOf(c,nextAt-c.At) end
 end
 return sum
end
-- Where the whole finisher leaves the body: the character itself goes there as the last clip lets go.
function M.FinisherEnd(K)
 local last=K.Clips and K.Clips[#K.Clips];if not last then return Vector3.zero end
 return flat(M.FinisherTravel(K,K.Seconds)+travelOf(last,K.Seconds-last.At))
end
-- The chainsaw (owner, 2026-11-15: "one of the finishers must be with a chainsaw"; ChainsawModel). Everything is in
-- the root's frame: `frame` is the saw (its own frame: the rear handle, the bar along its LookVector), the right
-- hand holds that handle (`grip`: the saw in the hand's frame) and the left goes to `leftAt` on the saw - the starter
-- cord while it is being started, then the front handle. The times are K.Saw:
--   Draw    it comes from behind the back into the right hand, on the walk up
--   Pull    the starter cord is pulled at each of these; the engine catches on the last
--   Raise   up over the shoulder          Plunge  down into the boss's head (`aim`, its head in the root's frame)
--   Cut     it is in: pressed further in until Rip, the body leaning on it
--   Rip     torn up and out; then held high in the right hand alone (Hold) and lowered (Lower)
-- Style='Sweep' (2026-11-16, the chainsaw's second finisher) uses the same times for a cut from the side: at Raise
-- the saw is drawn back to the right, flat, at Plunge swung in at the head's side, from Cut to Rip ground across
-- it to the left, and torn out past it.
-- `lean`, `twist` and `stance` pose the body (CombatPose.SawPose); `engine` (0..1: off, idling, flat out), `cutting`
-- and `pulls` drive the sound, the smoke, the chain and the sparks (ActionVisuals).
local SAW_HAND=CFrame.Angles(math.pi/2,0,0) -- the right hand on the rear handle, in the saw's frame: fingers along the bar
local SAW_GRIP=SAW_HAND:Inverse()
local CORD,FRONT=Vector3.new(-.46,.24,-.72),Vector3.new(-.04,.8,-.8)
local function sawAt(pos,pitch,yaw,roll) return CFrame.new(pos)*CFrame.Angles(0,yaw,0)*CFrame.Angles(pitch,0,0)*CFrame.Angles(0,0,roll) end
local SAW={
 back={sawAt(Vector3.new(.75,-.15,.65),-1.35,0,0),0,0,0},
 carry={sawAt(Vector3.new(.95,-.85,-.25),-.5,.1,0),0,0,0},
 start={sawAt(Vector3.new(.5,-.5,-.72),-.22,.5,.3),.18,.22,.6},
 -- raised and torn out, the saw is rolled on its side: its top, with the front handle, turns to the left hand
 raise={sawAt(Vector3.new(.75,.55,-.45),1.15,.1,1.1),-.28,-.18,1},
 rip={sawAt(Vector3.new(.95,.8,-.45),1.05,-.5,1),-.3,-.5,1},
 -- held high in the right hand alone, the bar to the sky
 hold={sawAt(Vector3.new(1,1.75,-.2),1.45,0,0),-.15,0,.5},
}
local function blend(a,b,t)
 return {a[1]:Lerp(b[1],t),a[2]+(b[2]-a[2])*t,a[3]+(b[3]-a[3])*t,a[4]+(b[4]-a[4])*t}
end
local function saw(sec,K,aim)
 local S=K.Saw
 if sec<S.Draw then return nil end
 aim=aim or Vector3.new(0,-.4,-K.Stand)
 local lastPull=S.Pull[#S.Pull]
 local push=smooth((sec-S.Cut)/(S.Rip-S.Cut))
 local raise,cut,rip
 if S.Style=='Sweep' then
  -- flat, its top to the left hand, the bar ahead: drawn back to the right, then across the head to the left
  local y=math.clamp(aim.Y+.05,-.9,.6)
  -- (not quite flat: tipped, so the cut runs down across it and the bar shows its face to a camera at the side)
  local function across(x,drop,yaw,twist,lean) return {sawAt(Vector3.new(aim.X+x,y+drop,-.78),-.12,yaw,.95),lean,twist,1} end
  raise=across(1.35,.55,-.7,-.6,.05)
  cut=across(.95-1.7*push,.4-.75*push,-.15+.4*push,-.4+.9*push,.22)
  rip=across(-1.3,-.45,.95,.7,.12)
 else
  -- the cut: from in front of the belly towards its head, pressed in as it goes
  local hand=Vector3.new(.22,-.05-.22*push,-.8-.4*push)
  local to=aim-hand
  raise,rip=SAW.raise,SAW.rip
  cut={sawAt(hand,math.clamp(math.atan2(to.Y,math.max(1,Vector3.new(to.X,0,to.Z).Magnitude)),-.95,.6),math.clamp(math.atan2(-to.X,-to.Z),-.5,.5),0),.42+.14*push,.12,1}
 end
 local key,left,leftAt,engine,cutting=SAW.carry,0,FRONT,0,0
 local pulls,pull=0,0
 if sec<K.Walk then
  key=blend(SAW.back,SAW.carry,smooth((sec-S.Draw)/.25))
 elseif sec<S.Raise then
  -- starting it: the left hand takes the cord and yanks; the saw kicks with each pull
  local settle=smooth((sec-K.Walk)/.22)
  key=blend(SAW.carry,SAW.start,settle);left=settle;leftAt=CORD
  for _,at in ipairs(S.Pull) do
   if sec>=at then pulls+=1;pull=math.max(pull,math.sin(math.clamp((sec-at)/.24,0,1)*math.pi)) end
  end
  leftAt=CORD+Vector3.new(-.5,.7,.4)*pull
  key={key[1]*CFrame.new(.04*pull,.06*pull,0)*CFrame.Angles(.1*pull,0,-.16*pull),key[2]-.1*pull,key[3]+.2*pull,key[4]}
 elseif sec<S.Plunge then
  local k=smooth((sec-S.Raise)/(S.Plunge-S.Raise))
  key=blend(SAW.start,raise,k);left=1;leftAt=CORD:Lerp(FRONT,smooth(k*2.5));pulls=#S.Pull
 elseif sec<S.Cut then
  local k=math.clamp((sec-S.Plunge)/(S.Cut-S.Plunge),0,1)
  key=blend(raise,cut,k*k);left=1;pulls=#S.Pull
 elseif sec<S.Rip then
  key=cut;left=1;cutting=1;pulls=#S.Pull
 elseif sec<S.Hold then
  local k=math.clamp((sec-S.Rip)/(S.Hold-S.Rip),0,1)
  key=blend(cut,rip,1-(1-k)*(1-k));left=1;pulls=#S.Pull;cutting=1-smooth(k*3)
 elseif sec<S.Lower then
  key=blend(rip,SAW.hold,smooth((sec-S.Hold)/.45));left=1-smooth((sec-S.Hold)/.3);pulls=#S.Pull
 else
  local k=smooth((sec-S.Lower)/math.max(.1,K.Seconds-S.Lower))
  key=blend(SAW.hold,SAW.carry,k);pulls=#S.Pull
 end
 -- the engine: catches on the last pull, idles, flat out from the raise to the end of the rip and held high
 if sec>=lastPull+.1 then
  local rev=math.max(smooth((sec-S.Raise)/.3)*(1-smooth((sec-S.Hold-.1)/.3)),.7*smooth((sec-S.Hold-.25)/.2)*(1-smooth((sec-S.Lower+.1)/.25)))
  engine=(.4+.6*rev)*smooth((sec-lastPull-.1)/.15)*(1-smooth((sec-S.Lower-.1)/.3))
 end
 -- it shakes in the hands with the engine, hard while it cuts
 local shake=engine*(.012+.03*cutting)
 local frame=key[1]*CFrame.new(math.noise(sec*38,1.7)*shake,math.noise(sec*41,5.3)*shake,math.noise(sec*35,9.1)*shake)*CFrame.Angles(math.noise(sec*33,2.2)*shake*.8,0,math.noise(sec*29,7.4)*shake*1.6)
 return {kind='saw',tool='Chainsaw',frame=frame,grip=SAW_GRIP,hand=SAW_HAND,spin=0,left=left,leftAt=leftAt,
  lean=key[2]+math.noise(sec*36,3.3)*shake*.6,twist=key[3],stance=key[4],engine=engine,cutting=cutting,pulls=pulls,phase=sec/K.Seconds}
end
function M.Finisher(sec,K,aim)
 K=K or F.Of(nil)
 if K.Saw then return saw(sec,K,aim) end
 local entry
 for _,c in ipairs(K.Clips) do if sec>=c.At then entry=c end end
 if not entry then return nil end
 local dt=sec-entry.At
 local offset=M.FinisherTravel(K,sec)
 -- a chainsword's engine through its finisher, and the grinding
 local engine,cutting
 if K.Engine then
  engine=smooth((sec-K.Engine[1])/.2)*(1-smooth((sec-K.Engine[2])/.3))
  cutting=K.Soft and sec>=K.Soft[1] and sec<K.Soft[2] and 1 or 0
  engine*=.55+.45*math.max(cutting,math.abs(math.sin(sec*5.1)))
 end
 if entry.Code=='spin' then
  -- the swing's spin, round and round: the weapon out to the side, both hands on a long one
  local u=math.clamp(dt/entry.Seconds,0,1);local out=smooth(dt/.2)*(1-smooth((dt-entry.Seconds+.15)/.15))
  local two=(C[K.Tool] and C[K.Tool].Hands or 2)==2
  return {frame=ready:Lerp(sweep,out),spin=math.pi*2*entry.Turns*(u*u*(3-2*u)*.35+u*.65),left=two and out or 0,lean=0,kind='swing',tool=K.Tool,offset=offset,engine=engine,cutting=cutting,phase=sec/K.Seconds}
 elseif entry.Code=='flourish' then
  -- the knife out in front of the chest, flipping
  local u=math.clamp(dt/entry.Seconds,0,1);local up=smooth(dt/.18)*(1-smooth((dt-entry.Seconds+.12)/.12))
  local show=CFrame.new(.55,.35,-1.25)*CFrame.Angles(-.5,0,math.pi+.35)*CFrame.Angles(0,math.sin(u*math.pi*4)*.25,0)
  return {frame=ready:Lerp(show,up),spin=0,left=0,lean=0,kind='show',tool=K.Tool,flip=(u*(entry.Flips or 2))%1,offset=offset,phase=sec/K.Seconds}
 end
 return {frame=GRIPS[entry.Grip or ''] or blade,slide=0,spin=0,left=0,lean=0,kind='clip',clip=entry.Name,t=clipTime(entry,dt),
  offset=offset-hipsAt(entry,entry.From or 0),tool=K.Tool,engine=engine,cutting=cutting,phase=sec/K.Seconds}
end
-- The middle of a boss's head now: a rigid boss's head piece; a skinned one's Head bone, moved by the model's
-- HeadCentre (the head's middle in the bone's frame, from the art: without it, the bone itself - the neck). Nil when
-- it has neither.
local heads=setmetatable({},{__mode='k'})
function M.BossHead(boss)
 local root=boss and boss.PrimaryPart;if not root then return nil end
 local head=heads[boss]
 if head==nil then
  head=false
  for _,j in root:GetChildren() do
   if j:IsA('Motor6D') and (j:GetAttribute('PoseGroup') or j.Name)=='Head' and j.Part1 then head=j.Part1;break end
  end
  if not head then local bone=boss:FindFirstChild('Head',true);if bone and bone:IsA('Bone') then head=bone end end
  heads[boss]=head
 end
 if not head or not head.Parent then return nil end
 if not head:IsA('Bone') then return head.Position end
 local centre=boss:GetAttribute('HeadCentre')
 return centre and head.TransformedWorldCFrame*(centre*boss:GetScale()) or head.TransformedWorldCFrame.Position
end
-- The head of the boss this player is finishing, in the player's root frame (kept once the boss is gone).
local aims=setmetatable({},{__mode='k'})
local function aimOf(player,root)
 local id=player:GetAttribute('FinisherBoss');local held=aims[player]
 if not held or held.id~=id then held={id=id};aims[player]=held end
 if not held.boss or not held.boss.Parent then
  held.boss=nil
  local folder=workspace:FindFirstChild('Mutants')
  for _,m in ipairs(folder and folder:GetChildren() or {}) do if m:GetAttribute('MutantId')==id then held.boss=m;break end end
 end
 local head=held.boss and M.BossHead(held.boss)
 if head and root then held.aim=root.CFrame:PointToObjectSpace(head) end
 return held.aim
end
function M.ForPlayer(player,now)
 local ch=player.Character;local h=ch and ch:FindFirstChildOfClass('Humanoid')
 if not h or h.Health<=0 or player:GetAttribute('Training') or now<(player:GetAttribute('KnockedOutUntil') or 0) then return nil end
 if now<(player:GetAttribute('FinisherUntil') or 0) then
  local K=F.Of(player)
  return M.Finisher(now-(player:GetAttribute('FinisherAt') or now),K,K.Saw and aimOf(player,ch:FindFirstChild('HumanoidRootPart')) or nil)
 end
 local weapon=player:GetAttribute('EquippedShovel');if not C[weapon or ''] then weapon=C.Order[1] end
 -- The swing is the coded spin - the whole body goes round with the weapon out (M.Sample). For a few hours on
 -- 2026-11-15 it was the animation pack's sword cut; the owner: "the player used to spin like Axe from Dota, and
 -- now the animation has come out clumsy" - so the spin is back.
 if now<(player:GetAttribute('RoadBatUntil') or 0) then
  return M.Sample('swing',(now-(player:GetAttribute('ShovelSwingAt') or now))/C.Swing,weapon)
 elseif player:GetAttribute('DiggingGrave') then
  return M.Sample('dig',(now-(player:GetAttribute('DigStartedAt') or now))/math.max(.1,player:GetAttribute('DigDuration') or 1.5))
 elseif player:GetAttribute('ActiveSlot')==1 then return M.Sample('ready',0,weapon) end
 return nil
end
return M
