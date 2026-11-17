"""Dredge anatomy study: a single skull, clawed arms and a continuous coiled tail.

New geometry, informed by the user's second screenshot and the Dredge render at
https://www.mcmod.cn/item/948927.html. Z up, front -Y. No game integration.
"""
import math
import sys
from pathlib import Path
from mathutils import Vector

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'blender'))
import kit

RIGS={};DETAILS={};TAIL_PATH=[]
RED='78313B';FLESH='A64E50';MUSCLE='8E3C41';DARK='342A31'
BLACK='15171C';BONE='D6BC94';PALE='E3CDA9';BROWN='574048'


def part(a,name,attach=None):
    return a.part(name,attach=attach or name,ao=.31,ao_dist=.36,grad=.06)


def box(p,c,s,col,**kw):
    return p.box(c,s,col,bevel=kw.pop('bevel',.025),seg=1,smooth=False,**kw)


def bone(r,name,start,end,parent):r[name]=(tuple(start),tuple(end),parent)


def beam(p,a,b,w,d,col):
    a,b=Vector(a),Vector(b)
    e=(b-a).to_track_quat('Z','Y').to_euler()
    box(p,(a+b)/2,(w,d,(b-a).length),col,rot=tuple(math.degrees(x) for x in e),bevel=min(w,d)*.09)


def segment(p,a,b,ra,rb,col,n=8):
    a,b=Vector(a),Vector(b);q=(b-a).to_track_quat('Z','Y')
    rings=[]
    for t,r in ((0,ra),(.16,ra*1.03),(.87,rb*1.02),(1,rb)):
        c=a.lerp(b,t)
        rings.append([c+q@Vector((math.cos(j*math.tau/n)*r,math.sin(j*math.tau/n)*r*.83,0)) for j in range(n)])
    p.loft(rings,col,smooth=False)


def blade(p,points,col,r,n=5):
    p.tube([(*c,max(.009,r*(1-i/(len(points)-1))**.65)) for i,c in enumerate(points)],col,
           seg=n,sub=1,smooth=False)


def poly(p,outline,y,depth,col):
    p.prism(outline,depth,col,c=(0,y,0),bevel=.018,smooth=False)


def dredge():
    name='Dredge';a=kit.asset(name);r={};RIGS[name]=r
    bone(r,'Root',(0,0,0),(0,0,.5),None)
    bone(r,'Body',(0,.05,3.09),(0,0,4.92),'Root')
    bone(r,'Neck',(0,0,4.91),(0,-.025,5.46),'Body')
    bone(r,'Head',(0,-.025,5.46),(0,-.025,6.69),'Neck')
    bone(r,'Jaw',(0,.01,5.69),(0,-.57,5.29),'Head')

    # Slender upright flesh torso with a pronounced narrow waist.
    p=part(a,'Body')
    p.loft([[(rx*math.cos(j*math.tau/10),cy+ry*math.sin(j*math.tau/10),z) for j in range(10)]
            for z,rx,ry,cy in [(3.06,.41,.37,.09),(3.53,.45,.37,.05),
                              (3.96,.55,.42,.03),(4.51,.69,.40,.02),
                              (4.97,.86,.34,.03),(5.11,.38,.28,.04)]],
           lambda i:[DARK,RED,MUSCLE,FLESH,RED][min(i,4)],smooth=False)
    # Broad central dark split; the white rib segments wrap around it.
    poly(p,[(-.23,3.53),(-.43,4.35),(-.34,4.81),(.28,4.88),(.45,4.34),(.23,3.49)],-.39,.10,'4C242B')
    for s in (-1,1):
        for j in range(6):
            z=3.57+j*.225;w=.36+.073*j
            # Source ribs are short bone bars along the sides of a red split chest.
            p.tube([(s*(w-.04),-.43,z+.17,.073),(s*(w-.09),-.50,z+.08,.073),
                    (s*(w-.27),-.52,z+.05,.054)],PALE if j%3 else BONE,seg=5,sub=1,smooth=False)
        # Small red/bone protrusions down the waist, rather than broad armor pads.
        for j in range(3):
            z=3.44+j*.21
            blade(p,[(s*.39,.09,z),(s*.63,-.02,z-.10),(s*.72,-.10,z-.28)],RED,.12)
    poly(p,[(-.39,3.51),(.39,3.51),(.45,3.25),(0,3.02),(-.45,3.25)],-.41,.15,FLESH)
    neck=part(a,'Neck')
    segment(neck,(0,.03,4.94),(0,-.025,5.65),.24,.26,RED)

    # One true skull. Front is built from plates surrounding open eye slots,
    # while the backing lies behind the slots; no extra floating heads.
    h=part(a,'Head')
    box(h,(0,.18,6.08),(1.19,.67,1.24),RED,bevel=.09,taper=.90)
    poly(h,[(-.61,6.29),(-.59,6.58),(-.25,6.82),(.27,6.76),(.60,6.54),(.61,6.28)],-.405,.16,BONE)
    # Asymmetric shallow red scars built into the frontal plates.
    poly(h,[(-.52,6.66),(-.21,6.76),(-.13,6.53),(-.30,6.43),(-.48,6.48)],-.498,.025,RED)
    poly(h,[(.32,6.67),(.53,6.54),(.56,6.29),(.45,6.32)],-.499,.025,FLESH)
    for s in (-1,1):
        # Angled cheek/jaw plates retain a human skull and leave actual eye gaps.
        poly(h,[(s*.09,6.10),(s*.56,6.10),(s*.53,5.78),(s*.23,5.48),(s*.12,5.66)],-.42,.17,BONE)
        poly(h,[(s*.12,6.10),(s*.51,6.15),(s*.51,6.24),(s*.13,6.22)],-.32,.05,BLACK)
        beam(h,(s*.12,-.55,6.13),(s*.52,-.50,6.17),.045,.05,BROWN)
    # Nose bridge and the long median split distinguish the skull from three masks.
    poly(h,[(-.075,6.63),(.085,6.63),(.12,5.66),(.035,5.57),(-.05,5.79)],-.54,.20,PALE)
    box(h,(.015,-.655,5.78),(.062,.035,.21),BLACK,bevel=.005)
    box(h,(-.018,-.655,6.57),(.056,.035,.29),BLACK,bevel=.005)
    # Compact mouth under the skull, with a separate jaw bone.
    poly(h,[(-.26,5.75),(.25,5.75),(.22,5.48),(-.19,5.45)],-.36,.10,BLACK)
    for i in range(4):
        x=(i-1.5)*.105
        poly(h,[(x-.036,5.72),(x+.036,5.72),(x+.017,5.61)],-.495,.065,PALE)
    jaw=part(a,'Jaw')
    poly(jaw,[(-.28,5.51),(.26,5.51),(.17,5.28),(-.14,5.28)],-.43,.26,RED)
    beam(jaw,(-.16,-.58,5.40),(.16,-.58,5.40),.10,.08,BONE)
    # Four short backward/radial bone struts form the crown around this ONE head.
    for s,side in ((-1,'R'),(1,'L')):
        for j in range(2):
            bn='Crown'+side+str(j+1)
            aa=(s*.48,.11,6.30+(j*.28))
            bb=(s*(1.16 if j==0 else .98),.30+(j*.22),6.15+(j*.73))
            bone(r,bn,aa,bb,'Head')
            pr=part(a,bn)
            beam(pr,aa,bb,.20,.27,RED)
            end=Vector(aa).lerp(Vector(bb),.67)
            beam(pr,end,bb,.21,.29,BONE)
            box(pr,bb,(.22,.30,.15),PALE,rot=(0,s*13,0),bevel=.017)
        # Thin curved arms and splayed hooked digits.
        shoulder=(s*.77,.035,4.90);elbow=(s*1.58,-.055,4.04);wrist=(s*2.73,-.48,3.61)
        for bn,aa,bb,ra,rb,col,parent in [
            ('Arm'+side,shoulder,elbow,.21,.20,RED,'Body'),
            ('Forearm'+side,elbow,wrist,.18,.11,DARK,'Arm'+side)]:
            bone(r,bn,aa,bb,parent);pr=part(a,bn);segment(pr,aa,bb,ra,rb,col)
        handname='Hand'+side;bone(r,handname,wrist,(s*2.96,-.61,3.18),'Forearm'+side)
        hand=part(a,handname)
        beam(hand,(s*1.93,-.48,3.76),(s*2.12,-.57,3.64),.24,.17,DARK)
        for j in range(3):
            xx=s*(1.98+j*.13);yy=-.58+j*.105
            blade(hand,[(xx,yy,3.72),(xx+s*.33,yy-.09,3.37),
                        (xx+s*.21,yy-.19,3.13),(xx+s*.03,yy-.23,3.20)],DARK,.066)
        blade(hand,[(s*1.99,-.39,3.75),(s*2.32,-.31,3.91),(s*2.57,-.26,3.87)],DARK,.065)
        for v in hand.bm.verts:
            v.co.x+=s*.8;v.co.z-=.15

    # One continuous U-shaped snake tail; there are NO leg bones or foot meshes.
    path=[(0,.08,3.27,.48),(0,.08,2.76,.49),(0,.10,2.20,.49),
          (0,.16,1.61,.48),(0,.30,1.04,.45),(0,.62,.58,.42),
          (0,1.14,.43,.39),(0,1.72,.60,.35),(0,2.21,1.02,.32),
          (0,2.56,1.57,.29),(0,2.78,2.19,.26),(0,2.94,2.82,.23),
          (0,3.04,3.41,.18),(0,3.08,3.91,.13),(0,3.11,4.47,.038)]
    skin=part(a,'TailSkin','Body')
    skin.tube(path,DARK,seg=8,sub=2,smooth=False)
    previous='Body'
    for i,(aa,bb) in enumerate(zip(path,path[1:])):
        bn='Tail'+str(i+1).zfill(2)
        bone(r,bn,aa[:3],bb[:3],previous)
        pr=part(a,bn) if i<13 else None
        va,vb=Vector(aa[:3]),Vector(bb[:3]);q=(vb-va).to_track_quat('Z','Y')
        # Low rectangular segment plates retain the source's stacked tail silhouette.
        mid=va.lerp(vb,.44);rr=(aa[3]+bb[3])/2
        if i<12:
            rotation=tuple(math.degrees(x) for x in q.to_euler())
            for t in (.24,.72):
                ringmid=va.lerp(vb,t)
                box(pr,ringmid,(rr*2.08,rr*1.93,(vb-va).length*.42),
                    '472A32' if i<7 else '672C36',rot=rotation,bevel=.025)
                for s in (-1,1):
                    patch=ringmid+q@Vector((s*rr*.91,-rr*.19,0))
                    box(pr,patch,(rr*.26,rr*1.37,(vb-va).length*.34),
                        MUSCLE if i<7 else FLESH,rot=rotation,bevel=.012)
        if i in (7,8,9,10,11,12):
            for s in (-1,1):
                aa2=mid+q@Vector((s*rr*.75,rr*.25,0))
                tip=mid+q@Vector((s*(rr+.39),rr*.29,.13))
                blade(pr,[aa2,tip],RED,.095)
        if i==8:
            # Three long thin dark rods on each side of the lower raised tail.
            for s in (-1,1):
                for j in range(3):
                    root=mid+Vector((s*.23,-.12+j*.13,0))
                    tip=root+Vector((s*(1.05-j*.13),.08+j*.23,.33-j*.33))
                    blade(pr,[root,tip],DARK,.057)
        previous=bn
    # Place the undersurface exactly on the ground; preserve root at ground level.
    minimum=min(v.co.z for pr in a.parts for v in pr.bm.verts)
    for pr in a.parts:
        for v in pr.bm.verts:v.co.z-=minimum
    for bn,(aa,bb,parent) in list(r.items()):
        if bn=='Root':continue
        r[bn]=((aa[0],aa[1],aa[2]-minimum),(bb[0],bb[1],bb[2]-minimum),parent)
    TAIL_PATH[:]=[Vector((x,y,z-minimum)) for x,y,z,radius in path]
    DETAILS[name]={'reference':2,'focus':(0,-.12,5.49-minimum),'close_scale':3.65,
        'interpretation':'Dredge: one executioner-like skull, four bone crown struts, two clawed arms, open ribs and one continuous coiled snake body. No walking legs or extra heads.'}


def build():dredge()


def skin_weights(part_name,position,default_bone):
    if part_name!='TailSkin':return {default_bone:1.0}
    p=Vector(position);best=None
    for i,(aa,bb) in enumerate(zip(TAIL_PATH,TAIL_PATH[1:])):
        ab=bb-aa;t=max(0,min(1,(p-aa).dot(ab)/ab.length_squared))
        distance=(p-(aa+ab*t)).length_squared
        if best is None or distance<best[0]:best=(distance,i,t)
    param=max(0,min(13,best[1]+best[2]-.5))
    i=int(param);w=param-i
    if i==13:return {'Tail14':1.0}
    return {'Tail'+str(i+1).zfill(2):1-w,'Tail'+str(i+2).zfill(2):w}
