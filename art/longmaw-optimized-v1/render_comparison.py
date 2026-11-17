"""Render imported source/full/mobile exports under identical stage settings."""
import sys
import json
from pathlib import Path
import bpy
from mathutils import Vector
ROOT=Path(__file__).resolve().parent;sys.path.insert(0,str(ROOT))
from assets import models,verify_sources
verify_sources()
bpy.ops.wm.open_mainfile(filepath=str(ROOT.parent/'longmaw-v5/models/Longmaw_Review.blend'))
stage=bpy.data.collections['Preview_Only']
def clear():
    for ob in list(bpy.context.scene.objects):
        if stage not in ob.users_collection:bpy.data.objects.remove(ob,do_unlink=True)
clear();scene=bpy.context.scene;scene.render.engine='CYCLES'
scene.cycles.samples=12;scene.cycles.use_denoising=True
scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA'
camera=scene.camera;camera.data.type='ORTHO'
manifest=[]
for asset in models():
    for profile in ('source','models','mobile'):
        clear();source=asset['source'] if profile=='source' else ROOT/profile/(asset['id']+'.glb')
        bpy.ops.import_scene.gltf(filepath=str(source))
        for view,pos,target,scale,size in [('Full',(14,-18,9.1),(0,-.1,3.25),9.4,(560,680))]+(
            [('Head',(7,-14,7.4),(0,-1.65,5.80),3.7,(620,580))]
            if asset['role'] in ('Base','Punk','Knight','Assassin') and asset['state']=='Idle' else []):
            output=ROOT/'previews/raw'/(asset['id']+'_'+profile+'_'+view+'.png')
            output.parent.mkdir(parents=True,exist_ok=True)
            camera.location=pos;camera.rotation_euler=(Vector(target)-camera.location).to_track_quat('-Z','Y').to_euler()
            camera.data.ortho_scale=scale
            scene.render.resolution_x,scene.render.resolution_y=size
            scene.render.filepath=str(output)
            bpy.ops.render.render(write_still=True)
            manifest.append({'id':asset['id'],'profile':profile,'view':view,'file':str(output.relative_to(ROOT))})
            print('COMPARISON_RENDERED',asset['id'],profile,view,flush=True)
(ROOT/'render_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('RENDER_COMPARISON_COMPLETE',len(manifest),'UNCHANGED',verify_sources(),flush=True)
