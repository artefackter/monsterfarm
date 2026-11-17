"""Reimport compact/mobile GLBs, exercise all important bones and verify both grips."""
import sys
import json
from pathlib import Path
import bpy
import numpy as np
from mathutils.bvhtree import BVHTree
from mathutils import Vector

ROOT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT))
from compact_glb import GLB

report=json.loads((ROOT/'report.json').read_text())
results=[]
for asset in report['models']:
    for profile,path_key in [('full','output'),('mobile','mobile_file')]:
        if path_key not in asset:continue
        path=ROOT/asset[path_key]
        glb=GLB(path);stats=asset[profile]
        data={}
        for mesh in glb.doc['meshes']:
            prim=mesh['primitives'][0]
            data[mesh['name']]={'pos':glb.array(prim['attributes']['POSITION']),
                'indices':glb.array(prim['indices'],False).reshape(-1,3)}
        instrument=data['Biwa']
        bvh=BVHTree.FromPolygons([Vector(p) for p in instrument['pos']],instrument['indices'].tolist(),all_triangles=True)
        grips={}
        for label in ('L','R'):
            positions=[];palm=[]
            for name,r in stats['part_ranges'].items():
                if name=='Hand.'+label or name.startswith('Finger') and name.endswith('.'+label):
                    coords=data[r['mesh']]['pos'][r['vertex_start']:r['vertex_start']+r['vertex_count']]
                    positions.extend(coords)
                    if name=='Hand.'+label:palm=list(coords)
            distances=[bvh.find_nearest(Vector(p))[3] for p in positions]
            palm_min=min(bvh.find_nearest(Vector(p))[3] for p in palm)
            close=sum(d<.09 for d in distances)
            assert palm_min<.12 and close>=10,(asset['id'],profile,label)
            grips[label]={'palm_min_distance':round(palm_min,6),'near_surface_vertices':close}

        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.gltf(filepath=str(path))
        rigs=[o for o in bpy.context.scene.objects if o.type=='ARMATURE']
        assert len(rigs)==1;rig=rigs[0]
        meshes={o.name:o for o in bpy.context.scene.objects if o.type=='MESH' and o.name in ('MimicBody','Biwa')}
        assert len(meshes)==2 and len(rig.data.bones)==37
        for ob in meshes.values():
            assert len(ob.data.color_attributes)>0
            assert any(m.type=='ARMATURE' and m.object==rig for m in ob.modifiers)
            for vertex in ob.data.vertices:
                assert vertex.groups
                assert abs(sum(g.weight for g in vertex.groups)-1)<.0002
        moved={}
        for bone,mesh_name,angles in [
            ('Head','MimicBody',(.05,0,.08)),('Jaw','MimicBody',(.12,0,0)),
            ('Forearm.L','MimicBody',(0,.12,0)),('Finger2.L','MimicBody',(.15,0,0)),
            ('Hair.Back','MimicBody',(0,.05,0)),('Skirt.Back','MimicBody',(.03,0,0)),
            ('Biwa','Biwa',(0,0,.05))]:
            ob=meshes[mesh_name]
            bpy.context.view_layer.update();deps=bpy.context.evaluated_depsgraph_get()
            before=np.array([tuple(v.co) for v in ob.evaluated_get(deps).data.vertices])
            pose=rig.pose.bones[bone];pose.rotation_mode='XYZ';pose.rotation_euler=angles
            bpy.context.view_layer.update()
            after=np.array([tuple(v.co) for v in ob.evaluated_get(deps).data.vertices])
            count=int(np.count_nonzero(np.linalg.norm(after-before,axis=1)>.00001))
            assert count>0,(asset['id'],profile,bone)
            moved[bone]=count
            pose.rotation_euler=(0,0,0);bpy.context.view_layer.update()
        results.append({'id':asset['id'],'profile':profile,'passed':True,'meshes':2,'bones':37,
            'two_hand_contacts':grips,'deformation_moved_vertices':moved})
        print('BLENDER_VALIDATED',asset['id'],profile,flush=True)
(ROOT/'blender_validation.json').write_text(json.dumps({'passed':True,'checks':results},indent=2)+'\n')
