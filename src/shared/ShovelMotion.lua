-- One timeline drives the hand targets, tool orientation and body turn.
local C=require(script.Parent.Config.ShovelConfig)
local M={}
local function smooth(t) t=math.clamp(t,0,1);return t*t*(3-2*t) end
local ready=CFrame.new(1.25,-.25,-.9)*CFrame.Angles(0,0,math.pi)
local sweep=CFrame.new(1.1,.05,-1.3)*CFrame.Angles(0,0,math.pi/2)
local load=CFrame.new(.65,0,-1.2)*CFrame.Angles(-.1,0,.8)
local lift=CFrame.new(.65,.3,-1.25)*CFrame.Angles(-.3,0,.8)
local plant=CFrame.new(.65,-.45,-1.3)*CFrame.Angles(.08,0,.8)
local lever=CFrame.new(.65,-.2,-1.2)*CFrame.Angles(-.18,0,.8)
function M.Sample(kind,t)
 t=math.clamp(t or 0,0,1)
 local frame,spin,left,lean=ready,0,0,0
 if kind=='swing' then
  local extend=smooth(t/.2)*(1-smooth((t-.8)/.2))
  frame=ready:Lerp(sweep,extend);left=extend
  spin=math.pi*2*smooth((t-.18)/.62)
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
 return {frame=frame,spin=spin,left=left,lean=lean,kind=kind,phase=t}
end
function M.ForPlayer(player,now)
 local ch=player.Character;local h=ch and ch:FindFirstChildOfClass('Humanoid')
 if not h or h.Health<=0 or player:GetAttribute('Training') or now<(player:GetAttribute('KnockedOutUntil') or 0) then return nil end
 if now<(player:GetAttribute('RoadBatUntil') or 0) then
  return M.Sample('swing',(now-(player:GetAttribute('ShovelSwingAt') or now))/C.Swing)
 elseif player:GetAttribute('DiggingGrave') then
  return M.Sample('dig',(now-(player:GetAttribute('DigStartedAt') or now))/math.max(.1,player:GetAttribute('DigDuration') or 1.5))
 elseif player:GetAttribute('ActiveSlot')==1 then return M.Sample('ready',0) end
 return nil
end
return M
