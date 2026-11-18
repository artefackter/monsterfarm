"""Fit the game's Hooded Stranger costume set to the approved Pale Grinner V3."""
import json, math, sys
from pathlib import Path
import bpy
from mathutils import Vector
ROOT = Path(__file__).resolve().parent
sys.path[:0] = [str(ROOT.parent/'hooded-stranger-forms-v1'), str(ROOT.parent/'blender')]
import outfits, kit
BASE = ROOT.parent/'pale-grinner-v3/models/PaleGrinner.blend'
roles = ['Farmer','Miner','Knight','King','Punk','Assassin']
report = {}

def fit(part, role, rig):
    """Map wardrobe landmarks to this character's crown, shoulders, waist and knees."""
    if part.name.startswith('Role_Bracer'):
        bone = rig.data.bones[part.attach]
        axis = (bone.tail_local-bone.head_local).normalized()
        for vertex in part.bm.verts:
            center = bone.head_local + axis * (vertex.co-bone.head_local).dot(axis)
            vertex.co = center + .71*(vertex.co-center)
        return
    for vertex in part.bm.verts:
        x,y,z = vertex.co
        if part.attach == 'Head':
            base = {'King':6.78,'Miner':6.78,'Farmer':6.77,'Knight':6.66,'Punk':6.99}[role]
            target = {'King':7.21,'Miner':7.21,'Farmer':7.22,'Knight':7.10,'Punk':7.49}[role]
            vertex.co = (x*.76,y*.72-.015,target+(z-base)*.88)
        elif part.name.startswith('Role_Shoulder'):
            vertex.co = (x*.76,y*.87,z+.10)
        elif part.name.startswith('Role_Knee'):
            vertex.co = (x*1.03,y+.24,z)
        else:
            front_offset = 0.
            if role in ('Farmer','Miner') and part.name == 'Role_Chest' and y < -.12:
                front_offset = min(.13, max(0.,(-y-.12)*.55))
            vertex.co = (x*.85,y*.90+.035-front_offset,z)
    # Source costume and target rig use opposite side suffix conventions.
    if part.name.startswith(('Role_Shoulder','Role_Knee')):
        side = 'L' if part.attach.endswith('R') else 'R'
        part.attach = ('Arm' if part.name.startswith('Role_Shoulder') else 'Shin')+side

def color_clothing(mesh, role):
    col=mesh.data.color_attributes['Col']
    palette=outfits.ROLES[role]
    groups={}
    for vertex in mesh.data.vertices:
        joint=mesh.vertex_groups[vertex.groups[0].group].name
        if joint in ('Chest','ArmL','ArmR','ForearmL','ForearmR'):
            channel='pants' if role in ('Farmer','Miner') and joint=='Chest' and vertex.co.z<3.3 else 'shirt'
        elif joint in ('LegL','LegR','ShinL','ShinR'):
            channel='pants'
        else:
            continue
        groups.setdefault(channel,[]).append(vertex.index)
    for key,ids in groups.items():
        rgb=kit._rgb(palette[key])
        values=[sum(col.data[i].color_srgb[:3])/3 for i in ids]
        avg=sum(values)/len(values)
        for i,val in zip(ids,values):
            shade=max(.65,min(1.15,val/max(avg,.001)))
            col.data[i].color_srgb=(*(c*shade for c in rgb),1)

def costume_piece(part, collection, rig, material, bvh):
    verts,_,colors,indices=kit.bake_part(part,bvh)
    faces=[]
    for i in range(0,len(indices),3):
        tri=indices[i:i+3]
        a,b,c=(verts[j] for j in tri)
        if (b-a).cross(c-a).length_squared>1e-16:faces.append(tri)
    data=bpy.data.meshes.new(part.name)
    data.from_pydata(verts,[],faces);data.update();data.materials.append(material)
    col=data.color_attributes.new(name='Col',type='BYTE_COLOR',domain='POINT')
    for entry,color in zip(col.data,colors):entry.color_srgb=(*color,1)
    ob=bpy.data.objects.new(part.name,data);collection.objects.link(ob)
    assert part.attach in rig.data.bones and not part.attach.startswith('Hand')
    ob.parent=rig
    ob.vertex_groups.new(name=part.attach).add(list(range(len(verts))),1,'REPLACE')
    return ob

def render(scene,name,label,direction,center,scale,size):
    camera=scene.camera
    camera.location=Vector(center)+Vector(direction)
    camera.rotation_euler=(-Vector(direction)).to_track_quat('-Z','Y').to_euler()
    camera.data.ortho_scale=scale
    scene.render.resolution_x,scene.render.resolution_y=size
    scene.render.filepath=str(ROOT/'previews'/f'{name}_{label}.png')
    bpy.ops.render.render(write_still=True)

for role in roles:
    name='PaleGrinner'+role
    bpy.ops.wm.open_mainfile(filepath=str(BASE))
    scene=bpy.context.scene
    collection=bpy.data.collections['PaleGrinner']
    rig=next(o for o in collection.objects if o.type=='ARMATURE')
    mesh=next(o for o in collection.objects if o.type=='MESH')
    mesh.name=name+'_Mesh';rig.name=name+'_Rig'
    color_clothing(mesh,role)
    kit.ASSETS.clear()
    asset=outfits.build(role,rig)
    for part in asset.parts:fit(part,role,rig)
    bvh=kit._asset_bvh(asset)
    pieces=[costume_piece(p,collection,rig,mesh.data.materials[0],bvh) for p in asset.parts]
    bpy.ops.object.select_all(action='DESELECT')
    for ob in [mesh,*pieces]:ob.select_set(True)
    bpy.context.view_layer.objects.active=mesh
    bpy.ops.object.join()
    rig.select_set(True)
    mesh.data.calc_loop_triangles()
    report[name]={'role':role,'label':outfits.ROLES[role]['ru'],'triangles':len(mesh.data.loop_triangles),'bones':len(rig.data.bones)}
    path=ROOT/'models'/name
    bpy.ops.export_scene.gltf(filepath=str(path.with_suffix('.glb')),use_selection=True,export_animations=False)
    bpy.ops.export_scene.fbx(filepath=str(path.with_suffix('.fbx')),use_selection=True,object_types={'MESH','ARMATURE'},add_leaf_bones=False,bake_anim=False)
    render(scene,name,'Back',(-5,17,1.7),(0,0,4),9.1,(550,720))
    render(scene,name,'Head',(3,-18,.5),(0,0,6.55),3.9,(560,600))
    render(scene,name,'Front',(4,-18,1.55),(0,0,4.04),9.05,(700,840))
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.wm.save_as_mainfile(filepath=str(path.with_suffix('.blend')))
(ROOT/'report.json').write_text(json.dumps({'models':report},indent=2,ensure_ascii=False))
