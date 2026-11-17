"""Pack mobile geometry into the same two-mesh core-glTF delivery layout."""
import json
from pathlib import Path
from build import sha,verify_originals
from compact_glb import pack

ROOT=Path(__file__).resolve().parent
report=json.loads((ROOT/'report.json').read_text())
for asset in report['models']:
    source=ROOT/'intermediate'/(asset['id']+'.glb')
    if not source.exists():continue
    output=ROOT/'mobile'/(asset['id']+'.glb')
    packed=pack(source,output)
    geometry=json.loads((ROOT/'intermediate'/(asset['id']+'_stats.json')).read_text())
    packed.update(geometry_changed=True,source_original_bytes=asset['full']['input_bytes'],
                  source_original_triangles=asset['full']['triangles'],
                  mesh_geometry_changes=geometry,intermediate_sha256=sha(source))
    asset.update(mobile=packed,mobile_file=str(output.relative_to(ROOT)),mobile_sha256=sha(output))
    assert packed['triangles']<12000,(asset['id'],packed['triangles'])
    print(asset['id'],packed['triangles'],packed['output_bytes'],flush=True)
(ROOT/'report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
verify_originals()
