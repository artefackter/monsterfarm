# Skinned monsters (owner, 2026-11-15: "the monsters are built of rigid parts - you have Blender, fix it"): a boss
# keeps its skeleton. Takes the art pack's skinned GLB as it is - mesh, bones and weights - stores the vertex colours
# as sRGB numbers (Roblox shows COLOR_0 raw) and writes it without its animation clips (the game moves the bones
# itself). Roblox imports it as one MeshPart per mesh with the Bone tree inside (checked 2026-11-15: 19 bones for
# Slendrina, HasSkinnedMesh true).
# Usage: blender --background --factory-startup --python skinned_srgb.py -- <src.glb> <dst.glb>
import bpy, sys

src, dst = sys.argv[sys.argv.index('--') + 1:][:2]


def srgb(c):
    c = max(0.0, min(1.0, c))
    return c * 12.92 if c <= 0.0031308 else 1.055 * (c ** (1 / 2.4)) - 0.055


bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
for o in list(bpy.context.scene.objects):
    if o.type == 'ARMATURE':
        if o.animation_data:
            o.animation_data.action = None  # the bind pose
        for pb in o.pose.bones:
            pb.custom_shape = None
    elif o.type == 'MESH' and not any(m.type == 'ARMATURE' for m in o.modifiers):
        bpy.data.objects.remove(o)  # the importer's bone display shape
for a in list(bpy.data.actions):
    bpy.data.actions.remove(a)
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
    print('OBJ', o.name, len(me.polygons), len(o.vertex_groups), [m.name for m in me.materials])
kw = dict(filepath=dst, export_format='GLB', export_yup=True, export_apply=False, export_materials='EXPORT',
          export_skins=True, export_animations=False)
try:
    bpy.ops.export_scene.gltf(**kw, export_vertex_color='ACTIVE')
except TypeError:
    bpy.ops.export_scene.gltf(**kw, export_colors=True)
print('DONE', dst)
