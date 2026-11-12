"""Second approval pass: organic deer faces and a weight-bearing RingMaw."""
import math

from mathutils import Matrix, Vector

import assets_monster_prototypes as base
import kit
import claw_geometry
from assets_deer import beam, box, poly, ring

JOINTS = base.JOINTS


def deer_face(asset, role):
    head = base.part(asset, "Head", (0, -.43, 4.84), ao=.32, ao_dist=.40)
    glints = base.part(asset, "EyesGlow", attach="Head", material="Neon",
                       ao=0, grad=0, cast=False)
    # Broad temple and brow give way to narrow cheeks and an extended nose bridge.
    base.torso(head, [(4.92,-.50,.29,.28),(5.26,-.53,.47,.41),
                      (5.65,-.53,.63,.49),(6.05,-.46,.61,.45),
                      (6.35,-.37,.44,.36),(6.47,-.28,.22,.26)],
               ["644034","724637","90553D","A36849","895339"])
    for side in (-1,1):
        raise_ear = .10 if side < 0 else -.09
        ear = [(side*.46,-.47,6.01),(side*.68,-.46,6.31+raise_ear),
               (side*1.13,-.41,6.32+raise_ear),(side*1.10,-.37,6.14+raise_ear),
               (side*.89,-.36,5.94+raise_ear),(side*.58,-.40,5.81)]
        head.loft([ear,[(x*.97,y+.21,z-.04) for x,y,z in ear]],
                  "754634",smooth=False)
        poly(head,[(side*.62,5.98),(side*.77,6.22+raise_ear),
                   (side*1.04,6.24+raise_ear),(side*.93,6.00+raise_ear),
                   (side*.80,5.97+raise_ear)],-.493,.055,"C48679",bevel=.025)

        eye_x = side*(.334 if side<0 else .346)
        eye_z = 6.01 + side*.035
        # Large pale sclera and dark pupils follow the reference's stare.
        head.sphere((eye_x,-.913,eye_z),(.334,.233,.342),"472825",sub=2,smooth=False)
        head.sphere((eye_x,-1.076,eye_z),(.266,.163,.293),
                    "E8DAC2",rot=(0,side*12,0),sub=3)
        iris_x=eye_x-side*.058
        iris_z=eye_z+.031
        head.sphere((iris_x,-1.224,iris_z),(.178,.064,.212),
                    "6A3122",rot=(0,side*16,0),sub=3)
        head.sphere((iris_x-side*.015,-1.273,iris_z+.015),(.143,.055,.184),
                    "16151B",rot=(0,side*15,0),sub=3)
        glints.sphere((iris_x-.058,-1.321,iris_z+.094),
                      (.044,.022,.052),"FFEFD7",sub=2)
        # Integrated upper eyelid, peaked at the temple and tilted down towards the nose.
        base.faceted(head,[(side*.097,-1.172,6.041,.089),
                           (side*.242,-1.222,6.161,.096),
                           (side*.413,-1.123,6.287,.104),
                           (side*.576,-.937,6.258,.113),
                           (side*.633,-.799,6.128,.078)],
                      ["563323","6D412C","80513A","875B42"],6)
        base.faceted(head,[(side*.115,-1.043,5.876,.070),
                           (side*.305,-1.080,5.754,.093),
                           (side*.513,-.996,5.808,.100),
                           (side*.620,-.839,5.930,.096)],
                      ["8C5942","A87558","80513D"],6)
        head.sphere((side*.48,-.795,5.58),(.22,.218,.265),
                    "895A44",rot=(0,side*22,0),sub=2,smooth=False)

    # The cream muzzle joins a drooping oval jaw with a dark, recessed cavity.
    shape=[(-.31,5.68),(-.41,5.46),(-.37,5.13),(-.31,4.83),
           (-.22,4.66),(-.08,4.58),(.09,4.58),(.25,4.69),
           (.33,4.93),(.39,5.27),(.38,5.51),(.25,5.70),(0,5.76)]
    profiles=[
        (-1.004,.95,.94),(-1.319,1,1),(-1.365,.84,.85),
        (-1.236,.72,.79),(-1.145,.59,.72),
    ]
    rows=[[(x*sx,y-(z-5.05)*.185,5.16+(z-5.16)*sz) for x,z in shape]
          for y,sx,sz in profiles]
    head.loft(rows,lambda i:["AB7957","D8AB85","704A43","261D22"][i],
              cap_start=True,cap_end=True,smooth=False)
    head.sphere((0,-1.355,5.738),(.263,.230,.222),
                "CFAA83",rot=(-10,0,0),sub=2,smooth=False)
    head.sphere((.008,-1.550,5.791),(.188,.105,.116),
                "302626",rot=(-12,0,0),sub=2,smooth=False)
    head.sphere((-.026,-1.629,5.826),(.072,.026,.028),
                "685247",rot=(-12,0,0),sub=2,smooth=False)
    for side in (-1,1):
        poly(head,[(side*.083,5.53),(side*.201,5.515),(side*.176,5.324)],
             -1.426,.077,base.BONE,bevel=.014)
        poly(head,[(side*.166,4.759),(side*.248,4.827),(side*.182,4.904)],
             -1.306,.061,"BEAA90",bevel=.011)
        for j in range(2):
            x=side*(.241+j*.045)
            head.sphere((x,-1.463,5.614-j*.041),(.016,.013,.016),
                        "80513F",sub=1,smooth=False)
    # Swept branching antlers follow the live head; the ears remain visible below.
    for side in (-1,1):
        rise = .19 if side<0 else -.15
        antler=[(side*.37,-.18,6.32,.157),(side*.48,-.05,6.72,.141),
                (side*.71,.09,7.06,.122),(side*1.19,.14,7.35,.095),
                (side*1.52,.17,7.74,.065),(side*1.65,.04,8.25+rise,.010)]
        tip="8245A8" if role=="Punk" else "55424A"
        base.faceted(head,antler,["221C24","2C2128","382A32","483540",tip],6)
        base.faceted(head,[(side*.74,.09,7.10,.10),(side*.80,.01,7.62,.061),
                           (side*.72,-.22,8.15+rise,.008)],
                     ["2A2128","352935",tip],6)
        base.faceted(head,[(side*.48,-.03,6.77,.095),(side*.39,-.22,7.15,.052),
                           (side*.41,-.47,7.57+rise,.009)],
                     ["2B222A","3C2D38",tip],6)
        if role=="Punk":
            ring(head,(side*1.19,.135,7.36),.139,.033,base.STEEL,seg=10)
    deer_headwear(head, role)
    anchor=Vector((0,-.43,4.84))
    tilt=(Matrix.Rotation(math.radians({"Farmer":-9,"Punk":7,"Assassin":-12,"Chief":4}[role]),3,"Y")
          @ Matrix.Rotation(math.radians(5),3,"X"))
    for mesh in (head,glints):
        for vertex in mesh.bm.verts:
            vertex.co=anchor+tilt@(vertex.co-anchor)
        mesh.bm.normal_update()


def deer_headwear(head, role):
    if role=="Farmer":
        # Raise the brim over the brow, exposing both eyes.
        head.cyl((0,-.43,6.42),.88,.88,.11,"D6A13B",rot=(9,-7,0),seg=18,smooth=False)
        head.cyl((0,-.455,6.60),.54,.47,.32,"E9B552",rot=(9,-7,0),seg=14,smooth=False)
        head.cyl((0,-.443,6.50),.55,.53,.11,"AA4630",rot=(9,-7,0),seg=14,smooth=False)
    elif role=="Assassin":
        outer=[(-.76,5.32),(-.92,6.03),(-.66,6.50),(.03,6.76),(.69,6.48),(.88,6.02),(.75,5.34)]
        inner=[(-.63,5.45),(-.73,6.04),(-.55,6.36),(.02,6.58),(.56,6.35),(.72,6.04),(.62,5.47)]
        for i in range(6):
            poly(head,[outer[i],outer[i+1],inner[i+1],inner[i]],-.85,.17,
                 "773A4B",bevel=.02)
        rear=[(x*.85,z-.12) for x,z in outer]
        head.loft([[(x,-.77,z) for x,z in outer],[(x,.24,z) for x,z in rear]],
                  "4E2D3A",cap_start=False,cap_end=False,wrap=False,smooth=False)
        poly(head,rear,.24,.12,"4D2B36")
    elif role=="Chief":
        box(head,(0,-.32,6.54),(.80,.59,.34),base.CREAM,rot=(7,-7,0),bevel=.061)
        box(head,(0,-.635,6.53),(.32,.038,.072),base.TEAL,rot=(0,-7,0))
        box(head,(0,-.638,6.53),(.070,.038,.235),base.TEAL,rot=(0,-7,0))
        box(head,(0,-.820,6.401),(.94,.122,.118),"554F58",bevel=.021)
        head.cyl((0,-.927,6.409),.226,.226,.086,base.STEEL,rot=(90,0,0),seg=16,smooth=False)
        head.cyl((0,-.985,6.409),.164,.164,.032,"B4C8D6",rot=(90,0,0),seg=16,smooth=False)
        ring(head,(0,-1.010,6.409),.104,.010,"E0DFDA",seg=12)


def build_deer(role):
    asset=kit.asset("Deer_"+role)
    base.deer_body(asset,role)
    base.deer_limbs(asset,role)
    deer_face(asset,role)


def grounded_paw(mesh, x, y, width, reach):
    claw_geometry.paw(mesh,x,y,width,reach)


def ring_quadruped(name="RingMaw", high_knees=False, paw_builder=None):
    asset=kit.asset(name)
    body=base.part(asset,"Body",ao=.34)
    profiles=[(-1.20,2.29,.38,.38),(-.95,2.24,.62,.58),
              (-.55,2.18,.73,.65),(-.06,2.10,.59,.50),
              (.44,1.99,.47,.39),(.89,1.94,.59,.50),
              (1.31,1.94,.56,.45),(1.62,1.96,.25,.28)]
    rings=[[(rx*math.cos(a*math.tau/10),y,z+rz*math.sin(a*math.tau/10)) for a in range(10)]
           for y,z,rx,rz in profiles]
    body.loft(rings,lambda i:["504050","4A3B45","3A3541","35313B",
                             "433846","443948","3A333D"][i],smooth=False)
    base.faceted(body,[(.06,-.69,2.22,.423),(.09,-1.14,2.36,.366),
                        (.13,-1.42,2.61,.295)],
                  ["3C3540","4B3940","513B40"])
    # Staggered spine plates and lateral ribs make the low body readable from above.
    for j in range(6):
        y=-.63+j*.37
        body.sphere((.02,y,2.70-j*.088),(.165,.23,.15),
                    "554653",sub=1,smooth=False)
    for side in (-1,1):
        for j in range(3):
            y=-.42+j*.31
            base.faceted(body,[(side*.25,y,2.58-j*.10,.079),
                                (side*.58,y+.08,2.29-j*.09,.092),
                                (side*.50,y-.06,1.89-j*.06,.053)],
                          ["4F414D","564653"],5)
    for side,name in [(-1,"ArmR"),(1,"ArmL")]:
        shoulder=(side*.57,-.66,2.37)
        elbow=(side*1.02,-.52 if side<0 else -.73,1.42)
        wrist=(side*1.34,-1.34 if side<0 else -1.56,.29)
        arm=base.part(asset,name,shoulder,ao=.33)
        base.faceted(arm,[(*shoulder,.378),(side*.81,-.61,1.98,.332),
                           (*elbow,.237),(side*1.25,(elbow[1]+wrist[1])*.5,.76,.183),
                           (*wrist,.139)],
                      ["50434D","4C404B","483842","392D38"])
        base.faceted(arm,[(side*.78,-.88,1.98,.11),(side*1.08,elbow[1]-.22,1.38,.11),
                          (side*1.32,wrist[1]-.035,.35,.062)],
                      ["71504B","5D3E3C"],5)
        if paw_builder:
            paw_builder(arm,wrist[0],wrist[1],.285,.65,hind=False)
        else:
            grounded_paw(arm,wrist[0],wrist[1],.285,.65)
    for side,name in [(-1,"LegR"),(1,"LegL")]:
        hip=(side*.43,1.08,2.08)
        if high_knees:
            knee=(side*1.03,1.00 if side<0 else .86,3.77 if side<0 else 3.56)
            hock=(side*1.58,2.08 if side<0 else 1.91,1.33)
            ankle=(side*1.50,2.22 if side<0 else 2.04,.24)
            thigh=(side*.73,.98,2.87,.293)
        else:
            knee=(side*.78,.77 if side<0 else .68,1.32)
            hock=(side*1.05,1.85 if side<0 else 1.70,.77)
            ankle=(side*1.12,1.49 if side<0 else 1.30,.24)
            thigh=(side*.63,.98,1.71,.355)
        leg=base.part(asset,name,hip,ao=.36)
        if high_knees:
            # Separate sweeps keep the tight knee bend from folding over itself.
            base.faceted(leg,[(*hip,.289),thigh,(*knee,.191)],
                          ["4D3E49","473A45","473A45"])
            leg.sphere(knee,(.218,.204,.204),"50414D",sub=2,smooth=False)
            shin=(side*1.38,(knee[1]+hock[1])*.5,(knee[2]+hock[2])*.5,.161)
            base.faceted(leg,[(*knee,.185),shin,(*hock,.129),(*ankle,.124)],
                          ["473A45","3D333F","352D36"])
        else:
            base.faceted(leg,[(*hip,.338),thigh,
                               (*knee,.246),(*hock,.138),(*ankle,.129)],
                          ["4D3E49","473A45","3D333F","352D36"])
        if paw_builder:
            paw_builder(leg,ankle[0],ankle[1],.237,.54,hind=True)
        else:
            grounded_paw(leg,ankle[0],ankle[1],.237,.54)
    base.ring_head(asset,(.13,-1.98,2.78),(.10,-1.38,2.61))
    return asset


def build():
    for role in ("Farmer","Punk","Assassin","Chief"):
        build_deer(role)
    ring_quadruped()
    base.cave_creature()
