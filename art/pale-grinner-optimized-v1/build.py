"""Thin the two approved, ring-based surfaces using their geometry and painted colour."""
import json
import sys
from math import pi
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Vector
from mathutils.kdtree import KDTree

ROOT = Path(__file__).resolve().parent
V4 = ROOT.parent / "pale-grinner-v4"
sys.path.insert(0, str(V4))
from lunge import head_transform


def retain_rows(features, parameters, max_span):
    """Polyline simplification, using the worst error over every sample in a ring."""
    keep = {0, len(parameters)-1}
    stack = [(0, len(parameters)-1)]
    while stack:
        lo, hi = stack.pop()
        if hi-lo < 2:
            continue
        t = (parameters[lo+1:hi]-parameters[lo])/(parameters[hi]-parameters[lo])
        shape = (-1,) + (1,)*(features.ndim-1)
        predicted = features[lo]+t.reshape(shape)*(features[hi]-features[lo])
        errors = np.abs(features[lo+1:hi]-predicted).reshape(hi-lo-1,-1).max(axis=1)
        best = int(errors.argmax())
        if errors[best] <= 1 and hi-lo <= max_span:
            continue
        mid = lo+1+best if errors[best] > 1 else (hi+lo)//2
        keep.add(mid)
        stack.extend(((lo,mid),(mid,hi)))
    return sorted(keep)


def strip(top,bottom,width):
    """Triangulate between two independently sampled circular rows without T-junctions."""
    top = top + [(width,top[0][1])]
    bottom = bottom + [(width,bottom[0][1])]
    a=b=0
    while a<len(top)-1 or b<len(bottom)-1:
        if b==len(bottom)-1 or (a<len(top)-1 and
                top[a][0]+top[a+1][0] <= bottom[b][0]+bottom[b+1][0]):
            yield (top[a][1],bottom[b][1],top[a+1][1])
            a+=1
        else:
            yield (top[a][1],bottom[b][1],bottom[b+1][1])
            b+=1


def surface_faces(part,source):
    positions=np.array(source["v"])
    colors=np.array(source["c"])
    portrait=part=="Portrait"
    if portrait:
        sections=[(0,66,59)]
    else:
        sections=[(0,19,28)]+[(offset,20,7) for offset in range(19*28+2,len(positions),142)]
    triangles=[]
    for offset,rows,columns in sections:
        count=rows*columns
        coords=positions[offset:offset+count].reshape(rows,columns,3)
        paint=colors[offset:offset+count].reshape(rows,columns,3)
        features=np.concatenate((coords/(.012 if portrait else .010),
                                 paint/(.038 if portrait else .028)),axis=-1)
        axis=-coords[:,0,2] if portrait else np.arange(rows)
        levels=retain_rows(features,axis,7 if portrait else 4)
        rings=[]
        for row in levels:
            # Front and back are parameterized at different angular densities.
            if portrait:
                spans=[(0,49),(49,59)]
            elif columns==7:
                spans=[]
            else:
                spans=[(0,14),(14,28)]
            kept=set(range(columns)) if not spans else set()
            closed=np.vstack((features[row],features[row,:1]))
            for lo,hi in spans:
                chosen=retain_rows(closed[lo:hi+1],np.arange(hi-lo+1),5)
                kept.update((lo+i)%columns for i in chosen)
            rings.append([(i,offset+row*columns+i) for i in sorted(kept)])
        # Use actual angles for the zipper at the sparsely sampled back of the skull.
        def parameter(ring):
            return [(i*pi/49 if i<=49 else pi+(i-49)*pi/10,idx) for i,idx in ring]
        for upper,lower in zip(rings,rings[1:]):
            tris=strip(parameter(upper),parameter(lower),2*pi) if portrait else strip(upper,lower,columns)
            triangles.extend(tri if portrait else tri[::-1] for tri in tris)
        for cap,ring in enumerate((rings[0],rings[-1])):
            for j,(_,a) in enumerate(ring):
                b=ring[(j+1)%len(ring)][1]
                triangles.append((offset+count+cap,b,a) if cap==0 else (offset+count+cap,a,b))
    assert max(max(f) for f in triangles)<len(positions)
    return triangles


def replace_surfaces(mesh,aggressive):
    head=mesh.vertex_groups["Head"].index
    candidates=[v for v in mesh.data.vertices if any(g.group==head and g.weight==1 for g in v.groups)]
    tree=KDTree(len(candidates))
    for v in candidates: tree.insert(v.co,v.index)
    tree.balance()
    bm=bmesh.new()
    bm.from_mesh(mesh.data)
    bm.verts.ensure_lookup_table()
    counts={}
    for part in ("Portrait","Hair"):
        path=ROOT.parent/"pale-grinner-v3"/"geometry"/f"PaleGrinner.{part}.json"
        source=json.loads(path.read_text())
        lookup=[]
        transform=head_transform(1) if aggressive else None
        for xyz in source["v"]:
            co=Vector(xyz)
            _,index,distance=tree.find(transform@co if aggressive else co)
            assert distance<.00001,(part,index,distance)
            lookup.append(bm.verts[index])
        assert len(set(lookup))==len(lookup)
        existing={f for v in lookup for f in v.link_faces}
        assert len(existing)==len(source["t"])//3
        for face in existing: bm.faces.remove(face)
        reduced=surface_faces(part,source)
        for tri in reduced:
            face=bm.faces.new(tuple(lookup[i] for i in tri))
            face.smooth=True
        counts[part]=[len(existing),len(reduced)]
    for edge in list(bm.edges):
        if not edge.link_faces: bm.edges.remove(edge)
    for vertex in list(bm.verts):
        if not vertex.link_faces: bm.verts.remove(vertex)
    bm.to_mesh(mesh.data)
    bm.free()
    mesh.data.update()
    return counts


def export(name,spec):
    bpy.ops.wm.open_mainfile(filepath=str(V4/"models"/(name+".blend")))
    scene=bpy.context.scene
    mesh=bpy.data.objects[name+"_Mesh"]
    rig=mesh.find_armature()
    aggressive=bool(spec["animations"])
    changes=replace_surfaces(mesh,aggressive)
    bpy.ops.object.select_all(action="DESELECT")
    mesh.select_set(True);rig.select_set(True)
    bpy.context.view_layer.objects.active=rig
    target=ROOT/"models"/name
    bpy.ops.export_scene.gltf(filepath=str(target.with_suffix(".glb")),use_selection=True,
                              export_animations=aggressive,export_rest_position_armature=True)
    bpy.ops.export_scene.fbx(filepath=str(target.with_suffix(".fbx")),use_selection=True,
                             object_types={"MESH","ARMATURE"},add_leaf_bones=False,bake_anim=aggressive,
                             bake_anim_use_nla_strips=False,bake_anim_use_all_actions=False,
                             bake_anim_simplify_factor=.15)
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.wm.save_as_mainfile(filepath=str(target.with_suffix(".blend")),compress=True)
    # Same renderer, stage, pose and camera as the approved review.
    scene.render.filepath=str(ROOT/"previews"/(name+".png"))
    bpy.ops.render.render(write_still=True)
    mesh.data.calc_loop_triangles()
    count=len(mesh.data.loop_triangles)
    assert count==spec["triangles"]-sum(a-b for a,b in changes.values())
    return {**spec,"triangles":count,"original_triangles":spec["triangles"],"surfaces":changes}


for folder in ("models","previews"): (ROOT/folder).mkdir(exist_ok=True)
original=json.loads((V4/"report.json").read_text())
chosen=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else list(original)
path=ROOT/"report.json"
report=json.loads(path.read_text()) if path.exists() else {}
for name in chosen:
    report[name]=export(name,original[name])
    path.write_text(json.dumps(report,indent=2)+"\n")
