"""Import all delivery GLBs and check rigging, protected faces and deformation."""
import json
import math
import sys
from collections import Counter
from pathlib import Path
import bpy
from mathutils import Vector
from mathutils.kdtree import KDTree
from mathutils.bvhtree import BVHTree

ROOT=Path(__file__).resolve().parent;sys.path.insert(0,str(ROOT))
from assets import models,verify_sources,sha

def load(path):
    for ob in list(bpy.context.scene.objects):bpy.data.objects.remove(ob,do_unlink=True)
    bpy.ops.import_scene.gltf(filepath=str(path))
    rigs=[o for o in bpy.context.scene.objects if o.type=='ARMATURE']
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH' and
            any(m.type=='ARMATURE' and m.object in rigs for m in o.modifiers)]
    assert len(rigs)==len(meshes)==1,[(o.name,o.type) for o in bpy.context.scene.objects]
    return rigs[0],meshes[0]

def points(ob):
    bpy.context.view_layer.update()
    evaluated=ob.evaluated_get(bpy.context.evaluated_depsgraph_get())
    return [evaluated.matrix_world@v.co for v in evaluated.data.vertices]

def geometry(ob,subset=None,snap=None):
    pos=[ob.matrix_world@v.co for v in ob.data.vertices]
    if snap:
        tree,labels=snap
        keys=[]
        for v in pos:
            _,i,d=tree.find(v)
            keys.append(labels[i] if d<.00003 else tuple(round(x,6) for x in v))
    else:keys=[tuple(round(x,6) for x in v) for v in pos]
    return Counter(tuple(sorted(keys[i] for i in p.vertices)) for p in ob.data.polygons
                   if subset is None or p.index in subset)

def snapshot(rig,ob,protected):
    tree=KDTree(len(ob.data.vertices));labels=[]
    for i,v in enumerate(ob.data.vertices):
        pos=ob.matrix_world@v.co;tree.insert(pos,i);labels.append(tuple(round(x,6) for x in pos))
    tree.balance()
    return {'bones':{b.name:(b.parent.name if b.parent else None,
                rig.matrix_world@b.matrix_local) for b in rig.data.bones},
            'geometry':geometry(ob),'protected':geometry(ob,protected),'snap':(tree,labels),
            'rays':rays(ob),'paws':paws(ob)}

def rays(ob):
    ob.data.calc_loop_triangles()
    bvh=BVHTree.FromPolygons([ob.matrix_world@v.co for v in ob.data.vertices],
        [tuple(t.vertices) for t in ob.data.loop_triangles],all_triangles=True)
    hits=[]
    for camera in ((14,-18,9.1),(0,-20,6.5)):
        origin=Vector(camera)
        for target in ((.34,-1.931,5.566),(-.34,-1.931,5.566),(0,-3.7,4.8)):
            hit=bvh.ray_cast(origin,(Vector(target)-origin).normalized(),60)[0]
            assert hit is not None;hits.append(tuple(hit))
    return hits

def paws(ob):
    result={}
    for name in ('FrontPaw.L','FrontPaw.R','HindPaw.L','HindPaw.R'):
        group=ob.vertex_groups[name].index
        result[name]=min((ob.matrix_world@v.co).z for v in ob.data.vertices
            if any(g.group==group and g.weight>.99 for g in v.groups))
    return result

verify_sources();results=[]
for asset in models():
    mobile=json.loads((ROOT/'intermediate'/(asset['id']+'_stats.json')).read_text())
    rig,ob=load(asset['source']);baseline=snapshot(rig,ob,set(mobile['protected_source_faces']))
    for profile in ('models','mobile'):
        path=ROOT/profile/(asset['id']+'.glb');rig,ob=load(path)
        assert set(rig.data.bones.keys())==set(baseline['bones']) and len(rig.data.bones)==23
        assert len(ob.data.materials)==1 and ob.data.color_attributes
        matrix_error=0
        for bone in rig.data.bones:
            parent,matrix=baseline['bones'][bone.name]
            assert (bone.parent.name if bone.parent else None)==parent
            actual=rig.matrix_world@bone.matrix_local
            matrix_error=max(matrix_error,max(abs(actual[i][j]-matrix[i][j]) for i in range(4) for j in range(4)))
        assert matrix_error<.00003,(asset['id'],profile,'bind transform',matrix_error)
        ob.data.calc_loop_triangles()
        assert all(t.area>1e-12 for t in ob.data.loop_triangles)
        for vertex in ob.data.vertices:
            assert all(math.isfinite(x) for x in vertex.co)
            assert vertex.groups and len(vertex.groups)<=4
            assert abs(sum(g.weight for g in vertex.groups)-1)<.00005
        actual=geometry(ob,snap=baseline['snap'])
        wanted=baseline['geometry' if profile=='models' else 'protected']
        # Blender removes duplicate triangles if exact record deduplication makes
        # their three indices identical. Raw full-profile draw corners have a
        # separate exact-array check. Here every unique protected surface must
        # survive import, including the original winding-independent position.
        assert not set(wanted)-set(actual),(asset['id'],profile,'missing protected surface',
                                            len(set(wanted)-set(actual)))
        paw_heights=paws(ob)
        assert max(abs(paw_heights[k]-baseline['paws'][k]) for k in paw_heights)<.025
        assert all(.04<h<.08 for h in paw_heights.values())
        face_error=max((Vector(a)-Vector(b)).length for a,b in zip(rays(ob),baseline['rays']))
        assert face_error<.003,(asset['id'],profile,'face rays',face_error)
        movement={}
        for name in ('Head','Jaw','Spine','Hips','FrontUpper.L','FrontLower.R','HindThigh.L','HindShin.R'):
            before=points(ob);bone=rig.pose.bones[name]
            bone.rotation_mode='XYZ';bone.rotation_euler.x=.12
            after=points(ob)
            moved=sum((a-b).length>.00001 for a,b in zip(before,after));assert moved>10,name
            movement[name]=moved;bone.rotation_euler.x=0
        results.append({'id':asset['id'],'profile':profile,'passed':True,'sha256':sha(path),
            'triangles':len(ob.data.loop_triangles),'bones':23,'meshes':1,'materials':1,
            'bind_matrix_max_error':matrix_error,'protected_unique_surfaces_preserved':len(wanted),
            'redundant_coincident_faces_removed_by_importer':sum((wanted-actual).values()),
            'face_ray_max_error':face_error,'paw_heights':paw_heights,
            'deformation_moved_vertices':movement})
        print('VALIDATED',asset['id'],profile,len(ob.data.loop_triangles),flush=True)
(ROOT/'blender_validation.json').write_text(json.dumps({'passed':True,'validated_outputs':len(results),
    'source_files_unchanged':verify_sources(),'Roblox_tested':False,'results':results},indent=2)+'\n')
print('VALIDATION_COMPLETE',len(results),flush=True)
