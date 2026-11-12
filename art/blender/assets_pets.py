"""Distinct chibi farm companions, baked colour/AO. One body mesh per species."""
from kit import asset
INK='302A40';CREAM='FFF1CD';GOLD='FFCE51'
def build():
 for name,col in [('FarmerCat','F2B45E'),('DiggerMole','9B799C'),('CoinHen','FFF1CD'),('LuckyOwl','8ABAC7'),('GuardDog','B88152'),('BanditBat','8976CA')]:
  a=asset('Pet_'+name);b=a.part('Body');bird=name in ['CoinHen','LuckyOwl'];bat=name=='BanditBat'
  b.sphere((0,.2,.65),(.68,.75,.62),col,sub=2)
  b.sphere((0,-.15,1.5),(.85,.7,.8),col,sub=3)
  for x in [-.4,.4]:
   b.sphere((x,-.66,1.55),(.32,.14,.37),CREAM,sub=2)
   b.sphere((x+.04,-.8,1.55),(.16,.07,.22),INK,sub=2)
   b.sphere((x,-.86,1.64),.065,'FFFFFF',sub=1)
   b.sphere((x,-.25,.14),(.26,.4,.16),GOLD if bird else col,sub=2)
  if bird:
   b.cyl((0,-.87,1.2),.22,0,.42,'FF9B3F',rot=(90,0,0),seg=6)
   for x in [-.66,.66]: b.sphere((x,.12,.8),(.22,.48,.55),col if name=='CoinHen' else '51879F',sub=2)
  elif bat:
   b.sphere((0,-.78,1.2),(.2,.13,.12),'F6A4C5',sub=2)
  else:
   for x in [-.2,.2]: b.sphere((x,-.72,1.12),(.28,.23,.23),CREAM,sub=2)
   b.sphere((0,-.94,1.24),(.17,.12,.12),'6F3954',sub=2)
  if name=='FarmerCat':
   for x in [-.6,.6]:
    b.prism([(-.24,0),(0,.58),(.24,0)],.3,col,c=(x,-.08,2),bevel=.03)
    b.prism([(-.13,0),(0,.36),(.13,0)],.04,'F18E9F',c=(x,-.26,2.08),bevel=.015)
   b.cyl((0,.08,2.08),1.02,1.02,.12,GOLD,seg=20);b.cyl((0,.08,2.29),.52,.43,.35,GOLD,seg=16)
   b.cyl((0,.08,2.15),.54,.54,.12,'78BA7C',seg=16)
   b.tube([(.5,.65,.7,.16),(.95,1.05,.9,.15),(1.1,.9,1.4,.11)],col,seg=7,sub=2)
   for x in [-.8,.8]:
    for z in [1.1,1.24]:b.box((x,-.65,z),(.35,.035,.035),INK,bevel=0)
  elif name=='DiggerMole':
   b.sphere((0,0,2.03),(.88,.72,.4),GOLD,sub=2);b.box((0,-.04,1.94),(1.7,1.4,.1),GOLD,bevel=.08)
   b.cyl((0,-.78,2.06),.25,.25,.18,INK,rot=(90,0,0),seg=12)
   b.cyl((0,-.89,2.06),.17,.17,.04,'E8FFFF',rot=(90,0,0),seg=12)
   for x in [-.7,.7]:
    b.sphere((x,-.45,.55),(.34,.38,.24),col,sub=2)
    for dx in [-.14,0,.14]: b.cyl((x+dx,-.78,.55),.07,0,.3,CREAM,rot=(90,0,0),seg=5)
  elif name=='CoinHen':
   for y,z in [(-.25,2.28),(0,2.42),(.25,2.3)]: b.sphere((0,y,z),(.16,.24,.3),'EE6475',sub=2)
   for x in [-.2,0,.2]:b.sphere((x,.82,.9),(.18,.25,.7),GOLD,rot=(30,x*90,0),sub=2)
   b.cyl((0,-.61,.63),.3,.3,.07,GOLD,rot=(90,0,0),seg=16)
   b.box((0,-.66,.63),(.07,.04,.4),'C68C25',bevel=.01)
  elif name=='LuckyOwl':
   for x in [-.4,.4]:b.torus((x,-.83,1.55),.34,.055,GOLD,rot=(90,0,0),seg=16,rseg=5)
   b.box((0,-.84,1.6),(.2,.06,.05),GOLD,bevel=.01)
   for x in [-.65,.65]:b.prism([(-.2,0),(x*.25,.5),(.2,0)],.25,col,c=(x,0,2),bevel=.03)
   b.sphere((0,-.48,.7),(.46,.16,.4),CREAM,sub=2)
   for x in [-.2,0,.2]:b.sphere((x,-.63,.72),(.06,.03,.1),'51879F',sub=1)
  elif name=='GuardDog':
   for x in [-.8,.8]:b.sphere((x,.02,1.5),(.26,.38,.7),'6D493E',rot=(0,x*16,0),sub=2)
   b.cyl((0,0,2.12),.68,.6,.25,'4277AA',seg=18);b.box((0,-.5,2.05),(1.25,.75,.12),'4277AA',bevel=.12)
   b.sphere((0,-.55,.9),(.65,.14,.15),'4277AA',sub=2)
   b.prism([(-.18,.2),(.18,.2),(.16,-.08),(0,-.23),(-.16,-.08)],.07,GOLD,c=(0,-.72,.85),bevel=.03)
  else:
   for x in [-.6,.6]:b.prism([(-.24,0),(0,.85),(.24,0)],.3,col,c=(x,0,2),bevel=.04)
   for sign in [-1,1]:
    poly=[(sign*x,z) for x,z in [(.55,.95),(1.15,1.7),(2,1.55),(1.65,.9),(1.3,.55),(1,.85)]]
    b.prism(poly,.12,'55447F',c=(0,.3,0),bevel=.035)
    b.tube([(sign*.55,.22,.95,.045),(sign*1.15,.22,1.65,.04),(sign*2,.22,1.55,.025)],col,seg=5,sub=1)
   for x in [-.2,.2]:b.cyl((x,-.85,1),.07,0,.22,CREAM,rot=(180,0,0),seg=5)
