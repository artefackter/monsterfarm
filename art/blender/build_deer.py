"""Build the approval-stage deer pack and render actual mesh geometry (not concept art)."""
import sys, json, math
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import bpy, kit, assets_deer
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'export'/'deer';PREVIEW=ROOT/'preview'/'deer'
OUT.mkdir(parents=True,exist_ok=True);PREVIEW.mkdir(parents=True,exist_ok=True)
assets_deer.build()
manifest,baked,total=kit.export_all(str(OUT))
(OUT/'_manifest.json').write_text(json.dumps(manifest,indent=2))
(OUT/'_rig.json').write_text(json.dumps({'coordinates':'Roblox (-BlenderX, BlenderZ, BlenderY)',
    'feetY':0,'joints':assets_deer.JOINTS,'separateHandItems':True},indent=2))
stats={name:{'parts':len(parts),'triangles':sum(p['tris'] for p in parts),
    'height':max(p['offset'][1]+p['size'][1]/2 for p in parts)} for name,parts in manifest.items()}
assert all(p['tris']<10000 for parts in manifest.values() for p in parts)
(OUT/'_validation.json').write_text(json.dumps({'totalTriangles':total,'assets':stats,
    'status':'Awaiting render approval; no Studio imports or gameplay changes'},indent=2))
print(json.dumps(stats),flush=True)

def clear():
    for ob in list(bpy.data.objects):bpy.data.objects.remove(ob,do_unlink=True)

def material(name,color):
    m=bpy.data.materials.new(name);m.use_nodes=True
    pb=m.node_tree.nodes.get('Principled BSDF');pb.inputs['Base Color'].default_value=(*[x**2.2 for x in kit._rgb(color)],1)
    pb.inputs['Roughness'].default_value=.72
    return m

def floor():
    bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.17))
    bpy.context.object.data.materials.append(material('Studio backdrop','B5CDD3'))

def plinth(x,scale=1):
    bpy.ops.mesh.primitive_cylinder_add(vertices=48,radius=2.32*scale,depth=.16,location=(x,0,-.08))
    o=bpy.context.object;o.data.materials.append(material('Stone base','637E88'))
    mod=o.modifiers.new('Soft edge','BEVEL');mod.width=.06;mod.segments=2

FONT=bpy.data.fonts.load('/System/Library/Fonts/Supplemental/Arial Bold.ttf')
def text(value,x,y,z,size=.46,color='243142'):
    c=bpy.data.curves.new(value,'FONT');c.body=value;c.align_x='CENTER';c.size=size;c.font=FONT;c.extrude=.002
    o=bpy.data.objects.new(value,c);bpy.context.scene.collection.objects.link(o);o.location=(x,y,z);o.rotation_euler=(math.pi/2,0,0)
    c.materials.append(material('Text',color))

def spawn(name,x=0,scale=1,angle=0):
    before=set(bpy.data.objects)
    kit.spawn_preview(baked,name,manifest[name],(x,0,0),scale=scale,rot_z=angle)
    for ob in set(bpy.data.objects)-before:
        ob.name=name+'__'+ob.name
        if ob.name.startswith(name+'__EyesGlow'):
            pb=ob.data.materials[0].node_tree.nodes.get('Principled BSDF')
            pb.inputs['Emission Color'].default_value=(1,.008,.002,1);pb.inputs['Emission Strength'].default_value=.45

def render(name,cam,look,width,res):
    kit.setup_render(str(PREVIEW/(name+'.png')),cam,look,res=res,samples=32,bg='CCDDEA')
    s=bpy.context.scene;s.cycles.use_denoising=True;s.camera.data.type='ORTHO';s.camera.data.ortho_scale=width
    for light in bpy.data.lights:
        if light.type=='SUN':light.energy=1.6
    s.world.node_tree.nodes['Background'].inputs[1].default_value=.65
    s.render.image_settings.file_format='PNG'
    # Large frontal softbox and cool rear fill keep dark antlers readable.
    for at,power,size in [((-5,-10,13),1100,8),((7,3,10),800,6)]:
        l=bpy.data.lights.new('Softbox','AREA');l.energy=power;l.shape='DISK';l.size=size
        o=bpy.data.objects.new('Softbox',l);s.collection.objects.link(o);o.location=at;o.rotation_euler=(Vector(look)-o.location).to_track_quat('-Z','Y').to_euler()
    bpy.ops.wm.save_as_mainfile(filepath=str(PREVIEW/(name+'.blend')))
    bpy.ops.render.render(write_still=True)
    print('RENDERED '+name,flush=True)

clear();floor()
for x,kind,title in [(-10.5,'Farmer','ФЕРМЕР'),(-3.5,'Punk','НЕФОР'),(3.5,'Assassin','УБИЙЦА'),(10.5,'Chief','ГЛАВВРАЧ')]:
    spawn('Deer_'+kind,x,1.06 if kind=='Chief' else 1,angle=-8)
    plinth(x);text(title,x,-2.55,.01,.46)
text('ОЛЕНИ  /  ВЕРСИЯ 2',0,.7,10.10,.55)
render('deer-lineup',(1,-40,13),(0,0,4.5),29.4,(2800,1350))

clear();floor();spawn('Deer_Chief',angle=-12);plinth(0)
text('ГЛАВВРАЧ',0,.65,9.7,.52)
render('chief-detail',(6,-23,10),(0,0,4.65),11.2,(1400,1400))

clear();floor()
for x,kind,title in [(-10.5,'Farmer','ФЕРМЕР'),(-3.5,'Punk','НЕФОР'),(3.5,'Assassin','УБИЙЦА'),(10.5,'Chief','ГЛАВВРАЧ')]:
    spawn('Deer_'+kind,x,1.06 if kind=='Chief' else 1,angle=155);plinth(x)
    text(title,x,-2.55,.01,.46)
text('ВИД СЗАДИ  /  ВЕРСИЯ 2',0,.7,10.10,.55)
render('deer-back',(1,-40,13),(0,0,4.5),29.4,(2800,1350))
