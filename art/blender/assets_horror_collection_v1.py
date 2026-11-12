"""Three articulated horror creatures, with distinct silhouettes and state meshes."""
import math
import kit
from assets_deer import box,beam,poly
from assets_monster_prototypes import part,torso
from mathutils import Vector,Matrix
JOINTS={}
FORMS={}

def joint(a,name,pos):JOINTS.setdefault(a.name,{})[name]=list(kit.to_rbx(pos))
def mesh(a,name,pivot=None,attach=None,**kw):
    if pivot is not None:joint(a,name,pivot)
    return a.part(name,attach=attach or name,ao=.32,ao_dist=.28,**kw)

def fingers(p,wrist,side,kind):
    x,y,z=wrist
    if kind=='Dealer':
        p.sphere((x,y,z-.16),(.30,.18,.40),'AEBAB4',sub=2,smooth=False)
        for j in range(4):
            xx=x+(j-1.5)*.14;end=z-.73+abs(j-1.5)*.07
            beam(p,(xx,y-.04,z-.30),(xx,y-.15,end),.12,.14,'B9C2B9')
            box(p,(xx,y-.24,end+.06),(.09,.035,.13),'D5D3BD',bevel=.015)
        beam(p,(x-side*.22,y,z-.1),(x-side*.48,y-.19,z-.40),.16,.16,'AEBAB4')
    elif kind=='Smile':
        box(p,(x,y,z-.12),(.30,.22,.34),'252938',bevel=.05)
        for j in range(4):
            xx=x+(j-1.5)*.12
            pts=[(xx,y-.03,z-.20),(xx+side*.10,y-.16,z-.48),(xx+side*.08,y-.40,z-.67)]
            for aa,bb in zip(pts,pts[1:]):beam(p,aa,bb,.09,.10,'242734')
            p.loft([[(pts[-1][0]-.05,pts[-1][1],pts[-1][2]),(pts[-1][0]+.05,pts[-1][1],pts[-1][2]),(pts[-1][0],pts[-1][1]+.07,pts[-1][2])],
                    [(xx+side*.03,y-.54,z-.55)]*3],'D4D4BC',smooth=False)
    else:
        p.sphere((x,y,z-.14),(.17,.15,.30),'775542',sub=1,smooth=False)
        for j in range(3):
            xx=x+(j-1)*.15
            beam(p,(xx,y,z-.25),(xx+side*.13,y-.06,z-.65),.085,.10,'8F6851')
            beam(p,(xx+side*.13,y-.06,z-.65),(xx+side*.07,y-.24,z-.92),.055,.06,'BD9970')
        beam(p,(x-side*.12,y,z-.06),(x-side*.34,y-.19,z-.37),.10,.11,'775542')

def limbs(a,kind,aggressive):
    tall=kind=='SirenHead';dealer=kind=='Dealer'
    skin='775542' if tall else 'AEBAB4' if dealer else '252938'
    hipz=3.35 if tall else 2.45
    shoulderz=5.48 if tall else 4.15
    for side,name in [(-1,'LegR'),(1,'LegL')]:
        hip=(side*.32,.04,hipz);knee=(side*.51,-.17,hipz*.50);ankle=(side*.52,.07,.28)
        p=mesh(a,name,hip)
        beam(p,hip,knee,.22 if tall else .32,.27,skin if not dealer else '222B32')
        beam(p,knee,ankle,.14 if tall else .22,.19,skin if not dealer else '303C40')
        box(p,(side*.52,-.12,.13),(.35 if tall else .48,.76,.24),'443D36' if tall else '17212B',bevel=.04)
        if tall:
            for j in range(3):beam(p,(side*.52+(j-1)*.10,-.22,.12),(side*.52+(j-1)*.15,-.61,.09),.07,.08,'604B3B')
    for side,name in [(-1,'ArmR'),(1,'ArmL')]:
        shoulder=(side*(.69 if tall else .81),0,shoulderz)
        elbow=(side*(1.13 if tall else 1.18),-.14,3.40 if tall else 2.83)
        wrist=(side*(1.31 if tall else 1.42),-.25-(.25 if aggressive else 0),1.57 if tall else 1.68)
        p=mesh(a,name,shoulder)
        beam(p,shoulder,elbow,.18 if tall else .33,.23 if tall else .36,skin if not dealer else '303B40')
        beam(p,elbow,wrist,.12 if tall else .24,.19 if tall else .26,skin if not dealer else '39464A')
        if tall:
            for z in (4.73,4.05,3.01,2.43):box(p,(side*(.88 if z>3.4 else 1.22),-.14,z),(.21,.24,.06),'A78360',bevel=.015)
        fingers(p,wrist,side,kind)

def siren(state):
    a=kit.asset('SirenHead_'+state);agg=state=='Aggressive'
    b=mesh(a,'Body');torso(b,[(3.15,.08,.38,.24),(3.7,0,.30,.23),(4.48,.06,.56,.26),(5.35,.03,.67,.31),(5.62,0,.30,.22)],['644A3B','80614A','735140','967050'])
    for side in (-1,1):
        for i in range(6):beam(b,(side*.10,-.275,4.07+i*.19),(side*(.48+i*.025),-.21,4.12+i*.19),.06,.06,'AE8660')
    beam(b,(0,-.31,3.65),(0,-.33,5.35),.09,.08,'513B31')
    limbs(a,'SirenHead',agg)
    h=mesh(a,'Head',(0,0,5.60));g=mesh(a,'EyesGlow',attach='Head',material='Neon')
    beam(h,(0,.02,5.46),(0,.02,7.26),.23,.25,'664A3A')
    for i,(x,z,angle) in enumerate([(-.28,6.45,-12),(.23,7.26,14)]):
        h.lathe([(.18,-.5),(.22,-.18),(.49,.16),(.64,.42),(.66,.51),(.53,.53),(.44,.26),(.18,-.13),(.05,-.17)],
                lambda j:['614532','76563D','926747','AE7B50','CB9B65','4B332B','332925','1C2020'][j],
                c=(x,-.18,z),rot=(90,0,angle),seg=16,smooth=False,caps=True)
        h.cyl((x,-.47,z),.28,.28,.045,'172022',rot=(90,0,0),seg=16,smooth=False)
        g.sphere((x,-.51,z),(.075,.035,.075),'FF382F' if agg else 'C2A66D',sub=1)
        if agg:
            for j in range(7):
                xx=x+(j-3)*.115
                poly(h,[(xx-.043,z+.40),(xx+.043,z+.40),(xx,z+.18)],-.71,.06,'E5D5AE')
                poly(h,[(xx-.042,z-.36),(xx+.042,z-.36),(xx,z-.16)],-.71,.06,'E5D5AE')
    h.tube([(.14,.13,5.6,.035),(.38,.2,5.94,.035),(-.16,.23,6.35,.035),(.28,.18,6.86,.035)],'342A25',seg=5,sub=1)
    return a

def smile(state):
    a=kit.asset('Smile_'+state);agg=state=='Aggressive'
    b=mesh(a,'Body');torso(b,[(2.22,0,.32,.24),(2.78,.02,.38,.27),(3.6,.02,.58,.30),(4.22,0,.76,.33)],['202735','292F3D','242C39'])
    limbs(a,'Smile',agg)
    h=mesh(a,'Head',(0,0,4.28));g=mesh(a,'EyesGlow',attach='Head',material='Neon')
    h.sphere((0,-.12,5.16),(1.03,.69,1.03),'202837',sub=2,smooth=False)
    for side in (-1,1):
        h.sphere((side*.40,-.704,5.57),(.23,.12,.32),'10151F',sub=2)
        g.sphere((side*.40,-.812,5.62),(.10,.035,.15),'FF334D' if agg else 'ECE9CF',sub=2)
    outer=[(-.83,5.19),(-.61,4.70),(0,4.46),(.61,4.70),(.83,5.19),(.45,4.99),(0,4.88),(-.45,4.99)]
    if agg:outer=[(x,4.9+(z-4.9)*1.48) for x,z in outer]
    poly(h,outer,-.765,.08,'0D121D',bevel=.03)
    for j in range(11):
        x=(j-5)*.135;top=4.96+.33*(abs(x)/.75)**1.5
        length=(.39 if agg else .24)*(1-.32*abs(x))
        poly(h,[(x-.053,top),(x+.053,top),(x+.045,top-length),(x-.035,top-length-.02)],-.86,.07,'E8E4CD')
    return a

def dealer(state):
    a=kit.asset('BuckshotDealer_'+state);agg=state=='Aggressive'
    b=mesh(a,'Body');torso(b,[(2.15,.03,.42,.31),(2.83,.02,.55,.34),(3.63,.05,.70,.39),(4.25,.08,.84,.34)],['1C272E','2D3A3E','394747'])
    for side in (-1,1):
        poly(b,[(side*.12,4.18),(side*.78,4.21),(side*.37,3.50),(side*.18,3.75)],-.34,.07,'4E5B55')
    box(b,(0,-.37,3.83),(.31,.07,.62),'A7B5A8',bevel=.015)
    for z in (3.0,3.25,3.50):b.sphere((0,-.38,z),.035,'A4A68A',sub=1)
    limbs(a,'Dealer',agg)
    h=mesh(a,'Head',(0,0,4.27));g=mesh(a,'EyesGlow',attach='Head',material='Neon')
    h.sphere((0,-.10,5.25),(1.03,.73,1.10),'B5C0B0',sub=2,smooth=False)
    for side in (-1,1):
        h.sphere((side*.47,-.69,5.57),(.31,.13,.25),'31403B',sub=2)
        g.sphere((side*.48,-.805,5.56),(.06,.025,.055),'FF5945' if agg else 'C8D1B6',sub=1)
        beam(h,(side*.18,-.76,5.83),(side*.75,-.61,5.77),.15,.13,'6B7D6F')
        h.sphere((side*.69,-.61,5.03),(.26,.18,.30),'7A8D80',sub=1)
    poly(h,[(-.13,5.45),(-.22,5.18),(0,5.06),(.22,5.18),(.13,5.45)],-.85,.19,'8B9D8B')
    poly(h,[(-.85,5.02),(-.74,4.68),(-.38,4.42),(.31,4.39),(.75,4.66),(.87,5.03),(.40,4.88),(-.41,4.88)],-.76,.10,'19231F',bevel=.02)
    for j in range(12):
        x=(j-5.5)*.12;z=4.83+.17*abs(x)
        box(h,(x,-.89,z),(.102,.09,.25+(j%3)*.035),'D8D1AD',rot=(0,(j-5)*2,0),bevel=.012)
        if agg:box(h,(x,-.86,4.49+.20*abs(x)),(.09,.10,.20),'C9C6A0',bevel=.01)
    return a

def build():
    for name,fn in [('SirenHead',siren),('BuckshotDealer',dealer)]:
        FORMS[name]={}
        for state in ('Passive','Aggressive'):
            a=fn(state);FORMS[name][state]=a.name
            if state=='Aggressive':
                for p in a.parts:
                    if p.attach in ('ArmR','ArmL'):
                        pivot=Vector(kit.to_rbx(JOINTS[a.name][p.attach]));rot=Matrix.Rotation(math.radians(-12),3,'X')
                        for v in p.bm.verts:v.co=pivot+rot@(v.co-pivot)
                        p.bm.normal_update()
