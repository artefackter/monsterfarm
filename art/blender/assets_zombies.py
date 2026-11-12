"""Zombie kit: one chunky bobble-headed base plus a gag-loaded outfit for each of the 11 types."""
import math
from kit import asset, arc, star_poly

WHITE = "FFFFFF"
INK = "241A3D"
MOUTH = "5A1742"
TONGUE = "FF6FA8"
TOOTH = "FFF4CF"
PANTS = "4B3E7A"
GOLD = "FFC933"
GOLD2 = "E99A12"
RED = "FF4757"
STEEL = "C9D6EA"
WOOD = "B9783F"
BRAIN = "FF9CC2"

HEAD_Z = 3.55


def head_y(x, z):
    """Front surface of the head ellipsoid, for sticking details onto the face."""
    k = 1 - (x / 1.32) ** 2 - ((z - HEAD_Z) / 1.12) ** 2
    return -0.05 - 1.16 * math.sqrt(max(0.0, k))


def base():
    A = asset("Z_Base")
    ring = A.part("Ring", tint="rarity", cast=False, ao=0, grad=0)
    ring.lathe([(1.0, 0.0), (1.05, 0.05), (1.32, 0.05), (1.38, 0.0)], WHITE, seg=28)

    legs = A.part("Legs")
    for s, shoe in ((-1, "FF5C5C"), (1, "27C7D9")):  # mismatched sneakers
        legs.tube([(s * 0.46, 0.0, 1.2, 0.34), (s * 0.5, 0.0, 0.8, 0.31), (s * 0.5, -0.02, 0.38, 0.27)], PANTS, seg=10)
        legs.sphere((s * 0.52, -0.26, 0.24), (0.42, 0.66, 0.25), shoe, sub=2)
        legs.box((s * 0.52, -0.3, 0.05), (0.76, 1.16, 0.12), "FFF4CF", bevel=0.05)
    legs.sphere((0.54, -0.9, 0.28), (0.13, 0.13, 0.12), "9BE36B", sub=2)  # big toe poking through the shoe

    body = A.part("Body", tint="outfit", attach="Body")
    body.lathe([(0.0, 0.9), (0.66, 0.96), (0.99, 1.36), (1.04, 1.74), (0.93, 2.12), (0.68, 2.44), (0.36, 2.62), (0.0, 2.66)],
               WHITE, seg=22)
    for s in (-1, 1):
        body.sphere((s * 0.86, -0.04, 2.28), (0.38, 0.38, 0.36), WHITE, sub=2)
    body.wonk(0.035, 1.6, 2)

    head = A.part("Head", tint="skin", attach="Head")
    head.sphere((0, -0.05, HEAD_Z), (1.32, 1.16, 1.12), WHITE, sub=3)
    head.sphere((0, -0.14, 3.0), (1.06, 0.98, 0.62), WHITE, sub=2)
    head.sphere((-1.3, -0.05, 3.5), (0.2, 0.15, 0.3), WHITE, sub=2)
    head.sphere((1.32, -0.05, 3.62), (0.17, 0.13, 0.22), WHITE, sub=2)
    head.sphere((0.02, -1.22, 3.34), (0.2, 0.17, 0.16), WHITE, sub=2)
    head.wonk(0.05, 1.25, 4)

    f = A.part("Face", attach="Head", ao=0.35, ao_dist=0.4)
    # one huge eye, one tiny eye: the signature derp
    f.sphere((-0.52, -0.9, 3.8), 0.56, WHITE, sub=3)
    f.sphere((-0.42, -1.36, 3.7), (0.27, 0.13, 0.27), INK, sub=2)
    f.sphere((-0.5, -1.48, 3.8), 0.075, WHITE, sub=2)
    f.sphere((0.6, -0.97, 3.62), 0.37, WHITE, sub=2)
    f.sphere((0.5, -1.29, 3.72), (0.17, 0.09, 0.17), INK, sub=2)
    f.sphere((0.46, -1.37, 3.78), 0.05, WHITE, sub=1)
    f.box((0.66, -1.17, 4.08), (0.68, 0.14, 0.15), INK, rot=(0, -20, 0), bevel=0.05)
    # crooked grin, two surviving teeth, tongue flopping out the side
    f.sphere((0.02, -1.0, 2.92), (0.66, 0.17, 0.28), MOUTH, rot=(0, 9, 0), sub=2)
    f.box((-0.24, -1.15, 3.07), (0.22, 0.09, 0.24), TOOTH, rot=(0, 6, 0), bevel=0.035)
    f.box((0.25, -1.15, 3.0), (0.2, 0.09, 0.19), TOOTH, rot=(0, -9, 0), bevel=0.035)
    f.tube([(0.26, -1.12, 2.88, 0.14), (0.33, -1.25, 2.72, 0.145), (0.37, -1.25, 2.5, 0.12)], TONGUE, seg=8)
    # forehead stitches
    for i, x in enumerate((-0.02, 0.16, 0.34, 0.52)):
        z = 4.3 + (i % 2) * 0.02
        f.box((x, head_y(x, z) - 0.02, z), (0.05, 0.05, 0.26), INK, rot=(0, 10, 0), bevel=0.02)
    f.box((0.25, head_y(0.25, 4.3) - 0.03, 4.31), (0.68, 0.05, 0.05), INK, bevel=0.02)

    armL = A.part("ArmL", tint="skin", attach="ArmL")
    armR = A.part("ArmR", tint="skin", attach="ArmR")
    for s, arm, dz in ((-1, armL, 0.12), (1, armR, -0.08)):
        arm.tube([(s * 0.92, -0.05, 2.3, 0.27), (s * 1.1, -0.72, 2.34 + dz, 0.25), (s * 1.12, -1.42, 2.44 + dz, 0.22)], WHITE, seg=10)
        arm.sphere((s * 1.13, -1.6, 2.46 + dz), (0.33, 0.3, 0.26), WHITE, sub=2)
        for i, dx in enumerate((-0.2, 0.0, 0.2)):
            arm.tube([(s * 1.13 + dx, -1.8, 2.47 + dz, 0.095), (s * 1.13 + dx * 1.2, -2.05 - 0.04 * i, 2.42 + dz, 0.08)], WHITE, seg=6, sub=2)

    hair = A.part("Hair", attach="Head")
    for dx, dy, h in ((-0.3, 0, 5.05), (0.05, -0.15, 5.25), (0.35, 0.08, 5.0)):
        hair.tube([(dx, dy, 4.55, 0.12), (dx * 1.3, dy, h - 0.2, 0.09), (dx * 1.9, dy - 0.1, h, 0.02)], "2E8B57", seg=6)

    brain = A.part("Brain", attach="Head", ao_dist=0.4)
    for x, y, z, r in ((0.62, -0.28, 4.36, 0.34), (0.95, -0.2, 4.08, 0.27), (0.52, 0.12, 4.5, 0.3), (0.86, 0.14, 4.25, 0.3)):
        brain.sphere((x, y, z), r, BRAIN, sub=2)
    for x, y, z in ((0.32, -0.48, 4.3), (0.36, -0.3, 4.46), (0.45, -0.12, 4.56)):
        brain.box((x, y, z), (0.05, 0.05, 0.2), INK, rot=(0, 20, 0), bevel=0.02)


def pajama():
    A = asset("Z_Pajama")
    h = A.part("Head", attach="Head")
    pts = [(0, 0, 4.1, 1.17), (0, 0.02, 4.5, 1.0), (0.06, 0.1, 4.95, 0.68), (0.4, 0.26, 5.3, 0.38), (0.92, 0.3, 5.22, 0.2), (1.32, 0.3, 4.72, 0.11)]
    h.tube(pts, lambda i: "6FC3FF" if (i // 3) % 2 == 0 else WHITE, seg=14)
    h.torus((0, 0, 4.08), 1.15, 0.14, WHITE, seg=26)
    h.sphere((1.34, 0.3, 4.55), 0.27, "FFE36E", sub=3)
    b = A.part("Body", attach="Body")
    for z, r in ((1.28, 0.99), (1.74, 1.05), (2.16, 0.91)):
        b.lathe([(r - 0.02, z - 0.1), (r + 0.035, z - 0.06), (r + 0.035, z + 0.06), (r - 0.02, z + 0.1)], "3D8BFF", seg=22)
    for z in (1.42, 1.88):
        b.sphere((0, -1.03, z), 0.08, "FFE36E", sub=2)
    t = A.part("HandItem", attach="ArmR")  # lost teddy, dangling by one paw
    o = (1.12, -1.7, 1.72)
    t.sphere(o, (0.34, 0.28, 0.4), "C98F55", sub=3)
    t.sphere((o[0], o[1], o[2] + 0.5), 0.3, "C98F55", sub=3)
    for s in (-1, 1):
        t.sphere((o[0] + s * 0.23, o[1], o[2] + 0.76), 0.11, "C98F55", sub=2)
        t.sphere((o[0] + s * 0.38, o[1], o[2] - 0.1), (0.13, 0.13, 0.2), "C98F55", sub=2)
        t.sphere((o[0] + s * 0.17, o[1], o[2] - 0.42), (0.14, 0.14, 0.14), "C98F55", sub=2)
    t.sphere((o[0], o[1] - 0.25, o[2] + 0.44), 0.11, "EBCF9E", sub=2)
    t.sphere((o[0] - 0.1, o[1] - 0.28, o[2] + 0.56), 0.05, INK, sub=1)
    t.box((o[0] + 0.1, o[1] - 0.28, o[2] + 0.56), (0.12, 0.03, 0.03), INK, rot=(0, 45, 0), bevel=0.01)
    t.tube([(1.13, -1.62, 2.34, 0.05), (o[0] + 0.05, o[1], o[2] + 0.72, 0.05)], "C98F55", seg=6, sub=2)


def gardener():
    A = asset("Z_Gardener")
    h = A.part("Head", attach="Head")
    h.lathe([(1.95, 4.2), (1.92, 4.27), (1.2, 4.34), (1.02, 4.5), (0.95, 4.95), (0.62, 5.12), (0.0, 5.14)], "F4CE5B", seg=26,
            rfn=lambda a, i: 1 + (0.035 * math.sin(a * 9) if i < 2 else 0), zfn=lambda a, i: 0.09 * math.sin(a * 2 + 1) if i < 3 else 0)
    h.lathe([(1.0, 4.42), (1.05, 4.48), (1.02, 4.68), (0.98, 4.74)], RED, seg=24)
    for i in range(6):  # daisy flopping off the hat
        a = i / 6 * math.tau
        h.sphere((0.86 + math.cos(a) * 0.2, -0.82, 4.66 + math.sin(a) * 0.2), (0.14, 0.05, 0.1), WHITE, rot=(0, -math.degrees(a), 0), sub=2)
    h.sphere((0.86, -0.86, 4.66), 0.1, "FFD93B", sub=2)
    h.tube([(0, 0.1, 5.1, 0.04), (0.08, 0.1, 5.45, 0.035), (0.25, 0.1, 5.6, 0.03)], "4CAF50", seg=6)  # a sprout growing out of the hat
    h.sphere((0.34, 0.1, 5.62), (0.16, 0.05, 0.09), "6FDC55", sub=2)
    h.sphere((-0.04, 0.1, 5.56), (0.14, 0.05, 0.08), "6FDC55", sub=2)
    b = A.part("Body", attach="Body")
    b.lathe([(0.0, 0.88), (0.72, 0.94), (1.02, 1.3), (1.07, 1.62), (1.03, 1.68), (0.0, 1.7)], "4A83FF", seg=22)
    b.box((0, -0.87, 2.0), (1.0, 0.2, 0.86), "4A83FF", bevel=0.08)
    b.box((0, -1.0, 1.98), (0.5, 0.05, 0.36), "2F66DD", bevel=0.02)
    for s in (-1, 1):
        b.tube([(s * 0.38, -0.85, 2.36, 0.09), (s * 0.5, -0.45, 2.62, 0.09), (s * 0.5, 0.2, 2.6, 0.09), (s * 0.56, 0.72, 2.16, 0.09)], "4A83FF", seg=6)
        b.sphere((s * 0.38, -0.97, 2.36), 0.1, "FFD93B", sub=2)
    t = A.part("HandItem", attach="ArmR")
    t.tube([(1.13, -1.6, 2.72, 0.08), (1.34, -1.74, 1.72, 0.08)], WOOD, seg=8, sub=1)
    t.sphere((1.12, -1.59, 2.78), 0.13, WOOD, sub=2)
    t.prism([(-0.34, 0.42), (0.34, 0.42), (0.3, -0.18), (0, -0.58), (-0.3, -0.18)], 0.07, "7DE8FF", c=(1.38, -1.76, 1.3), rot=(0, 12, 0), bevel=0.025)


def postman():
    A = asset("Z_Postman")
    h = A.part("Head", attach="Head")
    h.lathe([(0.0, 4.32), (1.12, 4.34), (1.16, 4.72), (1.34, 5.06), (1.22, 5.22), (0.0, 5.28)], "2F5FD8", seg=24)
    h.lathe([(1.14, 4.3), (1.18, 4.34), (1.18, 4.52), (1.14, 4.56)], "FFC933", seg=24)
    h.sphere((0, -1.2, 4.33), (0.92, 0.45, 0.09), "1B2F7A", sub=3)
    h.prism(star_poly(0.2, 0.09), 0.05, GOLD, c=(0, -1.24, 4.82))
    b = A.part("Body", attach="Body")
    b.tube([(-0.7, -0.72, 2.42, 0.08), (-0.1, -1.0, 2.1, 0.08), (0.55, -0.92, 1.66, 0.08), (0.98, -0.45, 1.42, 0.08)], "8C5A2B", seg=6)
    b.tube([(-0.7, 0.72, 2.42, 0.08), (0.2, 0.9, 1.95, 0.08), (1.0, 0.45, 1.42, 0.08)], "8C5A2B", seg=6)
    b.box((1.1, -0.12, 1.2), (0.42, 1.2, 0.95), "A66A33", bevel=0.14, rot=(0, 0, 0))
    b.box((1.16, -0.12, 1.5), (0.44, 1.26, 0.42), "8C5A2B", bevel=0.1)
    for dy, dz, rot in ((-0.24, 1.75, -8), (0.16, 1.82, 10)):
        b.box((1.1, dy, dz), (0.06, 0.48, 0.42), WHITE, rot=(rot, 0, 0), bevel=0.015)
    b.sphere((1.33, -0.12, 1.34), 0.08, GOLD, sub=2)
    t = A.part("HandItem", attach="ArmR")  # a love letter, slightly chewed
    t.box((1.14, -1.72, 2.72), (0.86, 0.05, 0.56), WHITE, rot=(0, 8, 0), bevel=0.015)
    t.prism([(-0.42, 0.28), (0, -0.05), (0.42, 0.28)], 0.02, "DDE6F5", c=(1.14, -1.76, 2.72), rot=(0, 8, 0), bevel=0)
    t.sphere((1.14, -1.78, 2.72), (0.13, 0.03, 0.12), RED, sub=2)


def skater():
    A = asset("Z_Skater")
    h = A.part("Head", attach="Head")
    h.lathe([(0.0, 4.2), (1.16, 4.22), (1.14, 4.6), (0.86, 5.0), (0.42, 5.2), (0.0, 5.24)], "FF4757", seg=22)
    h.sphere((0, 1.5, 4.35), (0.86, 0.72, 0.09), "FFD93B", rot=(-8, 0, 0), sub=3)  # bill worn backwards, obviously
    h.sphere((0, 0, 5.26), 0.1, "FFD93B", sub=2)
    b = A.part("Body", attach="Body")
    b.prism([(-0.1, 0.42), (0.28, 0.42), (0.04, 0.05), (0.3, 0.05), (-0.22, -0.46), (-0.04, -0.08), (-0.3, -0.08)], 0.06, "FFD93B", c=(0, -1.04, 1.72), bevel=0.015)
    b.sphere((-0.5, -0.26, 0.74), (0.32, 0.2, 0.27), "FFD93B", sub=2)
    b.sphere((0.5, -0.26, 0.74), (0.32, 0.2, 0.27), "FFD93B", sub=2)
    # skateboard
    b.box((0, -0.25, -0.06), (1.36, 3.6, 0.13), "FF4FA3", bevel=0.05, taper=1.0)
    b.box((0, -0.25, -0.0), (1.2, 3.1, 0.03), "2E2140", bevel=0.01)
    for y in (-1.3, 0.8):
        b.box((0, y, -0.2), (0.7, 0.2, 0.14), STEEL, bevel=0.03)
        for s in (-1, 1):
            b.cyl((s * 0.54, y, -0.3), 0.2, 0.2, 0.2, "27E0C8", rot=(0, 90, 0), seg=14, bevel=0.03)


def pirate():
    A = asset("Z_Pirate")
    h = A.part("Head", attach="Head")
    dark, trim = "2C2147", GOLD
    h.sphere((0, 0, 4.72), (1.08, 1.0, 0.62), dark, sub=3)
    N = 42
    inner, mid, outer = [], [], []
    for j in range(N):
        a = j / N * math.tau
        tri = math.cos(3 * (a + math.pi / 2))
        r = 1.72 + 0.44 * tri
        z = 4.3 + 0.62 * (1 - (tri + 1) / 2)
        inner.append((math.cos(a) * 1.0, math.sin(a) * 0.95, 4.38))
        mid.append((math.cos(a) * (r - 0.05), math.sin(a) * (r - 0.05), z))
        outer.append((math.cos(a) * r, math.sin(a) * r, z + 0.06))
    h.loft([inner, mid, outer], dark)
    tr = [(p[0], p[1], p[2], 0.05) for p in outer[::2]]
    tr.append(tr[0])
    h.tube(tr, trim, seg=6, sub=1, cap=False)
    h.sphere((0, -1.28, 4.95), (0.27, 0.1, 0.25), WHITE, sub=3)
    h.box((0, -1.3, 4.68), (0.3, 0.07, 0.12), WHITE, bevel=0.03)
    for s in (-1, 1):
        h.sphere((s * 0.1, -1.37, 4.97), 0.05, INK, sub=1)
    # eye patch, on the small eye (the big one still has things to see)
    h.sphere((0.6, -1.3, 3.65), (0.42, 0.1, 0.38), "191226", sub=3)
    h.tube([(0.1, -1.25, 3.98, 0.03), (0.55, -1.37, 3.78, 0.03), (1.0, -1.2, 3.42, 0.03), (1.3, -0.5, 3.3, 0.03)], "191226", seg=5)
    b = A.part("Body", attach="Body")
    for z, r in ((1.46, 1.04), (1.86, 1.03), (2.22, 0.87)):
        b.lathe([(r - 0.02, z - 0.08), (r + 0.035, z - 0.05), (r + 0.035, z + 0.05), (r - 0.02, z + 0.08)], "2C2147", seg=22)
    b.lathe([(0.98, 1.02), (1.08, 1.08), (1.1, 1.26), (1.0, 1.32)], RED, seg=22)
    b.sphere((1.06, -0.3, 1.14), (0.14, 0.12, 0.26), RED, sub=2)
    # skeleton parrot: still demands crackers
    p = (0.5, 0.05, 5.56)
    h.sphere(p, (0.3, 0.3, 0.38), "F8F1DD", sub=3)
    h.sphere((p[0], p[1] - 0.14, p[2] + 0.42), 0.26, "F8F1DD", sub=3)
    h.sphere((p[0] - 0.1, p[1] - 0.36, p[2] + 0.46), 0.08, INK, sub=1)
    h.sphere((p[0] + 0.1, p[1] - 0.36, p[2] + 0.46), 0.08, INK, sub=1)
    h.cyl((p[0], p[1] - 0.46, p[2] + 0.32), 0.12, 0.0, 0.36, "FF9A2E", rot=(95, 0, 0), seg=8)
    h.tube([(p[0], p[1] + 0.25, p[2] - 0.2, 0.09), (p[0], p[1] + 0.62, p[2] - 0.5, 0.03)], "F8F1DD", seg=6)
    for dz in (-0.1, 0.06, 0.2):
        h.lathe([(0.3, dz - 0.03), (0.32, dz), (0.3, dz + 0.03)], "BFB6A1", c=p, seg=12)
    t = A.part("HandItem", attach="ArmR")
    t.cyl((1.13, -1.72, 2.38), 0.34, 0.28, 0.2, GOLD2, rot=(90, 0, 0), seg=14, bevel=0.03)
    t.tube([(1.13, -1.82, 2.38, 0.075), (1.13, -2.28, 2.38, 0.075), (1.13, -2.62, 2.58, 0.07), (1.13, -2.44, 2.92, 0.055), (1.13, -2.14, 2.84, 0.02)], STEEL, seg=8)


def cowboy():
    A = asset("Z_Cowboy")
    h = A.part("Head", attach="Head")
    tan = "B9743A"
    N = 40
    rings = []
    for r, base in ((0.98, 4.42), (1.3, 4.34), (1.9, 4.34), (2.08, 4.38)):
        ring = []
        for j in range(N):
            a = j / N * math.tau
            up = (math.cos(a) ** 2) * (r / 2.08) ** 2 * 0.72
            ring.append((math.cos(a) * r, math.sin(a) * r * 0.84, base + up))
        rings.append(ring)
    h.loft(rings, tan)
    h.lathe([(1.04, 4.36), (1.0, 4.8), (0.86, 5.3), (0.42, 5.46), (0.0, 5.3)], tan, seg=22,
            zfn=lambda a, i: -0.14 * (math.cos(a) ** 2) if i >= 3 else 0, rfn=lambda a, i: 1 - 0.08 * (math.sin(a) ** 2))
    h.lathe([(1.03, 4.44), (1.07, 4.48), (1.04, 4.72), (1.0, 4.75)], "4A2A16", seg=22)
    h.box((0, -1.07, 4.58), (0.3, 0.05, 0.26), GOLD, bevel=0.03)
    # heroic moustache
    h.tube([(-0.92, -1.08, 3.32, 0.02), (-0.66, -1.22, 3.14, 0.1), (-0.25, -1.36, 3.17, 0.15), (0.0, -1.38, 3.22, 0.12),
            (0.25, -1.36, 3.17, 0.15), (0.66, -1.22, 3.14, 0.1), (0.92, -1.08, 3.32, 0.02)], "3A2412", seg=8)
    b = A.part("Body", attach="Body")
    b.lathe([(0.72, 2.28), (0.8, 2.32), (0.54, 2.6), (0.42, 2.64)], RED, seg=20)
    b.prism([(-0.48, 0.1), (0.48, 0.1), (0, -0.52)], 0.06, RED, c=(0, -0.86, 2.3), rot=(10, 0, 0), bevel=0.02)
    b.lathe([(1.0, 1.02), (1.07, 1.05), (1.08, 1.24), (1.0, 1.27)], "4A2A16", seg=22)
    b.box((0, -1.08, 1.15), (0.62, 0.12, 0.44), GOLD, bevel=0.05)
    b.sphere((0, -1.14, 1.15), (0.15, 0.04, 0.12), RED, sub=2)
    b.prism(star_poly(0.3, 0.13), 0.06, GOLD, c=(-0.48, -0.9, 1.92), rot=(14, 0, -12))
    t = A.part("HandItem", attach="ArmR")
    t.tube([(1.13, -1.6, 2.4, 0.05), (1.3, -1.7, 2.9, 0.05), (1.36, -1.72, 3.22, 0.05)], "E8C48A", seg=6)
    t.torus((1.36, -1.72, 3.42), 0.64, 0.055, "E8C48A", rot=(10, 12, 0), seg=26, rseg=6)


def knight():
    A = asset("Z_Knight")
    h = A.part("Head", attach="Head")
    h.lathe([(1.32, 4.14), (1.35, 4.32), (1.22, 4.72), (0.86, 5.08), (0.4, 5.26), (0.0, 5.3)], STEEL, seg=24)
    h.lathe([(1.34, 4.12), (1.38, 4.16), (1.38, 4.34), (1.33, 4.38)], GOLD, seg=24)
    for s in (-1, 1):
        h.box((s * 1.33, -0.25, 3.62), (0.2, 0.9, 1.05), STEEL, bevel=0.08)
    h.sphere((0, -0.98, 4.84), (0.98, 0.34, 0.33), "AAB9D2", rot=(-20, 0, 0), sub=3)
    for x in (-0.5, -0.17, 0.17, 0.5):
        h.box((x, -1.28, 4.82), (0.2, 0.05, 0.05), INK, rot=(-20, 0, 0), bevel=0.015)
    h.sphere((-0.72, -0.45, 5.0), 0.14, "AAB9D2", sub=2)  # the dent everyone politely ignores
    h.tube([(0, 0.0, 5.26, 0.15), (0, 0.3, 5.86, 0.2), (0, 0.9, 6.04, 0.2), (0, 1.5, 5.62, 0.14), (0, 1.75, 4.95, 0.03)],
           lambda i: "FF4FA3" if (i // 3) % 2 == 0 else "FF96C8", seg=10)
    h.wonk(0.03, 1.3, 7)
    b = A.part("Body", attach="Body")
    b.lathe([(0.98, 1.3), (1.09, 1.42), (1.11, 1.76), (1.0, 2.14), (0.74, 2.46)], STEEL, seg=22)
    b.lathe([(1.0, 1.24), (1.07, 1.28), (1.1, 1.42), (1.03, 1.45)], GOLD, seg=22)
    for s in (-1, 1):
        b.sphere((s * 0.96, -0.02, 2.38), (0.52, 0.52, 0.42), STEEL, sub=3)
    # breastplate emblem: a brain, proudly
    b.sphere((-0.14, -1.08, 1.82), (0.22, 0.09, 0.24), "FF9CC2", sub=2)
    b.sphere((0.14, -1.08, 1.82), (0.22, 0.09, 0.24), "FF9CC2", sub=2)
    t = A.part("HandItem", attach="ArmR")  # "the sword is in the shop" -- baguette
    t.tube([(1.1, -1.68, 2.05, 0.17), (1.32, -1.72, 2.7, 0.22), (1.72, -1.76, 3.7, 0.21), (2.02, -1.8, 4.45, 0.09)], "E9A94F", seg=10)
    for z, x in ((2.95, 1.43), (3.35, 1.59), (3.75, 1.75), (4.12, 1.89)):
        t.sphere((x, -1.93, z), (0.13, 0.05, 0.2), "FFE2A8", rot=(0, 34, 0), sub=2)
    t.box((1.25, -1.66, 2.5), (0.95, 0.2, 0.16), GOLD, rot=(0, 20, 0), bevel=0.06)


def dj():
    A = asset("Z_DJ")
    h = A.part("Head", attach="Head")
    pts = [(math.cos(math.radians(a)) * 1.55, 0.0, HEAD_Z + 0.12 + math.sin(math.radians(a)) * 1.34, 0.11) for a in range(0, 181, 15)]
    h.tube(pts, "2B2140", seg=8, sub=1)
    for s in (-1, 1):
        h.cyl((s * 1.5, 0, 3.66), 0.56, 0.56, 0.36, "FF4FA3", rot=(0, 90, 0), seg=18, bevel=0.06)
        h.cyl((s * 1.72, 0, 3.66), 0.36, 0.36, 0.1, "FFE36E", rot=(0, 90, 0), seg=14, bevel=0.03)
    # mohawk through the headband
    for i in range(7):
        y = -0.72 + i * 0.26
        z = 4.45 + math.sqrt(max(0, 0.9 - y * y)) * 0.28
        h.cyl((0, y, z + 0.32), 0.17, 0.02, 0.8, "27E0C8" if i % 2 else "FFD93B", rot=(y * -24, 0, 0), seg=8)
    # shades slipped down the nose
    for s in (-1, 1):
        h.box((s * 0.52, -1.4, 3.26 + s * 0.04), (0.74, 0.08, 0.42), "191226", bevel=0.05, rot=(0, s * 3, 0))
        h.box((s * 0.72, -1.45, 3.34 + s * 0.04), (0.14, 0.02, 0.1), "7D68C9", bevel=0.005)
    h.box((0, -1.42, 3.28), (0.42, 0.06, 0.07), GOLD, bevel=0.02)
    b = A.part("Body", attach="Body")
    for i in range(22):
        a = i / 22 * math.tau
        fall = max(0, -math.sin(a)) * 0.68
        b.sphere((math.cos(a) * 0.74, math.sin(a) * 0.76 - fall * 0.42, 2.44 - fall), 0.085, GOLD, sub=1)
    b.prism([(-0.26, 0.26), (0.26, 0.26), (0.26, 0.14), (-0.06, -0.14), (0.26, -0.14), (0.26, -0.26), (-0.26, -0.26), (-0.26, -0.14), (0.06, 0.14), (-0.26, 0.14)],
            0.08, GOLD, c=(0, -1.0, 1.42), bevel=0.012)
    t = A.part("HandItem", attach="ArmR")
    t.cyl((1.72, -1.72, 2.05), 0.8, 0.8, 0.05, "1C1630", rot=(90, 0, 0), seg=26)
    t.cyl((1.72, -1.72, 2.05), 0.3, 0.3, 0.07, "FF4FA3", rot=(90, 0, 0), seg=16)
    t.cyl((1.72, -1.72, 2.05), 0.06, 0.06, 0.09, WHITE, rot=(90, 0, 0), seg=8)


def king():
    A = asset("Z_King")
    h = A.part("Head", attach="Head")
    N = 50
    lo, hi, inner = [], [], []
    for j in range(N):
        a = j / N * math.tau
        spike = max(0.0, math.cos(a * 5))
        lo.append((math.cos(a) * 0.92, math.sin(a) * 0.86, 0.0))
        hi.append((math.cos(a) * 1.06, math.sin(a) * 1.0, 0.34 + 0.62 * spike ** 2))
        inner.append((math.cos(a) * 1.0, math.sin(a) * 0.94, 0.28 + 0.62 * spike ** 2))
    crown_pos, crown_rot = (0.28, 0, 4.55), (0, 12, 0)
    h.loft([lo, hi, inner, [(p[0] * 0.05, p[1] * 0.05, 0.2) for p in lo]], GOLD, c=crown_pos, rot=crown_rot)
    h.sphere((0.28, 0, 4.6), (0.86, 0.8, 0.28), "C2185B", sub=3)
    from mathutils import Vector
    from kit import _mat
    M = _mat(crown_pos, crown_rot)
    for i in range(5):
        a = i / 5 * math.tau
        tip = M @ Vector((math.cos(a) * 1.06, math.sin(a) * 1.0, 1.0))
        h.sphere(tuple(tip), 0.1, GOLD, sub=2)
    for x, y, z, c in ((0.24, -1.0, 4.74, RED), (-0.32, -0.87, 4.62, "27B7FF"), (0.82, -0.84, 4.62, "5BE36B")):
        h.sphere((x, y, z), 0.13, c, sub=2)
    b = A.part("Body", attach="Body")
    # ermine collar
    N = 16
    for i in range(N):
        a = i / N * math.tau
        b.sphere((math.cos(a) * 0.82, math.sin(a) * 0.76, 2.44), 0.26, WHITE, sub=2)
        if i % 2 == 0:
            b.sphere((math.cos(a) * 0.86, math.sin(a) * 0.8 - 0.06, 2.62), 0.05, INK, sub=1)
    # cape: closed slab so it renders from both sides
    pts = [(-1.0, 2.3), (1.0, 2.3), (1.46, 0.1), (0.8, 0.28), (0.25, 0.08), (-0.3, 0.3), (-0.9, 0.08), (-1.46, 0.2)]
    b.prism(pts, 0.12, "E0245E", c=(0, 1.02, 0), rot=(-6, 0, 0), bevel=0.04)
    b.prism([(-1.3, 0.2), (-1.0, 0.2), (-0.72, 2.2), (-0.92, 2.2)], 0.02, GOLD, c=(0, 0.92, 0), rot=(-6, 0, 0), bevel=0)
    b.prism([(1.0, 0.2), (1.3, 0.2), (0.92, 2.2), (0.72, 2.2)], 0.02, GOLD, c=(0, 0.92, 0), rot=(-6, 0, 0), bevel=0)
    t = A.part("HandItem", attach="ArmR")  # sceptre with the royal snack on top
    t.tube([(1.0, -1.6, 1.8, 0.07), (1.72, -1.6, 3.55, 0.07)], GOLD, seg=8, sub=1)
    t.sphere((1.0, -1.6, 1.8), 0.13, GOLD, sub=2)
    for dx, dy, dz, r in ((-0.16, 0, 3.8, 0.27), (0.16, 0, 3.8, 0.27), (-0.1, -0.12, 4.0, 0.2), (0.12, -0.12, 4.0, 0.2), (0, 0.12, 3.98, 0.22)):
        t.sphere((1.86 + dx, -1.6 + dy, dz + 0.02), r, "FF9CC2", sub=2)


def astronaut():
    A = asset("Z_Astronaut")
    g = A.part("Glass", attach="Head", transparency=0.72, ao=0, cast=False)
    g.sphere((0, -0.05, 3.62), (1.82, 1.72, 1.72), "CFEFFF", sub=3)
    h = A.part("Head", attach="Head")
    h.tube([(0.9, 0, 5.1, 0.05), (1.15, 0, 5.7, 0.04), (1.42, 0, 6.12, 0.03)], STEEL, seg=6)
    h.sphere((1.45, 0, 6.18), 0.13, RED, sub=2)
    b = A.part("Body", attach="Body")
    b.torus((0, -0.03, 2.3), 1.03, 0.16, "E8EDF8", seg=28)
    b.box((0, -1.0, 1.72), (0.86, 0.2, 0.62), "E8EDF8", bevel=0.06)
    for x, c in ((-0.25, RED), (0.0, "FFD93B"), (0.25, "27E0C8")):
        b.sphere((x, -1.1, 1.82), 0.07, c, sub=1)
    b.box((0, -1.12, 1.56), (0.58, 0.04, 0.09), "2C2147", bevel=0.01)
    b.lathe([(1.03, 1.22), (1.08, 1.26), (1.08, 1.4), (1.03, 1.44)], "FF8A1F", seg=22)
    b.box((0, 1.0, 1.82), (1.46, 0.6, 1.42), "E8EDF8", bevel=0.14)
    for s in (-1, 1):
        b.cyl((s * 0.42, 1.36, 1.86), 0.24, 0.24, 1.14, STEEL, seg=12, bevel=0.06)
    t = A.part("HandItem", attach="ArmR")
    t.tube([(1.13, -1.6, 1.9, 0.045), (1.13, -1.6, 4.1, 0.045)], STEEL, seg=6, sub=1)
    t.prism([(0, 0), (1.14, 0), (1.14, -0.72), (0.74, -0.54), (0, -0.72)], 0.03, "2BB7FF", c=(1.15, -1.6, 4.1), bevel=0.0)
    for dx, dz, r in ((0.34, -0.32, 0.17), (0.6, -0.32, 0.17), (0.47, -0.2, 0.14)):
        t.sphere((1.15 + dx, -1.63, 4.1 + dz), (r, 0.03, r), "FF9CC2", sub=2)


def dragon():
    A = asset("Z_Dragon")
    pur, pink, cream = "A349FF", "FF4FA3", "FFE9A8"
    h = A.part("Head", attach="Head")
    # kigurumi hood: he insists it is a real dragon
    h.lathe([(1.42, 4.1), (1.42, 4.4), (1.28, 4.86), (0.9, 5.24), (0.42, 5.42), (0.0, 5.46)], pur, seg=24)
    h.sphere((0, -0.98, 4.5), (1.05, 0.72, 0.46), pur, sub=3)
    for s in (-1, 1):
        h.sphere((s * 0.34, -1.6, 4.62), 0.09, "6D21C9", sub=2)
        h.sphere((s * 0.6, -0.36, 5.16), 0.22, "FFD93B", sub=3)
        h.sphere((s * 0.6, -0.54, 5.2), 0.1, INK, sub=2)
        h.tube([(s * 0.8, 0.1, 5.1, 0.2), (s * 1.12, 0.22, 5.58, 0.13), (s * 1.3, 0.5, 6.0, 0.02)], cream, seg=8)
    for i in range(6):  # felt teeth hanging over his forehead
        x = -0.75 + i * 0.3
        h.cyl((x, -1.42 + abs(x) * 0.34, 4.05), 0.02, 0.1, 0.24, WHITE, rot=(0, 0, 0), seg=6)
    for i in range(4):
        y = 0.1 + i * 0.36
        z = 5.42 - i * i * 0.13 - i * 0.05
        h.prism([(-0.26, 0), (0.26, 0), (0, 0.36)], 0.08, pink, c=(0, y, z), rot=(0, 0, 90), bevel=0.02)
    b = A.part("Body", attach="Body")
    for z, w in ((1.14, 0.66), (1.5, 0.8), (1.86, 0.74), (2.18, 0.54)):
        b.sphere((0, -0.76, z), (w, 0.36, 0.24), "FFD166", sub=2)
    b.tube([(0, 0.8, 1.2, 0.46), (0, 1.5, 0.9, 0.34), (0.1, 2.3, 0.62, 0.22), (0.3, 3.0, 0.74, 0.1)], pur, seg=12)
    b.prism([(0, 0.46), (0.42, 0), (0, -0.42), (-0.42, 0)], 0.09, pink, c=(0.36, 3.2, 0.82), rot=(80, 0, 0), bevel=0.03)
    for i in range(4):
        y = 0.92 + i * 0.5
        b.prism([(-0.2, 0), (0.2, 0), (0, 0.3)], 0.07, pink, c=(0.02 * i, y, 1.62 - i * 0.26), rot=(-14, 0, 90), bevel=0.015)
    for s, name in ((-1, "WingL"), (1, "WingR")):
        w = A.part(name, attach=name, ao=0.3)
        poly = [(0, 0), (0.0, 0.34), (0.5, 1.02), (1.3, 1.58), (2.5, 1.84), (2.14, 0.9), (2.4, 0.2), (1.62, 0.3), (1.34, -0.42), (0.68, -0.08)]
        if s < 0:
            poly = [(-x, z) for x, z in reversed(poly)]
        w.prism(poly, 0.09, pink, c=(s * 0.56, 0.86, 2.06), rot=(0, 0, s * -14), bevel=0.02)
        bones = [(0.0, 0.2), (2.5, 1.84)]
        w.tube([(s * 0.56, 0.86, 2.26, 0.09), (s * 1.8, 1.16, 3.22, 0.06), (s * 2.96, 1.46, 3.9, 0.02)], pur, seg=6)


def build():
    base(); pajama(); gardener(); postman(); skater(); pirate(); cowboy(); knight(); dj(); king(); astronaut(); dragon()
