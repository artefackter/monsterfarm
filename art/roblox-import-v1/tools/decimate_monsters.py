# Lighter monsters (owner, 2026-11-15: phones run hot again): the converted rigid monsters (monsters/*.glb, about
# 7,000 triangles on average, up to 13,000) cut to about TARGET triangles each with Blender's collapse decimation.
# Small parts (eyes, tendrils, up to KEEP_SMALL triangles) and textured parts (the Stranger's face) stay as they are;
# the rest share one ratio, redone gentler for any part that would lose its shape. Part names, vertex colours (COLOR_0, raw) and the glTF origin are kept, so the same
# normalize step (pivots from the conversion JSON) applies.
# Usage: blender --background --factory-startup --python decimate_monsters.py -- <src dir> <dst dir> [target]
import bpy, sys, os, json

ARGS = sys.argv[sys.argv.index('--') + 1:]
SRC, DST = ARGS[0], ARGS[1]
TARGET = int(ARGS[2]) if len(ARGS) > 2 else 3000
KEEP_SMALL = 150
os.makedirs(DST, exist_ok=True)
report = {}


def tris(o):
    return sum(len(p.vertices) - 2 for p in o.data.polygons)


def shape(me):
    area = sum(p.area for p in me.polygons)
    if not me.vertices:
        return area, (0, 0, 0)
    lo = [min(v.co[k] for v in me.vertices) for k in range(3)]
    hi = [max(v.co[k] for v in me.vertices) for k in range(3)]
    return area, tuple(hi[k] - lo[k] for k in range(3))


def textured(o):
    for m in o.data.materials:
        if m and m.use_nodes and any(n.type == 'TEX_IMAGE' for n in m.node_tree.nodes):
            return True
    return False


for f in sorted(os.listdir(SRC)):
    if not f.endswith('.glb'):
        continue
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(SRC, f))
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    before = sum(tris(o) for o in meshes)
    gentler = []
    keep = [o for o in meshes if tris(o) <= KEEP_SMALL or textured(o)]
    cut = [o for o in meshes if o not in keep]
    kept = sum(tris(o) for o in keep)
    rest = sum(tris(o) for o in cut)
    ratio = 1.0 if rest == 0 else max(0.12, min(1.0, (TARGET - kept) / rest))
    if ratio < 0.98:
        for o in cut:
            # Thin limbs (the Longmaw's legs) can collapse away whole: a part that loses over 14% of its surface or
            # 5% of any extent is redone gentler, and left as it was if even ratio 0.85 cannot hold it.
            src = o.data.copy()
            area, ext = shape(src)
            r = ratio
            while True:
                bpy.context.view_layer.objects.active = o
                mod = o.modifiers.new('Decimate', 'DECIMATE')
                mod.decimate_type = 'COLLAPSE'
                mod.ratio = r
                mod.use_collapse_triangulate = True
                bpy.ops.object.modifier_apply(modifier=mod.name)
                a2, e2 = shape(o.data)
                if a2 >= area * 0.86 and all(e2[k] >= ext[k] * 0.95 for k in range(3)):
                    break
                o.data = src.copy()
                if r >= 0.85:
                    gentler.append(o.name + ' kept')
                    break
                r = min(0.85, r * 1.35)
                gentler.append('%s %.2f' % (o.name, r))
    for o in meshes:  # keep the colour attribute the exporter writes
        me = o.data
        if me.color_attributes:
            me.color_attributes.active_color = me.color_attributes[0]
            me.color_attributes.render_color_index = 0
    after = sum(tris(o) for o in meshes)
    kw = dict(filepath=os.path.join(DST, f), export_format='GLB', export_yup=True, export_apply=True, export_materials='EXPORT')
    try:
        bpy.ops.export_scene.gltf(**kw, export_vertex_color='ACTIVE')
    except TypeError:
        bpy.ops.export_scene.gltf(**kw, export_colors=True)
    report[f[:-4]] = {'before': before, 'after': after, 'ratio': round(ratio, 3), 'gentler': gentler}
    print('OUT', f, before, '->', after, gentler)
with open(os.path.join(DST, 'decimate_report.json'), 'w') as fh:
    json.dump(report, fh, indent=1)
print('DONE', len(report))
