"""Pack full geometry; pack mobile intermediates when available."""
import json
from assets import ROOT,models,verify_sources,sha
from compact_glb import pack,verify_pack

verify_sources();rows=[]
for asset in models():
    row={**asset,'source_sha256':sha(asset['source']),'profiles':{}}
    for profile in ('models','mobile'):
        source=asset['source'] if profile=='models' else ROOT/'intermediate'/(asset['id']+'.glb')
        if profile=='mobile' and not source.exists():continue
        output=ROOT/profile/(asset['id']+'.glb')
        stats=pack(source,output)
        row['profiles'][profile]={'file':str(output.relative_to(ROOT)),**stats,
             'sha256':sha(output),'packing_validation':verify_pack(source,output)}
    rows.append(row)
    print('PACKED',asset['id'],{p:v['output_bytes'] for p,v in row['profiles'].items()},flush=True)
(ROOT/'models_report.json').write_text(json.dumps({'models':rows,'source_files_unchanged':verify_sources(),
    'status':'optimized_copies_for_review','integrated':False},ensure_ascii=False,indent=2)+'\n')
