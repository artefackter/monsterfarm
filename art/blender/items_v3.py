"""Original stylized firearms/tools, not real engineering models.
Each moving component has a separate named mesh; grip/muzzle/joint anchors export
with the pack for procedural animation. Authoring front -Y, up +Z.
"""
import math
from kit import asset
from assets_v3 import box,anchor,INK,GOLD,PURPLE,TEAL,WOOD,STONE
STEEL='9CAAB8'; DARK='29323F'; EDGE='D2DAE2'; WALNUT='985E36'; OLIVE='526E53'
def part(a,name):return a.part(name,ao=.3,ao_dist=.12,grad=.04)
def barrel(q,y0,y1,z,r=.09,col=DARK):
 q.cyl((0,(y0+y1)/2,z),r,r,abs(y1-y0),col,rot=(90,0,0),seg=12,bevel=.015)
 q.cyl((0,y0-.008,z),r*.62,r*.62,.018,'111925',rot=(90,0,0),seg=12)
def screw(q,x,y,z):q.cyl((x,y,z),.04,.04,.015,EDGE,rot=(0,90,0),seg=6)
def trigger(q,y=.3,z=-.24):
 # Open trigger guard with a distinct curved trigger inside.
 q.tube([(0,y+.16,z+.1,.035),(0,y+.18,z-.3,.035),(0,y-.22,z-.35,.035),(0,y-.3,z-.12,.035),(0,y-.26,z+.12,.035)],DARK,seg=6,sub=2)
 q.tube([(0,y-.06,z+.05,.025),(0,y-.1,z-.13,.025),(0,y+.01,z-.18,.025)],STEEL,seg=6,sub=2)
def grip(q,y,z,col=DARK):
 box(q,(0,y,z),(.3,.4,.65),col,.055,rot=(12,0,0))
 for h in [-.2,-.08,.04,.16]:
  box(q,(0,y-.21,z+h),(.31,.035,.03),'58626C',.008,rot=(12,0,0))
def deagle():
 a=asset('V3_GunDeagle');body=part(a,'Main');slide=part(a,'Slide');mag=part(a,'Magazine')
 box(body,(0,-.25,.07),(.36,1.18,.29),STEEL,.045)
 grip(body,.3,-.38);trigger(body,.02,-.1)
 # Sloped upper slide gives the heavy pistol its recognizable silhouette.
 slide.prism([(-.23,-.08),(.23,-.08),(.23,.13),(.15,.23),(-.15,.23),(-.23,.13)],1.45,EDGE,c=(0,-.38,.25),rot=(0,0,0),bevel=.025)
 for side in [-1,1]:
  for y in [.04,.14,.24]:box(slide,(side*.238,y,.3),(.018,.035,.19),DARK,.005,rot=(0,0,-12))
  box(body,(side*.19,.28,-.37),(.035,.31,.38),DARK,.02)
  screw(body,side*.215,.24,-.27)
 barrel(body,-1.15,-.35,.15,.115)
 box(slide,(0,-.96,.51),(.08,.12,.1),DARK,.01)
 for x in [-.12,.12]:box(slide,(x,.22,.5),(.08,.16,.1),DARK,.01)
 box(mag,(0,.33,-.54),(.25,.32,.42),DARK,.025);box(mag,(0,.39,-.79),(.34,.45,.09),STEEL,.02)
 anchor(a,'Grip',(0,.3,-.12));anchor(a,'Muzzle',(0,-1.17,.15));anchor(a,'SlideAxis',(0,1,0));anchor(a,'MagazinePivot',(0,.33,-.54))

def rifle(kind):
 a=asset('V3_Gun'+kind);main=part(a,'Main');mag=part(a,'Magazine');bolt=part(a,'Bolt');stock=part(a,'Stock')
 ak=kind=='AK';sniper=kind=='AWP';col=WALNUT if ak else OLIVE if sniper else '586A67'
 front=-2.3 if sniper else -1.75
 box(main,(0,-.1,.1),(.34,1.35,.36),DARK,.04)
 box(main,(0,-.18,.33),(.3,1.2,.13),STEEL if ak else DARK,.04)
 grip(main,.34,-.4,col if sniper else DARK);trigger(main,.05,-.12)
 # Stock cheekpiece, buffer tube, buttpad; the silhouette is readable at mobile scale.
 barrel(stock,.48,1.3,.1,.12)
 stock.prism([(-.12,-.28),(.12,-.28),(.17,.28),(-.17,.28)],.75,col,c=(0,1.1,.08),bevel=.06)
 box(stock,(0,1.48,.02),(.42,.16,.65),DARK,.04)
 box(stock,(0,1.05,.25),(.37,.62,.17),col,.035)
 if ak:
  box(main,(0,-.88,.12),(.43,.62,.37),WALNUT,.065)
  barrel(main,front,-1.03,.13,.085)
  barrel(main,-1.4,-.62,.31,.065,STEEL)
  for y in [-.76,-.9,-1.04]:box(main,(0,y,.34),(.35,.045,.04),DARK,.008)
  # Curved magazine, not a single angled block.
  rings=[]
  for z,y in [(-.04,-.26),(-.27,-.25),(-.5,-.18),(-.72,-.05),(-.83,.06)]:rings.append([(-.13,y-.23,z),(.13,y-.23,z),(.13,y+.23,z),(-.13,y+.23,z)])
  mag.loft(rings,DARK,smooth=False)
  for s in [-1,1]:
   for z,y in [(-.27,-.25),(-.5,-.18),(-.7,-.05)]:box(mag,(s*.136,y,z),(.025,.3,.035),STEEL,.008)
 elif sniper:
  box(main,(0,-.73,-.04),(.44,1.25,.32),OLIVE,.065)
  barrel(main,front,-1.23,.18,.105)
  for y in [-1.2,-1.05,-.9]:box(main,(0,y,-.2),(.3,.07,.06),DARK,.008)
  box(mag,(0,-.1,-.27),(.28,.44,.32),DARK,.025)
  scope=part(a,'Scope')
  for y in [-.65,.2]:box(scope,(0,y,.5),(.2,.18,.3),DARK,.02)
  barrel(scope,-1.0,.5,.72,.13,DARK)
  for y in [-.94,.44]:scope.cyl((0,y,.72),.22,.22,.3,DARK,rot=(90,0,0),seg=16)
  scope.cyl((0,-1.1,.72),.17,.17,.02,TEAL,rot=(90,0,0),seg=16)
  scope.cyl((0,-.2,.93),.1,.1,.15,STEEL,seg=10)
  # Folding decorative bipod, separate ready for future poses.
  bipod=part(a,'Bipod')
  for side in [-1,1]:box(bipod,(side*.23,-1.12,-.36),(.08,.1,.65),DARK,.02,rot=(0,side*25,0))
 else:
  box(main,(0,-.9,.16),(.42,.9,.4),col,.055)
  barrel(main,front,-1.25,.15,.08)
  for y in [-1.22,-1.07,-.92,-.77,-.62]:
   box(main,(0,y,.4),(.35,.07,.09),DARK,.015)
   for side in [-1,1]:box(main,(side*.218,y,.16),(.025,.08,.16),INK,.01)
  box(mag,(0,-.28,-.43),(.28,.42,.68),DARK,.03,rot=(-8,0,0))
  for z in [-.25,-.43,-.61]:box(mag,(0,-.51,z),(.23,.035,.045),STEEL,.008)
  # Small open reflex sight with transparent-looking teal pane, no oversized blaster chamber.
  sight=part(a,'Sight');box(sight,(0,-.1,.55),(.32,.3,.06),DARK,.01)
  for side in [-1,1]:box(sight,(side*.16,-.1,.7),(.06,.2,.3),DARK,.01)
  box(sight,(0,-.1,.86),(.35,.2,.06),DARK,.01);box(sight,(0,-.12,.7),(.24,.025,.23),'759A9D',.01)
 # Ejection port and charging handle are separate from the receiver.
 box(main,(.18,-.08,.2),(.02,.45,.16),'111925',.01)
 box(bolt,(.2,-.04,.2),(.06,.3,.12),STEEL,.01)
 box(bolt,(.3,.05,.17),(.24,.1,.08),DARK,.015)
 if sniper:bolt.sphere((.44,.05,.13),.09,DARK,sub=2)
 if not sniper:
  box(main,(0,front+.12,.34),(.09,.12,.3),DARK,.01)
  for x in [-.08,.08]:box(main,(x,.39,.46),(.06,.12,.1),DARK,.01)
 for side in [-1,1]:
  for y in [-.42,.28]:screw(main,side*.18,y,.12)
 anchor(a,'Grip',(0,.3,-.12));anchor(a,'SupportHand',(0,-.9,-.12));anchor(a,'Muzzle',(0,front-.02,.18 if sniper else .13 if ak else .15));anchor(a,'BoltPivot',(.2,-.04,.2));anchor(a,'MagazinePivot',(0,-.2,-.3))


def shovel(id,index,col):
 a=asset('V3_Shovel'+id);h=part(a,'Handle');b=part(a,'Blade');orn=part(a,'Details')
 shaftcol='D9C6A8' if id=='Bone' else '665271' if index>=5 else WALNUT
 h.cyl((0,0,.05),.09,.09,2.7,shaftcol,seg=10)
 for x in [-.29,.29]:box(h,(x,0,1.48),(.12,.15,.55),col,.035)
 box(h,(0,0,1.77),(.7,.2,.16),DARK if index<3 else col,.055)
 box(h,(0,0,1.21),(.65,.15,.12),col,.025)
 for z in [.1,.22,.34,.46]:h.torus((0,0,z),.092,.016,DARK,seg=10,rseg=4)
 # Concave stylized spade with separate raised ribs and sharpened visual lip.
 w=.57+index*.025
 poly=[(-w,.35),(w,.35),(w*.95,-.25),(w*.65,-.7),(0,-.95),(-w*.65,-.7),(-w*.95,-.25)]
 b.prism(poly,.14,col,c=(0,0,-1.42),bevel=.04,seg=2,smooth=True)
 b.prism([(x*.9,z*.9) for x,z in poly],.03,'6D5141' if id=='Rusty' else '7F91A4' if id=='Steel' else col,c=(0,-.095,-1.42),bevel=.02)
 for side in [-1,1]:orn.tube([(0,-.12,-1.1,.025),(side*w*.4,-.12,-1.55,.025),(side*w*.65,-.12,-1.95,.015)],EDGE if index<3 else GOLD,seg=5,sub=2)
 h.cyl((0,0,-1.02),.16,.12,.5,col,seg=10)
 if id=='Rusty':
  for x,z in [(-.25,-1.4),(.2,-1.7),(-.05,-2.1)]:orn.sphere((x,-.13,z),(.1,.015,.14),'B46C39',sub=1,smooth=False)
 elif id=='Combat':
  for side in [-1,1]:
   for z in [-1.2,-1.4,-1.6]:box(orn,(side*.61,0,z),(.12,.2,.08),EDGE,.015)
 elif id=='Bone':
  orn.sphere((0,-.18,-1.4),(.23,.12,.23),'FFF0CF',sub=2)
  for x in [-.085,.085]:orn.sphere((x,-.28,-1.37),(.05,.03,.07),INK,sub=1)
 elif id=='Golden':
  orn.prism([(-.25,0),(0,.28),(.25,0),(0,-.28)],.08,'62D6C0',c=(0,-.15,-1.6),bevel=.015)
 elif id=='Lunar':orn.torus((0,-.2,-1.55),.27,.06,'C9EFFF',rot=(90,0,0),seg=16,rseg=5)
 elif id=='Rainbow':
  for i,cc in enumerate(['F877A7','FFBB55','E6EC69','61DAB0','65ABEF','AD7CE5']):
   box(orn,(-.38+i*.15,-.13,-1.55),(.13,.035,.7),cc,.02)
 anchor(a,'Grip',(0,0,0));anchor(a,'BladeTip',(0,0,-2.4))

def trap():
 a=asset('V3_Trap');base=part(a,'Base');plate=part(a,'Plate');light=part(a,'Light')
 box(base,(0,0,.15),(4.6,4.6,.3),DARK,.15)
 for x in [-1.8,1.8]:
  for y in [-1.8,1.8]:base.cyl((x,y,.33),.14,.14,.12,STEEL,seg=8)
 plate.cyl((0,0,.37),1.28,1.28,.18,GOLD,seg=16,bevel=.04)
 for i in [-1,0,1]:box(plate,(i*.4,0,.47),(.12,1.5,.04),WALNUT,.01)
 for side,name in [(-1,'JawL'),(1,'JawR')]:
  jaw=part(a,name)
  box(jaw,(side*1.95,0,.48),(.36,4,.4),STEEL,.09)
  for y in [-1.5,-.5,.5,1.5]:
   jaw.prism([(0,0),(.6,0),(.4,.35),(.2,.35)],.42,EDGE,c=(side*1.65,y,.55),rot=(0,0,0 if side==-1 else 180),bevel=.04)
  for y in [-1.8,1.8]:base.cyl((side*1.9,y,.45),.25,.25,.45,STEEL,rot=(90,0,0),seg=10)
  anchor(a,name+'Pivot',(side*1.95,0,.48))
 light.sphere((0,-1.8,.4),(.18,.18,.12),GOLD,sub=2)
 anchor(a,'Ground',(0,0,0))

def build():
 deagle()
 for name in ['AK','M4','AWP']:rifle(name)
 for i,(name,col) in enumerate([('Rusty','997657'),('Steel',STEEL),('Combat',OLIVE),('Bone','E5D4B3'),('Golden',GOLD),('Lunar','B8A0F7'),('Rainbow','F98BC7')]):shovel(name,i,col)
 trap()
