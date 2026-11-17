"""Core glTF packing, exact geometry, deduplication of identical vertex records.

Float32 positions/normals and skeleton transforms stay exact. Only palette
colors and skin weights use UNORM16, with measured rounding error. No decoder
extension, geometry quantization, Draco, meshopt, texture or external file.
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
        length,kind=struct.unpack_from('<II',self.raw,12)
        assert kind==0x4E4F534A
        self.doc=json.loads(self.raw[20:20+length])
        n,kind=struct.unpack_from('<II',self.raw,20+length)
        assert kind==0x004E4942
        self.binary=self.raw[28+length:28+length+n]

    def array(self,index,normalized=True):
        a=self.doc['accessors'][index];v=self.doc['bufferViews'][a['bufferView']]
        assert 'sparse' not in a
        dtype=np.dtype(DTYPES[a['componentType']]);width=WIDTHS[a['type']]
        offset=v.get('byteOffset',0)+a.get('byteOffset',0)
        out=np.ndarray((a['count'],width),dtype=dtype,buffer=self.binary,offset=offset,
                       strides=(v.get('byteStride',width*dtype.itemsize),dtype.itemsize)).copy()
        if normalized and a.get('normalized'):
            out=out.astype(float)/np.iinfo(dtype).max
            if dtype.kind=='i':out=np.maximum(out,-1)
        return out

    def mesh(self):
        assert len(self.doc['meshes'])==1
        primitives=self.doc['meshes'][0]['primitives'];assert len(primitives)==1
        p=primitives[0];assert p.get('mode',4)==4
        return {k:self.array(i) for k,i in p['attributes'].items()},self.array(p['indices'],False).ravel()

def pack(source,destination):
    source=GLB(source);doc=source.doc
    assert len(doc['skins'])==len(doc['materials'])==1
    assert len(doc['skins'][0]['joints'])==23
    assert not doc.get('animations') and not doc.get('images') and not doc.get('extensionsRequired')
    arrays,indices=source.mesh()
    assert set(arrays)=={'POSITION','NORMAL','COLOR_0','JOINTS_0','WEIGHTS_0'}
    before=len(arrays['POSITION'])
    # Compare full original records; never weld across normals, color or skin seams.
    keys=np.concatenate([np.ascontiguousarray(arrays[k]).view('u1').reshape(before,-1)
                         for k in sorted(arrays)],axis=1)
    records=np.ascontiguousarray(keys).view(np.dtype((np.void,keys.shape[1]))).ravel()
    _,first,inverse=np.unique(records,return_index=True,return_inverse=True)
    a={k:v[first] for k,v in arrays.items()};indices=inverse[indices].reshape(-1,1)
    binary=bytearray();views=[];accessors=[]
    def accessor(array,component,kind,target=None,normalized=False,bounds=False):
        array=np.ascontiguousarray(array,dtype=DTYPES[component])
        binary.extend(b'\0'*(-len(binary)%4));offset=len(binary)
        payload=array.tobytes();binary.extend(payload)
        view={'buffer':0,'byteOffset':offset,'byteLength':len(payload)}
        if target:view['target']=target
        views.append(view)
        acc={'bufferView':len(views)-1,'componentType':component,'count':len(array),'type':kind}
        if normalized:acc['normalized']=True
        if bounds:
            acc['min']=array.min(axis=0).astype(float).tolist()
            acc['max']=array.max(axis=0).astype(float).tolist()
        accessors.append(acc);return len(accessors)-1
    original_colors=a['COLOR_0']
    colors=np.rint(np.clip(original_colors,0,1)*65535).astype('<u2')
    color_error=float(np.abs(colors.astype(float)/65535-original_colors).max())
    if colors.shape[1]==3:
        colors=np.column_stack((colors,np.full(len(colors),65535,dtype='<u2')))
    weights=a['WEIGHTS_0'].astype(float)
    weights/=weights.sum(axis=1,keepdims=True)
    packed=np.rint(weights*65535).astype(np.int64)
    packed[np.arange(len(packed)),np.argmax(packed,axis=1)]+=65535-packed.sum(axis=1)
    weight_error=float(np.abs(packed.astype(float)/65535-weights).max())
    attrs={'POSITION':accessor(a['POSITION'],5126,'VEC3',34962,bounds=True),
           'NORMAL':accessor(a['NORMAL'],5126,'VEC3',34962),
           'COLOR_0':accessor(colors,5123,'VEC4',34962,True),
           'JOINTS_0':accessor(a['JOINTS_0'],5121,'VEC4',34962),
           'WEIGHTS_0':accessor(packed,5123,'VEC4',34962,True)}
    primitive=copy.deepcopy(doc['meshes'][0]['primitives'][0])
    primitive['attributes']=attrs
    primitive['indices']=accessor(indices,5123 if len(first)<=65535 else 5125,'SCALAR',34963)
    out=copy.deepcopy(doc)
    out['meshes'][0]['primitives']=[primitive]
    for skin in out['skins']:
        skin['inverseBindMatrices']=accessor(source.array(skin['inverseBindMatrices']),5126,'MAT4')
    out.update(accessors=accessors,bufferViews=views,buffers=[{'byteLength':len(binary)}])
    out['asset']={'version':'2.0','generator':'Longmaw compact core-glTF pack'}
    encoded=json.dumps(out,separators=(',',':')).encode();encoded+=b' '*(-len(encoded)%4)
    binary.extend(b'\0'*(-len(binary)%4))
    destination=Path(destination);destination.parent.mkdir(parents=True,exist_ok=True)
    destination.write_bytes(struct.pack('<III',0x46546C67,2,28+len(encoded)+len(binary))+
        struct.pack('<II',len(encoded),0x4E4F534A)+encoded+
        struct.pack('<II',len(binary),0x004E4942)+binary)
    return {'input_bytes':len(source.raw),'output_bytes':destination.stat().st_size,
            'input_vertices':before,'output_vertices':len(first),'removed_identical_records':before-len(first),
            'triangles':len(indices)//3,'meshes':1,'materials':1,'bones':23,'textures':0,
            'geometry_normal_triangle_changes':False,'max_linear_color_error':color_error,
            'max_weight_error':weight_error,'extensions_required':[]}

def verify_pack(source,output):
    a,b=GLB(source),GLB(output)
    aa,ai=a.mesh();bb,bi=b.mesh()
    assert len(ai)==len(bi)
    assert a.doc['nodes']==b.doc['nodes'] and a.doc['materials']==b.doc['materials']
    for key in ('POSITION','NORMAL','JOINTS_0'):
        assert np.array_equal(aa[key][ai],bb[key][bi]),key
    assert np.abs(aa['COLOR_0'][ai,:3]-bb['COLOR_0'][bi,:3]).max()<1/65535
    assert np.abs(aa['WEIGHTS_0'][ai]-bb['WEIGHTS_0'][bi]).max()<2/65535
    assert np.max(np.abs(bb['WEIGHTS_0'].sum(axis=1)-1))<1e-12
    sa,sb=a.doc['skins'][0],b.doc['skins'][0]
    assert {k:v for k,v in sa.items() if k!='inverseBindMatrices'}=={k:v for k,v in sb.items() if k!='inverseBindMatrices'}
    assert np.array_equal(a.array(sa['inverseBindMatrices']),b.array(sb['inverseBindMatrices']))
    return {'passed':True,'expanded_positions_normals_joints_exact':True,
            'triangle_order_exact':True,'skeleton_exact':True,'normalized_weights':True}
