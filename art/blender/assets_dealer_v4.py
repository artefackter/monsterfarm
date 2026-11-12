"""Dealer V4: sculpted cranium, recessed sockets, a volumetric retracting jaw, detached hands."""
import math,random
import bpy,bmesh
from mathutils import Vector,Matrix
import kit
from assets_deer import box
from assets_horror_collection_v1 import mesh,JOINTS
import assets_dealer_v3 as old

SKIN='DDD9D0';PINK='BC9291';GUM='77535B';BLACK='0D0C11';BONE='D4D0BC'
WIDTH=1.74

def top(x):return 4.18+.57*(abs(x)/WIDTH)**1.65
def bottom(x,agg):return (2.04+2.50*(abs(x)/WIDTH)**1.8) if agg else (3.03+1.50*(abs(x)/WIDTH)**1.8)
def depth(x):return -1.025+.51*(abs(x)/WIDTH)**2
def mouth_outline(agg,count=30):
    xs=[-WIDTH+2*WIDTH*j/count for j in range(count+1)]
    return [(x,depth(x),top(x)) for x in xs]+[(x,depth(x),bottom(x,agg)) for x in reversed(xs)]

def cuts(p,agg):
    me=bpy.data.meshes.new('SculptedDealer');p.bm.to_mesh(me)
    ob=bpy.data.objects.new('SculptedDealer',me);bpy.context.scene.collection.objects.link(ob)
    for name in ('Skin','Cavity'):me.materials.append(bpy.data.materials.new(name))
    cutters=[]
    for side in (-1,1):
        cut=kit.asset('_cut').part('socket')
        # The sockets are irregular, narrower below, and not symmetric in height or contour.
        shape=[(-.46,-.35),(-.53,.07),(-.33,.47),(-.04,.60),(.28,.48),(.46,.16),(.42,-.30),(.15,-.51),(-.18,-.51)]
        cx=side*.73;cz=5.27+side*.055
        cut.loft([[(cx+side*x*k,y,cz+z*k) for x,z in shape] for y,k in [(-2,1),(-.22,1),(.32,.66)]],BLACK,smooth=False)
        cutters.append(cut)
    cut=kit.asset('_mouth').part('mouth')
    outline=mouth_outline(agg)
    cut.loft([[(x*1.005,-2.2,z) for x,y,z in outline],[(x*.96,.26,3.8+(z-3.8)*.98) for x,y,z in outline]],BLACK,smooth=False)
    cutters.append(cut)
    for cut in cutters:
        cm=bpy.data.meshes.new('cut');cut.bm.to_mesh(cm)
        co=bpy.data.objects.new('cut',cm);bpy.context.scene.collection.objects.link(co)
        cm.materials.append(me.materials[0]);cm.materials.append(me.materials[1])
        for f in cm.polygons:f.material_index=1
        bpy.context.view_layer.objects.active=ob
        mod=ob.modifiers.new('Deep cavity','BOOLEAN');mod.operation='DIFFERENCE';mod.solver='EXACT';mod.object=co
        bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(co,do_unlink=True);cut.bm.free()
    kit.ASSETS.pop('_cut',None);kit.ASSETS.pop('_mouth',None)
    p.bm.free();p.bm=bmesh.new();p.bm.from_mesh(ob.data)
    p.layer=p.bm.faces.layers.int.get('c') or p.bm.faces.layers.int.new('c')
    for f in p.bm.faces:f[p.layer]=p._cid(BLACK if f.material_index==1 else SKIN);f.smooth=False
    bpy.data.objects.remove(ob,do_unlink=True)

def fang(p,x,z,upper,agg,row,rng):
    gap=top(x)-bottom(x,agg)
    length=min(rng.uniform(.49,1.0),gap*rng.uniform(.43,.78))*(.78 if row else 1)
    width=rng.uniform(.055,.095)*(1 if row==0 else .70)
    y=depth(x)-.05+row*.19
    direction=-1 if upper else 1
    bend=rng.uniform(-.12,.12)
    rings=[]
    for t,scale in [(0,1),(.47,.66),(.82,.28),(1,.008)]:
        center=Vector((x+bend*t,y+.18*t*t,z+direction*length*t))
        rings.append([center+Vector((math.cos(j*math.tau/5)*width*scale,math.sin(j*math.tau/5)*width*.63*scale,0)) for j in range(5)])
    p.loft(rings,lambda i:BONE if row==0 else '9A9D91',smooth=False)

def dealer(state):
    agg=state=='Aggressive';a=kit.asset('BuckshotDealer_'+state)
    helper=mesh(a,'Body',transparency=1,cast=False);box(helper,(0,.15,4.62),(.08,.08,.08),'FFFFFF',bevel=0)
    h=mesh(a,'Head',(0,.15,4.62));h.ao=.20;h.ao_dist=.25;h.grad=.035
    # Broad, bald head with cheekbones sculpted into its surface instead of attached cheek balls.
    h.sphere((0,.12,4.80),(1.84,1.11,1.62),SKIN,sub=4,smooth=False)
    for v in h.bm.verts:
        x,y,z=v.co
        if y<.12:
            front=max(0,min(1,(.12-y)/.9))
            cheek=.14*math.exp(-((abs(x)-1.17)/.38)**2-((z-4.97)/.38)**2)
            temple=.055*math.exp(-((abs(x)-1.56)/.24)**2-((z-5.4)/.4)**2)
            v.co.y-=cheek*front;v.co.x*=1+temple
        if z>6.0:v.co.z=6.0+(z-6.0)*.86
    cuts(h,agg)
    edge=mouth_outline(agg);middle=3.60 if agg else 3.94
    half=len(edge)//2
    outer=[(x*1.047,y+.10,z+(.09 if i<half else -.22*(1-(abs(x)/1.8)**2)-.08)) for i,(x,y,z) in enumerate(edge)]
    back=[(x*.88,y+.68,middle+(z-middle)*.90) for x,y,z in outer]
    lip=[(x*1.006,y-.025,z) for x,y,z in edge]
    inside=[(x*.94,y+.07,middle+(z-middle)*.93) for x,y,z in edge]
    throat=[(x*.83,.35,middle+(z-middle)*.80) for x,y,z in edge]
    # A thick lower jaw with its own rear and underside; the mouth wraps around the cheeks in depth.
    h.loft([back,outer,lip,inside,throat],lambda i:[SKIN,PINK,GUM,'17131A'][i],smooth=False,cap_start=False,cap_end=True)
    # Two-sided rear closure: dark toward the mouth, pale toward the back of the head.
    h.loft([back,[(x,y+.018,z) for x,y,z in back]],BLACK,smooth=False,cap_start=True,cap_end=True)
    h.loft([[(x,y+.026,z) for x,y,z in back],[(x,y+.044,z) for x,y,z in back]],SKIN,smooth=False,cap_start=True,cap_end=True)
    # Low, crooked human nose, integrated into the centre of the face.
    sections=[]
    for z,w,d,y in [(5.53,.07,.035,-.84),(5.18,.09,.06,-.97),(4.88,.10,.12,-1.00),
                     (4.71,.21,.25,-1.01),(4.55,.12,.14,-.99)]:
        sections.append([(-w,y,z),(-w*.68,y-d*.65,z),(0,y-d,z),(w*.68,y-d*.65,z),(w,y,z),(0,y+.09,z)])
    h.loft(sections,lambda i:'CCC5BE' if i<2 else 'B99593',smooth=False)
    h.sphere((0,-1.22,4.71),(.125,.075,.075),'BD9793',sub=2,smooth=False)
    for s in (-1,1):
        h.sphere((s*.12,-1.13,4.65),(.075,.06,.06),'BE9995',sub=2,smooth=False)
        h.sphere((s*.10,-1.19,4.614),(.048,.018,.025),'46343A',sub=1,smooth=False)
    # Irregular nested rows follow the changing jaw opening and curve backwards into the throat.
    rng=random.Random(601)
    for row,count in [(0,21),(1,17)]:
        for upper in (True,False):
            for j in range(count):
                x=-1.62+3.24*j/(count-1)+rng.uniform(-.025,.025)
                fang(h,x,top(x) if upper else bottom(x,agg),upper,agg,row,rng)
    skin_rgb=kit._rgb(SKIN);pink_rgb=kit._rgb(PINK)
    def complexion(co,color):
        if max(abs(color[i]-skin_rgb[i]) for i in range(3))<.001:
            blush=.24*math.exp(-((co.z-4.82)/.55)**2)*max(0,min(1,(-co.y+.2)/1.1))
            grain=.014*math.sin(co.x*27+co.z*19)*math.sin(co.z*37-co.y*11)
            return tuple(color[i]*(1-blush)+pink_rgb[i]*blush+grain for i in range(3))
        return color
    h.colfn=complexion
    for side in (-1,1):
        old.hand(a,side,agg)
        p=a.parts[-1];pivot=Vector(kit.to_rbx(JOINTS[a.name][p.name]))
        turn=Matrix.Rotation(math.radians(side*(16 if agg else 30)),3,'Z') @ Matrix.Rotation(math.radians(side*-20),3,'Y')
        for v in p.bm.verts:v.co=pivot+turn@(v.co-pivot)
        bmesh.ops.recalc_face_normals(p.bm,faces=list(p.bm.faces));p.bm.normal_update()
        minimum=min(v.co.z for v in p.bm.verts)
        if minimum<.04:
            shift=.04-minimum
            for v in p.bm.verts:v.co.z+=shift
            JOINTS[a.name][p.name][1]+=shift
    return a
