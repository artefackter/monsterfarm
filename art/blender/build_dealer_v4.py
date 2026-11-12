"""Build and inspect Dealer V4 actual game meshes; no Studio replacement before review."""
import sys,json
from pathlib import Path
import bpy
HERE=Path(__file__).resolve().parent;sys.path.insert(0,str(HERE));sys.path.insert(0,str(HERE.parent/'tools'))
import kit
import assets_dealer_v4 as assets
from package_monster_prototypes import write_pack
OUT=HERE.parent/'export/collection-v2/road-v3/dealer-v4';PREVIEW=HERE.parent/'preview/road-v3'
OUT.mkdir(parents=True,exist_ok=True)
for form in ('Passive','Aggressive'):assets.dealer(form)
m,baked,total=kit.export_all(str(OUT))
(OUT/'_manifest.json').write_text(json.dumps(m,indent=2));(OUT/'_rig.json').write_text(json.dumps(assets.JOINTS,indent=2))
path,report=write_pack(OUT,m,assets.JOINTS,total,floating=set(m));path.rename(OUT/'DealerV4.glb')
(OUT/'_validation.json').write_text(json.dumps(report,indent=2))
def clear():
 for o in list(bpy.data.objects):bpy.data.objects.remove(o,do_unlink=True)
def show(form,x,angle,head=False):
 name='BuckshotDealer_'+form;parts=[p for p in m[name] if p['part']!='Body' and (not head or p['part']=='Head')]
 kit.spawn_preview(baked,name,parts,(x,0,0),rot_z=angle)
 for ob in bpy.context.scene.objects:
  if ob.type=='MESH':ob.data.materials[0].node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.91
def render(file,cam,target,width,res):
 kit.setup_render(str(PREVIEW/file),cam,target,res=res,samples=44,bg='3C414B')
 s=bpy.context.scene;s.camera.data.type='ORTHO';s.camera.data.ortho_scale=width;s.cycles.use_denoising=True;s.view_settings.view_transform='AgX'
 bpy.ops.render.render(write_still=True)
clear();show('Passive',-3.25,-6);show('Aggressive',3.25,-18)
render('BuckshotDealerV4.png',(0,-29,8.1),(0,0,3.15),16.2,(1900,1200))
bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'DealerV4.blend'))
clear();show('Passive',-2.4,0,True);show('Aggressive',2.4,-25,True)
render('BuckshotDealerV4-face.png',(0,-27,7.4),(0,0,4.15),10.1,(1900,1050))
print('DEALER_V4_COMPLETE',json.dumps(report),flush=True)
