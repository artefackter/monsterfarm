"""Validate the actual exported GLBs and create review sheets and a delivery archive."""
import json, math, struct, zipfile, hashlib
from pathlib import Path
from collections import Counter
from PIL import Image, ImageDraw, ImageFont

R=Path(__file__).resolve().parent
catalog=json.loads((R/'models/catalog.json').read_text())
def font(size,bold=False):
    paths=[
        '/System/Library/Fonts/Supplemental/Arial Bold.ttf' if bold else '/System/Library/Fonts/Supplemental/Arial.ttf',
        '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf' if bold else '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
        'C:/Windows/Fonts/arialbd.ttf' if bold else 'C:/Windows/Fonts/arial.ttf',
    ]
    for path in paths:
        if Path(path).is_file():return ImageFont.truetype(path,size)
    return ImageFont.load_default(size=size)

def board(filename,title,subtitle,names,cols=3):
    rows=math.ceil(len(names)/cols);cw=600;ch=590;header=135
    im=Image.new('RGB',(cols*cw,header+rows*ch+25),'#F6F0E8');d=ImageDraw.Draw(im)
    d.text((35,25),title,font=font(38,True),fill='#402E49')
    d.text((35,82),subtitle,font=font(23),fill='#7B6C80')
    labels={a['name']:a['label'] for a in catalog['assets']}
    for i,name in enumerate(names):
        source=Image.open(R/'previews'/(name+'.png')).convert('RGB');source.thumbnail((cw-24,ch-70))
        x=(i%cols)*cw+(cw-source.width)//2;y=header+(i//cols)*ch
        im.paste(source,(x,y));d.text(((i%cols)*cw+cw//2,y+ch-29),labels[name],anchor='mm',font=font(26,True),fill='#402E49')
    im.save(R/'previews'/filename,quality=94)

board('pavilions.jpg','ПАВИЛЬОНЫ ЦЕНТРАЛЬНОЙ ПЛОЩАДИ','Отдельные 3D-модели • Версия для согласования',[
    'Pavilion_Weapons','Pavilion_Brawler','Pavilion_Pets','Pavilion_Quests','Pavilion_Rewards','Pavilion_Help'])
board('hero_objects.jpg','ФОНТАН И ЗОНА РЕКОРДОВ','Каменная лапа с кристаллом, пергола и золотой чемпион',[
    'Slime_Fountain','Records_Pergola','Champion_ImpStatue'])
board('decor.jpg','ДЕКОР И ОЗЕЛЕНЕНИЕ','Модульный набор для сборки площади',[
    'Bench','Lantern','Lantern_Banner','Flowerbed_Curved','Planter_Box','Tree_Oak','Shrub_Cluster','Mushroom_Cluster','StringLights_12'])
for name in ('Plaza_day','Plaza_front'):
    im=Image.open(R/'previews'/(name+'.png')).convert('RGB');im.save(R/'previews'/(name+'.jpg'),quality=94)

def check_glb(path):
    raw=path.read_bytes();magic,version,length=struct.unpack_from('<4sII',raw)
    assert magic==b'glTF' and version==2 and length==len(raw),(path,'header')
    jsize,jtype=struct.unpack_from('<I4s',raw,12);assert jtype==b'JSON'
    doc=json.loads(raw[20:20+jsize]);offset=20+jsize;bsize,btype=struct.unpack_from('<I4s',raw,offset)
    assert btype==b'BIN\0';binary=raw[offset+8:offset+8+bsize]
    assert not doc.get('cameras') and not doc.get('extensions',{}).get('KHR_lights_punctual')
    assert all('uri' not in b for b in doc.get('buffers',[]))
    assert all('uri' not in i for i in doc.get('images',[])),(path,'external image')
    def values(idx):
        a=doc['accessors'][idx];view=doc['bufferViews'][a['bufferView']]
        fmt={5126:'f',5125:'I',5123:'H',5121:'B'}[a['componentType']]
        count={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']]
        item=struct.calcsize('<'+fmt*count);stride=view.get('byteStride',item);start=view.get('byteOffset',0)+a.get('byteOffset',0)
        assert start+(a['count']-1)*stride+item<=len(binary)
        return [struct.unpack_from('<'+fmt*count,binary,start+i*stride) for i in range(a['count'])]
    tris=[]
    for me in doc['meshes']:
        tri=0
        for p in me['primitives']:
            assert p.get('mode',4)==4
            pos=values(p['attributes']['POSITION']);idx=[v[0] for v in values(p['indices'])]
            assert len(idx)%3==0 and min(idx)>=0 and max(idx)<len(pos)
            assert all(math.isfinite(v) for point in pos for v in point)
            if 'NORMAL' in p['attributes']:
                normals=values(p['attributes']['NORMAL']);assert len(normals)==len(pos)
                assert all(math.isfinite(v) for point in normals for v in point)
            tri+=len(idx)//3
        tris.append(tri)
    return doc,tris,hashlib.sha256(raw).hexdigest()

report=[]
for row in catalog['assets']:
    path=R/'models'/(row['name']+'.glb');doc,tris,sha=check_glb(path)
    assert sum(tris)==row['triangles'],(path,'triangle mismatch',sum(tris),row['triangles'])
    assert len(doc['meshes'])==row['meshes'],(path,'mesh count')
    node_names={n.get('name') for n in doc['nodes']}
    for a in row['anchors']:assert row['name']+'__ANCHOR_'+a in node_names,(path,a)
    report.append(dict(file=path.name,valid=True,meshes=len(tris),triangles=sum(tris),sha256=sha))
doc,tris,sha=check_glb(R/'models/Plaza_Assembly.glb')
scene=doc['scenes'][doc.get('scene',0)];nodes=doc['nodes']
expected=Counter(r['asset'] for r in catalog['layout']);actual=Counter()
for i in scene['nodes']:
    name=nodes[i]['name'];assert '_instance' in name,('unexpected scene object',name)
    actual[name.split('_instance')[0]]+=1
assert actual==expected,('assembly instance counts',actual,expected)
byname={r['name']:r for r in catalog['assets']}
def instance_triangles(i):
    n=nodes[i];return (tris[n['mesh']] if 'mesh' in n else 0)+sum(instance_triangles(j) for j in n.get('children',[]))
total=sum(instance_triangles(i) for i in scene['nodes'])
assert total==sum(byname[name]['triangles']*num for name,num in expected.items())
report.append(dict(file='Plaza_Assembly.glb',valid=True,instances=sum(actual.values()),instanced_triangles=total,unique_meshes=len(tris),sha256=sha))
(R/'validation.json').write_text(json.dumps(dict(valid=True,assets=len(catalog['assets']),files=report),indent=2)+'\n')
with zipfile.ZipFile(R/'Plaza_Reference_V1_Review.zip','w',zipfile.ZIP_DEFLATED) as z:
    for p in sorted(R.rglob('*')):
        if p.is_file() and p.suffix in ('.glb','.blend','.png','.jpg','.json','.py','.md','.txt'):
            z.write(p,p.relative_to(R))
print(json.dumps(dict(valid=True,assets=len(catalog['assets']),instances=sum(actual.values()),instanced_triangles=total,archive=str(R/'Plaza_Reference_V1_Review.zip')),indent=2))
