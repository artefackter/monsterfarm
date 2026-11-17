"""Measure the selected import set and create a self-contained offline ZIP."""
import json
import sys
import zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parent;sys.path.insert(0,str(ROOT))
from assets import verify_sources,sha
models=json.loads((ROOT/'models_report.json').read_text())['models']
icons=json.loads((ROOT/'icons_report.json').read_text())['icons']
assert json.loads((ROOT/'packing_validation.json').read_text())['passed']
assert json.loads((ROOT/'blender_validation.json').read_text())['passed']
assert len(models)==35 and len(icons)==12
def reduction(a,b):return round((1-b/a)*100,2)
source_models=sum(m['stats']['input_bytes'] for m in models);packed_models=sum(m['stats']['output_bytes'] for m in models)
source_icons=sum(i['source_bytes'] for i in icons)
icon_profiles={key:{'bytes':sum(i['variants'][key]['bytes'] for i in icons),
    'reduction_percent':reduction(source_icons,sum(i['variants'][key]['bytes'] for i in icons)),
    'rgba8_uncompressed_bytes':sum(i['variants'][key]['rgba8_uncompressed_bytes'] for i in icons)} for key in ('large1024','ui512','small256')}
manifest={'status':'optimized_copies_for_review','game_integration_authorized':False,
    'models':{m['id']:{'file':m['output'],'character':m['character'],'role':m['role'],'sha256':m['output_sha256'],
        'bones':m['stats']['bones'],'meshes':m['stats']['output_meshes'],'triangles':m['stats']['triangles'],
        'animations':{'Idle':2.4,'Aggressive':1.2}} for m in models},
    'icons':{i['id']:{'file':i['variants']['ui512']['file'],'size':[512,512],'sha256':i['variants']['ui512']['sha256']} for i in icons}}
(ROOT/'runtime_manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
note='Granny / Grandfather / Slender family: offline compact asset set.\n35 rigged GLB models, each with Idle and Aggressive, and 12 transparent PNG icons at 512x512.\nOriginal artwork and authoring scenes are preserved outside this archive.\nModels retain all triangle geometry and bones; mesh objects are merged, colors/weights packed to normalized uint16.\nThese are assets for review and future skeletal import, not an automatic replacement of procedural game rigs.\nNo Studio import, upload, game registration or runtime performance measurement has been performed.\nSee runtime_manifest.json for file paths and SHA-256.\n'
(ROOT/'README_RUNTIME.txt').write_text(note)
files=[m['output'] for m in models]+[i['variants']['ui512']['file'] for i in icons]+['runtime_manifest.json','README_RUNTIME.txt']
archive=ROOT/'GrannySlender_Models_Icons512.zip'
with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
    for rel in files:z.write(ROOT/rel,arcname=rel)
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None and set(z.namelist())==set(files)
    for rel in files:assert z.read(rel)==(ROOT/rel).read_bytes()
summary={'model_count':35,'icon_count':12,'models':{'source_bytes':source_models,'optimized_bytes':packed_models,
    'reduction_percent':reduction(source_models,packed_models),'source_meshes':sum(m['stats']['input_meshes'] for m in models),
    'optimized_meshes':sum(m['stats']['output_meshes'] for m in models),'triangles_preserved':sum(m['stats']['triangles'] for m in models),
    'source_vertices':sum(g['source_vertices'] for m in models for g in m['stats']['groups'].values()),
    'optimized_vertices':sum(g['vertices'] for m in models for g in m['stats']['groups'].values()),
    'bones_preserved':sum(m['stats']['bones'] for m in models),
    'input_animation_keys':sum(a['input_keys'] for m in models for a in m['stats']['animations'].values()),
    'output_animation_keys':sum(a['output_keys'] for m in models for a in m['stats']['animations'].values()),
    'moving_keys_preserved':True},'icons':{'source_bytes':source_icons,'profiles':icon_profiles},
    'selected_set':{'profile':'models + icons/ui512','source_bytes':source_models+source_icons,
        'optimized_bytes':packed_models+icon_profiles['ui512']['bytes'],
        'reduction_percent':reduction(source_models+source_icons,packed_models+icon_profiles['ui512']['bytes'])},
    'archive':{'file':archive.name,'bytes':archive.stat().st_size,'sha256':sha(archive),'verified':True},
    'source_files_unchanged':verify_sources(),'game_integrated':False,'runtime_load_time_measured':False,
    'measurement_scope':'Alternative main GLB + one icon-resolution set only. Authoring scenes, FBX, historical versions, duplicate static poses and review renders are not included. Working directory grows because original assets and review copies are retained.'}
(ROOT/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(summary,ensure_ascii=False,indent=2))
