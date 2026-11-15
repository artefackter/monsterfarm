# Renders each converted GLB twice side by side material: limb groups in flat colours (front three-quarter view).
# Usage: blender --background --factory-startup --python render_qa.py -- <out dir> <png dir>
import bpy, sys, os, math
from mathutils import Vector

ARG = sys.argv[sys.argv.index('--') + 1:]
SRC, DST = ARG[0], ARG[1]
os.makedirs(DST, exist_ok=True)
COL = {'Body': (0.55, 0.55, 0.6), 'Head': (0.95, 0.75, 0.2), 'ArmL': (0.2, 0.5, 1.0), 'ArmR': (1.0, 0.25, 0.25),
       'LegL': (0.1, 0.8, 0.9), 'LegR': (0.9, 0.3, 0.9), 'TendrilL': (0.3, 1, 0.3), 'TendrilR': (0.1, 0.5, 0.1),
       'HeadFace': (1, 1, 1)}
for f in sorted(os.listdir(SRC)):
    if not f.endswith('.glb'):
        continue
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(SRC, f))
    sc = bpy.context.scene
    lo, hi = Vector((1e9,) * 3), Vector((-1e9,) * 3)
    for o in sc.objects:
        if o.type != 'MESH':
            continue
        m = bpy.data.materials.new(o.name)
        m.diffuse_color = (*COL.get(o.name.split('.')[0], (0, 0, 0)), 1)
        o.data.materials.clear()
        o.data.materials.append(m)
        for c in o.bound_box:
            w = o.matrix_world @ Vector(c)
            lo = Vector(map(min, lo, w))
            hi = Vector(map(max, hi, w))
    center = (lo + hi) / 2
    size = max(hi - lo)
    cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam'))
    sc.collection.objects.link(cam)
    # glTF +Z forward is Blender -Y: look at the model's front from a three-quarter angle
    cam.location = center + Vector((size * 1.2, -size * 1.9, size * 0.55))
    cam.rotation_euler = (center - cam.location).to_track_quat('-Z', 'Y').to_euler()
    sc.camera = cam
    sc.render.engine = 'BLENDER_WORKBENCH'
    sc.display.shading.light = 'STUDIO'
    sc.display.shading.color_type = 'MATERIAL'
    sc.render.resolution_x = sc.render.resolution_y = 256
    sc.render.filepath = os.path.join(DST, f[:-4] + '.png')
    bpy.ops.render.render(write_still=True)
