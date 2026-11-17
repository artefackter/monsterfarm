"""Pack five material groups into ordinary glTF, without decoder extensions."""
import copy, hashlib, json, struct
from pathlib import Path
import numpy as np

ROOT=Path(__file__).resolve().parent
DTYPES={5121:'u1',5123:'<u2',5125:'<u4',5126:'<f4'}
WIDTHS={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}

class GLB:
    def __init__(self,path):
        self.raw=Path(path).read_bytes()
        assert struct.unpack_from('<III',self.raw)==(0x46546C67,2,len(self.raw))
        size,kind=struct.unpack_from('<II',self.raw,12);assert kind==0x4E4F534A
        self.doc=json.loads(self.raw[20:20+size])
        n,kind=struct.unpack_from('<II',self.raw,20+size);assert kind==0x004E4942
        self.bin=self.raw[28+size:28+size+n]
    def array(self,index,normalized=True):
        a=self.doc['accessors'][index];v=self.doc['bufferViews'][a['bufferView']]
        dtype=np.dtype(DTYPES[a['componentType']]);width=WIDTHS[a['type']]
        offset=v.get('byteOffset',0)+a.get('byteOffset',0)
        arr=np.ndarray((a['count'],width),dtype=dtype,buffer=self.bin,offset=offset,
            strides=(v.get('byteStride',width*dtype.itemsize),dtype.itemsize)).copy()
        if normalized and a.get('normalized'):arr=arr.astype(float)/np.iinfo(dtype).max
        return arr

def pack():
    source=GLB(ROOT/'intermediate'/'Crypt-geometry.glb');doc=source.doc
    assert len(doc['nodes'])==1
    assert not any(k in doc['nodes'][0] for k in ('matrix','translation','rotation','scale'))
    groups={};max_error=0
    for primitive in doc['meshes'][0]['primitives']:
        material=copy.deepcopy(doc['materials'][primitive['material']])
        color=np.array(material['pbrMetallicRoughness'].get('baseColorFactor',[1,1,1,1]))
        material['pbrMetallicRoughness']['baseColorFactor']=[1,1,1,1]
        material.pop('name',None)
        key=json.dumps(material,sort_keys=True)
        if key not in groups:groups[key]={'material':material,'parts':[]}
        pos=source.array(primitive['attributes']['POSITION'])
        normal=source.array(primitive['attributes']['NORMAL'])
        indices=source.array(primitive['indices'],False).reshape(-1)
        colors=np.tile(np.rint(color*65535).astype('<u2'),(len(pos),1))
        max_error=max(max_error,float(np.abs(colors[0]/65535-color).max()))
        groups[key]['parts'].append((pos,normal,colors,indices))

    data=bytearray();views=[];accessors=[];meshes=[];materials=[]
    def array(value,component,kind,target,bounds=False,normalized=False):
        value=np.ascontiguousarray(value,dtype=DTYPES[component])
        data.extend(b'\0'*(-len(data)%4));offset=len(data);data.extend(value.tobytes())
        views.append({'buffer':0,'byteOffset':offset,'byteLength':value.nbytes,'target':target})
        a={'bufferView':len(views)-1,'componentType':component,'count':len(value),'type':kind}
        if normalized:a['normalized']=True
        if bounds:a.update(min=value.min(axis=0).astype(float).tolist(),max=value.max(axis=0).astype(float).tolist())
        accessors.append(a);return len(accessors)-1

    report=[]
    for group in groups.values():
        material=group['material'];pbr=material['pbrMetallicRoughness']
        if material.get('emissiveFactor'):
            name='LanternLight' if max(material['emissiveFactor'])>.5 else 'VioletInlays'
        elif pbr.get('metallicFactor',0)>.25:name='Iron'
        elif pbr.get('metallicFactor',0)>.1:name='Bronze'
        else:name='StoneAndRoof'
        material['name']='Crypt_'+name
        materials.append(material)
        pos=[];normal=[];color=[];indices=[];offset=0
        for p,n,c,idx in group['parts']:
            pos.append(p);normal.append(n);color.append(c);indices.append(idx.astype(np.uint32)+offset);offset+=len(p)
        p=np.concatenate(pos);n=np.concatenate(normal);c=np.concatenate(color);idx=np.concatenate(indices)
        # Only weld fully equal position, hard normal and palette color tuples.
        mapping={};keep=[];remap=[]
        for i in range(len(p)):
            key=p[i].tobytes()+n[i].tobytes()+c[i].tobytes()
            if key not in mapping:mapping[key]=len(keep);keep.append(i)
            remap.append(mapping[key])
        remap=np.array(remap,dtype=np.uint32);idx=remap[idx]
        p=p[keep];n=n[keep];c=c[keep]
        attrs={'POSITION':array(p,5126,'VEC3',34962,True),
               'NORMAL':array(n,5126,'VEC3',34962),
               'COLOR_0':array(c,5123,'VEC4',34962,normalized=True)}
        assert len(p)<65536
        index=array(idx.reshape(-1,1),5123,'SCALAR',34963)
        meshes.append({'name':'Crypt_'+name,'primitives':[{'attributes':attrs,'indices':index,'material':len(materials)-1}]})
        report.append({'name':name,'vertices':len(p),'triangles':len(idx)//3})
    assert len(meshes)==len(materials)==5
    out={'asset':{'version':'2.0','generator':'Crypt geometry and material optimization'},
         'scene':0,'scenes':[{'name':'Crypt','nodes':[0]}],
         'nodes':[{'name':'Crypt','children':list(range(1,len(meshes)+1))}]+[
             {'name':m['name'],'mesh':i} for i,m in enumerate(meshes)],
         'meshes':meshes,'materials':materials,'accessors':accessors,
         'bufferViews':views,'buffers':[{'byteLength':len(data)}]}
    if doc.get('extensionsUsed'):out['extensionsUsed']=doc['extensionsUsed']
    if doc.get('extensionsRequired'):out['extensionsRequired']=doc['extensionsRequired']
    encoded=json.dumps(out,separators=(',',':')).encode();encoded+=b' '*(-len(encoded)%4)
    data.extend(b'\0'*(-len(data)%4))
    output=ROOT/'Crypt-optimized.glb'
    output.write_bytes(struct.pack('<III',0x46546C67,2,28+len(encoded)+len(data))+
        struct.pack('<II',len(encoded),0x4E4F534A)+encoded+
        struct.pack('<II',len(data),0x004E4942)+data)
    baseline=GLB(ROOT.parent/'crypt-v1'/'Crypt.glb')
    before={'triangles':sum(baseline.doc['accessors'][p['indices']]['count']//3 for m in baseline.doc['meshes'] for p in m['primitives']),
            'meshes':len(baseline.doc['meshes']),'primitives':sum(len(m['primitives']) for m in baseline.doc['meshes']),
            'materials':len(baseline.doc['materials']),'bytes':len(baseline.raw)}
    after={'triangles':sum(r['triangles'] for r in report),'meshes':len(meshes),'primitives':len(meshes),
           'materials':len(materials),'bytes':output.stat().st_size}
    summary={'before':before,'after':after,
             'reduction_percent':{k:round(100*(1-after[k]/before[k]),2) for k in before},
             'max_linear_color_error':max_error,'position_normal_precision':'float32',
             'indices':'uint16','palette':'linear UNORM16','external_dependencies':False,
             'special_compression_decoder':False,'groups':report,
             'sha256':hashlib.sha256(output.read_bytes()).hexdigest()}
    (ROOT/'summary.json').write_text(json.dumps(summary,indent=2)+'\n')
    print(json.dumps(summary,indent=2))

if __name__=='__main__':pack()
