"""Render the delivered GLBs beside their references on the approved portrait stage."""
import sys
from pathlib import Path
import tempfile

import bpy

ROOT=Path(__file__).resolve().parent
ART=ROOT.parent
sys.path.insert(0,str(ART/'floating-grin-v2'))
from build import camera

work=Path(tempfile.gettempdir())/'floating-grin-runtime-comparison'
work.mkdir(exist_ok=True)
base=ART/'floating-grin-v4'
cases=[
    ('FloatingGrin',base,(0,0,5.38),(0,-16,.05),2.9),
    ('FloatingGrinAggressive',base,(-.15,-1.2,4.25),(9,-12,1),5.45),
    ('FloatingGrinKing',ART/'floating-grin-forms-v1',(-.25,0,4.48),(2,-16,1.2),5.98),
]
for name,original,target,direction,scale in cases:
    for version,root in [('before',original),('after',ROOT)]:
        bpy.ops.wm.open_mainfile(filepath=str(base/'models/FloatingGrin.blend'))
        scene=bpy.context.scene
        for ob in list(bpy.data.collections['FloatingGrin'].objects):
            bpy.data.objects.remove(ob,do_unlink=True)
        for clip in list(bpy.data.actions):
            bpy.data.actions.remove(clip)
        bpy.ops.import_scene.gltf(filepath=str(root/'models'/(name+'.glb')))
        if name.endswith('Aggressive'):
            rig=next(o for o in scene.objects if o.type=='ARMATURE')
            anim=rig.animation_data_create()
            for track in anim.nla_tracks:
                track.mute=True
            anim.action,=bpy.data.actions
            start,end=anim.action.frame_range
            scene.frame_set(round(start+(end-start)*.42))
        camera(scene,target,direction,scale,(460,460))
        scene.render.resolution_percentage=100
        scene.render.engine='CYCLES'
        scene.cycles.samples=24
        scene.cycles.seed=19
        scene.render.image_settings.color_mode='RGBA'
        scene.render.film_transparent=True
        bpy.data.objects['Review Gradient'].hide_render=True
        scene.render.filepath=str(work/(name+'_'+version+'.png'))
        bpy.ops.render.render(write_still=True)
