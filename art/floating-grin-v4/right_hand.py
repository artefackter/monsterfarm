"""Give Floating Grin an anatomically paired right-hand pose in both forms."""
import sys
from pathlib import Path

import numpy as np
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parent
PREVIOUS = ROOT.parent / "floating-grin-v3"
sys.path.insert(0, str(PREVIOUS))
from dealer_pose import FRONT, SCALE, basis, dealer_hand, placed_hand
from build import build_pair
from verify import verify_exports

# The source skeleton names hands by their position in the frontal portrait.
RIGHT = "L"
LEFT = "R"
MIRROR_X = Matrix.Diagonal(Vector((-1, 1, 1)))


def bounds_center(points):
    xyz = np.asarray(points)
    return Vector((xyz.min(axis=0) + xyz.max(axis=0)) * .5)


def paired_hand(geometry, side, bones):
    first_vertex = len(geometry.points)
    first_face = len(geometry.faces)
    placed_hand(geometry, side, bones)
    if side != RIGHT:
        return

    center, width, along = dealer_hand(RIGHT)
    _, left_width, left_along = dealer_hand(LEFT)
    # Mirror the other palm's frame. A rotation alone would retain the two
    # identical chiralities in the previous sculpt (including finger curl).
    transform = MIRROR_X @ basis(left_width, left_along) @ basis(width, along).transposed()
    points = [transform @ p for p in geometry.points[first_vertex:]]
    shift = center - bounds_center(points)
    geometry.points[first_vertex:] = [p + shift for p in points]
    geometry.faces[first_face:] = [tuple(reversed(face)) for face in geometry.faces[first_face:]]
    for name in bones:
        if name.startswith("Hand" + RIGHT):
            head, tail, parent = bones[name]
            bones[name] = (transform @ head + shift, transform @ tail + shift, parent)


if __name__ == "__main__":
    build_pair(ROOT, hand_builder=paired_hand, front_target=FRONT, front_scale=SCALE,
               profile_target=(-.1, -.70, FRONT[2]), profile_scale=SCALE)
    verify_exports(ROOT)
