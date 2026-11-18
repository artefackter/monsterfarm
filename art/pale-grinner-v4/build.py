"""Prepare review-only models from the approved base and six wardrobe masters."""
import json
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector

ROOT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT))
import hands
import lunge

BASE="PaleGrinner"
AGGRESSIVE=BASE+"Aggressive"
FORMS=ROOT.parent/"pale-grinner-forms-v1"
ROLES=json.loads((FORMS/"report.json").read_text())["models"]
sources={name:(FORMS/"models"/(name+".blend")) for name in ROLES}
original=ROOT.parent/"pale-grinner-v3"/"models"/(BASE+".blend")
sources={BASE:original,AGGRESSIVE:original,**sources}
for folder in ("models","previews"): (ROOT/folder).mkdir(exist_ok=True)


def render(scene,filename,at,view,scale,size):
    c=scene.camera
    c.location=Vector(at)+Vector(view)
    c.rotation_euler=(-Vector(view)).to_track_quat('-Z','Y').to_euler()
    c.data.ortho_scale=scale
    scene.render.resolution_x,scene.render.resolution_y=size
    scene.render.filepath=str(ROOT/"previews"/(filename+".png"))
    bpy.ops.render.render(write_still=True)


def update_skin(mesh,aggressive):
    bm=bmesh.new()
    bm.from_mesh(mesh.data)
    layer=bm.verts.layers.deform.active
    remove=[]
    for v in bm.verts:
        group=mesh.vertex_groups[next(iter(v[layer].keys()))].name
        if group.startswith("Hand") or (aggressive and group=="Neck"):
            remove.append(v)
        elif aggressive and group=="Head":
            v.co=lunge.head_transform(1)@v.co
    bmesh.ops.delete(bm,geom=remove,context="VERTS")
    bm.to_mesh(mesh.data)
    bm.free()


def select_only(*objects):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects: obj.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]


def build(name,path):
    bpy.ops.wm.open_mainfile(filepath=str(path))
    scene=bpy.context.scene
    scene.cycles.samples=12
    collection=bpy.data.collections["PaleGrinner"]
    mesh=next(o for o in collection.objects if o.type=="MESH")
    rig=next(o for o in collection.objects if o.type=="ARMATURE")
    mat=mesh.data.materials[0]
    aggressive=name==AGGRESSIVE
    hand_view=((1.32,-.24,2.02),(3,-16,2),1.56,(480,550))
    side_view=((0,-.90,4.02),(17,-2.1,1.25),8.65,(650,780))
    if name==BASE:
        render(scene,"Hand_Previous",*hand_view)
    update_skin(mesh,aggressive)
    anchors={}
    pieces=[]
    for side in ("L","R"):
        obj,pivots=hands.make_hand(side,rig,mat)
        anchors.update(pivots)
        pieces.append(obj)
    select_only(rig)
    bpy.ops.object.mode_set(mode="EDIT")
    bones=rig.data.edit_bones
    for bone,(head,tail) in anchors.items():
        bones[bone].head,bones[bone].tail=head,tail
    if aggressive: lunge.extend_skeleton(bones)
    bpy.ops.object.mode_set(mode="OBJECT")
    if aggressive: pieces.append(lunge.new_neck(rig,mat))
    select_only(mesh,*pieces)
    bpy.ops.object.join()
    mesh.name=name+"_Mesh"; mesh.data.name=name+"_Skin"
    rig.name=name+"_Rig"
    rig["RigType"]="Custom skinned NPC"
    rig["Status"]="Local review"
    if aggressive: lunge.animate(rig,scene)
    elif rig.animation_data: assert not rig.animation_data.action

    select_only(rig,mesh)
    target=ROOT/"models"/name
    bpy.ops.export_scene.gltf(filepath=str(target.with_suffix(".glb")),use_selection=True,
                              export_animations=aggressive,export_rest_position_armature=True)
    bpy.ops.export_scene.fbx(filepath=str(target.with_suffix(".fbx")),use_selection=True,
                             object_types={"ARMATURE","MESH"},add_leaf_bones=False,
                             bake_anim=aggressive,bake_anim_use_nla_strips=False,
                             bake_anim_use_all_actions=False,bake_anim_simplify_factor=0.)
    if name==BASE:
        render(scene,"Hand_Revised",*hand_view)
        render(scene,"Base_Profile",*side_view)
    if aggressive:
        scene.frame_set(14)
        render(scene,"Aggressive_Profile",*side_view)
        render(scene,"Aggressive_Portrait",(0,-1.13,5.9),(12,-8,.9),4.65,(700,630))
    render(scene,name, (0, -.75 if aggressive else 0, 3.95),
           (10,-15,1.5) if aggressive else (4,-18,1.5),8.8,(620,770))
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.wm.save_as_mainfile(filepath=str(target.with_suffix(".blend")),compress=True)
    mesh.data.calc_loop_triangles()
    return {"triangles":len(mesh.data.loop_triangles),"bones":len(rig.data.bones),
            "animations":["HeadLunge"] if aggressive else []}


selected=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else list(sources)
report_path=ROOT/"report.json"
report=json.loads(report_path.read_text()) if report_path.exists() else {}
for name in selected:
    report[name]=build(name,sources[name])
    report_path.write_text(json.dumps(report,indent=2)+"\n")
