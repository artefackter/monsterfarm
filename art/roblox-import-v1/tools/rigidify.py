# Skinned GLB -> rigid GLB for the game's part-based monsters.
# The game animates a monster as rigid groups (Body, Head, ArmL, ArmR, LegL, LegR, TendrilL, TendrilR) turned about
# one pivot each (ZombieVisuals / MutantAnimation). This bakes the skinned mesh in its idle pose, splits it by each
# vertex's strongest bone into those groups, converts the vertex colours to sRGB (Roblox shows COLOR_0 raw) and writes
# a static GLB plus a JSON with the groups' pivots, the bounds and triangle counts, all in glTF space (Y up).
# Usage: blender --background --factory-startup --python rigidify.py -- <jobs.json>
#   jobs.json: [{"src": "...glb", "dst": "...glb", "meta": "...json", "name": "GrannyFarmer"}, ...]
import bpy, bmesh, sys, json, re, math
from mathutils import Vector

ARG = sys.argv[sys.argv.index('--') + 1:]
JOBS = json.load(open(ARG[0], encoding='utf-8-sig'))

SIDE = re.compile(r'^(.*?)[._]?([LR])(\d*)$')


def parse(name):
    m = SIDE.match(name)
    if not m:
        return name, None, None
    return m.group(1), m.group(2), int(m.group(3)) if m.group(3) else None


def group_roots(bones):
    """bone name -> group name for the bones that start a group; the rest inherit from their parent."""
    roots = {}
    multi = {}  # numbered legs per base: base -> {side: [idx]}
    for b in bones:
        base, side, idx = parse(b.name)
        if side and idx is not None and base in ('Leg', 'Coxa'):
            multi.setdefault(base, {}).setdefault(side, []).append(idx)
    names = {b.name for b in bones}
    for b in bones:
        base, side, idx = parse(b.name)
        if side and base in ('Arm', 'UpperArm', 'FrontUpper') and idx is None:
            roots[b.name] = 'Arm' + side
        elif side and base in ('Leg', 'Thigh', 'HindThigh') and idx is None:
            roots[b.name] = 'Leg' + side
        elif side and idx is not None and base in ('Leg', 'Coxa'):
            ids = sorted(multi[base][side])
            if idx == ids[0]:
                roots[b.name] = 'Arm' + side  # the front pair swings like arms
            elif idx == ids[-1]:
                roots[b.name] = 'Leg' + side
        elif side and base == 'Tendril' and idx is None:
            roots[b.name] = 'Tendril' + side
        elif b.name == 'Neck' or (b.name == 'Head' and 'Neck' not in names) or b.name == 'LowerJaw':
            roots[b.name] = 'Head'
    return roots


def to_gltf(v):  # Blender Z up -> glTF Y up
    return [v.x, v.z, -v.y]


def srgb(c):
    c = max(0.0, min(1.0, c))
    return c * 12.92 if c <= 0.0031308 else 1.055 * (c ** (1 / 2.4)) - 0.055


def run(job):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=job['src'])
    scene = bpy.context.scene
    arm = next((o for o in scene.objects if o.type == 'ARMATURE'), None)
    shapes = {pb.custom_shape for pb in arm.pose.bones if pb.custom_shape} if arm else set()
    # only what the skin drives (the importer adds a bone display shape as a mesh too)
    meshes = [o for o in scene.objects if o.type == 'MESH' and o not in shapes and (not arm or o.find_armature() == arm or o.parent == arm)]
    print('MESHES', [o.name for o in meshes], 'SKIPPED', [o.name for o in scene.objects if o.type == 'MESH' and o not in meshes])
    pose = 'rest'
    if arm:
        idle = next((a for a in bpy.data.actions if 'idle' in a.name.lower()), None)
        ad = arm.animation_data or arm.animation_data_create()
        for t in ad.nla_tracks:
            t.mute = True
        if idle:
            ad.action = idle
            if hasattr(ad, 'action_slot') and getattr(idle, 'slots', None):
                ad.action_slot = idle.slots[0]
            scene.frame_set(int(idle.frame_range[0]))
            pose = idle.name
        else:
            ad.action = None
            for pb in arm.pose.bones:
                pb.matrix_basis.identity()
            scene.frame_set(0)
    bpy.context.view_layer.update()
    bones = arm.data.bones if arm else []
    roots = group_roots(bones)

    def group_of(name):
        b = arm.data.bones.get(name) if arm else None
        while b:
            if b.name in roots:
                return roots[b.name]
            b = b.parent
        return 'Body'

    # pivots: the posed heads of each group's root bones
    pivots = {}
    if arm:
        for name, g in roots.items():
            pivots.setdefault(g, []).append(arm.matrix_world @ arm.pose.bones[name].head)
    pivots = {g: to_gltf(sum(v, Vector()) / len(v)) for g, v in pivots.items()}

    depsgraph = bpy.context.evaluated_depsgraph_get()
    out = {}  # (group, textured) -> bmesh
    mats = {}
    for o in meshes:
        vg_group = {vg.index: group_of(vg.name) for vg in o.vertex_groups}
        src = o.data
        vert_group = []
        for v in src.vertices:
            best, w = None, -1
            for ge in v.groups:
                if ge.weight > w and ge.group in vg_group:
                    best, w = vg_group[ge.group], ge.weight
            vert_group.append(best or 'Body')
        ev = o.evaluated_get(depsgraph)
        me = bpy.data.meshes.new_from_object(ev, preserve_all_data_layers=True, depsgraph=depsgraph)
        me.transform(o.matrix_world)
        textured = any(m and m.use_nodes and any(n.type == 'TEX_IMAGE' for n in m.node_tree.nodes) for m in src.materials)
        for g in set(vert_group):
            bm = bmesh.new()
            bm.from_mesh(me)
            bm.verts.ensure_lookup_table()
            gone = []
            for f in bm.faces:
                votes = {}
                for v in f.verts:
                    k = vert_group[v.index]
                    votes[k] = votes.get(k, 0) + 1
                if max(votes, key=lambda k: (votes[k], k == vert_group[f.verts[0].index])) != g:
                    gone.append(f)
            bmesh.ops.delete(bm, geom=gone, context='FACES')
            loose = [v for v in bm.verts if not v.link_faces]
            bmesh.ops.delete(bm, geom=loose, context='VERTS')
            if len(bm.faces) == 0:
                bm.free()
                continue
            key = (g, textured)
            if key in out:
                tmp = bpy.data.meshes.new('tmp')
                bm.to_mesh(tmp)
                bm.free()
                out[key].from_mesh(tmp)
            else:
                out[key] = bm
                mats[key] = list(src.materials)
        bpy.data.meshes.remove(me)

    # drop everything imported; build the groups as plain objects
    for o in list(scene.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    report = {'name': job['name'], 'pose': pose, 'groups': {}, 'pivots': pivots}
    lo, hi = Vector((1e9, 1e9, 1e9)), Vector((-1e9, -1e9, -1e9))
    for (g, textured), bm in out.items():
        name = g + ('Face' if textured else '')
        me = bpy.data.meshes.new(name)
        bm.to_mesh(me)
        bm.free()
        for m in mats[(g, textured)]:
            me.materials.append(m)
        # vertex colours: store sRGB numbers in a float attribute so the exporter writes them as they are
        for attr in list(me.color_attributes):
            vals = [tuple(d.color) for d in attr.data]
            dom, aname = attr.domain, attr.name
            me.color_attributes.remove(attr)
            na = me.color_attributes.new(aname, 'FLOAT_COLOR', dom)
            for d, c in zip(na.data, vals):
                d.color = (srgb(c[0]), srgb(c[1]), srgb(c[2]), c[3])
        if me.color_attributes:
            me.color_attributes.active_color = me.color_attributes[0]
            me.color_attributes.render_color_index = 0
        ob = bpy.data.objects.new(name, me)
        scene.collection.objects.link(ob)
        tris = sum(len(p.vertices) - 2 for p in me.polygons)
        for v in me.vertices:
            lo = Vector(map(min, lo, v.co))
            hi = Vector(map(max, hi, v.co))
        report['groups'][name] = {'tris': tris, 'textured': textured}
    report['bounds'] = [[lo.x, lo.z, -hi.y], [hi.x, hi.z, -lo.y]]
    kw = dict(filepath=job['dst'], export_format='GLB', use_selection=False, export_skins=False,
              export_animations=False, export_yup=True, export_apply=True, export_materials='EXPORT')
    try:
        bpy.ops.export_scene.gltf(**kw, export_vertex_color='ACTIVE')
    except TypeError:
        bpy.ops.export_scene.gltf(**kw, export_colors=True)
    json.dump(report, open(job['meta'], 'w', encoding='utf-8'), indent=1)
    print('DONE', job['name'], pose, {k: v['tris'] for k, v in report['groups'].items()})


for job in JOBS:
    try:
        run(job)
    except Exception as e:
        import traceback
        traceback.print_exc()
        print('FAIL', job['name'], e)
