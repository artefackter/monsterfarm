"""Re-import both delivery formats and check independent skin deformation."""
import bpy
import json
import math
import hashlib
from pathlib import Path

ROOT=Path(__file__).resolve().parent
PROJECT=ROOT.parents[1]
report=json.loads((ROOT/'report.json').read_text())
results={}
cases={
    'AssimilatedAdventurer':('Head','Leg','ChestFlapL','ChestFlapR',2),
    'PrimitiveSummoner':('UpperJaw','Leg','LowerJaw','UpperJaw',4),
    'ParasiteExisting':('Head','Leg','ArmL','ArmR',2),
    'ParasiteAdapted':('Head','Leg','ArmL','ArmR',2),
    'AdaptedViscera':('Mouth','Leg','Tentacle01_2','Tentacle02',6),
}

def evaluated(mesh):
    bpy.context.view_layer.update()
    ob=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get());me=ob.to_mesh()
    coords=[ob.matrix_world@v.co for v in me.vertices]
    ob.to_mesh_clear();return coords

def deformation(mesh,rig,bone_name,protected_prefix):
    protected=[v.index for v in mesh.data.vertices if any(
        mesh.vertex_groups[g.group].name.startswith(protected_prefix) for g in v.groups)]
    assert protected,(bone_name,'missing protected geometry')
    before=evaluated(mesh)
    pb=rig.pose.bones[bone_name];pb.rotation_mode='XYZ';pb.rotation_euler.x=.24
    after=evaluated(mesh)
    moved=sum((aa-bb).length>1e-5 for aa,bb in zip(before,after))
    assert moved>10,(bone_name,'does not deform geometry')
    assert all((before[i]-after[i]).length<1e-5 for i in protected),(
        bone_name,'incorrectly moves '+protected_prefix)
    pb.rotation_euler.x=0
    return {'bone':bone_name,'moved_vertices':moved,
            'unrelated_group_unchanged':protected_prefix,'protected_vertices':len(protected)}

for name,spec in report['models'].items():
    results[name]={}
    for ext in ('glb','fbx'):
        bpy.ops.wm.read_factory_settings(use_empty=True)
        path=ROOT/'models'/(name+'.'+ext)
        if ext=='glb':bpy.ops.import_scene.gltf(filepath=str(path))
        else:bpy.ops.import_scene.fbx(filepath=str(path),use_anim=False)
        rigs=[o for o in bpy.context.scene.objects if o.type=='ARMATURE']
        helpers={p.custom_shape for r in rigs for p in r.pose.bones if p.custom_shape}
        meshes=[o for o in bpy.context.scene.objects if o.type=='MESH' and o not in helpers]
        assert len(meshes)==1 and len(rigs)==1,(name,ext,'object count')
        mesh,rig=meshes[0],rigs[0]
        assert len(rig.data.bones)==spec['bones']
        assert len(mesh.data.materials)==1
        assert any(m.type=='ARMATURE' and m.object==rig for m in mesh.modifiers)
        assert len(mesh.data.color_attributes)>0
        assert not any(n.type=='TEX_IMAGE' for m in mesh.data.materials for n in m.node_tree.nodes)
        mesh.data.calc_loop_triangles()
        assert len(mesh.data.loop_triangles)==spec['triangles']
        assert all(t.area>1e-12 for t in mesh.data.loop_triangles)
        assert all(math.isfinite(x) for v in mesh.data.vertices for x in v.co)
        assert all(abs(sum(g.weight for g in v.groups)-1)<1e-5 for v in mesh.data.vertices)
        assert all(mesh.vertex_groups[g.group].name in rig.data.bones for v in mesh.data.vertices for g in v.groups)
        assert not bpy.data.actions
        main,protected,secondary,other,leg_count=cases[name]
        assert len([b for b in rig.data.bones if b.name.startswith('Leg')])==leg_count
        checks=[deformation(mesh,rig,main,protected),deformation(mesh,rig,secondary,other)]
        results[name][ext]={'triangles':len(mesh.data.loop_triangles),'bones':len(rig.data.bones),
                           'meshes':1,'materials':1,'normalized_weights':True,'vertex_colors':True,
                           'deformation_checks':checks,'animation_clips':0,
                           'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
        print('PASS',name,ext,flush=True)

baseline=json.loads((ROOT/'game-files-baseline.json').read_text())
changed=[p for p,digest in baseline.items() if not (PROJECT/p).is_file()
         or hashlib.sha256((PROJECT/p).read_bytes()).hexdigest()!=digest]
assert not changed,changed
source=json.loads((ROOT/'source-parasite-baseline.json').read_text())
source_changed=[p for p,digest in source.items()
                if hashlib.sha256((PROJECT/p).read_bytes()).hexdigest()!=digest]
assert not source_changed,source_changed
topology={}
for adapted in (False,True):
    name='ParasiteAdapted' if adapted else 'ParasiteExisting'
    folder=PROJECT/'art/export/collection-v2/road-v3/root-archetypes-v1'
    entries=json.loads((folder/'_manifest.json').read_text())['Parasite_Root_Aggressive']
    for entry in entries:
        pn=entry['part'];original=json.loads((folder/(entry['mesh']+'.json')).read_text())
        result=json.loads((ROOT/'geometry'/(name+'.'+pn+'.json')).read_text())
        assert result['t']==original['t'],(name,pn,'source topology changed')
        assert len(result['v'])==len(original['v'])//3
        if adapted and pn not in ('Body','ArmR','ArmL'):
            before=json.loads((ROOT/'geometry'/('ParasiteExisting.'+pn+'.json')).read_text())
            assert result['v']==before['v'],(name,pn,'protected existing shape changed')
    topology[name]={'original_parts':len(entries),'original_triangle_indices_preserved':True,
                    'head_legs_hands_tendrils_retained':True}
dredge=ROOT.parent/'srp-dredge-v1'
approval=json.loads((dredge/'approval.json').read_text())
changed_approved=[p for p,details in approval['files'].items()
                  if hashlib.sha256((dredge/p).read_bytes()).hexdigest()!=details['sha256']]
assert not changed_approved,changed_approved
(ROOT/'validation.json').write_text(json.dumps({'status':'passed','exports':results,
    'protected_game_files_checked':len(baseline),'protected_game_files_changed':changed,
    'approved_dredge_files_checked':len(approval['files']),'approved_dredge_files_changed':changed_approved,
    'source_parasite_files_checked':len(source),'source_parasite_files_changed':source_changed,
    'existing_parasite_topology':topology,
    'scope':'Offline geometry and skinning verification. No Roblox Studio import or runtime test.'},indent=2)+'\n')
print('VALIDATION_PASSED',len(results)*2,'exports;',len(baseline),'game files unchanged;',
      len(approval['files']),'approved files unchanged',flush=True)
