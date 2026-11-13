"""Prepare the review boards and verify the standalone GLB payloads."""
import json, math, struct, zipfile
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

R=Path(__file__).resolve().parent
font='/System/Library/Fonts/Supplemental/Arial.ttf'
bold='/System/Library/Fonts/Supplemental/Arial Bold.ttf'
def f(size,heavy=False):return ImageFont.truetype(bold if heavy else font,size)
names=[('Wooden','Деревянная'),('Stone','Каменная'),('Marble','Мраморная'),('Golden','Золотая'),('Lunar','Лунная')]
sheet=Image.new('RGB',(2500,800),'#F4F0F5');d=ImageDraw.Draw(sheet)
d.text((48,28),'МОГИЛЫ / НОВЫЙ НАБОР',font=f(42,True),fill='#342A45')
d.text((48,86),'3D-модели по референсу • На согласование • В игру не установлены',font=f(25),fill='#746B80')
for i,(kind,title) in enumerate(names):
    im=Image.open(R/'previews'/('Grave_'+kind+'.png')).convert('RGB');im.thumbnail((480,560))
    sheet.paste(im,(i*500+(500-im.width)//2,145))
    d.text((i*500+250,724),title,anchor='mm',font=f(28,True),fill='#342A45')
sheet.save(R/'previews'/'lineup.jpg',quality=94)

sheet=Image.new('RGB',(1800,850),'#F4F0F5');d=ImageDraw.Draw(sheet)
d.text((40,24),'ЗОЛОТАЯ / ОБЗОР ФОРМЫ',font=f(36,True),fill='#342A45')
for i,(img,title) in enumerate([('Golden_front.png','Спереди'),('Grave_Golden.png','Три четверти'),('Golden_back.png','Сзади')]):
    im=Image.open(R/'previews'/img).convert('RGB');im.thumbnail((580,680))
    sheet.paste(im,(i*600+(600-im.width)//2,92))
    d.text((i*600+300,798),title,anchor='mm',font=f(25,True),fill='#342A45')
sheet.save(R/'previews'/'golden_views.jpg',quality=94)

# Read actual exported binary buffers; check index ranges, finite positions and triangle counts.
report=[]
for row in json.loads((R/'models'/'catalog.json').read_text()):
    path=R/'models'/(row['name']+'.glb');raw=path.read_bytes()
    magic,version,length=struct.unpack_from('<4sII',raw)
    assert magic==b'glTF' and version==2 and length==len(raw)
    size,typ=struct.unpack_from('<I4s',raw,12);assert typ==b'JSON'
    doc=json.loads(raw[20:20+size]);offset=20+size
    bsize,btyp=struct.unpack_from('<I4s',raw,offset);assert btyp==b'BIN\0'
    binary=raw[offset+8:offset+8+bsize]
    def values(idx):
        a=doc['accessors'][idx];v=doc['bufferViews'][a['bufferView']]
        fmt={5126:'f',5125:'I',5123:'H',5121:'B'}[a['componentType']]
        count={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']]
        item=struct.calcsize('<'+fmt*count);stride=v.get('byteStride',item)
        start=v.get('byteOffset',0)+a.get('byteOffset',0)
        return [struct.unpack_from('<'+fmt*count,binary,start+i*stride) for i in range(a['count'])]
    tri=0
    for mesh in doc['meshes']:
        for p in mesh['primitives']:
            assert p.get('mode',4)==4
            pos=values(p['attributes']['POSITION']);indices=[v[0] for v in values(p['indices'])]
            assert all(math.isfinite(v) for point in pos for v in point)
            assert min(indices)>=0 and max(indices)<len(pos) and len(indices)%3==0
            tri+=len(indices)//3
    assert tri==row['triangles'],(path,tri,row['triangles'])
    assert not doc.get('cameras')
    report.append(dict(file=path.name,triangles=tri,valid=True,bytes=len(raw)))
(R/'validation.json').write_text(json.dumps(report,indent=2))
with zipfile.ZipFile(R/'Graves_Reference_V2_Review.zip','w',zipfile.ZIP_DEFLATED) as z:
    for p in sorted(R.rglob('*')):
        if p.is_file() and p.suffix in ('.glb','.blend','.png','.jpg','.json','.py'):
            z.write(p,p.relative_to(R))
print(json.dumps(report,indent=2))
