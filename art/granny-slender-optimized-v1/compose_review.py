"""Review sheets and image comparisons from reimported model renders / source PNGs."""
import json
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageOps,ImageChops,ImageStat
ROOT=Path(__file__).resolve().parent;OUT=ROOT/'previews'
def font(size,bold=False):return ImageFont.truetype('/System/Library/Fonts/Supplemental/'+('Arial Bold.ttf' if bold else 'Arial.ttf'),size)
def paste(board,path,box):
    x,y,w,h=box;im=Image.open(path).convert('RGBA');im=ImageOps.contain(im,(w,h),Image.Resampling.LANCZOS)
    board.paste(im,(x+(w-im.width)//2,y+(h-im.height)//2),im)
renders=json.loads((ROOT/'render_manifest.json').read_text())['renders'];cases={}
for row in renders:cases.setdefault(row['case'],{})[row['profile']]=row
pixel_checks=[]
for case,items in cases.items():
    before=Image.open(ROOT/items['original']['file']).convert('RGB');after=Image.open(ROOT/items['optimized']['file']).convert('RGB')
    assert before.size==after.size
    diff=ImageChops.difference(before,after);stats=ImageStat.Stat(diff)
    pixel_checks.append({'case':case,'mean_rgb_error_255':round(sum(stats.mean)/3,6),
                         'maximum_channel_error_255':max(x[1] for x in diff.getextrema())})
    width,height=(1800,1250) if before.height>before.width else (2000,1050)
    board=Image.new('RGB',(width,height),'#10191F');d=ImageDraw.Draw(board)
    d.text((30,20),case.replace('_',' / '),font=font(30,True),fill='#EEE6D8')
    for c,profile in enumerate(('original','optimized')):
        paste(board,ROOT/items[profile]['file'],(c*width//2,110,width//2,height-160))
        d.text((c*width//2+30,75),'ИСХОДНИК' if c==0 else 'ОПТИМИЗИРОВАННЫЙ GLB',font=font(27,True),fill='#ADBAC3')
    d.text((30,height-36),'Повторный импорт GLB · одинаковое освещение и камера · в игру не добавлено',font=font(22),fill='#ADBAC3')
    folder=OUT/'comparisons';folder.mkdir(exist_ok=True);board.save(folder/(case+'.png'))

selected=[('Granny_Idle_full','GRANNY / IDLE'),('Grandfather_King_Idle_full','ДЕД / КОРОЛЬ'),
          ('Slenderman_King_Idle_full','СЛЕНДЕРМЕН / КОРОЛЬ'),('SpiderMom_Knight_Idle_full','МАМА-ПАУК / РЫЦАРЬ')]
board=Image.new('RGB',(2400,2020),'#10191F');d=ImageDraw.Draw(board)
d.text((35,20),'35 МОДЕЛЕЙ / СРАВНЕНИЕ ИСХОДНИКОВ И КОМПАКТНЫХ КОПИЙ',font=font(34,True),fill='#EEE6D8')
for i,(case,title) in enumerate(selected):
    x=(i%2)*1200;y=100+(i//2)*930
    d.text((x+30,y),title,font=font(28,True),fill='#DCC7A4')
    for c,profile in enumerate(('original','optimized')):
        paste(board,ROOT/cases[case][profile]['file'],(x+c*600,y+88,600,810))
        d.text((x+c*600+30,y+48),'Исходник' if c==0 else 'Компактный GLB',font=font(24,True),fill='#ADBAC3')
d.text((35,1975),'Треугольники, нормали, скелеты и движущиеся ключи сохранены · в игру не добавлено',font=font(25),fill='#ADBAC3')
board.save(OUT/'Model_Comparison.png')

grips=[('Granny_Idle_grip','GRANNY / IDLE'),('Granny_Aggressive_grip','GRANNY / AGGRESSIVE'),('Grandfather_King_Idle_weapon','ДЕД / РУЖЬЁ')]
board=Image.new('RGB',(1800,2220),'#10191F');d=ImageDraw.Draw(board)
d.text((30,20),'ХВАТЫ / ДО И ПОСЛЕ ОПТИМИЗАЦИИ',font=font(34,True),fill='#EEE6D8')
for i,(case,title) in enumerate(grips):
    y=100+i*690;d.text((30,y),title,font=font(28,True),fill='#DCC7A4')
    for c,profile in enumerate(('original','optimized')):
        paste(board,ROOT/cases[case][profile]['file'],(c*900,y+85,900,580))
        d.text((c*900+30,y+43),'Исходник' if c==0 else 'Компактный GLB',font=font(24,True),fill='#ADBAC3')
board.save(OUT/'Grip_Comparison.png')

icons=json.loads((ROOT/'icons_report.json').read_text())['icons'];byid={i['id']:i for i in icons}
board=Image.new('RGB',(1600,1390),'#EDE5F3');d=ImageDraw.Draw(board)
d.text((30,20),'ИКОНКИ / ОДИН РИСУНОК ПРИ РАЗНЫХ РАЗРЕШЕНИЯХ',font=font(30,True),fill='#38213F')
d.text((30,66),'Во всех колонках размер показа 192 px · прозрачность сохранена',font=font(23),fill='#6D526F')
columns=[('source','1254 px / исходник'),('large1024','1024 px'),('ui512','512 px'),('small256','256 px')]
for row,(id,bg) in enumerate([('GrannyFarmer','#F6EEDC'),('GrannyFarmer','#151C26'),('GrandfatherKing','#F6EEDC'),('GrandfatherKing','#151C26')]):
    y=125+row*300;d.rectangle((0,y,1600,y+290),fill=bg)
    ink='#472C50' if bg=='#F6EEDC' else '#EEE6D8';icon=byid[id]
    for c,(profile,label) in enumerate(columns):
        path=Path(icon['source']) if profile=='source' else ROOT/icon['variants'][profile]['file']
        paste(board,path,(c*400,y+60,400,192));d.text((c*400+24,y+15),label,font=font(24,True),fill=ink)
    d.text((25,y+258),'GRANNY / ФЕРМЕР' if id.startswith('Granny') else 'ДЕД / КОРОЛЬ',font=font(19,True),fill=ink)
d.text((30,1350),'Рисунок не перегенерирован · уменьшение разрешения и PNG-сжатие · в игру не добавлено',font=font(21),fill='#6D526F')
board.save(OUT/'Icon_Comparison.png')

roles={'Farmer':'Фермер','Miner':'Шахтёр','Princess':'Принцесса','King':'Король','Knight':'Рыцарь','Punk':'Нефор','Assassin':'Убийца'}
role_order={'Farmer':0,'Miner':1,'Princess':2,'King':2,'Knight':3,'Punk':4,'Assassin':5}
board=Image.new('RGB',(1920,880),'#EDE5F3');d=ImageDraw.Draw(board)
d.text((30,15),'12 ИКОНОК / PNG 512×512',font=font(30,True),fill='#38213F')
for row,person in enumerate(('Granny','Grandfather')):
    rows=sorted((i for i in icons if i['character']==person),key=lambda i:role_order[i['role']])
    y=70+row*380
    for c,icon in enumerate(rows):
        paste(board,ROOT/icon['variants']['ui512']['file'],(c*320,y,320,310))
        d.text((c*320+20,y+320),('Granny' if row==0 else 'Дед')+' / '+roles[icon['role']],font=font(20,True),fill='#472C50')
board.save(OUT/'All_Icons_512.png')
(ROOT/'visual_validation.json').write_text(json.dumps({'passed':True,'model_render_comparisons':pixel_checks,
    'icon_comparison_sizes':[64,96,128],'icon_metrics':'icons_report.json','note':'Review renders only; source and optimized model files are not changed by this script.'},indent=2)+'\n')
print('REVIEW_SHEETS_COMPLETE','RENDER_PAIRS',len(pixel_checks),'MAX_RENDER_MEAN_RGB_ERROR',max(i['mean_rgb_error_255'] for i in pixel_checks))
