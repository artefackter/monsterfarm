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

def pack(source,destination):
    g=GLB(source);d=copy.deepcopy(g.doc);w=Writer()
    assert len(d['skins'])==len(d['meshes'])==len(d['materials'])==1
    assert not d.get('animations') and not d.get('images') and not d.get('textures')
    assert set(d.get('extensionsUsed',[])) <= {'KHR_materials_specular'}
    assert not d.get('extensionsRequired')
    p=d['meshes'][0]['primitives'][0]
    assert len(d['meshes'][0]['primitives'])==1 and p.get('mode',4)==4
    a={k:g.array(v) for k,v in p['attributes'].items()}
    assert set(a)=={'POSITION','NORMAL','COLOR_0','JOINTS_0','WEIGHTS_0'}
    assert max(a['JOINTS_0'].flat)<256
    oldverts=len(a['POSITION']);indices=g.array(p['indices'],False).reshape(-1)
    assert len(indices)%3==0
    original_colors=a['COLOR_0'];colors=np.rint(np.clip(original_colors,0,1)*65535).astype('<u2')
    color_error=float(np.abs(colors.astype(float)/65535-original_colors).max())
    if colors.shape[1]==3:colors=np.column_stack((colors,np.full(len(colors),65535,dtype='<u2')))
    original_weights=a['WEIGHTS_0'].copy()
    weights=np.clip(original_weights.astype(float),0,1);weights/=weights.sum(axis=1,keepdims=True)
    packed=np.rint(weights*65535).astype(np.int64)
    packed[np.arange(len(packed)),np.argmax(packed,axis=1)]+=65535-packed.sum(axis=1)
    assert packed.min()>=0 and packed.max()<=65535
    weight_error=float(np.abs(packed/65535-original_weights).max())
    a['COLOR_0']=colors;a['WEIGHTS_0']=packed.astype('<u2');a['JOINTS_0']=a['JOINTS_0'].astype('u1')
    a,remap=unique_vertices(a);indices=remap[indices].reshape(-1,1)
    p['attributes']={
        'POSITION':w.array(a['POSITION'],5126,'VEC3',34962,bounds=True),
        'NORMAL':w.array(a['NORMAL'],5126,'VEC3',34962),
        'COLOR_0':w.array(a['COLOR_0'],5123,'VEC4',34962,True),
        'JOINTS_0':w.array(a['JOINTS_0'],5121,'VEC4',34962),
        'WEIGHTS_0':w.array(a['WEIGHTS_0'],5123,'VEC4',34962,True)}
    p['indices']=w.array(indices,5123 if len(a['POSITION'])<=65535 else 5125,'SCALAR',34963)
    skin=d['skins'][0]
    skin['inverseBindMatrices']=w.array(g.array(skin['inverseBindMatrices']),5126,'MAT4')
    d['asset']['generator']='SRP compact GLB: unchanged geometry and rig; uint16 colors/weights'
    w.save(d,destination)
    return dict(input_bytes=len(g.raw),output_bytes=Path(destination).stat().st_size,
        input_vertices=oldverts,output_vertices=len(a['POSITION']),triangles=len(indices)//3,
        bones=len(skin['joints']),meshes=1,materials=1,animation_clips=0,
        max_linear_color_error=color_error,max_weight_error=weight_error,
        extensions_preserved=d.get('extensionsUsed',[]),geometry_changed=False)

