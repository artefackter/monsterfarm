"""Core-glTF asset packing: two skinned primitives, float geometry, 16-bit color/weights.

No Draco, meshopt or quantization extension is required by these files.
Geometry, normals, bone names and bind matrices are preserved without rounding.
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
        magic,version,size=struct.unpack_from('<III',self.raw,0)
        assert magic==0x46546C67 and version==2 and size==len(self.raw)
        n,kind=struct.unpack_from('<II',self.raw,12)
        assert kind==0x4E4F534A
        self.doc=json.loads(self.raw[20:20+n]);offset=20+n
        n,kind=struct.unpack_from('<II',self.raw,offset)
        assert kind==0x004E4942
        self.binary=self.raw[offset+8:offset+8+n]

    def array(self,index,normalized=True):
        a=self.doc['accessors'][index]
        assert 'sparse' not in a
        v=self.doc['bufferViews'][a['bufferView']]
        dtype=np.dtype(DTYPES[a['componentType']]);width=WIDTHS[a['type']]
        offset=v.get('byteOffset',0)+a.get('byteOffset',0)
        arr=np.ndarray((a['count'],width),dtype=dtype,buffer=self.binary,offset=offset,
            strides=(v.get('byteStride',width*dtype.itemsize),dtype.itemsize)).copy()
        if normalized and a.get('normalized'):
            if dtype.kind=='u':arr=arr.astype(np.float64)/np.iinfo(dtype).max
            else:arr=np.maximum(arr.astype(np.float64)/np.iinfo(dtype).max,-1)
        return arr


def pack(source,destination):
    source=GLB(source);d=source.doc
    assert len(d['skins'])==1 and len(d['materials'])==1
    assert not d.get('animations') and not d.get('images') and not d.get('extensionsRequired')
    parent={child:i for i,node in enumerate(d['nodes']) for child in node.get('children',[])}
    mesh_nodes=[(i,n) for i,n in enumerate(d['nodes']) if 'mesh' in n]
    assert len({parent.get(i) for i,n in mesh_nodes})==1
    for i,n in mesh_nodes:
        assert n.get('skin')==0
        assert all(k not in n for k in ('matrix','translation','rotation','scale'))

    groups={'MimicBody':[],'Biwa':[]}
    ranges={}
    original_triangles=0
    for node_id,node in mesh_nodes:
        mesh=d['meshes'][node['mesh']]
        assert len(mesh['primitives'])==1
        prim=mesh['primitives'][0]
        assert prim.get('mode',4)==4 and prim.get('material',0)==0
        attrs={k:source.array(v) for k,v in prim['attributes'].items()}
        assert set(attrs)=={'POSITION','NORMAL','COLOR_0','JOINTS_0','WEIGHTS_0'}
        indices=source.array(prim['indices'],False).reshape(-1)
        name=mesh['name']
        group='Biwa' if name in ('Biwa','Role_InstrumentTrim') else 'MimicBody'
        count=sum(len(a['POSITION']) for a,_,_,_ in groups[group])
        first_triangle=sum(len(t)//3 for _,t,_,_ in groups[group])
        ranges[name]={'mesh':group,'vertex_start':count,'vertex_count':len(attrs['POSITION']),
                      'triangle_start':first_triangle,'triangles':len(indices)//3}
        groups[group].append((attrs,indices,node_id,name))
        original_triangles+=len(indices)//3

    binary=bytearray();views=[];accessors=[];meshes=[]
    def accessor(arr,component,kind,target=None,normalized=False,bounds=False):
        arr=np.ascontiguousarray(arr,dtype=np.dtype(DTYPES[component]))
        binary.extend(b'\0'*(-len(binary)%4));offset=len(binary)
        block=arr.tobytes();binary.extend(block)
        view={'buffer':0,'byteOffset':offset,'byteLength':len(block)}
        if target:view['target']=target
        views.append(view)
        acc={'bufferView':len(views)-1,'componentType':component,'count':len(arr),'type':kind}
        if normalized:acc['normalized']=True
        if bounds:
            acc['min']=arr.min(axis=0).astype(float).tolist();acc['max']=arr.max(axis=0).astype(float).tolist()
        accessors.append(acc);return len(accessors)-1

    removed=set();keep_nodes={};groups_report={}
    max_color_error=0;max_weight_error=0
    for group,parts in groups.items():
        assert parts
        a={key:np.concatenate([row[0][key] for row in parts]) for key in parts[0][0]}
        idx=[];offset=0
        for attrs,indices,node_id,name in parts:
            idx.append(indices.astype(np.uint32)+offset);offset+=len(attrs['POSITION'])
        indices=np.concatenate(idx).reshape(-1,1)
        # Keep both RGB and alpha when present; the source palettes are linear values.
        colors=np.rint(np.clip(a['COLOR_0'],0,1)*65535).astype('<u2')
        color_width=colors.shape[1]
        if color_width==3:
            # Four ushort channels keep every vertex element 4-byte aligned.
            colors=np.column_stack((colors,np.full(len(colors),65535,dtype='<u2')))
        weights=a['WEIGHTS_0'].astype(float)
        weights/=weights.sum(axis=1,keepdims=True)
        packed=np.rint(weights*65535).astype(np.int64)
        correction=65535-packed.sum(axis=1)
        packed[np.arange(len(packed)),np.argmax(packed,axis=1)]+=correction
        packed=packed.astype('<u2')
        max_color_error=max(max_color_error,float(np.abs(colors[:,:color_width].astype(float)/65535-a['COLOR_0']).max()))
        max_weight_error=max(max_weight_error,float(np.abs(packed.astype(float)/65535-weights).max()))
        attrs={
            'POSITION':accessor(a['POSITION'],5126,'VEC3',34962,bounds=True),
            'NORMAL':accessor(a['NORMAL'],5126,'VEC3',34962),
            'COLOR_0':accessor(colors,5123,'VEC4' if colors.shape[1]==4 else 'VEC3',34962,True),
            'JOINTS_0':accessor(a['JOINTS_0'],5121,'VEC4',34962),
            'WEIGHTS_0':accessor(packed,5123,'VEC4',34962,True),
        }
        index_component=5123 if len(a['POSITION'])<=65535 else 5125
        index=accessor(indices,index_component,'SCALAR',34963)
        mesh_id=len(meshes)
        meshes.append({'name':group,'primitives':[{'attributes':attrs,'indices':index,'material':0}]})
        keep=parts[0][2];keep_nodes[keep]=(group,mesh_id)
        removed.update(p[2] for p in parts[1:])
        groups_report[group]={'vertices':len(a['POSITION']),'triangles':len(indices)//3,
                              'source_parts':[p[3] for p in parts]}

    remap={old:new for new,old in enumerate(i for i in range(len(d['nodes'])) if i not in removed)}
    nodes=[]
    for i,node in enumerate(d['nodes']):
        if i in removed:continue
        n=copy.deepcopy(node)
        if i in keep_nodes:
            n['name'],n['mesh']=keep_nodes[i]
            n.pop('extras',None)
        if 'children' in n:n['children']=[remap[c] for c in n['children'] if c not in removed]
        nodes.append(n)
    skins=copy.deepcopy(d['skins'])
    for skin in skins:
        skin['joints']=[remap[i] for i in skin['joints']]
        if 'skeleton' in skin:skin['skeleton']=remap[skin['skeleton']]
        if 'inverseBindMatrices' in skin:
            skin['inverseBindMatrices']=accessor(source.array(skin['inverseBindMatrices']),5126,'MAT4')
    scenes=copy.deepcopy(d['scenes'])
    for scene in scenes:scene['nodes']=[remap[i] for i in scene['nodes'] if i not in removed]
    document={'asset':{'version':'2.0','generator':'Mimic compact core-glTF pack'},
              'scene':d.get('scene',0),'scenes':scenes,'nodes':nodes,'skins':skins,
              'materials':copy.deepcopy(d['materials']),'meshes':meshes,
              'accessors':accessors,'bufferViews':views,'buffers':[{'byteLength':len(binary)}]}
    encoded=json.dumps(document,separators=(',',':')).encode();encoded+=b' '*(-len(encoded)%4)
    binary.extend(b'\0'*(-len(binary)%4))
    destination=Path(destination);destination.parent.mkdir(parents=True,exist_ok=True)
    destination.write_bytes(struct.pack('<III',0x46546C67,2,28+len(encoded)+len(binary))+
        struct.pack('<II',len(encoded),0x4E4F534A)+encoded+
        struct.pack('<II',len(binary),0x004E4942)+binary)
    return {'input_bytes':len(source.raw),'output_bytes':destination.stat().st_size,
            'input_meshes':len(mesh_nodes),'output_meshes':len(meshes),
            'triangles':original_triangles,'bones':len(skins[0]['joints']),
            'geometry_changed':False,'max_linear_color_error':max_color_error,
            'max_weight_error':max_weight_error,'groups':groups_report,'part_ranges':ranges,
            'extensions_required':[]}
