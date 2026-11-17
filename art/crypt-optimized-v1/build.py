"""Optimize the standalone crypt, with conservative interior-face removal.

Run with Blender in background mode. Original Crypt.glb is read-only.
"""
import bpy, bmesh, hashlib, json, math, sys
import numpy as np
from pathlib import Path
from mathutils import Vector

ROOT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT))
from geometry import groups

SOURCE=ROOT.parent/'crypt-v1'/'Crypt.glb'
SOURCE_HASH=hashlib.sha256(SOURCE.read_bytes()).hexdigest()
TMP=ROOT/'intermediate';TMP.mkdir(exist_ok=True)

objects=[o for members in groups.values() for o in members]
bpy.context.view_layer.update()

def world_vertices(ob):
    return np.array([tuple(ob.matrix_world@v.co) for v in ob.data.vertices],dtype=np.float64)

def triangles(ob):
    bm=bmesh.new();bm.from_mesh(ob.data)
    bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-7)
    bmesh.ops.triangulate(bm,faces=list(bm.faces))
    tiny=[f for f in bm.faces if f.calc_area()<1e-10]
    if tiny:bmesh.ops.delete(bm,geom=tiny,context='FACES_ONLY')
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    bm.to_mesh(ob.data);bm.free();ob.data.update()

for ob in objects:triangles(ob)

# An occluder is accepted only if all its vertices lie within all face planes:
# that is, it is a closed convex component. A triangle is removed only when
# all three vertices are strictly inside ONE such component. Convexity then
# guarantees the entire triangle is hidden, with no sampled-ray approximation.
occluders=[]
for ob in objects:
    mesh=ob.data;pos=world_vertices(ob)
    ids=np.array([list(f.vertices) for f in mesh.polygons],dtype=np.int32)
    edges={}
    for face in ids:
        for a,b in zip(face,np.roll(face,-1)):
            key=tuple(sorted((int(a),int(b))))
            edges[key]=edges.get(key,0)+1
    if not all(count==2 for count in edges.values()):continue
    cross=np.cross(pos[ids[:,1]]-pos[ids[:,0]],pos[ids[:,2]]-pos[ids[:,0]])
    length=np.linalg.norm(cross,axis=1)
    if np.any(length<1e-10):continue
    normal=cross/length[:,None]
    offset=np.sum(normal*pos[ids[:,0]],axis=1)
    if np.max(pos@normal.T-offset)>1e-6:continue
    occluders.append((ob,pos.min(axis=0),pos.max(axis=0),normal,offset))

removed=0;before=0
for ob in objects:
    mesh=ob.data;pos=world_vertices(ob)
    ids=np.array([list(f.vertices) for f in mesh.polygons],dtype=np.int32)
    before+=len(ids)
    tri=pos[ids];mask=np.zeros(len(ids),dtype=bool)
    tri_min=tri.min(axis=1);tri_max=tri.max(axis=1)
    for other,lo,hi,n,d in occluders:
        if other==ob:continue
        candidate=(~mask)&np.all(tri_min>lo+1e-6,axis=1)&np.all(tri_max<hi-1e-6,axis=1)
        selected=np.flatnonzero(candidate)
        if not len(selected):continue
        sample=tri[selected].reshape(-1,3)
        inside=np.all(sample@n.T-d < -1e-6,axis=1).reshape(-1,3).all(axis=1)
        mask[selected[inside]]=True
    removed+=int(mask.sum())
    if mask.any():
        bm=bmesh.new();bm.from_mesh(mesh);bm.faces.ensure_lookup_table()
        bmesh.ops.delete(bm,geom=[bm.faces[i] for i in np.flatnonzero(mask)],context='FACES_ONLY')
        loose=[v for v in bm.verts if not v.link_faces]
        if loose:bmesh.ops.delete(bm,geom=loose,context='VERTS')
        bm.to_mesh(mesh);bm.free();mesh.update()

# Remove unused default cube UVs; the asset uses only solid material colors.
# Join everything once: the final packer will group by identical PBR behavior.
bpy.ops.object.select_all(action='DESELECT')
for ob in objects:
    for uv in list(ob.data.uv_layers):ob.data.uv_layers.remove(uv)
    ob.select_set(True)
bpy.context.view_layer.objects.active=objects[0]
bpy.ops.object.join();model=bpy.context.object;model.name='Crypt'
bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
bpy.ops.export_scene.gltf(filepath=str(TMP/'Crypt-geometry.glb'),export_format='GLB',
    use_selection=True,export_yup=True,export_cameras=False,export_lights=False,export_animations=False)
model.data.calc_loop_triangles()
report={'source_sha256':SOURCE_HASH,'source_triangles':7822,
        'triangles_after_small_bevel_cleanup':before,'interior_triangles_removed':removed,
        'final_triangles':len(model.data.loop_triangles),'accepted_convex_occluders':len(occluders),
        'original_unchanged':hashlib.sha256(SOURCE.read_bytes()).hexdigest()==SOURCE_HASH}
(ROOT/'geometry_report.json').write_text(json.dumps(report,indent=2)+'\n')
assert report['original_unchanged']
print('GEOMETRY_OPTIMIZED',json.dumps(report),flush=True)
