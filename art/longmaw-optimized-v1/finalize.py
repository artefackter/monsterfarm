"""Write measured summary/manifest and package candidates, keeping sources intact."""
import json
from zipfile import ZipFile,ZIP_DEFLATED
from assets import ROOT,verify_sources,sha

def write(name,data):
    (ROOT/name).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')

def savings(before,after):
    return {'source_bytes':before,'output_bytes':after,
            'reduction_percent':round((1-after/before)*100,3)}

models=json.loads((ROOT/'models_report.json').read_text())['models']
icons=json.loads((ROOT/'icons_report.json').read_text())['icons']
validation=json.loads((ROOT/'blender_validation.json').read_text())
assert validation['passed'] and validation['validated_outputs']==28
assert len(models)==14 and len(icons)==6
for result in validation['results']:
    path=ROOT/result['profile']/(result['id']+'.glb')
    assert sha(path)==result['sha256']
before=sum(m['profiles']['models']['input_bytes'] for m in models)
icon_before=sum(i['source_bytes'] for i in icons)
summary={'status':'awaiting_owner_review','integrated':False,'runtime_loading_measured':False,
    'model_count':14,'icon_count':6,'model_profiles':{},'icon_profiles':{},
    'source_files_unchanged':verify_sources(),'raw_export_triangles':{}}
for p in ('models','mobile'):
    summary['model_profiles'][p]=savings(before,sum(m['profiles'][p]['output_bytes'] for m in models))
    summary['raw_export_triangles'][p]=sum(m['profiles'][p]['triangles'] for m in models)
for p in ('ui512','small256','large1024'):
    summary['icon_profiles'][p]=savings(icon_before,sum(i['variants'][p]['bytes'] for i in icons))
    summary['icon_profiles'][p]['size']=icons[0]['variants'][p]['size']
summary['combined_mobile_ui512']=savings(before+icon_before,
    summary['model_profiles']['mobile']['output_bytes']+summary['icon_profiles']['ui512']['output_bytes'])
write('summary.json',summary)

manifest={'status':'awaiting_owner_review','integration_authorized':False,
          'choose_one_model_profile_and_one_icon_size':True,'models':[],'icons':[]}
for row in models:
    manifest['models'].append({'id':row['id'],'role':row['role'],'state':row['state'],
        'source_sha256':row['source_sha256'],'profiles':{p:{k:r[k] for k in ('file','sha256','output_bytes','triangles','bones','meshes','materials','textures')}
                                                        for p,r in row['profiles'].items()}})
for row in icons:
    manifest['icons'].append({'id':row['id'],'role':row['role'],'source_sha256':row['source_sha256'],
        'variants':{p:{k:r[k] for k in ('file','sha256','bytes','size')} for p,r in row['variants'].items()}})
write('runtime_manifest.json',manifest)

write('visual_validation.json',{'reviewed_by':'Codex visual inspection','passed_at_rendered_resolution':True,
    'views':['three-quarter, all seven looks, Idle and Aggressive','head close-up: Base, Knight, Punk, Assassin',
             'all six icons, original/512/256','icons at 96 and 64 px, light and dark backgrounds'],
    'preserved_appearance':['four long legs','pointed hump','long tapering mouth','small white eyes','no animal ears or tail'],
    'mobile_tradeoff':'Minor ornament and paw detail surfaces simplified; inspect comparisons before integration.',
    'Roblox_tested':False})

files=[]
for p in ('models','mobile'):
    for row in models:
        item=row['profiles'][p];path=ROOT/item['file']
        assert sha(path)==item['sha256'];files.append(path)
for row in icons:
    for item in row['variants'].values():
        path=ROOT/item['file'];assert sha(path)==item['sha256'];files.append(path)
files+=sorted(ROOT.glob('*.json'))+sorted(ROOT.glob('*.py'))+[ROOT/'README.md']
files+=sorted((ROOT/'previews').glob('*.png'))
files+=sorted((ROOT/'intermediate').glob('*_stats.json'))
archive=ROOT/'Longmaw_Optimized_Models_Icons.zip'
with ZipFile(archive,'w',ZIP_DEFLATED,compresslevel=9) as z:
    for path in files:z.write(path,ROOT.name/path.relative_to(ROOT))
with ZipFile(archive) as z:
    assert z.testzip() is None
    assert len(z.infolist())==len(files)
    for p in files:
        assert z.read(str(ROOT.name/p.relative_to(ROOT)))==p.read_bytes()
print('OPTIMIZATION_PACKAGE_COMPLETE',len(files),'files',archive.stat().st_size,'bytes',flush=True)
print(json.dumps(summary,ensure_ascii=False,indent=2),flush=True)
