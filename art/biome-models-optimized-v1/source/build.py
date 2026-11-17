"""Local review assets only. Run with Blender --background --python source/build.py.
Authoring: Z up, front -Y, 1 numerical unit = 1 intended Roblox stud.
Never opens, writes, or connects to a Roblox place.
"""
from pathlib import Path
import sys, json, math, random
import bpy
from mathutils import Vector

HERE = Path(__file__).resolve().parent
OUT = HERE.parent
sys.path.insert(0, str(HERE))
import kit

CAT = {}
EMISSION = {}

def asset(name, title, biomes, placement, note=""):
    a = kit.asset(name)
    CAT[name] = dict(title=title, biomes=biomes.split(), placement=placement, note=note,
                     pivot="floor_back_center" if placement == "wall" else "floor_center",
                     intended_studs_per_unit=1, front_axis="-Z", up_axis="+Y",
                     default_collision=False)
    return a

def part(a, name="Body"):
    return a.part(name, ao=.18, ao_dist=1.6, grad=.035)

def box(p, c, s, color, rot=(0,0,0), bevel=.10):
    return p.box(c, s, color, rot=rot, bevel=0 if min(s) <= .85 and p.owner.name not in ("BR_Fluorescent", "BM_EntranceOpen", "BM_Torch", "AC_Streetlight") else bevel, seg=1, smooth=False)

def beam(p, a, b, w, d, color):
    a,b=Vector(a),Vector(b)
    e=(b-a).to_track_quat('Z','Y').to_euler()
    return box(p, (a+b)/2, (w,d,(b-a).length),color,tuple(math.degrees(x) for x in e),.04)

def tube(p, pts, color, seg=6, sub=1):
    return p.tube(pts,color,seg=seg,sub=sub,smooth=False)

def stone(p,c,r,color="88817F",seed=0):
    p.sphere(c,r,color,rot=(seed*13%30,seed*23%50,seed*41%80),sub=1,smooth=False)

def glow(a, name, color):
    p=a.part(name,ao=0,grad=0,material="Neon",cast=False)
    EMISSION[a.name+"."+name]=color
    return p

def window(p,x,y,z,w=4,h=4,boarded=True, trim="A7977A"):
    box(p,(x,y,z),(w,.16,h),"343332",bevel=0)
    for dx in [-w/2,w/2]: box(p,(x+dx,y-.12,z),(.24,.28,h+.25),trim,bevel=.02)
    for dz in [-h/2,h/2]: box(p,(x,y-.12,z+dz),(w+.25,.28,.24),trim,bevel=.02)
    if boarded:
        beam(p,(x-w*.46,y-.32,z-h*.46),(x+w*.46,y-.32,z+h*.46),.42,.2,"967653")
        beam(p,(x+w*.46,y-.35,z-h*.46),(x-w*.46,y-.35,z+h*.46),.42,.2,"AD8C61")

def door(p,x,y,h=8,w=4.5,boarded=False):
    box(p,(x,y,h/2),(w,.22,h),"423C36",bevel=0)
    for dx in [-w/2,w/2]: box(p,(x+dx,y-.18,h/2),(.32,.35,h),"76685A",bevel=.03)
    box(p,(x,y-.18,h),(w+.4,.35,.38),"93806A",bevel=.03)
    if boarded:
        for z,tilt in [(3,-10),(5.8,14)]: box(p,(x,y-.4,z),(w+1,.35,.8),"9B7855",(0,tilt,0),.02)
    else:
        box(p,(x+w*.30,y-.24,3.7),(.18,.15,.6),"B4A07B",bevel=.03)

def backrooms():
    a=asset("BR_WallPanel","Стеновая панель", "backrooms", "wall", "Продольный модуль у стены; ширина 32 studs.")
    p=part(a);box(p,(0,-.8,7),(32,1.6,14),"C9B551")
    box(p,(0,-1.65,.4),(32,.15,.8),"9D8B48",bevel=0)
    box(p,(0,-.8,14),(32.2,1.6,.3),"D8C565",bevel=.02)
    a=asset("BR_DoorPartition","Перегородка с проходом", "backrooms", "road_edge", "Ставить поперёк от края; открытый проём 6 × 9 studs, не перекрывать центр дороги.")
    p=part(a)
    for x,w in [(-8.5,11),(8.5,11)]:box(p,(x,0,7),(w,1.6,14),"CEB95B")
    box(p,(0,0,11.5),(6,1.6,5),"CEB95B")
    for x,w in [(-8.5,11),(8.5,11)]:box(p,(x,-.84,.4),(w,.12,.8),"A18C46",bevel=0)
    a=asset("BR_CornerPartition","Угловая перегородка", "backrooms", "road_edge", "Короткая Г-образная секция, без потолка.")
    p=part(a);box(p,(0,0,7),(20,1.6,14),"C9B551");box(p,(-9.2,5.2,7),(1.6,9,14),"C9B551")
    a=asset("BR_Pillar","Квадратная колонна", "backrooms", "road")
    p=part(a);box(p,(0,0,8),(3.8,3.8,16),"D4BF60");box(p,(0,0,.2),(3.9,3.9,.4),"AD9B4E",bevel=.02)
    a=asset("BR_Fluorescent","Настенный светильник", "backrooms", "wall_mount", "Настенный модуль; светящаяся геометрия отдельно от корпуса. Источник света при интеграции.")
    p=part(a);box(p,(0,0,.65),(7.5,.6,1.3),"969782")
    g=glow(a,"Light","FFF5CC");box(g,(0,-.42,.65),(6.8,.3,.64),"FFF5CC",bevel=.06)
    CAT[a.name]["light_anchor"]=[0,0.65,-.8]

def mine_wall(name, title, mode):
    a=asset(name,title,"blood_mine","wall", "Неглубокая скальная полоса; затемнена только ниша входа.")
    p=part(a);rng=random.Random(40+mode)
    # Continuous rear slab and faceted banks around an actual shallow niche.
    box(p,(0,-.6,6.8),(54,1.2,13.6),"766D6E",bevel=.28)
    opening= mode!=2
    for i,x in enumerate(range(-24,25,6)):
        if opening and abs(x)<8:continue
        for row in range(2):
            z=3.4+row*6+rng.uniform(-.4,.4)
            stone(p,(x+rng.uniform(-.55,.55),-3.4+rng.uniform(-.25,.25),z),
                  (rng.uniform(4.05,4.8),rng.uniform(3.3,3.6),rng.uniform(3.7,4.3)),
                  rng.choice(["928A87","847C7A","9B928D"]),i+row*13)
    if opening:
        box(p,(0,-1.3,5.3),(15,.2,10.6),"35272A",bevel=0)
        for i,x in enumerate([-6,0,6]):stone(p,(x,-3.1,12.4),(4.5,3.2,3.2),"8D8480",i+5)
        for x in [-8,8]:box(p,(x,-5.7,5.8),(1.35,1.3,11.6),"9A6D48",(0,0,(-1 if x<0 else 1)*2))
        box(p,(0,-5.7,11.5),(18.8,1.5,1.35),"B0865B",(0,-2,0))
        for x in [-6.7,6.7]:beam(p,(x,-5.7,9),(x*1.15,-5.7,10.8),.8,.8,"8C6142")
        if mode==1:
            beam(p,(-7,-6.6,2),(7,-6.6,9.5),1.2,.5,"AF8357")
            beam(p,(-7,-6.7,9),(7,-6.7,2.8),1.1,.5,"956D4A")
            box(p,(0,-6.65,5.2),(15,.5,.85),"BA9160",(0,5,0))
        else:
            box(p,(0,-3.4,.08),(14.5,4.1,.16),"642D32",bevel=0)
            g=glow(a,"OreGlow","8E3339")
            tube(g,[(-5,-1.45,2,.1),(-3,-1.48,3.6,.1),(-.5,-1.47,3.2,.08),(1.6,-1.47,5,.06)],"A54144",seg=4)
            CAT[a.name]["light_anchor"]=[0,3,-3]
    # Sparse, low relief dark-red veins; no giant crystal growths.
    for x in [-20,18]:
        tube(p,[(x-3,-5.8,8,.12),(x-1,-6.4,9,.14),(x,-6.2,10.7,.13),(x+3,-5.8,11.4,.08)],"8C343B",seg=4)
    return a

def mine():
    mine_wall("BM_EntranceOpen","Открытый вход шахты",0)
    mine_wall("BM_EntranceBoarded","Заколоченный вход",1)
    mine_wall("BM_RockWall","Скальная полоса",2)
    a=asset("BM_OreCluster","Камни с кровавой рудой","blood_mine","road")
    p=part(a)
    for i,(c,r) in enumerate([((0,0,1.6),(3.2,2.5,2)),((3,1,1),(1.8,1.5,1.3)),((-2,-2,.8),(1.5,1.2,1))]):stone(p,c,r,"918982",i+2)
    tube(p,[(-1.7,-1.8,2.3,.12),(-.5,-2.1,2.8,.16),(1,-1.3,3.3,.08)],"8D3139",seg=4)
    a=asset("BM_Minecart","Ржавая вагонетка","blood_mine","road")
    p=part(a)
    box(p,(0,0,2.1),(7.6,5.5,.5),"553F35")
    for y in [-2.55,2.55]:box(p,(0,y,3.7),(8,.4,3.3),"995B40",(9*(1 if y<0 else -1),0,0))
    for x in [-3.7,3.7]:box(p,(x,0,3.7),(.45,5.5,3.3),"A66649",(0,9*(1 if x>0 else -1),0))
    for x in [-4.05,4.05]:box(p,(x,0,5.35),(.22,6,.3),"B78B68")
    for y in [-2.85,2.85]:box(p,(0,y,5.35),(8.3,.22,.3),"B78B68")
    for x in [-2.5,2.5]:
        beam(p,(x,-3.4,1.1),(x,3.4,1.1),.35,.35,"3E3D3B")
        for y in [-3.1,3.1]:
            p.cyl((x,y,1.1),1.1,1.1,.5,"57524D",rot=(90,0,0),seg=10,smooth=False)
            p.cyl((x,y+(.28 if y>0 else -.28),1.1),.35,.35,.10,"9E8265",rot=(90,0,0),seg=8,smooth=False)
    for i,c in enumerate([(-2,0,4.2),(1,1,4.2),(2,-1,4.1)]):stone(p,c,(2,1.7,1.6),"A29A90",i)
    a=asset("BM_RailBroken","Короткие рельсы","blood_mine","road")
    p=part(a)
    for y in [-5,-2.5,0,2.5,5]:box(p,(0,y,.25),(8,.85,.5),"785A44",(0,0,y),.03)
    for x in [-2.4,2.4]:box(p,(x,0,.65),(.48,13,.48),"6E6761",bevel=.02)
    a=asset("BM_TimberPile","Сломанные крепи","blood_mine","road")
    p=part(a)
    for c,s,rot,col in [((0,0,.5),(12,1,1),(0,0,12),"A37A53"),((1,0,1.2),(9,1,1),(0,4,-35),"B18B60"),((-3,1,.6),(4,1.2,1.2),(0,0,70),"8B6346")]:box(p,c,s,col,rot,.04)
    a=asset("BM_Torch","Факел шахты","blood_mine","road")
    p=part(a);box(p,(0,0,3.4),(.5,.5,6.8),"5B4334",bevel=.04)
    p.cyl((0,0,6.6),.5,.75,.9,"69605A",seg=7,smooth=False)
    g=glow(a,"Flame","FFB94F");g.sphere((0,0,7.6),(.65,.55,1.1),"FFAF42",sub=1,smooth=False)
    g.sphere((.05,-.3,7.45),(.28,.25,.65),"FFE1A0",sub=1,smooth=False)
    CAT[a.name]["light_anchor"]=[0,7.6,0]

def village_house(name,title,variant):
    a=asset(name,title,"village","wall","Вытянутый фасад, плоская задняя грань. Кровля и декор остаются в неглубокой полосе у стены.")
    p=part(a);w=60;depth=7.2;h=15.5
    box(p,(0,-depth/2,h/2),(w,depth,h),"A0927C" if variant else "AA9B84",bevel=.18)
    box(p,(0,-depth/2,.65),(w+.2,depth+.15,1.3),"81796C")
    # Shallow gabled cross-section, ridge runs along the full facade.
    p.prism([(-depth/2-.6,h),(-depth/2,h+.4),(0,h+4),(depth/2,h+.4),(depth/2+.6,h)],w+.8,"71615A",c=(0,-depth/2,0),rot=(0,0,90),bevel=.04,smooth=False)
    # Broad roof tiles, intentionally only a few rows and occasional missing tiles.
    rng=random.Random(120+variant)
    for side in [-1,1]:
        for row in range(3):
            y=-depth/2+side*(.6+row*1.25);z=h+3.6-row*1.1
            for i in range(15):
                if (i,row,side) in [(3,2,-1),(10,1,-1),(12,2,1)]:continue
                box(p,(-28+i*4,y,z),(3.9,1.65,.26),rng.choice(["7D6B62","8D776A","75635F","887267"]),(side*-42,0,0),0)
    for x in [-29,-15,0,15,29]:box(p,(x,-7.32,7.8),(.55,.3,15.5),"695340",bevel=.03)
    box(p,(0,-7.35,14.7),(60,.4,.5),"725B46",bevel=.03)
    for x in [-23,-9,9,23]:window(p,x,-7.35,9.1,5.8,5.2,True,"AD9574")
    door(p,0 if not variant else 15,-7.4,8.3,4.6,variant==1)
    if variant:
        box(p,(-20,-2.5,19.3),(2.3,2.2,5.6),"8F8175")
        box(p,(-20,-2.5,22.2),(2.7,2.6,.45),"756A61")
    return a

def dead_tree(p,offset=(0,0,0),scale=1):
    paths=[[(0,0,0,1.2),(.3,.1,4,1),(0,0,8,.75),(1,0,12,.48),(.8,.2,17,.08)],
           [(0,0,7,.65),(-2,-.3,10,.43),(-5,-.4,12,.15),(-6,-.2,14,.05)],
           [(-2,-.3,10,.36),(-2.3,.3,13,.25),(-3,1,15,.04)],
           [(1,0,11,.45),(4,0,13,.34),(5,1,16,.05)],
           [(4,0,13,.25),(7,0,13.6,.04)],
           [(.2,0,5,.7),(2,2,8,.4),(3,3,11,.05)]]
    for path in paths:tube(p,[(x*scale+offset[0],y*scale+offset[1],z*scale+offset[2],r*scale) for x,y,z,r in path],"71513B",seg=6)
    for ang in [0,2,4]:tube(p,[(math.cos(ang)*2.4*scale+offset[0],math.sin(ang)*2.4*scale+offset[1],.2*scale+offset[2],.12*scale),(offset[0],offset[1],1.5*scale+offset[2],.8*scale)],"664B38",seg=5)

def village():
    village_house("AV_HouseLongA","Длинный деревенский дом",0)
    village_house("AV_HouseLongB","Дом с заколоченной дверью",1)
    a=asset("AV_FenceBroken","Сломанный забор","village","road_edge")
    p=part(a)
    for x,z in [(-6,3.2),(0,2.7),(6,3.4)]:box(p,(x,0,z/2),(.6,.7,z),"806247",(0,8 if x==0 else 0,0),.04)
    for x,w,rz in [(-3,6,-5),(3,5.5,14)]:
        for z in [1.2,2.5]:box(p,(x,-.35,z),(w,.4,.45),"9F7C52",(0,rz,0),.03)
    a=asset("AV_Well","Старый колодец","village","road")
    p=part(a)
    for row in range(2):
        for i in range(10):
            angle=math.tau*(i+.5*(row%2))/10
            box(p,(math.cos(angle)*2.9,math.sin(angle)*2.9,.65+row*1.1),(1.85,1.1,1.1),"918D83" if i%2 else "A29C8E",(0,0,math.degrees(angle)+90),.11)
    p.cyl((0,0,.15),2.4,2.4,.2,"393933",seg=10,smooth=False)
    for x in [-3.6,3.6]:box(p,(x,0,4),(.6,.6,8),"8D6948")
    beam(p,(-4,0,7.4),(4,0,7.4),.65,.65,"A18057")
    p.cyl((0,0,6),.32,.32,7.8,"695844",rot=(0,90,0),seg=8,smooth=False)
    p.cyl((0,0,4.3),.08,.08,3.3,"B29A73",seg=5,smooth=False)
    a=asset("AV_Cart","Деревянная телега","village","road")
    p=part(a)
    for i in range(6):box(p,(-2.9+i*1.16,0,2.6),(1.08,8,.32),"977249",bevel=.03)
    for x in [-3.5,3.5]:
        for z in [3.3,4.2,5.1]:box(p,(x,0,z),(.35,7.8,.6),"A48257",bevel=.04)
        for y in [-3.4,3.4]:box(p,(x,y,3.8),(.5,.5,3),"715137",bevel=.03)
        box(p,(x,-7,2),( .45,8,.45),"8C693F",(7,0,0),.04)
        p.torus((x*1.2,1,2),1.8,.22,"4F4237",rot=(0,90,0),seg=12,rseg=4)
        for ang in range(0,180,45):
            r=math.radians(ang);beam(p,(x*1.2,1+math.cos(r)*1.8,2+math.sin(r)*1.8),(x*1.2,1-math.cos(r)*1.8,2-math.sin(r)*1.8),.18,.18,"B08B59")
    a=asset("AV_DeadTree","Сухое дерево","village","road");p=part(a);dead_tree(p)
    for i,c in enumerate([(-2,-1,.5),(2,1,.6)]):stone(p,c,(1,.9,.65),"918A7E",i)

def city_facade(name,title,variant=False,infected=False):
    biome="parasitown" if infected else "city"
    a=asset(name,title,biome,"wall","Фасад вдоль стены; заражение прилегает к зданию, щупалец на дороге нет." if infected else "Низкий длинный городской фасад с плоской задней гранью.")
    p=part(a);w=64;d=6.5;h=18.5 if infected else 20
    wall="54504E" if infected else ("96918B" if variant else "9D9993")
    box(p,(0,-d/2,h/2),(w,d,h),wall,bevel=.16)
    box(p,(0,-d/2,.55),(w+.25,d+.2,1.1),"67625E" if infected else "827F79")
    box(p,(0,-d/2,h),(w+.7,d+.5,.85),"464343" if infected else "B0ABA3")
    for x in [-31,-11,11,31]:box(p,(x,-d-.12,h/2),(1.1,.4,h),"645D56" if infected else "A6A198")
    for x in [-25,-17,17,25]:
        for z in ([5.4,12.8] if infected else [11.3]):window(p,x,-d-.3,z,4.8,4.8,infected,"9C805B" if infected else "AAA59C")
    if not infected:
        for x in [-7,7]:
            if variant and x==7:continue
            window(p,x,-d-.3,11.3,4.8,6,False,"A6A198")
    door(p,0,-d-.34,8,5,True)
    # Roof vent, low and blocky.
    box(p,(-18,-3,h+1.7),(5,3,3),"5D5956" if infected else "858480")
    for z in [h+.8,h+1.4,h+2,h+2.6]:box(p,(-18,-4.56,z),(4,.1,.12),"383A39" if infected else "555858",bevel=0)
    if variant:box(p,(24,-2,h+1.1),(3.4,2.7,2),"68645F" if infected else "898781")
    if infected:
        for idx,x in enumerate([-28,28] if not variant else [-27,9]):
            tube(p,[(x,-7.1,.5,.6),(x-.8,-7.2,6,.62),(x+.2,-7.4,12,.75),(x+1.8,-7.1,h+.7,.8),(x+2,-3,h+1,.65),(x+3,-.5,h+.8,.12)],"60262D",seg=6,sub=2)
            tube(p,[(x,-7.6,7,.3),(x-3,-7.5,9,.3),(x-5,-7.4,9.4,.06)],"782C34",seg=5)
        # Small skin plates near doorway: no bright pink, slime or large nodules.
        for x,z in [(-4,10),(4.2,7.5)]:
            p.prism([(-.8,-1),(.2,-1.6),(1.1,.1),(.5,1.6),(-.9,.8)],.35,"782D36",c=(x,-7.0,z),bevel=.02,smooth=False)
    return a

def car(name,title,color):
    a=asset(name,title,"city","road")
    p=part(a)
    box(p,(0,0,2.4),(6.4,12,2.3),color,bevel=.3)
    box(p,(0,0,4.4),(5.7,6.1,2.5),color,bevel=.25)
    # Simple inset glass panels, all opaque for robust import.
    box(p,(0,-3.1,4.6),(5.1,.12,1.8),"36434B",bevel=.06)
    box(p,(0,3.1,4.6),(5.1,.12,1.8),"3A4548",bevel=.06)
    for x in [-2.91,2.91]:
        for y in [-1.6,1.55]:box(p,(x,y,4.6),(.1,2.6,1.8),"3D474C",bevel=.06)
        for y in [-3.9,3.9]:
            p.cyl((x,y,1.25),1.25,1.25,.85,"333534",rot=(0,90,0),seg=10,smooth=False)
            p.cyl((x+( .46 if x>0 else -.46),y,1.25),.55,.55,.08,"727572",rot=(0,90,0),seg=8,smooth=False)
    for y in [-6.05,6.05]:box(p,(0,y,1.6),(5.8,.4,.6),"7D7971")
    for x in [-2.1,2.1]:
        box(p,(x,-6.06,2.8),(1.15,.16,.65),"BFB89A",bevel=.03)
        box(p,(x,6.06,2.8),(1.1,.16,.65),"793F35",bevel=.03)
    box(p,(1.8,-4.6,3.58),(1.8,1.7,.03),"6D4E3D",rot=(0,0,12),bevel=0)
    return a

def city():
    city_facade("AC_FacadeLongA","Длинный городской фасад")
    city_facade("AC_FacadeLongB","Фасад с глухой секцией",True)
    car("AC_CarBlue","Брошенная синяя машина","647E8A")
    car("AC_CarRust","Брошенная ржавая машина","97685A")
    a=asset("AC_Streetlight","Наклонённый фонарь","city","road")
    p=part(a);beam(p,(0,0,0),(-2,0,17),.48,.48,"6F726E");beam(p,(-2,0,17),(-5,0,18),.4,.4,"6F726E")
    box(p,(-5,0,17.8),(3.1,1.3,.65),"62665F")
    g=glow(a,"Light","E9D18B");box(g,(-5,-.1,17.43),(2.6,1,.12),"E9D18B",bevel=.02)
    CAT[a.name]["light_anchor"]=[5,17,-.1]
    a=asset("AC_PlanterTree","Сухое дерево в клумбе","city","road")
    p=part(a)
    box(p,(0,0,.45),(7,7,.8),"6C6558")
    for x in [-3.6,3.6]:box(p,(x,0,.65),(.8,8,.9),"A39E92")
    for y in [-3.6,3.6]:box(p,(0,y,.65),(6.5,.8,.9),"A39E92")
    dead_tree(p,(0,0,.7),.9)

def patch(p,scale=1):
    rng=random.Random(72)
    poly=[(-1.6,-1),(-2.2,.3),(-1.8,1.4),(-.3,1.9),(.8,1.5),(2.2,1.2),(1.7,-.1),(1.9,-1),(.4,-1.7),(-.7,-1.3)]
    p.prism([(x*scale,z*scale) for x,z in poly],.08*scale,"60262D",c=(0,0,.10*scale),rot=(90,0,0),bevel=0,smooth=False)
    # Uneven flat roots, not a regular starburst and not upright spikes.
    for ang in [-.3,.7,1.8,2.3,3.9,4.6,5.6]:
        length=rng.uniform(3.4,5.8);bend=rng.uniform(-.55,.55)
        path=[(0,0,.65),(math.cos(ang)*1.7,math.sin(ang)*1.7,.5),
              (math.cos(ang+bend)*length*.68,math.sin(ang+bend)*length*.68,.25),
              (math.cos(ang+.2)*length,math.sin(ang+.2)*length,.025)]
        left=[];right=[]
        for i,(x,y,w) in enumerate(path):
            before=path[max(i-1,0)];after=path[min(i+1,len(path)-1)]
            dx,dy=after[0]-before[0],after[1]-before[1];ln=math.hypot(dx,dy)
            left.append(((x-dy/ln*w)*scale,(y+dx/ln*w)*scale))
            right.append(((x+dy/ln*w)*scale,(y-dx/ln*w)*scale))
        p.prism(left+right[::-1],.07*scale,"6E2932",c=(0,0,.085*scale),rot=(90,0,0),bevel=0,smooth=False)

def parasitown():
    city_facade("PT_InfectedFacadeA","Заражённый фасад A",False,True)
    city_facade("PT_InfectedFacadeB","Заражённый фасад B",True,True)
    a=asset("PT_InfectionPatch","Плоский очаг заражения","parasitown","wall_base","Только у подножия фасада или на арене, не заполнять проезжую часть.");p=part(a);patch(p)
    a=asset("PT_WallGrowth","Пристенный нарост","parasitown","wall_mount","Прилегает к плоскости стены; не использовать как щупальце на дороге.")
    p=part(a);tube(p,[(0,0,0,.4),(-.5,0,5,.7),(1,0,10,.6),(2,0,16,.1)],"65262F",seg=6,sub=2)
    tube(p,[(-.2,-.3,6,.4),(-3,-.2,8,.3),(-5,-.1,8.2,.04)],"7C3038",seg=5)
    for variant in [0,1]:
        a=asset("PT_ArenaTentacle"+("Tall" if not variant else "Hook"),"Щупальце арены — "+("высокое" if not variant else "изогнутое"),"parasitown","arena_only","ТОЛЬКО АРЕНА. На дороге не размещать.")
        p=part(a);patch(p,1.4)
        pts=([(0,0,.7,2),(1,0,6,1.8),(2,0,12,1.45),(4,0,18,1.1),(3,0,22,.7),(-.5,0,24,.35),(-3,0,23,.06)] if not variant else
             [(0,0,.8,2),(-2,0,5,1.6),(-4,0,10,1.2),(-5,0,15,1),(-2,0,18,.8),(2,0,17,.5),(3,0,14,.05)])
        tube(p,pts,"482D30",seg=7,sub=2)
        tube(p,[(x,y-r*.82,z,r*.34) for x,y,z,r in pts],"7B2D36",seg=5,sub=2)
        CAT[a.name]["road_allowed"]=False

def shared():
    a=asset("SH_Crate","Деревянный ящик","village city","road");p=part(a)
    box(p,(0,0,2.1),(4.2,4.2,4.2),"826143")
    for x in [-1.9,1.9]:
        for y in [-2.16,2.16]:box(p,(x,y,2.1),(.32,.24,4.2),"B18B5A",bevel=.02)
    for y in [-2.16,2.16]:
        for z in [.2,4]:box(p,(0,y,z),(4.2,.24,.35),"B18B5A",bevel=.02)
        beam(p,(-1.8,y,0.4),(1.8,y,3.8),.35,.22,"B18B5A")
        beam(p,(1.8,y,.4),(-1.8,y,3.8),.35,.22,"A47D51")
    for x in [-2.16,2.16]:
        for z in [.2,4]:box(p,(x,0,z),(.24,4.2,.35),"B18B5A",bevel=.02)
        beam(p,(x,-1.8,.4),(x,1.8,3.8),.28,.28,"A88054")
    a=asset("SH_Barrel","Деревянная бочка","village city","road");p=part(a)
    p.lathe([(1.5,0),(1.8,.5),(2,2.2),(1.8,4.3),(1.5,4.7)],"876649",seg=12,smooth=False,caps=True)
    for z,r in [(.6,1.85),(3.9,1.88)]:p.lathe([(r,z),(r,z+.35)],"5C5B51",seg=12,smooth=False,caps=True)
    p.cyl((0,0,4.73),1.5,1.5,.12,"A08056",seg=12,smooth=False)
    a=asset("SH_Rubble","Небольшой каменный завал","blood_mine city","road");p=part(a)
    for i,(x,y,z,s) in enumerate([(-2,0,1.1,1.8),(0,1,1.7,2.4),(2.7,0,.9,1.5),(0,-2,.65,1.1)]):stone(p,(x,y,z),(s,s*.8,s*.8),["9A958A","AEA79B","89867E"][i%3],i)

def normalize():
    for name,a in kit.ASSETS.items():
        allverts=[v for p in a.parts for v in p.bm.verts]
        zmin=min(v.co.z for v in allverts)
        ymax=max(v.co.y for v in allverts) if CAT[name]["placement"]=="wall" else 0
        for v in allverts:v.co.z-=zmin;v.co.y-=ymax

bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
backrooms();mine();village();city();parasitown();shared();normalize()
manifest,baked,total=kit.export_all(str(OUT/'geometry'))
for name,parts in manifest.items():
    CAT[name]["parts"]=parts
    CAT[name]["triangles"]=sum(p["tris"] for p in parts)
    lo=[min(p['offset'][i]-p['size'][i]/2 for p in parts) for i in range(3)]
    hi=[max(p['offset'][i]+p['size'][i]/2 for p in parts) for i in range(3)]
    CAT[name]["bounds"]={"min":[round(v,3) for v in lo],"max":[round(v,3) for v in hi],"size":[round(hi[i]-lo[i],3) for i in range(3)]}
    CAT[name]["file"]="models/"+name+".glb"
    for p in parts:
        if p['mesh'] in EMISSION:p['emission_srgb']=EMISSION[p['mesh']]
(OUT/'catalog.json').write_text(json.dumps(dict(version=1,status="LOCAL_REVIEW_NOT_APPROVED_FOR_INTEGRATION",reference="road-reskin-screenshot-concepts-v5",assets=CAT),ensure_ascii=False,indent=2))
print(json.dumps(dict(assets=len(CAT),parts=sum(len(a.parts) for a in kit.ASSETS.values()),triangles=total)))
