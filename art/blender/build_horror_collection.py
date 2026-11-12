"""Export six state models and render real geometry; also render four transparent 2D weapon icons."""
import sys,json,math
from pathlib import Path
import bpy
from mathutils import Vector
HERE=Path(__file__).resolve().parent;sys.path.insert(0,str(HERE));sys.path.insert(0,str(HERE.parent/'tools'))
import kit
import assets_horror_collection_v1 as assets
from package_monster_prototypes import write_pack
OUT=HERE.parent/'export/collection-v2/road-v3';PREVIEW=HERE.parent/'preview/road-v3'
OUT.mkdir(parents=True,exist_ok=True);PREVIEW.mkdir(parents=True,exist_ok=True)
assets.build();manifest,baked,total=kit.export_all(str(OUT))
(OUT/'_manifest.json').write_text(json.dumps(manifest,indent=2));(OUT/'_rig.json').write_text(json.dumps(assets.JOINTS,indent=2));(OUT/'_forms.json').write_text(json.dumps(assets.FORMS,indent=2))
path,report=write_pack(OUT,manifest,assets.JOINTS,total);path.rename(OUT/'HorrorCollection.glb')
(OUT/'_validation.json').write_text(json.dumps(report,indent=2))
def clear():
    for o in list(bpy.data.objects):bpy.data.objects.remove(o,do_unlink=True)
def spawn(name,x,z=0,angle=-15):kit.spawn_preview(baked,name,manifest[name],(x,0,z),rot_z=angle)
def render(path,target,width,res=(1800,1100),transparent=False):
    kit.setup_render(str(path),(0,-28,9.2),target,res=res,samples=28,bg='637B8E')
    scene=bpy.context.scene;scene.camera.data.type='ORTHO';scene.camera.data.ortho_scale=width
    scene.render.film_transparent=transparent;scene.render.image_settings.color_mode='RGBA'
    scene.view_settings.view_transform='AgX'
    scene.world.node_tree.nodes['Background'].inputs[1].default_value=.8
    bpy.ops.render.render(write_still=True)
for family in assets.FORMS:
    clear();spawn(family+'_Passive',-2.8);spawn(family+'_Aggressive',2.8,angle=-25)
    render(PREVIEW/(family+'.png'),(0,0,3.9 if family=='SirenHead' else 3.0),14 if family=='SirenHead' else 11)
clear()
for i,name in enumerate(manifest):spawn(name,(i%3-1)*5.5,z=(i//3)*9)
bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'HorrorCollection.blend'))

# Icons are raster renders of the exact game meshes, so their silhouettes and details stay consistent.
import assets_weapons_preview as weapons
kit.ASSETS.clear();weapons.build();wm,wb,_=kit.export_all(str(OUT/'icon-source'))
icon_dir=OUT/'icons';icon_dir.mkdir(exist_ok=True)
for name,ident in [('GunM249','M249'),('GunDouble','Double'),('GunPump','Pump'),('GunMP5','MP5')]:
    clear();kit.spawn_preview(wb,name,wm[name],(0,0,0),rot_z=78)
    kit.setup_render(str(icon_dir/(ident+'.png')),(0,-12,3.0),(0,0,-.08),res=(1024,1024),samples=40,bg='718B9D')
    scene=bpy.context.scene;scene.camera.data.type='ORTHO';scene.camera.data.ortho_scale=4.5
    scene.render.film_transparent=True;scene.render.image_settings.color_mode='RGBA'
    scene.world.node_tree.nodes['Background'].inputs[1].default_value=.85
    bpy.ops.render.render(write_still=True)
print('COMPLETE',len(manifest),'models and 4 transparent weapon icons',flush=True)
