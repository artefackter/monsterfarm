import bpy,json,math
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(R/'models/ReviewPack.blend'))
def linear(x):return x/12.92 if x<=.04045 else ((x+.055)/1.055)**2.4
for m in bpy.data.materials:
 if len(m.name)==6 and all(c in '0123456789ABCDEF' for c in m.name):
  rgba=tuple(linear(int(m.name[i:i+2],16)/255) for i in (0,2,4))+(1,);m.diffuse_color=rgba;m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=rgba
  if m.name in ('E8A820','FFE37A'):m.node_tree.nodes['Principled BSDF'].inputs['Metallic'].default_value=.55
for o in list(bpy.data.objects):
 if o.type in ('LIGHT','CAMERA'):bpy.data.objects.remove(o,do_unlink=True)
scene=bpy.context.scene;scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.12,.10,.16,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.5
for p,e in [((4,-8,12),1800),((-8,-4,7),1300),((4,6,9),2000)]:
 bpy.ops.object.light_add(type='AREA',location=p);o=bpy.context.object;o.data.energy=e;o.data.size=8;o.rotation_euler=(-o.location).to_track_quat('-Z','Y').to_euler()
scene.render.resolution_x=1000;scene.render.resolution_y=900;scene.cycles.samples=20;scene.view_settings.view_transform='Standard'
cat=json.loads((R/'models/catalog.json').read_text())
for idx,row in enumerate(cat):
 for r in cat:bpy.data.collections[r['name']].hide_render=r!=row
 co=bpy.data.collections[row['name']];delta=Vector(((idx%5)*8,(idx//5)*9,0))
 for o in co.objects:o.location-=delta
 pts=[o.matrix_world@Vector(v) for o in co.objects for v in o.bound_box];lo=Vector(tuple(min(v[i] for v in pts) for i in range(3)));hi=Vector(tuple(max(v[i] for v in pts) for i in range(3)));center=(lo+hi)/2;extent=max(hi-lo)
 bpy.ops.object.camera_add(location=center+Vector((extent*.8,-extent*1.7,extent*.65)));cam=bpy.context.object;cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=extent*1.65;scene.camera=cam
 scene.render.filepath=str(R/'previews'/(row['name']+'.png'));bpy.ops.render.render(write_still=True);bpy.data.objects.remove(cam,do_unlink=True)
 bpy.ops.object.select_all(action='DESELECT')
 for o in co.objects:o.select_set(True)
 bpy.ops.export_scene.gltf(filepath=str(R/'models'/(row['name']+'.glb')),use_selection=True,export_format='GLB')
 for o in co.objects:o.location+=delta
for row in cat:bpy.data.collections[row['name']].hide_render=False
bpy.ops.wm.save_as_mainfile(filepath=str(R/'models/ReviewPack.blend'))
print('ALL_INDIVIDUAL_RENDERS_COMPLETE')
