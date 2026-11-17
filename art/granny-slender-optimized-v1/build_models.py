"""Run with Blender's bundled NumPy. Writes only this offline output package."""
import json
import sys
from pathlib import Path
ROOT=Path(__file__).resolve().parent;sys.path.insert(0,str(ROOT))
from assets import model_assets,snapshot_sources,verify_sources,sha
from compact_glb import pack

inventory_path=ROOT/'source_inventory.json'
if inventory_path.exists():verify_sources()
else:inventory_path.write_text(json.dumps(snapshot_sources(),ensure_ascii=False,indent=2)+'\n')
report={'status':'optimized_copies_for_review','game_integrated':False,'runtime_load_time_measured':False,'models':[]}
for asset in model_assets():
    target=ROOT/'models'/(asset['id']+'.glb');stats=pack(asset['source'],target,asset['character'])
    asset.update(output=str(target.relative_to(ROOT)),source_sha256=sha(asset['source']),output_sha256=sha(target),stats=stats)
    report['models'].append(asset)
    print('PACKED',asset['id'],stats['input_bytes'],'->',stats['output_bytes'],flush=True)
(ROOT/'models_report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
print('MODELS_PACKED',len(report['models']),'SOURCES_UNCHANGED',verify_sources(),flush=True)
