"""Create an additive Luau manifest after manual import. Does not replace production files."""
import argparse,json
from pathlib import Path
P=argparse.ArgumentParser();P.add_argument('--ids',required=True);P.add_argument('--out',required=True);args=P.parse_args()
ROOT=Path(__file__).resolve().parents[1];man=json.loads((ROOT/'export/v3/_manifest.json').read_text());ids=json.loads(Path(args.ids).read_text())
wanted={p['mesh'] for parts in man.values() for p in parts};assert set(ids)==wanted,'Imported mesh set differs from pack'
assert all(isinstance(v,int) and not isinstance(v,bool) and v>0 for v in ids.values()),'Invalid asset ID'
def vec(v):return 'Vector3.new('+','.join(str(round(n,3)) for n in v)+')'
lines=['-- Generated from the manually imported WorldV3 pack.','return {']
for name,parts in sorted(man.items()):
 lines.append(name+'={')
 for p in parts:
  d=json.loads((ROOT/'export/v3'/(p['mesh']+'.json')).read_text());colors=d['c'];count=len(colors)
  avg=''.join(f'{sum((c>>shift)&255 for c in colors)//count:02X}' for shift in [16,8,0])
  lines.append('{part='+json.dumps(p['part'])+',id='+str(ids[p['mesh']])+',offset='+vec(p['offset'])+',size='+vec(p['size'])+',material='+json.dumps(p['material'])+',transparency='+str(p['transparency'])+',cast='+str(p['cast']).lower()+',avg='+json.dumps(avg)+'},')
 lines.append('},')
lines.append('}')
Path(args.out).write_text('\n'.join(lines)+'\n');print(args.out)
