"""Check both saved poses against V3 and render the clip from the corrected side."""
from pathlib import Path
import sys

import bpy
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from right_hand import LEFT, PREVIOUS, RIGHT, ROOT
from build import camera
from review_scene import source_arrays


def check_pose(path):
    old, groups, colors = source_arrays(PREVIOUS/"models"/path.name)
    new, updated_groups, updated_colors = source_arrays(path)
    changed = np.char.startswith(groups, "Hand" + RIGHT)
    assert np.array_equal(groups, updated_groups)
    assert np.array_equal(colors, updated_colors)
    assert np.array_equal(old[~changed], new[~changed])
    a, b = old[changed], new[changed]
    old_center = (a.min(axis=0) + a.max(axis=0)) / 2
    new_center = (b.min(axis=0) + b.max(axis=0)) / 2
    np.testing.assert_allclose(old_center, new_center, atol=2e-6)
    a, b = a-a.mean(axis=0), b-b.mean(axis=0)
    u, _, vt = np.linalg.svd(a.T @ b)
    assert np.linalg.det(u @ vt) < -.99999
    np.testing.assert_allclose(a @ u @ vt, b, atol=3e-6)

    bones = next(o for o in bpy.context.scene.objects if o.type == "ARMATURE").data.bones
    def direction(side):
        bone = bones["Hand" + side]
        return np.asarray((bone.tail_local - bone.head_local).normalized())
    np.testing.assert_allclose(direction(RIGHT), direction(LEFT)*[-1,1,1], atol=2e-6)
    for side, inward in [(RIGHT, 1), (LEFT, -1)]:
        thumb = bones["Hand" + side + "Finger0"]
        pinky = bones["Hand" + side + "Finger4"]
        assert (thumb.tail_local.x - pinky.tail_local.x)*inward > .4


if __name__ == "__main__":
    for path in sorted((ROOT/"models").glob("*.blend")):
        check_pose(path)
    output = Path(sys.argv[sys.argv.index("--")+1])
    output.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.open_mainfile(filepath=str(ROOT/"models/FloatingGrinAggressive.blend"))
    scene = bpy.context.scene
    camera(scene, (-.42,-.65,4.23), (-8,-12,.7), 6.85, (420,480))
    scene.cycles.samples = 16
    for frame in range(1,38,2):
        scene.frame_set(frame)
        scene.render.filepath = str(output/f"frame-{frame:02}.png")
        bpy.ops.render.render(write_still=True)
