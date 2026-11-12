"""Original cartoon zombie cultists for the abandoned road. Feet Z=0, facing -Y.
Separate animated limbs, face, hunter rifle, parasite and tendrils. No gore.
"""
import math
from mathutils import Vector,Matrix
import kit

SKIN='8DAF59';SKINLIGHT='B5CE79';SKINDARK='4D693D'
INK='201E29';CLOTH='46304F';EDGE='754F75';BONE='E1D4AD';RUST='9C6945'
JOINTS={}

def box(p,c,s,col,**kw):
    return p.box(c,s,col,bevel=kw.pop('bevel',.03),seg=1,smooth=False,**kw)
def poly(p,pts,y,depth,col,**kw):
    return p.prism(pts,depth,col,c=(0,y,0),bevel=kw.pop('bevel',.015),smooth=False,**kw)
def beam(p,a,b,w,d,col):
    a,b=Vector(a),Vector(b);rot=(b-a).to_track_quat('Z','Y').to_euler()
    box(p,(a+b)/2,(w,d,(b-a).length),col,rot=tuple(math.degrees(x) for x in rot))
def ring(p,c,r,t,col,rot=(90,0,0)):
    p.torus(c,r,t,col,rot=rot,seg=12,rseg=5)

def skull(p,c,size=.24):
    x,y,z=c
    box(p,(x,y,z),(size*1.5,size*.42,size*1.15),BONE,bevel=.04)
    box(p,(x,y-.035,z-size*.61),(size*.87,size*.32,size*.40),BONE,bevel=.01)
    for s in (-1,1):box(p,(x+s*size*.33,y-size*.24,z+.015),(size*.34,.025,size*.38),INK,bevel=.015)
    for dx in (-.19,.19):box(p,(x+size*dx,y-size*.24,z-size*.62),(.017,.025,size*.25),INK,bevel=0)

def hood(p,kind):
    color='394639' if kind=='Hunter' else CLOTH
    trim='768466' if kind=='Hunter' else EDGE
    # Hood shell has a real face opening and a ragged cowl around the neck.
    front=[(-.94,3.76),(-1.02,4.48),(-.81,5.23),(-.26,5.65),(.28,5.55),(.86,5.19),(1.0,4.45),(.88,3.76)]
    inner=[(-.67,3.94),(-.76,4.47),(-.61,5.08),(-.22,5.34),(.23,5.28),(.63,5.03),(.74,4.45),(.65,3.94)]
    back=[(x*.89,z+.02) for x,z in front]
    for i in range(len(front)-1):poly(p,[front[i],front[i+1],inner[i+1],inner[i]],-.60,.18,trim)
    p.loft([[(x,-.55,z) for x,z in front],[(x,.55,z) for x,z in back]],color,wrap=False,cap_start=False,cap_end=False,smooth=False)
    poly(p,back,.55,.13,color,bevel=.03)
    for i in range(4):
        box(p,(-.90,-.70,4.12+i*.19),(.13,.025,.035),BONE,rot=(0,-18,0),bevel=0)
    if kind=='Hunter':
        box(p,(0,-.65,5.27),(.58,.09,.16),'263328')
        poly(p,[(-.17,5.27),(0,5.39),(.17,5.27),(0,5.16)],-.715,.025,'B1A375')

def head(a,kind):
    p=a.part('Head',attach='Head',ao=.4,ao_dist=.5)
    # Green cheeks, broken teeth and mismatched eyes read as zombies beneath the hood.
    box(p,(0,-.05,4.52),(1.36,.97,1.25),SKIN,bevel=.17)
    box(p,(.10,-.43,4.04),(.99,.45,.39),SKINLIGHT,rot=(0,-7,0),bevel=.06)
    for s in (-1,1):
        box(p,(s*.66,-.05,4.41),(.27,.30,.51),SKINDARK,rot=(0,s*18,0),bevel=.08)
        p.sphere((s*.34,-.57,4.68),(.31,.12,.32),SKINDARK,sub=2,smooth=False)
    p.sphere((-.34,-.68,4.69),(.26,.18,.29),'ECDEAB',sub=3)
    p.sphere((-.29,-.84,4.66),(.12,.045,.15),INK,sub=2)
    p.sphere((.35,-.69,4.65),(.22,.15,.21),'D8E3A7',sub=2)
    box(p,(.36,-.824,4.65),(.075,.035,.14),INK,rot=(0,17,0),bevel=.01)
    box(p,(-.02,-.67,4.40),(.23,.27,.25),SKINLIGHT,rot=(0,-8,0),bevel=.045)
    poly(p,[(-.44,4.29),(.39,4.22),(.48,3.96),(.05,3.90),(-.40,4.01)],-.70,.06,INK)
    for x,z,height in [(-.30,4.24,.15),(-.09,4.22,.19),(.27,4.19,.11)]:
        box(p,(x,-.75,z-height/2),(.13,.06,height),BONE,rot=(0,-8,0),bevel=.008)
    box(p,(.24,-.76,3.99),(.14,.07,.12),BONE,rot=(0,12,0),bevel=.008)
    # A sewn cheek and a chipped ear; stylized marks, without open wounds.
    beam(p,(-.56,-.55,4.42),(-.62,-.51,4.16),.035,.035,SKINDARK)
    for z in (4.21,4.31,4.40):box(p,(-.60,-.57,z),(.14,.025,.027),BONE,rot=(0,-15,0),bevel=0)
    if kind!='Parasite':hood(p,kind)
    else:
        # Hood torn away where the parasite crests over the shoulder.
        poly(p,[(-.93,3.82),(-1.01,4.58),(-.80,5.22),(-.27,5.59),(.08,5.33),(-.35,5.13),(-.66,4.58),(-.63,3.94)],-.50,.24,EDGE)
        poly(p,[(-.90,3.86),(-.90,5.12),(-.25,5.54),(.56,5.16),(.81,4.35),(.63,3.88)],.52,.12,CLOTH)
        for i in range(3):
            box(p,(.33+i*.12,-.05,5.12-i*.04),(.11,.24,.10),SKINLIGHT,rot=(0,20,0),bevel=.035)

def torso(a,kind):
    b=a.part('Body',attach='Body')
    col='394639' if kind=='Hunter' else CLOTH
    box(b,(0,.08,2.97),(1.38,.83,1.53),col,taper=1.1,bevel=.08)
    box(b,(0,-.12,3.84),(.48,.52,.44),SKIN,rot=(12,0,0))
    # A flared, split lower robe leaves both legs free to animate.
    for s in (-1,1):
        poly(b,[(s*.05,2.54),(s*.65,2.54),(s*.97,1.61),(s*.65,1.78),(s*.53,1.40),(s*.30,1.64),(s*.10,1.41)],-.13,.84,col,bevel=.025)
        poly(b,[(s*.13,3.77),(s*.77,3.85),(s*1.01,3.51),(s*.69,3.27),(s*.39,3.46)],-.43,.20,'596348' if kind=='Hunter' else '694064')
        beam(b,(s*.63,-.55,3.46),(s*.46,-.52,2.59),.045,.03,'8D9872' if kind=='Hunter' else '926C87')
    box(b,(0,.54,3.04),(1.22,.13,1.48),col,bevel=.035)
    box(b,(0,.04,2.55),(1.45,.94,.18),'5F493B')
    box(b,(-.04,-.50,2.55),(.34,.11,.27),'B39864')
    box(b,(-.04,-.565,2.55),(.19,.025,.14),INK,bevel=.006)
    for i in range(4):
        z=2.03+i*.18;box(b,(-.58,-.58,z),(.13,.025,.035),BONE,rot=(0,20,0),bevel=0)
    if kind=='Normal':
        b.tube([(-.32,-.51,3.78,.035),(-.34,-.62,3.39,.035),(0,-.65,3.12,.035),(.33,-.62,3.39,.035),(.31,-.51,3.78,.035)],'B39A6A',seg=5,sub=1)
        skull(b,(0,-.70,3.05),.30)
        box(b,(.59,-.50,2.30),(.32,.24,.40),'795239',rot=(0,-12,0))
        box(b,(.59,-.64,2.45),(.35,.05,.15),'A57749',rot=(0,-12,0))
        # Ritual marks remain readable on the plain cultist's back.
        poly(b,[(-.29,3.46),(.29,3.46),(0,2.94)],.62,.025,'94738D')
        skull(b,(0,.66,3.24),.14)
    elif kind=='Hunter':
        beam(b,(-.64,-.57,3.72),(.54,-.58,2.56),.19,.10,'674831')
        for i in range(5):
            x=-.49+i*.20;z=3.56-i*.19
            box(b,(x,-.66,z),(.12,.10,.23),'AA8647',rot=(0,42,0))
            box(b,(x-.06,-.68,z+.08),(.12,.10,.08),'D9C4A0',rot=(0,42,0))
        for s in (-1,1):box(b,(s*.59,-.51,2.37),(.36,.25,.35),'6D7758',rot=(0,s*7,0))
        # Small hunting pack with flap, straps, and bedroll.
        box(b,(0,.74,3.00),(.98,.44,1.14),'5B684A',bevel=.08)
        box(b,(0,1.00,3.34),(1.01,.10,.45),'85916B',bevel=.035)
        for s in (-1,1):box(b,(s*.31,1.07,2.99),(.11,.055,.69),'453D32')
        b.cyl((0,.81,3.69),.22,.22,1.10,'706754',rot=(0,90,0),seg=10,smooth=False)
        for x in (-.35,.35):box(b,(x,.58,3.70),(.10,.10,.37),'43342B')
    else:
        poly(b,[(.23,3.70),(.74,3.83),(.89,3.27),(.59,2.87),(.23,3.07)],-.51,.09,SKINDARK)
        for i in range(3):
            beam(b,(.22+i*.13,-.60,3.12),(.46+i*.12,-.59,3.38),.075,.07,'A8BC6B')

def legs(a,kind):
    for s,name in [(-1,'LegR'),(1,'LegL')]:
        p=a.part(name,attach=name)
        hip=(s*.40,.04,2.40);knee=(s*.53,.24,1.28);ankle=(s*.62,-.05,.38)
        beam(p,hip,knee,.47,.49,'30302C' if kind=='Hunter' else '352934')
        beam(p,knee,ankle,.31,.33,SKINDARK)
        for i in range(3):
            box(p,(s*.59,.02,.65+i*.14),(.35,.38,.10),'7C8060',rot=(0,-s*6,0))
        box(p,(s*.64,-.20,.20),(.52,.88,.38),'302D30',bevel=.06)
        box(p,(s*.64,-.22,.055),(.55,.91,.10),'514846',bevel=.02)
        if kind!='Hunter' and s<0:
            box(p,(s*.64,-.65,.22),(.35,.10,.16),SKIN)
            for x in (-.10,.04,.15):box(p,(s*.64+x,-.72,.20),(.10,.12,.12),SKINLIGHT,bevel=.025)
        JOINTS.setdefault(a.name,{})[name]=list(kit.to_rbx(hip))

GUN_ORIGIN=Vector((0,-.94,3.10));GUN_ROT=Matrix.Rotation(math.radians(35),4,'Z')
def gunpoint(p):return GUN_ORIGIN+GUN_ROT.to_3x3()@Vector(p)

def hands(p,at,s,mutant=False):
    at=Vector(at);scale=1.65 if mutant else 1
    box(p,at,(.38*scale,.32*scale,.39*scale),SKINDARK if mutant else SKIN,rot=(0,-s*15,0))
    for i,dx in enumerate((-.13,0,.13)):
        p.tube([tuple(at+Vector((dx*scale,-.06,-.14*scale)))+(.075*scale,),
                tuple(at+Vector((dx*scale*1.6,-.17,-.38*scale)))+(.06*scale,),
                tuple(at+Vector((dx*scale*1.7,-.31,-.46*scale)))+(.013,)],SKINLIGHT,seg=5,sub=2,smooth=False)
    p.tube([tuple(at+Vector((-s*.18*scale,0,0)))+(.09*scale,),
            tuple(at+Vector((-s*.30*scale,-.20,-.16*scale)))+(.055*scale,),
            tuple(at+Vector((-s*.19*scale,-.32,-.26*scale)))+(.01,)],SKIN,seg=5,sub=2,smooth=False)

def arms(a,kind):
    for s,name in [(-1,'ArmR'),(1,'ArmL')]:
        p=a.part(name,attach=name);shoulder=(s*.81,.02,3.62)
        if kind=='Hunter':
            elbow=(s*1.03,-.62,2.94)
            palm=gunpoint((0,.10,-.23) if s<0 else (0,-.80,-.11))
        else:
            elbow=(s*1.32,-.20,2.91);palm=Vector((s*1.68,-.54,2.16))
        mutated=kind=='Parasite' and s>0
        if mutated:elbow=(1.58,-.06,3.03);palm=Vector((2.02,-.40,2.05))
        cloth='4F5C43' if kind=='Hunter' else EDGE
        beam(p,shoulder,elbow,.48 if not mutated else .71,.51 if not mutated else .72,cloth if not mutated else SKINDARK)
        beam(p,elbow,palm,.27 if not mutated else .52,.29 if not mutated else .53,SKIN)
        box(p,shoulder,(.55,.59,.49),cloth,rot=(0,s*25,0))
        for i in range(3):
            point=Vector(elbow).lerp(palm,.2+i*.15)
            box(p,point,(.34,.36,.105),'9A9B76',rot=(0,-s*23,0))
        if kind=='Hunter':
            box(p,palm,(.34,.35,.35),'5C6747',bevel=.055)
            # Visible curled fingers under the forestock and around the pistol grip.
            for i in range(3):
                off=Vector((.03,-.09+i*.085,-.13)) if s>0 else Vector((-.03,-.13,.07-i*.08))
                box(p,palm+off,(.27,.07,.11),SKIN,rot=(0,0,35),bevel=.025)
        else:hands(p,palm,s,mutated)
        if mutated:
            for i in range(3):
                point=Vector(elbow).lerp(palm,.1+i*.22)+Vector((.23,.14,.08))
                p.cyl(point,.16,.005,.48,BONE,rot=(0,42,0),seg=5,smooth=False)
        JOINTS[a.name][name]=list(kit.to_rbx(shoulder))

def rifle(a):
    p=a.part('Rifle',attach='ArmR')
    box(p,(0,-.08,0),(.29,.81,.30),'414550')
    box(p,(0,.61,.015),(.25,.65,.27),RUST,bevel=.04)
    box(p,(0,.95,-.05),(.28,.13,.43),'543B2D')
    box(p,(0,-.65,0),(.32,.48,.28),'74644A')
    box(p,(0,.10,-.26),(.20,.22,.40),'352D2B',rot=(-12,0,0))
    box(p,(0,-.25,-.31),(.18,.28,.46),'59606B',rot=(12,0,0))
    p.cyl((0,-1.13,.025),.065,.065,.59,'333640',rot=(90,0,0),seg=10,smooth=False)
    p.cyl((0,-1.46,.025),.10,.10,.12,'565D67',rot=(90,0,0),seg=10,smooth=False)
    p.cyl((0,-1.528,.025),.055,.055,.015,INK,rot=(90,0,0),seg=10,smooth=False)
    for y in (-.31,.14):box(p,(0,y,.22),(.17,.08,.18),'363944')
    p.cyl((0,-.08,.35),.115,.115,.65,'252B35',rot=(90,0,0),seg=12,smooth=False)
    p.cyl((0,-.42,.35),.15,.15,.12,'414C5C',rot=(90,0,0),seg=12,smooth=False)
    p.cyl((0,-.487,.35),.11,.11,.015,'67C6CA',rot=(90,0,0),seg=12,smooth=False)
    for y in (-.80,-.62,-.45):box(p,(.169,y,.02),(.025,.06,.12),'A68B5C',bevel=.008)
    for v in p.bm.verts:v.co=gunpoint(v.co)
    p.bm.normal_update()

def parasite(a):
    b=a.part('ParasiteBody',attach='Body')
    # A segmented external grub climbs from the back onto the zombie's shoulder.
    b.tube([(.15,.61,2.75,.37),(.43,.91,3.15,.54),(.70,.87,3.66,.63),
            (.95,.54,4.17,.58),(1.18,.20,4.56,.43)],'777C42',seg=9,sub=2,smooth=False)
    for x,y,z,r in [(.30,.91,3.16,.46),(.52,1.00,3.52,.48),(.77,.92,3.90,.46),(1.02,.65,4.25,.39)]:
        b.sphere((x,y,z),(r,.30,.21),'A6AA61',rot=(0,-20,0),sub=2,smooth=False)
    for s in (-1,1):
        for i in range(3):
            z=3.07+i*.32;x=.40+i*.18
            b.tube([(x+s*.30,.65,z,.07),(x+s*.59,.49,z-.15,.055),(x+s*.50,.16,z-.31,.012)],'4E3B4D',seg=5,sub=2,smooth=False)
    h=a.part('ParasiteHead',attach='ParasiteHead')
    h.sphere((1.23,.02,4.79),(.59,.59,.62),'86709B',sub=2,smooth=False)
    h.sphere((1.25,-.46,4.68),(.43,.16,.39),INK,sub=2,smooth=False)
    ring(h,(1.25,-.51,4.68),.39,.085,'B699B2')
    for i in range(7):
        t=i*math.tau/7
        x=1.25+math.cos(t)*.31;z=4.68+math.sin(t)*.31
        h.cyl((x,-.55,z),.065,.005,.21,BONE,rot=(math.degrees(t)+90,0,90),seg=5,smooth=False)
    glow=a.part('ParasiteGlow',attach='ParasiteHead',material='Neon',ao=0,grad=0,cast=False)
    for x,z,r in [(1.00,5.07,.13),(1.35,5.19,.18),(1.63,4.99,.105)]:
        h.sphere((x,-.35,z),(r+.04,.12,r+.04),'463D58',sub=2)
        glow.sphere((x,-.44,z),(r,.10,r),'D0FA62',sub=2)
    for s,name in [(-1,'TendrilL'),(1,'TendrilR')]:
        p=a.part(name,attach=name)
        pts=[(1.23+s*.32,.16,5.02,.11),(1.23+s*.70,.09,5.65,.085),
             (1.23+s*.98,-.12,5.83,.055),(1.23+s*1.03,-.43,5.59,.018)]
        p.tube(pts,'685278',seg=6,sub=3,smooth=False)
        p.sphere(pts[-1][:3],(.09,.10,.13),'C8DD70',sub=2)
        JOINTS[a.name][name]=list(kit.to_rbx(pts[0][:3]))
    JOINTS[a.name]['ParasiteHead']=list(kit.to_rbx((1.13,.31,4.45)))

def build():
    for kind in ('Normal','Hunter','Parasite'):
        a=kit.asset('Cultist_'+kind)
        torso(a,kind);legs(a,kind);arms(a,kind);head(a,kind)
        JOINTS[a.name]['Head']=list(kit.to_rbx((0,-.10,3.90)))
        if kind=='Hunter':rifle(a)
        if kind=='Parasite':parasite(a)
        # Push the head forward and give each cultist a slightly different crooked posture.
        origin=Vector((0,-.10,3.90))
        tilt=Matrix.Rotation(math.radians(-9 if kind=='Parasite' else 5 if kind=='Normal' else 0),4,'Y')
        for p in a.parts:
            if p.attach=='Head':
                for v in p.bm.verts:v.co=origin+Vector((-.10 if kind=='Parasite' else 0,-.15,0))+tilt.to_3x3()@(v.co-origin)
                p.bm.normal_update()
        JOINTS[a.name]['Head']=list(kit.to_rbx(origin+Vector((-.10 if kind=='Parasite' else 0,-.15,0))))
