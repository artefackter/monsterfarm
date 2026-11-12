"""Second-pass authored geometry: warm stylised abandoned road, reference-directed."""
import math,random
import kit
from assets_environment_v4 import beam

def build():
 def part(n):return kit.asset(n).part('Main',ao=.32,ao_dist=1.3,grad=.1)
 def box(p,c,s,col,rot=(0,0,0),bevel=.09):p.box(c,s,col,rot=rot,bevel=bevel,seg=1)
 rng=random.Random(816)
 # Hand-laid paving tiles, raised bevels and cracks; usable as repeating modules.
 for name,colors in [('MR_DirtPath',['C99562','D6A06B','D8AA75']),('MR_VillagePaving',['BDA383','C9AE8D','C0A486']),('MR_FactoryPaving',['A3A294','B5B1A1','9B9A8F']),('MR_CavePaving',['9B8274','AE9381','A28A7B'])]:
  p=part(name)
  for row in range(4):
   for col in range(3):
    x=(col-1)*3.3;y=(row-1.5)*3.3
    box(p,(x+rng.uniform(-.06,.06),y,.10),(3.21,3.2,.20),rng.choice(colors),rot=(0,0,rng.uniform(-1,1)),bevel=.13)
  for x,y in [(-2,0),(2,4),(.4,-4)]:
   beam(p,(x-.5,y,.215),(x,y+.5,.215),.035,.025,'716452');beam(p,(x,y+.5,.215),(x+.4,y+.6,.215),.035,.025,'716452')
 p=part('MR_GrassClump')
 for i in range(8):
  a=i*2.399;h=rng.uniform(.35,1.05);x=math.cos(a)*.4;y=math.sin(a)*.4
  p.loft([[(-.10,0,0),(.10,0,0),(.07,.04,0),(-.07,.04,0)],[(-.025,.20,h),(.025,.20,h),(.015,.23,h),(-.015,.23,h)]],['7E902E','9CA73C','ACAD4C'][i%3],c=(x,y,0),rot=(0,0,math.degrees(a)))
 p=part('MR_Mushrooms')
 for x,y,h in [(-.7,0,.55),(.5,.2,.8),(.2,-.5,.35)]:
  p.cyl((x,y,h/2),.13,.09,h,'E0C995',seg=8);p.sphere((x,y,h),(.45,.45,.24),'C94838',sub=2)
  for a in [0,2,4]:p.sphere((x+math.cos(a)*.2,y+math.sin(a)*.2,h+.19),.055,'F3E6C9',sub=1)
 p=part('MR_LeafLitter')
 for i in range(14):
  x,y=rng.uniform(-2,2),rng.uniform(-2,2);p.sphere((x,y,.05),(.25,.13,.025),rng.choice(['806447','9C7048','6D6650']),sub=1,rot=(0,0,rng.randrange(180)))
 # Rooted asymmetric branching tree, branch tips split instead of a repeated ladder silhouette.
 p=part('MR_TwistedTree')
 p.tube([(0,0,0,1.15),(-.3,.2,2,.95),(.45,.1,4,.68),(-.3,0,7,.5),(.8,.2,10,.28),(.6,-.1,13,.04)],'66584A',seg=9,sub=3)
 for i in range(7):
  a=i*2.399;z=4+i*.8;end=(math.cos(a)*(3.1+i*.15),math.sin(a)*2.8,z+2)
  p.tube([(.1,0,z,.38),(end[0]*.5,end[1]*.5,z+.2,.25),(*end,.15),(end[0]*1.15,end[1]*1.1,z+4,.02)],'72604F',seg=7,sub=2)
  p.tube([(end[0]*.8,end[1]*.8,z+1.5,.17),(end[0]*1.5,end[1]*.9,z+2.5,.07),(end[0]*1.6,end[1]*.8,z+3.7,.015)],'796653',seg=6,sub=2)
 for i in range(6):
  a=i*math.tau/6;p.tube([(math.cos(a)*2,math.sin(a)*2,.08,.12),(math.cos(a),math.sin(a),.5,.4),(0,0,1.6,.55)],'695845',seg=7,sub=2)
 # Lantern brackets, emissive glass will be lit by a small light in Studio.
 p=part('MR_HangingLantern')
 box(p,(0,0,3.8),(.5,.5,7.6),'987448');beam(p,(0,0,7.4),(2.7,0,7.4),.42,.42,'AA8350');beam(p,(0,0,5.7),(1.7,0,7.4),.25,.25,'8A653D')
 p.cyl((2.1,0,6.9),.035,.035,.8,'4D493B',seg=6)
 box(p,(2.1,0,5.9),(1.05,.85,1.6),'FFD16A')
 for dx in [-.6,.6]:
  for dy in [-.5,.5]:box(p,(2.1+dx,dy,5.9),(.11,.11,1.9),'6C4E30')
 box(p,(2.1,0,4.95),(1.4,1.15,.20),'725331');p.cyl((2.1,0,7),.9,.2,.55,'785634',seg=4,rot=(0,0,45))
 p=part('MR_CultTorch')
 box(p,(0,0,1.5),(.22,.22,3),'5C4333');p.cyl((0,0,2.8),.4,.5,.5,'4A4136',seg=8)
 p.sphere((0,0,3.2),(.32,.32,.55),'FF9B30',sub=2);p.sphere((0,-.1,3.3),(.17,.17,.4),'FFDE67',sub=2)
 p=part('MR_CultSkulls')
 for x,y,s in [(-.65,0,1),(.65,.25,.75)]:
  p.sphere((x,y,.7*s),(.65*s,.48*s,.65*s),'D9C8A1',sub=2)
  for dx in [-.25,.25]:p.sphere((x+dx*s,y-.42*s,.8*s),(.17*s,.08*s,.21*s),'423B34',sub=2)
  box(p,(x,y-.36*s,.30*s),(.65*s,.27*s,.25*s),'C5AE86')
  for dx in [-.22,0,.22]:box(p,(x+dx*s,y-.51*s,.26*s),(.13*s,.06*s,.16*s),'E6D5AD')
 p=part('MR_RuneStone')
 p.sphere((0,0,1.1),(1.15,.65,1.5),'8A8477',sub=1,smooth=False)
 for a,b in [((- .5,-.62,1.2),(0,-.64,1.9)),((0,-.64,1.9),(.5,-.62,1.2)),((.5,-.62,1.2),(0,-.64,.65)),((0,-.64,.65),(-.5,-.62,1.2))]:beam(p,a,b,.07,.07,'504A40')
 p=part('MR_Cart')
 box(p,(0,0,1.3),(3.8,5,.35),'A47A49')
 for x in [-2,2]:
  for z in [1.7,2.3]:box(p,(x,0,z),(.2,5,.4),'B68B56')
  for y in [-1.6,1.6]:
   # Wooden wheels with dark rims, hub and spokes.
   p.cyl((x*1.15,y,.9),1,1,.24,'6D5135',rot=(0,90,0),seg=12)
   p.cyl((x*1.23,y,.9),.78,.78,.05,'AC8150',rot=(0,90,0),seg=12)
   p.cyl((x*1.27,y,.9),.18,.18,.15,'6D5135',rot=(0,90,0),seg=10)
 for x in [-1.4,1.4]:beam(p,(x,-2,1.4),(x,-5,.6),.24,.24,'A47A49')
 # Architectural stone arch and recessed interior for the cave entrance.
 p=part('MR_CultCave')
 for i in range(9):
  a=math.pi*i/8;x=math.cos(a)*4.3;z=3+math.sin(a)*4.3
  box(p,(x,0,z),(2,3,2.1),['827C70','958C7E','736F66'][i%3],rot=(0,-math.degrees(a)+90,0),bevel=.25)
 for x in [-4.3,4.3]:
  for z in [.8,2.4]:box(p,(x,.1,z),(2,3,1.55),'857E70',bevel=.2)
 box(p,(0,1.1,3.2),(6.7,.4,6.4),'282D29')
 box(p,(0,-1.4,.16),(8,4,.32),'A49A87')
 for x in [-6.3,6.3]:
  p.sphere((x,1,2.5),(2.8,3.6,3.5),'7F7B70',sub=1,smooth=False)
  box(p,(x*.47,-1.7,4.8),(1.7,.15,3.8),'6B3F45')
  for a,b in [((x*.47-.5,-1.82,4.7),(x*.47,-1.82,5.6)),((x*.47,-1.82,5.6),(x*.47+.5,-1.82,4.7)),((x*.47+.5,-1.82,4.7),(x*.47,-1.82,3.9)),((x*.47,-1.82,3.9),(x*.47-.5,-1.82,4.7))]:beam(p,a,b,.065,.06,'DCAD5B')
 # Chunkier, irregular staggered masonry, with broad buttress and coping.
 p=part('MR_WallDetailed')
 for row in range(5):
  for col in range(4):
   x=-6+col*4
   box(p,(x,rng.uniform(-.035,.035),row*1.7+.85),(3.94,2.2,1.64),rng.choice(['B1A698','C2B5A3','BBAF9F','ADA396']),bevel=.15)
 for col in range(4):box(p,(-6+col*4,0,8.7),(3.98,2.9,.6),'CCC0AD',bevel=.10)
 box(p,(-7.6,-.25,4.1),(1.3,3.1,8.3),'B9AE9D',bevel=.10)
 box(p,(-7.6,-.25,8.5),(1.8,3.4,.6),'D1C3AE')
 # Rusted tank, bands, angled plumbing and pressure dial.
 p=part('MR_RustTank')
 p.cyl((0,0,3),2.5,2.5,6,'827B68',seg=16)
 for z in [.3,3,5.7]:p.cyl((0,0,z),2.57,2.57,.18,'B58A5D',seg=16)
 for i in range(14):
  a=i*2.399;z=rng.uniform(.7,5.4);p.sphere((math.cos(a)*2.49,math.sin(a)*2.49,z),(.25,.10,rng.uniform(.3,.8)),'A66C43',rot=(0,0,math.degrees(a)-90),sub=1)
 p.tube([(4,0,0,.55),(4,0,6.6,.55),(3.8,0,7.2,.55),(3.2,0,7.6,.55),(1.8,0,7.6,.55)],'9D7954',seg=12,sub=3)
 for z in [1,4,6]:p.cyl((4,0,z),.68,.68,.20,'C39C70',seg=12)
 p.cyl((0,-2.55,4),.62,.62,.22,'D2C5A6',rot=(90,0,0),seg=16)
 beam(p,(0,-2.69,4),(.30,-2.69,4.3),.06,.05,'4D4A3D')

 p=part('MR_HazardEdge')
 box(p,(0,0,.07),(.75,30,.14),'776E50')
 for i in range(15):box(p,(0,-14+i*2,.15),(.72,1.15,.06),'E0B94F',rot=(0,0,-20),bevel=.02)
 p=part('MR_ArenaSeal')
 p.cyl((0,0,.07),4.2,4.2,.14,'D9D6C0',seg=48)
 p.cyl((0,0,.16),3.85,3.85,.05,'83B4A2',seg=48)
 p.cyl((0,0,.20),3.5,3.5,.04,'BDC9B4',seg=48)
