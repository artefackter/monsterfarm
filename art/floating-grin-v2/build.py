"""Build the independent review assets on the project's existing review stage."""
import json
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector

ROOT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT))
from sculpt import CENTER, Geometry, hand, portrait

BASE="FloatingGrin"
AGGRESSIVE=BASE+"Aggressive"
STAGE=ROOT.parent/"horror-reference-set-v1"/"models"/(BASE+".blend")


def motion(bone,amount):
    if bone=="Head":
        return (Matrix.Translation(CENTER+Vector((0,-2.00*amount,-.42*amount))) @
                Matrix.Rotation(.135*amount,4,"X") @ Matrix.Translation(-CENTER))
    if bone.startswith("Hand"):
        slide=(-.14,-.62,.13) if bone[4]=="R" else (.19,-.74,.29)
        return Matrix.Translation(Vector(slide)*amount)
    return Matrix.Identity(4)


def animate(rig,scene):
    scene.frame_start,scene.frame_end,scene.render.fps=1,37,30
    for frame in range(1,38):
        if frame<5: t=0.
        elif frame<13: t=(frame-5)/8
        elif frame<=17: t=1.
        else:t=(37-frame)/20
        t=t*t*(3-2*t)
        for bn in ("Head","HandL","HandR"):
            bone=rig.pose.bones[bn]
            local=bone.bone.matrix_local
            bone.matrix_basis=local.inverted()@motion(bn,t)@motion(bn,1).inverted()@local
            bone.keyframe_insert(data_path="location",frame=frame,group=bn)
            bone.keyframe_insert(data_path="rotation_quaternion",frame=frame,group=bn)
    rig.animation_data.action.name="OrbLunge"
    scene.frame_set(14)


def material():
    mat=bpy.data.materials.new("FloatingGrin_VertexColour")
    mat.use_nodes=True
    shader=mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Roughness"].default_value=.61
    shader.inputs["Specular IOR Level"].default_value=.065
    vc=mat.node_tree.nodes.new("ShaderNodeVertexColor");vc.layer_name="Col"
    mat.node_tree.links.new(vc.outputs["Color"],shader.inputs["Base Color"])
    return mat


def model(name,collection,scene,hand_builder=hand):
    g=Geometry()
    bones={"Root":(Vector((0,0,0)),Vector((0,0,.35)),None),
           "Head":(CENTER-Vector((0,0,.85)),CENTER+Vector((0,0,.94)),"Root")}
    portrait(g)
    for side in ("L","R"):
        hand_builder(g,side,bones)
    aggressive=name==AGGRESSIVE
    matrices={bn:(motion(bn,1.) if aggressive else Matrix.Identity(4)) for bn in bones}
    rig=bpy.data.objects.new(name+"_Rig",bpy.data.armatures.new(name+"_Skeleton"))
    collection.objects.link(rig);bpy.context.view_layer.objects.active=rig;rig.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    for bn,(head,tail,parent) in bones.items():
        bone=rig.data.edit_bones.new(bn);bone.head=head;bone.tail=tail
        bone.transform(matrices[bn],scale=False)
        if parent: bone.parent=rig.data.edit_bones[parent]
    bpy.ops.object.mode_set(mode="OBJECT")
    data=bpy.data.meshes.new(name+"_Surface")
    data.from_pydata([matrices[bn]@p for bn,p in zip(g.joints,g.points)],[],g.faces)
    for face,smooth in zip(data.polygons,g.smooth): face.use_smooth=smooth
    colors=data.color_attributes.new(name="Col",type="BYTE_COLOR",domain="POINT")
    for dest,rgb in zip(colors.data,g.colors): dest.color_srgb=(*rgb,1)
    bm=bmesh.new();bm.from_mesh(data)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    bm.to_mesh(data);bm.free();data.update()
    ob=bpy.data.objects.new(name+"_Mesh",data)
    collection.objects.link(ob);ob.parent=rig;data.materials.append(material())
    groups={bn:ob.vertex_groups.new(name=bn) for bn in bones}
    for bn,group in groups.items():
        inds=[i for i,v in enumerate(g.joints) if v==bn]
        if inds:group.add(inds,1,"REPLACE")
    mod=ob.modifiers.new("Skeleton","ARMATURE");mod.object=rig
    if aggressive:animate(rig,scene)
    return ob,rig


def camera(scene,target,angle,scale,resolution):
    cam=scene.camera
    cam.location=Vector(target)+Vector(angle)
    cam.rotation_euler=(-Vector(angle)).to_track_quat("-Z","Y").to_euler()
    cam.data.ortho_scale=scale
    scene.render.resolution_x,scene.render.resolution_y=resolution
    card=bpy.data.objects["Review Gradient"]
    card.rotation_euler=cam.rotation_euler
    card.location=Vector(target)-Vector(angle).normalized()*14
    aspect=resolution[0]/resolution[1]
    card.scale=(scale*min(1,aspect)*.515,scale*min(1,1/aspect)*.515,1)


def backdrop(scene):
    for obj in scene.objects:
        if obj.type=="MESH" and not obj.find_armature(): obj.hide_render=True
    bpy.ops.mesh.primitive_plane_add(size=2)
    card=bpy.context.object;card.name="Review Gradient"
    for collection in list(card.users_collection): collection.objects.unlink(card)
    scene.camera.users_collection[0].objects.link(card)
    card.visible_shadow=False;card.visible_diffuse=False;card.visible_glossy=False
    mat=bpy.data.materials.new("Review backdrop");mat.use_nodes=True
    tree=mat.node_tree
    uv=tree.nodes.new("ShaderNodeTexCoord")
    split=tree.nodes.new("ShaderNodeSeparateXYZ")
    ramp=tree.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color=(.29,.42,.52,1)
    ramp.color_ramp.elements[1].color=(.23,.20,.26,1)
    ramp.color_ramp.elements.new(.46).color=(.32,.45,.53,1)
    em=tree.nodes.new("ShaderNodeEmission")
    for out,inp in ((uv.outputs["UV"],split.inputs[0]),(split.outputs["Y"],ramp.inputs[0]),
                    (ramp.outputs[0],em.inputs[0]),(em.outputs[0],tree.nodes["Material Output"].inputs[0])):
        tree.links.new(out,inp)
    card.data.materials.append(mat)


def render(scene,path,target,angle,scale,resolution):
    camera(scene,target,angle,scale,resolution)
    scene.render.filepath=str(path)
    bpy.ops.render.render(write_still=True)


def build(name,output=ROOT,hand_builder=hand,front_target=(-.12,-.25,3.50),front_scale=7.65,
          profile_target=(0,-.70,3.45),profile_scale=7.55):
    bpy.ops.wm.open_mainfile(filepath=str(STAGE))
    scene=bpy.context.scene
    char=bpy.data.collections[BASE]
    for o in list(char.objects): bpy.data.objects.remove(o,do_unlink=True)
    bpy.ops.object.select_all(action="DESELECT")
    char.name=name
    mesh,rig=model(name,char,scene,hand_builder)
    bpy.ops.object.select_all(action="DESELECT")
    rig.select_set(True);mesh.select_set(True);bpy.context.view_layer.objects.active=rig
    target=output/"models"/name
    aggressive=name==AGGRESSIVE
    bpy.ops.export_scene.gltf(filepath=str(target.with_suffix(".glb")),use_selection=True,
                              export_animations=aggressive,export_rest_position_armature=True)
    review_name=scene.name
    if aggressive: scene.name=rig.animation_data.action.name
    bpy.ops.export_scene.fbx(filepath=str(target.with_suffix(".fbx")),use_selection=True,
                             object_types={"MESH","ARMATURE"},add_leaf_bones=False,bake_anim=aggressive,
                             bake_anim_use_nla_strips=False,bake_anim_use_all_actions=False)
    scene.name=review_name
    scene.render.resolution_percentage=100;scene.cycles.samples=20
    backdrop(scene)
    center=CENTER+Vector((0,-2,-.42)) if aggressive else CENTER
    # Keep the head readable against a softly lit, blue-grey studio backdrop.
    previews=output/"previews"
    render(scene,previews/(name+"_Detail.png"),center,(0,-16,0),2.95,(620,620))
    render(scene,previews/(name+"_Profile.png"),profile_target,(14,-4,1.10),profile_scale,(600,700))
    render(scene,previews/(name+"_Front.png"),front_target,(.10,-15,.09),front_scale,(700,800))
    bpy.ops.object.select_all(action="DESELECT")
    rig.select_set(True)
    bpy.context.view_layer.objects.active=rig
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.wm.save_as_mainfile(filepath=str(target.with_suffix(".blend")),compress=True)
    mesh.data.calc_loop_triangles()
    assert all(t.area>1e-12 for t in mesh.data.loop_triangles)
    return {"triangles":len(mesh.data.loop_triangles),"bones":len(rig.data.bones),
            "animations":["OrbLunge"] if aggressive else []}


def build_pair(output=ROOT,**options):
    for folder in ("models","previews"): (output/folder).mkdir(parents=True,exist_ok=True)
    report={name:build(name,output,**options) for name in (BASE,AGGRESSIVE)}
    sys.path.insert(0,str(ROOT.parent/"pale-grinner-optimized-v1"))
    from pack_glb import pack
    for name in report:
        report[name]["packed"]=pack(output/"models"/(name+".glb"))
    (output/"report.json").write_text(json.dumps(report,indent=2)+"\n")


if __name__=="__main__":
    build_pair()
