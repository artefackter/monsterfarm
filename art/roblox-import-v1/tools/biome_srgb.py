# Biome props (art/biome-models-optimized-v1/models, 2026-11-15): store each model's vertex colours as sRGB numbers
# (Roblox shows COLOR_0 raw, the packs hold linear values) and re-export, one Blender session for the whole folder.
# Usage: blender --background --factory-startup --python biome_srgb.py -- <src dir> <dst dir>
import bpy, sys, os

src, dst = sys.argv[sys.argv.index('--') + 1:][:2]
os.makedirs(dst, exist_ok=True)


def srgb(c):
    c = max(0.0, min(1.0, c))
    return c * 12.92 if c <= 0.0031308 else 1.055 * (c ** (1 / 2.4)) - 0.055


for f in sorted(os.listdir(src)):
    if not f.endswith('.glb'):
        continue
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(src, f))
    parts = []
    for o in bpy.context.scene.objects:
        if o.type != 'MESH':
            continue
        # the part's name is the piece after the model's name: AC_Streetlight__Light -> Light
        o.name = o.name.split('__')[-1].split('.')[-1]
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
        parts.append(o.name)
    kw = dict(filepath=os.path.join(dst, f), export_format='GLB', export_yup=True, export_apply=True, export_materials='EXPORT')
    try:
        bpy.ops.export_scene.gltf(**kw, export_vertex_color='ACTIVE')
    except TypeError:
        bpy.ops.export_scene.gltf(**kw, export_colors=True)
    print('OUT', f, parts)
print('DONE')
