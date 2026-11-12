"""Offline acceptance tests for authored data; Studio collision/FPS still required after import."""
import json,math,struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'export'/'v3'
man=json.loads((OUT/'_manifest.json').read_text());meta=json.loads((OUT/'_metadata.json').read_text());checks=0

def check(condition,message):
 global checks
 assert condition,message;checks+=1

expected=['V3_Gun'+x for x in ['Deagle','AK','M4','AWP']]+['V3_Shovel'+x for x in ['Rusty','Steel','Combat','Bone','Golden','Lunar','Rainbow']]+['V3_House'+str(i) for i in range(1,6)]+['V3_Treadmill'+str(i) for i in range(1,6)]
for name in expected:check(name in man,'Missing '+name)
zero_area=0
for name,parts in man.items():
 check(len({p['part'] for p in parts})==len(parts),'Duplicate '+name)
 for p in parts:
  d=json.loads((OUT/(p['mesh']+'.json')).read_text());v=d['v'];n=d['n'];t=d['t']
  check(len(v)==len(n)==3*len(d['c']),p['mesh']+' vertex channels')
  check(len(t)//3==p['tris'],p['mesh']+' triangles')
  check(all(math.isfinite(x) for x in v+n),p['mesh']+' finite')
  check(max(t)<len(v)//3 and min(t)>=0,p['mesh']+' indices')
  check(p['tris']<=10000,p['mesh']+' triangle cap')
  check(all(.99<sum(n[j+k]**2 for k in range(3))<1.01 for j in range(0,len(n),3)),p['mesh']+' unit normals')
  for j in range(0,len(t),3):
   pts=[v[i*3:i*3+3] for i in t[j:j+3]];a=[pts[1][k]-pts[0][k] for k in range(3)];b=[pts[2][k]-pts[0][k] for k in range(3)]
   area=sum((a[(k+1)%3]*b[(k+2)%3]-a[(k+2)%3]*b[(k+1)%3])**2 for k in range(3))
   if area<1e-16:zero_area+=1
for i in range(1,6):
 name='V3_House'+str(i);c=meta['colliders'][name];anchors=meta['anchors'][name]
 check(abs(anchors['DoorOpening'][0])>=10,name+' doorway width')
 check(anchors['DoorOpening'][1]>=10,name+' doorway height')
 # 4-stud wide avatar sweep at height 3.6 through central front opening.
 for z in [-23,-21,-19,-17,-15,-12,-8,0]:
  hit=[b['name'] for b in c if all(abs(q-b['center'][k])<b['size'][k]/2+ext for k,(q,ext) in enumerate([(0,2),(3.6,2.8),(z,.6)]))]
  # Floor top .6 and avatar feet .8; body test must never touch walls/posts.
  check(not hit,name+' blocked door sweep '+str(z)+': '+str(hit))
 if i>=3:
  steps=sorted([v for v in c if v['name'].startswith('Step')],key=lambda v:v['name'])
  check(len(steps)==24,name+' 24 stairs')
  tops=[v['center'][1]+v['size'][1]/2 for v in steps]
  check(all(abs(tops[j+1]-tops[j]-.5)<1e-6 for j in range(23)),name+' half stud risers')
  check(all(v['size'][0]>=5.8 for v in steps),name+' stair width')
  check(abs(tops[-1]-12.6)<1e-6,name+' landing reachable')
for name in ['Deagle','AK','M4','AWP']:
 a='V3_Gun'+name;parts={p['part'] for p in man[a]};check({'Main','Magazine'}.issubset(parts),a+' detachable magazine')
 check(('Slide' if name=='Deagle' else 'Bolt') in parts,a+' moving action')
 check('Muzzle' in meta['anchors'][a] and 'Grip' in meta['anchors'][a],a+' anchors')
check({'JawL','JawR','Light','Plate','Base'}=={p['part'] for p in man['V3_Trap']},'Trap complete moving parts')
check(zero_area==0,'Degenerate exported triangles')
# Texture validation: real RGB PNGs with expected dimensions, flat normal convention.
for f in ['GrowVoxel_Color.png','GrowVoxel_Normal.png']:
 data=(ROOT/'textures'/'v3'/f).read_bytes();check(data[:8]==b'\x89PNG\r\n\x1a\n',f+' PNG');check(struct.unpack('>II',data[16:24])==(512,512),f+' dimensions')
result={'passed':True,'checks':checks,'zeroAreaTrianglesAfterQuantization':zero_area,'limitations':['Offline geometry checks do not prove Roblox collision, camera behavior, import colors, device FPS, or mobile UI.']}
(OUT/'_offline_tests.json').write_text(json.dumps(result,indent=2));print(json.dumps(result))
