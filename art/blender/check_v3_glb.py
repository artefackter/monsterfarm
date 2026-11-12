import bpy,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];path=ROOT/'export/v3/GrowAZombie_WorldV3.glb'
for obj in list(bpy.data.objects):bpy.data.objects.remove(obj,do_unlink=True)
bpy.ops.import_scene.gltf(filepath=str(path))
objects=[o for o in bpy.data.objects if o.type=='MESH'];assert len(objects)==157,len(objects)
assert all(o.name.startswith('V3_') and '__' in o.name for o in objects)
assert all(len(o.data.color_attributes)>0 for o in objects)
assert all(len(o.data.polygons)>0 for o in objects)
result={'passed':True,'importedMeshes':len(objects),'vertexColors':True,'namedParts':True}
(ROOT/'export/v3/_glb_roundtrip.json').write_text(json.dumps(result,indent=2));print('ROUNDTRIP',result,flush=True)
