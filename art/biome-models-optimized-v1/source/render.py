"""Re-import actual delivery GLBs, verify dimensions, render, save review .blend.
Stage, labels, lighting and camera exist only in the review Blender file.
"""
from pathlib import Path
import sys,json,math
import bpy
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[1]
CAT=json.loads((ROOT/'catalog.json').read_text())['assets']
LAYOUT=json.loads((ROOT/'review-layout.json').read_text())
PALETTES={'backrooms':'B7A888','blood_mine':'8A7978','village':'98816F','city':'8A8983','parasitown':'89827B'}
TITLES={'backrooms':'01 / BACKROOMS','blood_mine':'02 / BLOOD MINE','village':'03 / ABANDONED VILLAGE','city':'04 / ABANDONED CITY','parasitown':'05 / PARASITOWN'}

def linear(v):return v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4
def rgb(h):return tuple(linear(int(h[i:i+2],16)/255) for i in [0,2,4])

def mat(name,color,emission=False):
    m=bpy.data.materials.new(name);m.diffuse_color=(*rgb(color),1);m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*rgb(color),1);p.inputs['Roughness'].default_value=.9
    if emission:p.inputs['Emission Color'].default_value=(*rgb(color),1);p.inputs['Emission Strength'].default_value=.7
    return m

def bounds(objects):
    verts=[o.matrix_world@Vector(v) for o in objects if o.type=='MESH' for v in o.bound_box]
    return Vector([min(v[i] for v in verts) for i in range(3)]),Vector([max(v[i] for v in verts) for i in range(3)])

def add_cube(name,loc,size,m):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=size
    o.data.materials.append(m);return o

def add_text(name,body,loc,size,m,rot=(0,0,math.pi)):
    f=bpy.data.curves.new(name,'FONT');f.body=body;f.size=size;f.align_x='CENTER';f.align_y='CENTER'
    o=bpy.data.objects.new(name,f);bpy.context.scene.collection.objects.link(o);o.location=loc;o.rotation_euler=rot;f.materials.append(m)
    return o

def camera_fit(scene,lo,hi,aspect=1800/1050):
    target=(lo+hi)/2;direction=Vector((-.45,1,.91)).normalized()
    c=bpy.data.cameras.new('ReviewCamera');o=bpy.data.objects.new('ReviewCamera',c);scene.collection.objects.link(o)
    o.location=target+direction*250;o.rotation_euler=(target-o.location).to_track_quat('-Z','Y').to_euler();c.type='ORTHO';scene.camera=o
    basis=o.rotation_euler.to_matrix().transposed()
    corners=[Vector((x,y,z)) for x in (lo.x,hi.x) for y in (lo.y,hi.y) for z in (lo.z,hi.z)]
    local=[basis@(v-target) for v in corners]
    width=max(v.x for v in local)-min(v.x for v in local);height=max(v.y for v in local)-min(v.y for v in local)
    c.ortho_scale=max(width,height*aspect)*1.12;c.lens=50;c.clip_end=1000
    return o

def lights(scene):
    world=bpy.data.worlds.new(scene.name+'_World');world.use_nodes=True
    world.node_tree.nodes['Background'].inputs['Color'].default_value=(.73,.77,.82,1)
    world.node_tree.nodes['Background'].inputs['Strength'].default_value=.7;scene.world=world
    sun=bpy.data.lights.new('Daylight','SUN');sun.energy=1.8;sun.angle=.35
    o=bpy.data.objects.new('Daylight',sun);scene.collection.objects.link(o);o.rotation_euler=(.45,-.6,-.5)
    fill=bpy.data.lights.new('SoftFill','AREA');fill.energy=55000;fill.shape='DISK';fill.size=90
    o=bpy.data.objects.new('SoftFill',fill);scene.collection.objects.link(o);o.location=(-20,55,100);o.rotation_euler=(Vector((0,10,0))-o.location).to_track_quat('-Z','Y').to_euler()

def configure(scene,path):
    scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=32;scene.cycles.use_denoising=True
    scene.render.resolution_x=1800;scene.render.resolution_y=1050;scene.render.resolution_percentage=100
    scene.render.image_settings.file_format='PNG';scene.render.filepath=str(path)
    scene.view_settings.view_transform='Standard';scene.view_settings.look='None';scene.view_settings.exposure=0;scene.view_settings.gamma=1
    scene.render.film_transparent=False

bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
verify_scene=bpy.context.scene;verify_scene.name='ValidationTemporary'
verified=[]
for name,a in CAT.items():
    bpy.ops.import_scene.gltf(filepath=str(ROOT/a['file']))
    objects=list(verify_scene.objects);bpy.context.view_layer.update()
    mesh=[o for o in objects if o.type=='MESH'];lo,hi=bounds(objects)
    # Imported GLB Y-up -> Blender Z-up, depth changes sign.
    expected=a['bounds']['size'];actual=[hi.x-lo.x,hi.z-lo.z,hi.y-lo.y]
    assert all(abs(actual[i]-expected[i])<.004 for i in range(3)),(name,actual,expected)
    triangles=sum(len(o.data.polygons) for o in mesh)
    assert triangles==a['triangles'],(name,triangles,a['triangles'])
    assert len(mesh)==len(a['parts'])
    assert abs(lo.z)<.003,(name,lo.z)
    verified.append(dict(asset=name,meshes=len(mesh),triangles=triangles,size=[round(x,3) for x in actual],floor_z=round(lo.z,4)))
    for o in objects:bpy.data.objects.remove(o,do_unlink=True)
(ROOT/'blender-reimport-validation.json').write_text(json.dumps(dict(status='PASS',models=verified),indent=2))

for biome,layout in LAYOUT.items():
    scene=bpy.data.scenes.new(TITLES[biome]);bpy.context.window.scene=scene
    bpy.ops.import_scene.gltf(filepath=str(ROOT/'biome-packs'/(biome+'.glb')))
    bpy.context.view_layer.update();model_objects=list(scene.objects)
    # Imported model roots keep their own pivots and original names.
    assets_collection=bpy.data.collections.new('ASSETS__'+biome);scene.collection.children.link(assets_collection)
    for ob in model_objects:
        for c in list(ob.users_collection):c.objects.unlink(ob)
        assets_collection.objects.link(ob)
    lo,hi=bounds(model_objects);stage_min=Vector((lo.x-9,-7,-.5));stage_max=Vector((hi.x+9,hi.y+13,0))
    if biome=='parasitown':stage_max.y=max(stage_max.y,59)
    stage=add_cube('REVIEW_ONLY_Stage',(stage_min+stage_max)/2,stage_max-stage_min,mat('Stage_'+biome,PALETTES[biome]))
    stage['export_to_game']=False
    labelmat=mat('Label_'+biome,'EDE4D4',True)
    for name,loc in layout.items():
        x,y,z=loc;depth=CAT[name]['bounds']['size'][2]
        ly=-z+(depth/2 if CAT[name]['placement'] not in ['wall'] else depth)+4
        if CAT[name]['placement']=='arena_only':ly=-z+14
        label=name.replace('Entrance','Entry').replace('InfectedFacade','Facade').replace('ArenaTentacle','Arena').replace('CornerPartition','Corner').replace('DoorPartition','Door')
        add_text('LABEL_'+name,label,(x,ly,.13),1.25,labelmat)
    # Arena-only models shown on a distinct dark oval, not as road obstacles.
    if biome=='parasitown':
        arena_mat=mat('ArenaPreview','6E5555')
        for name in ['PT_ArenaTentacleTall','PT_ArenaTentacleHook']:
            loc=layout[name];bpy.ops.mesh.primitive_cylinder_add(vertices=32,radius=12,depth=.10,location=(loc[0],-loc[2],.01))
            bpy.context.object.name='REVIEW_ONLY_ArenaPad';bpy.context.object.data.materials.append(arena_mat)
        add_text('ArenaNote','ARENA ONLY',(31,54,.08),1.7,labelmat)
        stage_max.y=max(stage_max.y,59)
    # Background catcher, no new exported terrain.
    add_cube('REVIEW_ONLY_Background',(0,0,-1.4),(2000,2000,1),mat('Backdrop_'+biome,'CAD0D0'))
    fit_lo=Vector((stage_min.x,stage_min.y,-.5));fit_hi=Vector((stage_max.x,stage_max.y,hi.z+3))
    camera_fit(scene,fit_lo,fit_hi);lights(scene);configure(scene,ROOT/'previews'/(biome+'.png'))
    bpy.ops.render.render(write_still=True)
    print('RENDERED',biome,flush=True)

# Single master with one isolated scene per biome; no dependency on source GLB paths.
bpy.context.window.scene=bpy.data.scenes[TITLES['village']]
if verify_scene.name in bpy.data.scenes:bpy.data.scenes.remove(verify_scene)
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'Biomes_Optimized_v1.blend'))
print('REIMPORT PASS:',len(verified),'models; saved review .blend',flush=True)
