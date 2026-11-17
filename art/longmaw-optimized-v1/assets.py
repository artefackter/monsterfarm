"""Standalone Longmaw asset inventory. Never writes into source packages."""
import hashlib
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parent
ART=ROOT.parent
ROLES={'Base':'Базовый','Farmer':'Фермер','Miner':'Шахтёр','Princess':'Принцесса',
       'Knight':'Рыцарь','Punk':'Нефор','Assassin':'Убийца'}

def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def models():
    rows=[]
    for role,ru in ROLES.items():
        folder=ART/('longmaw-v5' if role=='Base' else 'longmaw-forms-v1')
        for state in ('Idle','Aggressive'):
            name='Longmaw_'+('' if role=='Base' else role+'_')+state
            rows.append({'id':name,'role':role,'ru':ru,'state':state,
                         'source':str(folder/'models'/(name+'.glb'))})
    return rows

def icons():
    folder=ART/'longmaw-icons-v1'
    return [{**a,'source':str(folder/a['file'])}
            for a in json.loads((folder/'assets.json').read_text())['assets']]

def inventory():
    return {str(p.relative_to(ART)): {'bytes':p.stat().st_size,'sha256':sha(p)}
            for name in ('longmaw-v5','longmaw-forms-v1','longmaw-icons-v1')
            for p in sorted((ART/name).rglob('*')) if p.is_file() and '__pycache__' not in p.parts}

def verify_sources():
    saved=json.loads((ROOT/'source_inventory.json').read_text())
    for relative,record in saved.items():
        path=ART/relative
        assert path.stat().st_size==record['bytes'] and sha(path)==record['sha256'],relative
    return len(saved)

if __name__=='__main__':
    target=ROOT/'source_inventory.json'
    if target.exists():
        print('SOURCES_UNCHANGED',verify_sources())
    else:
        target.write_text(json.dumps(inventory(),ensure_ascii=False,indent=2)+'\n')
        print('SOURCE_INVENTORY_SAVED',len(json.loads(target.read_text())))
