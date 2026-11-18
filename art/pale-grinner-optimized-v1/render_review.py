"""Compare the delivery GLBs to V4 from the same camera and on the same studio stage."""
import bpy
import tempfile
from pathlib import Path
from mathutils import Vector

ROOT=Path(__file__).resolve().parent
SOURCE=ROOT.parent/"pale-grinner-v4"
out=Path(tempfile.gettempdir())/"pale-grinner-optimization-review"
out.mkdir(exist_ok=True)
for name in ("PaleGrinner","PaleGrinnerAggressive"):
    for version,folder in (("V4",SOURCE),("Optimized",ROOT)):
        bpy.ops.wm.open_mainfile(filepath=str(SOURCE/"models"/(name+".blend")))
        scene=bpy.context.scene
        for ob in list(bpy.data.collections["PaleGrinner"].objects):
            bpy.data.objects.remove(ob,do_unlink=True)
        for clip in list(bpy.data.actions):
            bpy.data.actions.remove(clip)
        bpy.ops.import_scene.gltf(filepath=str(folder/"models"/(name+".glb")))
        if name.endswith("Aggressive"):
            rig=next(o for o in scene.objects if o.type=="ARMATURE")
            action,=bpy.data.actions
            anim=rig.animation_data_create()
            for track in anim.nla_tracks: track.mute=True
            anim.action=action
            start,end=action.frame_range
            scene.frame_set(round(start+(end-start)*.44))
            target=(0,-1.06,5.95);direction=(14,-6.2,.7);scale=4.75
        else:
            target=(0,-.10,6.36);direction=(3,-16,.4);scale=3.16
        cam=scene.camera
        cam.location=Vector(target)+Vector(direction)
        cam.rotation_euler=(-Vector(direction)).to_track_quat("-Z","Y").to_euler()
        cam.data.ortho_scale=scale
        scene.render.resolution_x,scene.render.resolution_y=560,500
        scene.cycles.samples=32
        scene.render.film_transparent=True
        for ob in scene.objects:
            if ob.type=="MESH" and not ob.find_armature(): ob.hide_render=True
        scene.render.image_settings.color_mode="RGBA"
        scene.render.filepath=str(out/(name+"_"+version+".png"))
        bpy.ops.render.render(write_still=True)
