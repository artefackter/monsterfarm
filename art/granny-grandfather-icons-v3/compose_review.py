"""Review layouts and PNG checks only; generated candidate pixels/alpha stay intact."""
import hashlib
import json
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont

ROOT=Path(__file__).resolve().parent
PROJECT=ROOT.parents[1]
MANIFEST=json.loads((ROOT/'assets.json').read_text())
ASSETS=MANIFEST['assets']
ROLES=['Farmer','Miner','Princess','King','Knight','Punk','Assassin']
def font(size,bold=False):
    name='Arial Bold.ttf' if bold else 'Arial.ttf'
    return ImageFont.truetype('/System/Library/Fonts/Supplemental/'+name,size)
def fit(path,size):
    im=Image.open(path).convert('RGBA');im.thumbnail(size,Image.Resampling.LANCZOS);return im

validation=[]
for a in ASSETS:
    p=ROOT/a['file'];im=Image.open(p)
    assert im.mode=='RGBA' and im.width==im.height
    alpha=im.getchannel('A')
    assert alpha.getextrema()==(0,255),a['id']
    corners=[alpha.getpixel(pos) for pos in [(0,0),(im.width-1,0),(0,im.height-1),(im.width-1,im.height-1)]]
    # Preserve generated alpha, including an occasional invisible 1/255 sample.
    assert max(corners)<=1,a['id']
    hist=alpha.histogram()
    validation.append({'id':a['id'],'file':a['file'],'width':im.width,'height':im.height,'mode':im.mode,
                       'alpha_min':0,'alpha_max':255,'corner_alpha':corners,'transparent_fraction':round(hist[0]/(im.width*im.height),4),
                       'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
for person,title in [('Granny','GRANNY'),('Grandfather','ДЕД')]:
    rows=sorted([a for a in ASSETS if a['character']==person],key=lambda a:ROLES.index(a['role']))
    board=Image.new('RGBA',(2100,1760),'#EDE5F3');d=ImageDraw.Draw(board)
    d.text((50,25),title+' / ИКОНКИ',font=font(40,True),fill='#38213F')
    d.text((50,80),'Новый разворот кисти Granny / Король у Деда · на согласование',font=font(25),fill='#6D526F')
    for i,a in enumerate(rows):
        x=(i%3)*700;y=135+(i//3)*760
        im=fit(ROOT/a['file'],(650,650))
        board.alpha_composite(im,(x+(700-im.width)//2,y))
        d.text((x+40,y+665),a['ru'],font=font(29,True),fill='#472C50')
    if person=='Grandfather' and any(a['id']=='GrandfatherAssassin' for a in MANIFEST['blocked']):
        x=1400;y=895
        d.rounded_rectangle((x+45,y+40,x+655,y+640),radius=24,fill='#DFD4E5',outline='#BBA9C6',width=3)
        for dy,line in [(170,'Убийца'),(235,'Исправленная иконка'),(280,'пока не создана'),(355,'Генератор отклонил запрос'),(400,'Старая версия сохранена отдельно')]:
            d.text((x+75,y+dy),line,font=font(26,dy==170),fill='#6D526F')
    d.text((50,1705),'PNG с прозрачностью · изменения на согласование · в игру не добавлены',font=font(23),fill='#6D526F')
    board.convert('RGB').save(ROOT/'previews'/(person+'_Icons_Review.png'))
    small=Image.new('RGBA',(1260,430),'#F6EDD8');ds=ImageDraw.Draw(small)
    ds.text((30,15),title+' / Читаемость: 96 px и 64 px',font=font(24,True),fill='#472C50')
    for i,a in enumerate(rows):
        x=i*210
        for size,y in ((96,70),(64,210)):
            im=fit(ROOT/a['file'],(size,size));small.alpha_composite(im,(x+(210-im.width)//2,y))
        ds.text((x+14,330),a['ru'],font=font(20,True),fill='#472C50')
    small.convert('RGB').save(ROOT/'previews'/(person+'_Icons_SmallSizes.png'))

board=Image.new('RGBA',(2000,660),'#EDE5F3');d=ImageDraw.Draw(board)
d.text((35,18),'СРАВНЕНИЕ С ТЕКУЩИМ ДИЗАЙНОМ',font=font(30,True),fill='#38213F')
cols=[(PROJECT/'art/ui/modal-refresh/DeerFarmer.png','Текущая: Олень'),
      (PROJECT/'art/mimic-icons-v1/icons/MimicFarmer.png','Мимик: кандидат'),
      (ROOT/'icons/GrannyFarmer.png','Granny: кандидат'),
      (ROOT/'icons/GrandfatherFarmer.png','Дед: кандидат')]
for i,(p,title) in enumerate(cols):
    im=fit(p,(455,455));board.alpha_composite(im,(i*500+(500-im.width)//2,90))
    d.text((i*500+25,590),title,font=font(24,True),fill='#472C50')
board.convert('RGB').save(ROOT/'previews/Style_Comparison.png')
(ROOT/'validation.json').write_text(json.dumps({'available_assets_passed':True,
    'complete':len(validation)==MANIFEST['requested_count'],'requested_count':MANIFEST['requested_count'],
    'completed_count':len(validation),'assets':validation,'blocked':MANIFEST['blocked'],
    'candidate_images_modified':False,'status':MANIFEST['status']},ensure_ascii=False,indent=2)+'\n')
print('ICONS_VALIDATED',len(validation))

# Only review-sheet crops; delivered icon PNGs and alpha are left untouched.
models=PROJECT/'art/granny-grandfather-v4/previews'
board=Image.new('RGBA',(2100,1320),'#EDE5F3');d=ImageDraw.Draw(board)
d.text((35,20),'GRANNY + ДЕД / ИСПРАВЛЕННЫЕ ХВАТЫ',font=font(36,True),fill='#38213F')
d.text((35,72),'Крупные планы фактических 3D-моделей и новых иконок',font=font(25),fill='#6D526F')
for row,person in enumerate(('Granny','Grandfather')):
    y=130+row*570
    names=([person+'_Idle_GripR.png',person+'_Aggressive_GripR.png'] if person=='Granny'
           else [person+'_Idle_Weapon.png',person+'_Aggressive_Weapon.png'])
    for col,name in enumerate(names):
        im=fit(models/name,(680,480));board.alpha_composite(im,(col*700+(700-im.width)//2,y+45))
        d.text((col*700+30,y),('GRANNY' if row==0 else 'ДЕД')+' / 3D '+('IDLE' if col==0 else 'AGGRESSIVE'),font=font(27,True),fill='#472C50')
    im=Image.open(ROOT/('icons/'+person+'Farmer.png')).convert('RGBA')
    box=(.23,.49,.40,.77) if person=='Granny' else (.22,.40,.80,.63)
    im=im.crop(tuple(round(v*(im.width if i%2==0 else im.height)) for i,v in enumerate(box)))
    im.thumbnail((650,480),Image.Resampling.LANCZOS)
    # Enlarge review crops for legibility without changing the asset.
    scale=min(650/im.width,480/im.height)
    im=im.resize((round(im.width*scale),round(im.height*scale)),Image.Resampling.LANCZOS)
    board.alpha_composite(im,(1400+(700-im.width)//2,y+45+(480-im.height)//2))
    d.text((1430,y),'ИКОНКА / НОВЫЙ ХВАТ',font=font(27,True),fill='#472C50')
d.text((35,1270),'3D и иконки: новый разворот кисти Granny · на согласование',font=font(26),fill='#6D526F')
board.convert('RGB').save(ROOT/'previews/Grip_Fixes_Review.png')
