import bpy,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];folder=ROOT/'export/environment-v4'
for obj in list(bpy.data.objects):bpy.data.objects.remove(obj,do_unlink=True)
bpy.ops.import_scene.gltf(filepath=str(folder/'GrowAZombie_GardenEnvironmentV4.glb'))
manifest=json.loads((folder/'_manifest.json').read_text())
objects=[o for o in bpy.data.objects if o.type=='MESH']
assert len(objects)==sum(len(p) for p in manifest.values())
for name,parts in manifest.items():
    for part in parts:
        o=bpy.data.objects.get(name+'__'+part['part'])
        assert o and o.type=='MESH',(name,part)
        assert len(o.data.color_attributes)>0 and len(o.data.polygons)>0
        assert all(v.co.length<1000 for v in o.data.vertices)
        assert len(o.data.polygons)<10000
image=bpy.data.images.load(str(folder/'GardenLawn_Seamless.png'))
assert tuple(image.size)==(512,512)
result={'passed':True,'importedMeshes':len(objects),'vertexColors':True,'grassTexture':[512,512],
        'models':len(manifest),'geometryChecked':True}
(folder/'_glb_roundtrip.json').write_text(json.dumps(result,indent=2));print('ROUNDTRIP',result,flush=True)
