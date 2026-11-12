"""Transparent icon framing follows mesh bounds; no muzzle or stock touches an image edge."""
import sys,json
from pathlib import Path
import bpy
from mathutils import Vector
HERE=Path(__file__).resolve().parent;sys.path.insert(0,str(HERE))
import kit,assets_weapons_preview as weapons
OUT=HERE.parent/'export/collection-v2/road-v3/icons-v2';OUT.mkdir(parents=True,exist_ok=True)
weapons.build();manifest,baked,_=kit.export_all(str(OUT/'source'))
for name,ident in [('GunM249','M249'),('GunDouble','Double'),('GunPump','Pump'),('GunMP5','MP5')]:
 for o in list(bpy.data.objects):bpy.data.objects.remove(o,do_unlink=True)
 kit.spawn_preview(baked,name,manifest[name],(0,0,0),rot_z=78)
 points=[o.matrix_world@v.co for o in bpy.data.objects if o.type=='MESH' for v in o.data.vertices]
 lo=Vector([min(v[i] for v in points) for i in range(3)]);hi=Vector([max(v[i] for v in points) for i in range(3)])
 center=(lo+hi)*.5;eye=center+Vector((0,-12,3))
 kit.setup_render(str(OUT/(ident+'.png')),eye,center,res=(1024,512),samples=40,bg='718B9D')
 scene=bpy.context.scene;scene.camera.data.type='ORTHO';scene.camera.data.ortho_scale=max((hi.x-lo.x)*1.18,(hi.z-lo.z)*2.4)
 scene.render.film_transparent=True;scene.render.image_settings.color_mode='RGBA';scene.world.node_tree.nodes['Background'].inputs[1].default_value=1.0
 bpy.ops.render.render(write_still=True)
print('Four tightly framed weapon icons rendered',flush=True)
