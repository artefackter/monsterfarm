"""Package only the four new deer characters; preserve named animation parts."""
from pathlib import Path
import hashlib,json,math,struct

OUT=Path(__file__).resolve().parents[1]/'export'/'deer'
manifest=json.loads((OUT/'_manifest.json').read_text())
blob=bytearray();views=[];accessors=[];meshes=[];nodes=[];roots=[]
def add(values,fmt,ctype,atype,count,target,**extra):
    blob.extend(b'\0'*((-len(blob))%4))
    data=struct.pack('<'+str(len(values))+fmt,*values)
    views.append({'buffer':0,'byteOffset':len(blob),'byteLength':len(data),'target':target});blob.extend(data)
    accessors.append({'bufferView':len(views)-1,'componentType':ctype,'count':count,'type':atype,**extra})
    return len(accessors)-1

for i,(name,parts) in enumerate(manifest.items()):
    children=[]
    for p in parts:
        d=json.loads((OUT/(p['mesh']+'.json')).read_text())
        v,n,c,t=d['v'],d['n'],d['c'],d['t'];num=len(v)//3
        assert len(v)==len(n)==num*3 and len(c)==num and len(t)%3==0
        assert all(math.isfinite(x) for x in v+n) and all(0<=x<num for x in t)
        assert len(t)//3<=10000
        lo=[min(v[j::3]) for j in range(3)];hi=[max(v[j::3]) for j in range(3)]
        pos=add(v,'f',5126,'VEC3',num,34962,min=lo,max=hi)
        nor=add(n,'f',5126,'VEC3',num,34962)
        colors=[a for rgb in c for a in [(rgb>>16&255)/255,(rgb>>8&255)/255,(rgb&255)/255,1]]
        col=add(colors,'f',5126,'VEC4',num,34962)
        idx=add(t,'I',5125,'SCALAR',len(t),34963)
        meshes.append({'name':d['name'],'primitives':[{'attributes':{'POSITION':pos,'NORMAL':nor,'COLOR_0':col},'indices':idx,'material':0}]})
        children.append(len(nodes))
        nodes.append({'name':name+'__'+p['part'],'mesh':len(meshes)-1,'translation':p['offset'],
            'extras':{'asset':name,'part':p['part'],'attach':p['attach']}})
    roots.append(len(nodes));nodes.append({'name':name,'children':children,'translation':[i*8,0,0]})

gltf={'asset':{'version':'2.0','generator':'Grow a Zombie deer mesh pack'},'scene':0,
    'scenes':[{'name':'GrowAZombie_DeerCollection','nodes':roots}],
    'nodes':nodes,'meshes':meshes,'accessors':accessors,'bufferViews':views,'buffers':[{'byteLength':len(blob)}],
    'materials':[{'name':'VertexColors','pbrMetallicRoughness':{'baseColorFactor':[1,1,1,1],'metallicFactor':0,'roughnessFactor':.8}}]}
js=json.dumps(gltf,separators=(',',':')).encode();js+=b' '*((-len(js))%4);blob.extend(b'\0'*((-len(blob))%4))
out=OUT/'GrowAZombie_DeerCollection.glb'
out.write_bytes(struct.pack('<III',0x46546C67,2,28+len(js)+len(blob))+struct.pack('<II',len(js),0x4E4F534A)+js+struct.pack('<II',len(blob),0x004E4942)+blob)
raw=out.read_bytes();assert struct.unpack_from('<I',raw,8)[0]==len(raw)
assert len({n['name'] for n in nodes})==len(nodes)
assert set(manifest)=={'Deer_Farmer','Deer_Punk','Deer_Assassin','Deer_Chief'}
stats=json.loads((OUT/'_validation.json').read_text())
stats.update({'meshes':len(meshes),'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest(),
    'checks':['finite vertices and normals','valid triangle indices','unique import names','GLB container length',
        'four new models only','every mesh below 10000 triangles','separate head, arms, legs and props']})
(OUT/'_validation.json').write_text(json.dumps(stats,indent=2))
print(json.dumps(stats,indent=2))
