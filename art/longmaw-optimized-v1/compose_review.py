"""Compose review-only sheets. Never modifies model or icon candidates."""
import json
import math
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageOps,ImageChops,ImageStat
from assets import ROOT,models,icons,ROLES,verify_sources

FONT=Path('/System/Library/Fonts/Supplemental')
bold=ImageFont.truetype(str(FONT/'Arial Bold.ttf'),26)
small=ImageFont.truetype(str(FONT/'Arial.ttf'),21)
title=ImageFont.truetype(str(FONT/'Arial Bold.ttf'),34)
BG='#EDE6F2';INK='#382341';PREVIEW=ROOT/'previews';PREVIEW.mkdir(exist_ok=True)
report=json.loads((ROOT/'models_report.json').read_text())
by_id={a['id']:a for a in report['models']}
icon_report=json.loads((ROOT/'icons_report.json').read_text())

def paste(sheet,path,box):
    image=Image.open(path).convert('RGBA')
    x,y,w,h=box;image=ImageOps.contain(image,(w,h),Image.Resampling.LANCZOS)
    sheet.alpha_composite(image,(x+(w-image.width)//2,y+(h-image.height)//2))

def raw(asset,profile,view='Full'):
    return PREVIEW/'raw'/(asset['id']+'_'+profile+'_'+view+'.png')

def model_board(assets,output,heading,view='Full'):
    w,h=(420,590) if view=='Full' else (550,620)
    sheet=Image.new('RGBA',(w*3,140+h*len(assets)),BG);draw=ImageDraw.Draw(sheet)
    draw.text((26,20),heading,font=title,fill=INK)
    columns=[('source','Исходник'),('models','Компактный GLB'),('mobile','Облегчённый GLB')]
    for i,(_,caption) in enumerate(columns):draw.text((i*w+w//2,83),caption,font=bold,fill=INK,anchor='mt')
    for j,asset in enumerate(assets):
        y=130+j*h
        for i,(profile,_) in enumerate(columns):
            draw.text((i*w+w//2,y),asset['ru']+' / '+asset['state'],font=small,fill=INK,anchor='mt')
            paste(sheet,raw(asset,profile,view),(i*w+10,y+34,w-20,h-106))
            if profile=='source':
                data=by_id[asset['id']]['profiles']['models'];size=data['input_bytes'];tris=data['triangles']
            else:
                data=by_id[asset['id']]['profiles'][profile];size=data['output_bytes'];tris=data['triangles']
            draw.text((i*w+w//2,y+h-53),f'{size/1000:.0f} КБ · {tris:,} трис'.replace(',',' '),font=small,fill=INK,anchor='mt')
    sheet.convert('RGB').save(PREVIEW/output)

assets=models()
model_board([a for a in assets if (a['role'],a['state']) in [('Base','Idle'),('Knight','Aggressive'),('Punk','Idle')]],
            'Optimization_Review.png','ДЛИННОРОТ / ОПТИМИЗАЦИЯ НА СОГЛАСОВАНИЕ')
for state in ('Idle','Aggressive'):
    model_board([a for a in assets if a['state']==state],f'Models_Comparison_{state}.png',
                'СРАВНЕНИЕ ВСЕХ МОДЕЛЕЙ / '+state.upper())
model_board([a for a in assets if a['role'] in ('Base','Knight','Punk','Assassin') and a['state']=='Idle'],
            'Details_Comparison.png','МОРДА И БЕЛЫЕ ГЛАЗА / КРУПНЫЙ ПЛАН','Head')

sheet=Image.new('RGBA',(1110,145+6*355),BG);draw=ImageDraw.Draw(sheet)
draw.text((24,20),'ИКОНКИ / РАЗРЕШЕНИЕ И РАЗМЕР PNG',font=title,fill=INK)
for i,caption in enumerate(('Исходник 1254 px','UI 512 px','Малые 256 px')):
    draw.text((i*370+185,82),caption,font=bold,fill=INK,anchor='mt')
for j,row in enumerate(icon_report['icons']):
    y=140+j*355
    for i,profile in enumerate(('source','ui512','small256')):
        if profile=='source':path=row['source'];size=row['source_bytes']
        else:
            variant=row['variants'][profile];path=ROOT/variant['file'];size=variant['bytes']
        draw.text((i*370+185,y),row['ru'],font=small,fill=INK,anchor='mt')
        paste(sheet,path,(i*370+40,y+31,290,275))
        draw.text((i*370+185,y+317),f'{size/1000:.1f} КБ',font=small,fill=INK,anchor='mt')
sheet.convert('RGB').save(PREVIEW/'Icons_Comparison.png')

sheet=Image.new('RGBA',(1680,770),BG);draw=ImageDraw.Draw(sheet)
draw.text((25,20),'ИКОНКИ В ИНТЕРФЕЙСЕ / ИСХОДНИК И 512 PX',font=title,fill=INK)
for j,row in enumerate(icon_report['icons']):
    x=j*280
    draw.text((x+140,82),row['ru'],font=small,fill=INK,anchor='mt')
    for size,y in ((96,129),(64,310)):
        for i,path in enumerate((row['source'],ROOT/row['variants']['ui512']['file'])):
            paste(sheet,path,(x+15+i*140+(120-size)//2,y,size,size))
            draw.text((x+75+i*140,y+size+12),('До' if i==0 else '512'),font=small,fill=INK,anchor='mt')
    draw.rectangle((x,463,x+280,730),fill='#20212B')
    for i,path in enumerate((row['source'],ROOT/row['variants']['ui512']['file'])):
        paste(sheet,path,(x+15+i*140+12,505,96,96))
        draw.text((x+75+i*140,625),('До' if i==0 else '512'),font=small,fill='#EDE6F2',anchor='mt')
sheet.convert('RGB').save(PREVIEW/'Icons_UI_Sizes.png')

comparisons=[]
for asset in assets:
    a=Image.open(raw(asset,'source')).convert('RGB')
    for profile in ('models','mobile'):
        b=Image.open(raw(asset,profile)).convert('RGB');assert a.size==b.size
        stats=ImageStat.Stat(ImageChops.difference(a,b));rms=math.sqrt(sum(v*v for v in stats.rms)/3)
        comparisons.append({'id':asset['id'],'profile':profile,'image_rms_255':round(rms,4),
                            'psnr_db':round(20*math.log10(255/max(rms,1e-9)),2)})
(ROOT/'visual_metrics.json').write_text(json.dumps({'same_stage_render_comparison':comparisons,
    'metric_is_not_runtime_benchmark':True,'source_files_unchanged':verify_sources()},indent=2)+'\n')
print('REVIEW_COMPLETE',len(comparisons),flush=True)
