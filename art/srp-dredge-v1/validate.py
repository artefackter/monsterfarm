"""Round-trip actual GLB/FBX exports, skin deformation and protected file check."""
import bpy
import json
import math
import hashlib
from pathlib import Path
from mathutils import Vector

ROOT=Path(__file__).resolve().parent
PROJECT=ROOT.parents[1]
report=json.loads((ROOT/'report.json').read_text())
results={}


def evaluated(mesh):
    bpy.context.view_layer.update()
    deps=bpy.context.evaluated_depsgraph_get()
    ob=mesh.evaluated_get(deps);me=ob.to_mesh()
    coords=[ob.matrix_world@v.co for v in me.vertices]
    ob.to_mesh_clear()
    return coords


for name,spec in report['models'].items():
    results[name]={}
    for ext in ('glb','fbx'):
        bpy.ops.wm.read_factory_settings(use_empty=True)
        path=ROOT/'models'/(name+'.'+ext)
        if ext=='glb':bpy.ops.import_scene.gltf(filepath=str(path))
        else:bpy.ops.import_scene.fbx(filepath=str(path),use_anim=False)
        rigs=[o for o in bpy.context.scene.objects if o.type=='ARMATURE']
        shapes={p.custom_shape for r in rigs for p in r.pose.bones if p.custom_shape}
        meshes=[o for o in bpy.context.scene.objects if o.type=='MESH' and o not in shapes]
        assert len(meshes)==1 and len(rigs)==1,(name,ext,'object count')
        mesh,rig=meshes[0],rigs[0]
        assert len(rig.data.bones)==spec['bones'],(name,ext,'bone count')
        assert len(mesh.data.materials)==1,(name,ext,'materials')
        assert any(m.type=='ARMATURE' and m.object==rig for m in mesh.modifiers)
        assert len(mesh.data.color_attributes)>0,(name,ext,'vertex colours')
        assert not any(n.type=='TEX_IMAGE' for m in mesh.data.materials for n in m.node_tree.nodes)
        mesh.data.calc_loop_triangles()
        assert len(mesh.data.loop_triangles)==spec['triangles'],(name,ext,'triangle count')
        assert all(t.area>1e-12 for t in mesh.data.loop_triangles),(name,ext,'degenerate geometry')
        assert all(math.isfinite(x) for v in mesh.data.vertices for x in v.co)
        assert all(abs(sum(g.weight for g in v.groups)-1)<1e-5 for v in mesh.data.vertices)
        assert all(mesh.vertex_groups[g.group].name in rig.data.bones for v in mesh.data.vertices for g in v.groups)
        assert not bpy.data.actions,(name,ext,'unexpected animations')
        before=evaluated(mesh)
        assert not any(b.name.startswith('Leg') for b in rig.data.bones), 'Dredge has no walking legs'
        assert len([b for b in rig.data.bones if b.name.startswith('Tail')])==14
        support=[v.index for v in mesh.data.vertices if any(mesh.vertex_groups[g.group].name.startswith('Tail') for g in v.groups)]
        assert support
        head=rig.pose.bones['Head'];head.rotation_mode='XYZ';head.rotation_euler.y=.24
        after=evaluated(mesh)
        moved=sum((a-b).length>1e-5 for a,b in zip(before,after))
        assert moved>20,(name,ext,'head skin did not move')
        assert all((before[i]-after[i]).length<1e-5 for i in support),(name,ext,'head moves support legs')
        head.rotation_euler.y=0
        before=evaluated(mesh)
        limb=rig.pose.bones['Tail08']
        limb.rotation_mode='XYZ';limb.rotation_euler.x=.22
        after=evaluated(mesh)
        limb_moved=sum((a-b).length>1e-5 for a,b in zip(before,after))
        assert limb_moved>10,(name,ext,'limb skin did not move')
        results[name][ext]={'triangles':len(mesh.data.loop_triangles),'bones':len(rig.data.bones),
                             'meshes':1,'materials':1,'normalized_weights':True,'vertex_colors':True,
                             'head_moved_vertices':moved,'tail_moved_vertices':limb_moved,
                             'head_did_not_move_tail':True,'no_leg_bones':True,'tail_bones':14,'animation_clips':0,
                             'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
        print('PASS',name,ext,moved,limb_moved,flush=True)

baseline=json.loads((ROOT/'game-files-baseline.json').read_text())
changed=[p for p,digest in baseline.items()
         if not (PROJECT/p).is_file() or hashlib.sha256((PROJECT/p).read_bytes()).hexdigest()!=digest]
assert not changed,changed
(ROOT/'validation.json').write_text(json.dumps({'status':'passed','exports':results,
    'protected_game_files_checked':len(baseline),'protected_game_files_changed':changed,
    'scope':'Offline import and skinning only; not tested in Roblox Studio'},indent=2)+'\n')
print('VALIDATION_PASSED',len(results)*2,'exports;',len(baseline),'game files unchanged',flush=True)
