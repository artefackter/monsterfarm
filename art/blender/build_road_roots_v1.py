"""Uncostumed road archetypes; collection outfits and existing imported pairs stay untouched."""
import sys,copy,json,math
from pathlib import Path
import bpy,bmesh
HERE=Path(__file__).resolve().parent;sys.path.insert(0,str(HERE));sys.path.insert(0,str(HERE.parent/'tools'))
import kit
import assets_monster_prototypes as base
import assets_monster_prototypes_v3 as face
import assets_monster_forms as posing
import assets_monster_forms_v2 as anatomy
import assets_collection_v2 as collection
from assets_deer import beam
from package_monster_prototypes import write_pack
JOINTS={}
a=kit.asset('Deer_Root_Aggressive')
base.deer_body(a,'Root');base.deer_limbs(a,'Root',hand_builder=anatomy.corrected_deer_hand)
face.deer_face(a,'Root',expression='AggressiveV2')
JOINTS[a.name]=copy.deepcopy(base.JOINTS[a.name]);posing.JOINTS[a.name]=JOINTS[a.name]
posing.pose_group(a,'Head',(9,0,0))
for side,group in ((-1,'ArmR'),(1,'ArmL')):posing.pose_group(a,group,(-15,-side*10,0))
for family in ('Parasite','Stalker','Verity'):
 a=collection.character(family,'Root',expression='Aggressive')
 old=a.name;del kit.ASSETS[old];a.name=family+'_Root_Aggressive';kit.ASSETS[a.name]=a
 JOINTS[a.name]=copy.deepcopy(collection.JOINTS[old]);posing.JOINTS[a.name]=JOINTS[a.name]
 for p in a.parts:
  if p.name.startswith('Tendril'):p.attach=p.name
 if family=='Verity':
  # A visible skeleton rather than an outfit-shaped solid chest.
  body=next(p for p in a.parts if p.name=='Body')
  bmesh.ops.delete(body.bm,geom=list(body.bm.verts),context='VERTS')
  beam(body,(0,.03,3.07),(0,-.03,5.34),.17,.20,'DCC8A2')
  body.sphere((0,.07,3.21),(.50,.25,.29),'D8C29A',sub=2,smooth=False)
  beam(body,(-.73,-.02,4.72),(.73,-.02,4.72),.16,.19,'E7D3AE')
  for i in range(5):
   z=3.65+i*.20;width=.45+.10*math.sin(i*math.pi/5)
   for side in (-1,1):
    body.tube([(0,.12,z,.063),(side*width,.04,z+.03,.065),
               (side*(width+.06),-.20,z+.10,.059),(side*.13,-.31,z+.09,.050)],
              'E2CCA5',seg=5,sub=2,smooth=False)
  glow=next(p for p in a.parts if p.name=='EyesGlow')
  for f in glow.bm.faces:f[glow.layer]=glow._cid('FF4B3A')
 posing.pose_group(a,'Head',(8,0,0))
 for side,group in ((-1,'ArmR'),(1,'ArmL')):posing.pose_group(a,group,(-12,-side*8,0))
 if family=='Parasite':
  for side,group in ((-1,'TendrilR'),(1,'TendrilL')):posing.pose_group(a,group,(18,0,-side*12))
for a in kit.ASSETS.values():assert not any(p.name in ('Outfit','Headwear','HandItem','HarvestItem') for p in a.parts)
OUT=HERE.parent/'export/collection-v2/road-v3/root-archetypes-v1';OUT.mkdir(parents=True,exist_ok=True)
PREVIEW=HERE.parent/'preview/road-v3';PREVIEW.mkdir(exist_ok=True)
manifest,baked,total=kit.export_all(str(OUT))
(OUT/'_manifest.json').write_text(json.dumps(manifest,indent=2));(OUT/'_rig.json').write_text(json.dumps(JOINTS,indent=2))
path,report=write_pack(OUT,manifest,JOINTS,total);path.rename(OUT/'RoadRootArchetypes.glb')
(OUT/'_validation.json').write_text(json.dumps(report,indent=2))
for o in list(bpy.data.objects):bpy.data.objects.remove(o,do_unlink=True)
for i,name in enumerate(manifest):kit.spawn_preview(baked,name,manifest[name],((i-1.5)*5,0,0),rot_z=-12)
kit.setup_render(str(PREVIEW/'RoadRootArchetypesV1.png'),(0,-30,12),(0,0,4.0),res=(2000,1100),samples=36,bg='586B6B')
s=bpy.context.scene;s.camera.data.type='ORTHO';s.camera.data.ortho_scale=23;s.cycles.use_denoising=True
s.view_settings.view_transform='AgX';bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'RoadRootArchetypes.blend'))
bpy.ops.render.render(write_still=True)
print('ROAD_ROOTS_COMPLETE',json.dumps(report),flush=True)
