"""Nine articulated collection monsters, authored against the user's three references."""
import math
import kit
from mathutils import Vector, Matrix
from assets_deer import box, beam, poly, ring

JOINTS={}
BLACK='201A26'; BONE='F2DEAD'; GOLD='FFBD36'; METAL='BFC0CD'

def joint(a,name,pos):
    JOINTS.setdefault(a.name,{})[name]=list(kit.to_rbx(pos))

def chain(p,x0,x1,z,y):
    for i in range(9):
        x=x0+(x1-x0)*i/8
        ring(p,(x,y,z-.26*math.sin(i*math.pi/8)),.115,.038,METAL,rot=(90,0,(i%2)*60),seg=8)

def head(a,family,role,expression=None):
    h=a.part('Head',attach='Head',ao=.4,ao_dist=.35)
    eye=a.part('EyesGlow',attach='Head',material='Neon',ao=0,grad=0)
    joint(a,'Head',(0,-.05,4.75))
    aggressive=expression=='Aggressive'
    if family=='Parasite':
        # Recessed mouth surrounded by a volumetric octagonal flesh rim.
        box(h,(0,.04,5.45),(1.75,1.15,1.62),'592734',bevel=.17)
        outer=[(-.95,5.75),(-.64,6.12),(.64,6.12),(.98,5.74),(.82,4.78),(.47,4.48),(-.47,4.48),(-.82,4.8)]
        inner=[(-.68,5.64),(-.43,5.83),(.43,5.83),(.70,5.64),(.59,4.92),(.34,4.72),(-.34,4.72),(-.59,4.92)]
        if aggressive:
            outer=[(x*1.10,5.35+(z-5.35)*1.16) for x,z in outer]
            inner=[(x*1.16,5.35+(z-5.35)*1.20) for x,z in inner]
        poly(h,inner,-.67,.08,'110F19')
        for i in range(8):
            j=(i+1)%8;poly(h,[outer[i],outer[j],inner[j],inner[i]],-.76,.29,'7C3445')
        box(h,(0,-.89,6.00),(1.05,.20,.32),'482530')
        for s in (-1,1):
            box(eye,(s*.30,-1.003,6.02),(.11,.025,.075),'FF302F' if aggressive else 'DCA75B' if expression else 'EF593C',bevel=0)
        for i in range(7):
            x=(i-3)*.175
            box(h,(x,-.92,5.66+(.07 if abs(i-3)<2 else 0)+(.11 if aggressive else 0)),(.125,.16,.25+(i%2)*.07),BONE,rot=(0,(i-3)*4,0),bevel=.015)
            box(h,(x,-.90,4.88-(.08 if abs(i-3)<2 else 0)-(.13 if aggressive else 0)),(.12,.15,.23+(i%2)*.07),BONE,rot=(0,-(i-3)*4,0),bevel=.015)
    elif family=='Stalker':
        box(h,(0,-.12,5.78),(1.45,1.15,1.30),'32B8B9',bevel=.12)
        jaw_drop=.24 if aggressive else 0
        box(h,(0,-.74,5.05-jaw_drop*.5),(.94 if aggressive else .84,.12,1.34+jaw_drop),'193232',bevel=.025)
        for s in (-1,1):
            beam(h,(s*(.55 if aggressive else .50),-.78,5.55),(s*.38,-.79,4.38-jaw_drop),.14,.18,'B84B60')
            box(eye,(s*.31,-.715,5.80),(.36,.04,.23),'FF3D46' if aggressive else 'D4FFFF',bevel=.01)
            for i in range(4):
                flare=.16 if aggressive else 0
                box(h,(s*(.84+flare+.07*(3-i)),.02,5.28+i*.35),(.34,.65,.56),'C95168',rot=(0,s*(18+i*7+(16 if aggressive else 0)),0),bevel=.04)
                box(h,(s*(1.02+flare+.05*(3-i)),.04,5.42+i*.35),(.16,.5,.18),'F0798B',rot=(0,s*(41 if aggressive else 25),0),bevel=.02)
        box(h,(0,-.8,4.40-jaw_drop),(.78,.18,.14),'D95F70')
        box(h,(0,-.84,4.49-jaw_drop),(.48,.10,.10),'45D2CB')
        if aggressive:
            for i in range(4):
                x=(i-1.5)*.19
                poly(h,[(x-.054,5.66),(x+.054,5.66),(x,5.39)],-.85,.085,BONE)
                poly(h,[(x-.05,4.43-jaw_drop),(x+.05,4.43-jaw_drop),(x,4.68-jaw_drop)],-.90,.085,BONE)
    else:
        poly(h,[(-.65,6.35),(-.83,6.02),(-.74,5.50),(-.4,5.04),(0,4.90),(.4,5.04),(.74,5.50),(.83,6.02),(.65,6.35)],-.03,.95,BONE,bevel=.08)
        for s in (-1,1):
            box(h,(s*.34,-.53,5.94),(.34,.08,.42),'201F1B',rot=(0,-s*8,0),bevel=.065)
            box(eye,(s*.36,-.575,6.01),(.035,.01,.035),'94815D',bevel=0)
        poly(h,[(-.65,5.65),(0,5.43),(.65,5.65),(.47,5.16),(0,5.04),(-.47,5.16)],-.56,.09,'2C2523')
        for i in range(9):
            x=(i-4)*.13;z=5.34+.18*(abs(i-4)/4)**1.4
            box(h,(x,-.625,z),(.108,.06,.30),BONE,rot=(0,-(i-4)*8,0),bevel=.014)
    if role=='Farmer':
        z=6.42 if family!='Parasite' else 6.28
        h.cyl((0,.02,z),1.24,1.24,.14,GOLD,seg=16,smooth=False)
        h.cyl((0,.04,z+.3),.72,.62,.52,'F0B739',seg=12,smooth=False)
        h.cyl((0,.04,z+.13),.73,.71,.16,'B74832',seg=12,smooth=False)
        for i in range(16):
            t=i*math.tau/16;beam(h,(.8*math.cos(t),.8*math.sin(t),z+.08),(1.20*math.cos(t),1.20*math.sin(t),z+.08),.022,.022,'FFE086')
    elif role=='Punk':
        if family=='Verity':
            for i in range(7):
                x=-.78+i*.21
                beam(h,(x,.02,6.45),(x-.45,-.30,5.85-abs(x)*.6),.25,.38,'8E39B4' if i%2 else 'B34CD2')
        else:
            for i in range(5):
                box(h,((i-2)*.24,.12,6.47+.28*(1-abs(i-2)/3)),(.22,.65,.75),'A83BD0',rot=(0,(i-2)*-12,0))
    elif role=='Assassin' and family!='Stalker':
        outer=[(-1.02,4.85),(-1.16,5.65),(-.76,6.57),(0,6.88),(.76,6.57),(1.16,5.65),(1.02,4.85)]
        inner=[(-.79,5.0),(-.86,5.65),(-.53,6.37),(0,6.55),(.53,6.37),(.86,5.65),(.79,5.0)]
        color='672535' if family=='Parasite' else '39313C'
        for i in range(6):poly(h,[outer[i],outer[i+1],inner[i+1],inner[i]],-.69,.23,color)
        h.loft([[(x,-.63,z) for x,z in outer],[(x*.85,.65,z-.10) for x,z in outer]],color,wrap=False,cap_start=False,cap_end=False,smooth=False)
        poly(h,[(x*.85,z-.1) for x,z in outer],.65,.12,color)

def character(family,role,expression=None):
    a=kit.asset(family+'_'+role)
    bulky=family=='Parasite';skin={'Parasite':'70313E','Stalker':'30B7B8','Verity':BONE}[family]
    w=1.05 if bulky else .63; thick=.65 if bulky else .28 if family=='Verity' else .36
    cloth=skin if role=='Root' else ('35649A' if family!='Verity' else '247D80') if role=='Farmer' else '673780' if role=='Punk' else BLACK
    b=a.part('Body',attach='Body');box(b,(0,.08,3.53),(w*2,1.05 if bulky else .68,2.0),skin,bevel=.09)
    beam(b,(0,0,4.2),(0,-.05,4.95),.42,.42,skin)
    # All costumes have finished front, back, and side geometry.
    box(b,(0,.08,2.70),(w*1.85,.93 if bulky else .72,.55),cloth)
    if role=='Farmer':
        box(b,(0,-.55 if bulky else -.37,3.44),(w*1.6,.12,1.23),cloth)
        box(b,(0,-.64 if bulky else -.46,3.24),(w*.85,.10,.47),'D19A32' if bulky else '31608A')
        for s in (-1,1):
            for y in (-.55 if bulky else -.37,.62 if bulky else .45):
                beam(b,(s*w*.72,y,4.5),(s*w*.65,y,3.40),.22,.12,cloth)
            box(b,(s*w*.65,-.65 if bulky else -.46,3.65),(.25,.09,.26),GOLD)
        if bulky:
            box(b,(0,-.70,3.06),(1.34,.13,.96),'DC982D')
            box(b,(0,-.79,3.08),(.70,.08,.49),'F6B647')
    elif role=='Punk':
        box(b,(0,-.53 if bulky else -.37,3.55),(w*1.7,.10,1.75),'793497')
        for s in (-1,1):
            box(b,(s*w*.85,.08,3.67),(w*.65,1.23 if bulky else .87,1.73),'2C2834')
            poly(b,[(s*w*.30,4.5),(s*w*1.22,4.4),(s*w*.73,3.8)],-.68 if bulky else -.48,.13,'4A414F')
            for z in (3.2,3.7,4.2):b.cyl((s*w*.90,-.69 if bulky else -.49,z),.13,0,.15,METAL,rot=(90,0,0),seg=4,smooth=False)
        box(b,(0,.69 if bulky else .47,3.65),(w*1.9,.12,1.7),'2C2834')
        poly(b,[(.08,4.08),(-.23,3.66),(.02,3.66),(-.13,3.17),(.37,3.83),(.10,3.80)],-.74 if bulky else -.50,.03,'DCA4FF')
        chain(b,-w*.65,w*.65,4.48,-.77 if bulky else -.54)
        chain(b,.15,w,2.83,-.66 if bulky else -.47)
    elif role=='Assassin':
        box(b,(0,.06,3.45),(w*1.88,1.05 if bulky else .80,1.8),'302932')
        for s in (-1,1):
            poly(b,[(s*w*.25,4.55),(s*w*1.48,4.48),(s*w*1.75,3.92),(s*w*.72,4.05)],-.10,.91,'493745')
            poly(b,[(s*.08,2.85),(s*w*.9,2.95),(s*w*1.2,1.95),(s*w*.65,2.18),(s*w*.5,1.85)],-.04,.25,'3C2E3C')
        box(b,(0,-.03,2.94),(w*2.06,1.13 if bulky else .87,.25),'913D46')
        beam(b,(-w*.77,-.65 if bulky else -.49,3.07),(w*.9,-.65 if bulky else -.49,4.48),.23,.13,'873544')
        box(b,(.2,-.75 if bulky else -.58,3.8),(.29,.12,.32),METAL)
        # Ragged cloak, separate from limbs and behind the torso.
        poly(b,[(-w,4.45),(w,4.45),(w*1.4,2.01),(.6,2.23),(.18,1.86),(-.35,2.1),(-w*1.3,1.96)],.80 if bulky else .57,.10,'692E40' if bulky else '302A37')
    for s,name in [(-1,'LegR'),(1,'LegL')]:
        p=a.part(name,attach=name);hip=(s*w*.57,.06,2.70);knee=(s*(w*.9),-.22,1.42);ankle=(s*w*.88,.10,.38)
        joint(a,name,hip)
        beam(p,hip,knee,thick*1.15,thick*1.3,cloth if role!='Assassin' or bulky else skin)
        beam(p,knee,ankle,thick,thick*1.1,cloth if role!='Assassin' else skin)
        footcol=skin if role=='Root' else 'DFA52D' if family=='Verity' and role=='Farmer' else skin if family=='Stalker' or (family=='Verity' and role=='Assassin') else BLACK
        box(p,(s*w*.88,-.14,.20),(thick*1.65,.95,.38),footcol)
        if family=='Stalker':
            for j in range(3):box(p,(s*w*.88+(j-1)*.17,-.65,.19),(.14,.25,.25),'CF647B')
        if role=='Farmer':box(p,knee,(thick*1.4,thick*1.5,.26),'5D85AC')
        if role=='Punk':
            for z in (.9,1.5,2.05):box(p,(s*w*.83,-.40,z),(thick*1.2,.055,.19),'41243F')
    for s,name in [(-1,'ArmR'),(1,'ArmL')]:
        p=a.part(name,attach=name);shoulder=(s*(w+.18),.03,4.35);elbow=(s*(w+.62),-.07,3.26);hand=(s*(w+.72),-.49,2.55 if bulky else 2.14)
        joint(a,name,shoulder)
        beam(p,shoulder,elbow,thick*1.25,thick*1.25,skin);beam(p,elbow,hand,thick,thick,skin)
        box(p,hand,(thick*1.4,.45,.53),skin if role in ('Farmer','Root') else BLACK if bulky else skin)
        if role in ('Punk','Assassin'):
            box(p,(hand[0],hand[1],hand[2]+.25),(thick*1.75,.62,.24),'8B389F' if role=='Punk' else '4B3E50')
            if role=='Punk':
                for j in range(2):p.cyl((hand[0]+(j-.5)*.23,hand[1]-.34,hand[2]+.25),.11,0,.13,METAL,rot=(90,0,0),seg=4,smooth=False)
        for j in range(3):
            x=hand[0]+(j-1)*thick*.45
            beam(p,(x,-.54,hand[2]-.2),(x+s*.10,-.67,hand[2]-.66),.12 if not bulky else .20,.15,BONE if bulky and role=='Assassin' else skin)
            if family!='Parasite':beam(p,(x+s*.10,-.67,hand[2]-.66),(x+s*.08,-.83,hand[2]-.85),.10,.12,'C86177' if family=='Stalker' else BONE)
    if family=='Parasite':
        for s,name in [(-1,'TendrilR'),(1,'TendrilL')]:
            p=a.part(name,attach='Body');pts=[(s*.7,.55,4.2),(s*1.3,.65,5.0),(s*1.7,.6,5.75),(s*1.5,.54,6.40),(s*1.80,.45,6.80)]
            for i in range(4):beam(p,pts[i],pts[i+1],.28,.32,'44202F' if i%2 else '702D43')
            box(p,pts[-1],(.42,.43,.35),'81344C')
            joint(a,name,pts[0])
    head(a,family,role,expression)
    if role=='Farmer':
        p=a.part('HandItem',attach='ArmR');x=-(w+.72);y=-.54
        beam(p,(x,y,.22),(x,y,3.65),.14,.14,'B87B32')
        if family=='Stalker':
            box(p,(x,y,3.68),(1.25,.25,.18),METAL)
            for j in range(5):box(p,(x+(j-2)*.25,y-.1,3.44),(.10,.14,.46),METAL)
        else:
            poly(p,[(x-.43,.87),(x+.43,.87),(x+.39,.18),(x,.03),(x-.39,.18)],y,.14,'A6A5B7')
            box(p,(x,y,3.65),(.45,.18,.14),'7F522A')
        carry=a.part('HarvestItem',attach='ArmL');hx=w+.72;hy=-.57;hz=1.18 if bulky else .70
        if family=='Parasite':
            # Open wooden vegetable basket, carried by its raised handle.
            box(carry,(hx,hy,hz),(1.03,.75,.12),'9D692E')
            for z in (hz+.16,hz+.35,hz+.54):
                for dy in (-.36,.36):box(carry,(hx,hy+dy,z),(1.08,.09,.14),'C68A44')
                for dx in (-.5,.5):box(carry,(hx+dx,hy,z),(.09,.75,.14),'B77F3B')
            for dx in (-.4,.4):beam(carry,(hx+dx,hy,hz+.55),(hx+dx,hy,2.20),.075,.075,'E1A855')
            beam(carry,(hx-.4,hy,2.20),(hx+.4,hy,2.20),.09,.09,'E1A855')
            for j in range(3):
                x=hx+(j-1)*.25
                carry.cyl((x,hy,hz+.62),.03,.14,.50,'F79026',seg=5,smooth=False)
                for k in (-1,0,1):beam(carry,(x,hy,hz+.85),(x+k*.14,hy+.08,hz+1.15),.075,.08,'63B733')
        elif family=='Stalker':
            box(carry,(hx,hy,hz),(.79,.65,.85),'D9B67B',taper=.8,bevel=.10)
            box(carry,(hx,hy,hz+.48),(.48,.45,.15),'AE8756')
            for dx in (-.18,.18):beam(carry,(hx+dx,hy,hz+.5),(hx+dx,hy,1.85),.07,.07,'D9B67B')
            beam(carry,(hx-.18,hy,1.85),(hx+.18,hy,1.85),.08,.08,'D9B67B')
            beam(carry,(hx,hy-.35,hz-.12),(hx,hy-.35,hz+.20),.035,.04,'3F8641')
            for s in (-1,1):poly(carry,[(hx,hz+.1),(hx+s*.25,hz+.34),(hx+s*.20,hz+.08)],hy-.36,.025,'6CA443')
        else:
            box(carry,(hx,hy,hz+.15),(.84,.65,.66),'9499AB',bevel=.045)
            for dx in (-.28,.28):beam(carry,(hx+dx,hy,hz+.48),(hx+dx,hy,1.86),.09,.1,'737889')
            beam(carry,(hx-.28,hy,1.86),(hx+.28,hy,1.86),.09,.1,'737889')
            beam(carry,(hx+.38,hy,hz+.15),(hx+.92,hy,hz+.44),.20,.20,'B2B6C3')
            box(carry,(hx+.95,hy,hz+.47),(.13,.38,.37),'BEC1CD',rot=(0,25,0))
            for j in range(3):box(carry,(hx+1.01,hy+(j-1)*.11,hz+.46),(.06,.045,.05),'494F5B')
    # Family silhouettes stay distinct even when viewed as small inventory thumbnails.
    def deform(v):
        x,y,z=v
        if family=='Parasite':return Vector((x*1.13,y,z*.82 if z<2.7 else z-.486))
        if family=='Stalker':
            return Vector((x,y-.32*max(0,min(1,(z-3.5)/1.4))-.23*max(0,1-abs(z-1.5)/1.1),z))
        return Vector((x,y,z*1.18 if z<2.7 else z+.486))
    for part in a.parts:
        for vertex in part.bm.verts:vertex.co=deform(vertex.co)
        part.bm.normal_update()
    for name,point in JOINTS[a.name].items():
        JOINTS[a.name][name]=list(kit.to_rbx(deform(Vector((-point[0],point[2],point[1])))))
    return a

def build():
    for family in ('Parasite','Stalker','Verity'):
        for role in ('Farmer','Punk','Assassin'):character(family,role)
