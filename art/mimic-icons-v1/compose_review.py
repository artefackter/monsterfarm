"""Review boards only. Source PNG files and their generated alpha are never edited."""
import json
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont

ROOT=Path(__file__).resolve().parent
PROJECT=ROOT.parents[1]
assets=json.loads((ROOT/'assets.json').read_text())['assets']
FONT='/System/Library/Fonts/Supplemental/Arial.ttf'
BOLD='/System/Library/Fonts/Supplemental/Arial Bold.ttf'
def font(n,bold=False):return ImageFont.truetype(BOLD if bold else FONT,n)
def fit(source,box):
    # Resizing is limited to the review sheet, never the candidate PNG asset.
    im=Image.open(source).convert('RGBA')
    im.thumbnail(box,Image.Resampling.LANCZOS)
    return im

board=Image.new('RGBA',(2100,1760),'#EDE5F3')
d=ImageDraw.Draw(board)
d.text((55,28),'МИМИК / ИКОНКИ',font=font(40,True),fill='#38213F')
d.text((55,82),'Текущий стиль интерфейса · 6 портретов · на согласование',font=font(25),fill='#6D526F')
for i,asset in enumerate(assets):
    x=(i%3)*700;y=145+(i//3)*760
    im=fit(ROOT/asset['file'],(660,660))
    board.alpha_composite(im,(x+(700-im.width)//2,y))
    d.text((x+45,y+670),asset['ru'],font=font(29,True),fill='#472C50')
d.text((55,1705),'PNG с прозрачностью · в игру не добавлены · модели согласованы отдельно',font=font(23),fill='#6D526F')
board.convert('RGB').save(ROOT/'previews/Mimic_Icons_Review.png')

# A small UI-size strip checks each silhouette at 64 and 96 pixels.
small=Image.new('RGBA',(1260,440),'#F6EDD8')
ds=ImageDraw.Draw(small)
ds.text((30,18),'Проверка читаемости: 96 px / 64 px',font=font(24,True),fill='#472C50')
for i,asset in enumerate(assets):
    x=i*210
    for size,y in ((96,75),(64,212)):
        im=fit(ROOT/asset['file'],(size,size))
        small.alpha_composite(im,(x+(210-im.width)//2,y))
    ds.text((x+20,335),asset['ru'],font=font(20,True),fill='#472C50')
small.convert('RGB').save(ROOT/'previews/Mimic_Icons_SmallSizes.png')

# Existing portraits are included only as style references on this comparison.
comparison=Image.new('RGBA',(1600,580),'#EDE5F3')
dc=ImageDraw.Draw(comparison)
dc.text((35,20),'СРАВНЕНИЕ С ТЕКУЩИМИ ИКОНКАМИ',font=font(29,True),fill='#38213F')
columns=[(PROJECT/'art/ui/modal-refresh/DeerFarmer.png','Текущая: фермер'),
         (ROOT/'icons/MimicFarmer.png','Новая: мимик-фермер'),
         (PROJECT/'art/ui/monster-outfits/VerityKnight.png','Текущая: рыцарь'),
         (ROOT/'icons/MimicKnight.png','Новая: мимик-рыцарь')]
for i,(path,label) in enumerate(columns):
    im=fit(path,(360,360))
    comparison.alpha_composite(im,(i*400+(400-im.width)//2,85))
    dc.text((i*400+20,520),label,font=font(19,True),fill='#472C50')
comparison.convert('RGB').save(ROOT/'previews/Mimic_Icons_StyleComparison.png')
print('MIMIC_ICON_REVIEW_BOARDS_COMPLETE')
