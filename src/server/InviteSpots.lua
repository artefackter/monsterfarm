-- A farm nobody lives on invites company: at its gate floats "Free farm - invite a friend" with a prompt that
-- opens Roblox's own invite window (client: HelpController). The marker goes away the moment someone moves in.
local P=require(script.Parent.PlotService)
local I={Signs={}}
local function build(plot)
 local q=Instance.new("Part");q.Name="InviteSpot";q.Size=Vector3.new(1,1,1);q.Transparency=1;q.Anchored=true;q.CanCollide=false;q.CanQuery=false;q.CanTouch=false
 q.CFrame=plot.Gate.CFrame*CFrame.new(0,5,0);q.Parent=plot.Model
 local pr=Instance.new("ProximityPrompt");pr.Name="InviteFriend";pr.ActionText="Invite a friend";pr.ObjectText="Free farm";pr.HoldDuration=0;pr.MaxActivationDistance=16;pr.RequiresLineOfSight=false;pr.Parent=q
 return q
end
function I.Init()
 task.spawn(function()
  while true do
   for _,plot in ipairs(P.Plots) do
    local sign=I.Signs[plot]
    if not plot.Owner and plot.Gate and not (sign and sign.Parent) then I.Signs[plot]=build(plot)
    elseif plot.Owner and sign then sign:Destroy();I.Signs[plot]=nil end
   end
   task.wait(2)
  end
 end)
end
return I
