"""Core glTF packing with exact corner geometry and all moving animation keys.

No extension/decoder is needed. Bones and bind matrices keep their original values.
Only colors and weights are packed to normalized uint16; each weight sum is 65535.
"""
import copy
import json
import struct
from pathlib import Path
import numpy as np

DTYPES={5120:'i1',5121:'u1',5122:'<i2',5123:'<u2',5125:'<u4',5126:'<f4'}
WIDTHS={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}
class GLB:
    def __init__(self,path):
        self.path=Path(path);self.raw=self.path.read_bytes()
        assert struct.unpack_from('<III',self.raw)==(0x46546C67,2,len(self.raw))
        length,kind=struct.unpack_from('<II',self.raw,12);assert kind==0x4e4f534a
        self.doc=json.loads(self.raw[20:20+length]);offset=20+length
        length,kind=struct.unpack_from('<II',self.raw,offset);assert kind==0x004e4942
        self.binary=self.raw[offset+8:offset+8+length]
    def array(self,index,normalized=True):
        a=self.doc['accessors'][index];assert 'sparse' not in a
        view=self.doc['bufferViews'][a['bufferView']];dtype=np.dtype(DTYPES[a['componentType']]);width=WIDTHS[a['type']]
        stride=view.get('byteStride',width*dtype.itemsize)
        needed=(a['count']-1)*stride+width*dtype.itemsize
        assert a.get('byteOffset',0)+needed<=view['byteLength'],(self.path,index,'accessor exceeds view')
        assert view.get('byteOffset',0)+view['byteLength']<=self.doc['buffers'][0]['byteLength']<=len(self.binary)
        out=np.ndarray((a['count'],width),dtype=dtype,buffer=self.binary,
            offset=view.get('byteOffset',0)+a.get('byteOffset',0),
            strides=(view.get('byteStride',width*dtype.itemsize),dtype.itemsize)).copy()
        if normalized and a.get('normalized'):
            out=out.astype(np.float64)/np.iinfo(dtype).max
            if dtype.kind=='i':out=np.maximum(out,-1)
        return out

class Writer:
    def __init__(self):self.binary=bytearray();self.views=[];self.accessors=[];self.cache={}
    def array(self,arr,component,kind,target=None,normalized=False,bounds=False):
        arr=np.ascontiguousarray(arr,dtype=np.dtype(DTYPES[component]));data=arr.tobytes()
        key=(component,kind,target,normalized,bounds,arr.shape,data)
        if key in self.cache:return self.cache[key]
        self.binary.extend(b'\0'*(-len(self.binary)%4));offset=len(self.binary);self.binary.extend(data)
        view={'buffer':0,'byteOffset':offset,'byteLength':len(data)}
        if target:view['target']=target
        self.views.append(view)
        a={'bufferView':len(self.views)-1,'componentType':component,'count':len(arr),'type':kind}
        if normalized:a['normalized']=True
        if bounds:a.update(min=arr.min(axis=0).astype(float).tolist(),max=arr.max(axis=0).astype(float).tolist())
        index=len(self.accessors);self.accessors.append(a);self.cache[key]=index;return index
    def save(self,doc,path):
        doc.update(accessors=self.accessors,bufferViews=self.views,buffers=[{'byteLength':len(self.binary)}])
        encoded=json.dumps(doc,separators=(',',':')).encode();encoded+=b' '*(-len(encoded)%4)
        self.binary.extend(b'\0'*(-len(self.binary)%4));path=Path(path);path.parent.mkdir(parents=True,exist_ok=True)
        path.write_bytes(struct.pack('<III',0x46546c67,2,28+len(encoded)+len(self.binary))+
            struct.pack('<II',len(encoded),0x4e4f534a)+encoded+
            struct.pack('<II',len(self.binary),0x004e4942)+self.binary)

def unique_vertices(arrays):
    """Keep first occurrence order and exact packed attribute bytes at seams."""
    order=('POSITION','NORMAL','COLOR_0','JOINTS_0','WEIGHTS_0')
    row=np.concatenate([np.ascontiguousarray(arrays[k]).view('u1').reshape(len(arrays[k]),-1) for k in order],axis=1)
    keys=np.ascontiguousarray(row).view(np.dtype((np.void,row.shape[1]))).reshape(-1)
    _,first,inverse=np.unique(keys,return_index=True,return_inverse=True)
    sequence=np.argsort(first);remap=np.empty(len(first),dtype=np.int64);remap[sequence]=np.arange(len(first))
    keep=first[sequence]
    return {k:v[keep] for k,v in arrays.items()},remap[inverse]

def pack(source,destination,person):
    source=GLB(source);d=source.doc;w=Writer()
    assert len(d['skins'])==1 and len(d['materials'])==1
    assert not d.get('images') and not d.get('extensionsRequired') and not d.get('extensionsUsed')
    parent={c:i for i,n in enumerate(d['nodes']) for c in n.get('children',[])}
    mesh_nodes=[(i,n) for i,n in enumerate(d['nodes']) if 'mesh' in n]
    assert len({parent.get(i) for i,n in mesh_nodes})==1
    groups={};ranges={};total_triangles=0
    for i,node in mesh_nodes:
        assert node.get('skin')==0 and not any(k in node for k in ('matrix','translation','rotation','scale'))
        mesh=d['meshes'][node['mesh']];assert len(mesh['primitives'])==1
        p=mesh['primitives'][0];assert p.get('mode',4)==4 and p.get('material',0)==0
        attrs={k:source.array(v) for k,v in p['attributes'].items()}
        assert set(attrs)=={'POSITION','NORMAL','COLOR_0','JOINTS_0','WEIGHTS_0'}
        indices=source.array(p['indices'],False).reshape(-1)
        group=person+('Weapon' if mesh['name'].endswith('__HandItem') else 'Body')
        parts=groups.setdefault(group,[]);first=sum(len(row[1])//3 for row in parts)
        ranges[mesh['name']]={'mesh':group,'triangle_start':first,'triangles':len(indices)//3,'source_vertices':len(attrs['POSITION'])}
        parts.append((attrs,indices,i,mesh['name']));total_triangles+=len(indices)//3
    removed=set();keepers={};meshes=[];stats={};color_error=0;weight_error=0
    for group,parts in groups.items():
        arrays={k:np.concatenate([p[0][k] for p in parts]) for k in parts[0][0]}
        indices=[];offset=0
        for a,ix,_,_ in parts:indices.append(ix.astype(np.int64)+offset);offset+=len(a['POSITION'])
        indices=np.concatenate(indices)
        colors=np.rint(np.clip(arrays['COLOR_0'],0,1)*65535).astype('<u2')
        color_error=max(color_error,float(np.max(np.abs(colors.astype(float)/65535-arrays['COLOR_0']))))
        if colors.shape[1]==3:
            # VEC4 keeps each uint16 vertex color 4-byte aligned. RGB gets opaque alpha.
            colors=np.column_stack((colors,np.full(len(colors),65535,dtype='<u2')))
        weights=np.clip(arrays['WEIGHTS_0'].astype(float),0,1);weights/=weights.sum(axis=1,keepdims=True)
        packed=np.rint(weights*65535).astype(np.int64)
        packed[np.arange(len(packed)),np.argmax(packed,axis=1)]+=65535-packed.sum(axis=1)
        assert packed.min()>=0 and packed.max()<=65535
        weight_error=max(weight_error,float(np.max(np.abs(packed.astype(float)/65535-arrays['WEIGHTS_0']))))
        before=len(arrays['POSITION']);arrays['COLOR_0']=colors;arrays['WEIGHTS_0']=packed.astype('<u2')
        arrays['JOINTS_0']=arrays['JOINTS_0'].astype('u1')
        arrays,vertex_map=unique_vertices(arrays);indices=vertex_map[indices].reshape(-1,1)
        attributes={
            'POSITION':w.array(arrays['POSITION'],5126,'VEC3',34962,bounds=True),
            'NORMAL':w.array(arrays['NORMAL'],5126,'VEC3',34962),
            'COLOR_0':w.array(arrays['COLOR_0'],5123,'VEC4',34962,True),
            'JOINTS_0':w.array(arrays['JOINTS_0'],5121,'VEC4',34962),
            'WEIGHTS_0':w.array(arrays['WEIGHTS_0'],5123,'VEC4',34962,True)}
        ix=w.array(indices,5123 if len(arrays['POSITION'])<=65535 else 5125,'SCALAR',34963)
        mesh_id=len(meshes);meshes.append({'name':group,'primitives':[{'attributes':attributes,'indices':ix,'material':0}]})
        keepers[parts[0][2]]=(group,mesh_id);removed.update(p[2] for p in parts[1:])
        stats[group]={'source_vertices':before,'vertices':len(arrays['POSITION']),'triangles':len(indices)//3}
    remap={old:new for new,old in enumerate(i for i in range(len(d['nodes'])) if i not in removed)}
    nodes=[]
    for i,node in enumerate(d['nodes']):
        if i in removed:continue
        n=copy.deepcopy(node)
        if i in keepers:n['name'],n['mesh']=keepers[i];n.pop('extras',None)
        if 'children' in n:n['children']=[remap[c] for c in n['children'] if c not in removed]
        nodes.append(n)
    skins=copy.deepcopy(d['skins'])
    for skin in skins:
        skin['joints']=[remap[i] for i in skin['joints']]
        if 'skeleton' in skin:skin['skeleton']=remap[skin['skeleton']]
        if 'inverseBindMatrices' in skin:skin['inverseBindMatrices']=w.array(source.array(skin['inverseBindMatrices']),5126,'MAT4')
    animations=[];animation_report={}
    defaults={'translation':(0,0,0),'rotation':(0,0,0,1),'scale':(1,1,1)}
    for action in d.get('animations',[]):
        out={'name':action['name'],'channels':[],'samplers':[]};before=0;after=0;dropped=0;constant=0
        for channel in action['channels']:
            sampler=action['samplers'][channel['sampler']]
            interpolation=sampler.get('interpolation','LINEAR');assert interpolation in ('LINEAR','STEP')
            times=source.array(sampler['input']);values=source.array(sampler['output']);before+=len(times)
            node=channel['target']['node'];path=channel['target']['path'];assert node not in removed
            is_constant=np.array_equal(values,np.broadcast_to(values[0],values.shape))
            if is_constant:
                constant+=1;default=np.asarray(d['nodes'][node].get(path,defaults[path]),dtype=np.float64)
                exact=np.array_equal(values[0],default) or (path=='rotation' and np.array_equal(values[0],-default))
                if exact:dropped+=1;continue
                times=times[:1];values=values[:1]
            after+=len(times)
            s={'input':w.array(times,5126,'SCALAR',bounds=True),'output':w.array(values,5126,'VEC4' if path=='rotation' else 'VEC3'),'interpolation':interpolation}
            out['channels'].append({'sampler':len(out['samplers']),'target':{'node':remap[node],'path':path}});out['samplers'].append(s)
        assert out['channels'];animations.append(out)
        animation_report[action['name']]={'input_channels':len(action['channels']),'output_channels':len(out['channels']),
            'input_keys':before,'output_keys':after,'constant_channels':constant,'removed_default_channels':dropped,'moving_keys_preserved':True}
    scenes=copy.deepcopy(d['scenes'])
    for scene in scenes:scene['nodes']=[remap[i] for i in scene['nodes'] if i not in removed]
    doc={'asset':{'version':'2.0','generator':'Granny Slender compact core-glTF'},'scene':d.get('scene',0),
         'scenes':scenes,'nodes':nodes,'skins':skins,'materials':copy.deepcopy(d['materials']),'meshes':meshes,'animations':animations}
    w.save(doc,destination)
    return {'input_bytes':len(source.raw),'output_bytes':Path(destination).stat().st_size,
        'input_meshes':len(mesh_nodes),'output_meshes':len(meshes),'triangles':total_triangles,
        'bones':len(skins[0]['joints']),'groups':stats,'part_ranges':ranges,
        'max_linear_color_error':color_error,'max_weight_error':weight_error,
        'geometry_changed':False,'animations':animation_report,'extensions_required':[]}
