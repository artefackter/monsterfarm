"""Generate a new reviewable Dealer revision without changing Studio or the current V2."""
import sys,json,math
from pathlib import Path
import bpy
HERE=Path(__file__).resolve().parent;sys.path.insert(0,str(HERE));sys.path.insert(0,str(HERE.parent/'tools'))
import kit
import assets_dealer_v3 as assets
from package_monster_prototypes import write_pack
OUT=HERE.parent/'export/collection-v2/road-v3/dealer-v3';PREVIEW=HERE.parent/'preview/road-v3'
OUT.mkdir(parents=True,exist_ok=True);PREVIEW.mkdir(parents=True,exist_ok=True)
for state in ('Passive','Aggressive'):assets.dealer(state)
manifest,baked,total=kit.export_all(str(OUT))
(OUT/'_manifest.json').write_text(json.dumps(manifest,indent=2));(OUT/'_rig.json').write_text(json.dumps(assets.JOINTS,indent=2))
path,report=write_pack(OUT,manifest,assets.JOINTS,total,floating=set(manifest));path.rename(OUT/'DealerV3.glb')
(OUT/'_validation.json').write_text(json.dumps(report,indent=2))
def clear():
 for o in list(bpy.data.objects):bpy.data.objects.remove(o,do_unlink=True)
def spawn(state,x,angle=0,head_only=False):
 name='BuckshotDealer_'+state
 parts=[p for p in manifest[name] if p['part']!='Body' and (not head_only or p['part']=='Head')]
 kit.spawn_preview(baked,name,parts,(x,0,0),rot_z=angle)
 for o in bpy.context.scene.objects:
  if o.type=='MESH':o.data.materials[0].node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.90
def render(file,camera,target,width,res):
 kit.setup_render(str(PREVIEW/file),camera,target,res=res,samples=48,bg='313039')
 s=bpy.context.scene;s.cycles.use_denoising=True;s.camera.data.type='ORTHO';s.camera.data.ortho_scale=width
 s.view_settings.view_transform='AgX';bpy.ops.render.render(write_still=True)
clear();spawn('Passive',-3.4,-5);spawn('Aggressive',3.4,-10)
render('BuckshotDealerV3.png',(0,-30,9),(0,0,3.05),13.7,(1900,1200))
bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'DealerV3.blend'))
clear();spawn('Passive',-2.5,0,True);spawn('Aggressive',2.5,-8,True)
render('BuckshotDealerV3-face.png',(0,-23,6.6),(0,0,4.3),10.5,(1900,1000))
print('DEALER_V3_COMPLETE',json.dumps(report),flush=True)
