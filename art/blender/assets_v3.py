"""Approved v3 palette. Original low-poly environment; units=studs, Z up.
Visual meshes never define collision implicitly. COLLIDERS and ANCHORS are exported
separately so doors, stairs, animation joints and UI surfaces stay intentional.
"""
import math, random
from kit import asset
CREAM='F3D7AA'; CREAM2='DAB98A'; PURPLE='713999'; LILAC='A65DC2'; INK='342641'
WOOD='DC9B39'; WOOD2='A86B2D'; TEAL='37C8CB'; GOLD='FFD456'; GREEN='70CC38'; SOIL='774738'; STONE='A6ADC8'
COLLIDERS={}; ANCHORS={}
def p(a,name='Main',**kw): return a.part(name,ao=.2,ao_dist=.6,grad=.025,**kw)
def box(q,c,s,col,bevel=.06,rot=(0,0,0)):
 return q.box(c,s,col,bevel=bevel,seg=1,smooth=False,rot=rot)
def solid(a,q,name,c,s,col,bevel=.06):
 box(q,c,s,col,bevel);COLLIDERS.setdefault(a.name,[]).append({'name':name,'center':c,'size':s})
def anchor(a,name,c): ANCHORS.setdefault(a.name,{})[name]=c

def window(q,x,y,z,w=4,h=4):
 box(q,(x,y,z),(w+.6,.5,h+.6),PURPLE)
 box(q,(x,y-.3,z),(w,.12,h),TEAL,.02)
 box(q,(x,y-.4,z),(.22,.2,h),PURPLE,.01);box(q,(x,y-.4,z),(w,.2,.22),PURPLE,.01)
 box(q,(x,y-.4,z-h/2-.35),(w+1,1,.45),LILAC)

def lantern(q,x,y,z,k=1):
 box(q,(x,y,z),(1*k,.8*k,1.4*k),GOLD)
 for dx in [-.52,.52]:box(q,(x+dx*k,y-.45*k,z),(.13*k,.16*k,1.65*k),PURPLE,.02)
 for dz in [-.8,.8]:box(q,(x,y,z+dz*k),(1.3*k,1*k,.25*k),PURPLE)

def roof(q,w,d,z,offset=(0,0)):
 # Thin hollow roof strips, never a solid wedge filling the attic.
 ox,oy=offset; steps=7; run=w/2/steps
 for side in [-1,1]:
  for i in range(steps):
   x=side*(w/2-run*(i+.5));h=z+i*.85
   box(q,(x+ox,oy,h),(run+.15,d,1.05),PURPLE if i%2 else LILAC,.09)
 box(q,(ox,oy,z+steps*.85-.6),(1.4,d+.35,.85),PURPLE,.12)

def house(level):
 a=asset('V3_House'+str(level));floor=p(a,'Floor');walls=p(a,'Walls');trim=p(a,'Trim');r=p(a,'Roof')
 solid(a,floor,'Floor',(0,0,.3),(48,36,.6),CREAM2,.12)
 # Door is 12 studs wide x 10.4 high, open through the entire facade.
 solid(a,walls,'Back',(0,17.5,6.6),(48,1,12),CREAM)
 for x in [-23.5,23.5]:solid(a,walls,'Side'+str(x),(x,0,6.6),(1,34,12),CREAM)
 for side in [-1,1]:solid(a,walls,'Front'+str(side),(side*15,-17.5,6.6),(18,1,12),CREAM)
 solid(a,walls,'Lintel',(0,-17.5,11.8),(12,1,1.6),CREAM)
 for x in [-6.4,6.4]:box(trim,(x,-18.1,5.7),(.8,1.1,10.2),PURPLE,.1)
 box(trim,(0,-18.1,10.9),(13.6,1.1,.8),PURPLE,.1)
 for x in [-15,15]:window(trim,x,-18,7,5,4.5);lantern(trim,x/1.7,-18.7,8,.8)
 # Continuous chunky belt courses, plus sparse original recessed-looking tile inlays.
 for x in [-23.5,23.5]:box(trim,(x,0,1),(1.3,36,.7),PURPLE)
 for y in [-17.7,17.7]:
  for side in [-1,1]:box(trim,(side*15,y,1),(18,1.1,.7),PURPLE)
 for x in [-21,-18,-12,-9,9,12,18,21]:
  for z in [3,5,9]:box(trim,(x,-18.03,z),(1.1,.04,.65),CREAM2,.025)
 # Portraits are simple geometric family portraits, not copied images.
 for x,col in [(-14,'98CF67'),(14,'77C6D9')]:
  box(trim,(x,16.9,7),(4.4,.25,5.2),GOLD);box(trim,(x,16.7,7),(3.8,.1,4.5),PURPLE)
  box(trim,(x,16.59,7.4),(2.4,.1,2.4),col,.2)
  for dx in [-.55,.55]:box(trim,(x+dx,16.48,7.7),(.55,.13,.7),'FFFFFF',.08)
 anchor(a,'Entry',(0,-18,.6));anchor(a,'DoorOpening',(12,0,10.4));anchor(a,'Light',(0,0,10.5))
 if level>=2:
  porch=p(a,'Porch');solid(a,porch,'Porch',(0,-21,.3),(31,7,.6),CREAM2)
  for x in [-14,14]:solid(a,porch,'PorchPost'+str(x),(x,-23.2,5.7),(1,1,10.2),WOOD)
  box(porch,(0,-21.5,11),(32,7,1),PURPLE,.15)
 if level>=3:
  upper=p(a,'Upper');stairs=p(a,'Stairs');rails=p(a,'Rails')
  # Stairwell at left side; floor omitted there. 24 half-stud risers, 1 stud tread.
  solid(a,upper,'UpperFloor',(3,0,12.8),(40,34,.6),CREAM2)
  solid(a,upper,'UpperLanding',(-20,13,12.8),(6,8,.6),CREAM2)
  for i in range(24):
   h=(i+1)*.5;solid(a,stairs,'Step%02d'%i,(-20,-13+i,h/2+.6),(5.8,1.02,h),WOOD,.025)
  for side in [-1,1]:solid(a,upper,'UpperSide'+str(side),(side*23.5,0,18.6),(1,34,11),CREAM)
  solid(a,upper,'UpperBack',(0,17.5,18.6),(48,1,11),CREAM)
  for side in [-1,1]:solid(a,upper,'UpperFront'+str(side),(side*15,-17.5,18.6),(18,1,11),CREAM)
  solid(a,upper,'UpperLintel',(0,-17.5,23),(12,1,2),CREAM)
  for x in [-15,15]:window(upper,x,-18,19,5,4.5)
  solid(a,upper,'Balcony',(0,-21,12.7),(31,7,.6),CREAM2)
  for x in [-15,15]:solid(a,rails,'BalconySide'+str(x),(x,-21,14.6),(.5,7,3),PURPLE)
  solid(a,rails,'BalconyFront',(0,-24,14.6),(30,.5,3),PURPLE)
  # Stairwell guard keeps upper-floor users from falling back into the opening.
  solid(a,rails,'StairGuard',(-17.1,-2,14.5),(.35,23,2.8),WOOD)
  roof(r,51,39,24.3)
 else: roof(r,51,39,13)
 if level>=4:
  tower=p(a,'Tower');x=17;y=10;z0=25 if level>=3 else 13
  box(tower,(x,y,z0+3.5),(10,10,8),CREAM,.15)
  for dz,s in [(8,12),(9,10),(10,8),(11,6),(12,4)]:box(tower,(x,y,z0+dz),(s,s,1.4),PURPLE,.12)
  window(tower,x,y-5.1,z0+4,4,4)
  box(tower,(x,y,z0+15),(.2,.2,5),GOLD);box(tower,(x+1.8,y,z0+16),(3.5,.12,1.8),GOLD)
 if level==5:
  castle=p(a,'CastleTrim')
  for x in [-21,21]:
   box(castle,(x,-12,15),(7,7,30),CREAM,.15)
   for i in range(4):box(castle,(x,-12,30+i),(9-i*1.4,9-i*1.4,1.3),PURPLE,.12)
   for z in [7,19,26]:window(castle,x,-15.6,z,2.4,3.4)
  for x in range(-18,19,4):box(castle,(x,-18.2,25),(2.2,1.8,2.2),GOLD,.08)
  for x in [-8,8]:box(castle,(x,-18.6,20),(1.4,.2,5),TEAL)
 # Close both stepped gables. Thin front/back infill leaves a genuinely hollow house.
 zbase=24.3 if level>=3 else 13
 for y in [-17.55,17.55]:
  for side in [-1,1]:
   for i in range(7):
    width=48/14;top=zbase+i*.85-.25;bottom=zbase-.6
    box(walls,(side*(24-width*(i+.5)),y,(top+bottom)/2),(width+.02,.9,top-bottom),CREAM,.015)
 window(trim,0,-18.08,zbase+1.9,3.3,2.7)
 box(r,(-16,10,zbase+4),(3,3,7),CREAM2,.1)
 box(r,(-16,10,zbase+7.7),(3.8,3.8,.8),PURPLE,.08)
 for z in [zbase+2,zbase+4,zbase+6]:box(r,(-16,8.46,z),(3,.06,.16),CREAM,.01)
 # Visible interior hanging light; actual PointLight is created at exported anchor.
 box(trim,(0,1,11),(.18,.18,1.8),PURPLE,.02)
 lantern(trim,0,1,9.9,1.3)
 anchor(a,'InteriorLight',(0,1,9.8))
 anchor(a,'Bounds',(52,48,45 if level==5 else 43 if level==4 else 33 if level==3 else 22))


def treadmill(level):
 a=asset('V3_Treadmill'+str(level));q=p(a,'Frame');belt=p(a,'Belt');roll=p(a,'Rollers');console=p(a,'Console');arrows=p(a,'Arrows',material='Neon')
 col=[STONE,TEAL,PURPLE,GOLD,'E57FC4'][level-1]
 box(q,(0,0,.4),(8.5,15,.8),INK,.12)
 box(belt,(0,0,1.5),(6.4,13,.2),'263744',.04)
 for x in [-3.8,3.8]:
  box(q,(x,0,1.1),(.9,14.8,1.5),col,.12)
  box(q,(x,-4.8,4.2),(.65,.8,6.8),col,.08,rot=(0,10 if x<0 else -10,0))
  box(q,(x,-2.4,5.2),(.65,5.8,.65),col,.08)
 for y in [-6.5,6.5]:roll.cyl((0,y,1.2),.44,.44,6.8,'7D8B98',rot=(0,90,0),seg=12)
 box(console,(0,-5.2,7.2),(7.5,2.7,.7),col,.12,rot=(16,0,0))
 box(console,(0,-5.7,7.55),(3.4,1.6,.08),INK,.05,rot=(16,0,0))
 for i in range(level):box(console,(-1.2+i*.6,-5.7,7.64),(.35,1,.08),TEAL,.02,rot=(16,0,0))
 for x in [-2.6,2.6]:box(console,(x,-5.7,7.6),(.5,.5,.15),GOLD,.1)
 for y in [-4,0,4]:
  for s in [-1,1]:box(arrows,(s*.7,y,1.63),(1.8,.25,.025),TEAL,.01,rot=(0,0,s*35))
 for i in range(level-1):
  for s in [-1,1]:box(q,(s*4.35,-4+i*2,1.6),(.15,.65,.65),GOLD,.04)
 anchor(a,'BeltCenter',(0,0,1.6));anchor(a,'Console',(0,-5.6,7.7));anchor(a,'TrainingSize',(6.4,13,0))


def stall(kind,col):
 a=asset('V3_Stall'+kind);q=p(a);roofpart=p(a,'Canopy')
 box(q,(0,0,.3),(11,7,.6),STONE)
 for x in [-4.5,4.5]:
  for y in [-2.5,2.5]:box(q,(x,y,4),( .55,.55,8),WOOD2)
 box(q,(0,-2.5,2.2),(9.6,.5,3.2),WOOD)
 box(q,(0,-2.5,3.9),(11,2,.55),CREAM)
 for x in [-4,-2,0,2,4]:box(q,(x,-2.8,2.2),(.12,.06,2.5),WOOD2,.01)
 for i in range(8):
  x=-5.25+i*1.5;cc=col if i%2==0 else 'FFF1CE'
  box(roofpart,(x,0,8.6),(1.5,8,.45),cc,.04,rot=(8,0,0))
  box(roofpart,(x,-4,7.95),(1.5,.2,1),cc,.04)
 box(q,(0,2.7,6),(7,.35,1.4),PURPLE)
 anchor(a,'Vendor',(0,1.3,.6));anchor(a,'Title',(0,-4.2,9.8));anchor(a,'Zone',(0,-7.5,0))
 # Simple bespoke shop emblems (crossed tools / leaf / ammo rack).
 if kind=='Weapons':
  for x in [-2,0,2]:box(q,(x,2.4,4.7),(.45,.4,2.3),INK,.04,rot=(0,0,18));box(q,(x,2.2,3.9),(.8,.6,.7),STONE)
 elif kind=='Pets':
  for x in [-2,0,2]:box(q,(x,-2.4,4.6),(1.1,1,1.2),'F7A33E',.22);box(q,(x,-2.4,5.3),(.2,.2,.3),GREEN)
 else:
  for x in [-2,2]:box(q,(x,2.2,5),(.25,.25,3),WOOD,.04);box(q,(x,2.1,6.3),(1.2,.2,1.3),STONE,.12)


def chest(name,col):
 a=asset('V3_'+name);b=p(a,'Base');lid=p(a,'Lid');glow=p(a,'Glow',material='Neon')
 box(b,(0,0,.3),(7.2,5,.6),STONE,.12);box(b,(0,0,1.9),(6,4,2.8),col,.18)
 for x in [-2.4,2.4]:box(b,(x,0,2),(.4,4.2,3),GOLD,.06)
 box(b,(0,-2.15,2),(1.15,.3,1.4),GOLD,.08);box(b,(0,-2.33,2),(.22,.06,.6),INK,.03)
 for i,(w,z) in enumerate([(6,3.45),(5.6,3.95),(4.5,4.45),(2.6,4.8)]):
  box(lid,(0,0,z),(w,4,.55),col if i%2 else TEAL,.09)
  for x in [-2.4,2.4]:
   if abs(x)<w/2:box(lid,(x,0,z+.05),(.4,4.15,.6),GOLD,.05)
 box(glow,(0,-2.1,3.25),(4,.08,.12),TEAL,.01)
 anchor(a,'LidPivot',(0,1.9,3.2));anchor(a,'Label',(0,-2.8,1));anchor(a,'Zone',(0,0,0))


def furnishings():
 a=asset('V3_UpgradeBoard');q=p(a)
 for x in [-2.5,2.5]:box(q,(x,0,1.7),(.55,.55,3.4),PURPLE)
 box(q,(0,0,4.4),(7,.6,4.4),GOLD,.14);box(q,(0,-.35,4.4),(6.4,.08,3.7),PURPLE,.06)
 anchor(a,'Surface',(0,-.41,4.4));anchor(a,'SurfaceSize',(6.4,0,3.7))
 a=asset('V3_QuestBoard');q=p(a)
 for x in [-3.2,3.2]:box(q,(x,0,3),(.65,.8,6),WOOD2)
 box(q,(0,0,5),(8,.7,6),PURPLE,.14);box(q,(0,-.4,5),(7.2,.12,5.2),CREAM,.06)
 for x,z,col in [(-1.8,5.8,TEAL),(1.6,5.4,GOLD),(-1.2,3.6,'F099B9')]:
  box(q,(x,-.5,z),(2.5,.08,1.8),col,.02,rot=(0,-5,0));box(q,(x,-.6,z+.65),(.16,.1,.16),INK,.02)
 anchor(a,'Surface',(0,-.65,5))
 a=asset('V3_MergeTable');q=p(a);glow=p(a,'Glow',material='Neon')
 for x in [-4.4,4.4]:
  for y in [-2,2]:box(q,(x,y,1.8),(.8,.8,3.6),WOOD2)
 box(q,(0,0,3.6),(11,6,.7),WOOD,.12);box(q,(0,0,2),(9,4,1.2),PURPLE,.1)
 for x in [-3.4,0,3.4]:box(q,(x,0,4),(2.8,3.2,.2),PURPLE);box(glow,(x,0,4.13),(2.3,2.7,.04),TEAL,.04)
 box(q,(0,2.1,5),(.3,.3,2.2),GOLD);q.sphere((0,2.1,6.2),.6,TEAL,sub=2)
 anchor(a,'Zone',(0,-4,0))
 a=asset('V3_CoffinRack');q=p(a)
 box(q,(0,0,.2),(16.8,2.3,.4),PURPLE)
 for x in [-5,0,5]:
  poly=[(-1.2,0),(1.2,0),(1.8,4.5),(1,6.8),(-1,6.8),(-1.8,4.5)]
  q.prism(poly,1.6,WOOD2,c=(x,0,.4),bevel=.09,smooth=False)
  q.prism([(u*.85,v*.92) for u,v in poly],.12,PURPLE,c=(x,-.87,.6),bevel=.05,smooth=False)
  box(q,(x,-.98,4.3),(.9,.1,1.1),GOLD,.06)
  for z in [1.6,5]:box(q,(x,-1,z),(2.2,.12,.18),WOOD)


def world():
 a=asset('V3_Fence');q=p(a)
 for z in [1.3,2.8]:box(q,(0,0,z),(8,.45,.65),WOOD)
 for x in [-3,0,3]:box(q,(x,0,2),(.55,.6,3.7),WOOD,.06)
 a=asset('V3_FencePost');q=p(a);box(q,(0,0,2),(1.4,1.4,4),STONE);box(q,(0,0,4.15),(1.9,1.9,.6),PURPLE)
 a=asset('V3_GateArch');q=p(a)
 for x in [-8,8]:box(q,(x,0,4.5),(1.6,1.6,9),STONE);box(q,(x,0,9.1),(2.1,2.1,.7),PURPLE)
 box(q,(0,0,8),(15,1.2,1.6),WOOD);box(q,(0,-.7,8),(10,.14,1.4),PURPLE)
 anchor(a,'NamePlate',(0,-.8,8));anchor(a,'Opening',(14.4,0,7.2))
 a=asset('V3_RoadArch');q=p(a)
 for x in [-49,49]:box(q,(x,0,10),(4,4,20),STONE,.15);box(q,(x,0,20),(5,5,1),PURPLE)
 box(q,(0,0,20),(102,4,4),PURPLE,.15);box(q,(0,-2.1,20),(30,.3,3),GOLD)
 anchor(a,'Title',(0,-2.4,20));anchor(a,'Opening',(94,0,18))
 a=asset('V3_Wall');q=p(a);box(q,(0,0,12),(24,2,24),CREAM2,.06);box(q,(0,0,24),(24.2,2.6,1),PURPLE)
 for x in [-11,11]:box(q,(x,-1.1,12),(1.2,.6,24),PURPLE)
 for z in [4,10,16,22]:box(q,(0,-1.02,z),(22,.04,.09),CREAM,.01)
 for name,variant in [('Tree',0),('TreeTall',1),('Bush',2)]:
  a=asset('V3_'+name);q=p(a)
  if variant<2:box(q,(0,0,3),(1.5,1.5,6),WOOD2,.1)
  for i,(x,y,z,s) in enumerate([(-1.8,0,6,3.4),(1.7,0,6.6,3.2),(0,0,9,4),(0,1.8,7.3,3.3),(0,-1.4,7.1,3)]):
   k=.5 if variant==2 else 1;zz=(z-5)*k if variant==2 else z*(1.3 if variant==1 else 1)
   box(q,(x*k,y*k,zz),(s*k,s*k,s*k),['75CC34','91DD40','51AD39'][i%3],.1)
 a=asset('V3_Rock');q=p(a)
 for c,s,col in [((0,0,.6),(3,2.6,1.2),STONE),((-.5,0,1.6),(2,2,1), '8991AD'),((.6,-.7,1.3),(1.4,1.2,1.5),'BCC2D6')]:box(q,c,s,col,.15)
 a=asset('V3_Lantern');q=p(a);box(q,(0,0,3),(.5,.5,6),PURPLE);box(q,(0,0,.2),(1.2,1.2,.4),STONE);lantern(q,0,0,6.8,1.1);anchor(a,'Light',(0,0,6.8))
 a=asset('V3_Bed');q=p(a);box(q,(0,0,.14),(5.8,5.8,.28),SOIL)
 for x in [-3,3]:box(q,(x,0,.35),(.35,6.3,.7),WOOD2)
 for y in [-3,3]:box(q,(0,y,.35),(6.3,.35,.7),WOOD2)
 a=asset('V3_GraveBorder');q=p(a)
 for x in [-2.2,2.2]:box(q,(x,0,.25),(.3,6,.5),STONE)
 for y in [-2.8,2.8]:box(q,(0,y,.25),(4.4,.3,.5),STONE)
 a=asset('V3_PathTile');q=p(a);box(q,(0,0,-.12),(8,8,.24),CREAM2,.05)
 for x in [-2,2]:
  for y in [-2,2]:box(q,(x,y,.06),(3.87,3.87,.13),CREAM,.035)
 a=asset('V3_Bench');q=p(a)
 for x in [-2.5,2.5]:box(q,(x,0,1),(.5,2.4,2),PURPLE)
 for y in [-.8,0,.8]:box(q,(0,y,2.1),(7,.65,.35),WOOD)
 for z in [2.8,3.6]:box(q,(0,1,z),(7,.45,.55),WOOD)
 a=asset('V3_Barricade');q=p(a)
 for x in [-3,3]:box(q,(x,0,1.5),(.5,2,3),WOOD2)
 for z in [1.5,2.8]:box(q,(0,0,z),(8,.4,.8),GOLD)
 for x in [-3,-1,1,3]:box(q,(x,-.24,2.8),(.55,.05,.8),INK,.01,rot=(0,15,0))
 a=asset('V3_Crates');q=p(a)
 for x,y,z in [(-1.4,0,1.2),(1.4,0,1.2),(-1.4,0,3.6)]:
  box(q,(x,y,z),(2.5,2.5,2.4),WOOD,.08)
  for dz in [-.9,.9]:box(q,(x,y-1.28,z+dz),(2.4,.12,.22),WOOD2,.02)
  box(q,(x,y-1.3,z),(.25,.12,2.4),WOOD2,.02,rot=(0,35,0))
 a=asset('V3_MutagenTank');q=p(a);glow=p(a,'Glow',material='Neon')
 box(q,(0,0,.4),(5,5,.8),PURPLE);box(q,(0,0,3.4),(3.8,3.8,5.8),INK)
 box(glow,(0,-1.96,3.6),(2.9,.08,4.4),'81E66A')
 for x in [-1.8,1.8]:box(q,(x,-2.05,3.5),(.25,.25,5.5),STONE)
 for z in [1,6.4]:box(q,(0,0,z),(4.8,4.8,.65),STONE)
 box(q,(0,0,7.1),(1.4,1.4,.8),PURPLE)
 a=asset('V3_ClinicCart');q=p(a)
 box(q,(0,0,1.6),(4,6,.6),STONE);box(q,(0,0,2),(3.6,5.7,.4),'C5F2E7')
 for x in [-1.6,1.6]:
  for y in [-2.4,2.4]:q.cyl((x,y,.55),.45,.45,.3,PURPLE,rot=(0,90,0),seg=8)
 box(q,(0,2.8,2.8),(4,.3,2.2),TEAL)
 a=asset('V3_RoadSign');q=p(a);box(q,(0,0,2.5),(.7,.7,5),PURPLE);box(q,(0,0,5),(8,.5,3),CREAM,.12);anchor(a,'Surface',(0,-.3,5))


def district(name,col,accent,kind):
 a=asset('V3_'+name);walls=p(a,'Walls');trim=p(a,'Trim');roofp=p(a,'Roof')
 # Decorative landmark 24x14; goes OUTSIDE the 96-stud playable lane.
 box(walls,(0,0,5.5),(24,14,11),col,.15)
 box(walls,(0,-7.08,4.5),(8,.12,8),INK,.08)
 box(trim,(0,-7.22,4.5),(6.9,.12,7.2),TEAL,.04)
 for x in [-8,8]:window(trim,x,-7.1,6,4.4,4.8)
 box(roofp,(0,0,11.4),(26,16,1.2),accent,.13)
 box(trim,(0,-7.7,10.8),(20,.5,2),accent,.08);anchor(a,'Sign',(0,-8,10.8));anchor(a,'Bounds',(27,17,27))
 if kind=='yard':
  for i in range(5):box(trim,(0,-7.36,1.6+i*1.3),(6.8,.15,.12),STONE,.01)
  box(roofp,(0,0,12.8),(20,11,1.6),PURPLE,.12)
  for x in [-9,9]:box(trim,(x,-7.5,2),(1.8,1.8,3.5),WOOD)
 elif kind=='mall':
  box(roofp,(0,0,15),(18,12,6),col,.12);box(roofp,(0,0,18.4),(20,14,1),accent)
  for x in [-6,0,6]:window(trim,x,-6.15,15,4.2,3.2)
  for x in [-9,-6,-3,0,3,6,9]:box(trim,(x,-9,8),(2.9,4,.45),GOLD if x%2 else CREAM,.04,rot=(12,0,0))
 elif kind=='factory':
  for x in [-7,7]:
   box(roofp,(x,3,18),(3.5,3.5,14),PURPLE,.1)
   for z in [13,18,23]:box(roofp,(x,3,z),(3.8,3.8,1),TEAL)
  for x in [-9,9]:box(trim,(x,-7.3,3),(2.4,.6,3.5),'89C652')
 elif kind=='clinic':
  box(roofp,(0,0,15),(14,10,6),col);box(roofp,(0,0,18.5),(16,12,1),accent)
  box(trim,(0,-5.2,15),(6,.3,4),TEAL)
  box(trim,(0,-5.4,15),(3.6,.2,.8),CREAM);box(trim,(0,-5.4,15),(.8,.2,3.6),CREAM)
 elif kind=='chief':
  for x in [-9,9]:
   box(roofp,(x,0,17),(6,12,12),col);box(roofp,(x,0,23),(7,13,1),accent)
   for z in [14,19]:window(trim,x,-6.1,z,3,3)
  for x in [-4.7,4.7]:box(trim,(x,-8,5),(.8,1,10),GOLD)
  for i in range(4):box(roofp,(0,0,16+i),(10-i*2,9-i*1.5,1.4),accent)
  box(trim,(0,-7.7,12.8),(2.5,.4,2.5),GOLD)

def build():
 for i in range(1,6):house(i);treadmill(i)
 for kind,col in [('Weapons',TEAL),('Pets',GREEN),('Brawler',GOLD)]:stall(kind,col)
 chest('GiftChest',PURPLE);chest('RewardChest','C97938');furnishings();world()
 for args in [('YardGarage',CREAM2,PURPLE,'yard'),('Mall','E5B4C1','8847A5','mall'),('Factory','86A9A1','405A74','factory'),('Clinic','D8E9D3','3CAEA3','clinic'),('ChiefOffice','C4B1D8','643F8C','chief')]:district(*args)
