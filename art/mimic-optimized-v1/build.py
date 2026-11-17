"""Build compact model files and PNG sizes from preserved approved/draft originals."""
import json
import hashlib
from pathlib import Path
import numpy as np
from compact_glb import pack

ROOT=Path(__file__).resolve().parent
ART=ROOT.parent


def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def source_assets():
    assets=[]
    for state in ('Idle','Aggressive'):
        assets.append({'id':'Mimic_'+state,'role':'Base','ru':'Базовый','state':state,
            'model':str(ART/'mimic-v2/models'/('Mimic_'+state+'.glb')),
            'blend':str(ART/'mimic-v2/models'/('Mimic_'+state+'.blend'))})
    catalog=json.loads((ART/'mimic-forms-v1/catalog.json').read_text())
    for role,data in catalog['roles'].items():
        for state,row in data['states'].items():
            assets.append({'id':'Mimic_'+role+'_'+state,'role':role,'ru':data['ru'],'state':state,
                'model':str(ART/'mimic-forms-v1'/row['model']),
                'blend':str(ART/'mimic-forms-v1'/row['source'])})
    return assets


def verify_originals():
    for name in ('mimic-v2','mimic-forms-v1'):
        folder=ART/name
        approval=json.loads((folder/'approval.json').read_text())
        groups=[approval['forms']] if 'forms' in approval else [r['states'] for r in approval['roles'].values()]
        for group in groups:
            for row in group.values():
                for rel,meta in row['files'].items():assert sha(folder/rel)==meta['sha256'],rel
    for row in json.loads((ART/'mimic-icons-v1/validation.json').read_text())['files']:
        assert sha(ART/'mimic-icons-v1/icons'/(row['id']+'.png'))==row['sha256']


def build():
    from PIL import Image
    verify_originals()
    report={'status':'optimized_copies_for_review','game_integrated':False,
            'runtime_load_time_measured':False,'models':[],'icons':[]}
    for asset in source_assets():
        target=ROOT/'models'/(asset['id']+'.glb')
        stats=pack(asset['model'],target)
        asset.update(output=str(target.relative_to(ROOT)),source_sha256=sha(asset['model']),
                     output_sha256=sha(target),full=stats)
        report['models'].append(asset)
        print(asset['id'],stats['input_bytes'],'->',stats['output_bytes'],flush=True)
    icon_manifest=json.loads((ART/'mimic-icons-v1/assets.json').read_text())
    for asset in icon_manifest['assets']:
        source=ART/'mimic-icons-v1'/asset['file'];image=Image.open(source).convert('RGBA')
        row={'id':asset['id'],'ru':asset['ru'],'source':str(source),'source_bytes':source.stat().st_size,
             'source_size':list(image.size),'source_sha256':sha(source),
             'approval':'awaiting_icon_approval','variants':{}}
        for profile,size in [('ui512',512),('small256',256),('large1024',1024)]:
            resized=image.resize((size,size),Image.Resampling.LANCZOS)
            out=ROOT/'icons'/profile/(asset['id']+'.png')
            out.parent.mkdir(parents=True,exist_ok=True)
            resized.save(out,format='PNG',optimize=True,compress_level=9)
            loaded=Image.open(out)
            assert loaded.mode=='RGBA' and loaded.size==(size,size)
            assert np.array_equal(np.array(loaded),np.array(resized))
            assert loaded.getchannel('A').getextrema()==(0,255)
            row['variants'][profile]={'file':str(out.relative_to(ROOT)),'bytes':out.stat().st_size,
                'size':[size,size],'rgba8_uncompressed_bytes':size*size*4,'sha256':sha(out)}
        report['icons'].append(row)
        print(asset['id'],'PNG',row['source_bytes'],'->',row['variants']['ui512']['bytes'],flush=True)
    (ROOT/'report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    verify_originals()


if __name__=='__main__':build()
