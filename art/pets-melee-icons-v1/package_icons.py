"""Copy generated artwork unchanged; resize and compose review sheets only."""
from pathlib import Path
import json, shutil, hashlib, zipfile
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parent
jobs=json.loads((ROOT/'prompts.json').read_text())['jobs']
sources={r['id']:Path(r['source']) for r in json.loads((ROOT/'generated_sources.json').read_text())}
font='/System/Library/Fonts/Supplemental/Arial.ttf'
bold='/System/Library/Fonts/Supplemental/Arial Bold.ttf'
rows=[]
for job in jobs:
    name=job['id']; dst=ROOT/'originals'/f'{name}.png'
    shutil.copy2(sources[name],dst)
    im=Image.open(dst)
    assert im.mode=='RGBA' and im.width==im.height
    alpha=im.getchannel('A'); assert alpha.getextrema()==(0,255)
    bbox=alpha.point(lambda p:255 if p>8 else 0).getbbox()
    assert bbox[0]>0 and bbox[1]>0 and bbox[2]<im.width and bbox[3]<im.height, (name,bbox)
    row={'id':name,'label':job['label'],'suggested_icon_key':f"modal_{job['category']}_{name}",'original':f'originals/{name}.png','original_bytes':dst.stat().st_size,'size':list(im.size),'alpha_bbox_gt8':bbox,'sha256':hashlib.sha256(dst.read_bytes()).hexdigest(),'variants':{}}
    for profile,size in [('ui512',512),('small256',256)]:
        out=ROOT/'icons'/profile/f'{name}.png'
        resized=im.resize((size,size),Image.Resampling.LANCZOS)
        resized.save(out,optimize=True,compress_level=9)
        check=Image.open(out)
        assert check.mode=='RGBA' and check.size==(size,size) and check.tobytes()==resized.tobytes()
        row['variants'][profile]={'file':str(out.relative_to(ROOT)),'bytes':out.stat().st_size,'size':[size,size]}
    rows.append(row)

sheet=Image.new('RGBA',(1440,1580),'#F7E8C7');d=ImageDraw.Draw(sheet)
d.text((45,30),'Питомцы и предметы • 2D-иконки',font=ImageFont.truetype(bold,40),fill='#511A3D')
d.text((45,86),'9 новых иконок • Предпросмотр для согласования',font=ImageFont.truetype(font,24),fill='#744A5B')
for i,job in enumerate(jobs):
    x=30+(i%3)*470;y=140+(i//3)*470
    d.rounded_rectangle((x,y,x+440,y+450),radius=22,fill='#FFF5DD',outline='#D5AB64',width=3)
    im=Image.open(ROOT/'icons/ui512'/f"{job['id']}.png").resize((370,370),Image.Resampling.LANCZOS)
    sheet.alpha_composite(im,(x+35,y+15))
    label=job['label'];f=ImageFont.truetype(bold,27)
    d.text((x+220,y+405),label,font=f,anchor='mm',fill='#511A3D')
sheet.convert('RGB').save(ROOT/'previews/All_9_Icons.png',optimize=True)

small=Image.new('RGBA',(1060,1120),'#F7E8C7');d=ImageDraw.Draw(small)
d.text((25,20),'Проверка в интерфейсе: 64 / 96 px',font=ImageFont.truetype(bold,30),fill='#511A3D')
for i,job in enumerate(jobs):
    y=75+i*112
    d.text((20,y+44),job['label'],font=ImageFont.truetype(font,21),fill='#511A3D')
    im=Image.open(ROOT/'icons/ui512'/f"{job['id']}.png")
    for j,bg in enumerate(('#FFF5DD','#252034')):
        x=320+j*355
        d.rounded_rectangle((x,y,x+330,y+104),radius=10,fill=bg)
        for s,off in ((64,35),(96,190)):
            small.alpha_composite(im.resize((s,s),Image.Resampling.LANCZOS),(x+off,y+(104-s)//2))
small.convert('RGB').save(ROOT/'previews/Small_Size_Check.png',optimize=True)
report={'passed':True,'count':len(rows),'integrated':False,'generator':'built-in image_gen','original_bytes':sum(r['original_bytes'] for r in rows),'ui512_bytes':sum(r['variants']['ui512']['bytes'] for r in rows),'small256_bytes':sum(r['variants']['small256']['bytes'] for r in rows),'assets':rows}
(ROOT/'manifest.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
with zipfile.ZipFile(ROOT/'Pets_Melee_9_Icons_Review.zip','w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
    for folder in ['originals','icons','previews']:
        for p in sorted((ROOT/folder).rglob('*.png')): z.write(p,p.relative_to(ROOT))
    for f in ['manifest.json','prompts.json','README.txt']: z.write(ROOT/f,f)
with zipfile.ZipFile(ROOT/'Pets_Melee_9_Icons_Review.zip') as z: assert z.testzip() is None
print(json.dumps({k:v for k,v in report.items() if k!='assets'},ensure_ascii=False,indent=2))
