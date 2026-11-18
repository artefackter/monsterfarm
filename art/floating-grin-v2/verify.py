"""Check bind pose, skinning and lunge travel after fresh FBX and GLB imports."""
import json
from pathlib import Path

import bpy
import numpy as np


ROOT = Path(__file__).resolve().parent


def vertices(mesh):
    bpy.context.view_layer.update()
    evaluated = mesh.evaluated_get(bpy.context.evaluated_depsgraph_get())
    points = np.empty((len(evaluated.data.vertices), 3), dtype=np.float32)
    evaluated.data.vertices.foreach_get("co", points.reshape(-1))
    world = np.array(evaluated.matrix_world)
    return points @ world[:3, :3].T + world[:3, 3]


def inspect(path, spec):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.fps = 30
    if path.suffix == ".glb":
        bpy.ops.import_scene.gltf(filepath=str(path))
    else:
        bpy.ops.import_scene.fbx(filepath=str(path))
    rig, = [o for o in scene.objects if o.type == "ARMATURE"]
    mesh, = [o for o in scene.objects if o.type == "MESH" and o.find_armature() == rig]
    mesh.data.calc_loop_triangles()
    assert len(mesh.data.loop_triangles) == spec["triangles"]
    assert all(tri.area > 1e-12 for tri in mesh.data.loop_triangles)
    assert len(mesh.data.materials) == 1 and len(mesh.data.color_attributes) == 1
    assert len(rig.data.bones) == 14
    members = {group.name: [] for group in mesh.vertex_groups}
    for vertex in mesh.data.vertices:
        influence, = [entry for entry in vertex.groups if entry.weight > 0]
        assert abs(influence.weight - 1) < .001
        members[mesh.vertex_groups[influence.group].name].append(vertex.index)
    expected_groups = ["Head", "HandL", "HandR"]
    fingers = [f"Hand{side}Finger{i}" for side in "LR" for i in range(5)]
    assert all(len(members[name]) >= 24 for name in expected_groups + fingers)
    assert len(bpy.data.actions) == len(spec["animations"])
    result = {"triangles": len(mesh.data.loop_triangles), "tested_digits": len(fingers)}
    if spec["animations"]:
        action, = bpy.data.actions
        assert "OrbLunge" in action.name
        anim = rig.animation_data_create()
        for track in anim.nla_tracks:
            track.mute = True
        anim.action = action
        start, end = action.frame_range
        samples = []
        for frame in (start, start + (end - start) * .39, end):
            scene.frame_set(int(frame), subframe=frame % 1)
            samples.append(vertices(mesh))
        assert np.max(np.abs(samples[2] - samples[0])) < .006
        travel = {}
        for name, distance in (("Head", 2), ("HandL", .74), ("HandR", .62)):
            delta = (samples[1] - samples[0])[members[name]].mean(axis=0)
            assert abs(-delta[1] - distance) < .09, (path.name, name, delta)
            travel[name] = round(float(-delta[1]), 3)
        result["forward_travel"] = travel
        result["duration_seconds"] = round(float((end-start)/scene.render.fps), 3)
        assert abs(result["duration_seconds"] - 1.2) < .04
        anim.action = None
    for name in fingers:
        bone = rig.pose.bones[name]
        original = bone.matrix_basis.copy()
        before = vertices(mesh)
        bone.rotation_mode = "XYZ"
        bone.rotation_euler.x += .30
        after = vertices(mesh)
        offsets = np.linalg.norm(after[members[name]] - before[members[name]], axis=1)
        assert np.median(offsets) > .025, (path.name, name)
        bone.matrix_basis = original
    return result


def verify_exports(folder):
    specs = json.loads((folder/"report.json").read_text())
    records = {path.name: inspect(path, specs[path.stem]) for path in sorted((folder/"models").iterdir())
               if path.suffix in (".glb", ".fbx")}
    assert len(records) == 4
    (folder/"validation.json").write_text(json.dumps(records, indent=2) + "\n")


if __name__ == "__main__":
    verify_exports(ROOT)
