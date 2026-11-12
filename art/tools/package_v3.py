"""Deterministic GLB: one new asset group per display-grid position, named leaf meshes.
Old characters are preview references only and never enter the import package.
"""
from pathlib import Path
import json,struct,math,hashlib
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'export'/'v3'
man=json.loads((OUT/'_manifest.json').read_text());meta=json.loads((OUT/'_metadata.json').read_text())
blob=bytearray();views=[];access=[];meshes=[];nodes=[];roots=[]
def add(values,fmt,ctype,atype,count,target,**extra):
 while len(blob)%4:blob.append(0)
 data=struct.pack('<'+str(len(values))+fmt,*values);views.append({'buffer':0,'byteOffset':len(blob),'byteLength':len(data),'target':target});blob.extend(data)
 access.append({'bufferView':len(views)-1,'componentType':ctype,'count':count,'type':atype,**extra});return len(access)-1
summary={};total=0
for i,(name,parts) in enumerate(sorted(man.items())):
 children=[]
 for p in parts:
  d=json.loads((OUT/(p['mesh']+'.json')).read_text());v,n,c,t=d['v'],d['n'],d['c'],d['t'];num=len(v)//3
  assert len(v)==len(n)==num*3 and len(c)==num and len(t)%3==0
  assert all(math.isfinite(x) for x in v+n) and all(0<=x<num for x in t)
  assert len(t)//3<=10000,(name,p['part'],'split this mesh')
  lo=[min(v[j::3]) for j in range(3)];hi=[max(v[j::3]) for j in range(3)]
  pos=add(v,'f',5126,'VEC3',num,34962,min=lo,max=hi);nor=add(n,'f',5126,'VEC3',num,34962)
  colors=[a for rgb in c for a in [(rgb>>16&255)/255,(rgb>>8&255)/255,(rgb&255)/255,1]]
  col=add(colors,'f',5126,'VEC4',num,34962);idx=add(t,'I',5125,'SCALAR',len(t),34963)
  meshes.append({'name':d['name'],'primitives':[{'attributes':{'POSITION':pos,'NORMAL':nor,'COLOR_0':col},'indices':idx,'material':0}]})
  children.append(len(nodes));nodes.append({'name':name+'__'+p['part'],'mesh':len(meshes)-1,'translation':p['offset'],'extras':{'asset':name,'part':p['part']}})
  total+=len(t)//3
 roots.append(len(nodes));nodes.append({'name':name,'children':children,'translation':[(i%8)*72,0,(i//8)*72]})
 summary[name]={'parts':len(parts),'triangles':sum(p['tris'] for p in parts)}
gltf={'asset':{'version':'2.0','generator':'Grow a Zombie original v3 art pipeline'},'scene':0,'scenes':[{'name':'GrowAZombie_WorldV3','nodes':roots}],'nodes':nodes,'meshes':meshes,'accessors':access,'bufferViews':views,'buffers':[{'byteLength':len(blob)}],'materials':[{'name':'VertexColors','pbrMetallicRoughness':{'baseColorFactor':[1,1,1,1],'metallicFactor':0,'roughnessFactor':.8}}]}
js=json.dumps(gltf,separators=(',',':')).encode();js+=b' '*((-len(js))%4);blob.extend(b'\0'*((-len(blob))%4))
path=OUT/'GrowAZombie_WorldV3.glb';path.write_bytes(struct.pack('<III',0x46546C67,2,28+len(js)+len(blob))+struct.pack('<II',len(js),0x4E4F534A)+js+struct.pack('<II',len(blob),0x004E4942)+blob)
# Validate container lengths and exact expected source mesh membership.
raw=path.read_bytes();assert struct.unpack_from('<I',raw,8)[0]==len(raw)
assert len({n['name'] for n in nodes})==len(nodes)
assert all(k.startswith('V3_') for k in summary)
for name,anchors in meta['anchors'].items():
 if 'DoorOpening' in anchors:assert abs(anchors['DoorOpening'][0])>=10,name
stats={'assets':len(man),'meshes':len(meshes),'triangles':total,'maxMeshTriangles':max(p['tris'] for ps in man.values() for p in ps),'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest(),'assetsDetail':summary,'checks':['finite geometry','triangle indices','unique import names','GLB length','no old character meshes','door width >= 10 studs','every mesh <= 10000 triangles']}
(OUT/'_validation.json').write_text(json.dumps(stats,indent=2));print(json.dumps({k:v for k,v in stats.items() if k!='assetsDetail'},indent=2))
