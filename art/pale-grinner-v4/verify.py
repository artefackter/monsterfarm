"""Round-trip the actual deliveries and measure head and finger motion."""
import json
from pathlib import Path

import bpy
import numpy as np


ROOT=Path(__file__).resolve().parent
stats=json.loads((ROOT/"report.json").read_text())
assert len(stats)==8 and sum(bool(s["animations"]) for s in stats.values())==1


def vertices(mesh):
    bpy.context.view_layer.update()
    evaluated=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get())
    data=evaluated.to_mesh()
    points=np.empty(len(data.vertices)*3,np.float32)
    data.vertices.foreach_get("co",points)
    evaluated.to_mesh_clear()
    world=np.array(mesh.matrix_world)
    return points.reshape(-1,3)@world[:3,:3].T+world[:3,3]


def indices(mesh,bone):
    group=mesh.vertex_groups[bone].index
    return [v.index for v in mesh.data.vertices if any(g.group==group and g.weight>.75 for g in v.groups)]


def inspect(name,expected,ext):
    path=ROOT/"models"/(name+"."+ext)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    if ext=="glb": bpy.ops.import_scene.gltf(filepath=str(path))
    else: bpy.ops.import_scene.fbx(filepath=str(path))
    rigs=[o for o in bpy.context.scene.objects if o.type=="ARMATURE"]
    assert len(rigs)==1
    rig=rigs[0]
    mesh,=[o for o in bpy.context.scene.objects if o.type=="MESH" and o.find_armature()==rig]
    mesh.data.calc_loop_triangles()
    assert len(mesh.data.loop_triangles)==expected["triangles"]
    assert all(t.area>1e-12 for t in mesh.data.loop_triangles)
    assert len(mesh.data.materials)==1 and len(mesh.data.color_attributes)>0
    assert len(rig.data.bones)==expected["bones"]
    assert all(abs(sum(g.weight for g in v.groups)-1)<.002 for v in mesh.data.vertices)
    actions=list(bpy.data.actions)
    assert len(actions)==len(expected["animations"]),(name,ext,actions)
    measured={}
    if actions:
        anim=rig.animation_data_create()
        action=actions[0]
        for track in anim.nla_tracks: track.mute=True
        anim.action=action
        start,end=action.frame_range
        head=indices(mesh,"Head")
        chest=indices(mesh,"Chest")
        frames=[round(start),round(start+(end-start)*.44),round(end)]
        samples=[]
        for frame in frames:
            bpy.context.scene.frame_set(frame)
            samples.append(vertices(mesh))
        travel=samples[1][head].mean(axis=0)-samples[0][head].mean(axis=0)
        assert travel[1]<-1.95,(name,ext,frames,travel)
        assert np.max(np.abs(samples[2][head]-samples[0][head]))<.006
        assert np.max(np.abs(samples[1][chest]-samples[0][chest]))<.006
        a=samples[0][head];b=samples[1][head]
        assert abs(np.linalg.norm(a-a.mean(axis=0))-np.linalg.norm(b-b.mean(axis=0)))<.01
        measured["forward_head_travel"]=round(float(-travel[1]),3)
    else:
        assert not any(b.name.startswith("Cervical_") for b in rig.data.bones)
    for side in ("L","R"):
        for number in range(5):
            name="Hand"+side+"Finger"+str(number)
            bone=rig.pose.bones[name]
            ids=indices(mesh,name)
            assert len(ids)>=24,(name,ext,len(ids))
            before=vertices(mesh)
            original=bone.matrix_basis.copy()
            bone.rotation_mode="XYZ";bone.rotation_euler.x+=.30
            after=vertices(mesh)
            displacement=np.linalg.norm(after[ids]-before[ids],axis=1)
            assert np.median(displacement)>.02,(name,ext,displacement)
            bone.matrix_basis=original
    return {"passed":True,"tested_digits":10,**measured}


result={}
for model,spec in stats.items():
    result[model]={ext:inspect(model,spec,ext) for ext in ("glb","fbx")}
(ROOT/"validation.json").write_text(json.dumps(result,indent=2)+"\n")
print("Validated 16 exports")
