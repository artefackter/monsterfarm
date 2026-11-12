"""A disembodied dealer: one huge hollow-eyed head and two independent human hands.

There are deliberately no torso, shoulders, forearms or legs. The tiny hidden Body
is solely the existing game's placement pivot, entirely inside the head.
"""
import math
import random
import bmesh
import bpy
import kit
from assets_deer import box, poly
from assets_horror_collection_v1 import mesh, JOINTS

SKIN='B7AA94'; LIGHT='D5C4A4'; SHADE='837765'; DARK='544638'


def hollow_sockets(p):
    """Boolean cavities with dark inner surfaces; no black eyeball or floating rim."""
    me=bpy.data.meshes.new('DealerSkullBoolean')
    p.bm.to_mesh(me)
    ob=bpy.data.objects.new('DealerSkullBoolean',me)
    bpy.context.scene.collection.objects.link(ob)
    for name in ('OuterSkin','SocketInterior'):
        me.materials.append(bpy.data.materials.new(name))
    for side in (-1,1):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=32,ring_count=20,location=(side*.80,-.75,4.82+side*.05))
        cutter=bpy.context.object;cutter.scale=(.60,.72,.68)
        cutter.data.materials.append(me.materials[0]);cutter.data.materials.append(me.materials[1])
        for face in cutter.data.polygons:face.material_index=1
        bpy.context.view_layer.objects.active=ob
        mod=ob.modifiers.new('Hollow eye socket','BOOLEAN');mod.operation='DIFFERENCE';mod.solver='EXACT';mod.object=cutter
        bpy.ops.object.modifier_apply(modifier=mod.name)
        bpy.data.objects.remove(cutter,do_unlink=True)
    p.bm.free();p.bm=bmesh.new();p.bm.from_mesh(ob.data)
    p.layer=p.bm.faces.layers.int.get('c') or p.bm.faces.layers.int.new('c')
    for face in p.bm.faces:face[p.layer]=p._cid('100F12' if face.material_index==1 else SKIN);face.smooth=False
    bpy.data.objects.remove(ob,do_unlink=True)


def loop(p,points,radius,color):
    p.tube([(*v,radius) for v in points+[points[0],points[1]]],color,seg=6,sub=2,smooth=True)


def hand(a,side,aggressive):
    # Short severed wrist, broad palm, four knuckled fingers and an opposing thumb.
    x=side*2.15; y=-.25-(.40 if aggressive else 0); z=1.03+(side*.16 if aggressive else 0)
    p=mesh(a,'ArmL' if side>0 else 'ArmR',(x,y,z))
    p.sphere((x,y+.07,z+.26),(.30,.23,.22),SHADE,sub=2,smooth=False)
    p.sphere((x,y,z),(.49,.24,.53),SKIN,sub=3,smooth=False)
    for j in range(4):
        xx=x+(j-1.5)*.235
        length=(.79,1.02,.94,.71)[j]
        bend=.32 if aggressive else .16
        pts=[(xx,y-.02,z-.31,.125),
             (xx+side*.045,y-bend,z-.57,.113),
             (xx+side*.07,y-bend-.13,z-.31-length*.70,.096),
             (xx+side*.05,y-bend+.08,z-.31-length,.073)]
        p.tube(pts,lambda i:LIGHT if i<3 else SKIN,seg=6,sub=1,smooth=False)
        p.sphere(pts[1][:3],.132,LIGHT,sub=1,smooth=False)
        tip=pts[-1]
        box(p,(tip[0],tip[1]-.055,tip[2]+.07),(.13,.035,.18),'DCD1B6',bevel=.012,rot=(10,0,0))
        # Short, fine crease across each visible proximal joint.
        box(p,(xx,y-.265,z-.43),(.13,.017,.024),SHADE,bevel=0)
    p.tube([(x-side*.36,y-.02,z+.13,.17),
            (x-side*.67,y-.20,z-.09,.15),
            (x-side*.73,y-.41,z-.43,.12),
            (x-side*.56,y-.50,z-.57,.085)],SKIN,seg=6,sub=1,smooth=False)
    return p


def dealer(state):
    a=kit.asset('BuckshotDealer_'+state);agg=state=='Aggressive'
    helper=mesh(a,'Body',transparency=1,cast=False)
    box(helper,(0,.2,4.05),(.08,.08,.08),'FFFFFF',bevel=0)
    h=mesh(a,'Head',(0,.15,4.05))
    h.sphere((0,.20,4.13),(1.97,1.18,2.02),SKIN,sub=4,smooth=False)
    hollow_sockets(h)
    # A high, bald forehead, sunken temples and asymmetric cheek planes.
    for side in (-1,1):
        h.sphere((side*1.39,-.56,3.91),(.60,.59,.79),SHADE,sub=2,smooth=False)
        h.sphere((side*1.54,-.90,3.98),(.40,.31,.57),SKIN,sub=2,smooth=False)
        x=side*.80;cz=4.82+side*.05
        for k in range(3):
            z=cz-.75-k*.075
            h.tube([(x-side*.36,-1.18,z+.07,.016),(x,-1.21,z-.05,.018),
                    (x+side*.40,-1.13,z+.04,.012)],DARK,seg=4,sub=1,smooth=False)
    # Small nose with dark nostrils, rather than a humanoid cartoon muzzle.
    poly(h,[(-.14,4.67),(-.25,4.16),(-.10,4.06),(.11,4.08),(.26,4.20),(.13,4.67)],-1.245,.29,SKIN,bevel=.04)
    for side in (-1,1):h.sphere((side*.17,-1.43,4.18),(.105,.035,.055),'42372D',sub=2)
    # Deep crescent mouth, separate rim and two irregular ranks of tapered teeth.
    drop=.27 if agg else 0
    outline=[(-1.66,4.05),(-1.40,3.78),(-.90,3.61),(-.32,3.55),(.35,3.57),(.94,3.68),(1.43,3.91),(1.64,4.15),
             (1.52,3.35-drop),(1.18,2.77-drop),(.55,2.37-drop),(-.10,2.25-drop),(-.78,2.44-drop),(-1.32,2.91-drop)]
    poly(h,outline,-1.25,.16,'0C0D10',bevel=.05)
    loop(h,[(x,-1.38,z) for x,z in outline],.105,SHADE)
    rng=random.Random(923)
    for row in ('upper','lower'):
        count=15 if row=='upper' else 13
        for j in range(count):
            x=-1.43+j*2.86/(count-1)
            edge=abs(x)/1.5
            z=(3.54+.39*edge**1.5) if row=='upper' else (2.28-drop+.83*edge**1.8)
            length=rng.uniform(.45,.88)*(1.05 if agg else .86)
            width=rng.uniform(.11,.19)
            tipx=x+rng.uniform(-.16,.16)
            tipz=z-length if row=='upper' else z+length
            # A four-sided, crooked fang with a fine tip, not a soft cone.
            y=-1.47-rng.uniform(0,.075)
            h.loft([[(x-width*.5,y-.055,z),(x+width*.5,y-.055,z),
                     (x+width*.5,y+.085,z),(x-width*.5,y+.085,z)],
                    [(x-width*.34,y-.06,z+(tipz-z)*.46),(x+width*.34,y-.06,z+(tipz-z)*.46),
                     (x+width*.34,y+.04,z+(tipz-z)*.46),(x-width*.34,y+.04,z+(tipz-z)*.46)],
                    [(tipx,y-.04,tipz)]*4],lambda i:LIGHT if i==0 else 'E8D7AE',smooth=False)
    # Thin deep cheek creases reinforce the grotesque smile without extra props.
    for side in (-1,1):
        h.tube([(side*1.31,-1.20,4.19,.023),(side*1.62,-1.22,4.08,.025),
                (side*1.73,-1.12,3.75,.012)],DARK,seg=4,sub=1,smooth=False)
    hand(a,-1,agg);hand(a,1,agg)
    return a
