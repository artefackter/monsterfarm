"""Validate original PNGs and compose review sheets without editing candidates."""
import hashlib
import json
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageOps

ROOT=Path(__file__).resolve().parent
PROJECT=ROOT.parents[1]
PREVIEW=ROOT/'previews'
FONT=Path('/System/Library/Fonts/Supplemental')
title=ImageFont.truetype(str(FONT/'Arial Bold.ttf'),40)
label=ImageFont.truetype(str(FONT/'Arial Bold.ttf'),27)
small=ImageFont.truetype(str(FONT/'Arial.ttf'),22)
BG='#EDE6F2'
INK='#382341'
data=json.loads((ROOT/'assets.json').read_text())
assets=data['assets']
assert len(assets)==6
images={}
validation=[]
references=json.loads((ROOT/'references.json').read_text())
for relative,expected in references['source_hashes'].items():
    assert hashlib.sha256((PROJECT/relative).read_bytes()).hexdigest()==expected,relative
for row in assets:
    path=ROOT/row['file']
    digest=hashlib.sha256(path.read_bytes()).hexdigest()
    assert digest==hashlib.sha256(Path(row['generated_source']).read_bytes()).hexdigest(),(row['role'],'original changed')
    im=Image.open(path)
    assert im.mode=='RGBA',(row['role'],im.mode)
    assert im.width==im.height and im.width>=1024,(row['role'],im.size)
    alpha=im.getchannel('A')
    histogram=alpha.histogram()
    assert histogram[0]>im.width*im.height*.08,(row['role'],'missing transparent area')
    # Native generation uses mostly 250-254 alpha for the painted silhouette.
    # Verify near-opacity rather than requiring every interior pixel to be 255.
    assert sum(histogram[250:])>im.width*im.height*.20,(row['role'],'missing near-opaque illustration')
    # Check the visible silhouette without changing native alpha. Generated
    # PNGs can have faint alpha speckles outside the illustration.
    border=[alpha.crop(box).getextrema()[1] for box in ((0,0,im.width,2),
             (0,im.height-2,im.width,im.height),(0,0,2,im.height),(im.width-2,0,im.width,im.height))]
    assert max(border)<16,(row['role'],'visible image touches frame',border)
    images[row['role']]=im
    validation.append({'role':row['role'],'file':row['file'],'size':list(im.size),'mode':im.mode,
        'alpha_extrema':list(alpha.getextrema()),'transparent_pixels':histogram[0],
        'opaque_pixels':histogram[255],'near_opaque_pixels_alpha_250_plus':sum(histogram[250:]),
        'visible_silhouette_inside_frame':True,
        'outer_border_max_alpha':max(border),
        'matches_generated_original':True,'sha256':digest})


def paste_icon(sheet,im,box):
    # Review-only scaling. The generated deliverable is never resampled or cropped.
    x,y,w,h=box
    thumb=ImageOps.contain(im,(w,h),Image.Resampling.LANCZOS)
    sheet.alpha_composite(thumb,(x+(w-thumb.width)//2,y+(h-thumb.height)//2))


sheet=Image.new('RGBA',(1980,1630),BG)
draw=ImageDraw.Draw(sheet)
draw.text((40,24),'ДЛИННОРОТ / ИКОНКИ НА СОГЛАСОВАНИЕ',font=title,fill=INK)
draw.text((40,80),'Рисованный стиль текущих иконок · PNG с прозрачностью · в игру не добавлено',font=small,fill='#68546D')
for i,row in enumerate(assets):
    x,y=30+(i%3)*650,140+(i//3)*710
    paste_icon(sheet,images[row['role']],(x,y,630,610))
    draw.text((x+315,y+625),row['ru'].upper(),font=label,fill=INK,anchor='mt')
draw.text((40,1582),'Светлый фон и подписи — только на этом листе просмотра.',font=small,fill='#68546D')
sheet.convert('RGB').save(PREVIEW/'Longmaw_Icons_Review.png')

sheet=Image.new('RGBA',(1680,610),BG)
draw=ImageDraw.Draw(sheet)
draw.text((30,22),'СРАВНЕНИЕ С ТЕКУЩИМИ ИКОНКАМИ',font=label,fill=INK)
refs=[(Image.open(PROJECT/'art/ui/modal-refresh/DeerFarmer.png').convert('RGBA'),'Текущая: фермер'),
      (images['Farmer'],'Новая: Длиннорот-фермер'),
      (Image.open(PROJECT/'art/ui/monster-outfits/RingMawKnight.png').convert('RGBA'),'Текущая: рыцарь'),
      (images['Knight'],'Новая: Длиннорот-рыцарь')]
for i,(im,caption) in enumerate(refs):
    paste_icon(sheet,im,(i*420+20,78,380,440))
    draw.text((i*420+210,553),caption,font=small,fill=INK,anchor='mt')
sheet.convert('RGB').save(PREVIEW/'Longmaw_Icons_StyleComparison.png')

sheet=Image.new('RGBA',(1680,520),BG)
draw=ImageDraw.Draw(sheet)
draw.text((30,22),'ЧИТАЕМОСТЬ В МАЛОМ РАЗМЕРЕ',font=label,fill=INK)
for i,row in enumerate(assets):
    x=i*280
    draw.text((x+140,86),row['ru'],font=small,fill=INK,anchor='mt')
    for y,size in ((138,96),(310,64)):
        paste_icon(sheet,images[row['role']],(x+(280-size)//2,y,size,size))
        draw.text((x+140,y+size+16),str(size)+' px',font=small,fill='#68546D',anchor='mt')
sheet.convert('RGB').save(PREVIEW/'Longmaw_Icons_SmallSizes.png')
(ROOT/'validation.json').write_text(json.dumps({'passed':True,'candidates_unmodified':True,
    'original_alpha_preserved':True,'reference_hashes_unchanged':True,
    'integration_authorized':False,'icons':validation},ensure_ascii=False,indent=2)+'\n')
print('ICON_REVIEW_COMPLETE',len(validation),flush=True)
