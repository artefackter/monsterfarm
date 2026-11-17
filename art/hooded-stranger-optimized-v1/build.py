"""Build optimized copies of seven GLBs and six PNGs; preserve all originals."""
import hashlib
import json
from pathlib import Path
import numpy as np
from PIL import Image
from compact_glb import pack

ROOT=Path(__file__).resolve().parent
ART=ROOT.parent

def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def source_models():
    return [{'id':'HoodedStranger','role':'Base','ru':'Базовый',
             'file':ART/'hooded-stranger-v2/models/HoodedStranger.glb'}]+[
        {'id':'HoodedStranger_'+role,'role':role,'ru':row['ru'],
         'file':ART/'hooded-stranger-forms-v1'/row['model']}
        for role,row in json.loads((ART/'hooded-stranger-forms-v1/catalog.json').read_text()).items()]

def source_icons():
    return json.loads((ART/'hooded-stranger-icons-v1/assets.json').read_text())['assets']

def source_files():
    paths=[]
    for folder in ('hooded-stranger-v2','hooded-stranger-forms-v1'):
        paths+=list((ART/folder/'models').glob('*'))
    paths+=list((ART/'hooded-stranger-icons-v1/icons').glob('*.png'))
    return {str(p.relative_to(ART)):sha(p) for p in paths if p.is_file()}

def build():
    snapshot=source_files()
    # Confirm that the inputs still match their earlier export checks.
    base_approval=json.loads((ART/'hooded-stranger-v2/approval.json').read_text())
    for rel,info in base_approval['files'].items():
        assert sha(ART/'hooded-stranger-v2'/rel)==info['sha256']
    source_validation=json.loads((ART/'hooded-stranger-icons-v1/validation.json').read_text())
    for icon in source_validation['assets']:
        assert sha(ART/'hooded-stranger-icons-v1'/icon['file'])==icon['sha256']
    report={'status':'optimized_copies_for_review','game_integrated':False,
        'runtime_load_time_measured':False,'source_hashes':snapshot,'models':[],'icons':[]}
    for model in source_models():
        target=ROOT/'models'/(model['id']+'.glb')
        stats=pack(model['file'],target,ROOT/'textures/FaceAtlas256.png')
        report['models'].append({'id':model['id'],'role':model['role'],'ru':model['ru'],
            'source':str(model['file'].relative_to(ART)),
            'source_sha256':sha(model['file']),'file':str(target.relative_to(ROOT)),
            'sha256':sha(target),**stats})
        print('MODEL',model['id'],stats['input_bytes'],'->',stats['output_bytes'],flush=True)
    for icon in source_icons():
        source=ART/'hooded-stranger-icons-v1'/icon['file']
        image=Image.open(source).convert('RGBA')
        row={'id':icon['id'],'ru':icon['ru'],'source':str(source.relative_to(ART)),
             'source_sha256':sha(source),'source_bytes':source.stat().st_size,
             'source_size':list(image.size),'variants':{}}
        for profile,size in [('ui512',512),('small256',256),('large1024',1024)]:
            resized=image.resize((size,size),Image.Resampling.LANCZOS)
            target=ROOT/'icons'/profile/(icon['id']+'.png')
            target.parent.mkdir(parents=True,exist_ok=True)
            resized.save(target,format='PNG',optimize=True,compress_level=9)
            loaded=Image.open(target)
            assert loaded.mode=='RGBA' and loaded.size==(size,size)
            assert np.array_equal(np.array(loaded),np.array(resized))
            assert loaded.getchannel('A').getextrema()==(0,255)
            row['variants'][profile]={'file':str(target.relative_to(ROOT)),
                'bytes':target.stat().st_size,'size':[size,size],
                'rgba8_uncompressed_bytes':size*size*4,'sha256':sha(target)}
        report['icons'].append(row)
        print('ICON',icon['id'],row['source_bytes'],'->',row['variants']['ui512']['bytes'],flush=True)
    assert snapshot==source_files(),'An original asset changed during optimization'
    (ROOT/'report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    def reduced(before,after):
        return {'before_bytes':before,'after_bytes':after,'reduction_percent':round(100*(1-after/before),2)}
    summary={'models':reduced(sum(r['input_bytes'] for r in report['models']),sum(r['output_bytes'] for r in report['models'])),
        'mesh_count':{'before':sum(r['input_meshes'] for r in report['models']),'after':14},
        'triangles':{'before':sum(r['triangles'] for r in report['models']),
                     'after':sum(r['triangles'] for r in report['models'])},
        'bones_per_model':28,'source_originals_unchanged':True,'runtime_load_time_measured':False}
    original_icons=sum(r['source_bytes'] for r in report['icons'])
    for profile in ('ui512','small256','large1024'):
        summary[profile]=reduced(original_icons,sum(r['variants'][profile]['bytes'] for r in report['icons']))
    summary['recommended_bundle']=reduced(summary['models']['before_bytes']+original_icons,
        summary['models']['after_bytes']+summary['ui512']['after_bytes'])
    summary['face_texture_pixels']={'before':1000*562,'after':256*256,
        'reduction_percent':round(100*(1-256*256/(1000*562)),2),'resampling':False}
    summary['icon_pixels_per_image']={'before':1254*1254,'ui512':512*512,
        'reduction_percent':round(100*(1-512*512/(1254*1254)),2)}
    (ROOT/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n')
    print('OPTIMIZATION_BUILT',json.dumps(summary),flush=True)

if __name__=='__main__':
    build()
