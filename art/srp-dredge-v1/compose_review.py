"""Compare actual Dredge geometry with the user-supplied source screenshot."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageOps

ROOT=Path(__file__).resolve().parent;OUT=ROOT/'previews'
FONT=Path('/System/Library/Fonts/Supplemental')
title=ImageFont.truetype(str(FONT/'Arial Bold.ttf'),43)
label=ImageFont.truetype(str(FONT/'Arial Bold.ttf'),28)
small=ImageFont.truetype(str(FONT/'Arial.ttf'),23)
BG='#141B21';FG='#EEE6D8';MUTED='#A8B7C2'


def fit(sheet,im,rect):
    x,y,w,h=rect
    im=ImageOps.contain(im.convert('RGB'),(w,h),Image.Resampling.LANCZOS)
    sheet.paste(im,(x+(w-im.width)//2,y+(h-im.height)//2))


source=Path('/var/folders/g0/p39b0rv17qv4_m_fxvnm1zkr0000gn/T/codex-clipboard-ae4f57f1-9806-428c-bd9b-6bc985b2d2b8.png')
reference=Image.open(source).crop((1450,655,2780,1740))
reference.save(OUT/'User_Reference_Dredge_Crop.png')
sheet=Image.new('RGB',(2200,1790),BG);d=ImageDraw.Draw(sheet)
d.text((44,26),'DREDGE / ИСПРАВЛЕННАЯ АНАТОМИЯ',font=title,fill=FG)
d.text((44,84),'Scape and Run: Parasites · одна голова · единое змеиное тело · четыре костяных выступа',font=small,fill=MUTED)
d.text((44,151),'ТВОЙ РЕФЕРЕНС №2',font=label,fill=FG)
d.text((1140,151),'НОВАЯ 3D-МОДЕЛЬ',font=label,fill=FG)
fit(sheet,reference,(30,204,1050,750))
fit(sheet,Image.open(OUT/'Dredge_ThreeQuarter.png'),(1130,204,1040,750))
d.text((44,1006),'ПРОФИЛЬ / ИЗГИБ ТЕЛА',font=label,fill=FG)
d.text((1140,1006),'ГОЛОВА И РЁБРА',font=label,fill=FG)
fit(sheet,Image.open(OUT/'Dredge_Side.png'),(30,1060,1050,650))
fit(sheet,Image.open(OUT/'Dredge_Detail.png'),(1130,1060,1040,650))
d.text((44,1740),'Рендеры фактической геометрии · внешний вид на согласование · в игру и Studio не добавлено',font=small,fill=MUTED)
sheet.save(OUT/'Dredge_Reference_Review.png')

sheet=Image.new('RGB',(2200,1550),BG);d=ImageDraw.Draw(sheet)
d.text((44,28),'DREDGE / РАКУРСЫ',font=title,fill=FG)
for file,caption,rect in [('Dredge_ThreeQuarter.png','ОБЩИЙ ВИД',(30,170,1040,620)),
                         ('Dredge_Back.png','СЗАДИ',(1130,170,1040,620)),
                         ('Dredge_Side.png','ПРОФИЛЬ',(30,880,1040,610)),
                         ('Dredge_Detail.png','ДЕТАЛИ',(1130,880,1040,610))]:
    d.text((rect[0]+15,rect[1]-42),caption,font=label,fill=MUTED)
    fit(sheet,Image.open(OUT/file),rect)
sheet.save(OUT/'Dredge_Views.png')
print(OUT/'Dredge_Reference_Review.png')
