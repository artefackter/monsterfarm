"""Render actual original and optimized GLBs with identical review settings."""
import bpy, json, sys
from pathlib import Path
from mathutils import Vector

ROOT=Path(__file__).resolve().parent
PREVIEW=ROOT/'previews';PREVIEW.mkdir(exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene;scene.render.engine='CYCLES'
scene.cycles.samples=40;scene.cycles.use_denoising=True
scene.render.resolution_x=1200;scene.render.resolution_y=1200;scene.render.resolution_percentage=100
scene.view_settings.view_transform='AgX'
scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs['Color'].default_value=(.28,.24,.34,1)
scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.65
floor=bpy.data.materials.new('ReviewFloor');floor.use_nodes=True
def lin(v):return v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4
floor.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=tuple(lin(int(v,16)/255) for v in ('51','4B','5C'))+(1,)
floor.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.75
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.025));bpy.context.object.data.materials.append(floor)
for p,e,s in [((-8,-10,16),2200,9),((9,-1,12),1500,8),((0,10,13),2600,7)]:
    bpy.ops.object.light_add(type='AREA',location=p);l=bpy.context.object;l.data.energy=e;l.data.size=s
    l.rotation_euler=(Vector((0,0,3.8))-l.location).to_track_quat('-Z','Y').to_euler()
for x in (-2.91,2.91):
    bpy.ops.object.light_add(type='POINT',location=(x,-5.12,2.46));l=bpy.context.object
    l.data.energy=12;l.data.color=(.63,.12,1);l.data.shadow_soft_size=.65
bpy.ops.object.camera_add();cam=bpy.context.object;scene.camera=cam
cam.data.type='ORTHO';cam.data.ortho_scale=14.7
stage=set(scene.objects)
stats={}
for label,path in [('original',ROOT.parent/'crypt-v1'/'Crypt.glb'),('optimized',ROOT/'Crypt-optimized.glb')]:
    bpy.ops.import_scene.gltf(filepath=str(path))
    imported=[ob for ob in scene.objects if ob not in stage]
    coords=[o.matrix_world@v.co for o in imported if o.type=='MESH' for v in o.data.vertices]
    stats[label]={'meshes':sum(o.type=='MESH' for o in imported),
        'bounds':[[min(v[i] for v in coords),max(v[i] for v in coords)] for i in range(3)]}
    for view,pos in [('three_quarter',(14,-22,15)),('front',(0,-26,10)),('back',(-16,22,14))]:
        target=Vector((0,-.7,3.8));cam.location=pos
        cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
        scene.cycles.seed=42
        scene.render.filepath=str(PREVIEW/(label+'_'+view+'.png'))
        bpy.ops.render.render(write_still=True)
    for ob in imported:bpy.data.objects.remove(ob,do_unlink=True)
(ROOT/'reimport.json').write_text(json.dumps(stats,indent=2)+'\n')
assert all(abs(stats['original']['bounds'][i][j]-stats['optimized']['bounds'][i][j])<1e-5 for i in range(3) for j in range(2))
print('REIMPORT_RENDER_VERIFIED',json.dumps(stats),flush=True)
