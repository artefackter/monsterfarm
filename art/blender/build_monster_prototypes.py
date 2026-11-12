"""Build the approval pack, render its meshes, and check the exported GLB in Blender."""
import json
import math
from pathlib import Path
import sys

import bpy
import bmesh
from mathutils import Vector, Matrix

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent / "tools"))
import kit
from package_monster_prototypes import write_pack

revision_two = "--revision-two" in sys.argv
revision_three = "--revision-three" in sys.argv
revision_four = "--revision-four" in sys.argv
revision_five = "--revision-five" in sys.argv
revision_six = "--revision-six" in sys.argv
revised_anatomy = revision_four or revision_five or revision_six
weapon_preview = "--weapon-preview" in sys.argv
if weapon_preview:
    import assets_weapons_preview as assets
    pack_name = "weapons-preview"
elif revision_six:
    import assets_monster_prototypes_v6 as assets
    pack_name = "monster-prototypes-v6"
elif revision_four or revision_five:
    import assets_monster_prototypes_v4 as assets
    pack_name = "monster-prototypes-v5" if revision_five else "monster-prototypes-v4"
elif revision_three:
    import assets_monster_prototypes_v3 as assets
    pack_name = "monster-prototypes-v3"
elif revision_two:
    import assets_monster_prototypes_v2 as assets
    pack_name = "monster-prototypes-v2"
else:
    import assets_monster_prototypes as assets
    pack_name = "monster-prototypes"

OUT = HERE.parent / "export" / pack_name
if '--output' in sys.argv:OUT=Path(sys.argv[sys.argv.index('--output')+1]).resolve()
PREVIEW = HERE.parent / "preview" / pack_name
OUT.mkdir(parents=True, exist_ok=True)
PREVIEW.mkdir(parents=True, exist_ok=True)

assets.build()
manifest, baked, triangle_count = kit.export_all(str(OUT))
(OUT / "_manifest.json").write_text(json.dumps(manifest, indent=2))
(OUT / "_rig.json").write_text(json.dumps({
    "coordinates": "Roblox (-BlenderX, BlenderZ, BlenderY)",
    "feetY": 0,
    "joints": assets.JOINTS,
}, indent=2))
glb_path, report = write_pack(OUT, manifest, assets.JOINTS, triangle_count, weapons=weapon_preview)


def clear():
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    for group in list(bpy.data.collections):
        if not group.objects:
            bpy.data.collections.remove(group)


def verify_roundtrip():
    clear()
    bpy.ops.import_scene.gltf(filepath=str(glb_path))
    imported = [obj for obj in bpy.data.objects if obj.type == "MESH"]
    expected = {f"{name}__{p['part']}": p for name, parts in manifest.items() for p in parts}
    assert {obj.name for obj in imported} == set(expected)
    for obj in imported:
        meta = expected[obj.name]
        assert obj.data.color_attributes
        assert obj.parent and obj.parent.name == obj.name.split("__")[0]
        assert len(obj.data.polygons) == meta["tris"]
        dimensions = [obj.dimensions.x, obj.dimensions.z, obj.dimensions.y]
        assert all(abs(expected_size - actual) < .012 or
                   (expected_size == .05 and actual <= .05)
                   for expected_size,actual in zip(meta["size"], dimensions)), obj.name
    report["roundtrip"] = {"parts": len(imported), "vertexColors": True,
                           "groupsAndDimensionsVerified": True}


verify_roundtrip()
(OUT / "_validation.json").write_text(json.dumps(report, indent=2))
print("GLB VALIDATED", report, flush=True)
if '--export-only' in sys.argv:
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'WeaponPrototypes.blend'))
    sys.exit(0)

FONT = bpy.data.fonts.load("/System/Library/Fonts/Supplemental/Arial Bold.ttf")


def material(name, color):
    value = bpy.data.materials.new(name)
    value.use_nodes = True
    shader = value.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*[c**2.2 for c in kit._rgb(color)], 1)
    shader.inputs["Roughness"].default_value = .76
    return value


def stage():
    bpy.ops.mesh.primitive_plane_add(size=200, location=(0,0,-.19))
    bpy.context.object.data.materials.append(material("Backdrop", "6A8294"))


def plinth(x, radius):
    bpy.ops.mesh.primitive_cylinder_add(vertices=56,radius=radius,depth=.20,location=(x,0,-.095))
    obj = bpy.context.object
    obj.data.materials.append(material("Slate base", "465966"))
    bevel = obj.modifiers.new("Edge bevel", "BEVEL")
    bevel.width = .062
    bevel.segments = 2


def label(value, x, y, z, size, color="F4F0E7"):
    curve = bpy.data.curves.new(value, "FONT")
    curve.body = value
    curve.font = FONT
    curve.align_x = "CENTER"
    curve.size = size
    curve.extrude = .002
    obj = bpy.data.objects.new(value,curve)
    bpy.context.scene.collection.objects.link(obj)
    obj.location = (x,y,z)
    obj.rotation_euler = (math.pi/2,0,0)
    curve.materials.append(material("Typography", color))


def spawn(name, x=0, angle=0, head_only=False, z=0, selected_parts=None):
    scene = bpy.context.scene
    group = bpy.data.collections.new(name)
    scene.collection.children.link(group)
    before = set(bpy.data.objects)
    parts = manifest[name]
    if head_only:
        parts = [p for p in parts if p["attach"] == "Head"]
    if selected_parts:
        parts = [p for p in parts if p["part"] in selected_parts]
    kit.spawn_preview(baked,name,parts,(x,0,z),rot_z=angle)
    for obj in set(bpy.data.objects) - before:
        meta = next(p for p in manifest[name] if p["part"] == obj.name)
        obj.name = f"{name}__{meta['part']}"
        if meta["attach"]:
            obj["Attach"] = meta["attach"]
        for collection in list(obj.users_collection):
            collection.objects.unlink(obj)
        group.objects.link(obj)
        if meta["material"] == "Neon":
            m = obj.data.materials[0]
            shader = m.node_tree.nodes.get("Principled BSDF")
            attr = next(node for node in m.node_tree.nodes if node.type == "VERTEX_COLOR")
            m.node_tree.links.new(attr.outputs["Color"],shader.inputs["Emission Color"])
            shader.inputs["Emission Strength"].default_value = 1.0 if name=="RingMaw" else .58


def lighting(camera,target,width,size,path):
    kit.setup_render(str(path), camera, target, res=size, samples=28, bg="839BAC")
    scene=bpy.context.scene
    scene.cycles.use_denoising=True
    scene.camera.data.type="ORTHO"
    scene.camera.data.ortho_scale=width
    scene.world.node_tree.nodes["Background"].inputs[1].default_value=.70
    for lamp in bpy.data.lights:
        if lamp.type=="SUN":
            lamp.energy=1.35
    for position,power,radius,color in [
        ((-6,-12,13),1500,9,(1,.88,.76)),
        ((8,-4,8),900,8,(.72,.84,1)),
        ((3,6,11),1900,7,(.61,.82,1)),
    ]:
        lamp=bpy.data.lights.new("Softbox","AREA")
        lamp.energy=power
        lamp.shape="DISK"
        lamp.size=radius
        lamp.color=color
        obj=bpy.data.objects.new("Softbox",lamp)
        scene.collection.objects.link(obj)
        obj.location=position
        obj.rotation_euler=(Vector(target)-obj.location).to_track_quat("-Z","Y").to_euler()
    scene.render.image_settings.file_format="PNG"


def render(name, camera, target, width, size):
    lighting(camera,target,width,size,PREVIEW/(name+".png"))
    bpy.ops.render.render(write_still=True)
    print("RENDERED",name,flush=True)


titles = [("Deer_Farmer","ФЕРМЕР"),("Deer_Punk","НЕФОР"),
          ("Deer_Assassin","УБИЙЦА"),("Deer_Chief","ГЛАВВРАЧ")]
if weapon_preview:
    clear()
    for name, caption, x, z in [
        ("GunM249","ПУЛИК",-3,2.4),("GunDouble","ДВУШКА",3,2.4),
        ("GunPump","ПОМП",-3,-.18),("GunMP5","МП ПЯТКА",3,-.18),
    ]:
        spawn(name,x,angle=69,z=z)
        label(caption,x,-.52,z-1.12,.28)
    label("НОВОЕ ОРУЖИЕ",0,0,3.64,.42)
    render("weapons",(0,-22,5.05),(0,0,1.33),11.75,(2080,1200))
    clear()
    spawn("V3_GunAK",angle=86)
    label("КАЛАШ  /  МАГАЗИН ИЗОГНУТ К СТВОЛУ",0,0,1.045,.159)
    render("kalash-magazine",(0,-14,3.11),(0,0,.02),4.83,(1590,780))
else:
    clear()
    stage()
    for i,(name,title) in enumerate(titles):
        x=(i-1.5)*5.65
        spawn(name,x,(-12,10,-13,11)[i])
        plinth(x,2.35)
        label(title,x,-2.38,.12,.32)
    label("ОЛЕНИ  /  НОВАЯ ВЕРСИЯ",0,0,9.24,.54)
    render("deer-lineup",(0,-37,10.6),(0,0,4.25),24.1,(2520,1260))

if revision_two or revision_three or revised_anatomy:
    clear()
    for i,(name,title) in enumerate(titles):
        x=(i-1.5)*3.7
        spawn(name,x,(1,-23,23,-16)[i],head_only=True)
        label(title,x,-.2,4.15,.25)
    render("deer-faces",(0,-22,6.0),(0,-.45,5.54),15.1,(2400,605))

    if revision_three or revised_anatomy:
        for family, family_title in [("CaveDweller","ПЕЩЕРНИК"),("RingMaw","КОЛЬЦЕВИК")]:
            clear()
            stage()
            for i, (role, caption) in enumerate([("Farmer","ФЕРМЕР"),("Punk","НЕФОР"),("Assassin","УБИЙЦА")]):
                x=(i-1)*6.1
                spawn(family+"_"+role,x,angle=(-33,-18,-43)[i])
                plinth(x,2.88)
                label(caption,x,-3.28,.08,.30)
            if revised_anatomy and family == "CaveDweller":
                label(family_title,0,0,7.50,.45)
                render("cavedweller-variants",(0,-29,10.3),(0,0,3.40),18.4,(2350,1320))
            else:
                label(family_title,0,0,5.24,.45)
                render(family.lower()+"-variants",(0,-27,8.7),(0,0,2.30),18.4,(2350,1120))
        clear()
        stage()
        for x, angle, caption in [(-3.05,-25,"ТРИ ЧЕТВЕРТИ"),(3.05,-83,"СБОКУ")]:
            spawn("RingMaw" if revised_anatomy else "CaveDweller",x,angle)
            plinth(x,2.78)
            label(caption,x,-3.08,.03,.28)
        if revised_anatomy:
            label("КОЛЬЦЕВИК  /  ВЫСОКИЕ КОЛЕНИ",0,0,5.13,.35)
            render("ringmaw-pose",(0,-23,8.2),(0,0,2.28),13.55,(1900,1120))
        else:
            label("ПЕЩЕРНИК  /  ВЫСОКИЕ КОЛЕНИ",0,0,4.45,.35)
            render("cavedweller-pose",(0,-23,7.17),(0,0,1.98),12.75,(1900,1050))
    else:
        clear()
        stage()
        for x, angle, caption in [(-3.55,-30,"ТРИ ЧЕТВЕРТИ"),(3.55,-87,"СБОКУ")]:
            spawn("RingMaw",x,angle)
            plinth(x,3.16)
            label(caption,x,-3.43,.03,.30)
        label("КОЛЬЦЕВИК  /  СТОЙКА НА ЧЕТЫРЁХ ЛАПАХ",0,0,5.18,.37)
        render("ringmaw-quadruped",(0,-23,8.2),(0,-.1,2.16),14.9,(2200,1220))
elif not weapon_preview:
    clear()
    stage()
    for name,title,x,angle in [
        ("RingMaw","КОЛЬЦЕВИК",-3.9,-14),
        ("CaveDweller","ПЕЩЕРНИК",3.9,13),
    ]:
        spawn(name,x,angle)
        plinth(x,2.72)
        label(title,x,-2.62,.11,.39)
    label("НОВЫЕ МОНСТРЫ",0,0,7.55,.54)
    render("new-monsters",(0,-29,8.3),(0,0,3.55),15.7,(1900,1230))

    clear()
    stage()
    for i,(name,title) in enumerate(titles):
        x=(i-1.5)*5.65
        spawn(name,x,148 if i%2==0 else 124)
        plinth(x,2.35)
        label(title,x,-2.38,.12,.32)
    label("ОЛЕНИ  /  СБОКУ И СЗАДИ",0,0,9.24,.54)
    render("deer-back",(0,-37,10.8),(0,0,4.25),24.1,(2200,1100))

    clear()
    stage()
    spawn("RingMaw",-3.9,-49)
    spawn("CaveDweller",3.9,137)
    plinth(-3.9,2.72)
    plinth(3.9,2.72)
    label("КОЛЬЦЕВИК",-3.9,-2.62,.11,.39)
    label("ПЕЩЕРНИК",3.9,-2.62,.11,.39)
    render("new-monsters-side",(0,-29,8.3),(0,0,3.55),15.7,(1800,1100))

if revision_five or revision_six:
    closeups = [
        ("Deer_Punk","ОЛЕНЬ",(3.5,-6.6,3.25),(1.77,-.59,1.99),1.56),
        ("RingMaw","КОЛЬЦЕВИК",(3.2,-4.9,2.5),(1.33,-1.88,.20),1.46),
        ("CaveDweller","ПЕЩЕРНИК",(3.0,-6.0,2.2),(1.23,-.41,.90),1.20),
    ]
    if revision_six:
        closeups = [
            ("Deer_Punk","ОЛЕНЬ",(3.5,-6.6,3.25),(1.76,-.55,1.87),1.67),
            ("RingMaw","КОЛЬЦЕВИК",(3.2,-4.9,2.5),(1.38,-1.88,.21),1.56),
            ("CaveDweller","ПЕЩЕРНИК",(3.0,-6.0,2.2),(1.23,-.36,.75),1.51),
        ]
    for name,caption,camera,target,width in closeups:
        clear()
        spawn(name,selected_parts={"ArmL"})
        render(name.lower()+"-claws",camera,target,width,(1100,1100))

if revision_six:
    clear()
    for name,caption,x,cut,anchor,scale,tilt in [
        ("Deer_Punk","ОЛЕНЬ / ЦЕПКИЙ ХВАТ",-2.35,2.405,(1.74,-.46,1.87),1.62,0),
        ("RingMaw","КОЛЬЦЕВИК / ОПОРНАЯ ЛАПА",0,.34,(1.34,-1.80,.17),1.82,23),
        ("CaveDweller","ПЕЩЕРНИК / ДЛИННЫЕ ПАЛЬЦЫ",2.35,1.275,(1.23,-.29,.70),1.60,0),
    ]:
        before=set(bpy.data.objects)
        spawn(name,selected_parts={"ArmL"})
        for obj in set(bpy.data.objects)-before:
            editable=bmesh.new()
            editable.from_mesh(obj.data)
            bmesh.ops.remove_doubles(editable,verts=list(editable.verts),dist=.00001)
            bmesh.ops.delete(editable,geom=[v for v in editable.verts if v.co.z>cut],context="VERTS")
            border=[edge for edge in editable.edges if edge.is_boundary]
            if border:
                bmesh.ops.holes_fill(editable,edges=border,sides=0)
            bmesh.ops.recalc_face_normals(editable,faces=list(editable.faces))
            for face in editable.faces:
                face.smooth=False
            editable.to_mesh(obj.data)
            editable.free()
            obj.matrix_world=(Matrix.Translation((x,0,1.14)) @
                              Matrix.Rotation(math.radians(tilt),4,"X") @
                              Matrix.Scale(scale,4) @ Matrix.Translation(-Vector(anchor)))
        label(caption,x,-.56,.09,.135)
    label("РАЗНАЯ АНАТОМИЯ КОНЕЧНОСТЕЙ",0,0,2.40,.22)
    render("limbs-comparison",(0,-12,7.2),(0,0,1.08),8.35,(2100,850))

# Editable model-only scene, with one collection per asset.
clear()
for i,name in enumerate(manifest):
    spawn(name,(i%6-2.5)*7,angle=70 if weapon_preview else 0,z=9*(i//6))
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type == "VIEW_3D":
            view=area.spaces.active
            view.shading.color_type="VERTEX"
            view.region_3d.view_location=Vector((0,0,4.1))
            view.region_3d.view_distance=46
            view.region_3d.view_rotation=Vector((.01,1,-.13)).to_track_quat("-Z","Y")
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/("WeaponPrototypes.blend" if weapon_preview else "MonsterPrototypes.blend")))
