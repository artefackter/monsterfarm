"""Reduce noncritical costume/cloth geometry, keeping face, teeth, hands and instrument."""
import sys
import json
from pathlib import Path
import bpy
import bmesh

ROOT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT))
from build import source_assets

PROTECTED={'Face','BrowRidges','Eyes','EyeMakeup','UpperGums','LowerJaw',
           'UpperTeeth','LowerTeeth','Hand.L','Hand.R','Thumb.L','Thumb.R',
           'Biwa','Role_InstrumentTrim'}
PROTECTED.update({'Role_Headgear','FlowerCrown'})
args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
assets=[a for a in source_assets() if not args or a['role'] in args]
for asset in assets:
    bpy.ops.wm.open_mainfile(filepath=asset['blend'])
    rigs=[o for o in bpy.context.scene.objects if o.type=='ARMATURE']
    assert len(rigs)==1;rig=rigs[0]
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers)]
    stats=[]
    for ob in meshes:
        ob.data.calc_loop_triangles();before=len(ob.data.loop_triangles)
        protected=ob.name in PROTECTED or ob.name.startswith('Finger')
        if not protected and before>=70:
            # The art kit intentionally splits corners at every hard normal.
            # Reconnect coincident geometry before collapse, retaining the
            # per-corner palette so that costume/color boundaries stay sharp.
            ca=ob.data.color_attributes.get('Color')
            if ca is not None and ca.domain=='POINT':
                colors=[tuple(ca.data[loop.vertex_index].color_srgb) for loop in ob.data.loops]
                ob.data.color_attributes.remove(ca)
                ca=ob.data.color_attributes.new(name='Color',type='BYTE_COLOR',domain='CORNER')
                for color,value in zip(ca.data,colors):color.color_srgb=value
            bm=bmesh.new();bm.from_mesh(ob.data)
            bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001)
            # Keep small ornaments and very thin seams as whole connected islands.
            # Collapsing their tiny tubes/beads would save little and can visibly
            # break the hem, hat weave or chains.
            mark=bm.verts.layers.int.new('mobile_keep')
            seen=set();fixed_count=0
            for vertex in bm.verts:
                if vertex in seen:continue
                stack=[vertex];component=[];seen.add(vertex)
                while stack:
                    current=stack.pop();component.append(current)
                    for edge in current.link_edges:
                        neighbor=edge.other_vert(current)
                        if neighbor not in seen:seen.add(neighbor);stack.append(neighbor)
                lo=[min(v.co[i] for v in component) for i in range(3)]
                hi=[max(v.co[i] for v in component) for i in range(3)]
                spans=[hi[i]-lo[i] for i in range(3)]
                keep=min(spans)<.035 or sum(s*s for s in spans)<.35**2
                for v in component:v[mark]=int(keep)
                if keep:fixed_count+=len(component)
            fixed_mesh=None
            mutable_count=len(bm.verts)-fixed_count
            if fixed_count and mutable_count:
                fixed=bm.copy();fixed_mark=fixed.verts.layers.int.get('mobile_keep')
                bmesh.ops.delete(fixed,geom=[v for v in fixed.verts if not v[fixed_mark]],context='VERTS')
                fixed_mesh=bpy.data.meshes.new('Mobile_PreservedOrnaments')
                fixed.to_mesh(fixed_mesh);fixed.free()
                bmesh.ops.delete(bm,geom=[v for v in bm.verts if v[mark]],context='VERTS')
            bm.to_mesh(ob.data);bm.free();ob.data.update()
            bpy.ops.object.select_all(action='DESELECT');ob.select_set(True)
            bpy.context.view_layer.objects.active=ob
            if mutable_count:
                mod=ob.modifiers.new('Mobile_Geometry','DECIMATE')
                mod.decimate_type='COLLAPSE';mod.ratio=.48;mod.use_collapse_triangulate=True
                # Collapse in bind space, before the skeleton deformation modifier.
                while ob.modifiers.find(mod.name)>0:
                    bpy.ops.object.modifier_move_up(modifier=mod.name)
                bpy.ops.object.modifier_apply(modifier=mod.name)
            if fixed_mesh is not None:
                combined=bmesh.new();combined.from_mesh(ob.data);combined.from_mesh(fixed_mesh)
                combined.to_mesh(ob.data);combined.free();bpy.data.meshes.remove(fixed_mesh)
                ob.data.update()
        ob.data.calc_loop_triangles()
        stats.append({'name':ob.name,'protected':protected,'before':before,'after':len(ob.data.loop_triangles)})
    bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
    for ob in meshes:ob.select_set(True)
    bpy.context.view_layer.objects.active=rig
    output=ROOT/'intermediate'/(asset['id']+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(output),export_format='GLB',use_selection=True,
                             export_skins=True,export_animations=False,export_yup=True)
    (ROOT/'intermediate'/(asset['id']+'_stats.json')).write_text(json.dumps(stats,indent=2)+'\n')
    print('MOBILE_GEOMETRY',asset['id'],sum(r['before'] for r in stats),'->',sum(r['after'] for r in stats),flush=True)
