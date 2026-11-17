"""Procedural cartoon modelling kit for Dig a Zombie.

Authoring space: Blender metres = Roblox studs, Z up, characters face -Y.
One Part becomes one Roblox MeshPart. Colours are baked per vertex (with soft AO and a
top-light gradient); parts flagged with `tint` stay white so Luau can recolour them.
"""
import bpy, bmesh, json, math, os, random
from mathutils import Vector, Matrix, Euler, noise
from mathutils.bvhtree import BVHTree

ASSETS = {}


def asset(name):
    a = Asset(name)
    ASSETS[name] = a
    return a


def _rgb(h):
    h = h.lstrip("#")
    return (int(h[0:2], 16) / 255, int(h[2:4], 16) / 255, int(h[4:6], 16) / 255)


def _mat(c=(0, 0, 0), rot=(0, 0, 0), scale=None):
    m = Matrix.Translation(Vector(c)) @ Euler(tuple(math.radians(x) for x in rot), "XYZ").to_matrix().to_4x4()
    if scale is not None:
        s = scale if hasattr(scale, "__len__") else (scale, scale, scale)
        m = m @ Matrix.Diagonal((s[0], s[1], s[2], 1))
    return m


class Asset:
    def __init__(self, name):
        self.name, self.parts = name, []

    def part(self, name=None, **meta):
        p = Part(name or "Main", self, **meta)
        self.parts.append(p)
        return p


class Part:
    def __init__(self, name, owner, tint=None, attach=None, material="SmoothPlastic", transparency=0.0,
                 ao=0.75, ao_dist=1.1, grad=0.12, collide=False, cast=True):
        self.name, self.owner, self.tint, self.attach = name, owner, tint, attach
        self.material, self.transparency = material, transparency
        self.ao, self.ao_dist, self.grad, self.collide, self.cast = ao, ao_dist, grad, collide, cast
        self.bm = bmesh.new()
        self.layer = self.bm.faces.layers.int.new("c")
        self.colors = []
        self.colfn = None

    def _cid(self, h):
        if h not in self.colors:
            self.colors.append(h)
        return self.colors.index(h)

    def _merge(self, t, M, col, smooth=True):
        bmesh.ops.transform(t, matrix=M, verts=t.verts)
        me = bpy.data.meshes.new("_t")
        t.to_mesh(me)
        t.free()
        n0 = len(self.bm.faces)
        self.bm.from_mesh(me)
        bpy.data.meshes.remove(me)
        self.bm.faces.ensure_lookup_table()
        n = len(self.bm.faces) - n0
        for i in range(n):
            f = self.bm.faces[n0 + i]
            f[self.layer] = self._cid(col[i] if isinstance(col, (list, tuple)) else col)
            f.smooth = smooth
        return self

    # ---- primitives ------------------------------------------------------------------
    def sphere(self, c, r, col, rot=(0, 0, 0), sub=3, smooth=True):
        t = bmesh.new()
        s = r if hasattr(r, "__len__") else (r, r, r)
        big = max(s)
        sub = 1 if big < 0.1 else min(sub, 2) if big < 0.5 else sub
        bmesh.ops.create_icosphere(t, subdivisions=sub, radius=1.0)
        return self._merge(t, _mat(c, rot, s), col, smooth)

    def box(self, c, s, col, rot=(0, 0, 0), bevel=0.08, seg=2, taper=None, smooth=True):
        t = bmesh.new()
        seg = 1 if min(s) < 0.2 else seg
        bmesh.ops.create_cube(t, size=1.0)
        for v in t.verts:
            k = 1.0
            if taper is not None and v.co.z > 0:
                k = taper
            v.co = Vector((v.co.x * s[0] * k, v.co.y * s[1] * k, v.co.z * s[2]))
        if bevel > 0:
            bmesh.ops.bevel(t, geom=list(t.verts) + list(t.edges), offset=min(bevel, min(s) * 0.49),
                            segments=seg, profile=0.5, affect="EDGES", clamp_overlap=True)
        return self._merge(t, _mat(c, rot), col, smooth)

    def cyl(self, c, r1, r2, h, col, rot=(0, 0, 0), seg=14, bevel=0.0, smooth=True):
        t = bmesh.new()
        bmesh.ops.create_cone(t, cap_ends=True, cap_tris=False, segments=seg, radius1=r1, radius2=r2, depth=h)
        if bevel > 0:
            ring = [e for e in t.edges if len(e.link_faces) == 2
                    and abs(e.link_faces[0].normal.dot(e.link_faces[1].normal)) < 0.8]
            bmesh.ops.bevel(t, geom=ring, offset=bevel, segments=2, profile=0.5, affect="EDGES", clamp_overlap=True)
        return self._merge(t, _mat(c, rot), col, smooth)

    def loft(self, rings, col, c=(0, 0, 0), rot=(0, 0, 0), cap_start=True, cap_end=True, smooth=True, wrap=True):
        """Connect rings of equal length. `col` is a colour, or fn(ring_index) -> colour."""
        t = bmesh.new()
        grid = [[t.verts.new(Vector(p)) for p in r] for r in rings]
        cols = []
        for i in range(len(grid) - 1):
            a, b = grid[i], grid[i + 1]
            n = len(a)
            for j in range(n if wrap else n - 1):
                k = (j + 1) % n
                t.faces.new((a[j], a[k], b[k], b[j]))
                cols.append(col(i) if callable(col) else col)
        if cap_start and wrap:
            t.faces.new(list(reversed(grid[0])))
            cols.append(col(0) if callable(col) else col)
        if cap_end and wrap:
            t.faces.new(grid[-1])
            cols.append(col(len(grid) - 2) if callable(col) else col)
        bmesh.ops.recalc_face_normals(t, faces=t.faces)
        return self._merge(t, _mat(c, rot), cols, smooth)

    def lathe(self, profile, col, c=(0, 0, 0), rot=(0, 0, 0), seg=18, rfn=None, zfn=None, smooth=True, caps=False):
        """Revolve [(radius, z), ...] around Z. Optional rfn(theta, i) / zfn(theta, i) add wobble."""
        rings = []
        for i, (r, z) in enumerate(profile):
            ring = []
            for j in range(seg):
                a = j / seg * math.tau
                rr = max(r, 0.0005) * (rfn(a, i) if rfn else 1.0)
                zz = z + (zfn(a, i) if zfn else 0.0)
                ring.append((math.cos(a) * rr, math.sin(a) * rr, zz))
            rings.append(ring)
        return self.loft(rings, col, c, rot, smooth=smooth, cap_start=caps, cap_end=caps)

    def tube(self, pts, col, seg=8, sub=3, smooth=True, cap=True, c=(0, 0, 0), rot=(0, 0, 0)):
        """Sweep a circle along a Catmull-Rom path of (x, y, z, radius). `col` may be fn(i)."""
        P = [Vector(p) for p in pts]
        path = []
        for i in range(len(P) - 1):
            p0, p1, p2, p3 = P[max(i - 1, 0)], P[i], P[i + 1], P[min(i + 2, len(P) - 1)]
            for s in range(sub):
                u = s / sub
                path.append(0.5 * ((2 * p1) + (-p0 + p2) * u + (2 * p0 - 5 * p1 + 4 * p2 - p3) * u * u
                                   + (-p0 + 3 * p1 - 3 * p2 + p3) * u * u * u))
        path.append(P[-1])
        up, rings = Vector((0.0123, 0.0071, 1.0)), []
        prev_n = None
        for i, q in enumerate(path):
            tan = (Vector(path[min(i + 1, len(path) - 1)][:3]) - Vector(path[max(i - 1, 0)][:3])).normalized()
            n = (prev_n - tan * prev_n.dot(tan)) if prev_n is not None else up.cross(tan)
            if n.length < 1e-5:
                n = Vector((1, 0, 0)).cross(tan)
            n.normalize()
            prev_n = n
            b = tan.cross(n)
            ring = []
            for j in range(seg):
                a = j / seg * math.tau
                ring.append(Vector(q[:3]) + (n * math.cos(a) + b * math.sin(a)) * q[3])
            rings.append(ring)
        return self.loft(rings, col, c, rot, cap_start=cap, cap_end=cap, smooth=smooth)

    def torus(self, c, R, r, col, rot=(0, 0, 0), seg=24, rseg=8):
        pts = []
        for j in range(seg):
            a = j / seg * math.tau
            ring = []
            for i in range(rseg):
                b = i / rseg * math.tau
                d = R + r * math.cos(b)
                ring.append((math.cos(a) * d, math.sin(a) * d, r * math.sin(b)))
            pts.append(ring)
        pts.append(pts[0])
        return self.loft(pts, col, c, rot, cap_start=False, cap_end=False)

    def prism(self, poly, depth, col, c=(0, 0, 0), rot=(0, 0, 0), bevel=0.04, seg=1, smooth=True):
        """Extrude an XZ polygon (counter-clockwise seen from -Y) along Y."""
        t = bmesh.new()
        front = [t.verts.new((x, -depth / 2, z)) for x, z in poly]
        back = [t.verts.new((x, depth / 2, z)) for x, z in poly]
        t.faces.new(list(reversed(front)) if _area(poly) > 0 else front)
        t.faces.new(back if _area(poly) > 0 else list(reversed(back)))
        n = len(poly)
        for i in range(n):
            j = (i + 1) % n
            f = t.faces.new((front[i], front[j], back[j], back[i]))
            if _area(poly) < 0:
                f.normal_flip()
        bmesh.ops.recalc_face_normals(t, faces=t.faces)
        if bevel > 0:
            edges = [e for e in t.edges if len(e.link_faces) == 2
                     and e.link_faces[0].normal.dot(e.link_faces[1].normal) < 0.5]
            if edges:
                bmesh.ops.bevel(t, geom=edges, offset=bevel, segments=seg, profile=0.5, affect="EDGES", clamp_overlap=True)
        bmesh.ops.triangulate(t, faces=[f for f in t.faces if len(f.verts) > 4], ngon_method="BEAUTY")
        return self._merge(t, _mat(c, rot), col, smooth)

    # ---- modifiers -------------------------------------------------------------------
    def wonk(self, amp=0.05, scale=1.2, seed=0.0, only_above=None):
        """Low-frequency displacement: breaks CAD-perfect shapes so everything feels hand-made."""
        off = Vector((seed * 13.7, seed * 7.3, seed * 3.1))
        for v in self.bm.verts:
            if only_above is not None and v.co.z < only_above:
                continue
            p = v.co * scale + off
            v.co += Vector((noise.noise(p), noise.noise(p + Vector((31, 7, 11))), noise.noise(p + Vector((5, 53, 19))))) * amp
        return self

    def color_fn(self, fn):
        """fn(position, base_rgb) -> rgb. Lets a part blend colours per vertex (grass patches etc)."""
        self.colfn = fn
        return self


def _area(poly):
    return sum(poly[i][0] * poly[(i + 1) % len(poly)][1] - poly[(i + 1) % len(poly)][0] * poly[i][1]
               for i in range(len(poly))) / 2


def arc(cx, cz, rx, rz, a0, a1, n):
    return [(cx + math.cos(math.radians(a0 + (a1 - a0) * i / n)) * rx,
             cz + math.sin(math.radians(a0 + (a1 - a0) * i / n)) * rz) for i in range(n + 1)]


def star_poly(R, r, n=5, rot=90):
    return [((R if i % 2 == 0 else r) * math.cos(math.radians(rot + i * 180 / n)),
             (R if i % 2 == 0 else r) * math.sin(math.radians(rot + i * 180 / n))) for i in range(n * 2)]


# ---- baking ----------------------------------------------------------------------------
_HEMI = []
for _i in range(18):  # fibonacci hemisphere
    _z = (_i + 0.5) / 18
    _a = _i * 2.399963
    _s = math.sqrt(max(0, 1 - _z * _z))
    _HEMI.append(Vector((math.cos(_a) * _s, math.sin(_a) * _s, _z)))
_AO_TINT = (0.60, 0.52, 0.74)  # shadows lean violet: stays colourful instead of going grey


def _asset_bvh(a):
    V, F = [], []
    for p in a.parts:
        if p.transparency > 0.3:
            continue
        b = p.bm.copy()
        bmesh.ops.triangulate(b, faces=b.faces)
        o = len(V)
        V += [v.co.copy() for v in b.verts]
        b.verts.index_update()
        F += [tuple(o + v.index for v in f.verts) for f in b.faces]
        b.free()
    return BVHTree.FromPolygons(V, F, all_triangles=True) if F else None


def _occlusion(bvh, co, nrm, dist):
    t = nrm.orthogonal().normalized()
    b = nrm.cross(t)
    occ = 0.0
    o = co + nrm * 0.015
    for d in _HEMI:
        w = t * d.x + b * d.y + nrm * d.z
        hit = bvh.ray_cast(o, w, dist)
        if hit[0] is not None:
            occ += 1.0 - min(hit[3] / dist, 1.0) * 0.6
    return min(1.0, occ / len(_HEMI) * 1.5)


def bake_part(p, bvh):
    bm = p.bm
    for e in bm.edges:
        if len(e.link_faces) == 2 and e.calc_face_angle(0.0) > math.radians(52):
            e.smooth = False
    me = bpy.data.meshes.new(p.name)
    bm.to_mesh(me)
    me.calc_loop_triangles()
    if not me.loop_triangles:
        raise RuntimeError(f"{p.owner.name}/{p.name} has no geometry")
    normals = me.corner_normals
    attr = me.attributes["c"].data
    zs = [v.co.z for v in me.vertices]
    zmin, zmax = min(zs), max(zs)
    zr = max(zmax - zmin, 1e-3)
    rgb = [(1, 1, 1) if p.tint else _rgb(h) for h in p.colors]
    index, verts, norms, cols, tris = {}, [], [], [], []
    ao_cache = {}
    for tri in me.loop_triangles:
        cid = attr[tri.polygon_index].value
        for li in tri.loops:
            vi = me.loops[li].vertex_index
            co = me.vertices[vi].co
            n = normals[li].vector
            key = (vi, round(n.x, 2), round(n.y, 2), round(n.z, 2), cid)
            if key not in index:
                c = rgb[cid]
                if p.colfn:
                    c = p.colfn(co, c)
                g = 1 + p.grad * ((co.z - zmin) / zr - 0.5) * 2
                c = (c[0] * g, c[1] * g, c[2] * g)
                if p.ao > 0 and bvh is not None:
                    k2 = key[:4]
                    if k2 not in ao_cache:
                        ao_cache[k2] = _occlusion(bvh, co, n.normalized(), p.ao_dist)
                    a = ao_cache[k2] * p.ao
                    c = tuple(c[i] * (1 - a + a * _AO_TINT[i]) for i in range(3))
                index[key] = len(verts)
                verts.append(co.copy())
                norms.append(n.copy())
                cols.append(tuple(min(1.0, max(0.0, x)) for x in c))
            tris.append(index[key])
    bpy.data.meshes.remove(me)
    return verts, norms, cols, tris


def to_rbx(v):
    """Blender (x, y, z), face -Y  ->  Roblox (-x, z, y), face -Z. A proper rotation: winding is kept."""
    return (-v[0], v[2], v[1])


def export_all(out_dir, only=None):
    os.makedirs(out_dir, exist_ok=True)
    manifest, baked, total = {}, {}, 0
    for name, a in ASSETS.items():
        if only and name not in only:
            continue
        bvh = _asset_bvh(a)
        entry = []
        for p in a.parts:
            verts, norms, cols, tris = bake_part(p, bvh)
            baked[(name, p.name)] = (verts, cols, tris)
            R = [to_rbx(v) for v in verts]
            lo = [min(r[i] for r in R) for i in range(3)]
            hi = [max(r[i] for r in R) for i in range(3)]
            mid = [(lo[i] + hi[i]) / 2 for i in range(3)]
            size = [max(hi[i] - lo[i], 0.05) for i in range(3)]
            # Tiny bevel corners can collapse at the established 0.001-stud export
            # precision. Remove only zero-area faces in the actual exported mesh.
            rounded = [Vector(tuple(round(r[i] - mid[i], 3) for i in range(3))) for r in R]
            clean = []
            for j in range(0, len(tris), 3):
                ia, ib, ic = tris[j:j+3]
                if (rounded[ib]-rounded[ia]).cross(rounded[ic]-rounded[ia]).length_squared > 1e-16:
                    clean.extend((ia, ib, ic))
            tris = clean
            baked[(name, p.name)] = (verts, cols, tris)
            mesh_key = f"{name}.{p.name}"
            data = {
                "name": mesh_key,
                "v": [round(x - mid[i], 3) for r in R for i, x in enumerate(r)],
                "n": [round(x, 3) for n in norms for x in to_rbx(n)],
                "c": [(int(c[0] * 255) << 16) + (int(c[1] * 255) << 8) + int(c[2] * 255) for c in cols],
                "t": tris,
            }
            with open(os.path.join(out_dir, mesh_key + ".json"), "w") as f:
                json.dump(data, f, separators=(",", ":"))
            total += len(tris) // 3
            entry.append({"part": p.name, "mesh": mesh_key, "offset": [round(x, 3) for x in mid],
                          "size": [round(x, 3) for x in size], "tint": p.tint, "attach": p.attach,
                          "material": p.material, "transparency": p.transparency,
                          "collide": p.collide, "cast": p.cast, "tris": len(tris) // 3})
        manifest[name] = entry
    return manifest, baked, total


# ---- preview rendering -----------------------------------------------------------------
TINTS = {"skin": "9BE36B", "outfit": "FFFFFF", "rarity": "5BD16B"}


def _preview_material(tr):
    m = bpy.data.materials.new("pv")
    m.use_nodes = True
    n = m.node_tree.nodes
    pb = n.get("Principled BSDF")
    at = n.new("ShaderNodeVertexColor")
    at.layer_name = "Col"
    m.node_tree.links.new(at.outputs["Color"], pb.inputs["Base Color"])
    pb.inputs["Roughness"].default_value = 0.5
    if tr > 0:
        pb.inputs["Alpha"].default_value = 1 - tr
        pb.inputs["Roughness"].default_value = 0.08
    return m


def spawn_preview(baked, name, part_meta, offset, scale=1.0, tints=None, rot_z=0):
    tints = tints or {}
    M = Matrix.Translation(Vector(offset)) @ Matrix.Rotation(math.radians(rot_z), 4, "Z") @ Matrix.Scale(scale, 4)
    for meta in part_meta:
        verts, cols, tris = baked[(name, meta["part"])]
        me = bpy.data.meshes.new(meta["part"])
        me.from_pydata([v[:] for v in verts], [], [tuple(tris[i:i + 3]) for i in range(0, len(tris), 3)])
        me.update()
        ca = me.color_attributes.new("Col", "BYTE_COLOR", "POINT")
        tint = tints.get(meta["part"]) or TINTS.get(meta["tint"] or "", "FFFFFF")
        tr = _rgb(tint)
        for i, c in enumerate(cols):
            ca.data[i].color_srgb = (c[0] * tr[0], c[1] * tr[1], c[2] * tr[2], 1)
        me.shade_smooth()
        ob = bpy.data.objects.new(meta["part"], me)
        ob.matrix_world = M
        me.materials.append(_preview_material(meta["transparency"]))
        bpy.context.scene.collection.objects.link(ob)


def setup_render(path, cam_pos, cam_look, res=(1500, 1000), lens=60, samples=48, bg="9ED8FF"):
    s = bpy.context.scene
    s.render.engine = "CYCLES"
    s.cycles.samples = samples
    s.cycles.device = "CPU"
    s.cycles.use_denoising = False
    s.render.resolution_x, s.render.resolution_y = res
    s.render.filepath = path
    s.view_settings.view_transform = "Standard"
    s.view_settings.look = "None"
    w = bpy.data.worlds.new("w")
    w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[0].default_value = (*[x ** 2.2 for x in _rgb(bg)], 1)
    w.node_tree.nodes["Background"].inputs[1].default_value = 0.85
    s.world = w
    sun = bpy.data.lights.new("sun", "SUN")
    sun.energy = 2.6
    sun.angle = math.radians(14)
    so = bpy.data.objects.new("sun", sun)
    so.rotation_euler = (math.radians(52), math.radians(8), math.radians(-32))
    s.collection.objects.link(so)
    cam = bpy.data.cameras.new("cam")
    cam.lens = lens
    co = bpy.data.objects.new("cam", cam)
    co.location = cam_pos
    d = Vector(cam_look) - Vector(cam_pos)
    co.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    s.collection.objects.link(co)
    s.camera = co
