from mesh import Asset, ASSETS, LAYOUTS, ROOT, write, gltf
from pathlib import Path
import math, json, random, struct, zlib

# Prefix, title, floor, centre stripe, wall, trim, light.
THEMES={
 'scp':('SC','SCP-тюрьма','798087','A9ACA9','464E54','69747A','EE4935'),
 'mall':('TC','Торговый центр','B4A79A','D5C3A6','D3C8BA','47716D','FFD498'),
 'pizza':('PZ','Пиццерия','BFA082','DFC7A3','974F40','9A3541','FFC166'),
 'zoo':('ZO','Зоопарк','BA986F','D9C09A','A58F76','675B43','EDC980'),
 'rift':('IR','Искажённая реальность','776D88','A69CB3','635970','93869D','9DE0CD'),
 'space':('DS','Тёмный космос','596677','68798C','485566','758296','69DDE3')}
def asset(b,n,title,group): return Asset(b,THEMES[b][0]+'_'+n,title,group)
def rect(p,x1,x2,y1,y2,z,tint):
 p.poly([(x1,y1,z),(x2,y1,z),(x2,y2,z),(x1,y2,z)],[(0,1,2,3)],tint)
def floor(b):
 _,_,ground,line,*_=THEMES[b]
 p=asset(b,'Floor64','Пол дороги 64 × 140','floor')
 # The full upper layer is a single coloured tessellation; no overlaid checker tiles.
 top=[(-32,-70,0),(32,-70,0),(32,70,0),(-32,70,0)]
 p.poly([(x,y,-1.2) for x,y,_ in top]+top,[(3,2,1,0),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],ground)
 stripe=16 if b=='pizza' else 14
 rect(p,-32,32,-stripe,stripe,0,line)
 if b in ('scp','zoo','rift'):
  rect(p,-32,32,-70,-stripe,0,ground)
  rect(p,-32,32,stripe,70,0,ground)
 else:
  # One quad per distinct colour tile. The centre and adjacent equal-colour
  # deck panels have no visible seam to preserve.
  dx=16 if b=='space' else 8
  rows=range(-9,9) if b=='pizza' else range(10)
  light_tile,dark_tile={'pizza':('D9C6A9','463E3F'),
                        'mall':(ground,'BEB0A0'),'space':(ground,'617082')}[b]
  for j in rows:
   y1,y2=(max(-70,j*8),min(70,(j+1)*8)) if b=='pizza' else (-70+j*14,-56+j*14)
   if -stripe<=y1 and y2<=stripe:continue
   for i,x in enumerate(range(-32,32,dx)):
    rect(p,x,x+dx,y1,y2,0,dark_tile if (i+j)%2 else light_tile)
 if b=='scp': rect(p,-32,32,-.5,.5,.018,'E4E5DE')
 if b=='space':
  for s in (-1,1):
   for x in (-27,5):p.box((x+6,s*13,.035),(12,.35,.07),'6AD1D8',light=True)
   for x in (-16,16):
    for k in range(5):rect(p,x+k*.65,x+k*.65+.32,s*52-2,s*52+2,.025,'39434D')
 return p

def frame(p,x,y,z,w,h,col,th=.55):
 for dx in [-w/2,w/2]:p.box((x+dx,y,z),(th,.55,h),col)
 for dz in [-h/2,h/2]:p.box((x,y,z+dz),(w+th,.55,th),col)

def badge(p,x,y,z,kind,scale=1):
 # Pawprint or stylized bird profile, readable on signage without textures.
 if kind=='paw':
  for dx,dz,r in [(0,-.5,1),(-1.2,.6,.45),(-.43,1.22,.49),(.45,1.25,.48),(1.25,.60,.43)]:
   p.pipe((x+dx*scale,y,z+dz*scale),(x+dx*scale,y-.13,z+dz*scale),r*scale,'413B32',n=8)
 else:
  coords=[(-2,.3),(-.3,.3),(.5,1.5),(1.3,1.1),(2,.6),(1.1,.45),(.8,-.6),(-.5,-1.2),(-1.8,-.4)]
  pts=[(x+dx*scale,y,z+dz*scale) for dx,dz in coords]
  # Fan around a point inside the silhouette; faces look toward the walkway.
  for i in range(len(pts)):p.poly([(x,y,z),pts[(i+1)%len(pts)],pts[i]],[(0,1,2)],'413B32')

def walls(b,variant):
 _,_,_,_,wall,trim,light=THEMES[b]
 titles={'scp':['Камера содержания','Бронированная гермодверь'],'mall':['Закрытая витрина','Магазин с роллетой'],'pizza':['Окно выдачи под козырьком','Фасад с вывеской-пиццей'],'zoo':['Узкий вольер за решёткой','Вольер с укрытием'],'rift':['Перекошенные двери','Смещённые окна'],'space':['Шлюз станции','Панель станции с иллюминаторами']}
 p=asset(b,'Wall'+('B' if variant else 'A'),titles[b][variant],'wall')
 p.box((0,-1.45,7),(64,2.9,14),wall)
 p.box((0,-1.7,14.25),(64,3.4,.5),trim)
 p.box((0,-1.8,.6),(64,3.6,1.2),trim)
 if b=='scp':
  for x in [-16,16]:
   p.box((x,-3,6.9),(24,.4,10),'30383D')
   if not variant:
    p.box((x,-3.3,7),(22,.2,6.8),'4C5C61')
    p.box((x+3,-4,5.4),(9,1.2,.65),'879496')
    for dx in (-11.4,11.4):p.box((x+dx,-4.6,6.9),(.8,3.4,8),'555F65')
    p.box((x,-4.6,10.95),(23.6,3.5,.55),'667178')
    p.box((x+6,-3.53,9),(3.4,.22,.35),'AEAB91')
    for j in range(-10,11,2):p.box((x+j,-6.15,7),(.55,.5,7),'353B3D')
    frame(p,x,-6.15,7,23,8,trim)
   else:
    for d in [-5.3,5.3]:p.box((x+d,-3.5,6.5),(10.15,.8,11),'596267')
    p.box((x,-4,10),(7,.4,1.6),'1F2B31')
    for d in [-11.6,11.6]:
     p.box((x+d,-3.65,6.9),(1.8,.7,11),'D7A04E')
     for k in [3,6,9]:p.box((x+d,-4.06,k),(1.7,.13,.7),'443E38',tilt=-18)
    p.box((x,-3.6,13),(4.2,.5,.7),light,light=True)
  for x in (-31,0,31):p.box((x,-3.3,7.4),(1,.7,12.7),trim)
 if b=='mall':
  for x in [-16,16]:
   p.box((x,-3.25,6.2),(29,.6,10.5),'36454A')
   if variant:
    p.box((x,-3.64,6.2),(27,.28,9.8),'969995')
    for j in range(2,12):p.box((x,-3.85,j),(27,.12,.21),'717775')
   else:
    for d in [-10,-3.3,3.4,10]:
     p.box((x+d,-3.73,6.3),(6,.3,9.3),'40585C' if d<0 else '53666A')
     p.box((x+d+.7,-3.92,7.8),(.45,.1,4),'788B8B',tilt=27)
   frame(p,x,-3.7,6.5,28,10.4,'C3BAB0')
   p.box((x,-3.85,12.7),(29,1.45,2.35),'92585D' if variant else trim)
  for x in [-30,0,30]:p.box((x,-4,10.5),(.65,.45,2.5),light,light=True)
 if b=='pizza':
  for row in range(3):
   for x in [-29,-22,23,29]:p.box((x+(row%2)*.6,-3.03,2+row*3),(3.8,.22,.68),'AC6650')
  for x in [-15,15]:
   p.box((x,-3.12,7),(21,.45,8),'422F30')
   p.box((x-4,-3.48,6),(7.5,.42,4.5),'635550')
   p.box((x-4,-3.73,6.3),(6,.12,2.3),'302C2A')
   p.box((x+5,-3.55,5.8),(6.5,.35,.55),'997757')
   p.box((x,-4.7,3),(23,4.5,.65),'996A4F')
   p.box((x,-5.3,11.7),(24,5.5,.85),trim)
   for j in range(8):p.box((x-10.5+3*j,-7.7,11),(2.85,.6,1.25),trim if j%2 else 'B44C45')
  if variant:
   p.pipe((0,-3.3,9),(0,-3.92,9),4.5,'BA7C44',n=18)
   p.pipe((0,-3.95,9),(0,-4.08,9),3.9,'E4B461',n=18)
   for dx,dz in [(-1.6,1),(1.4,1.5),(.4,-1.8)]:p.pipe((dx,-4.1,9+dz),(dx,-4.2,9+dz),.75,'AB4A3D',n=8)
  else:p.box((0,-3.55,6.4),(4,.9,10.5),'734C41')
 if b=='zoo':
  for x in [-15,15]:
   p.box((x,-3.1,6.5),(27,.5,9),'534E40' if variant else '655D4A')
   p.box((x,-4.9,1.4),(28,5,1.7),'8E8268')
   if variant:
    p.pipe((x-8,-4,2),(x+2,-4,6.8),.72,'84664B',r2=.33,n=6)
    p.pipe((x,-4,5.9),(x+2,-4.2,9),.43,'84664B',r2=.16,n=6)
    p.pipe((x+5,-4.7,2.2),(x+5,-4.7,4.3),2.1,'858369',r2=1.3,n=6)
   for j in range(-12,13,3 if not variant else 6):p.box((x+j,-7.15,7),(.46,.5,9.5),'494C43')
   frame(p,x,-7.1,7,27,10,trim,.75)
  p.box((0,-7,7),(6,1.1,7.4),'CAA97C');badge(p,0,-7.63,7,'bird' if variant else 'paw',1.25)
 if b=='rift':
  for i,x in enumerate([-23,-8,10,24]):
   h=8 if variant else 10;w=8 if variant else 6
   tilt=[13,-10,7,-6][i];z=6+(i%2)*2
   p.box((x,-3.15,z),(w,.65,h),'403B51',tilt=tilt)
   if not variant:p.box((x+1.55,-3.75,z-.8),(1.1,.6,.4),'B7A29A',tilt=tilt)
   for d in [-1,1]:
    p.box((x+d*(w/2+.15),-3.8,z),( .6,.55,h+.5),trim,tilt=tilt)
   p.box((x+math.sin(math.radians(tilt))*h/2,-3.82,z+h/2),(w+.65,.6,.65),trim,tilt=-tilt)
   if variant:
    p.box((x,-3.75,z),(w,.28,.4),trim,tilt=tilt)
    p.box((x,-3.78,z),(.4,.28,h),trim,tilt=tilt)
  for x in [-16,17]:
   for l,r in [((x,-3.45,3),(x+2,-3.45,5)),((x+2,-3.45,5),(x+.9,-3.45,6)),((x+.9,-3.45,6),(x+4,-3.45,8))]:p.pipe(l,r,.14,light,n=4,light=True)
 if b=='space':
  for x in [-16,16]:
   p.box((x,-3.2,7),(25,.8,10),'313E49')
   if variant:
    for d in [-8,0,8]:p.box((x+d,-3.8,7.1),(6.5,.55,4),'526D81')
    for j in range(4):p.box((x,-3.75,2.3+j*.52),(19,.25,.22),'667884')
   else:
    for d in [-4.8,4.8]:p.box((x+d,-3.8,6.2),(9.1,1.25,10),'697582')
    frame(p,x,-4.25,6.7,20,11.7,'8C969C',.9)
    p.box((x,-4.5,12.6),(13,.4,.45),'E9AD5C',light=True)
   p.box((x+12,-4,7.4),(.65,.5,3),light,light=True)
  for x in [-30,0,30]:p.box((x,-3.1,7),(1.8,1.1,14),'788592')
 return p

def bench(p,sofa=False):
 c='A43F4A' if sofa else 'A77C56'
 if sofa:
  p.box((0,0,1.45),(11,4,2.9),'75403E');p.box((0,-.2,3.1),(10.8,3.8,.85),c)
  p.box((0,1.6,4.7),(11,1,3.6),c)
  for x in (-5.2,5.2):p.box((x,-.35,3.55),(.7,3.6,1.1),'8E3542')
 else:
  for x in (-4,4):
   p.box((x,0,1.4),(.68,3.6,2.8),'494E49');p.box((x,1.5,3.7),(.58,.6,3.2),'494E49')
  for y in [-1,0,1]:p.box((0,y,2.8),(11,.83,.45),c)
  for z in [3.9,5]:p.box((0,1.55,z),(11,.44,.77),c)
def wheels(p):
 for x in [-2.8,2.8]:
  for y in [-2.2,2.2]:p.pipe((x,y-.24,1),(x,y+.24,1),1,'3E4241',n=10)
def trolley(p,b):
 wheels(p);p.box((0,0,1.9),(7.7,4.6,.66),'6E736A')
 for y in [-1.8,1.8]:p.pipe((3.6,y,2),(3.95,y,6),.19,'89918D')
 p.pipe((3.95,-1.8,6),(3.95,1.8,6),.22,'89918D')
 if b=='mall':
  p.box((-.8,0,3.55),(4.7,3.6,2.8),'C79C48')
  for x in [-1.8,0]:p.disc(x,0,4.8,.58,1.5,'A5C3BE')
 elif b=='zoo':
  p.box((0,0,3.4),(6.7,4,2.4),'75805D')
  for x in [-1.5,1.3]:p.pipe((x,0,4.5),(x+.25,0,6),1.35,'C9AD78',r2=.95,n=7)
 else:
  for i in range(4):p.box((-.8,0,2.5+i*.53),(4.5,4,.48),'CBAD80',roll=(-1)**i*5)
def prop(b,n,t,g='prop'):return asset(b,n,t,g)
def props(b):
 r=[]
 def make(n,t,g='prop'):
  p=prop(b,n,t,g);r.append(p);return p
 if b=='scp':
  p=make('Beacon','Красный аварийный маячок','mount')
  p.disc(0,0,0,1.45,.52,'424B4E');p.pipe((0,0,.5),(0,0,2),1,'E94434',r2=.85,n=10,light=True)
  p=make('Barrier','Бетонный барьер с полосами')
  p.box((0,0,.65),(11,4,1.3),'787B76');p.box((0,0,2.35),(10,2.7,2.7),'A2A49D')
  for x in [-3,0,3]:p.box((x,-1.4,2.3),(.95,.12,2.3),'C57F48',tilt=18)
  p=make('Camera','Камера наблюдения','mount')
  p.box((0,0,1.5),(1.2,.65,3),'70777A');p.box((0,-1.5,1.1),(.6,2.7,.6),'71797B')
  p.box((0,-3.3,1.8),(2.4,3.6,1.7),'BAC0BB');p.pipe((0,-5.12,1.75),(0,-5.43,1.75),.6,'263943',n=10)
 if b=='mall':
  bench(make('Bench','Скамейка галереи'))
  p=make('Directory','Двусторонняя схема этажей')
  p.box((0,0,.42),(6,3,.84),'565A58');p.box((0,0,5),(5.4,1,9.2),'474B4A')
  for y in [-.56,.56]:
   p.box((0,y,5.2),(4.65,.1,7.8),'D2C9B6')
   for x,z,w,c in [(-1,7.4,1.7,'527C77'),(1,6.6,1.5,'AE7779'),(-.85,4.6,1.9,'B49C67'),(.75,3.8,1.8,'718E91')]:p.box((x,y*1.15,z),(w,.055,1.4),c)
  trolley(make('CleanerCart','Тележка уборщика'),b)
  p=make('DryFountain','Сухой фонтан','arena_prop')
  p.disc(0,0,0,11,1,'98958F',n=32);p.band(0,0,.98,11,1.3,1.65,'C2B9A8',n=32)
  p.pipe((0,0,.9),(0,0,4.7),2.6,'A59D91',r2=1.4,n=16)
  p.pipe((0,0,4.7),(0,0,5.7),2.1,'BDB5A5',r2=5.1,n=20);p.band(0,0,5.7,5.1,.45,.5,'D2C9B9',n=20);p.disc(0,0,5.7,.9,1,'9C978B')
 if b=='pizza':
  bench(make('Booth','Красный диванчик'),True)
  p=make('Table','Круглый стол');p.disc(0,0,0,2.2,.44,'564D46');p.disc(0,0,.44,.48,3.6,'62574C');p.disc(0,0,4,4,.48,'CEAA7D')
  trolley(make('BoxCart','Тележка с коробками пиццы'),b)
  p=make('Stage','Сцена с занавесом','arena_prop')
  p.box((0,0,1.4),(27,11,2.8),'895F47')
  for x in [-12,12]:p.box((x,4,7),(1.2,1.5,10.5),'714840')
  for x in range(-11,12,2):p.box((x,4,7),(2.03,1.6,8.7),'9F3E46' if x%4==1 else '893741')
  p.box((0,4,12),(26,2,1.6),'723538')
  for x in [-9,0,9]:p.pipe((x,2.9,12),(x,2.58,12),.52,'FFD18C',n=8,light=True)
 if b=='zoo':
  for name,kind,title in [('PawSign','paw','Табличка с отпечатком лапы'),('BirdSign','bird','Табличка с птицей')]:
   p=make(name,title);p.box((0,0,3),(.75,.85,6),'746046');p.box((0,0,6.8),(6.5,1,4.2),'C9AA7D');badge(p,0,-.53,6.9,kind,.99)
  trolley(make('KeeperCart','Тележка смотрителя'),b)
  p=make('FeedBucket','Ведро для корма');p.pipe((0,0,0),(0,0,2.2),1.15,'768176',r2=1.5,n=12);p.disc(0,0,2.2,1.36,.1,'B59E74',n=12)
 if b=='rift':
  p=make('LooseDoor','Отдельный дверной проём')
  for x,h in [(-3,10),(3,9)]:p.box((x,0,h/2+.1),(.85,.95,h),'9D91AB',tilt=8)
  p.box((.6,0,9.45),(7.4,.98,.9),'A59AB3',tilt=8)
  p=make('FloatShards','Три зависших осколка','floating')
  for x,y,z,s in [(-5,1,10,2),(0,0,15,3.7),(6,-1,19,1.5)]:p.box((x,y,z),(s,s*.9,s*1.4),'8D809B' if x else '716780',roll=23+x,tilt=-28+x)
  p=make('Lamp','Наклонённый фонарь');p.box((0,0,.38),(3,3,.76),'504C60');p.pipe((0,0,.7),(2.6,0,11),.38,'5D5968',n=6)
  p.box((2.7,0,11.7),(2,1.6,2.5),'A8E0CF',tilt=13,light=True);p.box((2.95,0,13.1),(2.6,2.2,.45),'544F63',tilt=13)
 if b=='space':
  p=make('AirlockCargo','Повреждённый грузовой модуль');p.box((0,0,2.4),(7,5,4.8),'68737B')
  for x in [-2.6,2.6]:p.box((x,0,2.5),(.65,5.2,5),'414F5A')
  p.box((0,-2.56,2.8),(2,.14,1.1),'C5965A');p.box((0,0,5.4),(3.8,4,.35),'7B8992',tilt=-13)
  p=make('SolarDebris','Обломок солнечной панели')
  p.box((0,0,.55),(12,6.4,1.1),'8A949C',roll=8)
  for i in [-1,0,1]:
   for j in [-1,1]:p.box((i*3.75-j*.2,j*1.5+i*.49,1.15),(3.4,2.55,.15),'405B7F',roll=8)
  p=make('Dish','Антенна связи');p.disc(0,0,0,2.4,.6,'757F88');p.pipe((0,0,.6),(0,0,5),.63,'697582')
  p.pipe((0,0,4.4),(0,-1.5,6.7),1,'A0AAB0',r2=4.4,n=16);p.pipe((0,-1.6,6.7),(0,-2.6,8.4),.26,'56646E',r2=.5,n=8)
 return r


def arena(b):
    _, _, ground, line, wall, trim, light = THEMES[b]
    p = asset(b,'Arena','Боковая арена с открытым входом','arena')
    start, end = -math.asin(.8), math.pi+math.asin(.8)
    n = 56
    arc = [start+(end-start)*i/n for i in range(n+1)]
    outline = [(100*math.cos(a),100*math.sin(a)) for a in arc]
    for i, a in enumerate(outline):
        c = outline[(i+1)%len(outline)]
        p.poly([(0,0,0),(*a,0),(*c,0)], [(0,1,2)], ground)
        p.poly([(0,0,-1.2),(*c,-1.2),(*a,-1.2)], [(0,1,2)], ground)
        p.poly([(*a,-1.2),(*c,-1.2),(*c,0),(*a,0)], [(0,1,2,3)], trim)
    p.band(0,0,0,100,2.8,6,wall,n=n,start=start,end=end)
    p.band(0,0,6,100,3.15,.7,trim,n=n,start=start,end=end)
    p.band(0,0,.035,52,.65,.055,line)
    for side in (-1,1):
        p.box((side*62,-79.3,2.55),(4,1.4,7.5),wall)
    if b=='scp':
        for i in range(30):
            a = start+(end-start)*(i+.16)/30
            p.band(0,0,6.71,99.7,2.1,.12,'DCA34F',n=2,start=a,end=a+.055)
    if b=='pizza':
        for i in range(24):
            p.band(0,0,.025,74,3.7,.07,'4F4442' if i%2 else 'DCC8A7',
                   n=3,start=i*math.tau/24,end=(i+1)*math.tau/24)
    elif b=='space':
        for x, y in [(-23,-23),(23,23),(-23,23),(23,-23)]:
            p.box((x,y,.09),(7,.7,.16),light,light=True)
    elif b=='rift':
        for x,y,h in [(-65,47,8),(61,45,11),(-75,18,6)]:
            p.box((x,y,h),(3,3,6),trim,tilt=-25,roll=27)
    for i in range(1,10):
        a = start+(end-start)*i/10
        x,y = 98.4*math.cos(a),98.4*math.sin(a)
        p.disc(x,y,6.7,.75,3.2 if b=='zoo' else 1.3,trim,n=8)
        if b!='zoo':
            p.disc(x,y,8,.7,.85,light,n=8,light=True)
        elif i>1:
            prev = a-(end-start)/10
            # A chord would cut across the arena. Follow the curved fence in short spans.
            for j in range(4):
                aa = prev+(a-prev)*j/4
                bb = prev+(a-prev)*(j+1)/4
                p.pipe((98.4*math.cos(aa),98.4*math.sin(aa),9.15),
                       (98.4*math.cos(bb),98.4*math.sin(bb),9.15),.23,trim,n=5)
    return p


def layout(b):
    pref = THEMES[b][0]+'_'
    result = []
    def place(name,x,y,z=0,rot=0): result.append((pref+name,(x,y,z),rot))
    for i,x in enumerate(range(-224,225,64)):
        place('Floor64',x,0)
        for side in (-1,1):
            if side==1 and abs(x)==32: continue
            wall = 'WallB' if (i+(side==1))%3==0 else 'WallA'
            place(wall,x,side*70,rot=0 if side==1 else 180)
    place('Arena',0,150)
    road = {
        'scp':[('Barrier',-180,39,16),('Barrier',-57,-46,-11),('Barrier',87,40,18),('Barrier',194,-40,-8)],
        'mall':[('Bench',-189,44,3),('Directory',-111,-43,166),('Bench',-44,-50,179),
                ('CleanerCart',22,38,-19),('Bench',118,45,4),('Directory',189,-39,165),('DryFountain',-24,216,0)],
        'pizza':[('Booth',-170,49,0),('Table',-170,41,0),('Booth',-78,-46,180),('Table',-78,-38,0),
                 ('BoxCart',34,43,-10),('Booth',146,49,0),('Table',146,41,0),('Stage',0,225,0)],
        'zoo':[('PawSign',-168,42,0),('KeeperCart',-78,-40,22),('BirdSign',32,-50,180),
               ('FeedBucket',86,40,0),('BirdSign',158,45,0),('PawSign',216,-43,180)],
        'rift':[('LooseDoor',-163,41,11),('Lamp',-64,-45,160),('FloatShards',42,-42,14),
                ('Lamp',128,41,-6),('FloatShards',183,49,47)],
        'space':[('AirlockCargo',-178,-41,13),('SolarDebris',-92,40,-8),('Dish',-21,-47,165),
                 ('AirlockCargo',91,43,-18),('SolarDebris',177,-42,16),('Dish',38,215,16)]}
    for name,x,y,angle in road[b]:
        place(name,x,y+math.copysign(8,y) if abs(y)<65 else y,rot=angle)
    if b=='scp':
        for x in (-210,110,210):
            for side in (-1,1):
                place('Beacon',x,side*68.4,14.5)
        place('Camera',-151,67,9.5);place('Camera',120,-67,9.5,180)
    return result


def main():
    from textures import palette, sky
    for b in THEMES:
        floor(b);walls(b,0);walls(b,1);props(b);arena(b)
    data = {name:a.mesh_data() for name,a in ASSETS.items()}
    img,uv = palette(ASSETS)
    (ROOT/'textures').mkdir(exist_ok=True)
    (ROOT/'textures'/'RoadPalette.png').write_bytes(img)
    sky(ROOT/'sky')
    catalog = []
    for name, a in ASSETS.items():
        path = Path('models')/a.biome/(name+'.glb')
        write(ROOT/path,[(name,(0,0,0),0)],data,img,uv)
        positions = [v[0] for _,vs,_ in data[name] for v in vs]
        lo = [round(min(axis),3) for axis in zip(*positions)]
        hi = [round(max(axis),3) for axis in zip(*positions)]
        triangles = sum(len(ix)//3 for _,_,ix in data[name])
        catalog.append(dict(file=path.as_posix(),biome=a.biome,name=name,title=a.title,group=a.group,
                            triangles=triangles,boundsMin=lo,boundsMax=hi))
    def save_json(path,content):
        path.write_text(json.dumps(content,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    save_json(ROOT/'catalog.json',catalog)
    for b in THEMES:
        placements = layout(b)
        write(ROOT/'samples'/(b+'.glb'),placements,data,img,uv)
        LAYOUTS[b] = [dict(model=n,position=gltf(p),yawDegrees=r) for n,p,r in placements]
    save_json(ROOT/'layouts.json',LAYOUTS)
    print(len(catalog),'individual models',max(row['triangles'] for row in catalog),'max triangles')
if __name__=='__main__': main()
