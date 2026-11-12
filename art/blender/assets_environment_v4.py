"""Warm garden environment. Geometry in studs, Z up. Original modular meshes."""
import math, random
import bmesh
from mathutils import Vector, Matrix, Euler
import kit

WOOD='B58448'; LIGHTWOOD='D3A263'; DARKWOOD='8E6037'
STONE='D5C39C'; SAND=['DCC39A','E8CEA6','DFC39B','D6BB94']
LEAVES=['78962A','8EA831','A0B637','ADC140','839D2B']

def beam(p,a,b,w,d,col):
    a,b=Vector(a),Vector(b)
    rot=(b-a).to_track_quat('Z','Y').to_euler()
    p.box((a+b)/2,(w,d,(b-a).length),col,rot=tuple(math.degrees(v) for v in rot),bevel=.04,seg=1)

def leaf(p,c,r,rot,col,phase=0):
    # A thick, gently domed five-lobed leaf cluster: no alpha cards or double-sided planes.
    bm=bmesh.new();n=24;bottom=[];top=[]
    for i in range(n):
        a=i*math.tau/n;rad=r*(.84+.16*math.cos(5*a+phase))
        x,y=math.cos(a)*rad,math.sin(a)*rad*.80
        bottom.append(bm.verts.new((x,y,-.025)))
        top.append(bm.verts.new((x,y,.045)))
    ct=bm.verts.new((0,0,r*.19));cb=bm.verts.new((0,0,-.055))
    for i in range(n):
        j=(i+1)%n
        bm.faces.new((ct,top[i],top[j]))
        bm.faces.new((cb,bottom[j],bottom[i]))
        bm.faces.new((bottom[i],bottom[j],top[j],top[i]))
    bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
    p._merge(bm,kit._mat(c,rot),col,True)

def tree(name,seed,scale=1):
    rng=random.Random(seed);a=kit.asset(name)
    trunk=a.part('Trunk',ao=.35,grad=.10)
    trunk.tube([(0,0,0,.80),(.12,.02,1.2,.63),(-.18,.1,3.2,.49),(.15,.13,5.5,.40),(.1,.18,7.9,.22),(.4,0,9.7,.06)],'90603A',seg=9,sub=2)
    for i in range(6):
        t=i*math.tau/6+.1
        trunk.tube([(math.cos(t)*1.2,math.sin(t)*1.2,.08,.22),(math.cos(t)*.65,math.sin(t)*.65,.46,.33),(0,0,1.8,.32)],'98683F',seg=6,sub=2)
    clusters=[]
    for i in range(7):
        ang=i*math.tau/7+.35;rad=rng.uniform(2.0,3.3);z=rng.uniform(7.7,9.6)
        c=Vector((math.cos(ang)*rad,math.sin(ang)*rad,z));clusters.append((c,rng.uniform(2.1,2.5)))
        trunk.tube([(.1,.1,4.7,.32),tuple(c*.53+Vector((0,0,2.0)))+(.23,),tuple(c)+(.06,)],'A17442',seg=7,sub=2)
    clusters.extend([(Vector((-.6,.4,11.05)),2.6),(Vector((.9,-.5,9.8)),2.5)])
    crown=a.part('Canopy',ao=.24,ao_dist=.8,grad=.16)
    for k,(c,r) in enumerate(clusters):
        crown.sphere(c,(r*.91,r*.9,r*.63),LEAVES[k%len(LEAVES)],sub=2)
        for j in range(10):
            t=j*2.39996+k*.37;uz=-.20+j/9*1.18
            xy=math.sqrt(max(.05,1-uz*uz))
            point=c+Vector((math.cos(t)*r*xy,math.sin(t)*r*xy,uz*r*.65))
            # Outward-facing leaves overlap the crown, preserving a broad scalloped silhouette.
            normal=Vector((math.cos(t)*xy,math.sin(t)*xy,max(.24,uz))).normalized()
            rot=normal.to_track_quat('Z','Y').to_euler()
            col=LEAVES[min(4,max(0,int((uz+.3)*3)+rng.randrange(-1,2)))]
            leaf(crown,point,rng.uniform(1.05,1.40),tuple(math.degrees(v) for v in rot),col,phase=rng.random()*6)
    # Subtle bark ridges are geometry, not costly per-instance textures.
    for t in (.2,2.4,4.5):
        trunk.tube([(math.cos(t)*.59,math.sin(t)*.59,.65,.045),(math.cos(t)*.46,math.sin(t)*.46,2.4,.033),(-.12+math.cos(t)*.39,.1+math.sin(t)*.39,3.7,.015)],'AD7D4B',seg=5,sub=2)
    if scale!=1:
        for p in a.parts:
            for v in p.bm.verts:v.co*=scale
            p.bm.normal_update()

def stone_post(p,x=0):
    p.box((x,0,.15),(1.22,1.18,.30),'C2AF8B',bevel=.08)
    p.box((x,0,1.57),(.87,.86,2.60),STONE,bevel=.075,seg=1)
    p.box((x,0,2.96),(1.03,1.01,.24),'E7D6B5',bevel=.055)
    p.box((x,-.44,.65),(.86,.025,.035),'B3A17F',bevel=0)

def fence():
    a=kit.asset('ENV_Fence');p=a.part('Main',ao=.45)
    stone_post(p,-4)
    p.box((0,0,1.30),(.43,.49,2.6),WOOD,bevel=.045)
    p.box((0,0,2.61),(.48,.54,.15),LIGHTWOOD,rot=(0,7,0),bevel=.025)
    for z in (.90,1.93):
        p.box((0,.08,z),(8,.22,.27),LIGHTWOOD,bevel=.035)
        p.box((0,-.055,z-.08),(8,.025,.055),DARKWOOD,bevel=.009)
        p.cyl((0,-.083,z),.045,.045,.025,'715238',rot=(90,0,0),seg=8)
    a=kit.asset('ENV_FencePost');stone_post(a.part('Main'))
    a=kit.asset('ENV_Gate');p=a.part('Main')
    for x in (-5.8,5.8):
        stone_post(p,x)
        p.box((x,0,2.6),(.95,.95,4.6),STONE,bevel=.07)
        p.box((x,0,4.93),(1.17,1.13,.25),'E7D6B5',bevel=.06)
    p.tube([(-5.3,0,4.1,.32),(-3,0,5.7,.32),(0,0,6.5,.32),(3,0,5.7,.32),(5.3,0,4.1,.32)],LIGHTWOOD,seg=8,sub=3)

def tile_geometry(p,c,seed,w=3.8,d=3.8):
    rng=random.Random(seed);x,y,z=c;cut=.22
    pts=[(-w/2+cut,-d/2),(w/2-cut,-d/2),(w/2,-d/2+cut),(w/2,d/2-cut),(w/2-cut,d/2),(-w/2+cut,d/2),(-w/2,d/2-cut),(-w/2,-d/2+cut)]
    pts=[(px+rng.uniform(-.045,.045),py+rng.uniform(-.045,.045)) for px,py in pts]
    rings=[[(x+px,y+py,z+.015) for px,py in pts],[(x+px,y+py,z+.15) for px,py in pts],[(x+px*.97,y+py*.97,z+.23) for px,py in pts]]
    color=SAND[seed%len(SAND)]
    p.loft(rings,lambda i:'C1A477' if i==0 else color,smooth=False)

def tiles():
    for i in range(3):
        a=kit.asset('ENV_Tile'+str(i+1));tile_geometry(a.part('Main',ao=.15,grad=0,cast=False),(0,0,0),i)
    # Identical span to existing W_Path runs, so the island approaches retain their endpoints.
    a=kit.asset('ENV_Path');p=a.part('Main',ao=.15,grad=0,cast=False)
    for i in range(6):tile_geometry(p,(0,i*3.75,0),i+4,w=4.2,d=3.69)

def plants():
    a=kit.asset('ENV_Bush');p=a.part('Main',ao=.25,grad=.12);rng=random.Random(19)
    for i in range(5):
        t=i*2.4;c=Vector((math.cos(t)*.68,math.sin(t)*.68,.66+(i%2)*.3))
        p.sphere(c,(.85,.75,.70),LEAVES[i],sub=2)
        for j in range(6):
            t=j*2.4+i;v=c+Vector((math.cos(t)*.65,math.sin(t)*.65,.38))
            leaf(p,v,.50,(rng.uniform(-35,35),rng.uniform(-35,35),rng.uniform(0,360)),LEAVES[(i+j)%5])
    a=kit.asset('ENV_Tuft');p=a.part('Main',ao=.15,grad=.08)
    for i in range(9):
        t=i*2.4;r=.35+(i%3)*.1;h=.5+(i%4)*.16
        p.tube([(0,0,0,.08),(math.cos(t)*r*.5,math.sin(t)*r*.5,h*.65,.07),(math.cos(t)*r,math.sin(t)*r,h,.005)],LEAVES[i%5],seg=4,sub=2)

def build():
    tree('ENV_TreeA',21,1.32);tree('ENV_TreeB',52,1.08);tree('ENV_TreeC',76,1.48)
    fence();tiles();plants()
