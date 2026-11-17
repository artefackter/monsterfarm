"""Package only the final requested assets; omit the abandoned new Crux."""
import json
import hashlib
import zipfile
from pathlib import Path

ROOT=Path(__file__).resolve().parent
DREDGE=ROOT.parent/'srp-dredge-v1'
DELIVERY=('AssimilatedAdventurer','PrimitiveSummoner','ParasiteAdapted','AdaptedViscera')
approval=json.loads((DREDGE/'approval.json').read_text())
assert approval['status']=='approved'
for relative,spec in approval['files'].items():
    assert hashlib.sha256((DREDGE/relative).read_bytes()).hexdigest()==spec['sha256']
validation=json.loads((ROOT/'validation.json').read_text())
assert validation['status']=='passed'
for name in DELIVERY:
    for ext in ('glb','fbx'):
        p=ROOT/'models'/(name+'.'+ext)
        assert hashlib.sha256(p.read_bytes()).hexdigest()==validation['exports'][name][ext]['sha256']
report=json.loads((ROOT/'report.json').read_text())
for name,spec in report['models'].items():
    spec['review_baseline_only']=name=='ParasiteExisting'
    spec['source_asset']='Parasite_Root_Aggressive' if name.startswith('Parasite') else None
report['delivery_models']=list(DELIVERY)
report['approved_dredge_package']='../srp-dredge-v1'
report['new_crux_included']=False
(ROOT/'report.json').write_text(json.dumps(report,indent=2)+'\n')
(ROOT/'review-history.json').write_text(json.dumps({
    'date':'2026-11-14','timezone':'Europe/Moscow',
    'dredge':'Approved in chat: Да, подходит. Binaries and previews unchanged.',
    'owner_steering':['Crux','Crux\'а делать не нужно','Он уже есть',
                      'Надо адаптировать существующего, его зовут Паразит'],
    'final_scope':'Three new models and a separate adaptation of existing Parasite_Root_Aggressive.',
    'pending_visual_approval':list(DELIVERY),
    'new_crux':'Superseded locally, excluded from delivery.',
    'game_integrated':False,'uploaded':False,'studio_modified':False,
},ensure_ascii=False,indent=2)+'\n')

package=ROOT/'SRP_Review_Set.zip'
items=[]
for p in sorted(ROOT.rglob('*')):
    if not p.is_file():continue
    rel=p.relative_to(ROOT)
    if any(part in ('superseded-new-crux','__pycache__') for part in rel.parts):continue
    if p.suffix in ('.zip','.log','.pyc') or p.name=='package_manifest.json':continue
    if rel.parts[0]=='models' and p.stem=='ParasiteExisting':
        # Its source data and preview are sufficient; the baseline is not a new model.
        continue
    if rel.parts[0]=='previews' and p.name.startswith('ParasiteExisting_') and p.name!='ParasiteExisting_ThreeQuarter.png':continue
    items.append((p,'Pending_approval/'+str(rel)))
for p in sorted(DREDGE.rglob('*')):
    if not p.is_file():continue
    rel=p.relative_to(DREDGE)
    if '__pycache__' in rel.parts or p.suffix in ('.zip','.log','.pyc'):continue
    items.append((p,'Dredge_approved/'+str(rel)))
assert not any('/Crux.' in arc or '/Crux_' in arc for p,arc in items)
manifest={arc:{'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
          for p,arc in items}
(ROOT/'package_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
overview='''SRP REVIEW SET — 14 November 2026

Dredge_approved: the accepted Dredge, unchanged.
Pending_approval: three new models plus a copy-based adaptation of the existing Parasite.
No new Crux is included. Nothing was added to the game or Roblox Studio.

Open Pending_approval/previews/SRP_Four_Reference_Review.png first.
For Parasite, open Pending_approval/previews/Parasite_Before_After.png.
Each model has GLB, FBX and Blender files. Custom rigs; no animation clips.
Full scope, limitations and validation are described in Pending_approval/README.md.
'''
with zipfile.ZipFile(package,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    z.writestr('SRP_Review_Set/START_HERE.txt',overview)
    z.writestr('SRP_Review_Set/package_manifest.json',json.dumps(manifest,indent=2)+'\n')
    for p,arc in items:z.write(p,'SRP_Review_Set/'+arc)
with zipfile.ZipFile(package) as z:
    assert z.testzip() is None
    for arc,spec in manifest.items():
        assert hashlib.sha256(z.read('SRP_Review_Set/'+arc)).hexdigest()==spec['sha256']
    models=[n for n in z.namelist() if '/models/' in n and n.endswith(('.glb','.fbx','.blend'))]
    assert len(models)==15,models
print(package)
print('PACKAGE_OK',package.stat().st_size,'bytes;',len(items),'files;',len(models),'model files')
