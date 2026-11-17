# Skeletons for the four bosses that were modelled as rigid pieces (owner, 2026-11-15: "make skeletons for the other
# four bosses"): the Chief Physician, the RingMaw, the Parasite and the Cave Dweller. None of them has a skinned
# source, so this builds one: the pieces are put together where the game puts them, joined into one mesh, and bound to
# an armature whose bones stand on the game's own joint points (MonsterRig), with an elbow and a knee found in each
# limb and the weights blended across them. The bone names are the ones MutantAnimation looks for:
#   Root, Spine, Head, ArmL/ForearmL, ArmR/ForearmR, LegL/ShinL, LegR/ShinR (and TendrilL/TendrilR on the Parasite)
# Glowing pieces (the Cave Dweller's face, the Parasite's eyes) stay a second mesh, "<Name>_Glow", on the Head bone,
# so Studio can make them Neon. Vertex colours are written as sRGB numbers (Roblox shows COLOR_0 raw).
# Sources:
#   json   art/export/collection-v2/release-v1/monsters/<Asset>.<Part>.json (v, n, c, t; each piece about its own
#          middle) placed by the offsets of shared/ArtManifestRelease
#   glb    art/monster-review-v2/models/<Name>_Proposed.glb (the reviewed RingMaw and Parasite: pieces in place)
# Usage: blender --background --factory-startup --python rig_bosses.py -- <repo> <out dir> [<qa dir>] [name ...]
import bpy, sys, os, json, math
from mathutils import Vector

args = sys.argv[sys.argv.index('--') + 1:]
repo, out = args[0], args[1]
qa = args[2] if len(args) > 2 and args[2] != '-' else None
only = args[3:]
REL = 'art/export/collection-v2/release-v1/monsters'
LIMBS = {'ArmL': 'ForearmL', 'ArmR': 'ForearmR', 'LegL': 'ShinL', 'LegR': 'ShinR'}

BOSSES = {
    'DeerChief_Skinned': dict(
        json=REL, asset='Deer_Chief_Aggressive',
        parts=[('Body', (0.0, 3.831, -0.143), 'Body'), ('LegR', (0.63, 1.578, -0.13), 'LegR'), ('LegL', (-0.612, 1.579, -0.116), 'LegL'),
               ('ArmR', (1.376, 3.724, -0.72), 'ArmR'), ('HandItem', (1.91, 2.566, -1.448), 'HandR'), ('ArmL', (-1.463, 3.166, -0.669), 'ArmL'),
               ('Head', (-0.108, 6.512, -0.949), 'Head')],
        joints=dict(LegR=(0.44, 2.91, 0.07), LegL=(-0.44, 2.91, 0.07), ArmR=(0.99, 4.46, -0.26), ArmL=(-0.99, 4.46, -0.26), Head=(0, 4.84, -0.43))),
    'CaveDweller_Skinned': dict(
        json=REL, asset='CaveDweller_Aggressive',
        parts=[('Body', (0.0, 3.658, -0.075), 'Body'), ('LegR', (0.352, 1.324, -0.136), 'LegR'), ('LegL', (-0.367, 1.324, -0.039), 'LegL'),
               ('ArmR', (1.135, 2.335, -0.533), 'ArmR'), ('ArmL', (-1.138, 2.391, -0.521), 'ArmL'), ('Head', (0.0, 5.307, -0.321), 'Head'),
               ('FaceGlow', (0.0, 5.415, -0.601), 'Glow')],
        joints=dict(LegR=(0.284, 2.61, 0.025), LegL=(-0.284, 2.61, 0.025), ArmR=(0.66, 4.29, -0.115), ArmL=(-0.66, 4.29, -0.115), Head=(0, 4.59, -0.43))),
    'RingMaw_Skinned': dict(
        glb='art/monster-review-v2/models/RingMaw_Proposed.glb', quad=True,
        groups={'Quadruped_ArmL': 'ArmL', 'Quadruped_ArmR': 'ArmR', 'Quadruped_Body': 'Body', 'Quadruped_LegL': 'LegL', 'Quadruped_LegR': 'LegR'}, default='Head',
        joints=dict(ArmR=(0.57, 2.37, -0.66), ArmL=(-0.57, 2.37, -0.66), LegR=(0.43, 2.08, 1.08), LegL=(-0.43, 2.08, 1.08), Head=(-0.1, 2.61, -1.38))),
    'Parasite_Skinned': dict(
        glb='art/monster-review-v2/models/Parasite_Proposed.glb',
        groups={'ArmL': 'ArmL', 'ArmR': 'ArmR', 'Body': 'Body', 'EyesGlow': 'Glow', 'Head': 'Head', 'LegL': 'LegL', 'LegR': 'LegR', 'TendrilL': 'TendrilL', 'TendrilR': 'TendrilR'},
        joints=dict(LegR=(0.6763, 2.214, 0.06), LegL=(-0.6763, 2.214, 0.06), ArmR=(1.3899, 3.864, 0.03), ArmL=(-1.3899, 3.864, 0.03),
                    TendrilR=(0.791, 3.714, 0.55), TendrilL=(-0.791, 3.714, 0.55), Head=(0, 4.264, -0.05))),
}


def srgb(c):
    c = max(0.0, min(1.0, c))
    return c * 12.92 if c <= 0.0031308 else 1.055 * (c ** (1 / 2.4)) - 0.055


def A(x, y, z):
    # the game's asset space (+Y up, -Z the front, +X the right arm's side) -> Blender (+Z up, -Y the front)
    return Vector((-x, z, y))


def json_part(path, name, offset):
    d = json.load(open(path, encoding='utf-8-sig'))
    v, n, c, t = d['v'], d['n'], d['c'], d['t']
    verts = [A(v[i] + offset[0], v[i + 1] + offset[1], v[i + 2] + offset[2]) for i in range(0, len(v), 3)]
    normals = [A(n[i], n[i + 1], n[i + 2]).normalized() for i in range(0, len(n), 3)]
    faces = [(t[i], t[i + 1], t[i + 2]) for i in range(0, len(t), 3)]
    # the winding that agrees with the stored normals
    agree = 0
    for a, b, cc in faces:
        fn = (verts[b] - verts[a]).cross(verts[cc] - verts[a])
        agree += 1 if fn.dot(normals[a] + normals[b] + normals[cc]) >= 0 else -1
    if agree < 0:
        faces = [(a, cc, b) for a, b, cc in faces]
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    me.update()
    col = me.color_attributes.new('Col', 'FLOAT_COLOR', 'CORNER')
    for li, loop in enumerate(me.loops):
        ci = c[loop.vertex_index]
        col.data[li].color = ((ci >> 16 & 255) / 255, (ci >> 8 & 255) / 255, (ci & 255) / 255, 1)
    me.normals_split_custom_set_from_vertices(normals)
    o = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(o)
    return o, ('flipped' if agree < 0 else 'kept')


def material_colour(mat):
    if mat and mat.node_tree:
        for node in mat.node_tree.nodes:
            if node.type == 'BSDF_PRINCIPLED':
                return tuple(node.inputs['Base Color'].default_value)
    return (0.6, 0.6, 0.6, 1)


def bake_colour(o):
    # one corner colour attribute "Col" of sRGB numbers: from the mesh's own vertex colours, or its materials' colours
    me = o.data
    loops = [None] * len(me.loops)
    if me.color_attributes:
        src = me.color_attributes[0]
        data = [tuple(d.color) for d in src.data]
        for li, loop in enumerate(me.loops):
            loops[li] = data[loop.vertex_index] if src.domain == 'POINT' else data[li]
    else:
        mats = [material_colour(m) for m in me.materials]
        for p in me.polygons:
            for li in p.loop_indices:
                loops[li] = mats[p.material_index] if mats else (0.6, 0.6, 0.6, 1)
    for a in list(me.color_attributes):
        me.color_attributes.remove(a)
    col = me.color_attributes.new('Col', 'FLOAT_COLOR', 'CORNER')
    for li, c in enumerate(loops):
        col.data[li].color = (srgb(c[0]), srgb(c[1]), srgb(c[2]), 1)


def limb(points, pivot, leg, quad):
    # The far end of a limb and where it bends. Its tip is the middle of the vertices furthest from the pivot. Cut
    # across the straight line between them, the limb's slices show how far it stands off that line: hardly at all
    # (a straight limb: it bends in its middle), somewhat (a bent arm: at the slice furthest off), or a lot (the
    # RingMaw's hind legs, which rise to a knee above its back: at the point furthest from the line). A two-legged
    # boss's legs are taken as straight: a thick leg stands off its own line by its bulk alone.
    # (a leg's tip is its foot: the middle of its lowest vertices - the furthest one may be a toe out to the side)
    far = sorted(points, key=(lambda q: q.z) if leg else (lambda q: -(q - pivot).length))[:max(3, len(points) // (10 if leg else 16))]
    tip = sum(far, Vector()) / len(far)
    axis = tip - pivot

    def along(q):
        return (q - pivot).dot(axis) / axis.length_squared

    def off(q):
        return (q - (pivot + axis * along(q))).length

    best = None
    for k in range(9):
        u0 = 0.28 + k * 0.05
        cut = [q for q in points if u0 <= along(q) < u0 + 0.08]
        if len(cut) >= 3:
            mid = sum(cut, Vector()) / len(cut)
            if best is None or off(mid) > best[0]:
                best = (off(mid), mid)
    if best and best[0] > 0.25 * axis.length and (quad or not leg):
        reach = max(off(q) for q in points)
        top = [q for q in points if off(q) >= 0.85 * reach]
        return tip, sum(top, Vector()) / len(top), 'knee off the line'
    if best and best[0] > 0.08 * axis.length and not leg:
        return tip, best[1], 'bent'
    cut = [q for q in points if 0.44 <= along(q) <= 0.56]
    return tip, (sum(cut, Vector()) / len(cut) if cut else pivot + axis * 0.5), 'straight'


def past_bend(q, pivot, mid, tip):
    # how far a point lies past the bend, along the limb's own two lines (negative: before it)
    best = None
    for a, b, sign in ((pivot, mid, -1), (mid, tip, 1)):
        seg = b - a
        t = min(1.0, max(0.0, (q - a).dot(seg) / seg.length_squared))
        d = (q - (a + seg * t)).length
        if best is None or d < best[0]:
            best = (d, (t if sign > 0 else t - 1) * seg.length)
    return best[1]


def build(name, B):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    report = {'name': name}
    pieces = []  # (object, group)
    if 'json' in B:
        for part, offset, group in B['parts']:
            o, wound = json_part(os.path.join(repo, B['json'], '%s.%s.json' % (B['asset'], part)), part, offset)
            pieces.append((o, group))
            report.setdefault('winding', {})[part] = wound
    else:
        bpy.ops.import_scene.gltf(filepath=os.path.join(repo, B['glb']))
        for o in list(bpy.context.scene.objects):
            if o.type != 'MESH':
                bpy.data.objects.remove(o)
                continue
            key = o.name.split('.')[0]
            group = B['groups'].get(key, B.get('default'))
            world = o.matrix_world.copy()
            o.parent = None
            o.data.transform(world)
            o.matrix_world.identity()
            bake_colour(o)
            pieces.append((o, group))
    joints = {k: A(*v) for k, v in B['joints'].items()}
    # the limbs' elbows and knees
    bends, points = {}, {}
    for o, g in pieces:
        points.setdefault(g, []).extend(v.co.copy() for v in o.data.vertices)
    for upper in LIMBS:
        bends[upper] = limb(points[upper], joints[upper], upper.startswith('Leg'), B.get('quad'))
    # the middle of the head from its bone, in the game's asset axes (normalize_skinned.lua keeps it as the model's
    # HeadCentre attribute: a finisher aims at the head's middle, not at the neck)
    head = points.get('Head', []) + points.get('Glow', [])
    lo = Vector([min(q[i] for q in head) for i in range(3)])
    hi = Vector([max(q[i] for q in head) for i in range(3)])
    off = (lo + hi) / 2 - joints['Head']
    report['head'] = [round(-off.x, 3), round(off.z, 3), round(off.y, 3)]
    # the two legs bend at the same place (each one's own guess differs by noise): the mean of the two, mirrored
    kl, kr = bends['LegL'][1], bends['LegR'][1]
    knee = Vector(((kl.x - kr.x) / 2, (kl.y + kr.y) / 2, (kl.z + kr.z) / 2))
    bends['LegL'] = (bends['LegL'][0], knee, bends['LegL'][2])
    bends['LegR'] = (bends['LegR'][0], Vector((-knee.x, knee.y, knee.z)), bends['LegR'][2])
    # the weights
    for o, group in pieces:
        me = o.data
        if group in LIMBS:
            pivot = joints[group]
            tip, mid, how = bends[group]
            band = 0.1 * ((mid - pivot).length + (tip - mid).length)
            up, low = o.vertex_groups.new(name=group), o.vertex_groups.new(name=LIMBS[group])
            for v in me.vertices:
                w = min(1.0, max(0.0, 0.5 + past_bend(v.co, pivot, mid, tip) / (2 * band)))
                if w < 1:
                    up.add([v.index], 1 - w, 'REPLACE')
                if w > 0:
                    low.add([v.index], w, 'REPLACE')
        else:
            bone = {'Body': 'Spine', 'Head': 'Head', 'Glow': 'Head', 'HandR': 'ForearmR'}.get(group, group)
            o.vertex_groups.new(name=bone).add([v.index for v in me.vertices], 1.0, 'REPLACE')
        for m in list(me.materials):
            me.materials.clear()
            break
    # one mesh, and the glowing pieces as another
    meshes = []
    for label, pick in ((name, lambda g: g != 'Glow'), (name + '_Glow', lambda g: g == 'Glow')):
        objs = [o for o, g in pieces if pick(g)]
        if not objs:
            continue
        bpy.ops.object.select_all(action='DESELECT')
        for o in objs:
            o.select_set(True)
        bpy.context.view_layer.objects.active = objs[0]
        if len(objs) > 1:
            bpy.ops.object.join()
        o = bpy.context.view_layer.objects.active
        o.name = label
        o.data.name = label
        mat = bpy.data.materials.new(label)
        o.data.materials.append(mat)
        o.data.color_attributes.active_color = o.data.color_attributes['Col']
        o.data.color_attributes.render_color_index = 0
        meshes.append(o)
    # the skeleton
    arm = bpy.data.armatures.new(name + '_Rig')
    ao = bpy.data.objects.new(name + '_Rig', arm)
    bpy.context.scene.collection.objects.link(ao)
    bpy.ops.object.select_all(action='DESELECT')
    bpy.context.view_layer.objects.active = ao
    ao.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    bones = {}

    def bone(bname, head, tail, parent=None):
        b = arm.edit_bones.new(bname)
        b.head, b.tail = head, tail if (tail - head).length > 0.05 else head + Vector((0, 0, 0.3))
        if parent:
            b.parent = bones[parent]
        bones[bname] = b
        report.setdefault('bones', {})[bname] = [round(x, 3) for x in head]

    hips = (joints['LegL'] + joints['LegR']) / 2
    chest = (joints['ArmL'] + joints['ArmR']) / 2
    bone('Root', Vector((0, 0, 0)), Vector((0, 0, 0.5)))
    bone('Spine', hips, chest, 'Root')
    bone('Head', joints['Head'], joints['Head'] + (Vector((0, -0.7, 0)) if B.get('quad') else Vector((0, 0, 0.7))), 'Spine')
    for upper, lower in LIMBS.items():
        tip, mid, how = bends[upper]
        bone(upper, joints[upper], mid, 'Spine' if upper.startswith('Arm') else 'Root')
        bone(lower, mid, tip, upper)
        report.setdefault('bend', {})[upper] = how
    for side in ('TendrilL', 'TendrilR'):
        if side in joints:
            far = sorted(points[side], key=lambda q: -(q - joints[side]).length)[:8]
            bone(side, joints[side], sum(far, Vector()) / len(far), 'Spine')
    bpy.ops.object.mode_set(mode='OBJECT')
    for o in meshes:
        o.parent = ao
        mod = o.modifiers.new('Armature', 'ARMATURE')
        mod.object = ao
        co = [v.co for v in o.data.vertices]
        report.setdefault('meshes', {})[o.name] = dict(tris=len(o.data.polygons), verts=len(co), groups=[g.name for g in o.vertex_groups],
                                                    lo=[round(min(c[i] for c in co), 2) for i in range(3)], hi=[round(max(c[i] for c in co), 2) for i in range(3)])
    dst = os.path.join(out, name + '.glb')
    bpy.ops.object.select_all(action='SELECT')
    kw = dict(filepath=dst, export_format='GLB', export_yup=True, export_apply=False, export_materials='EXPORT', export_skins=True, export_animations=False)
    try:
        bpy.ops.export_scene.gltf(**kw, export_vertex_color='ACTIVE')
    except TypeError:
        bpy.ops.export_scene.gltf(**kw, export_colors=True)
    report['file'] = dst
    if qa:
        render(name, ao, meshes, B)
    return report


def render(name, ao, meshes, B):
    # two pictures to check it by eye: as built, and with every joint bent
    sc = bpy.context.scene
    sc.render.engine = 'BLENDER_WORKBENCH'
    sc.display.shading.light = 'STUDIO'
    sc.display.shading.color_type = 'VERTEX'
    sc.render.resolution_x, sc.render.resolution_y = 640, 640
    cam = bpy.data.objects.new('QA', bpy.data.cameras.new('QA'))
    sc.collection.objects.link(cam)
    sc.camera = cam
    hi = max(max(v.co.z for v in o.data.vertices) for o in meshes)
    target = Vector((0, 0, hi * 0.5))
    for label, pose in (('rest', False), ('bent', True)):
        for pb in ao.pose.bones:
            pb.rotation_mode = 'XYZ'
            bend = 0.0
            if pose:
                bend = {'Forearm': 1.0, 'Shin': -1.0, 'Head': 0.5, 'Spine': 0.3, 'Arm': 0.5, 'Leg': 0.4, 'Tendril': 0.6}.get(pb.name.rstrip('LR'), 0)
            pb.rotation_euler = (bend, 0, 0)
        for view, at in (('front', Vector((-hi * 1.1, -hi * 2.2, hi * 0.9))), ('side', Vector((hi * 2.4, -hi * 0.5, hi * 0.8)))):
            cam.location = at
            cam.rotation_euler = (target - at).to_track_quat('-Z', 'Y').to_euler()
            sc.render.filepath = os.path.join(qa, '%s_%s_%s.png' % (name, label, view))
            bpy.ops.render.render(write_still=True)


reports = []
for name, B in BOSSES.items():
    if only and name not in only:
        continue
    reports.append(build(name, B))
    print('BOSS', json.dumps(reports[-1]))
json.dump(reports, open(os.path.join(out, 'rig_bosses.json'), 'w'), indent=1)
