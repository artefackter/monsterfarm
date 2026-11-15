# Static GLB: keep every object, store the vertex colours as sRGB numbers (Roblox shows COLOR_0 raw), re-export.
# Usage: blender --background --factory-startup --python srgb_static.py -- <src.glb> <dst.glb>
import bpy, sys

src, dst = sys.argv[sys.argv.index('--') + 1:][:2]


def srgb(c):
    c = max(0.0, min(1.0, c))
    return c * 12.92 if c <= 0.0031308 else 1.055 * (c ** (1 / 2.4)) - 0.055


bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
for o in bpy.context.scene.objects:
    if o.type != 'MESH':
        continue
    me = o.data
    me.name = o.name
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
    print('OBJ', o.name, len(me.polygons), [m.name for m in me.materials])
kw = dict(filepath=dst, export_format='GLB', export_yup=True, export_apply=True, export_materials='EXPORT')
try:
    bpy.ops.export_scene.gltf(**kw, export_vertex_color='ACTIVE')
except TypeError:
    bpy.ops.export_scene.gltf(**kw, export_colors=True)
print('DONE', dst)
