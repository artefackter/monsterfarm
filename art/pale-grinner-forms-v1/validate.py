import bpy,json,math
from pathlib import Path
ROOT=Path(__file__).resolve().parent
spec=json.loads((ROOT/'report.json').read_text())['models'];results={}
def coords(mesh):
 bpy.context.view_layer.update();ob=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get());me=ob.to_mesh()
 data=[v.co.copy() for v in me.vertices];ob.to_mesh_clear();return data
for name,stats in spec.items():
 results[name]={}
 for ext in ('glb','fbx'):
  bpy.ops.wm.read_factory_settings(use_empty=True)
  path=str(ROOT/'models'/f'{name}.{ext}')
  if ext=='glb':bpy.ops.import_scene.gltf(filepath=path)
  else:bpy.ops.import_scene.fbx(filepath=path)
  rigs=[o for o in bpy.context.scene.objects if o.type=='ARMATURE'];assert len(rigs)==1
  rig=rigs[0];helpers={p.custom_shape for p in rig.pose.bones}
  meshes=[o for o in bpy.context.scene.objects if o.type=='MESH' and o not in helpers];assert len(meshes)==1
  mesh=meshes[0];mesh.data.calc_loop_triangles()
  assert len(mesh.data.loop_triangles)==stats['triangles']
  assert len(rig.data.bones)==stats['bones']
  assert len(mesh.data.materials)==1 and len(mesh.data.color_attributes)>0
  assert all(abs(sum(g.weight for g in v.groups)-1)<1e-5 for v in mesh.data.vertices)
  assert all(t.area>1e-12 for t in mesh.data.loop_triangles)
  checks=[]
  for bn in ('Head','HandL'):
   before=coords(mesh);bone=rig.pose.bones[bn];bone.rotation_mode='XYZ';bone.rotation_euler.x=.25
   after=coords(mesh);moved=sum((a-b).length>1e-5 for a,b in zip(before,after));assert moved>10
   bone.rotation_euler.x=0;checks.append({'bone':bn,'moved_vertices':moved})
  results[name][ext]={'passed':True,'checks':checks,'triangles':stats['triangles'],'bones':stats['bones']}
 for_scene=ROOT/'models'/f'{name}.blend'
 with bpy.data.libraries.load(str(for_scene)) as (data,out):
  assert len(data.scenes)==1,(name,data.scenes)
(ROOT/'validation.json').write_text(json.dumps({'passed':True,'results':results},indent=2))
print('VALIDATED',len(results),'models in GLB and FBX')
