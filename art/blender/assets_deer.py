"""Four original, articulated deer monsters modelled from the supplied references.
Authoring: feet at Z=0, facing -Y. Separate head, arms, legs and hand items.
This pack is staged for render approval; no live game configuration is changed.
"""
import math
from mathutils import Vector, Matrix
import kit

BROWN='82401F'; LIGHT='AC602E'; DARK='482219'; HORN='201C23'
MUZZLE='E3B88C'; BLACK='17151C'; WHITE='FFF5DC'; RED='FF261F'
STEEL='BEC7DB'; GOLD='FFBD30'; TEAL='178C88'; COAT='FFF0D9'
JOINTS={}

def box(p,c,s,col,**kw):
    return p.box(c,s,col,bevel=kw.pop('bevel',.025),seg=1,smooth=False,**kw)

def beam(p,a,b,width,depth,col):
    a,b=Vector(a),Vector(b)
    rot=(b-a).to_track_quat('Z','Y').to_euler()
    box(p,(a+b)/2,(width,depth,(b-a).length),col,rot=tuple(math.degrees(v) for v in rot))

def poly(p,points,y,depth,col,**kw):
    return p.prism(points,depth,col,c=(0,y,0),bevel=kw.pop('bevel',.015),smooth=False,**kw)

def ring(p,c,r,t,col,rot=(90,0,0),seg=12):
    p.torus(c,r,t,col,rot=rot,seg=seg,rseg=5)

def face(a,kind):
    h=a.part('Head',attach='Head',ao=.4,ao_dist=.45)
    # Angular skull, broad cheekbones and elongated, framed open muzzle.
    poly(h,[(-.59,4.02),(-.72,4.70),(-.58,5.09),(.56,5.13),(.72,4.69),(.55,4.02)],.02,.95,BROWN,bevel=.055)
    for sign in (-1,1):
        poly(h,[(sign*.50,4.86),(sign*.89,5.40),(sign*1.20,5.48),(sign*1.27,5.18),(sign*.93,4.79)],.03,.24,DARK)
        poly(h,[(sign*.71,4.99),(sign*.96,5.33),(sign*1.10,5.36),(sign*1.12,5.17),(sign*.91,4.96)],-.107,.035,'BA4937')
        # Unblinking, protruding eyes replace the neat angry slits.
        radius=.355 if sign<0 else .315
        h.sphere((sign*.355,-.57,4.87+(sign*.035)),(radius+.055,.17,radius+.055),DARK,sub=2,smooth=False)
    # The muzzle is a real raised rim, with recessed black mouth and individual teeth.
    box(h,(0,-.63,4.19),(.89,.39,1.20),MUZZLE,rot=(5,0,0),bevel=.045)
    box(h,(0,-.856,4.08),(.69,.035,.87),BLACK,rot=(5,0,0),bevel=.012)
    box(h,(0,-.89,3.65),(.65,.07,.055),'C7553D')
    for i in range(4):
        x=-.255+i*.17
        length=(.31,.15,.23,.35)[i]
        poly(h,[(x-.064,4.49),(x+.064,4.49),(x+.032,4.49-length)],-.9,.06,WHITE,bevel=0)
        poly(h,[(x-.058,3.69),(x+.058,3.69),(x-.025,3.69+length*.72)],-.94,.06,WHITE,bevel=0)
    poly(h,[(-.19,4.67),(.19,4.67),(.15,4.54),(.055,4.54),(.055,4.48),(-.055,4.48),(-.055,4.54),(-.15,4.54)],-.85,.12,BLACK)
    box(h,(-.21,-.83,4.60),(.035,.025,.06),DARK)
    box(h,(.21,-.83,4.60),(.035,.025,.06),DARK)
    # Uneven, tapered branches bend in three dimensions rather than forming a flat rake.
    for sign in (-1,1):
        dz=.17 if sign<0 else -.08
        main=[(sign*.43,.13,5.08,.17),(sign*.49,.14,5.66,.16),
              (sign*.81,.20,6.15,.135),(sign*.92,.12,6.71,.105),
              (sign*.84,-.04,7.08+dz,.06),(sign*.91,-.11,7.45+dz,.006)]
        h.tube(main,lambda i:'A941CC' if kind=='Punk' and i>=7 else HORN,seg=5,sub=2,smooth=False)
        h.tube([(sign*.65,.17,5.95,.125),(sign*1.21,.11,6.37,.10),
                (sign*1.43,.02,6.77+dz,.065),(sign*1.68,-.15,7.00+dz,.006)],HORN,seg=5,sub=2,smooth=False)
        h.tube([(sign*.52,.15,5.67,.13),(sign*1.02,-.02,5.86,.075),
                (sign*1.34,-.24,5.90+dz*.5,.006)],HORN,seg=5,sub=2,smooth=False)
    eyes=a.part('EyesGlow',attach='Head',material='Neon',ao=0,grad=0,cast=False)
    for sign in (-1,1):
        radius=.355 if sign<0 else .315
        z=4.87+sign*.035
        eyes.sphere((sign*.355,-.70,z),(radius,.17,radius),RED,sub=3,smooth=True)
        h.sphere((sign*.355+.035,-.865,z-.015),(.205,.065,.22),BLACK,sub=2,smooth=True)
    if kind=='Farmer':
        h.cyl((0,.05,5.17),1.20,1.20,.13,GOLD,seg=20,smooth=False)
        h.cyl((0,.08,5.40),.64,.54,.42,'E7A52C',seg=12,smooth=False)
        h.cyl((0,.08,5.27),.65,.63,.16,'D74229',seg=12,smooth=False)
        for i in range(20):
            t=i*math.tau/20
            beam(h,(math.cos(t)*.73,math.sin(t)*.73+.05,5.247),(math.cos(t)*1.16,math.sin(t)*1.16+.05,5.247),.023,.025,'FFE090')
    elif kind=='Punk':
        ring(h,(-1.18,.025,6.40),.15,.038,STEEL)
        ring(h,(.87,.03,6.54),.14,.034,STEEL)
    elif kind=='Assassin':
        # Open hood: a hollow ring rather than a solid shape covering the face.
        outer=[(-.91,3.83),(-1.02,4.46),(-.79,5.18),(0,5.56),(.79,5.18),(1.02,4.46),(.91,3.83)]
        inner=[(-.63,4.03),(-.77,4.47),(-.55,5.05),(0,5.29),(.55,5.05),(.77,4.47),(.63,4.03)]
        for i in range(len(outer)-1):
            poly(h,[outer[i],outer[i+1],inner[i+1],inner[i]],-.56,.21,'842A3B')
        back=[(x*.88,z-.05) for x,z in outer]
        h.loft([[(x,-.50,z) for x,z in outer],[(x,.55,z) for x,z in back]],
            '642134',wrap=False,cap_start=False,cap_end=False,smooth=False)
        poly(h,back,.55,.12,'642134',bevel=.025)
    else:
        box(h,(0,.1,5.57),(.92,.66,.60),COAT,rot=(0,-5,0),bevel=.06)
        box(h,(0,-.245,5.62),(.13,.035,.35),TEAL)
        box(h,(0,-.25,5.62),(.36,.035,.12),TEAL)
        box(h,(0,-.51,5.31),(1.38,.12,.21),'51515C',bevel=.02)
        h.cyl((0,-.65,5.35),.29,.29,.09,STEEL,rot=(90,0,0),seg=16,smooth=False)
        h.cyl((0,-.709,5.35),.225,.225,.035,'E8E7EF',rot=(90,0,0),seg=16,smooth=False)
        h.cyl((0,-.74,5.35),.055,.055,.035,'62616D',rot=(90,0,0),seg=12,smooth=False)
        for i in range(8):
            t=i*math.tau/8
            beam(h,(math.cos(t)*.08,-.735,5.35+math.sin(t)*.08),(math.cos(t)*.21,-.735,5.35+math.sin(t)*.21),.013,.015,'A7A4B4')

def legs(a,kind):
    cloth={'Farmer':'3464AD','Punk':'282832','Assassin':'33292E','Chief':TEAL}[kind]
    for sign,name in [(-1,'LegR'),(1,'LegL')]:
        p=a.part(name,attach=name)
        top=(sign*.40,0,2.30);knee=(sign*.53,.02,1.28);ankle=(sign*.70,-.02,.32)
        beam(p,top,knee,.57,.60,cloth)
        beam(p,knee,ankle,.38,.43,LIGHT)
        if kind in ('Farmer','Chief'):
            beam(p,knee,(sign*.61,0,.75),.50,.53,cloth)
            box(p,(sign*.62,0,.83),(.57,.58,.24),'4B7FC8' if kind=='Farmer' else '2AABA3',rot=(0,sign*8,0))
        if kind=='Punk':
            beam(p,knee,(sign*.63,0,.62),.49,.51,cloth)
            box(p,(sign*.55,-.28,1.21),(.31,.035,.20),LIGHT,rot=(0,sign*9,0))
            box(p,(sign*.58,-.27,.88),(.41,.04,.10),'4D4B56',rot=(0,-sign*8,0))
        # Cloven hoof with a visible central split.
        for split in (-1,1):
            box(p,(sign*.72+split*.145,-.105,.18),(.265,.65,.35),HORN,taper=.75,bevel=.017)

def body(a,kind):
    b=a.part('Body',attach='Body')
    width=1.62 if kind=='Chief' else 1.22
    box(b,(0,.03,2.95),(width,.78,1.55),BROWN,taper=1.13,bevel=.075)
    box(b,(0,0,3.82),(.50,.55,.45),BROWN)
    if kind=='Farmer':
        box(b,(0,-.02,2.45),(1.27,.87,.53),'3464AD')
        box(b,(0,-.43,2.97),(.90,.10,.85),'3C70BE')
        box(b,(0,-.51,2.94),(.47,.07,.34),'28569D')
        box(b,(0,.48,2.60),(1.17,.10,.68),'3464AD')
        for s in (-1,1):
            beam(b,(s*.44,.45,3.72),(-s*.33,.49,2.80),.15,.07,'4381D1')
            box(b,(s*.32,.55,2.52),(.35,.06,.27),'28569D')
        for s in (-1,1):
            box(b,(s*.44,-.43,3.39),(.17,.11,.70),'4381D1',rot=(0,-s*7,0))
            box(b,(s*.43,-.51,3.15),(.17,.065,.18),GOLD)
            box(b,(s*.43,-.55,3.15),(.075,.03,.085),'FBE68D')
        poly(b,[(-.60,3.80),(-.38,3.43),(0,3.19),(.46,3.59),(.56,3.84)],-.49,.13,'D93D30')
        poly(b,[(-.47,3.74),(0,3.38),(.40,3.69)],-.575,.035,'F05A3E')
    elif kind=='Punk':
        box(b,(0,-.415,3.00),(1.06,.09,1.45),'823BBD')
        box(b,(0,.47,3.03),(1.20,.14,1.50),'292831',bevel=.035)
        box(b,(0,.55,3.08),(.78,.04,.77),'45414E',bevel=.015)
        # A subtle purple back patch completes the jacket from all camera angles.
        poly(b,[(-.04,3.40),(.16,3.40),(0,3.13),(.18,3.13),(-.19,2.82),(-.07,3.09),(-.23,3.09)],.585,.025,'A65CD8')
        poly(b,[(-.01,3.56),(.26,3.56),(.06,3.22),(.29,3.22),(-.21,2.74),(-.08,3.12),(-.30,3.12)],-.482,.025,'E6BBFF')
        for s in (-1,1):
            box(b,(s*.59,.02,3.06),(.38,.99,1.50),'292831',rot=(0,-s*5,0))
            poly(b,[(s*.28,3.75),(s*.75,3.70),(s*.52,3.25),(s*.35,3.38)],-.545,.11,'45414E')
            for z in (2.67,2.99,3.31):
                b.cyl((s*.61,-.56,z),.10,0,.15,STEEL,rot=(90,0,0),seg=4,smooth=False)
            # Over-ear headphones rest around the neck.
            b.cyl((s*.71,-.03,3.76),.32,.32,.21,BLACK,rot=(0,90,0),seg=12,smooth=False)
            b.cyl((s*.83,-.03,3.76),.255,.255,.09,'9D46DB',rot=(0,90,0),seg=12,smooth=False)
        b.tube([(-.71,.03,3.76,.065),(-.59,.39,4.04,.065),(0,.49,4.14,.065),(.59,.39,4.04,.065),(.71,.03,3.76,.065)],BLACK,seg=6,sub=2)
        for i in range(9):
            x=-.49+i*.1225;z=3.60-.20*(1-(x/.49)**2)
            ring(b,(x,-.64,z),.077,.025,STEEL,rot=(90,0,0 if i%2==0 else 60),seg=8)
        for i in range(7):
            x=.25+i*.09;z=2.37-.25*math.sin(i/6*math.pi)
            ring(b,(x,-.50,z),.075,.023,STEEL,rot=(90,0,i%2*60),seg=8)
    elif kind=='Assassin':
        box(b,(0,-.04,3.00),(1.28,.86,1.55),'30262E',bevel=.07)
        for s in (-1,1):
            poly(b,[(s*.08,3.83),(s*.61,3.89),(s*.99,3.46),(s*.66,3.35),(s*.32,3.55)],-.43,.18,'6E2334')
            poly(b,[(s*.06,2.39),(s*.60,2.49),(s*.89,1.81),(s*.48,2.01),(s*.35,1.68),(s*.19,1.95)],-.30,.65,'352B36')
        poly(b,[(-.78,3.65),(.78,3.65),(.90,1.76),(.50,1.99),(.22,1.73),(-.24,2.00),(-.74,1.69)],.53,.12,'652333')
    else:
        box(b,(0,-.04,2.89),(1.58,.85,1.55),TEAL,bevel=.07)
        poly(b,[(-.52,3.64),(0,3.18),(.56,3.62),(.35,3.76),(0,3.43),(-.28,3.79)],-.49,.06,'146961')
        for s in (-1,1):
            poly(b,[(s*.36,3.91),(s*.91,3.88),(s*1.08,3.39),(s*.75,2.39),(s*1.28,1.40),(s*.59,1.63),(s*.22,2.42)],-.12,.99,COAT,bevel=.045)
            poly(b,[(s*.41,3.86),(s*.90,3.65),(s*.66,3.40),(s*.80,3.24),(s*.28,2.82),(s*.55,3.38)],-.65,.06,'209C91')
            poly(b,[(s*.43,3.83),(s*.80,3.64),(s*.56,3.39),(s*.69,3.24),(s*.36,3.00),(s*.61,3.39)],-.695,.06,COAT)
            box(b,(s*.76,-.64,2.31),(.35,.06,.24),TEAL,rot=(0,s*15,0))
            box(b,(s*.76,-.68,2.36),(.35,.045,.075),COAT,rot=(0,s*15,0))
        poly(b,[(-.86,3.87),(.86,3.87),(.92,3.18),(.73,2.43),(1.15,1.50),(.20,1.61),(0,1.93),(-.20,1.61),(-1.15,1.50),(-.73,2.43),(-.92,3.18)],.51,.28,COAT,bevel=.035)
        box(b,(0,.67,2.72),(1.46,.06,.14),'E1D0B7',bevel=.015)
        beam(b,(0,.66,3.69),(0,.66,2.83),.022,.025,'D9CDBB')
        # Stethoscope and ID badge are actual geometry, not painted-on stickers.
        b.tube([(-.30,-.53,3.98,.055),(-.62,-.73,3.67,.055),(-.68,-.75,3.06,.055),(-.49,-.77,2.93,.055),(-.33,-.75,3.10,.055),(-.34,-.69,3.44,.055)],BLACK,seg=8,sub=2)
        b.tube([(.30,-.53,3.98,.055),(.61,-.73,3.67,.055),(.64,-.78,3.22,.055)],BLACK,seg=8,sub=2)
        for x in (-.65,-.35):box(b,(x,-.79,3.09),(.065,.07,.26),STEEL,bevel=.02)
        b.cyl((.64,-.82,3.20),.20,.20,.07,STEEL,rot=(90,0,0),seg=14,smooth=False)
        b.cyl((.64,-.865,3.20),.13,.13,.025,'747482',rot=(90,0,0),seg=14,smooth=False)
        box(b,(.65,-.73,2.87),(.50,.08,.33),GOLD)
        box(b,(.65,-.78,2.87),(.43,.03,.26),WHITE)
        box(b,(.52,-.80,2.87),(.055,.025,.17),TEAL);box(b,(.52,-.805,2.87),(.16,.025,.055),TEAL)
        for z in (2.92,2.85):box(b,(.74,-.80,z),(.17,.025,.022),'987450',bevel=0)
        for s in (-1,1):
            b.cyl((s*.45,-.67,2.32),.10,.10,.49,'46D9EF',seg=8,smooth=False)
            for z in (2.06,2.57):box(b,(s*.45,-.67,z),(.24,.25,.10),STEEL)
    if kind in ('Assassin','Chief'):
        box(b,(0,-.04,2.50),(1.43 if kind=='Chief' else 1.31,.95,.22),'593A2C')
        box(b,(0,-.565,2.50),(.38,.13,.32),STEEL if kind=='Chief' else 'C79862')
        box(b,(0,-.64,2.50),(.23,.035,.20),BLACK)

def arms(a,kind):
    for sign,name in [(-1,'ArmR'),(1,'ArmL')]:
        p=a.part(name,attach=name)
        shoulder=(sign*(.95 if kind=='Chief' else .76),.02,3.63)
        elbow=(sign*1.56,-.10,3.05)
        wrist=(sign*2.22,-.43,2.48)
        col=COAT if kind=='Chief' else LIGHT
        beam(p,shoulder,elbow,.49 if kind=='Chief' else .31,.51 if kind=='Chief' else .34,col)
        beam(p,elbow,wrist,.17,.19,HORN)
        if kind=='Chief':
            beam(p,elbow,Vector(elbow).lerp(Vector(wrist),.62),.40,.42,COAT)
        if kind=='Chief':
            box(p,(sign*.99,.02,3.61),(.60,.64,.48),COAT,rot=(0,sign*24,0),bevel=.065)
            box(p,Vector(elbow).lerp(Vector(wrist),.62),(.41,.44,.15),TEAL,rot=(0,-sign*45,0))
        elif kind=='Assassin':
            for i in range(4):
                t=.12+i*.13;at=Vector(elbow).lerp(Vector(wrist),t)
                box(p,at,(.25,.28,.11),MUZZLE,rot=(0,-sign*45,0))
        elif kind=='Punk':
            box(p,(sign*.83,.02,3.47),(.52,.63,.48),'323039',rot=(0,sign*22,0))
        glove=TEAL if kind=='Chief' else HORN
        box(p,(sign*2.30,-.48,2.30),(.49,.34,.43),glove,rot=(0,-sign*20,0))
        # Exaggerated hooked digits; tool hand curls around the shaft, other hand spreads.
        for i,dx in enumerate((-.19,0,.19)):
            spread=dx*2.1
            finger=[(sign*2.30+dx,-.52,2.20,.090),
                    (sign*2.36+spread,-.65,1.92-i*.035,.077),
                    (sign*2.34+spread,-.86,1.63-i*.045,.052),
                    (sign*2.29+spread,-1.00,1.52-i*.03,.006)]
            p.tube(finger,glove,seg=5,sub=2,smooth=False)
        p.tube([(sign*2.08,-.49,2.38,.11),(sign*1.91,-.64,2.16,.09),
                (sign*1.94,-.85,1.97,.05),(sign*2.08,-.95,1.99,.006)],glove,seg=5,sub=2,smooth=False)
        JOINTS.setdefault(a.name,{})[name]=list(kit.to_rbx(shoulder))

def hand_item(a,kind):
    if kind=='Punk':return
    p=a.part('HandItem',attach='ArmR')
    if kind=='Farmer':
        beam(p,(-1.61,-.46,.13),(-1.61,-.46,3.60),.12,.12,'BA792F')
        box(p,(-1.61,-.46,3.57),(.25,.23,.27),'795138')
        poly(p,[(-2.36,3.38),(-2.14,3.83),(-1.59,3.81),(-1.40,3.52),(-1.93,3.55)],-.46,.30,'B3BACD')
        poly(p,[(-2.36,3.38),(-2.14,3.83),(-2.06,3.75),(-2.25,3.41)],-.625,.025,'E1E6EF')
    elif kind=='Assassin':
        box(p,(-1.61,-.49,2.24),(.14,.17,.45),BLACK)
        box(p,(-1.61,-.49,2.01),(.52,.22,.14),STEEL)
        poly(p,[(-1.80,1.94),(-1.42,1.94),(-1.42,.96),(-1.60,.63),(-1.80,.96)],-.49,.11,'CAD5E3')
        poly(p,[(-1.60,1.91),(-1.42,1.91),(-1.42,.96),(-1.60,.63)],-.555,.018,'F4F3EF',bevel=0)
    else:
        x=-1.64;y=-.56
        p.cyl((x,y,1.21),.235,.235,1.23,'25D9EB',seg=12,smooth=False)
        # Opaque cyan glass core preserves the liquid silhouette in the Roblox mesh pipeline.
        for z in (.57,1.84):p.cyl((x,y,z),.29,.29,.16,STEEL,seg=10,smooth=False)
        p.cyl((x,y,2.15),.09,.09,.55,STEEL,seg=8,smooth=False)
        p.cyl((x,y,2.51),.30,.30,.15,TEAL,seg=8,smooth=False)
        p.cyl((x,y,.36),.10,.16,.27,STEEL,seg=8,smooth=False)
        p.cyl((x,y,.10),.022,.04,.25,'7D899E',seg=6,smooth=False)
        box(p,(x,y,1.97),(.81,.19,.10),STEEL)
        box(p,(x-.09,y-.235,1.20),(.065,.025,.91),'C0FFFF')
        for i in range(5):box(p,(x+.10,y-.236,.85+i*.17),(.17 if i%2==0 else .10,.027,.025),WHITE,bevel=0)

def uncanny_proportions(a,kind):
    """Long-legged, narrow-waisted, forward-hunched silhouette, with authored pivots updated."""
    def deform(v):
        x,y,z=v
        leg=max(0,min(1,(z-.35)/1.95))
        chest=max(0,min(1,(z-2.3)/1.35))
        zz=z if z<=.35 else .35+(z-.35)*1.50 if z<2.3 else 3.275+(z-2.3)*1.08
        width=(.91 if kind=='Chief' else .81)+chest*(.12 if kind=='Chief' else .21)
        # Hunched shoulder line, with the lower legs bent back under the pelvis.
        yy=y-.39*max(0,min(1,(z-2.65)/1.25))
        if z<2.3:yy+=.22*math.sin(leg*math.pi)
        return Vector((x*width,yy,zz))
    neck=Vector((0,0,3.95))
    head_origin=deform(neck)+Vector((0,-.18,0))
    tilt=Matrix.Rotation(math.radians({'Farmer':-6,'Punk':7,'Assassin':-10,'Chief':-7}[kind]),4,'Y') @ Matrix.Rotation(math.radians(10),4,'X')
    grip=Vector((-2.31,-.62,2.30))
    for p in a.parts:
        for v in p.bm.verts:
            if p.attach=='Head':
                v.co=head_origin+tilt.to_3x3()@((v.co-neck)*1.04)
            elif p.name=='HandItem':
                shifted=v.co+Vector((-.70,-.16,0))
                v.co=deform(grip)+(shifted-grip)
            else:v.co=deform(v.co)
        p.bm.normal_update()
    for name,point in JOINTS[a.name].items():
        if name=='Head':out=head_origin
        else:out=deform(Vector((-point[0],point[2],point[1])))
        JOINTS[a.name][name]=list(kit.to_rbx(out))

def build():
    for kind in ('Farmer','Punk','Assassin','Chief'):
        a=kit.asset('Deer_'+kind)
        body(a,kind);legs(a,kind);arms(a,kind);face(a,kind);hand_item(a,kind)
        JOINTS[a.name].update({'Head':list(kit.to_rbx((0,0,3.95))),
            'LegL':list(kit.to_rbx((.4,0,2.30))),'LegR':list(kit.to_rbx((-.4,0,2.30)))})
        uncanny_proportions(a,kind)
