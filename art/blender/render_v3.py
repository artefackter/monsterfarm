import os,sys,json,math
from pathlib import Path
sys.path.insert(0,os.path.dirname(__file__))
import bpy,kit
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'export'/'v3';PREVIEW=ROOT/'preview'/'v3-stage5';PREVIEW.mkdir(parents=True,exist_ok=True)
manifest=json.loads((OUT/'_manifest.json').read_text());baked={}
def load_meshes(man,folder):
 for name,parts in man.items():
  for p in parts:
   d=json.loads((folder/(p['mesh']+'.json')).read_text());vs=d['v'];o=p['offset'];verts=[]
   for i in range(0,len(vs),3):
    x,y,z=[vs[i+j]+o[j] for j in range(3)];verts.append(Vector((-x,z,y)))
   baked[name,p['part']]=(verts,[((c>>16&255)/255,(c>>8&255)/255,(c&255)/255) for c in d['c']],d['t'])
load_meshes(manifest,OUT)
refpath=ROOT/'references'/'v3';refs=json.loads((refpath/'_manifest.json').read_text()) if refpath.exists() else {};load_meshes(refs,refpath);manifest.update(refs)
def spawn(name,at=(0,0,0),scale=1,rot=0,tints=None,skip=()):
 before=set(bpy.data.objects)
 kit.spawn_preview(baked,name,[m for m in manifest[name] if m['part'] not in skip],at,scale=scale,rot_z=rot,tints=tints)
 for ob in set(bpy.data.objects)-before:ob.name=name+'__'+ob.name

def clear():
 for o in list(bpy.data.objects):bpy.data.objects.remove(o,do_unlink=True)

def ground(size=150,col='76BC45'):
 bpy.ops.mesh.primitive_cube_add(size=1,location=(0,0,-.25));o=bpy.context.object;o.name='PreviewGround';o.scale=(size,size,.5)
 m=bpy.data.materials.new('Ground');m.diffuse_color=(*kit._rgb(col),1);m.use_nodes=True
 bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*[x**2.2 for x in kit._rgb(col)],1);bs.inputs['Roughness'].default_value=.9
 coords=m.node_tree.nodes.new('ShaderNodeNewGeometry');scale=m.node_tree.nodes.new('ShaderNodeVectorMath');scale.operation='SCALE';scale.inputs[3].default_value=1/8
 m.node_tree.links.new(coords.outputs['Position'],scale.inputs[0])
 color=m.node_tree.nodes.new('ShaderNodeTexImage');color.image=bpy.data.images.load(str(ROOT/'textures'/'v3'/'GrowVoxel_Color.png'),check_existing=True);color.extension='REPEAT'
 normal=m.node_tree.nodes.new('ShaderNodeTexImage');normal.image=bpy.data.images.load(str(ROOT/'textures'/'v3'/'GrowVoxel_Normal.png'),check_existing=True);normal.image.colorspace_settings.name='Non-Color';normal.extension='REPEAT'
 for tex in [color,normal]:m.node_tree.links.new(scale.outputs[0],tex.inputs['Vector'])
 mix=m.node_tree.nodes.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1;mix.inputs[2].default_value=(*[x**2.2 for x in kit._rgb(col)],1)
 m.node_tree.links.new(color.outputs['Color'],mix.inputs[1]);m.node_tree.links.new(mix.outputs[0],bs.inputs['Base Color'])
 nm=m.node_tree.nodes.new('ShaderNodeNormalMap');nm.inputs['Strength'].default_value=.55;m.node_tree.links.new(normal.outputs['Color'],nm.inputs['Color']);m.node_tree.links.new(nm.outputs['Normal'],bs.inputs['Normal']);o.data.materials.append(m)


def label(text,at,size=1):
 curve=bpy.data.curves.new('label','FONT');curve.body=text;curve.align_x='CENTER';curve.size=size;curve.extrude=.01
 ob=bpy.data.objects.new('label',curve);bpy.context.scene.collection.objects.link(ob);ob.location=at;ob.rotation_euler=(math.pi/2,0,0)
 mat=bpy.data.materials.new('Ink');mat.diffuse_color=(.08,.03,.12,1);curve.materials.append(mat)

def light(at,power=1200):
 data=bpy.data.lights.new('InteriorWarm','POINT');data.energy=power;data.color=(1,.77,.48);data.shadow_soft_size=2.5
 ob=bpy.data.objects.new('InteriorWarm',data);bpy.context.scene.collection.objects.link(ob);ob.location=at

def render(name,cam,look,res=(1800,1100),lens=52,fit=True):
 kit.setup_render(str(PREVIEW/(name+'.png')),cam,look,res=res,lens=lens,samples=16)
 bpy.context.scene.cycles.use_denoising=True
 if fit:
  bpy.context.view_layer.update();co=bpy.context.scene.camera;inv=co.matrix_world.inverted();frame=co.data.view_frame(scene=bpy.context.scene)
  tx=max(abs(v.x/v.z) for v in frame)*.9;ty=max(abs(v.y/v.z) for v in frame)*.9;delta=0
  for ob in bpy.context.scene.objects:
   if ob.type not in ('MESH','FONT') or ob.name=='PreviewGround':continue
   for c in ob.bound_box:
    v=inv@(ob.matrix_world@Vector(c));delta=max(delta,abs(v.x)/tx+v.z,abs(v.y)/ty+v.z)
  co.location+=co.rotation_euler.to_matrix()@Vector((0,0,max(0,delta)))
 bpy.context.scene.render.image_settings.file_format='PNG'
 bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'blender'/('preview-'+name+'.blend')))
 bpy.ops.render.render(write_still=True);print('RENDERED',name,flush=True)

def zombie(t,at,scale,outfit):
 spawn('Z_Base',at,scale,tints={'Body':outfit,'Ring':'FFC84C'},skip=('Hair','Brain'));spawn('Z_'+t,at,scale)

def hero():
 clear();ground(135)
 spawn('V3_House1',(0,18,0));spawn('V3_MergeTable',(9.5,21,.6));spawn('V3_CoffinRack',(2,31.8,.6));light((0,19,9.8),2000)
 for x in [-20,-10]:
  for y in [-16,-26]:spawn('V3_Bed',(x,y,0),scale=1.4)
 zombie('Pajama',(-20,-26,.42),1,'8ED8FF');zombie('Gardener',(-10,-26,.42),1,'FFE08A');zombie('King',(-17,-14,.42),2.8,'8C4BFF')
 for x in [10,16,22]:
  spawn('V3_GraveBorder',(x,-24,0));spawn('G_Stone',(x,-24,.1));spawn('G_Mound',(x,-24,.1))
 spawn('V3_UpgradeBoard',(8,-32,0));spawn('V3_GateArch',(0,-38,0))
 for x in [-32,-24,-16,16,24,32]:spawn('V3_Fence',(x,-38,0))
 for x in [-36,36]:
  for y in [-34,-26,-18,-10,-2]:spawn('V3_Fence',(x,y,0),rot=90)
  for y in [-38,-6]:spawn('V3_FencePost',(x,y,0))
 for x in [38,46,54,62]:
  for y in [-30,-22,-14,-6,2]:spawn('V3_PathTile',(x,y,0))
 spawn('V3_StallWeapons',(49,8,0));spawn('V3_GiftChest',(47,-13,0));spawn('Pet_FarmerCat',(54,-13,.1),scale=1.5,rot=-20);spawn('M_Imp',(55,-24,0),scale=1.6,rot=-25)
 for x,y,k in [(-32,24,1.5),(32,32,1.6),(61,26,1.3),(-32,-10,1.2)]:spawn('V3_Tree',(x,y,0),scale=k)
 for x,y in [(-7,-35),(8,-35),(39,-3),(61,-3)]:spawn('V3_Lantern',(x,y,0))
 for x,y in [(-32,-32),(32,-2),(-28,6),(30,30)]:spawn('V3_Bush',(x,y,.5),scale=1.5)
 render('geometry-farm-plaza',(108,-155,98),(10,-2,5),(2000,1250),52)

def houses():
 clear();ground(250,'B9D7C8')
 for i in range(5):spawn('V3_House'+str(i+1),((i-2)*60,0,0));label('LEVEL '+str(i+1),((i-2)*60,-29,.2),3)
 render('houses-levels-1-5',(100,-300,148),(0,0,12),(2400,1000),49)

def interior():
 clear();spawn('V3_House3');spawn('V3_MergeTable',(9.5,3,.6));spawn('V3_CoffinRack',(2,13.8,.6))
 light((0,1,9.8),2200);light((10,9,9.5),1000)
 render('house-interior',(11,-13,7),(-8,7,6),(1600,1000),24,fit=False)

def weapons():
 clear()
 for i,name in enumerate(['Deagle','AK','M4','AWP']):
  x=(i%2)*5.5-2.75;z=3.3-(i//2)*3.3
  spawn('V3_Gun'+name,(x,0,z),rot=-68)
  label(name,(x,-.15,z-1.4),.45)
 render('weapons-deagle-ak-m4-awp',(1,-16,9),(0,0,1.4),(1800,1100),55)

def tools():
 clear()
 for i,name in enumerate(['Rusty','Steel','Combat','Bone','Golden','Lunar','Rainbow']):
  x=(i-3)*1.7;spawn('V3_Shovel'+name,(x,0,2.5),rot=-10);label(name.upper(),(x,-.1,-.2),.21)
 spawn('V3_Trap',(0,-5,-.4));label('TRAP',(0,-7,-.4),.4)
 render('shovels-and-trap',(5,-22,15),(0,-1,1.8),(1900,1150),54)

def plaza():
 clear();ground(90,'B9D7C8')
 for i,name in enumerate(['Weapons','Pets','Brawler']):spawn('V3_Stall'+name,((i-1)*15,0,0));label(name.upper(),((i-1)*15,-5,.1),1)
 for name,x in [('V3_GiftChest',-14),('V3_RewardChest',-5),('V3_QuestBoard',7),('V3_UpgradeBoard',17)]:spawn(name,(x,-15,0))
 render('plaza-shops-chests',(38,-65,42),(0,-5,3),(1900,1100),50)

def treadmills():
 clear();ground(100,'B9D7C8')
 for i in range(5):spawn('V3_Treadmill'+str(i+1),((i-2)*11,0,0));label('LEVEL '+str(i+1),((i-2)*11,-9,.1),1)
 render('treadmills-1-5',(35,-65,43),(0,0,3),(2000,1000),52)

def road():
 clear();ground(220,'B9D7C8')
 for i,name in enumerate(['YardGarage','Mall','Factory','Clinic','ChiefOffice']):
  x=(i-2)*32;spawn('V3_'+name,(x,0,0));label(name.upper(),(x,-15,.1),1.4)
  for j,prop in enumerate(['V3_Crates','V3_Bench'] if i<2 else ['V3_MutagenTank','V3_Barricade'] if i==2 else ['V3_ClinicCart','V3_Rock']):spawn(prop,(x-6+j*12,-11,0))
 render('road-landmarks',(75,-190,95),(0,0,7),(2400,1100),53)
def cube(at,size,col,name):
 bpy.ops.mesh.primitive_cube_add(size=1,location=at);o=bpy.context.object;o.name=name;o.scale=size
 m=bpy.data.materials.new(name);m.use_nodes=True;m.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(*[x**2.2 for x in kit._rgb(col)],1);o.data.materials.append(m)

def roadfull():
 clear();ground(520,'85B786')
 sections=[(0,75,'78B84C','YARD'),(75,160,'CDAF85','MALL'),(160,240,'5F857D','MUTAGEN'),(247,315,'87B8B0','CLINIC'),(315,385,'9380AD','CHIEF')]
 for start,end,col,title in sections:
  cube((0,(start+end)/2,-.45),(96,end-start,1),col,'RoadFloor')
  label(title,(0,start+10,.2),4)
  for x in [-46,46]:cube((x,(start+end)/2,.15),(1,end-start,.3),'C7C1A6','Curb')
 for x in [-49,49]:
  for y in range(12,385,24):spawn('V3_Wall',(x,y,0),rot=90 if x>0 else -90)
 for x in range(-36,49,24):spawn('V3_Wall',(x,385,0))
 spawn('V3_RoadArch',(0,0,0))
 for i,(name,y) in enumerate([('YardGarage',32),('Mall',105),('Factory',205),('Clinic',280),('ChiefOffice',360)]):
  side=-1 if i%2==0 else 1;spawn('V3_'+name,(side*39,y,0),rot=-side*90)
  spawn('V3_RoadSign',(-side*40,y-21,0),rot=-side*90)
  for d in [-24,24]:spawn('V3_Lantern',(-side*42,y+d,0),scale=1.3)
  for j in range(3):
   prop='V3_Tree' if i==0 else 'V3_Crates' if i==1 else 'V3_MutagenTank' if i==2 else 'V3_ClinicCart' if i==3 else 'V3_Rock'
   spawn(prop,(-side*(35+j%2*6),y-14+j*15,0),rot=-side*90)
 for y,x in [(55,-29),(55,29),(145,-10),(190,24),(295,-24),(310,24)]:
  for dx in [-8,0,8]:spawn('V3_Barricade',(x+dx,y,0))
 for y,x in [(130,-26.7),(165,26.7),(235,-29.3),(270,29.3),(345,-21.3),(365,21.3)]:spawn('G_Stone',(x,y,.1));spawn('G_Mound',(x,y,.1))
 for y in [120,175,225,255,330,372]:spawn('M_Imp',(7 if y%2 else -7,y,0),scale=1.5)
 render('road-five-districts',(240,-300,360),(0,180,0),(1800,2200),48)

args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ['hero','houses','interior','weapons','tools','plaza','treadmills','road']
for name in args:globals()[name]()
