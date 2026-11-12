import bpy,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];folder=ROOT/'export'/'cultists'
for obj in list(bpy.data.objects):bpy.data.objects.remove(obj,do_unlink=True)
bpy.ops.import_scene.gltf(filepath=str(folder/'GrowAZombie_Cultists.glb'))
objects=[o for o in bpy.data.objects if o.type=='MESH']
assert len(objects)==24,len(objects)
assert all(o.name.startswith('Cultist_') and '__' in o.name for o in objects)
assert all(len(o.data.color_attributes)>0 for o in objects)
assert all(len(o.data.polygons)>0 for o in objects)
for name in ('Normal','Hunter','Parasite'):
    for part in ('Body','Head','ArmL','ArmR','LegL','LegR'):
        assert bpy.data.objects.get('Cultist_'+name+'__'+part), (name,part)
result={'passed':True,'importedMeshes':len(objects),'vertexColors':True,'namedAnimationParts':True}
(folder/'_glb_roundtrip.json').write_text(json.dumps(result,indent=2));print('ROUNDTRIP',result,flush=True)
