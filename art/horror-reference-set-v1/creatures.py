"""Independent stylized reference studies. Working names, not identified originals."""
import sys,math
from pathlib import Path
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'blender'))
import kit
RIGS={};DETAILS={};IMPORTED={}
def part(a,n,b=None):return a.part(n,attach=b or n,ao=.25,ao_dist=.3,grad=.06)
def bone(r,n,h,t,parent='Root'):r[n]=(h,t,parent)
def sphere(p,c,s,col,sub=2):p.sphere(c,s,col,sub=sub,smooth=False)
def seg(p,h,t,r1,r2,col):
 h,t=Vector(h),Vector(t);q=(t-h).to_track_quat('Z','Y');rings=[]
 for u,r in [(0,r1),(.18,r1*1.06),(.82,r2*1.06),(1,r2)]:
  rings.append([h.lerp(t,u)+q@Vector((r*math.cos(j*math.tau/8),r*math.sin(j*math.tau/8),0)) for j in range(8)])
 p.loft(rings,col,smooth=False)
def tooth(p,c,length,width,col='D8CCAD',up=False):
 x,y,z=c;tip=z+length if up else z-length
 seg(p,(x,y,z),(x,y-.025,tip),width,.012,col)
def begin(name,ref,focus,scale):
 a=kit.asset(name);r={};RIGS[name]=r;bone(r,'Root',(0,0,0),(0,0,.4),None)
 DETAILS[name]={'reference':ref,'focus':focus,'close_scale':scale,'interpretation':'Stylized interpretation of one screenshot; unseen sides invented; working name, no claimed identification.'}
 return a,r
def face(a,b,c,s,col,kind='mask'):
 x,y,z=c;rx,ry,rz=s;p=part(a,'Face',b)
 sphere(p,c,s,col,3)
 # Dark sculpted socket inserts and raised cheek planes, clear at game distance.
 for sign in (-1,1):
  ex=x+sign*rx*.43
  sphere(p,(ex,y-ry*.87,z+rz*.18),(rx*.26,.075,rz*.18),'17131B')
  sphere(p,(ex,y-ry-.045,z+rz*.20),(.055,.045,.045),'EEEBD6')
  seg(p,(x+sign*rx*.68,y-ry*.6,z),(x+sign*rx*.30,y-ry*.91,z-rz*.23),rx*.16,rx*.07,col)
 if kind!='orb':seg(p,(x,y-ry*.9,z+rz*.1),(x,y-ry*1.15,z-rz*.22),rx*.12,rx*.075,col)
 sphere(p,(x,y-ry*.83,z-rz*.47),(rx*.69,.13,rz*.27),'25141C')
 for i in range(9):
  xx=(i-4)*rx*.145;arch=(abs(i-4)/4)**1.5
  tooth(p,(x+xx,y-ry-.16,z-rz*(.32+arch*.08)),rz*.15,rx*.052)
  tooth(p,(x+xx,y-ry-.16,z-rz*(.65-arch*.1)),rz*.12,rx*.05,up=True)
def hand(a,r,name,wrist,side,parent,col,long=False):
 wx,wy,wz=wrist;end=(wx+side*.1,wy-.08,wz-.38)
 bone(r,name,wrist,end,parent);p=part(a,name)
 seg(p,wrist,end,.19,.23,col)
 for i in range(5):
  h=(wx+(i-2)*.14,wy-.05,wz-.28)
  length=(.68 if not long else 1.35)*(1-.14*abs(i-2))
  t=(h[0]+(i-2)*(.10 if not long else .25),wy-.22,wz-.28-length)
  bn=name+'Finger'+str(i);bone(r,bn,h,t,name)
  pp=part(a,bn);seg(pp,h,t,.065,.028,col)
  tooth(pp,t,.15,.038,'A69C83')
def humanoid(name,ref,thin=False,shadow=False):
 height=8.7 if thin else (8.2 if shadow else 6.8)
 a,r=begin(name,ref,(0,-.35,height-.8),2.9)
 hip=(0,.1,height*.44);chest=(0,0,height*.73);neck=(0,-.08,height*.81);head=(0,-.12,height-.74)
 bone(r,'Pelvis',hip,(0,.1,hip[2]+.5));bone(r,'Chest',hip,chest,'Pelvis');bone(r,'Neck',chest,neck,'Chest');bone(r,'Head',neck,(0,0,height),'Neck')
 skin='A99772' if thin else ('9DABA3' if shadow else 'D1CFC1');cloth='151922' if not shadow else '171C20'
 p=part(a,'Body','Chest')
 if thin:
  seg(p,hip,chest,.33,.58,skin)
  # Emphasized ribs flank the sternum; narrower dark cavities underneath.
  sphere(p,(0,-.29,height*.65),(.53,.18,.7),'453C32')
  for i in range(6):
   zz=height*.72-i*.17
   for side in (-1,1):
    p.tube([(side*.08,-.50,zz,.055),(side*.35,-.44,zz-.05,.055),(side*.55,-.18,zz-.14,.04)],skin,seg=5,sub=1,smooth=False)
  seg(p,hip,(0,-.3,height*.72),.075,.08,'D2C3A0')
 else:
  p.loft([[(rx*math.cos(j*math.tau/10),.1+ry*math.sin(j*math.tau/10),zz) for j in range(10)] for zz,rx,ry in [(hip[2]-.5,.63,.39),(hip[2],.49,.32),(chest[2]-.35,.8,.42),(chest[2],.64,.35)]],cloth,smooth=False)
  for side in (-1,1):seg(p,(side*.6,-.29,chest[2]),(side*.1,-.36,chest[2]-.85),.12,.05,'292D35')
 seg(part(a,'Neck'),chest,(0,-.12,head[2]-.45),.16,.19,skin)
 if not thin:
  hair=part(a,'Hair','Head');sphere(hair,(0,.02,head[2]+.08),(.65,.48,.88),cloth,3)
  for side in (-1,1):seg(hair,(side*.51,-.05,head[2]+.3),(side*.51,-.01,head[2]-1),.19,.14,cloth)
 face(a,'Head',head,(.46 if thin else (.39 if shadow else .50),.40,.86 if shadow else .72),skin)
 for side in (-1,1):
  suffix='L' if side<0 else 'R'
  shoulder=(side*(.65 if thin else .82),0,chest[2]-.1);elbow=(side*(1.02 if thin else 1.04),-.05,height*.51);wrist=(side*1.28,-.22,height*(.29 if thin else .37))
  for bn,h,t,parent,rad in [('Arm'+suffix,shoulder,elbow,'Chest',.14 if thin else .25),('Forearm'+suffix,elbow,wrist,'Arm'+suffix,.105 if thin else .19)]:
   bone(r,bn,h,t,parent);seg(part(a,bn),h,t,rad,rad*.76,skin if thin else cloth)
  hand(a,r,'Hand'+suffix,wrist,side,'Forearm'+suffix,skin,thin or shadow)
  knee=(side*.48,.22 if not thin else -.05,1.8 if thin else 1.5);ankle=(side*.5,.1,.35);start=(side*.28,.1,hip[2])
  for bn,h,t,parent in [('Leg'+suffix,start,knee,'Pelvis'),('Shin'+suffix,knee,ankle,'Leg'+suffix)]:
   bone(r,bn,h,t,parent);seg(part(a,bn),h,t,.18 if thin else .24,.11 if thin else .18,skin if thin else cloth)
  bone(r,'Foot'+suffix,ankle,(side*.5,-.6,.2),'Shin'+suffix)
  foot=part(a,'Foot'+suffix);sphere(foot,(side*.5,-.19,.21),(.2,.43,.2),skin if thin else '11151B')
  if thin:
   for k in range(3):seg(foot,(side*.5+(k-1)*.14,-.3,.18),(side*.5+(k-1)*.18,-.78,.11),.05,.025,skin)
def orb():
 a,r=begin('FloatingGrin',3,(0,0,5.3),3.6);bone(r,'Head',(0,0,4.4),(0,0,6.6))
 p=part(a,'Head');sphere(p,(0,0,5.4),(1.22,.9,1.15),'241C2A',3)
 # Face features lie along the sphere's surface; wide grin, narrow angry white eyes.
 sphere(p,(0,-.79,5.02),(.91,.16,.39),'4B2633')
 for side in (-1,1):
  p.prism([(side*.32,5.73),(side*.94,5.98),(side*.76,5.72)],.06,'EEE9DC',c=(0,-.77,0),smooth=False)
 for i in range(13):
  x=(i-6)*.127;curve=(abs(i-6)/6)**1.7
  tooth(p,(x,-.94+abs(x)*.1,5.22-curve*.03),.17,.043)
  tooth(p,(x,-.94+abs(x)*.1,4.80+curve*.18),.15,.043,up=True)
 for side in (-1,1):
  s='L' if side<0 else 'R';w=(side*1.7,-.08,3.7)
  hand(a,r,'Hand'+s,w,side,'Root','20212A',True)
def crawler():
 a,r=begin('BlindCrawler',4,(0,-1.7,1.65),3.6)
 bone(r,'Chest',(0,.5,1.8),(0,-.5,2.1));bone(r,'Head',(0,-.5,2.1),(0,-1.7,1.7),'Chest')
 p=part(a,'Body','Chest');sphere(p,(0,.5,2),(1,.0+1.3,.73),'353C3D',3)
 sphere(p,(0,.4,2.43),(.85,1,.39),'44494A',2)
 p=part(a,'Head');sphere(p,(0,-1.55,1.65),(.86,.78,.91),'424849',3)
 sphere(p,(0,-2.16,1.21),(.66,.20,.47),'101419',3)
 for i in range(9):
  x=(i-4)*.14;c=abs(i-4)/4
  tooth(p,(x,-2.31,1.51-c*.10),.23,.075)
  tooth(p,(x,-2.31,.87+c*.12),.14,.053,up=True)
 for side in (-1,1):
  s='L' if side<0 else 'R'
  chains=[('Arm'+s,(side*.8,-.4,2.1),(side*1.5,-.8,1.5),'Chest',.36),('Forearm'+s,(side*1.5,-.8,1.5),(side*1.9,-1.7,.24),'Arm'+s,.27),('Leg'+s,(side*.67,1.2,1.8),(side*1.1,1.9,1.1),'Chest',.40),('Shin'+s,(side*1.1,1.9,1.1),(side*.9,1.2,.21),'Leg'+s,.24)]
  for bn,h,t,pa,rad in chains:
   bone(r,bn,h,t,pa);seg(part(a,bn),h,t,rad,rad*.68,'363D3E')
  bone(r,'Hand'+s,(side*1.9,-1.7,.24),(side*1.9,-2.4,.14),'Forearm'+s)
  p=part(a,'Hand'+s);sphere(p,(side*1.9,-1.9,.18),(.34,.36,.17),'404849')
  for k in range(4):seg(p,(side*1.9+(k-1.5)*.15,-2,.17),(side*1.9+(k-1.5)*.22,-2.65,.09),.08,.025,'5C6560')
def skin_weights(part_name,position,default_bone):return {default_bone:1.0}
def build():
 humanoid('PaleGrinner',1)
 humanoid('Longfinger',2,thin=True)
 orb();crawler()
 humanoid('DoorwayShade',5,shadow=True)
