"""Imp: angular quadrupedal pest. No blood, wounds, clothes or round white eyes."""
from kit import asset
RED='B3123F'; DARK='5C0A2E'; YELLOW='D7FF3E'; BLACK='1A0E1F'; TEETH='F4D878'
def build():
 a=asset('M_Imp')
 b=a.part('Body',attach='Body')
 b.sphere((0,.45,1.65),(.6,1.05,.73),RED,rot=(24,0,0),sub=2,smooth=False)
 b.sphere((0,.85,2.1),(.49,.62,.8),DARK,rot=(25,0,0),sub=1,smooth=False)
 for y,z in [(-.1,2.4),(.35,2.75),(.8,2.9),(1.2,2.55)]:
  b.cyl((0,y,z),.19,0,.65,BLACK,rot=(25,0,0),seg=5,smooth=False)
 for x,y,z in [(.48,.3,2),(-.44,.7,2.3),(.3,1.15,1.8)]: b.sphere((x,y,z),(.14,.18,.15),YELLOW,sub=1)
 h=a.part('Head',attach='Head',ao_dist=.5)
 h.prism([(-.85,-.5),(-1,.2),(-.62,.69),(.4,.72),(1,.16),(.73,-.58),(.1,-.78)],.9,RED,c=(0,-.72,2.02),bevel=.04,seg=1,smooth=False)
 # A huge dark maw and crooked rows of small yellow fangs. Cheek bulges are skin, not injuries.
 h.prism([(-.75,.25),(-.51,.4),(.62,.34),(.76,.03),(.43,-.55),(-.41,-.52),(-.78,-.18)],.12,BLACK,c=(0,-1.24,1.95),bevel=.02,seg=1)
 for i in range(7):
  x=-.58+i*.19
  h.cyl((x,-1.34,2.14+(i%2)*.035),.065,0,.26+(i%3)*.055,TEETH,rot=(180,(-1)**i*12,0),seg=4,smooth=False)
 for i in range(6): h.cyl((-.48+i*.18,-1.35,1.62),.055,0,.24+(i%2)*.08,TEETH,rot=(0,(-1)**i*15,0),seg=4,smooth=False)
 h.tube([(.25,-1.34,1.55,.12),(.55,-1.56,1.54,.1),(.72,-1.48,1.72,.035)],'F56C44',seg=5,sub=1)
 # Ragged ears, blunt little horns, slanted brow ridges.
 for s in [-1,1]:
  h.prism([(0,0),(.56,.48),(.43,.04),(.27,.12),(.18,-.24)],.13,DARK,c=(s*.72,-.6,2.4),rot=(0,s*8,0 if s==1 else 180),bevel=0,smooth=False)
  h.cyl((s*.56,-.45,2.94),.19,.025,.55,BLACK,rot=(0,s*24,0),seg=5,smooth=False)
  h.box((s*.4,-1.24,2.56),(.68,.17,.17),DARK,rot=(0,s*17,0),bevel=.025,seg=1)
 e=a.part('EyesGlow',attach='Head',material='Neon',ao=0,grad=0)
 for x,z,angle in [(-.47,2.47,-15),(.36,2.46,18),(.02,2.7,0)]:
  e.prism([(-.19,0),(0,.065),(.19,0),(0,-.045)],.04,YELLOW,c=(x,-1.36,z),rot=(0,angle,0),bevel=0,smooth=False)
 for s,name,scale in [(-1,'ArmL',.7),(1,'ArmR',1.15)]:
  p=a.part(name,attach=name)
  p.tube([(s*.45,-.15,2.1,.21*scale),(s*1.05,-.1,1.15,.17*scale),(s*1.22,-.95,.35,.23*scale)],RED,seg=5,sub=1,smooth=False)
  p.sphere((s*1.2,-1.05,.3),(.36*scale,.4,.23),DARK,sub=1,smooth=False)
  for dx in [-.22,0,.22]: p.tube([(s*1.2+dx,-1.25,.3,.1),(s*1.2+dx,-1.65,.12,.01)],BLACK,seg=4,sub=1,smooth=False)
 l=a.part('Legs',attach='Legs')
 for s in [-1,1]:
  l.tube([(s*.35,1.05,1.5,.23),(s*.65,1.45,.75,.18),(s*.65,.8,.18,.12)],RED,seg=5,sub=1,smooth=False)
  for dx in [-.12,.12]: l.cyl((s*.65+dx,.59,.14),.09,0,.35,BLACK,rot=(90,0,0),seg=4,smooth=False)
 t=a.part('Tail',attach='Tail')
 t.tube([(0,1.2,1.5,.17),(.45,1.9,1.1,.13),(.85,2.4,1.3,.09),(.65,2.65,1.8,.04)],DARK,seg=5,sub=1,smooth=False)
 t.cyl((.65,2.65,2),.22,0,.55,BLACK,seg=5,smooth=False)
