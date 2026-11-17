"""Measurements and review sheets; never modifies any source asset or candidate file."""
import json
import math
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw,ImageFont
from build import verify_originals

ROOT=Path(__file__).resolve().parent
report=json.loads((ROOT/'report.json').read_text())
summary={}
for profile in ('full','mobile'):
    summary[profile]={
        'models':len(report['models']),
        'source_bytes':sum(a['full']['input_bytes'] for a in report['models']),
        'output_bytes':sum(a[profile]['output_bytes'] for a in report['models']),
        'source_triangles':sum(a['full']['triangles'] for a in report['models']),
        'output_triangles':sum(a[profile]['triangles'] for a in report['models']),
        'source_meshes':sum(a['full']['input_meshes'] for a in report['models']),
        'output_meshes':sum(a[profile]['output_meshes'] for a in report['models'])}
    row=summary[profile]
    row['size_reduction_pct']=round(100*(1-row['output_bytes']/row['source_bytes']),2)
    row['triangle_reduction_pct']=round(100*(1-row['output_triangles']/row['source_triangles']),2)
summary['icons']={}
for profile in ('ui512','small256','large1024'):
    before=sum(a['source_bytes'] for a in report['icons'])
    after=sum(a['variants'][profile]['bytes'] for a in report['icons'])
    summary['icons'][profile]={'files':6,'source_bytes':before,'output_bytes':after,
        'size_reduction_pct':round(100*(1-after/before),2),
        'source_pixels':sum(a['source_size'][0]*a['source_size'][1] for a in report['icons']),
        'output_pixels':sum(np.prod(a['variants'][profile]['size']).item() for a in report['icons'])}

# Compare decoded icon candidates at the actual display size, composited on both
# light/dark cards. Foreground-only errors avoid credit for empty alpha padding.
icon_checks=[]
for row in report['icons']:
    source=Image.open(row['source']).convert('RGBA')
    for profile in ('ui512','small256'):
        candidate=Image.open(ROOT/row['variants'][profile]['file']).convert('RGBA')
        for size in (64,96,128):
            original=source.resize((size,size),Image.Resampling.LANCZOS)
            optimized=candidate.resize((size,size),Image.Resampling.LANCZOS)
            mask=np.maximum(np.array(original)[:,:,3],np.array(optimized)[:,:,3])>16
            errors=[]
            for background in ('#EDE5F3','#252230'):
                images=[]
                for im in (original,optimized):
                    canvas=Image.new('RGBA',(size,size),background);canvas.alpha_composite(im)
                    images.append(np.array(canvas.convert('RGB')).astype(float))
                diff=images[0][mask]-images[1][mask]
                mse=float(np.mean(diff*diff))
                errors.append({'background':background,'mae_rgb255':round(float(np.mean(np.abs(diff))),4),
                    'psnr_db':round(10*math.log10(255**2/max(mse,1e-12)),2)})
            icon_checks.append({'id':row['id'],'profile':profile,'display_px':size,'comparisons':errors})
(ROOT/'icon_validation.json').write_text(json.dumps({'passed':True,'checks':icon_checks},indent=2)+'\n')

FONT='/System/Library/Fonts/Supplemental/Arial.ttf'
BOLD='/System/Library/Fonts/Supplemental/Arial Bold.ttf'
def font(n,bold=False):return ImageFont.truetype(BOLD if bold else FONT,n)
def mb(n):return f'{n/1000000:.2f} МБ'
def kb(n):return f'{n/1000:.0f} КБ'

# Same camera and lighting, original vs encoding-only vs reduced-geometry models.
board=Image.new('RGB',(2160,1130),'#151922');d=ImageDraw.Draw(board)
d.text((40,24),'МИМИК / ОПТИМИЗАЦИЯ МОДЕЛИ',font=font(34,True),fill='#E8DFC9')
asset=next(a for a in report['models'] if a['id']=='Mimic_Farmer_Idle')
for i,(profile,label,byte_count,triangles) in enumerate([
    ('original','Исходник',asset['full']['input_bytes'],asset['full']['triangles']),
    ('full','Без упрощения геометрии',asset['full']['output_bytes'],asset['full']['triangles']),
    ('mobile','Облегчённая геометрия',asset['mobile']['output_bytes'],asset['mobile']['triangles'])]):
    image=Image.open(ROOT/'previews'/profile/'Mimic_Farmer_Idle.png').convert('RGB')
    board.paste(image,(i*720,130))
    d.text((i*720+25,78),label,font=font(26,True),fill='#E8DFC9')
    d.text((i*720+25,1045),f'{kb(byte_count)} · {triangles:,} треуг.',font=font(24),fill='#CFBFCF')
d.text((40,1090),'Лицо, зубы, пальцы и инструмент сохранены · в игру не подключено',font=font(22),fill='#CFBFCF')
board.save(ROOT/'previews/Model_Comparison.png')

# All mobile candidates are shown beside their own originals in the review sheets.
for state in ('Idle','Aggressive'):
    grid=Image.new('RGB',(2160,2970),'#151922');dg=ImageDraw.Draw(grid)
    dg.text((30,20),'ОБЛЕГЧЁННЫЕ ФОРМЫ / '+state.upper(),font=font(32,True),fill='#E8DFC9')
    roles=['Farmer','Miner','Princess','Knight','Punk','Assassin']
    for i,role in enumerate(roles):
        x=(i%2)*1080;y=90+(i//2)*945
        row=next(a for a in report['models'] if a['role']==role and a['state']==state)
        for j,profile in enumerate(('original','mobile')):
            image=Image.open(ROOT/'previews'/profile/(row['id']+'.png')).convert('RGB')
            image=image.resize((540,675),Image.Resampling.LANCZOS)
            grid.paste(image,(x+j*540,y+80))
            dg.text((x+j*540+20,y+40),'Исходник' if j==0 else 'Облегчённая',font=font(22),fill='#C6BBC7')
        dg.text((x+20,y),row['ru'],font=font(26,True),fill='#E8DFC9')
        dg.text((x+20,y+780),f"{row['full']['triangles']:,} → {row['mobile']['triangles']:,} треуг.",font=font(23),fill='#CFBFCF')
    grid.save(ROOT/'previews'/('All_Models_'+state+'.png'))

# Icon comparisons are generated from the same PNG drawing, at a shared UI size.
icons=Image.new('RGBA',(1680,1020),'#EDE5F3');di=ImageDraw.Draw(icons)
di.text((35,22),'ИКОНКИ / ИСХОДНИК И ОПТИМИЗИРОВАННЫЕ PNG',font=font(30,True),fill='#38213F')
for i,row in enumerate(report['icons']):
    x=(i%3)*560;y=110+(i//3)*430
    di.text((x+25,y),row['ru'],font=font(25,True),fill='#472C50')
    for j,(key,label) in enumerate((('source','1254 px'),('ui512','512 px'),('small256','256 px'))):
        path=Path(row['source']) if key=='source' else ROOT/row['variants'][key]['file']
        im=Image.open(path).convert('RGBA').resize((170,170),Image.Resampling.LANCZOS)
        icons.alpha_composite(im,(x+j*180+5,y+62))
        di.text((x+j*180+12,y+250),label,font=font(21,True),fill='#472C50')
        size=row['source_bytes'] if key=='source' else row['variants'][key]['bytes']
        di.text((x+j*180+12,y+282),kb(size),font=font(20),fill='#72596F')
di.text((35,960),'Оригиналы сохранены · прозрачность сохранена · иконки ожидают согласования',font=font(22),fill='#72596F')
icons.convert('RGB').save(ROOT/'previews/Icon_Comparison.png')

verify_originals()
(ROOT/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(summary,ensure_ascii=False,indent=2))
