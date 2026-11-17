"""Consistent reimported-GLB renders for original/compact/mobile visual review."""
import sys
import json
from pathlib import Path
import bpy
from mathutils import Vector

ROOT=Path(__file__).resolve().parent
report=json.loads((ROOT/'report.json').read_text())
args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
mobile_only='MobileOnly' in args
args=[role for role in args if role!='MobileOnly']
for asset in report['models']:
    if args and asset['role'] not in args:continue
    for profile,key in [('original','model'),('full','output'),('mobile','mobile_file')]:
        if mobile_only and profile!='mobile':continue
        # Full geometry/data identity is independently tested; render it for the
        # detailed farmer comparison, and render original/mobile for every outfit.
        if profile=='full' and asset['role'] not in ('Farmer','Base'):continue
        bpy.ops.wm.open_mainfile(filepath=asset['blend'])
        objects=[o for o in bpy.context.scene.objects if o.type=='ARMATURE' or
                 o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers)]
        for ob in objects:bpy.data.objects.remove(ob,do_unlink=True)
        path=Path(asset[key]) if key=='model' else ROOT/asset[key]
        bpy.ops.import_scene.gltf(filepath=str(path))
        scene=bpy.context.scene
        scene.cycles.samples=16;scene.cycles.use_denoising=True
        scene.cycles.seed=29
        scene.render.resolution_x=720;scene.render.resolution_y=900
        scene.render.resolution_percentage=100
        cam=scene.camera;cam.location=(7,-25,8.6)
        cam.rotation_euler=(Vector((-.1,-.15,3.95))-cam.location).to_track_quat('-Z','Y').to_euler()
        cam.data.ortho_scale=10.5
        destination=ROOT/'previews'/profile/(asset['id']+'.png')
        destination.parent.mkdir(exist_ok=True)
        scene.render.filepath=str(destination)
        bpy.ops.render.render(write_still=True)
        if asset['role']=='Farmer':
            cam.location=(1.4,-15,7.2)
            cam.rotation_euler=(Vector((0,-.3,6.15))-cam.location).to_track_quat('-Z','Y').to_euler()
            cam.data.ortho_scale=3.25
            scene.render.resolution_x=800;scene.render.resolution_y=800
            scene.render.filepath=str(destination.with_name(asset['id']+'_Face.png'))
            bpy.ops.render.render(write_still=True)
        print('REVIEW_RENDERED',asset['id'],profile,flush=True)
