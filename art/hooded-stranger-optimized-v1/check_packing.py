"""Independent binary checks of geometry, skeleton, pixels, skin weights and UVs."""
import io
import json
from pathlib import Path
import numpy as np
from PIL import Image
from compact_glb import GLB,CROP
from build import sha,source_files

ROOT=Path(__file__).resolve().parent
ART=ROOT.parent
report=json.loads((ROOT/'report.json').read_text())
assert source_files()==report['source_hashes']
checks=[]
for item in report['models']:
    source=GLB(ART/item['source']);target=GLB(ROOT/item['file'])
    assert sha(ROOT/item['file'])==item['sha256']
    assert len(target.doc['meshes'])==2 and len(target.doc['skins'])==1
    assert source.doc['materials']==target.doc['materials']
    assert source.doc.get('extensionsUsed')==target.doc.get('extensionsUsed')
    assert not target.doc.get('extensionsRequired') and not target.doc.get('animations')
    assert source.doc['samplers']==target.doc['samplers']
    old=source.doc['skins'][0];new=target.doc['skins'][0]
    old_names=[source.doc['nodes'][i]['name'] for i in old['joints']]
    new_names=[target.doc['nodes'][i]['name'] for i in new['joints']]
    assert old_names==new_names and len(new_names)==28
    assert np.array_equal(source.array(old['inverseBindMatrices']),target.array(new['inverseBindMatrices']))
    old_parent={c:i for i,n in enumerate(source.doc['nodes']) for c in n.get('children',[])}
    new_parent={c:i for i,n in enumerate(target.doc['nodes']) for c in n.get('children',[])}
    for a,b in zip(old['joints'],new['joints']):
        n1,n2=source.doc['nodes'][a],target.doc['nodes'][b]
        for key in ('matrix','translation','rotation','scale'):
            assert n1.get(key)==n2.get(key)
        assert source.doc['nodes'][old_parent[a]]['name']==target.doc['nodes'][new_parent[b]]['name']
    groups={}
    for mesh in target.doc['meshes']:
        primitive=mesh['primitives'][0]
        arrays={k:target.array(i) for k,i in primitive['attributes'].items()}
        indices=target.array(primitive['indices'],False).reshape(-1)
        assert all(np.isfinite(a).all() for a in arrays.values())
        assert indices.min()>=0 and indices.max()<len(arrays['POSITION'])
        assert np.abs(arrays['WEIGHTS_0'].sum(axis=1)-1).max()<1e-12
        assert arrays['JOINTS_0'].max()<28
        xyz=arrays['POSITION'][indices].reshape(-1,3,3)
        assert np.all(np.linalg.norm(np.cross(xyz[:,1]-xyz[:,0],xyz[:,2]-xyz[:,0]),axis=1)>2e-12)
        for key,index in primitive['attributes'].items():
            a=target.doc['accessors'][index]
            v=target.doc['bufferViews'][a['bufferView']]
            assert (v.get('byteOffset',0)+a.get('byteOffset',0))%4==0
        groups[mesh['name']]=(arrays,indices)
    triangles=0;max_uv_pixel_error=0;max_color_error=0;max_weight_error=0
    for mesh in source.doc['meshes']:
        primitive=mesh['primitives'][0]
        part=item['part_ranges'][mesh['name']]
        arrays,indices=groups[part['mesh']]
        start=part['vertex_start'];end=start+part['vertex_count']
        for key in ('POSITION','NORMAL','JOINTS_0'):
            assert np.array_equal(source.array(primitive['attributes'][key]),arrays[key][start:end]),(item['id'],mesh['name'],key)
        old_indices=source.array(primitive['indices'],False).reshape(-1)
        begin=part['triangle_start']*3
        assert np.array_equal(old_indices+start,indices[begin:begin+len(old_indices)])
        triangles+=len(old_indices)//3
        old_weights=source.array(primitive['attributes']['WEIGHTS_0']).astype(float)
        old_weights/=old_weights.sum(axis=1,keepdims=True)
        weight_error=float(np.abs(old_weights-arrays['WEIGHTS_0'][start:end]).max())
        max_weight_error=max(max_weight_error,weight_error)
        assert weight_error<.000016
        if mesh['name']=='Face':
            old_uv=source.array(primitive['attributes']['TEXCOORD_0']).astype(float)*[1000,562]
            restored=arrays['TEXCOORD_0'][start:end].astype(float)*256+[CROP[0],562-CROP[3]]
            error=float(np.abs(restored-old_uv).max())
            max_uv_pixel_error=max(max_uv_pixel_error,error)
            assert error<.00005
            for key,index in primitive['attributes'].items():
                if key.startswith('COLOR_'):
                    assert np.all(source.array(index)==1)
        else:
            original=source.array(primitive['attributes']['COLOR_0'])
            error=float(np.abs(original-arrays['COLOR_0'][start:end,:original.shape[1]]).max())
            max_color_error=max(max_color_error,error)
            assert error<.000008
    assert triangles==item['triangles']
    image_before=Image.open(io.BytesIO(source.image_bytes())).convert('RGB')
    image_after=Image.open(io.BytesIO(target.image_bytes())).convert('RGB')
    assert image_after.size==(256,256)
    assert np.array_equal(np.asarray(image_before.crop(CROP)),np.asarray(image_after))
    assert target.image_bytes()==(ROOT/'textures/FaceAtlas256.png').read_bytes()
    checks.append({'id':item['id'],'passed':True,'triangles':triangles,'meshes':2,'bones':28,
        'exact_positions_normals_triangles_joints':True,'exact_skeleton_and_bind_matrices':True,
        'exact_face_crop_pixels':True,'max_uv_pixel_error':max_uv_pixel_error,
        'max_linear_color_error':max_color_error,'max_weight_error':max_weight_error})
    print('PACKING_VERIFIED',item['id'],flush=True)

icon_checks=[]
for item in report['icons']:
    original=Image.open(ART/item['source']).convert('RGBA')
    assert sha(ART/item['source'])==item['source_sha256']
    comparison=[]
    for profile,meta in item['variants'].items():
        loaded=Image.open(ROOT/meta['file']).convert('RGBA')
        assert loaded.size==tuple(meta['size']) and sha(ROOT/meta['file'])==meta['sha256']
        expected=original.resize(tuple(meta['size']),Image.Resampling.LANCZOS)
        assert np.array_equal(np.asarray(loaded),np.asarray(expected))
        for size in (64,96,128):
            base=original.resize((size,size),Image.Resampling.LANCZOS)
            candidate=loaded.resize((size,size),Image.Resampling.LANCZOS)
            for background in ('#F6EDD8','#19212B'):
                base_rgb=Image.alpha_composite(Image.new('RGBA',(size,size),background),base).convert('RGB')
                next_rgb=Image.alpha_composite(Image.new('RGBA',(size,size),background),candidate).convert('RGB')
                delta=np.abs(np.asarray(base_rgb).astype(float)-np.asarray(next_rgb).astype(float))
                mae=float(delta.mean())
                assert mae<2.0,(item['id'],profile,size,mae)
                comparison.append({'profile':profile,'display_size':size,'background':background,
                    'mean_absolute_rgb_error_255':round(mae,5),'max_channel_error':int(delta.max())})
    icon_checks.append({'id':item['id'],'passed':True,'unchanged_after_deterministic_resize':True,
                        'comparisons':comparison})
assert source_files()==report['source_hashes']
(ROOT/'packing_validation.json').write_text(json.dumps({'passed':True,'source_originals_unchanged':True,
    'models':checks,'icons':icon_checks},ensure_ascii=False,indent=2)+'\n')
print('ALL_PACKING_AND_ICON_CHECKS_PASSED',flush=True)
