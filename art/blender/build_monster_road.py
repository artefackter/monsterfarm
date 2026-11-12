"""Original modular ruins kit for Grow a Monster; Blender Z up, Roblox export through kit."""
import sys,math,json,random
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import bpy
from mathutils import Vector
import kit
from assets_environment_v4 import beam,tree
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'export/monster-road-v2';PRE=ROOT/'preview/monster-road-v2'
OUT.mkdir(parents=True,exist_ok=True);PRE.mkdir(parents=True,exist_ok=True)

def part(name):return kit.asset(name).part('Main',ao=.3,grad=.10)
def box(p,c,s,col):p.box(c,s,col,bevel=.06,seg=1)
def window(p,x,y,z,board=True):
 box(p,(x,y,z),(2.9,.2,3.1),'514C42')
 for dx in [-1.6,1.6]:box(p,(x+dx,y-.12,z),(.28,.25,3.5),'BD9A69')
 for dz in [-1.7,1.7]:box(p,(x,y-.12,z+dz),(3.5,.25,.25),'BD9A69')
 if board:
  beam(p,(x-1.5,y-.3,z-1.3),(x+1.5,y-.3,z+1.3),.44,.2,'927044')
  beam(p,(x-1.5,y-.3,z+1.3),(x+1.5,y-.3,z-1.3),.44,.2,'A7804D')

def house(name,hospital=False):
 p=part(name);w=25 if hospital else 15;d=12;h=13 if hospital else 9
 box(p,(0,0,h/2),(w,d,h),'D8D9C9' if hospital else 'C9AF7F')
 for x in [-w/2+.25,0,w/2-.25]:box(p,(x,-d/2-.12,h/2),(.6,.5,h+.4),'86AEA4' if hospital else '795A3A')
 box(p,(0,-d/2-.2,.6),(w+.7,.6,1.2),'9D9B8D')
 for x in [-w*.31,w*.31]:
  window(p,x,-d/2-.35,4)
  if hospital:window(p,x,-d/2-.35,10)
 box(p,(0,-d/2-.4,2.7),(3.4,.4,5.4),'3D514C' if hospital else '6B4D31')
 if hospital:
  # Recessed entry, projecting columns, rooftop parapet and taller central medical block.
  box(p,(0,-7,1),(7,3,2),'C6C4B2')
  for i in range(3):box(p,(0,-9-i*.65,.75-i*.23),(7.8,1,.25),'CDC7B7')
  for x in [-3,3]:box(p,(x,-7.2,3.9),(.7,.8,5.8),'CDD3BD')
  box(p,(0,0,14.6),(9,13,3.2),'D9DBCD')
  box(p,(0,0,16.4),(9.8,13.8,.5),'E3DFCE')
  for x in [-12.2,12.2]:box(p,(x,0,13.7),(.6,12,1.4),'B7C9BD')
  for x in [-8,8]:box(p,(x,5.8,13.7),(8,.6,1.4),'B7C9BD')
  for z in [6.5,13]:box(p,(0,0,z),(w+1,d+1,.5),'B5C3B6')
  box(p,(0,-d/2-.5,14),(4.8,.5,4),'E7E2D0')
  box(p,(0,-d/2-.8,14),(1,.2,3.7),'58A69A');box(p,(0,-d/2-.8,14),(3.7,.2,1),'58A69A')
  box(p,(0,-d/2-1.5,5.9),(6,3,.5),'86AEA4')
 else:
  p.prism([(-7.5,0),(7.5,0),(0,4.5)],12,'C9AF7F',c=(0,0,9))
  # Timber outline, exposed rafters, ridge and separate missing shingles.
  for y in [-6.5,6.5]:
   beam(p,(-8,y,9),(0,y,13.8),.5,.5,'795A3A');beam(p,(0,y,13.8),(8,y,9),.5,.5,'795A3A')
  for x in [-7.3,0,7.3]:box(p,(x,-6.2,4.7),(.45,.5,9.5),'7C593B')
  beam(p,(-7.3,-6.3,1),(-1.9,-6.3,4),.35,.3,'967047');beam(p,(7.3,-6.3,1),(1.9,-6.3,4),.35,.3,'967047')
  box(p,(0,-6.25,9),(15,.5,.5),'77563B')
  for side in [-1,1]:
   for col in range(6):
    for row in range(4):
     if (col,row,side) in [(1,1,-1),(2,1,-1),(2,2,-1),(4,1,1)]:continue
     p.box((side*(.9+row*1.95),-5.7+col*2.3,13.4-row*1.16),(2.4,2.36,.30),['916B66','AA7D74','9A716B'][(row+col)%3],rot=(0,side*31,0),bevel=.09,seg=1)
  beam(p,(0,-7,13.8),(0,7,13.8),.45,.45,'705139')
  box(p,(-4,2,14),(1.4,1.5,4),'A49077');box(p,(-4,2,16),(1.8,1.9,.35),'CEB596')
  for x in [-6.8,6.8]:
   p.tube([(x,-6.5,.1,.12),(x+.4,-6.5,3,.1),(x-.1,-6.5,6,.07),(x+.5,-6.5,8,.02)],'657039',seg=5,sub=2)
   for i in range(11):p.sphere((x+math.sin(i*2)*.4,-6.6,.8+i*.64),(.38,.15,.28),'7C8E42',sub=1)

 return p
house('MR_VillageHouse');house('MR_Hospital',True)
p=part('MR_Factory')
box(p,(0,0,5),(21,13,10),'9C6149')
for z in range(1,10,2):
 for x in range(-10,11,3):box(p,(x+(z%4)*.3,-6.56,z),(2.8,.16,1.75),'B57958')
for x in [-6,0,6]:window(p,x,-6.75,5.5)
for side in [-1,1]:
 for x in range(-11,12):p.box((x,side*3.7,11.4),(.92,8,.25),'A6A398',rot=(-side*15,0,0),bevel=.03,seg=1)
box(p,(7,2,14),(2.5,2.5,7),'95583E');box(p,(7,2,17.5),(3.1,3.1,.5),'C5B59E')
p=part('MR_Boiler');box(p,(0,0,3),(7,5,6),'8C8980')
for x in [-3.2,0,3.2]:box(p,(x,-2.6,3),(.25,.15,5.8),'BB784D')
p.cyl((4,0,6),.7,.7,6,'9E7151',seg=10);p.cyl((1.8,0,8.7),.7,.7,4.4,'9E7151',rot=(0,90,0),seg=10)
for x in [-5,6]:p.cyl((x,-3,1.7),1.25,1.25,3.4,'A67249',seg=12)
p=part('MR_Cave')
for side in [-1,1]:
 for i in range(4):p.sphere((side*(4+i*.6),0,1+i*1.8),(2,3,2),'77766C',sub=1,smooth=False)
p.sphere((0,0,8),(4,3,2.5),'858277',sub=1,smooth=False)
box(p,(0,1,3.6),(6,.4,7.2),'252927')
for side in [-1,1]:
 beam(p,(side*2.5,-2.5,0),(side*2.5,-2.5,6.3),.3,.3,'AA803B')
 box(p,(side*2.5,-2.5,4),(2,.25,3),'75474D')
p=part('MR_DeadTree')
p.tube([(0,0,0,.9),(.4,0,3,.7),(-.2,.2,6,.5),(.6,0,9,.3),(.3,0,12,.05)],'605348',seg=7,sub=2)
for side in [-1,1]:
 for i in range(3):
  z=4+i*2;p.tube([(0,0,z,.4),(side*(2+i*.4),.3,z+1,.22),(side*(3+i*.5),0,z+3,.04)],'716052',seg=6,sub=2)
p=part('MR_Log');p.cyl((0,0,1),.9,1,9,'88633E',rot=(0,90,0),seg=12);p.cyl((4.55,0,1),.82,.82,.07,'D1AE71',rot=(0,90,0),seg=12)
p=part('MR_Well')
for i in range(12):
 a=i*math.tau/12;p.box((math.cos(a)*2,math.sin(a)*2,1),(1.05,1.1,2),'A6A08D',rot=(0,0,math.degrees(a)),bevel=.1,seg=1)
for x in [-2.4,2.4]:box(p,(x,0,3.4),(.5,.5,6),'84603B')
beam(p,(-3,0,6),(3,0,6),.6,.6,'B58B54')
p=part('MR_Lantern');box(p,(0,0,3),(.45,.45,6),'987343');beam(p,(0,0,6),(2,0,6),.35,.35,'B18A51');box(p,(1.6,0,4.8),(1,.9,1.4),'FFD66A');box(p,(1.6,0,5.6),(1.3,1.1,.25),'694E36')
p=part('MR_Sign');box(p,(0,0,4),(9,.7,3),'705235');box(p,(0,-.4,4),(8.4,.1,2.4),'463A2D')
for x in [-3.5,3.5]:box(p,(x,.1,2),(.55,.55,4),'9E7848')
p=part('MR_StoneWall')
for row in range(4):
 for j in range(4):box(p,(-6+j*4+(row%2)*.1,0,1+row*2),(3.92,2,1.94),['A9A49A','B5AEA4','9E9B94'][(row+j)%3])
for j in range(4):box(p,(-6+j*4,0,8.5),(3.92,2.7,.8),'C6BEB0')
for x in [-7.8,7.8]:box(p,(x,-.25,4.5),(1.1,2.9,9),'B5AEA4')
p=part('MR_Rocks')
for x,y,z,s in [(-1,0,.7,1.6),(1,.3,1,2),(0,-1,.3,1)]:p.sphere((x,y,z),(s,s*.8,s*.7),'7D8178',sub=1,smooth=False)
tree('MR_ForestTree',101,.8)
import monster_road_details
monster_road_details.build()
selected=set(kit.ASSETS)-{'MR_Cave','MR_DeadTree','MR_Lantern','MR_StoneWall'}
manifest,baked,total=kit.export_all(str(OUT),only=selected);(OUT/'_manifest.json').write_text(json.dumps(manifest,indent=2));(OUT/'_validation.json').write_text(json.dumps({'totalTriangles':total,'assets':{k:{'parts':len(v),'triangles':sum(p['tris'] for p in v)} for k,v in manifest.items()}},indent=2))
for ob in list(bpy.data.objects):bpy.data.objects.remove(ob,do_unlink=True)
def spawn(n,xyz,scale=1,angle=0):kit.spawn_preview(baked,n,manifest[n],xyz,scale=scale,rot_z=angle)
# A condensed composition for art review, NOT the variable-length runtime layout.
rng=random.Random(61)
def mat(name,color):
 m=bpy.data.materials.new(name);m.use_nodes=True;bs=m.node_tree.nodes['Principled BSDF'];bs.inputs['Base Color'].default_value=(*[c**2.2 for c in kit._rgb(color)],1);bs.inputs['Roughness'].default_value=.9;return m
floor_mats={}
def floor(i,color):
 m=mat('Biome '+str(i),color)
 n=m.node_tree.nodes;l=m.node_tree.links;tex=n.new('ShaderNodeTexNoise');tex.inputs['Scale'].default_value=2.3;tex.inputs['Detail'].default_value=2
 geo=n.new('ShaderNodeTexCoord');l.new(geo.outputs['Object'],tex.inputs['Vector'])
 ramp=n.new('ShaderNodeValToRGB');base=kit._rgb(color)
 ramp.color_ramp.elements[0].position=.15;ramp.color_ramp.elements[0].color=(*[(c*.92)**2.2 for c in base],1)
 ramp.color_ramp.elements[1].position=.85;ramp.color_ramp.elements[1].color=(*[min(c*1.08,1)**2.2 for c in base],1)
 l.new(tex.outputs['Fac'],ramp.inputs[0]);l.new(ramp.outputs[0],n.get('Principled BSDF').inputs['Base Color'])
 bpy.ops.mesh.primitive_cube_add(size=1,location=(0,i*32,-.2));o=bpy.context.object;o.scale=(48,32,.4);o.data.materials.append(m)
fontpath='/System/Library/Fonts/Supplemental/Arial Bold.ttf'
font=bpy.data.fonts.load(fontpath) if Path(fontpath).exists() else None
names=['1. ЛЕС','2. ЗАБРОШЕННЫЙ\nЗАВОД','3. МРАЧНЫЙ\nЛЕС','4. ЗАБРОШЕННАЯ\nДЕРЕВНЯ','5. ПЕЩЕРА\nКУЛЬТИСТОВ','6. ЗАБРОШЕННАЯ\nБОЛЬНИЦА']
textmat=mat('Ivory letters','FFF1CF')
for i,color in enumerate(['91A630','A6A291','525E51','B7A185','8C7D70','B8C4B5']):
 floor(i,color)
 for side in [-1,1]:
  for j in range(2):spawn('MR_WallDetailed',(side*25,i*32-8+j*16,0),angle=90)
 spawn('MR_Sign',(-12,i*32-11,0),.95)
 cu=bpy.data.curves.new('Localized zone sign','FONT');cu.body=names[i];cu.align_x='CENTER';cu.align_y='CENTER';cu.size=.85;cu.space_line=.85;cu.extrude=.008
 if font:cu.font=font
 ob=bpy.data.objects.new('Zone sign '+str(i+1),cu);bpy.context.collection.objects.link(ob);ob.location=(-12,i*32-11.42,3.8);ob.rotation_euler=(math.pi/2,0,0);cu.materials.append(textmat)
 spawn('MR_HangingLantern',(7,i*32-9,0),.8)
 path=['MR_DirtPath','MR_FactoryPaving','MR_CavePaving','MR_VillagePaving','MR_CavePaving','MR_FactoryPaving'][i]
 for j in range(3):
  for lane in ([-1,0,1] if i in [1,3,4,5] else [0]):spawn(path,(lane*8,i*32-10.66+j*10.66,.025),.8)
 if i==1:
  for side in [-1,1]:spawn('MR_HazardEdge',(side*12.5,i*32,0))
 for j in range(14):
  x=rng.choice([-1,1])*rng.uniform(7,22);y=i*32+rng.uniform(-14,14)
  spawn('MR_GrassClump',(x,y,.02),rng.uniform(.7,1.4),rng.randrange(360))
  if j%3==0:spawn('MR_LeafLitter',(x,y,.03),1,rng.randrange(360))
for x,y,k in [(-16,3,1),(16,5,1.05),(-18,-10,.9),(18,-11,.8)]:spawn('MR_ForestTree',(x,y,0),k)
spawn('MR_Log',(0,4,0),1.15,12)
spawn('MR_Factory',(-13,36,0),.85);spawn('MR_RustTank',(16,37,0),1.15)
for x,y in [(11,31),(20,32)]:spawn('MR_Boiler',(x,y,0),.45)
for x,y,k in [(-15,56,1.1),(16,59,1),(-17,72,.95),(14,73,.85),(-10,64,.7)]:spawn('MR_TwistedTree',(x,y,0),k)
for x,y in [(-13,93),(15,96),(-15,106)]:spawn('MR_VillageHouse',(x,y,0),.8)
spawn('MR_Cart',(-5,99,0),.85,25);spawn('MR_Well',(8,104,0),.9)
for x in [-15,15]:
 spawn('MR_CultCave',(x,132,0),1.15)
 spawn('MR_CultSkulls',(x-4,128,0),1.1);spawn('MR_RuneStone',(x+5,127,0))
 for dx in [-3,3]:
  spawn('MR_CultTorch',(x+dx,129,0),1.1)
  li=bpy.data.lights.new('Cave fire','POINT');li.energy=90;li.color=(1,.36,.06);ob=bpy.data.objects.new('Cave fire',li);ob.location=(x+dx,128.5,4);bpy.context.collection.objects.link(ob)
spawn('MR_Hospital',(0,169,0),1.15)
spawn('MR_ArenaSeal',(0,153,.22),.9)
for i in range(6):
 for x in [-20,20]:
  spawn('MR_Rocks',(x,i*32-6,0),rng.uniform(.8,1.25),rng.randrange(360))
  if i in [0,2]:spawn('MR_Mushrooms',(x+2,i*32-4,0),1.1)
def render(name,cam,look,scale,res):
 kit.setup_render(str(PRE/(name+'.png')),cam,look,res=res,samples=40,bg='8CC8EE')
 s=bpy.context.scene;s.camera.data.type='ORTHO';s.camera.data.ortho_scale=scale;s.cycles.use_denoising=True
 for light in bpy.data.lights:
  if light.type=='SUN':light.energy=2.1;light.color=(1,.94,.83)
 s.world.node_tree.nodes['Background'].inputs[0].default_value=(.30,.57,.86,1);s.world.node_tree.nodes['Background'].inputs[1].default_value=.65
 bpy.ops.wm.save_as_mainfile(filepath=str(PRE/(name+'.blend')));bpy.ops.render.render(write_still=True)
render('six-biomes',(155,-150,190),(0,77,1),195,(1900,1600))
render('forest-factory',(62,-50,53),(0,19,2),80,(1600,1300))
render('village-caves',(61,46,49),(0,112,3),80,(1600,1300))
