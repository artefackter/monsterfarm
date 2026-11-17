"""Validate delivery scope, PNG alpha, unchanged generation pixels and source files."""
from pathlib import Path
import hashlib, json
from PIL import Image
ROOT=Path(__file__).resolve().parent
REPO=ROOT.parent.parent
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
jobs=json.loads((ROOT/'prompts.json').read_text())
assets=json.loads((ROOT/'assets.json').read_text())
expected={x['id'] for x in jobs['items']}
assert len(expected)==24 and {x.stem for x in (ROOT/'icons').glob('*.png')}==expected
results=[]
for a in assets:
    p=ROOT/'icons'/(a['id']+'.png'); im=Image.open(p)
    assert im.mode=='RGBA' and im.size==(1254,1254), p
    alpha=im.getchannel('A'); assert alpha.getextrema()==(0,255), p
    bbox=alpha.point(lambda v:255 if v>16 else 0).getbbox()
    assert bbox and min(bbox[:2])>0 and max(bbox[2:])<1254, (p,bbox)
    corners=[alpha.getpixel(pt) for pt in [(0,0),(1253,0),(0,1253),(1253,1253)]]
    # Preserve generator alpha: 1/255 corner residue is visually transparent.
    assert max(corners)<=1,p
    assert sha(p)==sha(Path(a['source'])),p
    results.append({'id':a['id'],'file':str(p.relative_to(ROOT)),'size':im.size,'mode':im.mode,'alpha_extrema':alpha.getextrema(),'corner_alpha':corners,'visible_bounds':bbox,'sha256':sha(p),'original_generated_pixels_preserved':True})
protected=json.loads((ROOT/'protected-files.json').read_text())
changes=[s for s,h in protected.items() if not (REPO/s).exists() or sha(REPO/s)!=h]
report={'status':'passed' if not changes else 'source_changes_detected','icons':len(results),'protected_files_checked':len(protected),'protected_files_changed':changes,'game_integration':False,'user_approval':'pending','assets':results}
(ROOT/'validation.json').write_text(json.dumps(report,indent=2))
jobs['items']=[dict(j,status='generated_pending_user_approval') for j in jobs['items']]
(ROOT/'prompts.json').write_text(json.dumps(jobs,ensure_ascii=False,indent=2))
print(json.dumps({k:v for k,v in report.items() if k!='assets'},indent=2))
assert not changes,changes
