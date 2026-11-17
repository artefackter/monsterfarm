"""Validate unchanged generated PNGs and assemble approval sheets only."""
import hashlib
import json
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont

ROOT=Path(__file__).resolve().parent
PROJECT=ROOT.parents[1]
assets=json.loads((ROOT/'assets.json').read_text())['assets']
OUT=ROOT/'previews'
OUT.mkdir(exist_ok=True)
FONTS=Path('/System/Library/Fonts/Supplemental')
def font(size,bold=False):
    return ImageFont.truetype(str(FONTS/('Arial Bold.ttf' if bold else 'Arial.ttf')),size)
def fit(path,size):
    image=Image.open(path).convert('RGBA')
    image.thumbnail(size,Image.Resampling.LANCZOS)
    return image

validation=[]
for asset in assets:
    path=ROOT/asset['file']
    image=Image.open(path)
    assert image.format=='PNG' and image.mode=='RGBA' and image.width==image.height
    alpha=image.getchannel('A')
    hist=alpha.histogram()
    pixels=image.width*image.height
    assert alpha.getextrema()==(0,255)
    visible_fraction=sum(hist[128:])/pixels
    transparent_fraction=sum(hist[:6])/pixels
    assert .10<visible_fraction<.75 and transparent_fraction>.25
    visible=alpha.point(lambda value:255 if value>=128 else 0).getbbox()
    assert visible and visible[0]>0 and visible[1]>0 and visible[2]<image.width and visible[3]<image.height
    edges=[]
    for x in range(image.width):
        edges.extend((alpha.getpixel((x,0)),alpha.getpixel((x,image.height-1))))
    for y in range(image.height):
        edges.extend((alpha.getpixel((0,y)),alpha.getpixel((image.width-1,y))))
    assert max(edges)<8,'Visible subject reaches canvas boundary'
    payload=path.read_bytes()
    assert payload==Path(asset['generated_source']).read_bytes(),'Candidate PNG was modified after generation'
    validation.append({'id':asset['id'],'file':asset['file'],'size':list(image.size),
        'format':'PNG','mode':'RGBA','alpha_extrema':[0,255],
        'visible_bbox_alpha128':visible,'visible_fraction':round(visible_fraction,4),
        'transparent_fraction_alpha5':round(transparent_fraction,4),
        'max_boundary_alpha':max(edges),'generated_pixels_and_alpha_unchanged':True,
        'sha256':hashlib.sha256(payload).hexdigest(),'bytes':len(payload)})

sheet=Image.new('RGBA',(2100,1780),'#EDE5F3')
d=ImageDraw.Draw(sheet)
d.text((48,25),'НЕЗНАКОМЕЦ / ШЕСТЬ ИКОНОК',font=font(40,True),fill='#38213F')
d.text((48,81),'В стиле текущих иконок · на согласовании · в игру не добавлены',font=font(25),fill='#6D526F')
for i,asset in enumerate(assets):
    x=(i%3)*700;y=135+(i//3)*770
    image=fit(ROOT/asset['file'],(660,660))
    sheet.alpha_composite(image,(x+(700-image.width)//2,y))
    d.text((x+44,y+675),asset['ru'],font=font(30,True),fill='#472C50')
d.text((48,1733),'Отдельные PNG с исходной прозрачностью · встроенный image_gen',font=font(23),fill='#6D526F')
sheet.convert('RGB').save(OUT/'HoodedStranger_Icons_Review.png')

small=Image.new('RGBA',(1320,460),'#F6EDD8')
d=ImageDraw.Draw(small)
d.text((30,18),'ЧИТАЕМОСТЬ В ИНТЕРФЕЙСЕ / 96 px И 64 px',font=font(26,True),fill='#472C50')
for i,asset in enumerate(assets):
    x=i*220
    for size,y in ((96,83),(64,235)):
        image=fit(ROOT/asset['file'],(size,size))
        small.alpha_composite(image,(x+(220-image.width)//2,y))
    d.text((x+20,365),asset['ru'],font=font(21,True),fill='#472C50')
small.convert('RGB').save(OUT/'HoodedStranger_Icons_SmallSizes.png')

comparison=Image.new('RGBA',(1800,700),'#EDE5F3')
d=ImageDraw.Draw(comparison)
d.text((35,20),'СРАВНЕНИЕ С ТЕКУЩИМ СТИЛЕМ ИГРЫ',font=font(33,True),fill='#38213F')
columns=[(PROJECT/'art/ui/modal-refresh/DeerFarmer.png','Текущая: Фермер'),
         (ROOT/'icons/HoodedStrangerFarmer.png','Новая: Незнакомец / Фермер'),
         (PROJECT/'art/ui/monster-outfits/DeerKing.png','Текущая: Король'),
         (ROOT/'icons/HoodedStrangerKing.png','Новая: Незнакомец / Король')]
for i,(path,label) in enumerate(columns):
    image=fit(path,(420,495))
    comparison.alpha_composite(image,(i*450+(450-image.width)//2,100))
    d.text((i*450+18,634),label,font=font(21,True),fill='#472C50')
comparison.convert('RGB').save(OUT/'HoodedStranger_Icons_StyleComparison.png')

# The rendering/model references are only read, never modified by this package.
references=json.loads((ROOT/'references.json').read_text())
for rel,info in references['model_renders'].items():
    assert hashlib.sha256((PROJECT/rel).read_bytes()).hexdigest()==info['sha256']
(ROOT/'validation.json').write_text(json.dumps({'passed':True,'complete':len(validation)==6,
    'status':'awaiting_icon_approval','mode':'built-in image_gen',
    'candidate_png_modified':False,'game_integration_performed':False,
    'source_model_renders_unchanged':True,'assets':validation},ensure_ascii=False,indent=2)+'\n')
print('SIX_PNG_CANDIDATES_VALIDATED')
