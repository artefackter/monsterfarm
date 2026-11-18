"""Render the actual Dealer parts next to the revised pose, plus the lunge frames."""
import json
import sys
from pathlib import Path

import bpy
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from dealer_pose import DEALER, FORM, FRONT, ROOT, SCALE, blender_axes
from build import camera, material
from sculpt import CENTER, RADII


def source_arrays(path):
    bpy.ops.wm.open_mainfile(filepath=str(path))
    mesh = next(o for o in bpy.context.scene.objects if o.type == "MESH" and o.find_armature())
    assignment = np.array([mesh.vertex_groups[v.groups[0].group].name for v in mesh.data.vertices])
    points = np.asarray([list(v.co) for v in mesh.data.vertices])
    colors = np.asarray([list(v.color_srgb) for v in mesh.data.color_attributes["Col"].data])
    return points, assignment, colors


def check_hand_shapes():
    previous = ROOT.parent / "floating-grin-v2/models"
    for path in sorted((ROOT/"models").glob("*.blend")):
        old, names, colors = source_arrays(previous/path.name)
        new, new_names, new_colors = source_arrays(path)
        assert np.array_equal(names, new_names) and np.array_equal(colors, new_colors)
        assert np.array_equal(old[names == "Head"], new[names == "Head"])
        for prefix in ("HandL", "HandR"):
            selected = np.char.startswith(names, prefix)
            a, b = old[selected], new[selected]
            a = a - a.mean(0)
            b = b - b.mean(0)
            u, _, vt = np.linalg.svd(a.T @ b)
            rotation = u @ vt
            assert np.linalg.det(rotation) > .99999
            assert np.max(np.abs(a @ rotation - b)) < 1e-5


def render_dealer(scene, output):
    for obj in scene.objects:
        if obj.type == "MESH" and obj.find_armature():
            obj.hide_render = True
    parts = json.loads((DEALER / "_manifest.json").read_text())[FORM]
    head = next(p for p in parts if p["part"] == "Head")
    scale = 2 * RADII[0] / head["size"][0]
    mat = material()
    for p in parts:
        if p["transparency"] == 1:
            continue
        data = json.loads((DEALER/(p["mesh"]+".json")).read_text())
        xyz = np.asarray(data["v"]).reshape(-1, 3) + p["offset"] - np.asarray(head["offset"])
        geom = bpy.data.meshes.new(p["part"])
        geom.from_pydata((blender_axes(xyz)*scale+np.array(CENTER)).tolist(), [],
                         np.asarray(data["t"]).reshape(-1, 3).tolist())
        geom.update()
        attr = geom.color_attributes.new(name="Col", type="BYTE_COLOR", domain="POINT")
        for dest, c in zip(attr.data, data["c"]):
            dest.color_srgb = ((c >> 16)/255, ((c >> 8) & 255)/255, (c & 255)/255, 1)
        geom.materials.append(mat)
        obj = bpy.data.objects.new(p["part"], geom)
        scene.collection.objects.link(obj)
    camera(scene, FRONT, (.10,-15,.09), SCALE, (700,800))
    scene.render.filepath = str(output)
    bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
    check_hand_shapes()
    # Frame intermediates stay outside the deliverable.
    output = Path(sys.argv[sys.argv.index("--") + 1])
    output.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.open_mainfile(filepath=str(ROOT/"models/FloatingGrin.blend"))
    render_dealer(bpy.context.scene, output/"Dealer.png")
    bpy.ops.wm.open_mainfile(filepath=str(ROOT/"models/FloatingGrinAggressive.blend"))
    scene = bpy.context.scene
    camera(scene, (-.32,-.67,4.23), (12,-8,.65), SCALE, (420,480))
    scene.cycles.samples = 16
    for frame in range(1,38,2):
        scene.frame_set(frame)
        scene.render.filepath = str(output/f"frame-{frame:02}.png")
        bpy.ops.render.render(write_still=True)
