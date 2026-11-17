"""Compose review sheets only; never modify original icon pixels or alpha."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent.parent
CHARACTERS = ['Dredge', 'AssimilatedAdventurer', 'PrimitiveSummoner', 'AdaptedViscera']
NAMES = ['Dredge', 'Assimilated Adventurer', 'Primitive Summoner', 'Adapted Viscera']
ROLES = ['Farmer', 'Miner', 'King', 'Knight', 'Nefor', 'Killer']
LABELS = ['Фермер', 'Шахтёр', 'Король', 'Рыцарь', 'Нефор', 'Убийца']
BG = '#eee5f4'
INK = '#36233e'
def font(n, bold=False):
    return ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial'+(' Bold' if bold else '')+'.ttf', n)
def label(im, xy, text, n=28, anchor='la', fill=INK, bold=False):
    ImageDraw.Draw(im).text(xy, text, font=font(n,bold), anchor=anchor, fill=fill)
def place(im, path, box):
    a=Image.open(path).convert('RGBA')
    a.thumbnail((box[2],box[3]),Image.Resampling.LANCZOS)
    im.paste(a,(box[0]+(box[2]-a.width)//2,box[1]+(box[3]-a.height)//2),a)
def icon(c,r): return ROOT/'icons'/f'{c}{r}.png'

sheet=Image.new('RGB',(2400,2110),BG)
label(sheet,(40,45),'24 иконки • на согласование',48,bold=True)
label(sheet,(40,100),'4 персонажа × 6 образов · без предметов в руках · в игру не добавлены',25)
for k,c in enumerate(CHARACTERS):
    y=155+k*480
    label(sheet,(40,y),NAMES[k],30,bold=True)
    for j,r in enumerate(ROLES):
        x=20+j*395
        place(sheet,icon(c,r),(x,y+42,380,380))
        label(sheet,(x+190,y+445),LABELS[j],27,anchor='mm')
sheet.save(ROOT/'previews'/'All_24_Icons.png')
for k,c in enumerate(CHARACTERS):
    board=Image.new('RGB',(1800,1400),BG)
    label(board,(40,45),NAMES[k]+' • 6 образов',44,bold=True)
    label(board,(40,96),'Предварительный набор для согласования',25)
    for j,r in enumerate(ROLES):
        x=20+(j%3)*595; y=140+(j//3)*615
        place(board,icon(c,r),(x,y,560,540))
        label(board,(x+280,y+575),LABELS[j],31,anchor='mm')
    board.save(ROOT/'previews'/f'{c}_Six_Icons.png')

small=Image.new('RGB',(1500,1120),BG)
label(small,(30,35),'Проверка 96 px и 64 px • светлый / тёмный фон',32,bold=True)
for k,c in enumerate(CHARACTERS):
    y=95+k*250
    label(small,(25,y),NAMES[k],24,bold=True)
    for j,r in enumerate(ROLES):
        x=20+j*246
        label(small,(x+110,y+42),LABELS[j],20,anchor='mm')
        for off,bg in [(0,BG),(118,'#211b29')]:
            ImageDraw.Draw(small).rectangle((x+off,y+62,x+off+112,y+232),fill=bg)
            place(small,icon(c,r),(x+off+8,y+65,96,96))
            place(small,icon(c,r),(x+off+24,y+166,64,64))
small.save(ROOT/'previews'/'Small_Size_Check.png')

comparison=Image.new('RGB',(2000,580),BG)
label(comparison,(30,38),'Текущая иконка игры и новые иллюстрации',37,bold=True)
paths=[REPO/'art/ui/modal-refresh/DeerFarmer.png']+[icon(c,'Farmer') for c in CHARACTERS]
names=['Стиль игры: DeerFarmer']+NAMES
for i,(p,name) in enumerate(zip(paths,names)):
    place(comparison,p,(i*400+20,100,360,380))
    label(comparison,(i*400+200,525),name,22,anchor='mm')
comparison.save(ROOT/'previews'/'Style_Comparison.png')
print('7 review sheets saved')
