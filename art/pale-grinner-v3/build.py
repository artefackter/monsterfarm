"""Build standalone models and render their real geometry for visual approval."""
import bpy
import json
import math
import sys
from pathlib import Path
from mathutils import Vector

ROOT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT))
import creatures
import kit

MODELS=ROOT/'models';PREVIEWS=ROOT/'previews';GEOMETRY=ROOT/'geometry'
for folder in (MODELS,PREVIEWS,GEOMETRY):folder.mkdir(exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
kit.ASSETS.clear();creatures.build()
if '--' in sys.argv:
    selected=set(sys.argv[sys.argv.index('--')+1:])
    for key in list(kit.ASSETS):
        if selected and key not in selected:del kit.ASSETS[key]
manifest,baked,total=kit.export_all(str(GEOMETRY))
for name,imports in creatures.IMPORTED.items():
    if name not in kit.ASSETS:continue
    for item in imports:
        entry=item['entry'];pn=entry['part']
        manifest.setdefault(name,[]).append(entry)
        verts,colors,tris=item['verts'],item['colors'],item['tris']
        baked[(name,pn)]=(verts,colors,tris)
        (GEOMETRY/(name+'.'+pn+'.json')).write_text(json.dumps({
            'source':entry['source_mesh'],'authoring_axes':'Z up, front -Y',
            'v':[list(v) for v in verts],'c':colors,'t':tris},separators=(',',':')))
        total+=len(tris)//3
(GEOMETRY/'_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
(GEOMETRY/'_rig.json').write_text(json.dumps(creatures.RIGS,indent=2)+'\n')
scene=bpy.context.scene


def material(name,color=None):
    m=bpy.data.materials.new(name);m.use_nodes=True
    bs=m.node_tree.nodes.get('Principled BSDF')
    bs.inputs['Roughness'].default_value=.84
    bs.inputs['Specular IOR Level'].default_value=.22
    if color:
        rgb=kit._rgb(color)
        bs.inputs['Base Color'].default_value=tuple(v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in rgb)+(1,)
    else:
        vc=m.node_tree.nodes.new('ShaderNodeVertexColor');vc.layer_name='Col'
        m.node_tree.links.new(vc.outputs['Color'],bs.inputs['Base Color'])
    return m


collections={};rigs={};meshes={};stats={}
for name,entries in manifest.items():
    bpy.ops.object.select_all(action='DESELECT')
    co=bpy.data.collections.new(name);scene.collection.children.link(co);collections[name]=co
    data=bpy.data.armatures.new(name+'_Skeleton')
    rig=bpy.data.objects.new(name+'_Rig',data);co.objects.link(rig);rigs[name]=rig
    rig.show_in_front=True
    rig['Status']='Draft; appearance awaiting owner approval; not integrated'
    rig['RigType']='Custom segmented NPC skeleton, not R15; no animation clips'
    rig['ReferenceNumber']=creatures.DETAILS[name]['reference']
    bpy.context.view_layer.objects.active=rig;rig.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    for bn,(head,tail,parent) in creatures.RIGS[name].items():
        b=data.edit_bones.new(bn);b.head=head;b.tail=tail;b.use_connect=False
    for bn,(head,tail,parent) in creatures.RIGS[name].items():
        if parent:data.edit_bones[bn].parent=data.edit_bones[parent]
    bpy.ops.object.mode_set(mode='OBJECT');rig.select_set(False)
    mat=material(name+'_VertexColors');objects=[]
    for entry in entries:
        pn=entry['part'];verts,colors,tris=baked[(name,pn)]
        me=bpy.data.meshes.new(name+'__'+pn)
        me.from_pydata([tuple(v) for v in verts],[],[tris[i:i+3] for i in range(0,len(tris),3)])
        me.update()
        if pn in ('Portrait','Hair'):
            for face in me.polygons:face.use_smooth=True
        ca=me.color_attributes.new(name='Col',type='BYTE_COLOR',domain='POINT')
        for datum,color in zip(ca.data,colors):datum.color_srgb=(*color,1)
        me.materials.append(mat)
        ob=bpy.data.objects.new(name+'__'+pn,me);co.objects.link(ob);ob.parent=rig
        groups={}
        for v in me.vertices:
            for bn,w in creatures.skin_weights(pn,v.co,entry['attach']).items():
                if w<1e-7:continue
                if bn not in groups:groups[bn]=ob.vertex_groups.new(name=bn)
                groups[bn].add([v.index],w,'REPLACE')
        mod=ob.modifiers.new('Segment skin','ARMATURE');mod.object=rig
        objects.append(ob)
    # Game-oriented single mesh/material while keeping named bone groups.
    for ob in objects:ob.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.object.join()
    mesh=bpy.context.object;mesh.name=name+'_Mesh';meshes[name]=mesh
    mesh.data.calc_loop_triangles()
    assert all(t.area>1e-12 for t in mesh.data.loop_triangles),name+' has a degenerate triangle'
    assert all(abs(sum(g.weight for g in v.groups)-1)<1e-6 for v in mesh.data.vertices)
    assert len(mesh.data.materials)==1
    assert len(mesh.data.loop_triangles)<26000
    coords=[v.co for v in mesh.data.vertices]
    lo=[min(v[i] for v in coords) for i in range(3)];hi=[max(v[i] for v in coords) for i in range(3)]
    stats[name]={'reference':creatures.DETAILS[name]['reference'],
                 'source_asset':creatures.DETAILS[name].get('source_asset'),
                 'review_baseline_only':creatures.DETAILS[name].get('review_baseline_only',False),
                 'triangles':len(mesh.data.loop_triangles),'vertices':len(mesh.data.vertices),
                 'bones':len(data.bones),'meshes':1,'materials':1,'textures':0,'animation_clips':0,
                 'bounds':[lo,hi],'height':round(hi[2]-lo[2],3),
                 'interpretation':creatures.DETAILS[name]['interpretation']}
    bpy.ops.object.select_all(action='DESELECT');mesh.select_set(True);rig.select_set(True)
    bpy.context.view_layer.objects.active=rig
    bpy.ops.export_scene.gltf(filepath=str(MODELS/(name+'.glb')),export_format='GLB',use_selection=True,
                              export_skins=True,export_animations=False,export_yup=True)
    bpy.ops.export_scene.fbx(filepath=str(MODELS/(name+'.fbx')),use_selection=True,
                            object_types={'ARMATURE','MESH'},add_leaf_bones=False,bake_anim=False,
                            axis_forward='-Z',axis_up='Y',mesh_smooth_type='FACE')
    print('EXPORTED',name,json.dumps(stats[name]),flush=True)

# Review-only scene; exports above contain only a mesh and its rig.
scene.render.engine='CYCLES';scene.cycles.samples=12;scene.cycles.use_denoising=True
scene.render.resolution_percentage=100;scene.render.image_settings.file_format='PNG'
scene.view_settings.view_transform='AgX'
scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.16,.19,.23,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.52
stage=bpy.data.collections.new('Presentation_only');scene.collection.children.link(stage)
def stage_object(ob):
    for co in list(ob.users_collection):co.objects.unlink(ob)
    stage.objects.link(ob);return ob
bpy.ops.mesh.primitive_plane_add(size=2000,location=(0,0,-.02))
stage_object(bpy.context.object).data.materials.append(material('Backdrop','29343E'))
for at,energy,size,color in [((2,-8,11),1800,7,(1,.91,.82)),((-7,-3,7),1300,6,(.77,.87,1)),
                            ((4,5,10),2300,6,(.84,.91,1))]:
    ld=bpy.data.lights.new('Softbox','AREA');ld.energy=energy;ld.shape='DISK';ld.size=size;ld.color=color
    ob=bpy.data.objects.new('Softbox',ld);stage.objects.link(ob);ob.location=at
    ob.rotation_euler=(Vector((0,0,3.6))-ob.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add();cam=stage_object(bpy.context.object)
cam.name='ReviewCamera';cam.data.type='ORTHO';scene.camera=cam


def frame_model(name,angle,res=(1000,1200)):
    lo,hi=stats[name]['bounds'];target=Vector(tuple((lo[i]+hi[i])/2 for i in range(3)))
    cam.location=target+Vector(angle)
    cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
    inverse=cam.rotation_euler.to_matrix().transposed()
    pts=[inverse@(Vector((x,y,z))-target) for x in (lo[0],hi[0])
         for y in (lo[1],hi[1]) for z in (lo[2],hi[2])]
    width=max(v.x for v in pts)-min(v.x for v in pts)
    height=max(v.y for v in pts)-min(v.y for v in pts)
    aspect=res[0]/res[1]
    # ortho_scale is the size along the larger image dimension.
    cam.data.ortho_scale=max(height*max(1,aspect),width*max(1,1/aspect))*1.13
    scene.render.resolution_x,scene.render.resolution_y=res


def render(filename):
    scene.render.filepath=str(PREVIEWS/(filename+'.png'))
    bpy.ops.render.render(write_still=True)


for name,co in collections.items():
    for other,otherco in collections.items():
        otherco.hide_render=other!=name;otherco.hide_viewport=other!=name
    for suffix,angle,res in [('ThreeQuarter',(11,-18,3.0),(700,800)),
                             ('Side',(18,-.4,1.3),(700,700)),
                             ('Back',(-7,18,3.0),(700,800))]:
        framing='ParasiteAdapted' if name=='ParasiteExisting' else name
        frame_model(framing,angle,res);render(name+'_'+suffix)
    detail=creatures.DETAILS[name];target=Vector(detail['focus'])
    cam.location=target+Vector((0,-16,0))
    cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
    cam.data.ortho_scale=detail['close_scale']
    scene.render.resolution_x=700;scene.render.resolution_y=700
    render(name+'_Detail')
    cam.location=target+Vector((9,-14,.35));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();render(name+'_PortraitQuarter')
    frame_model(name,(11,-18,3.0),(700,800))
    bpy.ops.object.select_all(action='DESELECT');rigs[name].select_set(True)
    bpy.context.view_layer.objects.active=rigs[name]
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type=='VIEW_3D':
                area.spaces.active.region_3d.view_perspective='CAMERA'
                area.spaces.active.shading.type='MATERIAL'
                area.spaces.active.overlay.show_overlays=False
    bpy.context.preferences.filepaths.save_version=0
    review_scene=scene.copy();review_scene.name=name+' Review'
    for child in list(review_scene.collection.children):
        if child not in (co,stage):review_scene.collection.children.unlink(child)
    bpy.data.libraries.write(str(MODELS/(name+'.blend')), {review_scene}, fake_user=True)
    bpy.data.scenes.remove(review_scene)
    print('RENDERED',name,flush=True)

(ROOT/'report.json').write_text(json.dumps({'status':'awaiting_visual_approval','models':stats,
    'authoring_axes':{'up':'Z','front':'-Y'},'export_axes':{'up':'Y'},
    'unit':'One intended Roblox stud; scale not verified in Studio',
    'rig':'Custom rigid-segment NPC skeletons; not Roblox R15',
    'game_integrated':False,'studio_modified':False,'uploaded':False,
    'scope':'PaleGrinner revision 3. Asymmetric hair and clean mouth and chin.',
    'previews':'Rendered from the actual exported source geometry, no paintovers'},indent=2)+'\n')
print('SRP_REVIEW_COMPLETE',total,flush=True)
