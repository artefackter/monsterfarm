"""Build, export and render the garden style test before any live replacement."""
import sys,json,math
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import bpy,numpy as np
from mathutils import Vector
import kit,assets_environment_v4

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'export/environment-v4';PREVIEW=ROOT/'preview/environment-v4'
OUT.mkdir(parents=True,exist_ok=True);PREVIEW.mkdir(parents=True,exist_ok=True)
assets_environment_v4.build()
manifest,baked,total=kit.export_all(str(OUT))
(OUT/'_manifest.json').write_text(json.dumps(manifest,indent=2))
assert all(p['tris']<10000 for ps in manifest.values() for p in ps)
stats={'totalTriangles':total,'status':'Awaiting style approval; no live replacements',
       'assets':{n:{'parts':len(ps),'triangles':sum(p['tris'] for p in ps)} for n,ps in manifest.items()}}
(OUT/'_validation.json').write_text(json.dumps(stats,indent=2));print(json.dumps(stats),flush=True)

# A deterministic, periodic lawn texture. Low contrast; no grass geometry across the map.
N=512;yy,xx=np.mgrid[0:N,0:N]/N;rng=np.random.default_rng(72);field=np.zeros((N,N))
for f,amp,count in [(3,1.0,12),(10,.40,18),(35,.16,20),(100,.045,24)]:
    band=np.zeros_like(field)
    for _ in range(count):
        kx,ky=rng.integers(-f,f+1,2);phase=rng.uniform(0,math.tau)
        band+=np.sin(math.tau*(kx*xx+ky*yy)+phase)
    field+=band/math.sqrt(count)*amp
field=np.clip(field,-2.5,2.5)
rgb=np.array([145,166,46])[None,None,:]+field[:,:,None]*np.array([3.8,4.0,2.5])[None,None,:]
rgba=np.concatenate((np.clip(rgb/255,0,1),np.ones((N,N,1))),axis=2).astype('float32')
tex=bpy.data.images.new('GardenLawn_Seamless',width=N,height=N,alpha=False)
tex.pixels.foreach_set(rgba.reshape(-1));tex.filepath_raw=str(OUT/'GardenLawn_Seamless.png');tex.file_format='PNG';tex.save();tex.pack()

def load_reference(folder,chosen):
    m=json.loads((folder/'_manifest.json').read_text())
    for name in chosen:
        manifest[name]=m[name]
        for p in m[name]:
            d=json.loads((folder/(p['mesh']+'.json')).read_text());v=d['v'];o=p['offset']
            verts=[Vector((-(v[i]+o[0]),v[i+2]+o[2],v[i+1]+o[1])) for i in range(0,len(v),3)]
            baked[name,p['part']]=(verts,[((c>>16&255)/255,(c>>8&255)/255,(c&255)/255) for c in d['c']],d['t'])
load_reference(ROOT/'export/v3',['V3_House1','V3_Treadmill1'])
load_reference(ROOT/'references/v3',['Z_Base','Z_Gardener','G_Stone','G_Mound'])

placed_tiles=set()
def clear():
    placed_tiles.clear()
    for o in list(bpy.data.objects):bpy.data.objects.remove(o,do_unlink=True)

def spawn(name,at=(0,0,0),scale=1,angle=0,skip=(),tints=None):
    before=set(bpy.data.objects)
    kit.spawn_preview(baked,name,[m for m in manifest[name] if m['part'] not in skip],at,scale=scale,rot_z=angle,tints=tints)
    for ob in set(bpy.data.objects)-before:ob.name=name+'__'+ob.name

def simple_material(name,color):
    m=bpy.data.materials.new(name);m.use_nodes=True
    bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*[c**2.2 for c in kit._rgb(color)],1);bs.inputs['Roughness'].default_value=.9
    return m

def lawn(size=180):
    bpy.ops.mesh.primitive_plane_add(size=size,location=(0,0,-.025));o=bpy.context.object;o.name='Lawn'
    m=bpy.data.materials.new('Seamless garden grass');m.use_nodes=True;n=m.node_tree.nodes;l=m.node_tree.links
    bs=n.get('Principled BSDF');bs.inputs['Roughness'].default_value=.95
    geometry=n.new('ShaderNodeNewGeometry');scale=n.new('ShaderNodeVectorMath');scale.operation='SCALE';scale.inputs[3].default_value=1/16
    img=n.new('ShaderNodeTexImage');img.image=tex;img.extension='REPEAT'
    l.new(geometry.outputs['Position'],scale.inputs[0]);l.new(scale.outputs[0],img.inputs['Vector']);l.new(img.outputs['Color'],bs.inputs['Base Color'])
    o.data.materials.append(m)

def path(a,b):
    a,b=Vector(a),Vector(b);d=b-a;n=round(d.length/3.95)
    for j in range(n+1):
        p=a.lerp(b,j/max(1,n))
        if any((p-Vector(q)).length<3.0 for q in placed_tiles):continue
        placed_tiles.add(tuple(p));spawn('ENV_Tile'+str(j%3+1),(p.x,p.y,.005),angle=0 if abs(d.y)>abs(d.x) else 90)

def fence_line(a,b):
    a,b=Vector(a),Vector(b);d=b-a;n=round(d.length/8);angle=math.degrees(math.atan2(d.y,d.x))
    for j in range(n):
        p=a.lerp(b,(j+.5)/n);spawn('ENV_Fence',(p.x,p.y,0),angle=angle)
    # The following segment supplies the corner post; avoid coincident duplicate geometry.

def render(name,cam,look,width,res):
    kit.setup_render(str(PREVIEW/(name+'.png')),cam,look,res=res,samples=40,bg='A6CFF1')
    s=bpy.context.scene;s.cycles.use_denoising=True;s.camera.data.type='ORTHO';s.camera.data.ortho_scale=width
    for light in bpy.data.lights:
        if light.type=='SUN':light.energy=2.0;light.angle=math.radians(9);light.color=(1.0,.94,.82)
    s.world.node_tree.nodes['Background'].inputs[1].default_value=.85
    s.world.node_tree.nodes['Background'].inputs[0].default_value=(.72,.80,.90,1)
    s.render.image_settings.file_format='PNG'
    bpy.ops.wm.save_as_mainfile(filepath=str(PREVIEW/(name+'.blend')))
    bpy.ops.render.render(write_still=True);print('RENDERED',name,flush=True)

clear();lawn()
fence_line((-24,-24),(-8,-24));fence_line((8,-24),(24,-24));fence_line((-24,24),(-24,-24));fence_line((24,-24),(24,24));fence_line((24,24),(-24,24))
spawn('ENV_Gate',(0,-24,0),scale=1.05)
spawn('ENV_FencePost',(-8,-24,0))
path((0,-38),(0,8));path((-16,-6),(16,-6));path((16,-6),(16,5))
spawn('V3_House1',(10,15,0),scale=.37)
spawn('V3_Treadmill1',(-15,-13,.03),scale=.68)
for x,y,name,scale in [(-29,16,'ENV_TreeA',1),(29,19,'ENV_TreeB',1.2),(-29,-13,'ENV_TreeC',1),(21,-32,'ENV_TreeA',.9),(0,32,'ENV_TreeB',1)]:
    spawn(name,(x,y,0),scale=scale,angle=x*7)
for x,y in [(-20,20),(-21,-20),(21,22),(27,10),(-28,7),(7,25)]:spawn('ENV_Bush',(x,y,0),scale=1.3)
for x,y in [(-20,-5),(-22,10),(19,-19),(10,-21),(20,0),(-7,22),(28,-15),(-16,-20)]:spawn('ENV_Tuft',(x,y,0),scale=1.2)
spawn('Z_Base',(-6,-10,.07),skip=('Hair','Brain','Ring'),tints={'Body':'E7BC5C'})
spawn('Z_Gardener',(-6,-10,.07))
render('garden-style',(60,-84,70),(0,0,3),85,(2000,1500))

clear();lawn()
spawn('ENV_TreeA',(-12,5,0));spawn('ENV_TreeB',(2,7,0));spawn('ENV_TreeC',(17,7,0))
fence_line((-21,-7),(19,-7));path((-17,-16),(19,-16))
spawn('ENV_Bush',(-17,-3,0),scale=1.8);spawn('ENV_Tuft',(-12,-3,0),scale=1.8)
render('environment-lineup',(30,-62,36),(0,0,5),61,(2200,1300))

clear();lawn(70);fence_line((-12,4),(12,4));spawn('ENV_TreeB',(-12,11,0),scale=.72)
path((-16,-7),(16,-7));path((0,-7),(0,-19));spawn('ENV_Bush',(11,9,0),scale=1.6)
spawn('ENV_Tuft',(-7,1,0));spawn('ENV_Tuft',(9,-2,0))
render('grass-paving-fence',(24,-34,29),(0,-2,1),36,(1700,1200))
