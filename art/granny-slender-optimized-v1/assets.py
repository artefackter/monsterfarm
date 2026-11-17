"""Current art sources only. This package never modifies its source folders."""
import hashlib
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parent;ART=ROOT.parent;PROJECT=ART.parent
SOURCE_ROOTS=['granny-grandfather-v4','granny-grandfather-forms-v3',
              'granny-grandfather-icons-v3','slender-family-v1','slender-family-forms-v1']
def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def model_assets():
    assets=[]
    for folder,people in [('granny-grandfather-v4',['Granny','Grandfather']),
                          ('slender-family-v1',['Slenderman','Slendrina','SpiderMom'])]:
        for person in people:
            assets.append({'id':person,'character':person,'role':'Base','source':str(ART/folder/'models'/(person+'.glb'))})
    for folder in ['granny-grandfather-forms-v3','slender-family-forms-v1']:
        for name,m in json.loads((ART/folder/'catalog.json').read_text())['models'].items():
            assets.append({'id':name,'character':m['character'],'role':m['role'],'source':str(ART/folder/m['model'])})
    assert len(assets)==35 and len({a['id'] for a in assets})==35
    return assets
def icon_assets():
    root=ART/'granny-grandfather-icons-v3'
    return [dict(id=a['id'],character=a['character'],role=a['role'],source=str(root/a['file']))
            for a in json.loads((root/'assets.json').read_text())['assets']]
def snapshot_sources():
    files={str(p.relative_to(PROJECT)):{'bytes':p.stat().st_size,'sha256':sha(p)}
           for name in SOURCE_ROOTS for p in sorted((ART/name).rglob('*'))
           if p.is_file() and '__pycache__' not in p.parts}
    return {'roots':SOURCE_ROOTS,'files':files}
def verify_sources():
    saved=json.loads((ROOT/'source_inventory.json').read_text())
    for rel,meta in saved['files'].items():
        p=PROJECT/rel
        assert p.is_file() and p.stat().st_size==meta['bytes'] and sha(p)==meta['sha256'],rel
    return len(saved['files'])
