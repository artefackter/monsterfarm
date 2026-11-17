"""The current 24 SRP costumes and corresponding 24 illustrated icons."""
from pathlib import Path
import hashlib, json
ROOT=Path(__file__).resolve().parent
ART=ROOT.parent
PROJECT=ART.parent
CHARACTERS=['Dredge','AssimilatedAdventurer','PrimitiveSummoner','AdaptedViscera']
ROLES=['Farmer','Miner','King','Knight','Nefor','Killer']
def sha(path): return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def model_assets():
    return [dict(id=c+r,character=c,role=r,source=str(ART/'srp-character-variants-v1'/'models'/(c+r+'.glb'))) for c in CHARACTERS for r in ROLES]
def icon_assets():
    return [dict(id=c+r,character=c,role=r,source=str(ART/'srp-icons-v1'/'icons'/(c+r+'.png'))) for c in CHARACTERS for r in ROLES]
def snapshot_sources():
    paths=set()
    for folder in ['srp-character-variants-v1','srp-icons-v1']:
        paths.update(p for p in (ART/folder).rglob('*') if p.is_file() and '__pycache__' not in p.parts)
    paths.update(PROJECT/p for p in json.loads((ART/'srp-icons-v1/protected-files.json').read_text()))
    return {'files':{str(p.relative_to(PROJECT)):{'bytes':p.stat().st_size,'sha256':sha(p)} for p in sorted(paths)}}
def verify_sources():
    saved=json.loads((ROOT/'source_inventory.json').read_text())
    for rel,meta in saved['files'].items():
        p=PROJECT/rel
        assert p.is_file() and p.stat().st_size==meta['bytes'] and sha(p)==meta['sha256'],rel
    return len(saved['files'])
