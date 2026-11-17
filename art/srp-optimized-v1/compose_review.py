"""Compare original and optimized deliveries; previews do not alter assets."""
from pathlib import Path
import json
from PIL import Image,ImageDraw,ImageFont,ImageChops,ImageStat
ROOT=Path(__file__).resolve().parent
BG='#eee5f4';INK='#36233e'
def font(n,b=False):return ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial'+(' Bold' if b else '')+'.ttf',n)
def text(im,xy,s,n=24,anchor='la',fill=INK,b=False):ImageDraw.Draw(im).text(xy,s,font=font(n,b),fill=fill,anchor=anchor)
def place(im,p,box):
    a=Image.open(p).convert('RGBA');a.thumbnail(box[2:],Image.Resampling.LANCZOS)
    im.paste(a,(box[0]+(box[2]-a.width)//2,box[1]+(box[3]-a.height)//2),a)

renders=json.loads((ROOT/'render_manifest.json').read_text())['renders']
names=list(dict.fromkeys(r['id'] for r in renders));validation=[]
board=Image.new('RGB',(1600,2170),BG)
text(board,(30,40),'3D: исходник и компактный GLB',42,b=True)
text(board,(30,92),'Одинаковые камеры, свет и позы · геометрия и скелеты сохранены',24)
for j,s in enumerate(['Исходник','Компактный GLB','Исходник: поза','Компактный: поза']):text(board,(200+j*400,145),s,24,'mm')
for k,name in enumerate(names):
    y=185+k*490;text(board,(30,y),name,27,b=True)
    for j,(pose,profile) in enumerate([('rest','original'),('rest','optimized'),('posed','original'),('posed','optimized')]):
        p=ROOT/'previews'/profile/(name+'_'+pose+'.png');place(board,p,(j*400+10,y+35,380,440))
    for pose in ['rest','posed']:
        a=Image.open(ROOT/'previews/original'/(name+'_'+pose+'.png')).convert('RGB')
        b=Image.open(ROOT/'previews/optimized'/(name+'_'+pose+'.png')).convert('RGB')
        diff=ImageChops.difference(a,b);st=ImageStat.Stat(diff)
        mean=sum(st.mean)/3;maximum=max(x[1] for x in diff.getextrema())
        validation.append(dict(id=name,pose=pose,mean_rgb_error_255=mean,max_channel_error=maximum))
        assert mean<.1 and maximum<20,(name,pose,mean,maximum)
board.save(ROOT/'previews/Model_Comparison.png')
(ROOT/'visual_validation.json').write_text(json.dumps(dict(passed=True,render_pairs=validation),indent=2)+'\n')

icons=json.loads((ROOT/'icons_report.json').read_text())['icons'];labels=['Фермер','Шахтёр','Король','Рыцарь','Нефор','Убийца']
sheet=Image.new('RGB',(1800,1500),BG)
text(sheet,(30,38),'24 оптимизированные иконки • PNG 512',38,b=True)
for k in range(4):
    y=100+k*345;text(sheet,(30,y),icons[k*6]['character'],27,b=True)
    for j in range(6):
        r=icons[k*6+j];place(sheet,ROOT/r['variants']['ui512']['file'],(j*300+15,y+30,270,270))
        text(sheet,(j*300+150,y+320),labels[j],24,'mm')
sheet.save(ROOT/'previews/All_Icons_512.png')

comparison=Image.new('RGB',(1500,1430),BG)
text(comparison,(30,40),'Иконки: сравнение при показе в 128 px',35,b=True)
profiles=[('source','Исходник 1254'),('large1024','PNG 1024'),('ui512','PNG 512'),('small256','PNG 256')]
for j,(_,label) in enumerate(profiles):text(comparison,(180+j*375,105),label,26,'mm')
for k,ix in enumerate([2,6,16,21]):
    r=icons[ix];y=150+k*310;text(comparison,(30,y),r['id'],27,b=True)
    for j,(profile,_) in enumerate(profiles):
        path=r['source'] if profile=='source' else ROOT/r['variants'][profile]['file']
        x=j*375+30
        for off,bg in [(0,BG),(155,'#211b29')]:
            ImageDraw.Draw(comparison).rectangle((x+off,y+55,x+off+144,y+200),fill=bg)
            place(comparison,path,(x+off+8,y+63,128,128))
        size=r['source_bytes'] if profile=='source' else r['variants'][profile]['bytes']
        text(comparison,(x+150,y+232),f'{size/1000:.0f} КБ',25,'mm')
comparison.save(ROOT/'previews/Icon_Comparison.png')

# Inspect all 24 assets at both target UI sizes, against original at identical display size.
small=Image.new('RGB',(1800,1270),BG)
text(small,(25,35),'Все иконки: исходник / PNG 512 · 96 и 64 px',34,b=True)
for k in range(4):
    y=90+k*285;text(small,(25,y),icons[k*6]['character'],24,b=True)
    for j in range(6):
        r=icons[k*6+j];x=15+j*298;text(small,(x+140,y+40),labels[j],21,'mm')
        # Source on light, optimized on dark; both 96px and 64px at actual size.
        for col,path in enumerate([r['source'],ROOT/r['variants']['ui512']['file']]):
            xx=x+col*145
            ImageDraw.Draw(small).rectangle((xx,y+58,xx+140,y+265),fill=BG if col==0 else '#211b29')
            place(small,path,(xx+22,y+65,96,96));place(small,path,(xx+38,y+181,64,64))
small.save(ROOT/'previews/Small_Size_Check.png')
print('Review sheets and visual validation saved')
