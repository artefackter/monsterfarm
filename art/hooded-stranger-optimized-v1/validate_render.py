"""Reimport and pose both versions in Blender, compare geometry, render review pairs."""
import json
from pathlib import Path
import bpy
from mathutils import Vector

ROOT=Path(__file__).resolve().parent
ART=ROOT.parent
report=json.loads((ROOT/'report.json').read_text())
BASE=ART/'hooded-stranger-v2/models/HoodedStranger.blend'
OUT=ROOT/'previews'
OUT.mkdir(exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(BASE))
for ob in list(bpy.data.objects):
    if ob.type=='ARMATURE' or (ob.type=='MESH' and ob.name!='Plane'):
        bpy.data.objects.remove(ob,do_unlink=True)
scene=bpy.context.scene
scene.render.resolution_percentage=100
scene.cycles.samples=24
scene.cycles.seed=0
scene.cycles.use_denoising=True
camera=scene.camera


def import_model(path):
    before=set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(path),merge_vertices=False)
    imported=set(bpy.data.objects)-before
    rig=next(o for o in imported if o.type=='ARMATURE')
    shapes={b.custom_shape for b in rig.pose.bones if b.custom_shape}
    for shape in shapes:
        shape.hide_render=True
    meshes={o.name:o for o in imported if o.type=='MESH' and o not in shapes}
    assert len(rig.data.bones)==28
    for ob in meshes.values():
        assert any(m.type=='ARMATURE' and m.object==rig for m in ob.modifiers)
        assert all(abs(sum(g.weight for g in v.groups)-1)<.0002 for v in ob.data.vertices)
    return imported,rig,meshes


def evaluated(ob):
    deps=bpy.context.evaluated_depsgraph_get()
    ev=ob.evaluated_get(deps);me=ev.to_mesh()
    result=[ev.matrix_world@v.co for v in me.vertices]
    ev.to_mesh_clear()
    return result


def set_pose(rig,bone):
    for b in rig.pose.bones:
        b.rotation_mode='XYZ';b.rotation_euler=(0,0,0)
    if bone:
        rig.pose.bones[bone].rotation_euler.x=.20
    bpy.context.view_layer.update()


def render(name,head=False):
    look=Vector((0,-.05,6.0) if head else (0,0,3.73))
    camera.location=look+Vector((2.4,-16,.20) if head else (4,-16,1.15))
    camera.rotation_euler=(look-camera.location).to_track_quat('-Z','Y').to_euler()
    camera.data.ortho_scale=3.05 if head else 9.05
    scene.render.resolution_x,scene.render.resolution_y=(700,700) if head else (630,870)
    scene.render.filepath=str(OUT/(name+'.png'))
    bpy.ops.render.render(write_still=True)


results=[]
poses=[None,'Head','UpperArmR','Finger2L','ShinL','Spine']
for item in report['models']:
    snapshots={}
    for profile,path in [('original',ART/item['source']),('optimized',ROOT/item['file'])]:
        imported,rig,meshes=import_model(path)
        if profile=='optimized':
            assert set(meshes)=={'StrangerBody','Face'}
            images=[n.image for m in meshes['Face'].data.materials for n in m.node_tree.nodes if n.type=='TEX_IMAGE' and n.image]
            assert images and all(tuple(i.size)==(256,256) for i in images)
        for bone in poses:
            set_pose(rig,bone)
            rows={name:evaluated(ob) for name,ob in meshes.items()}
            if profile=='original':
                snapshots[bone]=rows
            else:
                errors=[]
                for name,part in item['part_ranges'].items():
                    start=part['vertex_start'];end=start+part['vertex_count']
                    aa=snapshots[bone][name];bb=rows[part['mesh']][start:end]
                    assert len(aa)==len(bb),(item['id'],bone,name,len(aa),len(bb))
                    errors.append(max((a-b).length for a,b in zip(aa,bb)))
                maximum=max(errors)
                assert maximum<.0002,(item['id'],bone,maximum)
                results.append({'id':item['id'],'pose':bone or 'Rest','max_position_error':maximum})
        set_pose(rig,None)
        render(item['id']+'_'+profile)
        if item['role']=='Base':
            render('Face_'+profile,head=True)
        for ob in list(imported):
            if ob.name in bpy.data.objects:
                bpy.data.objects.remove(ob,do_unlink=True)
    print('BLENDER_COMPARED',item['id'],flush=True)
(ROOT/'blender_validation.json').write_text(json.dumps({'passed':True,'imports':14,
    'bones_per_model':28,'mesh_count_optimized':2,'checks':results,
    'poses':6,'max_position_error':max(r['max_position_error'] for r in results),
    'scope':'Blender roundtrip and posed geometry; Roblox not modified'},indent=2)+'\n')
print('ALL_IMPORTS_POSES_AND_RENDERS_PASSED',flush=True)
