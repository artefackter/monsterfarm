-- Deterministic cosmetic curves. Server timers remain the authority for ammunition.
local W={}
local function smooth(a,b,t) local x=math.clamp((t-a)/(b-a),0,1);return x*x*(3-2*x) end
function W.Sample(id,shotAge,reload)
 local t=math.max(0,shotAge or 100);local heavy=id=='AWP' or id=='Pump' or id=='Double';local pistol=id=='Deagle'
 local kick=(heavy and 1.25 or pistol and .8 or id=='AK' and .45 or .32)*math.exp(-t*(heavy and 9 or 20))*math.sin(math.min(t/.035,1)*math.pi/2)
 local bolt=heavy and (smooth(.16,.3,t)-smooth(.48,.64,t)) or math.max(0,1-t/.095)
 local lift=heavy and (smooth(.1,.2,t)-smooth(.6,.73,t)) or 0
 local mag=0;local tilt=0
 if reload then
  mag=smooth(.12,.32,reload)-smooth(.62,.82,reload)
  tilt=smooth(0,.16,reload)-smooth(.82,1,reload)
  bolt=math.max(bolt,(smooth(.83,.88,reload)-smooth(.92,.98,reload)))
 end
 return {kick=kick,bolt=bolt,boltLift=lift,magazine=mag,tilt=tilt}
end
function W.Step(model,id,shotAge,reload)
 local s=W.Sample(id,shotAge,reload);local main=model.PrimaryPart
 for _,j in main:GetChildren() do if j:IsA('Motor6D') then
  if j.Name=='MagazineJoint' then
   j.Transform=CFrame.new(0,-s.magazine*.85,s.magazine*.14)*CFrame.Angles(0,0,-s.magazine*.15)
  elseif j.Name=='BarrelsJoint' or j.Name=='ForegripJoint' then
   j.Transform=CFrame.Angles(-s.tilt*.55,0,0)
  elseif j.Name=='PumpJoint' then
   local cycle=smooth(.12,.3,shotAge or 100)-smooth(.4,.6,shotAge or 100)
   j.Transform=CFrame.new(0,0,cycle*.42)
  elseif j.Name=='BoltJoint' or j.Name=='SlideJoint' then
   j.Transform=CFrame.new(0,0,-s.bolt*(id=='AWP' and .38 or .2))*CFrame.Angles(0,0,s.boltLift*.75)
  end
 end end
 model:SetAttribute('VisualBolt',s.bolt);model:SetAttribute('VisualMagazine',s.magazine)
 return s
end
return W
