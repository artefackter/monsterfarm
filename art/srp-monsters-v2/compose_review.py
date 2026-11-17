"""Approval sheets made from real model renders and the owner's screenshots."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageOps

ROOT=Path(__file__).resolve().parent;OUT=ROOT/'previews'
TEMP=Path('/var/folders/g0/p39b0rv17qv4_m_fxvnm1zkr0000gn/T')
FONT=Path('/System/Library/Fonts/Supplemental')
title=ImageFont.truetype(str(FONT/'Arial Bold.ttf'),42)
label=ImageFont.truetype(str(FONT/'Arial Bold.ttf'),28)
small=ImageFont.truetype(str(FONT/'Arial.ttf'),23)
BG='#141B21';FG='#EEE6D8';MUTED='#A8B7C2'

SPECS=[
    ('AssimilatedAdventurer',1,'ASSIMILATED ADVENTURER','11ec7a5e-514c-405c-a34f-cca71cd7ee38',
     (1575,565,2210,1460),'Раскрытая грудь · шлем · человеческие руки и ноги'),
    ('PrimitiveSummoner',3,'PRIMITIVE SUMMONER','1ee295eb-6b7f-4c3d-a8de-16c6882b7a58',
     (690,500,2990,2290),'Две отдельные челюсти · четыре высокие опорные лапы'),
    ('ParasiteAdapted',4,'ПАРАЗИТ — АДАПТАЦИЯ','85a8d2e6-008c-424f-bb24-254d25033264',
     (80,135,1190,1425),'На основе существующего Parasite_Root_Aggressive · отдельная копия'),
    ('AdaptedViscera',5,'ADAPTED VISCERA','a0a273b5-fd0d-4c41-b36e-12cb125935c6',
     (110,340,2830,2310),'Объёмная оболочка · восемь зубчатых отростков · шесть ног'),
]

def fit(sheet,im,rect):
    x,y,w,h=rect
    im=ImageOps.contain(im.convert('RGB'),(w,h),Image.Resampling.LANCZOS)
    sheet.paste(im,(x+(w-im.width)//2,y+(h-im.height)//2))

for name,number,caption,key,crop,note in SPECS:
    ref=OUT/('User_Reference_'+name+'_Crop.png')
    source=TEMP/('codex-clipboard-'+key+'.png')
    if source.exists():Image.open(source).crop(crop).save(ref)
    sheet=Image.new('RGB',(2200,1790),BG);d=ImageDraw.Draw(sheet)
    d.text((44,26),caption+' / НА СОГЛАСОВАНИЕ',font=title,fill=FG)
    d.text((44,84),note,font=small,fill=MUTED)
    d.text((44,151),'ТВОЙ РЕФЕРЕНС №'+str(number),font=label,fill=FG)
    d.text((1140,151),'АДАПТАЦИЯ ПАРАЗИТА' if number==4 else 'НОВАЯ 3D-МОДЕЛЬ',font=label,fill=FG)
    fit(sheet,Image.open(ref),(30,204,1050,750))
    fit(sheet,Image.open(OUT/(name+'_ThreeQuarter.png')),(1130,204,1040,750))
    d.text((44,1006),'ПРОФИЛЬ / ОБЪЁМ',font=label,fill=FG)
    d.text((1140,1006),'ДЕТАЛИ',font=label,fill=FG)
    fit(sheet,Image.open(OUT/(name+'_Side.png')),(30,1060,1050,650))
    fit(sheet,Image.open(OUT/(name+'_Detail.png')),(1130,1060,1040,650))
    d.text((44,1740),'Рендеры фактической геометрии · внешний вид на согласование · в игру и Studio не добавлено',font=small,fill=MUTED)
    sheet.save(OUT/(name+'_Reference_Review.png'))
    sheet=Image.new('RGB',(2200,1550),BG);d=ImageDraw.Draw(sheet)
    d.text((44,28),caption+' / РАКУРСЫ',font=title,fill=FG)
    for suffix,text,rect in [('ThreeQuarter','ОБЩИЙ ВИД',(30,170,1040,620)),
                             ('Back','СЗАДИ',(1130,170,1040,620)),
                             ('Side','ПРОФИЛЬ',(30,880,1040,610)),
                             ('Detail','ДЕТАЛИ',(1130,880,1040,610))]:
        d.text((rect[0]+15,rect[1]-42),text,font=label,fill=MUTED)
        fit(sheet,Image.open(OUT/(name+'_'+suffix+'.png')),rect)
    sheet.save(OUT/(name+'_Views.png'))

# A compact board still retains both the screenshot and its corresponding 3D model.
sheet=Image.new('RGB',(2400,2430),BG);d=ImageDraw.Draw(sheet)
d.text((44,28),'SCAPE AND RUN: PARASITES / ТРИ МОДЕЛИ + ПАРАЗИТ',font=title,fill=FG)
d.text((44,88),'На согласование · тот же подход к формам и материалам, что у одобренного Dredge',font=small,fill=MUTED)
for i,(name,number,caption,key,crop,note) in enumerate(SPECS):
    x=(i%2)*1200;y=165+(i//2)*1080
    d.rounded_rectangle((x+20,y,x+1180,y+1040),18,outline='#34434C',width=2)
    d.text((x+44,y+23),'№'+str(number)+'  '+caption,font=label,fill=FG)
    d.text((x+44,y+77),'ИСХОДНЫЙ ПАРАЗИТ' if number==4 else 'РЕФЕРЕНС',font=small,fill=MUTED)
    d.text((x+591,y+77),'АДАПТАЦИЯ' if number==4 else '3D-МОДЕЛЬ',font=small,fill=MUTED)
    refpath=OUT/'ParasiteExisting_ThreeQuarter.png' if number==4 else OUT/('User_Reference_'+name+'_Crop.png')
    fit(sheet,Image.open(refpath),(x+35,y+127,510,865))
    fit(sheet,Image.open(OUT/(name+'_ThreeQuarter.png')),(x+563,y+127,590,865))
d.text((44,2350),'Dredge согласован и сохранён без изменений. Остальные четыре требуют отдельного согласования.',font=small,fill=MUTED)
d.text((44,2388),'FBX + GLB + Blender · отдельные риги · без анимаций · игра и Roblox Studio не менялись',font=small,fill=MUTED)
sheet.save(OUT/'SRP_Four_Reference_Review.png')
sheet=Image.new('RGB',(2200,1700),BG);d=ImageDraw.Draw(sheet)
d.text((44,26),'ПАРАЗИТ / АДАПТАЦИЯ СУЩЕСТВУЮЩЕЙ МОДЕЛИ',font=title,fill=FG)
d.text((44,84),'Пасть, конечности, отростки и исходные точки крепления сохранены. Оригинал не менялся.',font=small,fill=MUTED)
for x,name,caption in [(30,'ParasiteExisting','ИСХОДНЫЙ ПАРАЗИТ'),(1130,'ParasiteAdapted','АДАПТИРОВАННАЯ КОПИЯ')]:
    d.text((x+14,150),caption,font=label,fill=FG)
    fit(sheet,Image.open(OUT/(name+'_ThreeQuarter.png')),(x,200,1040,780))
d.text((44,1020),'АДАПТАЦИЯ / СЗАДИ',font=label,fill=FG)
d.text((1140,1020),'АДАПТАЦИЯ / ПРОФИЛЬ',font=label,fill=FG)
fit(sheet,Image.open(OUT/'ParasiteAdapted_Back.png'),(30,1070,1040,550))
fit(sheet,Image.open(OUT/'ParasiteAdapted_Side.png'),(1130,1070,1040,550))
d.text((44,1645),'Добавлены складки на спине, шире верх корпуса и руки · отдельный файл на согласование · в игру не добавлено',font=small,fill=MUTED)
sheet.save(OUT/'Parasite_Before_After.png')
print(OUT/'SRP_Four_Reference_Review.png')
