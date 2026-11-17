"""Optional detail reduction, with the head, hump, legs and main paw pads fixed.

Reuses delivered GLB geometry. Reconnects only mutable geometry before collapse;
per-corner colors retain palette seams. No source file is saved or overwritten.
"""
import json
import sys
from pathlib import Path
import bpy
import bmesh

ROOT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT))
from assets import models,verify_sources

def clear():
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)

def classify(ob):
    # Connectivity analysis only: do not weld the protected source. Some kit
    # parts include coincident faces which a BMesh weld would silently remove.
    vertices=ob.data.vertices;parents=list(range(len(vertices)))
    def find(i):
        while parents[i]!=i:
            parents[i]=parents[parents[i]];i=parents[i]
        return i
    def union(a,b):parents[find(b)]=find(a)
    coincident={}
    for v in vertices:
        key=tuple(round(x,5) for x in v.co)
        if key in coincident:union(v.index,coincident[key])
        else:coincident[key]=v.index
    for p in ob.data.polygons:
        for i in p.vertices[1:]:union(p.vertices[0],i)
    components={}
    for v in vertices:components.setdefault(find(v.index),{'vertices':[],'faces':[]})['vertices'].append(v)
    for p in ob.data.polygons:components[find(p.vertices[0])]['faces'].append(p.index)
    fixed=set();mutable=set();stats=[]
    for component_data in components.values():
        component=component_data['vertices'];faces=component_data['faces']
        points=[ob.matrix_world@current.co for current in component]
        lo=[min(p[i] for p in points) for i in range(3)]
        hi=[max(p[i] for p in points) for i in range(3)]
        spans=[hi[i]-lo[i] for i in range(3)]
        bones={ob.vertex_groups[g.group].name for current in component
               for g in current.groups if g.weight>.0001}
        reason=None
        if bones&{'Head','Jaw','Neck'}:reason='head_neck_and_headgear'
        elif any(b.startswith(('Front','Hind')) for b in bones) and spans[2]>1:reason='long_leg_silhouette'
        elif spans[1]>2.5 and hi[2]>5.9:reason='pointed_hump_and_fitted_cloth'
        elif hi[2]<.6 and spans[0]>.3 and spans[1]>.5:reason='main_paw_pad'
        elif len(faces)<40:reason='small_low_poly_component'
        elif min(spans)<.018:reason='thin_detail'
        ids=set(faces)
        (fixed if reason else mutable).update(ids)
        stats.append({'triangles':len(faces),'fixed':bool(reason),'reason':reason,
                      'bones':sorted(bones),'bounds':[lo,hi]})
    assert not fixed&mutable and len(fixed|mutable)==len(ob.data.polygons)
    return fixed,mutable,stats

def subset(source,faces,name):
    old=source.data
    polygons=[old.polygons[i] for i in sorted(faces)]
    used=sorted({i for p in polygons for i in p.vertices});remap={old:new for new,old in enumerate(used)}
    me=bpy.data.meshes.new(name)
    me.from_pydata([old.vertices[i].co[:] for i in used],[],
                  [[remap[i] for i in p.vertices] for p in polygons]);me.update()
    me.materials.append(old.materials[0])
    ca=old.color_attributes.active_color or old.color_attributes[0]
    colors=me.color_attributes.new(name='Color',type='FLOAT_COLOR',domain='CORNER')
    normals=[];index=0
    for polygon in polygons:
        for li in polygon.loop_indices:
            vi=old.loops[li].vertex_index
            colors.data[index].color=ca.data[vi if ca.domain=='POINT' else li].color
            normals.append(tuple(old.corner_normals[li].vector));index+=1
    for p in me.polygons:p.use_smooth=True
    me.normals_split_custom_set(normals)
    ob=source.copy();ob.name=name;ob.data=me
    bpy.context.collection.objects.link(ob)
    for group in source.vertex_groups:
        if ob.vertex_groups.get(group.name) is None:ob.vertex_groups.new(name=group.name)
    for i,old_index in enumerate(used):
        for group in old.vertices[old_index].groups:
            ob.vertex_groups[group.group].add([i],group.weight,'REPLACE')
    return ob

verify_sources()
arguments=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
for asset in models():
    if arguments and asset['role'] not in arguments:continue
    clear();bpy.ops.import_scene.gltf(filepath=asset['source'])
    rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
    ob=next(o for o in bpy.context.scene.objects if o.type=='MESH')
    assert len(rig.data.bones)==23
    fixed_ids,mutable_ids,components=classify(ob)
    protected=subset(ob,fixed_ids,'Protected')
    mutable=subset(ob,mutable_ids,'ReducedDetails')
    bpy.data.objects.remove(ob,do_unlink=True)
    bm=bmesh.new();bm.from_mesh(mutable.data)
    bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001)
    bm.to_mesh(mutable.data);bm.free();mutable.data.update()
    for p in mutable.data.polygons:p.use_smooth=False
    # Custom imported normals are obsolete on the reduced surfaces.
    bpy.ops.object.select_all(action='DESELECT');mutable.select_set(True)
    bpy.context.view_layer.objects.active=mutable
    mod=mutable.modifiers.new('Reduced ornament geometry','DECIMATE')
    mod.decimate_type='COLLAPSE';mod.ratio=.58;mod.use_collapse_triangulate=True
    while mutable.modifiers.find(mod.name)>0:
        bpy.ops.object.modifier_move_up(modifier=mod.name)
    bpy.ops.object.modifier_apply(modifier=mod.name)
    mutable.data.calc_loop_triangles();after_mutable=len(mutable.data.loop_triangles)
    # Keep the protected geometry as the active mesh so its corner normals survive.
    bpy.ops.object.select_all(action='DESELECT')
    protected.select_set(True);mutable.select_set(True)
    bpy.context.view_layer.objects.active=protected;bpy.ops.object.join()
    protected.name=asset['id']+'_Mesh';protected.data.calc_loop_triangles()
    for vertex in protected.data.vertices:
        total=sum(g.weight for g in vertex.groups)
        assert total>0
        for group in vertex.groups:
            protected.vertex_groups[group.group].add([vertex.index],group.weight/total,'REPLACE')
    bpy.ops.object.select_all(action='DESELECT');protected.select_set(True);rig.select_set(True)
    bpy.context.view_layer.objects.active=rig
    out=ROOT/'intermediate'/(asset['id']+'.glb');out.parent.mkdir(exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(out),export_format='GLB',use_selection=True,
        export_skins=True,export_yup=True,export_animations=False,export_extras=False)
    row={'id':asset['id'],'before':len(fixed_ids)+len(mutable_ids),
         'after':len(protected.data.loop_triangles),'protected_source_faces':sorted(fixed_ids),
         'protected_triangles':len(fixed_ids),'mutable_before':len(mutable_ids),
         'mutable_after':after_mutable,'ratio_on_mutable_geometry':.58,'components':components}
    (ROOT/'intermediate'/(asset['id']+'_stats.json')).write_text(json.dumps(row,indent=2)+'\n')
    print('MOBILE_BUILT',asset['id'],row['before'],'->',row['after'],'protected',len(fixed_ids),flush=True)
print('MOBILE_COMPLETE',verify_sources(),flush=True)
