"""Identical source/optimized GLB renders in rest and exercised skeletal poses."""
import bpy,sys,json
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parent;sys.path.insert(0,str(ROOT))
from assets import verify_sources
rows={r['id']:r for r in json.loads((ROOT/'models_report.json').read_text())['models']}
CASES={'DredgeKing':[('Head',.20),('Tail05',.28)],
 'AssimilatedAdventurerFarmer':[('Head',.20),('ChestFlapL',.28)],
 'PrimitiveSummonerNefor':[('UpperJaw',.12),('LowerJaw',.24)],
 'AdaptedVisceraKnight':[('Tentacle01_2',.25),('Tentacle02_2',-.22)]}
renders=[]
for name,bones in CASES.items():
    row=rows[name]
    for pose in ['rest','posed']:
        camera_spec=None
        for profile in ['original','optimized']:
            bpy.ops.wm.read_factory_settings(use_empty=True)
            bpy.ops.import_scene.gltf(filepath=str(row['source'] if profile=='original' else ROOT/row['output']))
            rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE');rig.hide_render=True
            helpers={p.custom_shape for p in rig.pose.bones if p.custom_shape}
            meshes=[o for o in bpy.context.scene.objects if o.type=='MESH' and o not in helpers]
            for h in helpers:
                if h:h.hide_render=True
            if pose=='posed':
                for bone,angle in bones:
                    pb=rig.pose.bones[bone];pb.rotation_mode='XYZ';pb.rotation_euler.x=angle
            bpy.context.view_layer.update()
            points=[]
            for ob in meshes:
                ev=ob.evaluated_get(bpy.context.evaluated_depsgraph_get());me=ev.to_mesh()
                points.extend(ob.matrix_world@v.co for v in me.vertices);ev.to_mesh_clear()
            lo=Vector(tuple(min(p[i] for p in points) for i in range(3)));hi=Vector(tuple(max(p[i] for p in points) for i in range(3)))
            scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=16;scene.cycles.use_denoising=True;scene.cycles.seed=17
            scene.render.resolution_x=600;scene.render.resolution_y=700;scene.render.resolution_percentage=100
            scene.render.image_settings.file_format='PNG';scene.view_settings.view_transform='AgX'
            world=bpy.data.worlds.new('ReviewWorld');scene.world=world;world.use_nodes=True
            world.node_tree.nodes['Background'].inputs[0].default_value=(.13,.18,.23,1)
            world.node_tree.nodes['Background'].inputs[1].default_value=.45
            if camera_spec is None:
                target=(lo+hi)/2;angle=Vector((8,-15,4.5));rotation=(target-(target+angle)).to_track_quat('-Z','Y')
                inv=rotation.to_matrix().transposed();pts=[inv@(p-target) for p in points]
                width=max(p.x for p in pts)-min(p.x for p in pts);height=max(p.y for p in pts)-min(p.y for p in pts)
                target+=rotation@Vector(((min(p.x for p in pts)+max(p.x for p in pts))/2,(min(p.y for p in pts)+max(p.y for p in pts))/2,0))
                scale=max(height,width*700/600)*1.18
                camera_spec=(target.copy(),angle.copy(),rotation.copy(),scale,float(lo.z))
            target,angle,rot,scale,floor=camera_spec
            bpy.ops.object.camera_add(location=target+angle);cam=bpy.context.object;cam.rotation_mode='QUATERNION';cam.rotation_quaternion=rot
            cam.data.type='ORTHO';cam.data.ortho_scale=scale;scene.camera=cam
            bpy.ops.mesh.primitive_plane_add(size=2000,location=(0,0,floor-.015))
            mat=bpy.data.materials.new('Floor');mat.diffuse_color=(.026,.042,.056,1);mat.use_nodes=True
            bs=mat.node_tree.nodes['Principled BSDF'];bs.inputs['Base Color'].default_value=(.026,.042,.056,1);bs.inputs['Roughness'].default_value=.85
            bpy.context.object.data.materials.append(mat)
            for delta,power,size,color in [((2,-7,8),1200,7,(1,.90,.79)),((-6,-3,5),900,6,(.72,.85,1)),((5,4,6),1400,6,(.81,.91,1))]:
                light=bpy.data.lights.new('Softbox','AREA');light.energy=power;light.shape='DISK';light.size=size;light.color=color
                ob=bpy.data.objects.new('Softbox',light);scene.collection.objects.link(ob);ob.location=target+Vector(delta)
                ob.rotation_euler=(target-ob.location).to_track_quat('-Z','Y').to_euler()
            path=ROOT/'previews'/profile/(name+'_'+pose+'.png');path.parent.mkdir(parents=True,exist_ok=True)
            scene.render.filepath=str(path)
            bpy.ops.render.render(write_still=True)
            renders.append(dict(id=name,pose=pose,profile=profile,file=str(path.relative_to(ROOT))))
        print('RENDER_PAIR',name,pose,flush=True)
(ROOT/'render_manifest.json').write_text(json.dumps(dict(renders=renders,source_files_unchanged=verify_sources()),indent=2)+'\n')
