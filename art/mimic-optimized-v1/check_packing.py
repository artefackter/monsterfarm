"""Validate data preservation directly in the binary GLB, independently of Blender."""
import json
from pathlib import Path
import numpy as np
from compact_glb import GLB
from build import sha,verify_originals

ROOT=Path(__file__).resolve().parent
report=json.loads((ROOT/'report.json').read_text())
checks=[]
for asset in report['models']:
    source=GLB(asset['model'])
    for profile,path_key in [('full','output'),('mobile','mobile_file')]:
        if path_key not in asset:continue
        target=GLB(ROOT/asset[path_key]);stats=asset[profile]
        d=target.doc
        assert len(d['meshes'])==2 and len(d['skins'])==1 and len(d['materials'])==1
        assert not d.get('extensionsRequired') and not d.get('extensionsUsed')
        assert not d.get('animations') and not d.get('images')
        old_skin=source.doc['skins'][0];new_skin=d['skins'][0]
        old_bones=[source.doc['nodes'][i]['name'] for i in old_skin['joints']]
        new_bones=[d['nodes'][i]['name'] for i in new_skin['joints']]
        assert old_bones==new_bones and len(new_bones)==37
        assert np.array_equal(source.array(old_skin['inverseBindMatrices']),target.array(new_skin['inverseBindMatrices']))
        for old_id,new_id in zip(old_skin['joints'],new_skin['joints']):
            for key in ('matrix','translation','rotation','scale'):
                assert source.doc['nodes'][old_id].get(key)==d['nodes'][new_id].get(key)
        groups={}
        triangles=0
        for m in d['meshes']:
            assert len(m['primitives'])==1
            p=m['primitives'][0]
            arrays={k:target.array(i) for k,i in p['attributes'].items()}
            assert set(arrays)=={'POSITION','NORMAL','COLOR_0','JOINTS_0','WEIGHTS_0'}
            indices=target.array(p['indices'],False).reshape(-1)
            assert indices.min()>=0 and indices.max()<len(arrays['POSITION'])
            assert all(np.isfinite(a).all() for a in arrays.values())
            assert np.abs(arrays['WEIGHTS_0'].sum(axis=1)-1).max()<1e-12
            assert arrays['JOINTS_0'].max()<37
            xyz=arrays['POSITION'][indices].reshape(-1,3,3)
            areas=np.cross(xyz[:,1]-xyz[:,0],xyz[:,2]-xyz[:,0])
            assert np.all(np.linalg.norm(areas,axis=1)>1e-8),(asset['id'],profile,'degenerate triangle')
            for key,index in p['attributes'].items():
                acc=d['accessors'][index];view=d['bufferViews'][acc['bufferView']]
                assert (view.get('byteOffset',0)+acc.get('byteOffset',0))%4==0
            groups[m['name']]=(arrays,indices)
            triangles+=len(indices)//3
        assert triangles==stats['triangles']
        # The main pack has byte-identical position and normal float values, and
        # unchanged triangulation for every original object; only numeric encodings differ.
        intermediate=ROOT/'intermediate'/(asset['id']+'.glb')
        has_packing_input=profile=='full' or intermediate.exists()
        parts_source=source if profile=='full' or not intermediate.exists() else GLB(intermediate)
        protected={r['name'] for r in stats.get('mesh_geometry_changes',[]) if r['protected']}
        for mesh in parts_source.doc['meshes']:
            if not has_packing_input and mesh['name'] not in protected:continue
            p=mesh['primitives'][0];r=stats['part_ranges'][mesh['name']]
            arrays,indices=groups[r['mesh']];start=r['vertex_start'];end=start+r['vertex_count']
            for key in ('POSITION','NORMAL','JOINTS_0'):
                assert np.array_equal(parts_source.array(p['attributes'][key]),arrays[key][start:end]),(asset['id'],profile,mesh['name'],key)
            old_indices=parts_source.array(p['indices'],False).reshape(-1)
            begin=r['triangle_start']*3
            assert np.array_equal(old_indices+start,indices[begin:begin+len(old_indices)])
        checks.append({'id':asset['id'],'profile':profile,'passed':True,
            'triangles':triangles,'meshes':2,'bones':37,'sha256':sha(ROOT/asset[path_key]),
            'packing_input_available':has_packing_input,
            'geometry_preserved_from_packing_input':has_packing_input,
            'protected_geometry_checked':profile=='mobile'})
verify_originals()
(ROOT/'packing_validation.json').write_text(json.dumps({'passed':True,'checks':checks},indent=2)+'\n')
print('PACKING_VALIDATED',len(checks))
