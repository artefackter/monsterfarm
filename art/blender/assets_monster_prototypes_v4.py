"""Corrected anatomy: high rear knees on RingMaw and an upright CaveDweller."""
from mathutils import Vector

import assets_monster_prototypes as base
import assets_monster_prototypes_v2 as quadruped
import assets_monster_prototypes_v3 as approved
from assets_deer import beam, box, poly, ring
import kit
import claw_geometry

JOINTS = base.JOINTS


def cave_upright(name="CaveDweller", hand_builder=None, foot_builder=None):
    asset = kit.asset(name)
    body = base.part(asset, "Body", ao=.27)
    levels = [(2.52,.01,.39,.27),(2.91,.00,.44,.29),(3.31,-.03,.42,.27),
              (4.13,-.11,.60,.33),(4.40,-.12,.63,.31),(4.55,-.10,.35,.27)]
    body.loft([[(-width,y-depth,z),(width,y-depth,z),
                (width,y+depth,z),(-width,y+depth,z)]
               for z,y,width,depth in levels],
              lambda i: ["211D24","211C23","241F27","262129","231E25"][i],
              smooth=False)
    box(body,(0,-.055,4.62),(.315,.38,.35),"201B23",bevel=.028)
    for side,part_name in [(-1,"LegR"),(1,"LegL")]:
        hip=(side*.284,.025,2.61)
        knee=(side*.366,-.105,1.38 if side<0 else 1.47)
        ankle=(side*.441,.075 if side<0 else .185,.25)
        leg=base.part(asset,part_name,hip,ao=.29)
        base.faceted(leg,[(*hip,.237),(side*.320,-.025,2.05,.215),
                          (*knee,.159),(side*.411,.051,.84,.125),(*ankle,.108)],
                      ["241E27","221D24","211B23","1D1920"],4)
        (foot_builder or approved.shadow_paw)(leg,ankle[0],ankle[1],.183,.485)
    for side,part_name in [(-1,"ArmR"),(1,"ArmL")]:
        shoulder=(side*.66,-.115,4.29)
        elbow=(side*1.011,-.093,2.77 if side<0 else 2.90)
        wrist=(side*1.231,-.233,1.10 if side<0 else 1.23)
        arm=base.part(asset,part_name,shoulder,ao=.30)
        base.faceted(arm,[(*shoulder,.253),(side*.786,-.119,3.68,.225),
                          (*elbow,.142),(side*1.143,-.17,1.97,.121),(*wrist,.084)],
                      ["26212A","241E27","221C25","1F1922"],4)
        if hand_builder:
            hand_builder(arm,wrist,side)
        else:
            claw_geometry.hand(arm,wrist,side,"231D27","5C4D53",length=.39,spread=.77,digits=3)

    approved.cave_head(asset)
    shift=Vector((0,.58,2.6))
    for mesh in asset.parts:
        if mesh.attach=="Head":
            for vertex in mesh.bm.verts:
                vertex.co+=shift
            mesh.bm.normal_update()
    JOINTS[asset.name]["Head"]=list(kit.to_rbx(Vector((0,-1.01,1.99))+shift))
    return asset


def cave_outfit(asset, role):
    clothes=base.part(asset,"Outfit",attach="Body")
    headwear=base.part(asset,"Headwear",attach="Head")
    if role=="Farmer":
        headwear.cyl((0,-.655,6.357),.64,.64,.102,"E7AB42",
                     rot=(3,-8,0),seg=16,smooth=False)
        headwear.cyl((0,-.669,6.534),.37,.325,.295,"F3BB51",
                     rot=(3,-8,0),seg=12,smooth=False)
        headwear.cyl((0,-.661,6.442),.378,.36,.107,"AA4937",
                     rot=(3,-8,0),seg=12,smooth=False)
        box(clothes,(0,-.36,3.43),(.78,.15,1.13),"3E628D",bevel=.036)
        poly(clothes,[(-.257,3.17),(-.257,3.54),(.257,3.54),(.257,3.17),(0,3.08)],
             -.449,.065,"335177",bevel=.018)
        for side in (-1,1):
            beam(clothes,(side*.31,-.397,3.85),(side*.45,-.44,4.36),.132,.09,"638BB4")
            beam(clothes,(side*.45,-.44,4.36),(side*.40,.155,4.40),.132,.09,"638BB4")
            beam(clothes,(side*.40,.155,4.40),(-side*.28,.315,3.22),.126,.085,"456E9A")
            box(clothes,(side*.345,-.458,3.98),(.19,.073,.20),"DEAB50",bevel=.023)
        # Small produce basket sits behind the waist.
        box(clothes,(0,.56,3.075),(.60,.44,.17),"805332",bevel=.033)
        for side in (-1,1):
            box(clothes,(side*.283,.56,3.231),(.073,.44,.21),"AD753F")
            box(clothes,(0,.56+side*.185,3.231),(.59,.073,.21),"A56B3A")
        for j in range(3):
            x=(j-1)*.16
            clothes.cyl((x,.56,3.30),.035,.079,.19,"DA762D",seg=6,smooth=False)
            beam(clothes,(x,.56,3.38),(x+.04,.56,3.50),.033,.041,"679A3F")
    elif role=="Punk":
        for j in range(5):
            box(headwear,(0,-.46+j*.086,6.402+.08*(1-abs(j-2)*.5)),
                (.196,.131,.239),"A44FBC",rot=(-14,0,0),bevel=.022)
        box(clothes,(0,-.369,3.68),(.96,.117,1.48),"673881",bevel=.041)
        for side in (-1,1):
            box(clothes,(side*.471,-.19,3.74),(.24,.63,1.42),"302A38",
                rot=(0,-side*3,0),bevel=.037)
            poly(clothes,[(side*.253,4.37),(side*.52,4.28),(side*.371,3.91)],
                 -.542,.073,"514250",bevel=.019)
            for z in (3.28,3.64,4.02):
                clothes.cyl((side*.487,-.526,z),.082,0,.088,base.STEEL,
                            rot=(90,0,0),seg=4,smooth=False)
        poly(clothes,[(.04,4.12),(-.15,3.77),(.02,3.78),(-.07,3.44),
                      (.245,3.94),(.071,3.92)],-.447,.030,"BD82D5")
        for j in range(9):
            x=(j-4)*.094
            ring(clothes,(x,-.555,4.37-.18*(1-(x/.38)**2)),.065,.023,
                 base.STEEL,rot=(90,0,j%2*62),seg=8)
    else:
        head_z=6.23
        outline=[(-.51,head_z-.75),(-.51,head_z-.22),(-.34,head_z+.145),
                 (0,head_z+.236),(.34,head_z+.145),(.51,head_z-.22),(.51,head_z-.75)]
        headwear.loft([[(x,-.69,z) for x,z in outline],
                       [(x*.91,-.32,z-.09) for x,z in outline]],"673540",
                      wrap=False,cap_start=False,cap_end=False,smooth=False)
        for a,b in zip(outline,outline[1:]):
            beam(headwear,(a[0],-.69,a[1]),(b[0],-.69,b[1]),.097,.101,"8F4850")
        cape=[(-.56,4.39),(.56,4.39),(.49,2.64),(.21,2.79),(0,2.55),(-.23,2.77),(-.50,2.63)]
        poly(clothes,cape,.345,.086,"3C2836",bevel=.016)
        beam(clothes,(-.39,-.393,3.06),(.47,-.488,4.35),.153,.092,"793C45")
        box(clothes,(0,-.39,3.00),(.86,.12,.137),"6D3441",bevel=.022)
        box(clothes,(.095,-.462,3.71),(.21,.08,.18),"A99691",rot=(0,-32,0),bevel=.021)


def build():
    for role in ("Farmer","Punk","Assassin","Chief"):
        approved.build_deer(role)
    quadruped.ring_quadruped(high_knees=True)
    cave_upright()
    for role in ("Farmer","Punk","Assassin"):
        cave_outfit(cave_upright("CaveDweller_"+role),role)
        ring_asset=quadruped.ring_quadruped("RingMaw_"+role,high_knees=True)
        approved.outfit(ring_asset,role,ringmaw=True)
