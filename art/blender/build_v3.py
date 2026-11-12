import os,sys,json
from pathlib import Path
sys.path.insert(0,os.path.dirname(__file__))
import bpy,kit,assets_v3,items_v3
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'export'/'v3';OUT.mkdir(parents=True,exist_ok=True)
assets_v3.build();items_v3.build()
manifest,baked,total=kit.export_all(str(OUT))
(OUT/'_manifest.json').write_text(json.dumps(manifest,indent=2))
meta={'version':3,'units':'stud','coordinateSystem':'Roblox (-BlenderX, BlenderZ, BlenderY)','colliders':{},'anchors':{}}
for name,entries in assets_v3.COLLIDERS.items():
 meta['colliders'][name]=[{'name':v['name'],'center':kit.to_rbx(v['center']),'size':[v['size'][0],v['size'][2],v['size'][1]]} for v in entries]
for name,anchors in assets_v3.ANCHORS.items():meta['anchors'][name]={k:kit.to_rbx(v) for k,v in anchors.items()}
(OUT/'_metadata.json').write_text(json.dumps(meta,indent=2))
print('V3 EXPORTED',len(manifest),'assets',sum(map(len,manifest.values())),'meshes',total,'triangles',flush=True)
for name,parts in manifest.items(): print(name,sum(p['tris'] for p in parts),flush=True)
