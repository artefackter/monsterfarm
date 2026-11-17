# Melee weapons built from code (owner, 2026-11-16: "replace the shovels with other weapons" - the Reaper's Scythe, the
# katana, the Mimicry dagger, the butterfly knife and the diamond pickaxe; the chainsaw and the chainsword are built
# from parts in the game itself). Each is one static GLB of a few objects (one material each), colours in COLOR_0 as
# sRGB numbers raw (Roblox shows COLOR_0 as it is; the importer drops material base colours).
# Axes are the shovel's (ShovelModel / ShovelMotion), in the asset's space once imported and normalised:
#   origin  the middle of the right hand's grip (the model's pivot)
#   Y       the long axis: the working end (blade, pick head) towards -Y, the pommel / butt towards +Y; a two-hand
#           weapon's other hand takes it one stud further towards +Y
#   -Z      the cutting edge, the way it strikes
# Asset (x, y, z) is Blender (-x, z, y) and glTF (-x, y, -z) (the importer turns the meshes half round).
# Everything is a closed shell, wound outwards (Roblox culls back faces).
# Writes <out>/<Name>.glb, <out>/melee.json (bounds, the glTF bounds centre `c` normalize_v5.lua wants, parts with a
# suggested Roblox material, the butterfly knife's hinges) and QA sheets rendered from the exported files in <out>/qa.
# Usage: blender --background --factory-startup --python build_melee.py -- <out dir> [Name,Name|all] [norender]
import bpy, bmesh, math, random, sys, os, json, struct
from mathutils import Vector, Matrix, noise

ARGS = sys.argv[sys.argv.index('--') + 1:]
OUT = os.path.abspath(ARGS[0])
ONLY = set(ARGS[1].split(',')) if len(ARGS) > 1 and ARGS[1] != 'all' else None
RENDER = not (len(ARGS) > 2 and ARGS[2] == 'norender')
QA = os.path.join(OUT, 'qa')
os.makedirs(QA, exist_ok=True)
TAU = math.pi * 2


def rgb(r, g, b):
    return (r / 255, g / 255, b / 255)


def mix(a, b, t):
    t = max(0.0, min(1.0, t))
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def shade(c, k):
    return tuple(max(0.0, min(1.0, v * k)) for v in c)


def smooth(t):
    t = max(0.0, min(1.0, t))
    return t * t * (3 - 2 * t)


def lerp(a, b, t):
    return a + (b - a) * t


def centre(ps):
    n = len(ps)
    return tuple(sum(p[i] for p in ps) / n for i in range(3))


def ell(y, rx, rz, n, cz=0.0, cx=0.0, phase=0.0):
    """A ring across the long axis: an ellipse in the XZ plane at height y."""
    return [(cx + rx * math.cos(TAU * (j + phase) / n), y, cz + rz * math.sin(TAU * (j + phase) / n)) for j in range(n)]


def ring_xy(z, rx, ry, n, cy=0.0, cx=0.0):
    """A ring across Z: an ellipse in the XY plane."""
    return [(cx + rx * math.cos(TAU * j / n), cy + ry * math.sin(TAU * j / n), z) for j in range(n)]


def ring_yz(x, r, n, cy=0.0, cz=0.0):
    """A ring across X: a circle in the YZ plane."""
    return [(x, cy + r * math.cos(TAU * j / n), cz + r * math.sin(TAU * j / n)) for j in range(n)]


def is_point(r):
    return isinstance(r[0], (int, float))


class Part:
    """One object: closed shells lofted through rings of asset-space points, a colour a face."""

    def __init__(self, name, flat=False, sharp=35, material='SmoothPlastic', reflectance=0.0, color=None):
        self.name, self.flat, self.sharp = name, flat, math.radians(sharp)
        self.material, self.reflectance, self.color = material, reflectance, color
        self.bm = bmesh.new()
        self.col = self.bm.loops.layers.float_color.new('Col')

    def vert(self, p):
        return self.bm.verts.new((-p[0], p[2], p[1]))

    def face(self, verts, color, pts=None, vcol=None):
        f = self.bm.faces.new(verts)
        for n, loop in enumerate(f.loops):
            c = vcol(pts[n]) if vcol else color
            loop[self.col] = (c[0], c[1], c[2], 1.0)
        return f

    def loft(self, rings, color, cap0=True, cap1=True, cap_color=None, two=False, diamond=None, vcol=None):
        """rings: lists of points (all the same length), or one point (a tip the neighbouring ring fans to).
        color: one colour or f(i, j, centre, k) - ring interval, segment, the face's middle, triangle 0/1 (two=True
        cuts every quad into two triangles coloured apart). vcol=f(point): a colour a vertex instead, blended across
        the faces. diamond=(cord, skin, size): every quad a diamond of `skin` in its middle (size 1 reaches the
        quad's edges) with `cord` round it - a sword grip's wrap."""
        col = color if callable(color) else (lambda i, j, c, k=0: color)
        pts = [[r] if is_point(r) else r for r in rings]
        vs = [[self.vert(p) for p in r] for r in pts]
        for i in range(len(vs) - 1):
            a, b, pa, pb = vs[i], vs[i + 1], pts[i], pts[i + 1]
            n = max(len(a), len(b))
            if n == 1:
                continue
            for j in range(n):
                k = (j + 1) % n
                if len(a) == 1:
                    ps = [pa[0], pb[j], pb[k]]
                    self.face([a[0], b[j], b[k]], col(i, j, centre(ps), 0), ps, vcol)
                elif len(b) == 1:
                    ps = [pa[j], pa[k], pb[0]]
                    self.face([a[j], a[k], b[0]], col(i, j, centre(ps), 0), ps, vcol)
                elif vcol:
                    ps = [pa[j], pa[k], pb[k], pb[j]]
                    self.face([a[j], a[k], b[k], b[j]], None, ps, vcol)
                elif diamond:
                    corners, cp = [a[j], a[k], b[k], b[j]], [pa[j], pa[k], pb[k], pb[j]]
                    c = centre(cp)
                    d = []
                    for q in range(4):
                        m = centre([cp[q], cp[(q + 1) % 4]])
                        d.append(self.vert(tuple(lerp(c[x], m[x], diamond[2]) for x in range(3))))
                    self.face(d, diamond[1])
                    for q in range(4):
                        self.face([corners[q], corners[(q + 1) % 4], d[q]], diamond[0])
                        self.face([corners[(q + 1) % 4], d[(q + 1) % 4], d[q]], diamond[0])
                elif two:
                    c = centre([pa[j], pa[k], pb[k], pb[j]])
                    if (i + j) % 2:
                        self.face([a[j], a[k], b[k]], col(i, j, c, 0))
                        self.face([a[j], b[k], b[j]], col(i, j, c, 1))
                    else:
                        self.face([a[j], a[k], b[j]], col(i, j, c, 0))
                        self.face([a[k], b[k], b[j]], col(i, j, c, 1))
                else:
                    self.face([a[j], a[k], b[k], b[j]], col(i, j, centre([pa[j], pa[k], pb[k], pb[j]]), 0))
        if cap0 and len(vs[0]) > 2:
            self.face(list(reversed(vs[0])), cap_color or col(-1, 0, centre(pts[0]), 0))
        if cap1 and len(vs[-1]) > 2:
            self.face(vs[-1], cap_color or col(len(vs) - 1, 0, centre(pts[-1]), 0))

    def box(self, lo, hi, color):
        (x0, y0, z0), (x1, y1, z1) = lo, hi
        self.loft([[(x0, y0, z0), (x1, y0, z0), (x1, y0, z1), (x0, y0, z1)],
                   [(x0, y1, z0), (x1, y1, z0), (x1, y1, z1), (x0, y1, z1)]], color)

    def finish(self):
        bm = self.bm
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
        for f in bm.faces:
            f.smooth = not self.flat
        for e in bm.edges:
            if len(e.link_faces) == 2 and e.calc_face_angle(0.0) > self.sharp:
                e.smooth = False
        open_edges = sum(1 for e in bm.edges if len(e.link_faces) != 2)
        bmesh.ops.triangulate(bm, faces=bm.faces[:])
        # every shell must hold a positive volume (wound outwards)
        seen, inside_out, shells = set(), 0, 0
        for f0 in bm.faces:
            if f0.index in seen and seen:
                pass
        bm.faces.index_update()
        seen = set()
        for f0 in bm.faces:
            if f0.index in seen:
                continue
            stack, vol = [f0], 0.0
            seen.add(f0.index)
            while stack:
                f = stack.pop()
                v = [l.vert.co for l in f.loops]
                vol += v[0].dot(v[1].cross(v[2])) / 6
                for e in f.edges:
                    for g in e.link_faces:
                        if g.index not in seen:
                            seen.add(g.index)
                            stack.append(g)
            shells += 1
            if vol <= 0:
                inside_out += 1
        lo = [min(v.co[i] for v in bm.verts) for i in range(3)]
        hi = [max(v.co[i] for v in bm.verts) for i in range(3)]
        me = bpy.data.meshes.new(self.name)
        bm.to_mesh(me)
        bm.free()
        obj = bpy.data.objects.new(self.name, me)
        bpy.context.scene.collection.objects.link(obj)
        me.color_attributes.active_color = me.color_attributes['Col']
        me.color_attributes.render_color_index = 0
        mat = bpy.data.materials.new(self.name)
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
        # Blender (x, y, z) is asset (-x, z, y)
        self.stats = {'tris': len(me.polygons), 'material': self.material, 'reflectance': self.reflectance,
                      'min': [round(-hi[0], 3), round(lo[2], 3), round(lo[1], 3)],
                      'max': [round(-lo[0], 3), round(hi[2], 3), round(hi[1], 3)],
                      'shells': shells, 'open_edges': open_edges, 'inside_out': inside_out}
        if self.color:
            self.stats['color'] = self.color
        return obj


WHITE = (1.0, 1.0, 1.0)
GOLD = rgb(232, 186, 84)
GOLD_DARK = rgb(176, 132, 58)
STEEL_EDGE = rgb(240, 245, 252)


# ----------------------------------------------------------------------------------------------- the katana
def katana():
    c, y0, L = 0.02, -0.62, 2.85

    def zc(y):  # the whole sword is one shallow arc, its ends towards the back of the blade
        return c * (y - y0) ** 2 - c * y0 * y0

    def normal(y):  # across the blade, towards its back, in (y, z)
        dz = 2 * c * (y - y0)
        l = math.hypot(1, dz)
        return -dz / l, 1 / l

    blade = Part('Blade', sharp=26, material='Metal', reflectance=0.25)
    N, sk, rings = 36, 0.86, []
    for i in range(N):
        s = i / N
        y = y0 - L * s
        w, t = lerp(0.40, 0.33, s), lerp(0.11, 0.08, s)
        k = max(0.0, (s - sk) / (1 - sk))
        edge = -w / 2 + w * 0.97 * k ** 1.7  # the point: the edge sweeps up to the back
        t *= 1 - 0.7 * k
        ridge = edge + (w / 2 - edge) * 0.5
        ny, nz = normal(y)
        rings.append([(x, y + ny * zl, zc(y) + nz * zl) for x, zl in
                      [(0, edge), (t / 2, ridge), (t * 0.36, w / 2), (-t * 0.36, w / 2), (-t / 2, ridge)]])
    yt = y0 - L
    ny, nz = normal(yt)
    rings.append((0, yt + ny * 0.165, zc(yt) + nz * 0.165))

    def blade_col(i, j, p, k=0):
        s = max(0, i) / N
        if j in (0, 4):  # the polished edge
            return mix(rgb(232, 240, 250), rgb(252, 254, 255), s)
        if j in (1, 3):
            return mix(rgb(146, 160, 190), rgb(182, 194, 218), s)
        return rgb(100, 110, 138)

    blade.loft(rings, blade_col)

    guard = Part('Guard', sharp=30, material='Metal', reflectance=0.15)
    guard.loft([ell(y, rx, rz, 12, zc(y)) for y, rx, rz in [(-0.49, 0.082, 0.235), (-0.74, 0.068, 0.212)]], GOLD)  # habaki
    tsuba = [(-0.395, 0.275), (-0.412, 0.345), (-0.472, 0.345), (-0.489, 0.275)]
    guard.loft([ell(y, r, r, 20, zc(y)) for y, r in tsuba],
               lambda i, j, p, k=0: GOLD if i == 1 else GOLD_DARK, cap_color=rgb(50, 46, 64))
    guard.loft([ell(y, rx, rz, 12, zc(y)) for y, rx, rz in [(-0.395, 0.12, 0.168), (-0.30, 0.113, 0.16)]], GOLD)  # fuchi
    guard.loft([ell(y, rx, rz, 12, zc(y)) for y, rx, rz in
                [(1.35, 0.12, 0.168), (1.46, 0.12, 0.168), (1.51, 0.08, 0.115)]], GOLD)  # kashira

    handle = Part('Handle', sharp=50, material='Fabric')
    T, rings = 14, []
    for i in range(T + 1):
        t = i / T
        y = lerp(-0.30, 1.35, t)
        waist = 1 - 0.06 * math.sin(math.pi * t)
        rings.append(ell(y, 0.105 * waist, 0.152 * waist, 8, zc(y), phase=0.5))
    handle.loft(rings, WHITE, diamond=(rgb(150, 26, 44), rgb(244, 230, 196), 0.6))
    return [handle, guard, blade], {'twoHand': True, 'leftHand': [0, 1, 0], 'primary': 'Handle'}


# ----------------------------------------------------------------------------------------------- the scythe
def scythe():
    rng = random.Random(7)

    def sz(y):  # the snath leans towards the blade at its head, and a little back at the butt
        z = 0.0
        if y < -1.6:
            z -= 0.24 * ((-1.6 - y) / 2.7) ** 2
        if y > 1.5:
            z += 0.05 * ((y - 1.5) / 0.7) ** 2
        return z

    def sr(y):
        return 0.112 + 0.03 * smooth((-3.3 - y) / 0.9) + 0.012 * smooth((y - 1.6) / 0.6)

    handle = Part('Handle', sharp=50, material='Wood')
    ys = [2.2 - 0.25 * i for i in range(27)]
    grain = [1 + 0.16 * (rng.random() - 0.5) for _ in range(8)]
    handle.loft([ell(y, sr(y), sr(y), 8, sz(y)) for y in ys],
                lambda i, j, p, k=0: shade(rgb(76, 54, 70), grain[j] * (1 + 0.04 * math.sin(i * 1.7 + j))))

    wrap = Part('Wrap', sharp=50, material='Fabric')
    for lo, hi in [(-0.45, 0.45), (0.72, 1.36)]:
        n = round((hi - lo) / 0.09)
        ring_ys = [lerp(lo, hi, i / n) for i in range(n + 1)]
        wrap.loft([ell(y, sr(y) + 0.016, sr(y) + 0.016, 8, sz(y)) for y in ring_ys],
                  lambda i, j, p, k=0: rgb(104, 68, 146) if max(0, i) % 2 else rgb(78, 50, 112))

    bone, bone_dark = rgb(236, 226, 204), rgb(196, 182, 158)
    collar = Part('Collar', sharp=40, material='SmoothPlastic')
    collar.loft([ell(2.14, 0.145, 0.145, 8, sz(2.14)), ell(2.2, 0.155, 0.155, 8, sz(2.2)),
                 ell(2.27, 0.115, 0.115, 8, sz(2.27)), (0, 2.5, sz(2.5))],
                lambda i, j, p, k=0: bone if i != 0 else bone_dark)
    zr = sz(-4.22)
    sock = [(-3.9, 0.15), (-3.96, 0.205), (-4.08, 0.215), (-4.4, 0.22), (-4.5, 0.17)]
    collar.loft([ell(y, r, r, 8, sz(y)) for y, r in sock] + [(0, -4.86, sz(-4.5) - 0.06)],
                lambda i, j, p, k=0: bone_dark if i in (0, 3) else bone)
    # a spur on the back of the socket, curling to the butt
    collar.loft([ring_xy(zr + 0.14, 0.09, 0.105, 6, -4.2), ring_xy(zr + 0.4, 0.058, 0.068, 6, -4.17),
                 (0, -4.05, zr + 0.68)], bone)

    # the blade: an arc out towards -Z that droops back to the holder; the back outside, the edge inside
    R, Cz = 3.3, zr
    Cy = -4.26 + R
    a0, a1, N = math.radians(-3.5), math.radians(61), 40

    def at(x, r, a):
        return (x, Cy - r * math.cos(a), Cz - r * math.sin(a))

    def bw(u):
        return 0.84 * (1 - u) ** 0.72 * (0.62 + 0.38 * smooth(u / 0.07))

    blade = Part('Blade', sharp=26, material='Metal', reflectance=0.2)
    rings = []
    for i in range(N):
        u = i / N
        a, w, t = lerp(a0, a1, u), bw(u), 0.115 * (1 - 0.45 * u)
        rings.append([at(x, R - d, a) for x, d in
                      [(t / 2, 0), (t * 0.4, 0.6 * w), (0, w), (-t * 0.4, 0.6 * w), (-t / 2, 0)]])
    rings.append(at(0, R, a1 + math.radians(0.6)))

    def blade_col(i, j, p, k=0):
        u = max(0, i) / N
        if j in (1, 2):
            return mix(rgb(204, 214, 238), rgb(236, 244, 255), u)
        if j in (0, 3):
            return mix(rgb(62, 62, 92), rgb(92, 78, 132), u)
        return rgb(38, 40, 58)

    blade.loft(rings, blade_col)

    glow = Part('Glow', sharp=60, material='Neon', color='7CFFC8')
    # dashes of light let into both faces of the blade, and a band round the socket
    i = 3
    while i < N - 9:
        seg = []
        for q in range(i, i + 4):
            u = q / N
            a, w, t = lerp(a0, a1, u), bw(u), 0.115 * (1 - 0.45 * u)
            x = t / 2 * 0.93 + 0.02
            seg.append([at(x, R - 0.2 * w, a), at(x, R - 0.36 * w, a), at(-x, R - 0.36 * w, a), at(-x, R - 0.2 * w, a)])
        glow.loft(seg, WHITE)
        i += 5
    glow.loft([ell(y, 0.234, 0.234, 10, sz(y)) for y in (-4.17, -4.29)], WHITE)
    return [handle, wrap, collar, blade, glow], {'twoHand': True, 'leftHand': [0, 1, 0], 'primary': 'Handle'}


# ----------------------------------------------------------------------------------------------- the Mimicry dagger
def dagger():
    yb, L = -0.40, 1.02
    PAL = [rgb(48, 224, 206), rgb(150, 86, 255), rgb(255, 96, 178), rgb(255, 166, 56), rgb(64, 66, 176)]
    BIAS = [0.0, 0.02, -0.02, -0.05, -0.1]

    def hw(s):  # a leaf: it swells past the guard, then runs out to the point
        if s <= 0.36:
            return 0.125 + 0.09 * smooth(s / 0.36)
        return 0.215 * (1 - ((s - 0.36) / 0.64) ** 1.9)

    def camo(y, z, side):
        # the patch is whichever field is highest here; near a border the two highest blend, so the border
        # runs where the fields cross and not along the mesh's grid
        best, top, second, below = 0, -9.0, 0, -9.0
        for i in range(len(PAL)):
            v = noise.noise(Vector((y * 5.2 + i * 11.7, z * 6.0 + side * 5.1, i * 3.3 + side * 2.0))) + BIAS[i]
            if v > top:
                second, below, best, top = best, top, i, v
            elif v > below:
                second, below = i, v
        s = (yb - y) / L
        shimmer = 0.5 + 0.5 * math.sin(y * 9 + z * 14 + side)

        def tone(i):
            return mix(mix(PAL[i], PAL[(i + 1) % 4], 0.22 * shimmer), WHITE, 0.14 * s)

        return mix(tone(second), tone(best), 0.5 + 0.5 * smooth((top - below) / 0.07))

    blade = Part('Blade', sharp=40, material='Metal', reflectance=0.2)
    N, M, rings = 56, 12, []
    for i in range(N):
        s = i / N
        y, h = yb - L * s, hw(s)
        t = 0.05 * (1 - 0.55 * s) + 0.012
        ring = [(t * (1 - abs(-h + 2 * h * k / M) / h), y, -h + 2 * h * k / M) for k in range(M + 1)]
        ring += [(-t * (1 - abs(-h + 2 * h * k / M) / h), y, -h + 2 * h * k / M) for k in range(M - 1, 0, -1)]
        rings.append(ring)
    rings.append((0, yb - L, 0))

    def blade_col(p):
        s = (yb - p[1]) / L
        if abs(p[2]) > hw(min(s, 0.999)) * 0.8 - 1e-6 or s > 0.955:
            return STEEL_EDGE
        return camo(p[1], p[2], 1 if p[0] > 0 else -1)

    blade.loft(rings, WHITE, vcol=blade_col)

    teal, teal_dark = rgb(44, 216, 202), rgb(22, 150, 170)
    guard = Part('Guard', sharp=40, material='Metal', reflectance=0.15)
    R, K = 0.37, 14
    rings = [(0, -0.535, -R - 0.045)]
    for i in range(K + 1):
        z = -R + 2 * R * i / K
        a = abs(z) / R
        rings.append(ring_xy(z, 0.08 * (1 - 0.55 * a * a), 0.06 * (1 - 0.5 * a * a), 10, -0.35 - 0.15 * a ** 2.2))
    rings.append((0, -0.535, R + 0.045))
    guard.loft(rings, lambda i, j, p, k=0: mix(teal, teal_dark, abs(p[2]) / R) if j < 5 else mix(shade(teal, 1.15), teal, abs(p[2]) / R))
    guard.loft([ell(-0.30, 0.088, 0.172, 10), ell(-0.45, 0.07, 0.148, 10)], teal_dark)
    pommel = [(0.60, 0.092, 0.108), (0.655, 0.128, 0.15), (0.71, 0.128, 0.15)]
    guard.loft([ell(y, rx, rz, 6) for y, rx, rz in pommel] + [(0, 0.80, 0)],
               lambda i, j, p, k=0: shade(teal, (0.82, 1.0, 1.16)[(i + j) % 3]))

    handle = Part('Handle', sharp=50, material='SmoothPlastic')
    T, rings = 18, []
    for i in range(T + 1):
        t = i / T
        groove = 0.5 - 0.5 * math.cos(TAU * 3 * t)
        rings.append(ell(lerp(-0.30, 0.60, t), 0.1 - 0.014 * groove, 0.124 - 0.022 * groove, 10))

    def grip_col(i, j, p, k=0):
        t = (max(0, i) + 0.5) / T
        a, b, c = rgb(255, 160, 60), rgb(240, 72, 160), rgb(120, 72, 226)
        return mix(a, b, t * 2) if t < 0.5 else mix(b, c, t * 2 - 1)

    handle.loft(rings, grip_col)
    return [handle, guard, blade], {'twoHand': False, 'primary': 'Handle'}


# ----------------------------------------------------------------------------------------------- the butterfly knife
def butterfly():
    PY, PZ = -0.22, 0.095  # the two pivot pins, side by side at the blade's foot: +Z the hand's handle, -Z the other
    T, W, CH = 0.062, 0.078, 0.02
    blue, cyan, slot, pin = rgb(44, 96, 236), rgb(64, 212, 244), rgb(20, 24, 52), rgb(246, 196, 72)
    stations = [(-0.305, 0.45), (-0.29, 0.8), (-0.25, 1), (-0.13, 1), (0.0, 1), (0.2, 1), (0.28, 1), (0.48, 1), (0.56, 1),
                (0.74, 1), (0.79, 1), (0.815, 0.8), (0.827, 0.45)]
    slots = [(0.0, 0.2), (0.28, 0.48), (0.56, 0.74)]

    def handle(name, zc):
        p = Part(name, sharp=32, material='Metal', reflectance=0.1)
        rings = []
        for y, k in stations:
            t, w, s = T * k, W * k, 0.03 * k
            rings.append([(x, y, zc + z) for x, z in
                          [(t, -w + CH * k), (t, -s), (t, s), (t, w - CH * k), (t - CH * k, w), (-t + CH * k, w),
                           (-t, w - CH * k), (-t, s), (-t, -s), (-t, -w + CH * k), (-t + CH * k, -w), (t - CH * k, -w)]])

        def col(i, j, c, k=0):
            if i < 0 or i >= len(stations) - 1:
                return blue
            y0, y1 = stations[i][0], stations[i + 1][0]
            if j in (1, 7) and any(a <= y0 + 1e-6 and y1 <= b + 1e-6 for a, b in slots):
                return slot
            base = mix(blue, cyan, (c[1] + 0.3) / 1.12)
            return shade(base, 1.2) if j in (3, 5, 9, 11) else shade(base, 0.78) if j in (4, 10) else base

        p.loft(rings, col)
        # the pivot pin, and a rivet further up
        p.loft([ring_yz(x, 0.042, 8, PY, zc) for x in (-T - 0.022, T + 0.022)], pin)
        p.loft([ring_yz(x, 0.026, 8, 0.52, zc) for x in (-T - 0.014, T + 0.014)], pin)
        return p

    a, b = handle('Handle', PZ), handle('HandleB', -PZ)
    # the latch at the end of the second handle, reaching across to the first
    b.loft([ring_xy(z, 0.024, 0.02, 6, 0.842) for z in (-PZ - 0.02, PZ + 0.02)], pin)
    b.loft([ring_xy(z, 0.04, 0.034, 6, 0.842) for z in (-PZ - 0.06, -PZ - 0.02)], pin)

    blade = Part('Blade', sharp=26, material='Metal', reflectance=0.3)

    def spine(y):
        if y > -0.30:
            return 0.12
        if y > -0.36:
            return lerp(0.12, 0.15, (-0.30 - y) / 0.06)
        if y > -0.80:
            return 0.15
        u = (-0.80 - y) / 0.38
        return lerp(0.15, 0.02, u) - 0.028 * math.sin(math.pi * u)

    def edge(y):
        if y > -0.30:
            return -0.12
        if y > -0.36:
            return lerp(-0.12, -0.16, (-0.30 - y) / 0.06)
        if y > -0.72:
            return -0.16
        v = (-0.72 - y) / 0.46
        return -0.16 + 0.18 * v ** 2.1

    ys = [-0.10, -0.30, -0.36] + [lerp(-0.40, -1.16, i / 21) for i in range(22)]
    rings = []
    for y in ys:
        zs, ze = spine(y), edge(y)
        t = lerp(0.03, 0.02, smooth((-0.36 - y) / 0.8))
        rings.append([(0, y, ze), (t, y, ze + 0.36 * (zs - ze)), (t * 0.8, y, zs), (-t * 0.8, y, zs), (-t, y, ze + 0.36 * (zs - ze))])
    rings.append((0, -1.18, 0.02))
    blade.loft(rings, lambda i, j, p, k=0: STEEL_EDGE if j in (0, 4) else rgb(190, 198, 214) if j in (1, 3) else rgb(140, 148, 168))
    hinges = {'axis': [1, 0, 0],
              'A': {'point': [0, PY, PZ], 'moves': ['Blade', 'HandleB'], 'about': 'Handle'},
              'B': {'point': [0, PY, -PZ], 'moves': ['HandleB'], 'about': 'Blade'}}
    return [a, b, blade], {'twoHand': False, 'primary': 'Handle', 'hinges': hinges}


# ----------------------------------------------------------------------------------------------- the diamond pickaxe
def pickaxe():
    rng = random.Random(11)
    yh = -2.1  # the head's middle

    handle = Part('Handle', sharp=50, material='Wood')
    ys = [1.78, 1.7] + [1.5 - 0.25 * i for i in range(15)]
    grain = [1 + 0.2 * (rng.random() - 0.5) for _ in range(8)]

    def hr(y):
        return 1 + 0.16 * smooth((y - 1.45) / 0.3) + 0.14 * smooth((-1.3 - y) / 0.7)

    handle.loft([ell(y, 0.086 * hr(y), 0.112 * hr(y), 8) for y in ys],
                lambda i, j, p, k=0: shade(rgb(176, 120, 74), grain[j] * (1 + 0.04 * math.sin(i * 1.9 + j * 2))))

    wrap = Part('Wrap', sharp=50, material='Fabric')
    for lo, hi in [(-0.42, 0.42), (0.72, 1.32)]:
        n = round((hi - lo) / 0.085)
        wrap.loft([ell(lerp(lo, hi, i / n), 0.086 * hr(lerp(lo, hi, i / n)) + 0.016, 0.112 * hr(lerp(lo, hi, i / n)) + 0.016, 8)
                   for i in range(n + 1)],
                  lambda i, j, p, k=0: rgb(46, 84, 118) if max(0, i) % 2 else rgb(30, 58, 86))

    iron, iron_lit = rgb(58, 64, 90), rgb(84, 92, 124)
    collar = Part('Collar', sharp=30, material='Metal', reflectance=0.12)
    eye = [(-1.74, 0.17, 0.235), (-1.8, 0.205, 0.275), (-2.4, 0.205, 0.275), (-2.46, 0.17, 0.235), (-2.52, 0.1, 0.14)]
    collar.loft([ell(y, rx, rz, 8, phase=0.5) for y, rx, rz in eye],
                lambda i, j, p, k=0: iron_lit if j in (1, 2, 5, 6) else iron)
    for y in (-1.83, -2.4):  # gold bands
        collar.loft([ell(y + d, 0.22, 0.29, 8, phase=0.5) for d in (0.0, 0.065)], GOLD)
    collar.loft([ell(1.76, 0.115, 0.145, 8), ell(1.86, 0.115, 0.145, 8), ell(1.91, 0.07, 0.09, 8)], GOLD)

    # the head: one faceted crystal through the eye, a long beak towards -Z and a shorter chisel behind, both
    # drooping to the holder; a gem on top
    ice = [rgb(160, 248, 255), rgb(58, 214, 246), rgb(24, 150, 228)]
    head = Part('Head', flat=True, material='Glass', reflectance=0.3)
    cuts = [(-0.82, 0.085, 0.05), (-0.58, 0.17, 0.105), (-0.32, 0.25, 0.155), (-0.14, 0.27, 0.178), (0.16, 0.27, 0.178),
            (0.36, 0.25, 0.158), (0.66, 0.2, 0.125), (0.94, 0.165, 0.07), (1.0, 0.15, 0.004)]

    def hz(v):
        return v * (1.5 if v < 0 else 1.08)

    def hy(v):
        return yh + (0.4 if v < 0 else 0.3) * abs(v) ** 1.8

    rings = [(0, hy(-1), hz(-1))]
    for v, h, w in cuts:
        rings.append([(x, hy(v) + yl, hz(v)) for x, yl in
                      [(0, -h), (w, -h * 0.3), (w, h * 0.45), (0, h), (-w, h * 0.45), (-w, -h * 0.3)]])

    def ice_col(i, j, p, k=0):
        base = ice[(0, 1, 2, 2, 1, 0)[j]]
        spark = rng.random()
        c = mix(base, WHITE, 0.16 * abs(p[2]) / 1.5)
        return mix(c, WHITE, 0.45) if spark > 0.86 else shade(c, 0.9 if k else 1.04)

    head.loft(rings, ice_col, two=True)
    gem = [(-2.5, 0.09), (-2.62, 0.17), (-2.7, 0.15)]
    head.loft([ell(y, r, r, 6, phase=0.5) for y, r in gem] + [(0, -3.0, 0)],
              lambda i, j, p, k=0: mix(ice[(i + j) % 3], WHITE, 0.25 if (i + j) % 2 else 0.0))
    return [handle, wrap, collar, head], {'twoHand': True, 'leftHand': [0, 1, 0], 'primary': 'Handle'}


BUILDERS = {'Melee_Scythe': scythe, 'Melee_Katana': katana, 'Melee_Dagger': dagger, 'Melee_Butterfly': butterfly,
            'Melee_Pickaxe': pickaxe}
ORDER = ['Melee_Butterfly', 'Melee_Dagger', 'Melee_Katana', 'Melee_Pickaxe', 'Melee_Scythe']


def export(name):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    parts, meta = BUILDERS[name]()
    for p in parts:
        p.finish()
    lo = [min(p.stats['min'][i] for p in parts) for i in range(3)]
    hi = [max(p.stats['max'][i] for p in parts) for i in range(3)]
    path = os.path.join(OUT, name + '.glb')
    kw = dict(filepath=path, export_format='GLB', export_yup=True, export_apply=True, export_materials='EXPORT')
    try:
        bpy.ops.export_scene.gltf(**kw, export_vertex_color='ACTIVE')
    except TypeError:
        bpy.ops.export_scene.gltf(**kw, export_colors=True)
    info = {'file': name + '.glb', 'min': lo, 'max': hi, 'size': [round(hi[i] - lo[i], 3) for i in range(3)],
            # the bounds' centre in glTF space, (-x, y, -z) of the asset's: normalize_v5.lua's META c
            'c': [round(-(lo[0] + hi[0]) / 2, 4), round((lo[1] + hi[1]) / 2, 4), round(-(lo[2] + hi[2]) / 2, 4)],
            'tris': sum(p.stats['tris'] for p in parts), 'parts': {p.name: p.stats for p in parts}}
    info.update(meta)
    neon = {p.name: p.color for p in parts if p.material == 'Neon' and p.color}
    if neon:
        info['neon'] = neon
    bad = [p.name for p in parts if p.stats['open_edges'] or p.stats['inside_out']]
    print('BUILT', name, info['size'], info['tris'], 'BAD ' + ','.join(bad) if bad else 'ok')
    return info


def check_glb(name, info):
    """Reads the exported file back: every object there, with colours, inside the bounds the build measured."""
    with open(os.path.join(OUT, name + '.glb'), 'rb') as f:
        f.read(12)
        n, _ = struct.unpack('<II', f.read(8))
        js = json.loads(f.read(n))
    acc = js['accessors']
    names = {}
    for node in js['nodes']:
        if 'mesh' not in node:
            continue
        moved = any(k in node for k in ('translation', 'rotation', 'scale', 'matrix'))
        mesh = js['meshes'][node['mesh']]
        prims = mesh['primitives']
        pos = acc[prims[0]['attributes']['POSITION']]
        names[node['name']] = {'mesh': mesh['name'], 'prims': len(prims), 'moved': moved,
                               'color': 'COLOR_0' in prims[0]['attributes'],
                               'tris': sum(acc[p['indices']]['count'] // 3 for p in prims),
                               'min': [round(-pos['max'][0], 3), round(pos['min'][1], 3), round(-pos['max'][2], 3)],
                               'max': [round(-pos['min'][0], 3), round(pos['max'][1], 3), round(-pos['min'][2], 3)]}
    ok = True
    for part, st in info['parts'].items():
        g = names.get(part)
        same = g and g['mesh'] == part and g['prims'] == 1 and g['color'] and not g['moved'] and g['tris'] == st['tris'] \
            and all(abs(g['min'][i] - st['min'][i]) < 0.002 and abs(g['max'][i] - st['max'][i]) < 0.002 for i in range(3))
        if not same:
            ok = False
            print('MISMATCH', name, part, g, st)
    print('CHECKED', name, 'ok' if ok else 'BAD', sorted(names))
    return ok


# ------------------------------------------------------------------------------------------------ QA renders
def to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def load(name, turn=True):
    """Imports an exported weapon for a picture: colours made linear (the file holds sRGB numbers raw, which
    Roblox shows as they are), and turned blade up."""
    before = set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.join(OUT, name + '.glb'))
    objs = [o for o in bpy.context.scene.objects if o not in before and o.type == 'MESH']
    neon = report.get(name, {}).get('neon', {})
    for o in objs:
        me = o.data
        tint = neon.get(o.name.split('.')[0])
        for attr in me.color_attributes:
            for d in attr.data:
                c = d.color
                if tint:
                    c = [c[i] * int(tint[i * 2:i * 2 + 2], 16) / 255 for i in range(3)]
                d.color = (to_linear(c[0]), to_linear(c[1]), to_linear(c[2]), 1.0)
        if me.color_attributes:
            me.color_attributes.active_color = me.color_attributes[0]
        if turn:
            o.matrix_world = Matrix.Rotation(math.pi, 4, 'X') @ o.matrix_world
    return objs


def bounds(objs):
    lo, hi = Vector((1e9,) * 3), Vector((-1e9,) * 3)
    for o in objs:
        for c in o.bound_box:
            w = o.matrix_world @ Vector(c)
            lo, hi = Vector(map(min, lo, w)), Vector(map(max, hi, w))
    return lo, hi


def setup_scene():
    sc = bpy.context.scene
    sc.render.engine = 'BLENDER_WORKBENCH'
    sh = sc.display.shading
    sh.light, sh.color_type = 'STUDIO', 'VERTEX'
    sh.show_cavity, sh.show_specular_highlight, sh.show_shadows = True, True, False
    try:
        sh.cavity_type = 'BOTH'
    except Exception:
        pass
    sc.view_settings.view_transform = 'Standard'
    world = bpy.data.worlds.new('w')
    world.color = (0.16, 0.17, 0.2)
    sc.world = world
    try:
        sh.background_type = 'WORLD'
    except Exception:
        pass
    cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam'))
    cam.data.type = 'ORTHO'
    sc.collection.objects.link(cam)
    sc.camera = cam
    return sc, cam


def shoot(sc, cam, lo, hi, direction, size, path):
    mid = (lo + hi) / 2
    d = Vector(direction).normalized()
    cam.location = mid + d * 40
    cam.rotation_euler = (-d).to_track_quat('-Z', 'Y').to_euler()
    bpy.context.view_layer.update()
    right, up = cam.matrix_world.to_3x3() @ Vector((1, 0, 0)), cam.matrix_world.to_3x3() @ Vector((0, 1, 0))
    corners = [Vector((x, y, z)) - mid for x in (lo.x, hi.x) for y in (lo.y, hi.y) for z in (lo.z, hi.z)]
    width = 2 * max(abs(c.dot(right)) for c in corners)
    height = 2 * max(abs(c.dot(up)) for c in corners)
    m = max(size)
    cam.data.ortho_scale = max(width * m / size[0], height * m / size[1]) * 1.1
    sc.render.resolution_x, sc.render.resolution_y = size
    sc.render.resolution_percentage = 100
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)


def sheet(paths, out):
    import numpy as np
    tiles = []
    for p in paths:
        img = bpy.data.images.load(p)
        w, h = img.size
        tiles.append(np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4))
        bpy.data.images.remove(img)
        os.remove(p)
    full = np.concatenate(tiles, axis=1)
    img = bpy.data.images.new('sheet', full.shape[1], full.shape[0], alpha=True)
    img.pixels = full.ravel().tolist()
    img.filepath_raw, img.file_format = out, 'PNG'
    img.save()
    bpy.data.images.remove(img)


VIEWS = [(1, 0, 0.0), (0.8, -0.6, 0.3), (-0.75, -0.6, 0.3), (0, -1, 0.0)]  # flat side, two three-quarters, edge on


def render_weapon(name, size):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc, cam = setup_scene()
    lo, hi = bounds(load(name))
    paths = []
    for i, v in enumerate(VIEWS):
        paths.append(os.path.join(QA, '%s_%d.png' % (name, i)))
        shoot(sc, cam, lo, hi, v, size, paths[-1])
    sheet(paths, os.path.join(QA, name + '.png'))


def render_lineup(names):
    """All of them blade up beside a five-stud figure, the grip at the height of its hand."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc, cam = setup_scene()
    bm = bmesh.new()
    col = bm.loops.layers.float_color.new('Col')
    grey = (0.32, 0.33, 0.37, 1)
    for (x0, y0, z0), (x1, y1, z1) in [((-0.5, -1.0, 0), (0.5, -0.05, 2)), ((-0.5, 0.05, 0), (0.5, 1.0, 2)),
                                       ((-0.5, -1.0, 2), (0.5, 1.0, 4)), ((-0.6, -0.6, 4), (0.6, 0.6, 5)),
                                       ((-0.5, -1.5, 2.05), (0.5, -1.02, 4)), ((-0.5, 1.02, 2.05), (0.5, 1.5, 4))]:
        vs = [bm.verts.new((x, y, z)) for z in (z0, z1) for x, y in ((x0, y0), (x1, y0), (x1, y1), (x0, y1))]
        for q in ((3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)):
            f = bm.faces.new([vs[i] for i in q])
            for loop in f.loops:
                loop[col] = grey
    me = bpy.data.meshes.new('Figure')
    bm.to_mesh(me)
    bm.free()
    figure = bpy.data.objects.new('Figure', me)
    sc.collection.objects.link(figure)
    everything = [figure]
    y = 2.2
    for name in names:
        objs = load(name)
        lo, hi = bounds(objs)
        y += -lo.y + 0.35
        for o in objs:
            o.matrix_world = Matrix.Translation((0, y, 2.1)) @ o.matrix_world
        y += hi.y + 0.35
        everything += objs
    lo, hi = bounds(everything)
    shoot(sc, cam, lo, hi, (1, -0.25, 0.12), (1500, 900), os.path.join(QA, 'lineup.png'))


names = [n for n in ORDER if not ONLY or n in ONLY]
json_path = os.path.join(OUT, 'melee.json')
report = {}
if os.path.exists(json_path):
    with open(json_path) as f:
        report = json.load(f)
for name in names:
    report[name] = export(name)
    check_glb(name, report[name])
with open(json_path, 'w') as f:
    json.dump(report, f, indent=1)
if RENDER:
    for name in names:
        render_weapon(name, (360, 760))
    if all(os.path.exists(os.path.join(OUT, n + '.glb')) for n in ORDER):
        render_lineup(ORDER)
print('DONE', names)
