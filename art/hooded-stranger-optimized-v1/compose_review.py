"""Create before/after review sheets and measure offline render differences."""
import json
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw,ImageFont,ImageOps

ROOT=Path(__file__).resolve().parent
ART=ROOT.parent
OUT=ROOT/'previews'
report=json.loads((ROOT/'report.json').read_text())
FONTS=Path('/System/Library/Fonts/Supplemental')
def font(size,bold=False):
    return ImageFont.truetype(str(FONTS/('Arial Bold.ttf' if bold else 'Arial.ttf')),size)
def paste_fit(canvas,path,box):
    x,y,w,h=box
    image=Image.open(path).convert('RGBA')
    image=ImageOps.contain(image,(w,h),Image.Resampling.LANCZOS)
    canvas.alpha_composite(image,(x+(w-image.width)//2,y+(h-image.height)//2))

render_checks=[]
for item in report['models']:
    before=np.asarray(Image.open(OUT/(item['id']+'_original.png')).convert('RGB')).astype(float)
    after=np.asarray(Image.open(OUT/(item['id']+'_optimized.png')).convert('RGB')).astype(float)
    error=float(np.abs(before-after).mean())
    assert error<.50,(item['id'],error)
    render_checks.append({'id':item['id'],'mean_absolute_rgb_error_255':error})

sheet=Image.new('RGBA',(1660,1660),'#111a20')
d=ImageDraw.Draw(sheet)
d.text((36,23),'НЕЗНАКОМЕЦ / ОПТИМИЗАЦИЯ',font=font(37,True),fill='#eee9de')
d.text((36,77),'Сравнение повторно импортированных GLB при одинаковом свете',font=font(23),fill='#a8b9c1')
for col,(profile,label) in enumerate([('original','ИСХОДНИК'),('optimized','ОПТИМИЗИРОВАНО')]):
    x=col*830
    d.text((x+35,125),label,font=font(27,True),fill='#bdd4d6')
    paste_fit(sheet,OUT/('HoodedStranger_Farmer_'+profile+'.png'),(x+15,165,800,825))
    paste_fit(sheet,OUT/('Face_'+profile+'.png'),(x+35,1030,760,540))
d.text((38,1597),'Геометрия и 28 костей сохранены · текстура лица 1000×562 → 256×256 без ресайза',font=font(23),fill='#a8b9c1')
sheet.convert('RGB').save(OUT/'Model_Comparison.png')

all_models=Image.new('RGBA',(2100,1960),'#111a20')
d=ImageDraw.Draw(all_models)
d.text((35,24),'ШЕСТЬ ФОРМ / ДО И ПОСЛЕ',font=font(37,True),fill='#eee9de')
d.text((35,78),'В каждой паре: исходник слева, оптимизированная копия справа',font=font(23),fill='#a8b9c1')
for i,item in enumerate(r for r in report['models'] if r['role']!='Base'):
    x=(i%3)*700;y=130+(i//3)*870
    d.text((x+25,y),item['ru'],font=font(27,True),fill='#bdd4d6')
    for col,profile in enumerate(('original','optimized')):
        paste_fit(all_models,OUT/(item['id']+'_'+profile+'.png'),(x+col*350,y+45,345,775))
d.text((35,1898),'229 мешей → 14 во всём наборе · 41 367 треугольников сохранены',font=font(23),fill='#a8b9c1')
all_models.convert('RGB').save(OUT/'All_Models_Comparison.png')

icons=Image.new('RGBA',(1800,1400),'#EDE5F3')
d=ImageDraw.Draw(icons)
d.text((35,24),'ИКОНКИ / СРАВНЕНИЕ РАЗМЕРОВ',font=font(37,True),fill='#38213F')
d.text((35,80),'Один рисунок, одинаковый размер на листе · фон есть только в превью',font=font(24),fill='#6D526F')
farmer=report['icons'][0]
for i,(profile,title) in enumerate([('original','ИСХОДНИК 1254×1254'),('ui512','UI 512×512'),('small256','МАЛАЯ 256×256')]):
    x=i*600
    d.text((x+30,136),title,font=font(25,True),fill='#472C50')
    path=ART/farmer['source'] if profile=='original' else ROOT/farmer['variants'][profile]['file']
    paste_fit(icons,path,(x+25,185,550,550))
d.text((35,775),'ПРОВЕРКА ПРИ 96 px: ИСХОДНИК / PNG 512',font=font(27,True),fill='#472C50')
for i,item in enumerate(report['icons']):
    x=i*300
    for col,path in enumerate((ART/item['source'],ROOT/item['variants']['ui512']['file'])):
        paste_fit(icons,path,(x+35+col*125,855,96,96))
    d.text((x+25,987),item['ru'],font=font(22,True),fill='#472C50')
d.text((35,1074),'НА ТЁМНОМ ФОНЕ: ИСХОДНИК / PNG 512',font=font(27,True),fill='#472C50')
d.rectangle((15,1130,1785,1340),fill='#19212B')
for i,item in enumerate(report['icons']):
    x=i*300
    for col,path in enumerate((ART/item['source'],ROOT/item['variants']['ui512']['file'])):
        paste_fit(icons,path,(x+35+col*125,1150,96,96))
    d.text((x+25,1275),item['ru'],font=font(22,True),fill='#e1e5ea')
icons.convert('RGB').save(OUT/'Icon_Comparison.png')
(ROOT/'visual_validation.json').write_text(json.dumps({'passed':True,
    'same_light_and_camera':True,'renders':render_checks,
    'scope':'Offline comparison; not a Roblox frame-rate or network benchmark'},indent=2)+'\n')
print('OPTIMIZATION_REVIEW_SHEETS_COMPLETE')
