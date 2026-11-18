"""Round-trip the actual deliveries and measure head and finger motion."""
import json
from pathlib import Path

import bpy
import numpy as np


ROOT=Path(__file__).resolve().parent
SOURCE=ROOT.parent/"pale-grinner-v4"
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

def sample_pose(rig):
    action,=bpy.data.actions
    anim=rig.animation_data_create()
    for track in anim.nla_tracks: track.mute=True
    anim.action=action
    start,end=action.frame_range
    transforms=[]
    for time in np.linspace(start,end,73):
        bpy.context.scene.frame_set(int(time),subframe=float(time-int(time)))
        transforms.append([np.array(rig.matrix_world@bone.matrix) for bone in sorted(rig.pose.bones,key=lambda b:b.name)])
    return np.array(transforms)


def load_export(path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    if path.suffix==".glb": bpy.ops.import_scene.gltf(filepath=str(path))
    else: bpy.ops.import_scene.fbx(filepath=str(path))
    rig,=[o for o in bpy.context.scene.objects if o.type=="ARMATURE"]
    return rig


def inspect(name,expected,ext):
    path=ROOT/"models"/(name+"."+ext)
    if expected["animations"]:
        original=sample_pose(load_export(SOURCE/"models"/path.name))
    rig=load_export(path)
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
        optimized=sample_pose(rig)
        pos_error=np.linalg.norm(optimized[:,:,:3,3]-original[:,:,:3,3],axis=-1).max()
        assert pos_error<.008 and np.max(np.abs(optimized-original))<.01,(ext,pos_error)
        measured["max_joint_position_error_over_73_samples"]=round(float(pos_error),6)
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


def hand_records(path):
    bpy.ops.wm.open_mainfile(filepath=str(path))
    mesh=bpy.data.objects[path.stem+"_Mesh"]
    color=mesh.data.color_attributes["Col"]
    values=[]
    for v in mesh.data.vertices:
        groups=tuple(sorted((mesh.vertex_groups[g.group].name,g.weight) for g in v.groups if g.weight))
        if groups and any(n.startswith("Hand") for n,w in groups):
            values.append((tuple(v.co),tuple(color.data[v.index].color_srgb),groups))
    assert values
    return sorted(values)


result={}
for model,spec in stats.items():
    filename=model+".blend"
    assert hand_records(SOURCE/"models"/filename)==hand_records(ROOT/"models"/filename)
    result[model]={ext:inspect(model,spec,ext) for ext in ("glb","fbx")}
    result[model]["hand_positions_colours_weights_exact"]=True
(ROOT/"validation.json").write_text(json.dumps(result,indent=2)+"\n")
print("Validated 16 exports")
