"""Re-import all deliverables, check geometry and render assembly and detail views (Blender)."""
import json
from pathlib import Path
import bpy
from mathutils import Vector

root = Path(__file__).resolve().parents[1]
catalog = json.loads((root/'catalog.json').read_text())
layouts = json.loads((root/'layouts.json').read_text())
out = root/'previews'
out.mkdir(exist_ok=True)


def empty():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    return bpy.context.scene


def load(path):
    bpy.ops.import_scene.gltf(filepath=str(path))
    bpy.context.view_layer.update()
    return [o for o in bpy.context.scene.objects if o.type=='MESH']


def world_vertices(objects):
    return [ob.matrix_world @ v.co for ob in objects for v in ob.data.vertices]


def validate_models():
    for item in catalog:
        empty()
        objs = load(root/item['file'])
        n = sum(len(o.data.polygons) for o in objs)
        assert n == item['triangles'], (item['name'], n)
        assert all(o.data.uv_layers.active for o in objs)
        assert any(img.packed_file for img in bpy.data.images), item['name']
        coords = [(v.x,v.z,-v.y) for v in world_vertices(objs)]
        for axis, values in enumerate(zip(*coords)):
            assert abs(min(values)-item['boundsMin'][axis]) < .002
            assert abs(max(values)-item['boundsMax'][axis]) < .002
        if item['group'] in ('wall','floor'):
            assert max(v[0] for v in coords)==32 and min(v[0] for v in coords)==-32
        if item['group']=='wall': assert max(v[2] for v in coords)<11.2
    print('Verified individual meshes:',len(catalog),flush=True)


def setup(scene, biome):
    scene.world = bpy.data.worlds.new('Preview lighting')
    scene.world.use_nodes = True
    tree = scene.world.node_tree
    bg = tree.nodes.get('Background')
    bg.inputs['Color'].default_value = (.77,.81,.88,1)
    bg.inputs['Strength'].default_value = .57
    cam_bg = tree.nodes.new('ShaderNodeBackground')
    cam_bg.inputs['Color'].default_value = (.075,.58,.86,1)
    if biome=='space':
        bpy.ops.mesh.primitive_plane_add(size=1800,location=(0,0,-12))
        backdrop=bpy.context.object
        backdrop.name='Preview star field'
        sky_mat=bpy.data.materials.new('Preview star field');sky_mat.use_nodes=True
        sky_nodes=sky_mat.node_tree
        uv=sky_nodes.nodes.new('ShaderNodeTexCoord')
        repeat=sky_nodes.nodes.new('ShaderNodeVectorMath');repeat.operation='SCALE';repeat.inputs['Scale'].default_value=5
        image=sky_nodes.nodes.new('ShaderNodeTexImage')
        image.image=bpy.data.images.load(str(root/'sky'/'SkyboxDn.png'))
        emit=sky_nodes.nodes.new('ShaderNodeEmission')
        sky_nodes.links.new(uv.outputs['UV'],repeat.inputs[0]);sky_nodes.links.new(repeat.outputs[0],image.inputs[0])
        sky_nodes.links.new(image.outputs[0],emit.inputs[0]);sky_nodes.links.new(emit.outputs[0],sky_nodes.nodes.get('Material Output').inputs[0])
        backdrop.data.materials.append(sky_mat)
        tex = tree.nodes.new('ShaderNodeTexEnvironment')
        tex.image = bpy.data.images.load(str(root/'sky'/'SkyboxFt.png'))
        tex.interpolation = 'Closest'
        tree.links.new(tex.outputs['Color'],cam_bg.inputs[0])
    mix = tree.nodes.new('ShaderNodeMixShader')
    ray = tree.nodes.new('ShaderNodeLightPath')
    tree.links.new(ray.outputs['Is Camera Ray'],mix.inputs[0])
    tree.links.new(bg.outputs[0],mix.inputs[1]);tree.links.new(cam_bg.outputs[0],mix.inputs[2])
    tree.links.new(mix.outputs[0],tree.nodes.get('World Output').inputs['Surface'])
    sun = bpy.data.lights.new('Key','SUN')
    sun.energy=2.1;sun.angle=.16
    lamp = bpy.data.objects.new('Key',sun);scene.collection.objects.link(lamp)
    lamp.rotation_euler=(.49,-.6,-.5)
    scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=8
    scene.cycles.use_denoising=True
    scene.render.image_settings.file_format='JPEG';scene.render.image_settings.quality=80
    scene.view_settings.view_transform='Standard'
    scene.render.resolution_x=1360;scene.render.resolution_y=810;scene.render.resolution_percentage=100
    c = bpy.data.cameras.new('Camera');cam=bpy.data.objects.new('Camera',c)
    scene.collection.objects.link(cam);scene.camera=cam
    c.type='ORTHO';c.clip_end=3000
    return cam


def view(scene, cam, target, direction, scale, filename, points=None):
    target, d = Vector(target),Vector(direction).normalized()
    cam.rotation_euler=(-d).to_track_quat('-Z','Y').to_euler()
    transform=cam.rotation_euler.to_matrix()
    if points:
        projected=[transform.transposed() @ (p-target) for p in points]
        left,right=min(p.x for p in projected),max(p.x for p in projected)
        bottom,top=min(p.y for p in projected),max(p.y for p in projected)
        target += transform @ Vector(((right+left)/2,(top+bottom)/2,0))
        scale=max(right-left,(top-bottom)*1360/810)*1.075
    cam.location=target+d*770;cam.data.ortho_scale=scale
    scene.render.filepath=str(out/filename)
    bpy.ops.render.render(write_still=True)


def run():
    validate_models()
    for b,layout in layouts.items():
        scene=empty();objs=load(root/'samples'/(b+'.glb'))
        assert len(objs)==len(layout),(b,len(objs),len(layout))
        expected=sorted([tuple(round(t,2) for t in row['position']) for row in layout])
        actual=sorted([(round(o.matrix_world.translation.x,2),round(o.matrix_world.translation.z,2),round(-o.matrix_world.translation.y,2)) for o in objs])
        assert expected==actual,b
        pts=world_vertices(objs)
        assert abs(min(p.x for p in pts)+256)<.005 and abs(max(p.x for p in pts)-256)<.005
        cam=setup(scene,b)
        view(scene,cam,(0,30,0),(-.78,-1,.99),1,b+'.jpg',pts)
        view(scene,cam,(-154,48,4),(-.44,-1,.68),134,b+'-detail.jpg')
        print('Verified and rendered:',b, flush=True)


if __name__=='__main__': run()
