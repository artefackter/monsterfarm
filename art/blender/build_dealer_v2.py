"""Export only the corrected, floating Dealer and render the actual game geometry."""
import sys,json,math
from pathlib import Path
import bpy
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE));sys.path.insert(0,str(HERE.parent/'tools'))
import kit
import assets_dealer_v2 as assets
from package_monster_prototypes import write_pack
OUT=HERE.parent/'export/collection-v2/road-v3/dealer-v2'
PREVIEW=HERE.parent/'preview/road-v3'
OUT.mkdir(parents=True,exist_ok=True);PREVIEW.mkdir(parents=True,exist_ok=True)
for state in ('Passive','Aggressive'):assets.dealer(state)
manifest,baked,total=kit.export_all(str(OUT))
(OUT/'_manifest.json').write_text(json.dumps(manifest,indent=2))
(OUT/'_rig.json').write_text(json.dumps(assets.JOINTS,indent=2))
path,report=write_pack(OUT,manifest,assets.JOINTS,total,floating=set(manifest))
path.rename(OUT/'DealerV2.glb');(OUT/'_validation.json').write_text(json.dumps(report,indent=2))
for o in list(bpy.data.objects):bpy.data.objects.remove(o,do_unlink=True)
for state,x,angle in [('Passive',-3.8,-8),('Aggressive',3.8,-19)]:
    name='BuckshotDealer_'+state
    kit.spawn_preview(baked,name,manifest[name],(x,0,0),rot_z=angle)
    # Helpers are invisible both in the render and in the game manifest.
    for o in list(bpy.context.scene.objects):
        if o.name.startswith('Body'):o.hide_render=True
kit.setup_render(str(PREVIEW/'BuckshotDealerV2.png'),(0,-29,10),(0,0,3),res=(1900,1120),samples=40,bg='596A76')
bpy.context.scene.camera.data.type='ORTHO';bpy.context.scene.camera.data.ortho_scale=15
bpy.context.scene.view_settings.view_transform='AgX'
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'DealerV2.blend'))
bpy.ops.render.render(write_still=True)
print('DEALER_V2_COMPLETE',json.dumps(report),flush=True)
