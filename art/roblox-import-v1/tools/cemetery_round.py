# Round cemetery ground for the farm (owner, 2026-11-15: the round cemetery "lost the purple ground"): the old
# W_Graveyard patch's look on a circle - purple checker tiles, lavender rim stones, a few bones and grass tufts.
# The colours are W_Graveyard's own vertex colours (read from its mesh in Studio); the game tints the part
# (173,145,204) exactly as it tinted the old patch. One static mesh object "Main"; COLOR_0 holds the sRGB numbers raw
# (Roblox shows COLOR_0 as it is). No stones across the entrance, which faces Blender +X (the farm, once imported).
# Usage: blender --background --factory-startup --python cemetery_round.py -- <out.glb> <out.json>
import bpy, bmesh, math, random, sys, json

out_glb, out_json = sys.argv[sys.argv.index('--') + 1:][:2]
rng = random.Random(1115)

R_GROUND = 23.0      # the purple ground's radius (the fence stands at 24)
TILE = 2.2           # checker tile size
TOP = 0.12           # tile top above the lawn
R_STONES = 22.35     # rim stones' centre line
STONE_STEP = 1.55
GATE_HALF = math.radians(13)  # no stones within this angle of the entrance


def c255(r, g, b):
    return (r / 255, g / 255, b / 255, 1.0)


LIGHT = [(c255(124, 106, 158), 85), (c255(122, 104, 156), 15)]
DARK = [(c255(108, 90, 142), 65), (c255(97, 79, 136), 10), (c255(99, 80, 137), 8), (c255(114, 95, 149), 7),
        (c255(118, 100, 153), 5), (c255(86, 68, 123), 5)]
SKIRT = c255(66, 50, 99)
STONE_TOP = [c255(194, 204, 226), c255(192, 201, 224), c255(186, 194, 220), c255(187, 195, 220), c255(191, 201, 224)]
STONE_SIDE = [c255(165, 176, 204), c255(167, 179, 206), c255(163, 174, 203), c255(160, 170, 200), c255(172, 176, 209),
              c255(179, 185, 214)]
BONE_TOP, BONE_SIDE = c255(240, 228, 213), c255(205, 188, 193)
GRASS = [c255(128, 204, 85), c255(116, 181, 80), c255(121, 192, 82)]


def pick(weighted):
    total = sum(w for _, w in weighted)
    x = rng.uniform(0, total)
    for c, w in weighted:
        x -= w
        if x <= 0:
            return c
    return weighted[-1][0]


bpy.ops.wm.read_factory_settings(use_empty=True)
bm = bmesh.new()
col = bm.loops.layers.float_color.new('Col')


def face(points, color):
    vs = [bm.verts.new(p) for p in points]
    f = bm.faces.new(vs)
    for loop in f.loops:
        loop[col] = color
    return f


def angle_ok(a, half):
    a = math.atan2(math.sin(a), math.cos(a))
    return abs(a) >= half


# --- the tiles, clipped to the circle (Sutherland-Hodgman against a fine convex polygon)
CIRCLE = [(R_GROUND * math.cos(2 * math.pi * k / 128), R_GROUND * math.sin(2 * math.pi * k / 128)) for k in range(128)]


def clip(poly):
    for k in range(len(CIRCLE)):
        ax, ay = CIRCLE[k]
        bx, by = CIRCLE[(k + 1) % len(CIRCLE)]

        def inside(p):
            return (bx - ax) * (p[1] - ay) - (by - ay) * (p[0] - ax) >= 0

        def cut(p, q):
            dpx, dpy = q[0] - p[0], q[1] - p[1]
            ex, ey = bx - ax, by - ay
            t = (ex * (ay - p[1]) - ey * (ax - p[0])) / (ex * dpy - ey * dpx)
            return (p[0] + dpx * t, p[1] + dpy * t)

        out = []
        for i, p in enumerate(poly):
            q = poly[(i + 1) % len(poly)]
            if inside(p):
                out.append(p)
                if not inside(q):
                    out.append(cut(p, q))
            elif inside(q):
                out.append(cut(p, q))
        poly = out
        if len(poly) < 3:
            return None
    return poly


n = math.ceil(R_GROUND / TILE) + 1
tiles = 0
for i in range(-n, n):
    for j in range(-n, n):
        x0, y0 = i * TILE, j * TILE
        poly = clip([(x0, y0), (x0 + TILE, y0), (x0 + TILE, y0 + TILE), (x0, y0 + TILE)])
        if not poly:
            continue
        # drop slivers the clip leaves on the edge
        area = 0.5 * abs(sum(poly[k][0] * poly[(k + 1) % len(poly)][1] - poly[(k + 1) % len(poly)][0] * poly[k][1] for k in range(len(poly))))
        if area < 0.02:
            continue
        face([(p[0], p[1], TOP) for p in poly], pick(LIGHT) if (i + j) % 2 == 0 else pick(DARK))
        tiles += 1

# --- a skirt round the edge down into the lawn
SEG = 96
ring = [(R_GROUND * math.cos(2 * math.pi * k / SEG), R_GROUND * math.sin(2 * math.pi * k / SEG)) for k in range(SEG)]
for k in range(SEG):
    (ax, ay), (bx, by) = ring[k], ring[(k + 1) % SEG]
    face([(ax, ay, -0.15), (bx, by, -0.15), (bx, by, TOP), (ax, ay, TOP)], SKIRT)


# --- rim stones: bevelled, irregular, flat pebbles all round but the entrance
def stone(cx, cy, along, size, height):
    k = 7
    tx, ty = -math.sin(along), math.cos(along)  # tangent
    rx, ry = math.cos(along), math.sin(along)   # radial
    base, top = [], []
    for s in range(k):
        a = 2 * math.pi * s / k + rng.uniform(-0.2, 0.2)
        r = size * rng.uniform(0.86, 1.0)
        u, v = math.cos(a) * r * 1.15, math.sin(a) * r  # longer along the ring
        px, py = cx + tx * u - rx * v, cy + ty * u - ry * v  # (tangent, -radial) keeps the outline anticlockwise
        base.append((px, py, TOP - 0.04))
        top.append((cx + (px - cx) * 0.72, cy + (py - cy) * 0.72, height))
    face(top, rng.choice(STONE_TOP))
    side = rng.choice(STONE_SIDE)
    for s in range(k):
        b0, b1, t0, t1 = base[s], base[(s + 1) % k], top[s], top[(s + 1) % k]
        face([b0, b1, t1, t0], side)


count = round(2 * math.pi * R_STONES / STONE_STEP)
stones = 0
for s in range(count):
    a = 2 * math.pi * s / count + rng.uniform(-0.01, 0.01)
    if not angle_ok(a, GATE_HALF):
        continue
    stone(R_STONES * math.cos(a), R_STONES * math.sin(a), a, rng.uniform(0.78, 0.92), TOP + rng.uniform(0.18, 0.3))
    stones += 1


# --- a few bones lying about (clear of the crypt in the middle and of the walk in from the entrance)
def box(cx, cy, z0, sx, sy, sz, yaw, top_color, side_color):
    c, s = math.cos(yaw), math.sin(yaw)

    def v(x, y, z):
        return (cx + x * c - y * s, cy + x * s + y * c, z0 + z)

    hx, hy = sx / 2, sy / 2
    face([v(-hx, -hy, sz), v(hx, -hy, sz), v(hx, hy, sz), v(-hx, hy, sz)], top_color)
    face([v(hx, -hy, 0), v(hx, hy, 0), v(hx, hy, sz), v(hx, -hy, sz)], side_color)
    face([v(-hx, -hy, 0), v(-hx, -hy, sz), v(-hx, hy, sz), v(-hx, hy, 0)], side_color)
    face([v(-hx, hy, 0), v(-hx, hy, sz), v(hx, hy, sz), v(hx, hy, 0)], side_color)
    face([v(-hx, -hy, 0), v(hx, -hy, 0), v(hx, -hy, sz), v(-hx, -hy, sz)], side_color)


bones = 0
tries = 0
placed = []
while bones < 8 and tries < 500:
    tries += 1
    a = rng.uniform(0, 2 * math.pi)
    r = rng.uniform(14.5, 20.0)
    if not angle_ok(a, math.radians(28)):
        continue
    x, y = r * math.cos(a), r * math.sin(a)
    if any((x - px) ** 2 + (y - py) ** 2 < 36 for px, py in placed):
        continue
    placed.append((x, y))
    yaw = rng.uniform(0, math.pi)
    L = rng.uniform(0.95, 1.2)
    box(x, y, TOP - 0.01, L, 0.16, 0.12, yaw, BONE_TOP, BONE_SIDE)
    for e in (-1, 1):
        for side in (-1, 1):
            ox, oy = e * L / 2, side * 0.11
            box(x + ox * math.cos(yaw) - oy * math.sin(yaw), y + ox * math.sin(yaw) + oy * math.cos(yaw), TOP - 0.01,
                0.2, 0.2, 0.16, yaw, BONE_TOP, BONE_SIDE)
    bones += 1


# --- grass tufts just inside the stones
def blade(x, y, lean_a, h, color):
    w = 0.09
    b = [(x + w * math.cos(t), y + w * math.sin(t), TOP - 0.02) for t in (0, 2 * math.pi / 3, 4 * math.pi / 3)]
    apex = (x + 0.12 * math.cos(lean_a), y + 0.12 * math.sin(lean_a), TOP + h)
    for s in range(3):
        face([b[s], b[(s + 1) % 3], apex], color)


tufts = 0
for t in range(16):
    a = rng.uniform(0, 2 * math.pi)
    if not angle_ok(a, math.radians(20)):
        continue
    r = rng.uniform(20.6, 21.2)
    x, y = r * math.cos(a), r * math.sin(a)
    for q in range(3):
        blade(x + rng.uniform(-0.15, 0.15), y + rng.uniform(-0.15, 0.15), rng.uniform(0, 2 * math.pi),
              rng.uniform(0.35, 0.55), rng.choice(GRASS))
    tufts += 1

me = bpy.data.meshes.new('Main')
bm.to_mesh(me)
bm.free()
obj = bpy.data.objects.new('Main', me)
bpy.context.scene.collection.objects.link(obj)
me.color_attributes.active_color = me.color_attributes['Col']
me.color_attributes.render_color_index = 0

mat = bpy.data.materials.new('Main')
try:
    mat.use_nodes = True
except Exception:
    pass
nt = mat.node_tree
bsdf = next(nd for nd in nt.nodes if nd.type == 'BSDF_PRINCIPLED')
vc = nt.nodes.new('ShaderNodeVertexColor')
vc.layer_name = 'Col'
nt.links.new(vc.outputs['Color'], bsdf.inputs['Base Color'])
me.materials.append(mat)

lo = [min(v.co[i] for v in me.vertices) for i in range(3)]
hi = [max(v.co[i] for v in me.vertices) for i in range(3)]
centre_gltf = [(lo[0] + hi[0]) / 2, (lo[2] + hi[2]) / 2, -(lo[1] + hi[1]) / 2]
kw = dict(filepath=out_glb, export_format='GLB', export_yup=True, export_apply=True, export_materials='EXPORT')
try:
    bpy.ops.export_scene.gltf(**kw, export_vertex_color='ACTIVE')
except TypeError:
    bpy.ops.export_scene.gltf(**kw, export_colors=True)
with open(out_json, 'w') as f:
    json.dump({'name': 'Cemetery_Round', 'c': centre_gltf, 'tris': sum(len(p.vertices) - 2 for p in me.polygons),
               'tiles': tiles, 'stones': stones, 'bones': bones, 'tufts': tufts}, f)
print('DONE', out_glb, tiles, stones, bones, tufts)
