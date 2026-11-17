"""Round-trip every compact GLB through Blender and exercise actual skin modifiers."""
import json
import sys
from pathlib import Path
import bpy
from mathutils import Quaternion
ROOT=Path(__file__).resolve().parent;sys.path.insert(0,str(ROOT))
from compact_glb import GLB
from assets import verify_sources

def clear():
    for o in list(bpy.data.objects):bpy.data.objects.remove(o,do_unlink=True)
    for a in list(bpy.data.actions):bpy.data.actions.remove(a)
def points(ob):
    bpy.context.view_layer.update();deps=bpy.context.evaluated_depsgraph_get()
    return [v.co.copy() for v in ob.evaluated_get(deps).data.vertices]
checks=[]
for row in json.loads((ROOT/'models_report.json').read_text())['models']:
    clear();path=ROOT/row['output'];g=GLB(path)
    bpy.ops.import_scene.gltf(filepath=str(path))
    rigs=[o for o in bpy.context.scene.objects if o.type=='ARMATURE'];assert len(rigs)==1
    rig=rigs[0];shapes={p.custom_shape for p in rig.pose.bones if p.custom_shape}
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH' and o not in shapes]
    assert len(meshes)==row['stats']['output_meshes'] and len(rig.data.bones)==row['stats']['bones']
    assert len([a for a in bpy.data.actions if a.slots])==2
    triangles=0
    for ob in meshes:
        assert ob.data.color_attributes and any(m.type=='ARMATURE' and m.object==rig for m in ob.modifiers)
        ob.data.calc_loop_triangles();triangles+=len(ob.data.loop_triangles)
        assert all(t.area>1e-12 for t in ob.data.loop_triangles)
        assert all(abs(sum(g.weight for g in v.groups)-1)<1e-5 for v in ob.data.vertices)
    assert triangles==row['stats']['triangles']
    rig.animation_data_clear()
    body=next(o for o in meshes if o.name==row['character']+'Body')
    prim=next(m for m in g.doc['meshes'] if m['name']==body.name)['primitives'][0]
    indices=g.array(prim['indices'],False).reshape(-1)
    def part_indices(suffix):
        part=next(v for k,v in row['stats']['part_ranges'].items() if k.endswith('__'+suffix))
        assert part['mesh']==body.name
        return set(int(i) for i in indices[part['triangle_start']*3:(part['triangle_start']+part['triangles'])*3])
    head_ids=part_indices('Head');foot_ids=part_indices('TarsusL1' if row['character']=='SpiderMom' else 'FootL')
    before=points(body);bone=rig.pose.bones['Head'];bone.rotation_mode='QUATERNION';saved=bone.rotation_quaternion.copy()
    bone.rotation_quaternion=Quaternion((1,0,0),.18)@saved;after=points(body)
    motion=max((before[i]-after[i]).length for i in head_ids);stationary=max((before[i]-after[i]).length for i in foot_ids)
    assert motion>.02 and stationary<1e-5,(row['id'],motion,stationary)
    bone.rotation_quaternion=saved
    extra={}
    if row['character']=='SpiderMom':
        leg_ids=part_indices('TarsusL2');before=points(body);b=rig.pose.bones['CoxaL2'];b.rotation_mode='QUATERNION'
        saved=b.rotation_quaternion.copy();b.rotation_quaternion=Quaternion((0,0,1),.18)@saved;after=points(body)
        movement=max((before[i]-after[i]).length for i in leg_ids);assert movement>.02
        assert not any(n.startswith(('Arm','Hand')) for n in rig.data.bones.keys())
        extra['six_legs_preserved']=True;extra['leg_motion']=movement;b.rotation_quaternion=saved
    if row['character'] in ('Granny','Grandfather'):
        weapon=next(o for o in meshes if o.name==row['character']+'Weapon');before=points(weapon)
        b=rig.pose.bones['HandR' if row['character']=='Granny' else 'HandItem'];b.rotation_mode='QUATERNION'
        saved=b.rotation_quaternion.copy();b.rotation_quaternion=Quaternion((1,0,0),.18)@saved;after=points(weapon)
        movement=max((a-b).length for a,b in zip(before,after));assert movement>.02
        extra['weapon_bone_motion']=movement;b.rotation_quaternion=saved
    checks.append({'id':row['id'],'passed':True,'meshes':len(meshes),'triangles':triangles,'bones':len(rig.data.bones),
        'actions':2,'head_motion':motion,'stationary_foot_error':stationary,**extra})
    print('BLENDER_VERIFIED',row['id'],flush=True)
(ROOT/'blender_validation.json').write_text(json.dumps({'passed':True,'models':checks,'source_files_unchanged':verify_sources(),
    'roblox_import_tested':False},indent=2)+'\n')
print('ALL_BLENDER_VERIFIED',len(checks),flush=True)
