"""Dealer revision from the supplied model sheet: pale mask, living jaw and detached hands."""
import math,random
import bpy,bmesh
from mathutils import Vector,Matrix
import kit
from assets_deer import box,poly
from assets_horror_collection_v1 import mesh,JOINTS

SKIN='E3DFD4';PINK='BD8D8B';RIM='88656A';BLACK='100D13';TOOTH='CFCFC0'

def curve(x,aggressive,upper):
    edge=abs(x)/2.05
    return 4.06+.65*edge**1.6 if upper else (2.13+2.34*edge**1.8 if aggressive else 3.10+1.37*edge**1.8)

def carve_eyes(p):
    me=bpy.data.meshes.new('PaleMask');p.bm.to_mesh(me)
    ob=bpy.data.objects.new('PaleMask',me);bpy.context.scene.collection.objects.link(ob)
    for name in ('Skin','Black sockets'):me.materials.append(bpy.data.materials.new(name))
    for side in (-1,1):
        cut=kit.asset('_socket').part('cut')
        shape=[(-.54,-.32),(-.57,.15),(-.30,.58),(.14,.64),(.43,.32),(.49,-.20),(.25,-.55),(-.12,-.59)]
        cx=side*.88;cz=5.27+(side*.055)
        rings=[]
        for y,k in [(-2.0,1.0),(-.30,1.0),(.18,.72)]:
            rings.append([(cx+side*dx*k,y,cz+dz*k) for dx,dz in shape])
        cut.loft(rings,BLACK,smooth=False)
        cm=bpy.data.meshes.new('cut');cut.bm.to_mesh(cm);co=bpy.data.objects.new('cut',cm)
        bpy.context.scene.collection.objects.link(co)
        cm.materials.append(me.materials[0]);cm.materials.append(me.materials[1])
        for f in cm.polygons:f.material_index=1
        bpy.context.view_layer.objects.active=ob
        mod=ob.modifiers.new('Recessed irregular socket','BOOLEAN');mod.operation='DIFFERENCE';mod.solver='EXACT';mod.object=co
        bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(co,do_unlink=True)
        cut.bm.free();kit.ASSETS.pop('_socket',None)
    p.bm.free();p.bm=bmesh.new();p.bm.from_mesh(ob.data)
    p.layer=p.bm.faces.layers.int.get('c') or p.bm.faces.layers.int.new('c')
    for f in p.bm.faces:f[p.layer]=p._cid(BLACK if f.material_index==1 else SKIN);f.smooth=False
    bmesh.ops.triangulate(p.bm,faces=list(p.bm.faces))
    front=[e for e in p.bm.edges if all(v.co.y<-.80 for v in e.verts)]
    bmesh.ops.subdivide_edges(p.bm,edges=front,cuts=2,use_grid_fill=True)
    for v in p.bm.verts:
        if v.co.y<-.80:
            x,z=v.co.x,v.co.z
            brow=.15*math.exp(-((z-5.88)/.65)**2)*max(0,1-(x/2.15)**2)
            cheek=.10*math.exp(-((abs(x)-1.50)/.4)**2-((z-4.84)/.35)**2)
            v.co.y-=brow+cheek
    for f in p.bm.faces:
        if f[p.layer]!=p._cid(BLACK):
            f[p.layer]=p._cid(SKIN)
        f.smooth=True
    p.bm.normal_update()
    bpy.data.objects.remove(ob,do_unlink=True)

def hand(a,side,aggressive):
    wrist=Vector((side*2.4,-.05,1.46))
    p=mesh(a,'ArmL' if side>0 else 'ArmR',tuple(wrist));p.ao=.12
    outline=[(math.cos(j*math.tau/14),math.sin(j*math.tau/14)) for j in range(14)]
    rings=[]
    for z,w,d in [(1.52,.23,.12),(1.22,.34,.17),(.93,.43,.18),(.66,.40,.12)]:
        rings.append([(u*w,v*d,z) for u,v in outline])
    p.loft(rings,lambda i:['CBC4B9',SKIN,'D7CDC4'][i],smooth=True)
    for i,(offset,length) in enumerate([(-.30,.70),(-.10,.99),(.105,.91),(.30,.67)]):
        fan=(i-1.5)*(.09 if aggressive else .035)
        curl=.30 if aggressive else .17
        pts=[(offset,-.025,.73,.112),(offset+fan*.35,-.055,.51,.108),
             (offset+fan*.75,-curl,.73-length*.64,.087),
             (offset+fan,-curl-.035,.73-length,.061)]
        p.tube(pts,lambda j:SKIN if j<3 else 'D7CBC3',seg=7,sub=2,smooth=True)
        for point,r in [(pts[0],.119),(pts[1],.115),(pts[2],.091)]:p.sphere(point[:3],(r,r*.9,r*1.15),'DED5CC',sub=2,smooth=True)
        end=pts[-1]
        box(p,(end[0],end[1]+.042,end[2]+.085),(.095,.029,.14),'DDD3C7',bevel=.02,rot=(12,0,0))
        for z in (.50,.73-length*.64):
            p.tube([(offset-.055,.108,z,.008),(offset,.13,z-.017,.009),(offset+.055,.10,z,.006)],'A79A97',seg=4,sub=1)
    p.tube([(-.30,0,1.18,.17),(-.53,-.035,1.01,.145),(-.65,-.20,.77,.115),
            (-.53,-.28,.58,.071)],SKIN,seg=7,sub=2,smooth=True)
    # Palm and back-of-hand tendons are subtle, irregular lines rather than hard finger blocks.
    for i in range(3):
        x=(i-1)*.17
        p.tube([(x*.3,.113,1.40,.014),(x,.145,1.03,.019),(x,.12,.74,.012)],'C5B7B3',seg=4,sub=1)
    rot=Matrix.Rotation(math.radians(side*(18 if aggressive else 26)),3,'Y') @ Matrix.Rotation(math.radians(-13 if aggressive else -23),3,'X')
    for v in p.bm.verts:
        co=rot@(v.co-Vector((0,0,1.46)))
        co.x*=side
        v.co=wrist+co
    minimum=min(v.co.z for v in p.bm.verts)
    if minimum<.04:
        for v in p.bm.verts:v.co.z+=.04-minimum
        JOINTS[a.name][p.name][1]+=.04-minimum
    p.bm.normal_update()

def dealer(state):
    agg=state=='Aggressive';a=kit.asset('BuckshotDealer_'+state)
    helper=mesh(a,'Body',transparency=1,cast=False);box(helper,(0,0,4.5),(.08,.08,.08),'FFFFFF',bevel=0)
    h=mesh(a,'Head',(0,0,4.5));h.ao=.13;h.ao_dist=.20;h.grad=.045
    def tint_face(co,color):
        skin=kit._rgb(SKIN)
        if max(abs(color[i]-skin[i]) for i in range(3))<.001:
            k=max(0,min(1,(5.20-co.z)/1.0))*.30
            pink=kit._rgb(PINK)
            return tuple(color[i]*(1-k)+pink[i]*k for i in range(3))
        return color
    h.colfn=tint_face
    # A shallow sculpted upper face, not a ball. The lower boundary is the extreme smile line.
    crown=[(-2.08,4.66),(-1.98,5.21),(-1.60,5.89),(-.91,6.25),(-.20,6.34),
           (.53,6.30),(1.18,6.10),(1.73,5.63),(2.01,5.12),(2.10,4.68)]
    lip=[(x,curve(x,agg,True)) for x in [2.05,1.75,1.40,1.0,.55,0,-.55,-1,-1.4,-1.75,-2.05]]
    outline=crown+lip
    def ring(y,sx,sz):return [(x*sx,y,5.0+(z-5.0)*sz) for x,z in outline]
    h.loft([ring(.67,.74,.91),ring(.31,1.0,1.0),ring(-.57,1.015,1.005),ring(-.93,.98,.99)],
           lambda i:['B2A7A4','C9C6C0',SKIN][i],smooth=False,cap_start=True,cap_end=True)
    carve_eyes(h)
    # The flesh around the grin is pink and thin; there are no separate spherical cheek pads.
    upper=[(x,-.965,curve(x,agg,True)) for x in [(-2.05+i*4.10/24) for i in range(25)]]
    lower=[(x,-.97,curve(x,agg,False)) for x in [(2.05-i*4.10/24) for i in range(25)]]
    edge=upper+lower
    center_z=3.55 if agg else 3.94
    outer=[(x*1.035,y+.08,z+(.08 if i<25 else -.22*(1-(abs(x)/2.1)**2)-.07)) for i,(x,y,z) in enumerate(edge)]
    inner=[(x*.966,y-.01,center_z+(z-center_z)*.925) for x,y,z in edge]
    throat=[(x*.87,-.38,center_z+(z-center_z)*.82) for x,y,z in inner]
    h.loft([outer,edge,inner,throat],lambda i:[SKIN,PINK,RIM][i],cap_start=False,cap_end=True,smooth=False)
    poly(h,[(x,z) for x,y,z in throat],-.365,.035,BLACK,bevel=0)
    # Small human nose: a narrow bridge and a pink, downward-facing tip.
    nose=[]
    for z,w,d in [(5.59,.06,.03),(5.22,.075,.06),(4.86,.10,.11),(4.65,.22,.22),(4.46,.10,.11)]:
        nose.append([(-w,-.99,z),(-w*.7,-.99-d*.7,z),(0,-.99-d,z),
                     (w*.7,-.99-d*.7,z),(w,-.99,z),(0,-.90,z)])
    h.loft(nose,lambda i:'D7CDC5' if i<2 else 'C5A7A2',smooth=True)
    h.sphere((.01,-1.20,4.64),(.13,.083,.085),'C59D99',sub=2,smooth=True)
    for s in (-1,1):h.sphere((s*.13,-1.16,4.58),(.058,.035,.038),'6D5155',sub=1,smooth=False)
    # Uneven interlocking needle teeth follow the actual grin and recede into its depth.
    rng=random.Random(557)
    for row in range(2):
        count=21 if row==0 else 17
        for top in (True,False):
            for i in range(count):
                x=-1.93+i*3.86/(count-1)+rng.uniform(-.025,.025)
                z=curve(x,agg,top)
                gap=curve(x,agg,True)-curve(x,agg,False)
                length=min(rng.uniform(.40,.88),gap*rng.uniform(.43,.77))
                if row: length*=.78
                sign=-1 if top else 1
                y=-1.00+row*.19;w=rng.uniform(.045,.085)*(1 if row==0 else .77)
                dx=rng.uniform(-.11,.11)
                roots=[(x-w,y-.035,z),(x+w,y-.035,z),(x+w,y+.045,z),(x-w,y+.045,z)]
                middle=[(x-w*.5+dx*.4,y-.055,z+sign*length*.5),(x+w*.5+dx*.4,y-.055,z+sign*length*.5),
                        (x+w*.5+dx*.4,y+.018,z+sign*length*.5),(x-w*.5+dx*.4,y+.018,z+sign*length*.5)]
                h.loft([roots,middle,[(x+dx,y+.08,z+sign*length)]*4],
                       lambda j:TOOTH if row==0 else '9C9C91',smooth=False)
    # Fine face creases and asymmetric temple cracks, kept shallow enough for the game silhouette.
    for s in (-1,1):
        for path in [[(s*.42,-.95,5.97),(s*.34,-.965,5.70),(s*.40,-.96,5.50)],
                     [(s*1.55,-.955,5.05),(s*1.64,-.96,4.86),(s*1.94,-.94,4.70)],
                     [(s*.53,-.95,4.81),(s*.58,-.96,4.60),(s*.82,-.96,4.48)]]:
            h.tube([(*v,.009 if i!=1 else .014) for i,v in enumerate(path)],'947F80',seg=4,sub=1)
    hand(a,-1,agg);hand(a,1,agg)
    return a
