"""Pack copies with Blender's NumPy. No geometry simplification or rig changes."""
import sys,json
from pathlib import Path
ROOT=Path(__file__).resolve().parent;sys.path.insert(0,str(ROOT))
from assets import model_assets,snapshot_sources,verify_sources,sha
from compact_glb import pack
inventory=ROOT/'source_inventory.json'
if inventory.exists():verify_sources()
else:inventory.write_text(json.dumps(snapshot_sources(),indent=2)+'\n')
rows=[]
for a in model_assets():
    out=ROOT/'models'/(a['id']+'.glb')
    stats=pack(a['source'],out)
    rows.append(dict(a,output=str(out.relative_to(ROOT)),source_sha256=sha(a['source']),output_sha256=sha(out),stats=stats))
    print('PACKED',a['id'],stats['input_bytes'],'->',stats['output_bytes'],flush=True)
(ROOT/'models_report.json').write_text(json.dumps({'models':rows,'game_integrated':False,'runtime_load_time_measured':False},indent=2)+'\n')
print('SOURCES_UNCHANGED',verify_sources(),flush=True)
