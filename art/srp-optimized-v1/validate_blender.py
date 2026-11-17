"""Reimport all 24 optimized GLBs; exercise independent rigged parts."""
import bpy,json,sys,math
from pathlib import Path
ROOT=Path(__file__).resolve().parent;sys.path.insert(0,str(ROOT))
from assets import verify_sources
CASES={
 'Dredge':[('Head','Tail'),('Tail05','Arm')],
 'AssimilatedAdventurer':[('Head','Leg'),('ChestFlapL','ChestFlapR')],
 'PrimitiveSummoner':[('UpperJaw','Leg'),('LowerJaw','UpperJaw')],
 'AdaptedViscera':[('Shell','Leg'),('Tentacle01_2','Tentacle02')]}
def points(mesh):
    bpy.context.view_layer.update();ev=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get());me=ev.to_mesh()
    coords=[mesh.matrix_world@v.co for v in me.vertices];ev.to_mesh_clear();return coords
rows=[]
for r in json.loads((ROOT/'models_report.json').read_text())['models']:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(ROOT/r['output']))
    rigs=[o for o in bpy.context.scene.objects if o.type=='ARMATURE'];assert len(rigs)==1
    rig=rigs[0];helpers={p.custom_shape for p in rig.pose.bones if p.custom_shape}
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH' and o not in helpers];assert len(meshes)==1
    mesh=meshes[0];mesh.data.calc_loop_triangles()
    assert len(rig.data.bones)==r['stats']['bones'] and not bpy.data.actions
    assert len(mesh.data.loop_triangles)==r['stats']['triangles']
    assert all(t.area>1e-12 for t in mesh.data.loop_triangles)
    assert len(mesh.data.materials)==1 and mesh.data.color_attributes
    assert any(m.type=='ARMATURE' and m.object==rig for m in mesh.modifiers)
    assert all(abs(sum(g.weight for g in v.groups)-1)<1e-5 for v in mesh.data.vertices)
    checks=[]
    for bone,prefix in CASES[r['character']]:
        protected=[v.index for v in mesh.data.vertices if any(mesh.vertex_groups[g.group].name.startswith(prefix) for g in v.groups)]
        assert protected
        before=points(mesh);pb=rig.pose.bones[bone];pb.rotation_mode='XYZ';pb.rotation_euler.x=.24
        after=points(mesh);moved=sum((x-y).length>1e-5 for x,y in zip(before,after))
        error=max((before[i]-after[i]).length for i in protected)
        assert moved>10 and error<1e-5,(r['id'],bone,moved,error)
        pb.rotation_euler.x=0
        checks.append(dict(bone=bone,moved_vertices=moved,stationary_group=prefix,stationary_error=error))
    rows.append(dict(id=r['id'],passed=True,meshes=1,materials=1,bones=len(rig.data.bones),triangles=len(mesh.data.loop_triangles),animation_clips=0,deformation_checks=checks))
    print('BLENDER_PASS',r['id'],flush=True)
(ROOT/'blender_validation.json').write_text(json.dumps(dict(passed=True,models=rows,source_files_unchanged=verify_sources(),roblox_import_tested=False),indent=2)+'\n')
