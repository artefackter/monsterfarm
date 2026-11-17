"""Render reimported GLBs with identical cameras/lighting, including weapon grips."""
import json
import sys
from pathlib import Path
import bpy
from mathutils import Vector
ROOT=Path(__file__).resolve().parent;sys.path.insert(0,str(ROOT))
from compact_glb import GLB
from assets import verify_sources
rows={a['id']:a for a in json.loads((ROOT/'models_report.json').read_text())['models']}
OUT=ROOT/'previews';OUT.mkdir(exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24
scene.cycles.use_denoising=True;scene.cycles.seed=17;scene.render.fps=30
scene.render.image_settings.file_format='PNG';scene.render.resolution_percentage=100
scene.view_settings.view_transform='AgX';scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.13,.18,.23,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.45
bpy.ops.mesh.primitive_plane_add(size=2000,location=(0,0,-.005))
mat=bpy.data.materials.new('Backdrop');mat.use_nodes=True
mat.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.026,.042,.056,1)
mat.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.85;bpy.context.object.data.materials.append(mat)
for point,energy,size,color in [((1,-7,11),1400,8,(1,.90,.79)),((-6,-3,8),1000,6,(.72,.85,1)),((5,4,9),1700,6,(.81,.91,1))]:
    data=bpy.data.lights.new('Softbox','AREA');data.energy=energy;data.shape='DISK';data.size=size;data.color=color
    ob=bpy.data.objects.new('Softbox',data);scene.collection.objects.link(ob);ob.location=point
    ob.rotation_euler=(Vector((0,0,3.5))-ob.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add();camera=bpy.context.object;scene.camera=camera;camera.data.type='ORTHO'
stage=set(bpy.data.objects)

def load(path,clip):
    for ob in list(bpy.data.objects):
        if ob not in stage:bpy.data.objects.remove(ob,do_unlink=True)
    for action in list(bpy.data.actions):bpy.data.actions.remove(action)
    bpy.ops.import_scene.gltf(filepath=str(path))
    rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
    rig.animation_data.action=None;found=False
    for track in rig.animation_data.nla_tracks:
        match=clip in track.name;track.mute=not match;found|=match
    assert found,(path,clip,[t.name for t in rig.animation_data.nla_tracks])
    scene.frame_set(0);bpy.context.view_layer.update();rig.hide_render=True
    return rig

def center_of_part(row,profile,suffix):
    deps=bpy.context.evaluated_depsgraph_get()
    if profile=='original':
        ob=next(o for o in bpy.context.scene.objects if o.type=='MESH' and o.name.endswith('__'+suffix))
        points=[ob.matrix_world@v.co for v in ob.evaluated_get(deps).data.vertices]
    else:
        g=GLB(ROOT/row['output']);r=next(v for k,v in row['stats']['part_ranges'].items() if k.endswith('__'+suffix))
        primitive=next(m for m in g.doc['meshes'] if m['name']==r['mesh'])['primitives'][0]
        indices=g.array(primitive['indices'],False).reshape(-1)
        ids=set(int(i) for i in indices[r['triangle_start']*3:(r['triangle_start']+r['triangles'])*3])
        ob=bpy.data.objects[r['mesh']];me=ob.evaluated_get(deps).data
        points=[ob.matrix_world@me.vertices[i].co for i in ids]
    return Vector(tuple((min(v[i] for v in points)+max(v[i] for v in points))/2 for i in range(3)))

cases=[('Granny','Idle','full'),('Granny','Aggressive','full'),
       ('Granny','Idle','grip'),('Granny','Aggressive','grip'),
       ('Grandfather_King','Idle','full'),('Grandfather_King','Aggressive','full'),
       ('Grandfather_King','Idle','weapon'),('Slenderman_King','Idle','full'),
       ('Slendrina_Punk','Aggressive','full'),('SpiderMom_Knight','Idle','full'),('SpiderMom_Assassin','Aggressive','full')]
manifest=[]
for name,clip,view in cases:
    row=rows[name];person=row['character'];key=name+'_'+clip+'_'+view
    for profile in ('original','optimized'):
        path=row['source'] if profile=='original' else ROOT/row['output'];load(path,clip)
        target=Vector((0,0,4.15 if person=='Slenderman' else 3.48 if person=='Slendrina' else 2.07 if person=='SpiderMom' else 3.35))
        angle=Vector((-10,-15,1.4) if person=='Grandfather' else (4,-17,2 if person=='SpiderMom' else 1.5))
        width=11.4 if person=='Slenderman' else 9.4 if person in ('Slendrina','SpiderMom') else 8.9
        res=(800,600) if person=='SpiderMom' else (600,800)
        if view=='grip':target=center_of_part(row,profile,'HandR');angle=Vector((-.9,-1.6,.6));width=.95;res=(700,700)
        elif view=='weapon':target=Vector((-.2,-.65,3.60));angle=Vector((-4,-6,1.6));width=3.9;res=(800,650)
        camera.location=target+angle;camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.ortho_scale=width
        scene.render.resolution_x,scene.render.resolution_y=res
        folder=OUT/profile;folder.mkdir(exist_ok=True);file=folder/(key+'.png')
        scene.render.filepath=str(file);bpy.ops.render.render(write_still=True)
        manifest.append({'case':key,'id':name,'character':person,'clip':clip,'view':view,'profile':profile,'file':str(file.relative_to(ROOT))})
    print('COMPARISON_RENDERED',key,flush=True)
(ROOT/'render_manifest.json').write_text(json.dumps({'renders':manifest,'source_files_unchanged':verify_sources()},indent=2)+'\n')
print('COMPARISON_RENDERS_COMPLETE',len(manifest),flush=True)
