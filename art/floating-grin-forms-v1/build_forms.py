"""Build six offline role variants on the approved V4 mesh and finger rig."""
from hashlib import sha256
import json
from pathlib import Path
import sys

import bpy
import numpy as np

ROOT = Path(__file__).resolve().parent
ART = ROOT.parent
sys.path[:0] = [str(ROOT),str(ART/"blender"),str(ART/"floating-grin-v2"),
                str(ART/"srp-optimized-v1"),str(ART/"pale-grinner-optimized-v1")]
from build import camera
from pack_glb import pack
from verify import inspect
from wardrobe import ROLES, fitted_parts, kit, library_parts

APPROVED = ART/"floating-grin-v4"
BASE = APPROVED/"models/FloatingGrin.blend"
SOURCE = ART/"hooded-stranger-forms-v1/models"


def accessory(label, points, faces, colors, normals, bone, mat, collection, linear):
    pts = np.asarray(points)
    indices = np.asarray(faces).reshape(-1,3)
    a,b,c = pts[indices].transpose(1,0,2)
    indices = indices[np.linalg.norm(np.cross(b-a,c-a),axis=1)>2e-10]
    data = bpy.data.meshes.new(label)
    data.from_pydata(pts.tolist(),[],indices.tolist())
    data.update()
    data.materials.append(mat)
    attr = data.color_attributes.new(name="Col",type="BYTE_COLOR",domain="POINT")
    rgba = np.column_stack((colors,np.ones(len(pts)))).astype("f")
    attr.data.foreach_set("color" if linear else "color_srgb",rgba.ravel())
    # Normals baked with the source wardrobe include sharp metal edges and smooth cloth.
    data.shade_smooth()
    data.normals_split_custom_set_from_vertices(np.asarray(normals).tolist())
    obj = bpy.data.objects.new(label,data)
    collection.objects.link(obj)
    obj.vertex_groups.new(name=bone).add(list(range(len(pts))),1,"REPLACE")
    return obj


def make_role(role):
    bpy.ops.wm.open_mainfile(filepath=str(BASE))
    scene = bpy.context.scene
    group = bpy.data.collections["FloatingGrin"]
    mesh = next(o for o in group.objects if o.type=="MESH")
    rig = mesh.find_armature()
    name = "FloatingGrin"+role
    group.name, mesh.name, rig.name = name,name+"_Mesh",name+"_Rig"
    source_points = np.array([list(v.co) for v in mesh.data.vertices])
    source_colors = np.array([list(c.color_srgb) for c in mesh.data.color_attributes["Col"].data])
    mat = mesh.data.materials[0]
    pieces = []
    for part, pts, tris, rgb, norms in library_parts(SOURCE,role):
        pieces.append(accessory(part,pts,tris,rgb,norms,"Head",mat,group,True))
    custom = fitted_parts(role,rig)
    tree = kit._asset_bvh(custom)
    for part in custom.parts:
        pts, norms, rgb, tris = kit.bake_part(part,tree)
        pieces.append(accessory(part.name,pts,tris,rgb,norms,part.attach,mat,group,False))
        part.bm.free()
    bpy.ops.object.select_all(action="DESELECT")
    for obj in [mesh,*pieces]: obj.select_set(True)
    bpy.context.view_layer.objects.active = mesh
    bpy.ops.object.join()
    rig.select_set(True)
    n = len(source_points)
    np.testing.assert_array_equal(source_points,[list(v.co) for v in mesh.data.vertices[:n]])
    np.testing.assert_array_equal(source_colors,[list(c.color_srgb) for c in mesh.data.color_attributes["Col"].data[:n]])
    new_groups = {mesh.vertex_groups[v.groups[0].group].name for v in mesh.data.vertices[n:]}
    assert new_groups == {"Head","HandR","HandL"} and mesh.find_armature()==rig
    assert len(mesh.data.materials)==1 and not rig.animation_data
    mesh.data.calc_loop_triangles()
    assert all(t.area>1e-12 for t in mesh.data.loop_triangles)
    prefix = ROOT/"models"/name
    bpy.ops.export_scene.gltf(filepath=str(prefix.with_suffix(".glb")),use_selection=True,
                              export_animations=False,export_rest_position_armature=True)
    bpy.ops.export_scene.fbx(filepath=str(prefix.with_suffix(".fbx")),use_selection=True,
                             object_types={"MESH","ARMATURE"},add_leaf_bones=False,bake_anim=False)
    packed = pack(prefix.with_suffix(".glb"))
    camera(scene,(-.22,-.05,4.57),(2.7,-16,1.20),6.65,(640,720))
    scene.render.resolution_percentage=100
    scene.render.filepath=str(ROOT/"previews"/(name+".png"))
    bpy.ops.render.render(write_still=True)
    bpy.context.view_layer.objects.active=rig
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.wm.save_as_mainfile(filepath=str(prefix.with_suffix(".blend")),compress=True)
    # A transparent source view, also suitable for matching the model's exact silhouette.
    scene.render.film_transparent=True
    bpy.data.objects["Review Gradient"].hide_render=True
    camera(scene,(-.22,-.05,4.57),(2.7,-16,1.20),6.65,(768,768))
    scene.render.image_settings.color_mode="RGBA"
    work=ROOT/"previews"/"cutouts"
    work.mkdir(exist_ok=True)
    scene.render.filepath=str(work/(name+".png"))
    bpy.ops.render.render(write_still=True)
    return {"role":role,"label":ROLES[role],"triangles":len(mesh.data.loop_triangles),
            "bones":len(rig.data.bones),"animations":[],"original_vertices":n,"packed":packed}


if __name__=="__main__":
    lock=json.loads((APPROVED/"approval.json").read_text())
    assert all(sha256((APPROVED/p).read_bytes()).hexdigest()==v["sha256"] for p,v in lock["files"].items())
    for sub in ("models","previews"): (ROOT/sub).mkdir(exist_ok=True)
    specs={"FloatingGrin"+r:make_role(r) for r in ROLES}
    (ROOT/"models.json").write_text(json.dumps(specs,ensure_ascii=False,indent=2)+"\n")
    checked={p.name:inspect(p,specs[p.stem]) for p in sorted((ROOT/"models").iterdir())
             if p.suffix in (".glb",".fbx")}
    assert len(checked)==12
    (ROOT/"validation.json").write_text(json.dumps(checked,indent=2)+"\n")
