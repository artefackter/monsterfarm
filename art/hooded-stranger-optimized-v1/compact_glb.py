"""Pack a textured skinned GLB into two meshes without changing its geometry.

Float32 positions/normals and all skeleton transforms remain exact. Color and
skin weights use standard glTF UNORM16. Face UVs are remapped to a lossless crop.
"""
import copy
import io
import json
import struct
from pathlib import Path
import numpy as np
from PIL import Image

DTYPES={5120:'i1',5121:'u1',5122:'<i2',5123:'<u2',5125:'<u4',5126:'<f4'}
WIDTHS={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}
CROP=(392,152,648,408)


class GLB:
    def __init__(self,path):
        self.path=Path(path)
        self.raw=self.path.read_bytes()
        assert struct.unpack_from('<III',self.raw)==(0x46546C67,2,len(self.raw))
        size,kind=struct.unpack_from('<II',self.raw,12)
        assert kind==0x4E4F534A
        self.doc=json.loads(self.raw[20:20+size])
        length,kind=struct.unpack_from('<II',self.raw,20+size)
        assert kind==0x004E4942
        self.binary=self.raw[28+size:28+size+length]

    def array(self,index,normalized=True):
        a=self.doc['accessors'][index]
        assert 'sparse' not in a
        view=self.doc['bufferViews'][a['bufferView']]
        dtype=np.dtype(DTYPES[a['componentType']]);width=WIDTHS[a['type']]
        offset=view.get('byteOffset',0)+a.get('byteOffset',0)
        result=np.ndarray((a['count'],width),dtype=dtype,buffer=self.binary,offset=offset,
            strides=(view.get('byteStride',width*dtype.itemsize),dtype.itemsize)).copy()
        if normalized and a.get('normalized'):
            result=result.astype(np.float64)/np.iinfo(dtype).max
        return result

    def image_bytes(self,index=0):
        image=self.doc['images'][index]
        view=self.doc['bufferViews'][image['bufferView']]
        offset=view.get('byteOffset',0)
        return self.binary[offset:offset+view['byteLength']]


def pack(source,destination,texture_destination):
    source=GLB(source);doc=source.doc
    assert len(doc['skins'])==1 and len(doc['materials'])==2 and len(doc['images'])==1
    assert not doc.get('animations') and not doc.get('extensionsRequired')
    image=Image.open(io.BytesIO(source.image_bytes()))
    assert image.size==(1000,562) and image.mode=='RGB'
    cropped=image.crop(CROP)
    payload=io.BytesIO()
    cropped.save(payload,format='PNG',optimize=True,compress_level=9)
    texture_bytes=payload.getvalue()
    texture_destination=Path(texture_destination)
    texture_destination.parent.mkdir(parents=True,exist_ok=True)
    if texture_destination.exists():
        assert texture_destination.read_bytes()==texture_bytes
    else:
        texture_destination.write_bytes(texture_bytes)
    parent={child:i for i,node in enumerate(doc['nodes']) for child in node.get('children',[])}
    mesh_nodes=[(i,n) for i,n in enumerate(doc['nodes']) if 'mesh' in n]
    assert len({parent.get(i) for i,node in mesh_nodes})==1
    groups={'StrangerBody':[],'Face':[]}
    ranges={}
    for node_id,node in mesh_nodes:
        assert node.get('skin')==0
        assert not any(k in node for k in ('matrix','translation','rotation','scale'))
        mesh=doc['meshes'][node['mesh']]
        assert len(mesh['primitives'])==1
        primitive=mesh['primitives'][0]
        assert primitive.get('mode',4)==4
        attributes={key:source.array(index) for key,index in primitive['attributes'].items()}
        group='Face' if mesh['name']=='Face' else 'StrangerBody'
        if group=='Face':
            # Blender exported two unused all-white layers on the textured face.
            # Default glTF vertex tint is white, so both arrays are redundant.
            for key in list(attributes):
                if key.startswith('COLOR_'):
                    assert np.all(attributes[key]==1),(mesh['name'],key)
                    attributes.pop(key)
        required={'POSITION','NORMAL','JOINTS_0','WEIGHTS_0',
                  'TEXCOORD_0' if group=='Face' else 'COLOR_0'}
        assert set(attributes)==required,(mesh['name'],set(attributes))
        assert primitive.get('material',0)==(1 if group=='Face' else 0)
        indices=source.array(primitive['indices'],False).reshape(-1)
        start=sum(len(row[0]['POSITION']) for row in groups[group])
        tri_start=sum(len(row[1])//3 for row in groups[group])
        ranges[mesh['name']]={'mesh':group,'vertex_start':start,
            'vertex_count':len(attributes['POSITION']),'triangle_start':tri_start,
            'triangles':len(indices)//3}
        groups[group].append((attributes,indices,node_id,mesh['name']))

    binary=bytearray();views=[];accessors=[];meshes=[]
    def block(payload,target=None):
        binary.extend(b'\0'*(-len(binary)%4))
        offset=len(binary);binary.extend(payload)
        view={'buffer':0,'byteOffset':offset,'byteLength':len(payload)}
        if target:
            view['target']=target
        views.append(view)
        return len(views)-1
    def accessor(array,component,kind,target=None,normalized=False,bounds=False):
        array=np.ascontiguousarray(array,dtype=np.dtype(DTYPES[component]))
        view=block(array.tobytes(),target)
        a={'bufferView':view,'componentType':component,'count':len(array),'type':kind}
        if normalized:
            a['normalized']=True
        if bounds:
            a['min']=array.min(axis=0).astype(float).tolist()
            a['max']=array.max(axis=0).astype(float).tolist()
        accessors.append(a)
        return len(accessors)-1

    keep_nodes={};removed=set();stats={}
    max_color_error=0;max_weight_error=0;uv_pixel_error=0
    for group,parts in groups.items():
        assert parts
        arrays={k:np.concatenate([p[0][k] for p in parts]) for k in parts[0][0]}
        rows=[];offset=0
        for attributes,indices,node_id,name in parts:
            rows.append(indices.astype(np.uint32)+offset)
            offset+=len(attributes['POSITION'])
        indices=np.concatenate(rows).reshape(-1,1)
        weights=arrays['WEIGHTS_0'].astype(float)
        weights/=weights.sum(axis=1,keepdims=True)
        packed_weights=np.rint(weights*65535).astype(np.int64)
        packed_weights[np.arange(len(weights)),np.argmax(packed_weights,axis=1)]+=65535-packed_weights.sum(axis=1)
        max_weight_error=max(max_weight_error,float(np.abs(packed_weights/65535-weights).max()))
        attrs={
            'POSITION':accessor(arrays['POSITION'],5126,'VEC3',34962,bounds=True),
            'NORMAL':accessor(arrays['NORMAL'],5126,'VEC3',34962),
            'JOINTS_0':accessor(arrays['JOINTS_0'],5121,'VEC4',34962),
            'WEIGHTS_0':accessor(packed_weights,5123,'VEC4',34962,normalized=True),
        }
        if group=='Face':
            uv=arrays['TEXCOORD_0'].astype(np.float64)
            uv[:,0]=(uv[:,0]*image.width-CROP[0])/cropped.width
            uv[:,1]=(uv[:,1]*image.height-(image.height-CROP[3]))/cropped.height
            assert uv.min()>0 and uv.max()<1
            uv32=uv.astype('<f4')
            uv_pixel_error=float(np.abs(uv32.astype(float)-uv).max()*cropped.width)
            attrs['TEXCOORD_0']=accessor(uv32,5126,'VEC2',34962)
        else:
            original=arrays['COLOR_0']
            colors=np.rint(np.clip(original,0,1)*65535).astype('<u2')
            width=colors.shape[1]
            max_color_error=max(max_color_error,float(np.abs(colors.astype(float)/65535-original).max()))
            if width==3:
                colors=np.column_stack((colors,np.full(len(colors),65535,dtype='<u2')))
            attrs['COLOR_0']=accessor(colors,5123,'VEC4',34962,normalized=True)
        component=5123 if len(arrays['POSITION'])<=65535 else 5125
        index=accessor(indices,component,'SCALAR',34963)
        mesh_id=len(meshes)
        meshes.append({'name':group,'primitives':[{'attributes':attrs,'indices':index,
                                                'material':1 if group=='Face' else 0}]})
        keep_nodes[parts[0][2]]=(group,mesh_id)
        removed.update(row[2] for row in parts[1:])
        stats[group]={'vertices':len(arrays['POSITION']),'triangles':len(indices)//3,
                      'source_parts':[row[3] for row in parts]}

    remap={old:new for new,old in enumerate(i for i in range(len(doc['nodes'])) if i not in removed)}
    nodes=[]
    for i,node in enumerate(doc['nodes']):
        if i in removed:
            continue
        n=copy.deepcopy(node)
        if i in keep_nodes:
            n['name'],n['mesh']=keep_nodes[i]
            n.pop('extras',None)
        if 'children' in n:
            n['children']=[remap[c] for c in n['children'] if c not in removed]
        nodes.append(n)
    skins=copy.deepcopy(doc['skins'])
    for skin in skins:
        skin['joints']=[remap[i] for i in skin['joints']]
        if 'skeleton' in skin:
            skin['skeleton']=remap[skin['skeleton']]
        skin['inverseBindMatrices']=accessor(source.array(skin['inverseBindMatrices']),5126,'MAT4')
    scenes=copy.deepcopy(doc['scenes'])
    for scene in scenes:
        scene['nodes']=[remap[i] for i in scene['nodes'] if i not in removed]
    image_view=block(texture_bytes)
    out={'asset':{'version':'2.0','generator':'Hooded Stranger compact texture/skinning pack'},
        'scene':doc.get('scene',0),'scenes':scenes,'nodes':nodes,'skins':skins,
        'materials':copy.deepcopy(doc['materials']),'meshes':meshes,
        'textures':copy.deepcopy(doc['textures']),'samplers':copy.deepcopy(doc['samplers']),
        'images':[{'name':'FaceAtlas256','mimeType':'image/png','bufferView':image_view}],
        'accessors':accessors,'bufferViews':views,'buffers':[{'byteLength':len(binary)}]}
    for key in ('extensionsUsed','extensionsRequired'):
        if key in doc:
            out[key]=copy.deepcopy(doc[key])
    encoded=json.dumps(out,separators=(',',':')).encode()
    encoded+=b' '*(-len(encoded)%4)
    binary.extend(b'\0'*(-len(binary)%4))
    destination=Path(destination)
    destination.parent.mkdir(parents=True,exist_ok=True)
    destination.write_bytes(struct.pack('<III',0x46546C67,2,28+len(encoded)+len(binary))+
        struct.pack('<II',len(encoded),0x4E4F534A)+encoded+
        struct.pack('<II',len(binary),0x004E4942)+binary)
    return {'input_bytes':len(source.raw),'output_bytes':destination.stat().st_size,
        'input_meshes':len(mesh_nodes),'output_meshes':2,'bones':len(skins[0]['joints']),
        'triangles':sum(s['triangles'] for s in stats.values()),'groups':stats,'part_ranges':ranges,
        'position_normal_triangle_changes':False,'max_linear_color_error':max_color_error,
        'max_weight_error':max_weight_error,'max_uv_pixel_error':uv_pixel_error,
        'source_texture_size':list(image.size),'output_texture_size':list(cropped.size),
        'texture_crop':list(CROP),'source_texture_bytes':len(source.image_bytes()),
        'output_texture_bytes':len(texture_bytes),'texture_pixels_resampled':False,
        'removed_face_color_layers':'All-white COLOR_0 and COLOR_1; default white is identical',
        'compression_decoder_required':False,'extensions_used':out.get('extensionsUsed',[])}
