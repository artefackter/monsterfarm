"""Validate geometry, packing fidelity, colors, source preservation and renders."""
import bpy, hashlib, json, math, sys
from collections import Counter, defaultdict
from pathlib import Path
import numpy as np

ROOT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT))
from pack import GLB

source=GLB(ROOT.parent/'crypt-v1'/'Crypt.glb')
geometry=GLB(ROOT/'intermediate'/'Crypt-geometry.glb')
optimized=GLB(ROOT/'Crypt-optimized.glb')
summary=json.loads((ROOT/'summary.json').read_text())
geometry_report=json.loads((ROOT/'geometry_report.json').read_text())
assert hashlib.sha256(source.raw).hexdigest()==geometry_report['source_sha256']
assert hashlib.sha256(optimized.raw).hexdigest()==summary['sha256']
assert not optimized.doc.get('images') and not optimized.doc.get('animations') and not optimized.doc.get('skins')
assert not optimized.doc.get('extensionsRequired')
assert all('uri' not in b for b in optimized.doc['buffers'])

def material_key(m):
    d=json.loads(json.dumps(m));d.pop('name',None)
    d['pbrMetallicRoughness']['baseColorFactor']=[1,1,1,1]
    return json.dumps(d,sort_keys=True)

def check(asset,collect=False):
    counters=defaultdict(Counter);all_positions=[];triangles=0;vertices=0
    for view in asset.doc['bufferViews']:
        assert view.get('byteOffset',0)%4==0
        assert view.get('byteOffset',0)+view['byteLength']<=len(asset.bin)
    for node in asset.doc['nodes']:
        assert not any(k in node for k in ('matrix','translation','rotation','scale'))
    for mesh in asset.doc['meshes']:
        for primitive in mesh['primitives']:
            assert primitive.get('mode',4)==4
            p=asset.array(primitive['attributes']['POSITION'])
            n=asset.array(primitive['attributes']['NORMAL'])
            assert p.dtype==n.dtype==np.dtype('<f4')
            assert np.isfinite(p).all() and np.isfinite(n).all()
            assert np.max(np.abs(np.linalg.norm(n,axis=1)-1))<1e-5
            idx=asset.array(primitive['indices'],False).reshape(-1)
            assert len(idx)%3==0 and idx.min()>=0 and idx.max()<len(p)
            tri=p[idx].reshape(-1,3,3)
            area=np.linalg.norm(np.cross(tri[:,1]-tri[:,0],tri[:,2]-tri[:,0]),axis=1)
            assert area.min()>1e-8,(mesh['name'],float(area.min()))
            material=asset.doc['materials'][primitive['material']]
            if 'COLOR_0' in primitive['attributes']:
                c=asset.array(primitive['attributes']['COLOR_0'],False)
                acc=asset.doc['accessors'][primitive['attributes']['COLOR_0']]
                assert acc['normalized'] and acc['componentType']==5123
            else:
                color=material['pbrMetallicRoughness'].get('baseColorFactor',[1,1,1,1])
                c=np.tile(np.rint(np.array(color)*65535).astype('<u2'),(len(p),1))
            if collect:
                vertex=[p[i].tobytes()+n[i].tobytes()+c[i].tobytes() for i in range(len(p))]
                key=material_key(material)
                for row in idx.reshape(-1,3):
                    counters[key][tuple(vertex[i] for i in row)]+=1
            triangles+=len(idx)//3;vertices+=len(p);all_positions.append(p)
    pos=np.concatenate(all_positions)
    return dict(triangles=triangles,vertices=vertices,bounds=[pos.min(axis=0).tolist(),pos.max(axis=0).tolist()]),counters

base_stats,_=check(source)
geometry_stats,expected=check(geometry,True)
out_stats,actual=check(optimized,True)
assert expected==actual,'Packing changed a triangle, hard normal, material or quantized color'
assert out_stats['triangles']==summary['after']['triangles']==3751
assert base_stats['triangles']==summary['before']['triangles']==7822
assert out_stats['bounds']==base_stats['bounds']
assert len(optimized.doc['meshes'])==len(optimized.doc['materials'])==5
assert all(len(m['primitives'])==1 for m in optimized.doc['meshes'])
assert all(set(p['attributes'])=={'POSITION','NORMAL','COLOR_0'} for m in optimized.doc['meshes'] for p in m['primitives'])

differences={}
for view in ('three_quarter','front','back'):
    arrays=[]
    for label in ('original','optimized'):
        image=bpy.data.images.load(str(ROOT/'previews'/(label+'_'+view+'.png')),check_existing=False)
        a=np.empty(len(image.pixels),dtype=np.float32);image.pixels.foreach_get(a)
        arrays.append(a.reshape(-1,4)[:,:3])
        bpy.data.images.remove(image)
    delta=np.abs(arrays[0]-arrays[1])
    differences[view]={'mean_absolute_linear_rgb_difference':float(delta.mean()),
                       'pixels_with_any_channel_difference_over_0_05_percent':float(100*np.mean(delta.max(axis=1)>.05))}

report={'valid':True,'original_unchanged':True,'bounds_unchanged':True,
        'packing_preserves_all_surviving_triangles_normals_and_materials':True,
        'max_linear_palette_error':summary['max_linear_color_error'],
        'original':base_stats,'optimized':out_stats,'visual_differences':differences,
        'external_dependencies':False,'runtime_performance_measured':False,
        'studio_import_tested':False,'visual_review':'front, three-quarter and back reviewed'}
(ROOT/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
print('CRYPT_OPTIMIZATION_VALIDATED',json.dumps(report),flush=True)
