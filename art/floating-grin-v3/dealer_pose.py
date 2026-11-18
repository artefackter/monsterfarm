"""Match the in-game Dealer V4 hand placement using rigid transforms."""
import json
import sys
from functools import lru_cache
from pathlib import Path

import numpy as np
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT.parent / "floating-grin-v2"))
from build import build_pair
from sculpt import CENTER, RADII, hand
from verify import verify_exports

DEALER = ROOT.parent / "export/collection-v2/road-v3/dealer-v4"
FORM = "BuckshotDealer_Passive"
FRONT = (-.51, -.25, 4.23)
SCALE = 6.85


def blender_axes(rbx):
    return np.asarray(rbx)[..., [0, 2, 1]] * [-1, 1, 1]


@lru_cache(maxsize=2)
def dealer_hand(side):
    parts = {p["part"]: p for p in json.loads((DEALER / "_manifest.json").read_text())[FORM]}
    # Dealer's exporter reverses X. V2 labels hands by their side in the frontal render.
    part = parts["ArmR" if side == "L" else "ArmL"]
    head = parts["Head"]
    offset = np.asarray(part["offset"])
    center = CENTER + Vector(blender_axes(offset - head["offset"])) * (2 * RADII[0] / head["size"][0])
    geometry = json.loads((DEALER / (part["mesh"] + ".json")).read_text())
    points = np.unique(np.asarray(geometry["v"]).reshape(-1, 3), axis=0)
    points = blender_axes(points + offset)
    pivot = json.loads((DEALER / "_rig.json").read_text())[FORM][part["part"]]
    relative = points - blender_axes(pivot)
    distances = np.linalg.norm(relative, axis=1)
    distal = relative[distances >= np.percentile(distances, 85)].mean(axis=0)
    along = distal / np.linalg.norm(distal)
    # Width is the widest spread of the hand projected across its pointing direction.
    projected = relative - np.outer(relative @ along, along)
    _, _, axes = np.linalg.svd(projected - projected.mean(axis=0), full_matrices=False)
    width = axes[0] if axes[0, 0] * center.x > 0 else -axes[0]
    return center, Vector(width), Vector(along)


def basis(width, along):
    return Matrix((width, along.cross(width), along)).transposed()


def placed_hand(geometry, side, bones):
    start = len(geometry.points)
    _, old_width, _, old_along = hand(geometry, side, bones)
    target, width, along = dealer_hand(side)
    rotation = basis(width, along) @ basis(old_width, old_along).transposed()
    rotated = [rotation @ p for p in geometry.points[start:]]
    bounds = np.asarray(rotated)
    shift = target - Vector((bounds.min(axis=0) + bounds.max(axis=0)) / 2)
    assert abs(rotation.determinant() - 1) < 1e-5
    geometry.points[start:] = [p + shift for p in rotated]
    for name in list(bones):
        if name.startswith("Hand" + side):
            head, tail, parent = bones[name]
            bones[name] = (rotation @ head + shift, rotation @ tail + shift, parent)


if __name__ == "__main__":
    build_pair(ROOT, hand_builder=placed_hand, front_target=FRONT, front_scale=SCALE,
               profile_target=(-.1, -.70, FRONT[2]), profile_scale=SCALE)
    verify_exports(ROOT)
