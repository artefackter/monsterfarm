"""Approval-stage meshes. Feet at Z=0, forward -Y, with rigid animation groups."""
import math
from mathutils import Euler, Matrix, Vector
import kit
from assets_deer import box, beam, poly, ring
import claw_geometry

JOINTS = {}
BONE = "E7CFAD"
HOOF = "211B22"
FUR = "75402E"
CHEST = "9F5A3B"
LEATHER = "2D2731"
STEEL = "BCC2CC"
TEAL = "207D7A"
CREAM = "E9DBBE"


def part(asset, name, pivot=None, attach=None, **kwargs):
    if pivot is not None:
        JOINTS.setdefault(asset.name, {})[name] = list(kit.to_rbx(pivot))
    return asset.part(name, attach=attach or name, **kwargs)


def ellipse(z, y, rx, ry, count=10, x=0):
    return [(x+rx*math.cos(i*math.tau/count), y+ry*math.sin(i*math.tau/count), z)
            for i in range(count)]


def torso(mesh, profiles, palette):
    mesh.loft([ellipse(z,y,rx,ry) for z,y,rx,ry in profiles],
              lambda i: palette[min(i, len(palette)-1)], smooth=False)


def faceted(mesh, path, colors, segments=7):
    mesh.tube(path, lambda i: colors[min(i//2, len(colors)-1)], seg=segments, sub=2, smooth=False)


def claws(mesh, wrist, side, color, tip, length=1.0, spread=1.0, curled=False):
    claw_geometry.hand(mesh,wrist,side,color,tip,length,spread,curled)


def deer_face(asset, role):
    head = part(asset,"Head",(0,-.43,4.84),ao=.34,ao_dist=.48)
    glow = part(asset,"EyesGlow",attach="Head",material="Neon",ao=0,grad=0,cast=False)
    # Angled cranium and cheeks above the long muzzle.
    torso(head,[(4.93,-.57,.37,.33),(5.26,-.61,.66,.51),
                (5.72,-.57,.72,.55),(6.09,-.52,.60,.44),
                (6.30,-.46,.41,.30)],["583126","824936","92563A","70402D"])
    for side in (-1,1):
        ear = [(side*.45,-.54,5.91),(side*.80,-.56,6.19),
               (side*1.19,-.48,6.18),(side*1.06,-.41,5.86),(side*.77,-.41,5.74)]
        head.loft([ear,[(x*.97,y+.21,z-.03) for x,y,z in ear]],FUR,smooth=False)
        poly(head,[(side*.59,5.92),(side*.83,6.11),(side*1.08,6.11),
                   (side*.98,5.90),(side*.79,5.83)],-.604,.037,"B7756A",bevel=.018)
        # The eye sits in a bevelled dark socket and is cut by a sloped brow.
        socket=[(side*.10,5.75),(side*.17,6.01),(side*.53,6.12),
                (side*.68,5.96),(side*.58,5.73)]
        poly(head,socket,-1.033,.14,"342023",bevel=.04)
        eye=[(side*.18,5.79),(side*.20,5.91),(side*.55,6.02),
             (side*.56,5.86),(side*.38,5.78)]
        poly(glow,eye,-1.118,.04,"F54A2D",bevel=.012)
        poly(head,[(side*.30,5.82),(side*.34,5.96),(side*.40,5.98),(side*.39,5.83)],
             -1.144,.019,"331320",bevel=.004)
        beam(head,(side*.16,-1.15,5.95),(side*.61,-.99,6.14),.16,.19,"633323")
    # The mouth is a recessed cavity with an outer lip and slanted tooth rows.
    outer=[(-.47,5.67),(-.47,5.19),(-.34,4.75),(-.18,4.62),(.18,4.62),
           (.34,4.75),(.47,5.19),(.47,5.67),(.28,5.78),(-.28,5.78)]
    inner=[(x*.76,5.22+(z-5.22)*.79) for x,z in outer]
    muzzle_rings=[
        [(x*.92,-.83,z+.05) for x,z in outer],
        [(x,-1.19-(z-4.6)*.18,z) for x,z in outer],
        [(x,-1.24-(z-4.6)*.18,z) for x,z in inner],
        [(x*.68,-1.06,z) for x,z in inner],
    ]
    head.loft(muzzle_rings,lambda i:("AD7857","DAB08B","4C2926")[i],
              cap_start=True,cap_end=True,smooth=False)
    poly(head,inner,-1.128,.035,"21191C",bevel=0)
    head.sphere((0,-1.445,5.69),(.235,.122,.152),"302327",sub=2,smooth=False)
    for j in range(5):
        x=(j-2)*.117
        top=5.57-abs(x)*.14
        length=(.17,.105,.13,.10,.20)[j]
        poly(head,[(x-.053,top),(x+.047,top),(x+.020,top-length)],
             -1.35,.056,BONE,bevel=.007)
        bot=4.79+abs(x)*.12
        poly(head,[(x-.048,bot),(x+.044,bot),(x-.013,bot+length*.67)],
             -1.279,.054,BONE,bevel=.007)
    # Branching, swept antlers with solid taper and different left and right tips.
    for side in (-1,1):
        raise_tip = .23 if side == -1 else -.10
        base=[(side*.39,-.25,6.12,.155),(side*.51,-.16,6.57,.13),
              (side*.84,-.02,6.96,.115),(side*1.24,.04,7.26,.095),
              (side*1.58,.12,7.70,.060),(side*1.84,.06,8.12+raise_tip,.008)]
        tint="7943A1" if role=="Punk" else "55454D"
        faceted(head,base,[HOOF,"2E232A","392931","45323E",tint],6)
        faceted(head,[(side*.91,.00,7.03,.095),(side*.99,-.06,7.53,.065),
                      (side*.98,-.18,8.03+raise_tip,.007)],[HOOF,"392931",tint],6)
        faceted(head,[(side*.53,-.16,6.58,.092),(side*.47,-.33,7.03,.052),
                      (side*.41,-.41,7.51+raise_tip,.007)],[HOOF,"392931",tint],6)
        if role=="Punk":
            ring(head,(side*1.30,.0,7.31),.146,.036,STEEL,seg=10)
    if role=="Farmer":
        head.cyl((0,-.46,6.20),.94,.94,.11,"D6A13B",rot=(4,-9,0),seg=18,smooth=False)
        head.cyl((0,-.45,6.40),.56,.48,.34,"F1BC50",rot=(4,-9,0),seg=14,smooth=False)
        head.cyl((0,-.45,6.29),.569,.543,.12,"B74F32",rot=(4,-9,0),seg=14,smooth=False)
        brim_center=Vector((0,-.46,6.20))
        brim_tilt=Euler((math.radians(4),math.radians(-9),0),"XYZ").to_matrix()
        for i in range(16):
            t=i*math.tau/16
            start=brim_center+brim_tilt@Vector((.66*math.cos(t),.66*math.sin(t),.058))
            end=brim_center+brim_tilt@Vector((.89*math.cos(t),.89*math.sin(t),.058))
            beam(head,start,end,.022,.021,"EFC66C")
    elif role=="Assassin":
        outer_hood=[(-.81,5.05),(-.94,5.78),(-.72,6.24),(0,6.49),(.72,6.24),(.94,5.78),(.81,5.05)]
        inner_hood=[(-.66,5.20),(-.76,5.78),(-.58,6.13),(0,6.27),(.58,6.13),(.76,5.78),(.66,5.20)]
        for i in range(6):
            poly(head,[outer_hood[i],outer_hood[i+1],inner_hood[i+1],inner_hood[i]],
                 -.91,.18,"713546",bevel=.02)
        head.loft([[(x,-.83,z) for x,z in outer_hood],
                   [(x*.89,.28,z-.11) for x,z in outer_hood]],
                  "55303C",cap_start=False,cap_end=False,wrap=False,smooth=False)
        poly(head,[(x*.89,z-.11) for x,z in outer_hood],.28,.11,"4C2936")
    elif role=="Chief":
        box(head,(0,-.45,6.34),(.82,.63,.37),CREAM,rot=(8,-8,0),bevel=.065)
        box(head,(0,-.79,6.35),(.32,.035,.075),TEAL,rot=(0,-8,0))
        box(head,(0,-.79,6.35),(.075,.035,.25),TEAL,rot=(0,-8,0))
        box(head,(0,-.93,6.20),(.98,.13,.13),"554F58",bevel=.025)
        head.cyl((0,-1.04,6.21),.24,.24,.082,STEEL,rot=(90,0,0),seg=16,smooth=False)
        head.cyl((0,-1.09,6.21),.17,.17,.036,"E4E7EB",rot=(90,0,0),seg=16,smooth=False)
        ring(head,(0,-1.113,6.21),.098,.012,"A5A9B5",seg=12)
    # A living, slightly canted neck pose. Preserve the local animation pivot.
    anchor=Vector((0,-.43,4.84))
    tilt=Matrix.Rotation(math.radians({"Farmer":-6,"Punk":8,"Assassin":-10,"Chief":4}[role]),3,"Y")
    for mesh in (head,glow):
        for vertex in mesh.bm.verts:
            vertex.co=anchor+tilt@(vertex.co-anchor)
        mesh.bm.normal_update()


def deer_body(asset, role):
    b=part(asset,"Body",ao=.40)
    chest_width=.98 if role=="Chief" else .86
    torso(b,[(2.70,.10,.48,.30),(3.05,.09,.60,.41),(3.38,.06,.49,.33),
             (3.97,-.12,.66,.40),(4.48,-.26,chest_width,.49),
             (4.69,-.25,.54,.40),(4.86,-.39,.27,.26)],
          [FUR,FUR,CHEST,FUR,"84523B","64402E"])
    faceted(b,[(0,-.29,4.48,.36),(0,-.39,4.74,.31),(0,-.50,5.21,.26)],
            [FUR,CHEST,CHEST])
    if role in ("Farmer","Punk"):
        b.sphere((0,.33,2.97),(.25,.34,.25),"A26A48",sub=2,smooth=False)
    if role=="Farmer":
        torso(b,[(2.67,.10,.51,.33),(3.04,.08,.63,.45),(3.36,.05,.52,.37)],
              ["355780","4772A0"])
        poly(b,[(-.49,3.22),(-.40,3.92),(.40,3.92),(.49,3.22)],-.356,.14,"4B78A7")
        poly(b,[(-.27,3.39),(-.28,3.68),(.28,3.68),(.27,3.39),(0,3.29)],-.450,.055,"35577E")
        for side in (-1,1):
            faceted(b,[(side*.36,-.40,3.72,.105),(side*.53,-.64,4.31,.102),
                      (side*.51,-.27,4.69,.102),(side*.29,.36,4.49,.089),
                      (-side*.23,.47,3.30,.091)],["456B9D","517DA8","456B9D","355783"],5)
            box(b,(side*.41,-.52,3.84),(.24,.12,.26),"E7B453",rot=(0,side*10,0))
            box(b,(side*.41,-.59,3.84),(.105,.035,.13),"644C37",rot=(0,side*10,0))
        poly(b,[(-.48,4.67),(.40,4.64),(.24,4.36),(-.07,4.15),(-.33,4.37)],-.677,.16,"AD4438")
        poly(b,[(-.30,4.54),(.32,4.55),(-.08,4.24)],-.769,.025,"CB5947")
    elif role=="Punk":
        torso(b,[(3.08,.04,.56,.42),(3.42,.03,.54,.40),(4.20,-.15,.75,.47),
                 (4.61,-.24,.65,.44)],["5A3675","714497","7D4EA4"])
        for side in (-1,1):
            poly(b,[(side*.29,3.25),(side*.67,3.24),(side*.84,4.51),
                    (side*.42,4.64),(side*.36,4.36)],-.36,.62,LEATHER,bevel=.037)
            poly(b,[(side*.37,4.55),(side*.68,4.42),(side*.42,3.94),(side*.32,4.22)],
                 -.701,.10,"524652")
            for z in (3.58,3.89,4.19):
                b.cyl((side*.51,-.73,z),.105,0,.12,STEEL,rot=(90,0,0),seg=4,smooth=False)
        poly(b,[(.03,4.17),(-.26,3.79),(-.05,3.79),(-.16,3.43),
                (.24,3.93),(.04,3.91)],-.638,.035,"DCBBFC")
        for j in range(9):
            x=(j-4)*.112
            ring(b,(x,-.76,4.47-.21*math.sin(j*math.pi/8)),.077,.027,STEEL,
                 rot=(90,0,(j%2)*62),seg=8)
        poly(b,[(-.44,4.42),(.43,4.42),(.34,3.35),(-.38,3.35)],.28,.15,LEATHER)
    elif role=="Assassin":
        torso(b,[(2.75,.08,.59,.41),(3.28,.04,.56,.37),(4.12,-.15,.75,.45),
                 (4.62,-.28,.83,.48)],["362C38",LEATHER,"483645"])
        for side in (-1,1):
            poly(b,[(side*.36,4.68),(side*.91,4.65),(side*1.17,4.29),
                    (side*.83,4.15),(side*.41,4.31)],-.23,.87,"63303F",bevel=.045)
        cape=[(-.87,4.53),(.82,4.56),(.95,2.52),(.56,2.74),(.25,2.36),
              (-.13,2.71),(-.43,2.41),(-.61,2.65),(-.96,2.52)]
        poly(b,cape,.54,.16,"58303F",bevel=.024)
        beam(b,(-.48,-.41,3.31),(.60,-.57,4.35),.22,.12,"913D44")
        box(b,(.17,-.56,3.91),(.30,.10,.28),"A38C8B",rot=(0,-42,0))
    elif role=="Chief":
        torso(b,[(2.76,.08,.53,.38),(3.37,.04,.56,.40),(4.07,-.18,.79,.44),
                 (4.63,-.24,.82,.44)],["206B6D","268282","30928C"])
        for side in (-1,1):
            poly(b,[(side*.36,4.64),(side*.95,4.60),(side*1.01,4.23),
                    (side*.66,3.43),(side*.92,2.45),(side*.48,2.58),
                    (side*.19,3.32)],-.26,.90,CREAM,bevel=.044)
            poly(b,[(side*.41,4.55),(side*.80,4.39),(side*.57,4.18),
                    (side*.65,4.01),(side*.28,3.65)],-.739,.06,TEAL)
            box(b,(side*.63,-.72,3.30),(.31,.06,.18),"D3C3A5",rot=(0,side*13,0))
        poly(b,[(-.87,4.59),(.87,4.59),(.88,3.78),(.69,3.34),(.92,2.40),
                (.25,2.54),(0,2.77),(-.25,2.54),(-.91,2.39),(-.65,3.37)],
             .45,.25,CREAM,bevel=.032)
        faceted(b,[(-.29,-.49,4.72,.047),(-.51,-.79,4.36,.048),
                  (-.54,-.80,4.02,.049),(-.40,-.81,3.91,.049),
                  (-.28,-.74,4.12,.045)],[LEATHER,LEATHER,STEEL,STEEL])
        faceted(b,[(.30,-.49,4.71,.046),(.58,-.74,4.44,.046),
                  (.58,-.78,4.07,.047)],[LEATHER,LEATHER])
        b.cyl((.58,-.82,4.07),.15,.15,.078,STEEL,rot=(90,0,0),seg=12,smooth=False)
        box(b,(.56,-.755,3.83),(.42,.09,.26),"D9BB84")
        box(b,(.47,-.81,3.83),(.19,.02,.05),TEAL)
        box(b,(.47,-.813,3.83),(.05,.02,.16),TEAL)
    if role in ("Punk","Assassin","Chief"):
        box(b,(0,.015,3.13),(1.16,.88,.19),"573F38",bevel=.045)
        box(b,(0,-.461,3.13),(.32,.075,.25),STEEL)
        box(b,(0,-.511,3.13),(.18,.026,.13),LEATHER)


def deer_limbs(asset, role, hand_builder=None):
    cloth={"Farmer":"3F658B","Punk":"332C42","Assassin":"413241","Chief":"21777B"}.get(role,FUR)
    for side,name in [(-1,"LegR"),(1,"LegL")]:
        hip=(side*.44,.07,2.91)
        knee=(side*.83,-.52,1.94)
        hock=(side*.68,.38,1.11)
        ankle=(side*.71,.05,.25)
        leg=part(asset,name,hip,ao=.35)
        faceted(leg,[(*hip,.326),(side*.65,-.27,2.54,.355),(*knee,.27),
                     (*hock,.145),(*ankle,.13)],[cloth,cloth,FUR,"553529","473128"])
        # Two blunt weight-bearing toes, with a visible split.
        for dx in (-.132,.132):
            box(leg,(ankle[0]+dx,-.082,.171),(.237,.54,.342),HOOF,taper=.75,bevel=.025)
        if role=="Farmer":
            beam(leg,(knee[0],knee[1]-.01,2.05),(knee[0]+side*.01,knee[1]+.07,1.88),
                 .55,.58,"567CA6")
        if role=="Punk":
            box(leg,(side*.73,-.59,2.30),(.33,.046,.14),"9D6549",rot=(0,side*26,0))
    for side,name in [(-1,"ArmR"),(1,"ArmL")]:
        shoulder=(side*(.99 if role=="Chief" else .87),-.26,4.46)
        elbow=(side*1.31,-.14,3.41)
        holding=side<0 and role in ("Farmer","Assassin","Chief")
        wrist=(side*(1.58 if holding else 1.74),-.69 if holding else -.40,
               2.79 if holding else 2.36)
        arm=part(asset,name,shoulder,ao=.36)
        arm_colors=[CREAM,CREAM,TEAL,TEAL] if role=="Chief" else [CHEST,FUR,"503235",HOOF]
        faceted(arm,[(*shoulder,.31),(side*1.12,-.23,4.07,.28),(*elbow,.19),
                     (side*1.54,-.29,2.96,.155),(*wrist,.108)],arm_colors)
        if role in ("Punk","Assassin"):
            box(arm,(side*.99,-.29,4.40),(.52,.59,.46),LEATHER,rot=(0,side*19,0),bevel=.054)
            for j in range(3):
                x=side*(1.48+j*.057)
                box(arm,(x,-.39,2.99-j*.13),(.31,.34,.09),
                    "77635E" if role=="Assassin" else "403346",rot=(0,-side*25,0))
        (hand_builder or claws)(arm,wrist,side,TEAL if role=="Chief" else HOOF,
                                "6C5051",.53,curled=holding)
        if holding:
            deer_tool(asset,role,wrist)


def deer_tool(asset,role,wrist):
    p=part(asset,"HandItem",attach="ArmR")
    x,y,z=wrist
    y-=.21
    if role=="Farmer":
        beam(p,(x,y,.10),(x,y,4.10),.117,.128,"A06B41")
        poly(p,[(x-.66,4.07),(x-.37,4.42),(x+.36,4.40),(x+.57,4.21),(x+.19,4.13)],
             y,.22,"9FA4AC",bevel=.034)
        beam(p,(x-.65,y-.101,4.07),(x-.34,y-.109,4.40),.036,.025,"E1E3E5")
    elif role=="Assassin":
        beam(p,(x,y,z+.10),(x,y,z-.38),.14,.16,"443137")
        box(p,(x,y,z-.39),(.47,.20,.09),STEEL)
        poly(p,[(x-.16,z-.43),(x+.17,z-.43),(x+.11,z-1.44),(x-.06,z-1.69),(x-.14,z-1.35)],
             y,.12,"CBD1D5",bevel=.021)
        poly(p,[(x+.03,z-.45),(x+.17,z-.45),(x+.11,z-1.44),(x-.06,z-1.69)],
             y-.063,.018,"F1F0E8",bevel=.004)
    else:
        p.cyl((x,y,z-.78),.215,.215,1.10,"31C6CB",seg=12,smooth=False)
        for h in (z-.26,z-1.33):
            p.cyl((x,y,h),.27,.27,.15,STEEL,seg=10,smooth=False)
        p.cyl((x,y,z+.05),.085,.085,.60,STEEL,seg=8,smooth=False)
        p.cyl((x,y,z+.35),.25,.25,.14,TEAL,seg=8,smooth=False)
        p.cyl((x,y,z-1.54),.065,.11,.28,"8996AA",seg=8,smooth=False)
        box(p,(x-.07,y-.212,z-.78),(.037,.023,.88),"B9FFFF")
        for h in range(5):
            box(p,(x+.10,y-.207,z-1.10+h*.15),(.10,.023,.022),CREAM)


def build_deer(role):
    asset=kit.asset("Deer_"+role)
    deer_body(asset,role)
    deer_limbs(asset,role)
    deer_face(asset,role)


def creature_legs(asset, heavy=False):
    for side,name in [(-1,"LegR"),(1,"LegL")]:
        if heavy:
            hip=(side*.39,.23,2.52)
            knee=(side*.72,-.14,1.57)
            heel=(side*.86,.20,.23)
            path=[(*hip,.36),(side*.55,.09,2.14,.38),(*knee,.25),
                  (side*.81,.30,.83,.185),(*heel,.138)]
            muscle=["32303A","45404A","292B34","25242C"]
        else:
            hip=(side*.33,.17,2.71)
            knee=(side*.66,-.31,1.49 if side<0 else 1.62)
            heel=(side*.64,.14 if side<0 else .35,.23)
            path=[(*hip,.24),(side*.47,-.04,2.20,.205),(*knee,.147),
                  (side*.64,.14,.79,.114),(*heel,.082)]
            muscle=["3C373C","4A4244","322E36","26252A"]
        leg=part(asset,name,hip,ao=.34)
        faceted(leg,path,muscle)
        leg.sphere((heel[0],heel[1]-.12,.164),(.24 if heavy else .18,.34,.165),
                   "34323D" if heavy else "2E282D",sub=2,smooth=False)
        for j in range(3):
            x=heel[0]+(j-1)*(.137 if heavy else .102)
            faceted(leg,[(x,heel[1]-.21,.14,.084),(x,heel[1]-.41,.102,.063),
                         (x,heel[1]-.55-(j%2)*.04,.044,.008)],
                    [muscle[-1],"65585E"],5)


def ring_creature():
    asset=kit.asset("RingMaw")
    body=part(asset,"Body",ao=.33)
    torso(body,[(2.32,.20,.45,.34),(2.72,.16,.55,.43),(3.01,.10,.46,.37),
                (3.49,-.04,.56,.43),(3.94,-.25,.90,.56),(4.30,-.36,.99,.51),
                (4.62,-.45,.54,.39)],
          ["363139","2E2B34","3D3742","343542","383C49","3C3540"])
    # Interlocking pectoral plates and dorsal ridges create a muscular silhouette.
    for side in (-1,1):
        body.sphere((side*.43,-.66,4.05),(.49,.31,.35),"474651",
                    rot=(0,side*19,0),sub=2,smooth=False)
        for j in range(3):
            faceted(body,[(side*.65,-.40+j*.08,3.80-j*.28,.087),
                          (side*.41,-.54+j*.08,3.66-j*.28,.097),
                          (side*.12,-.46+j*.08,3.60-j*.26,.041)],
                    ["4E4650","3C3540"],5)
        for j in range(4):
            at=(side*(.35+j*.05),.27-j*.04,3.57+j*.25)
            body.sphere(at,(.16,.26,.22),"3A3542",sub=1,smooth=False)
    faceted(body,[(0,-.20,4.19,.42),(0,-.27,4.61,.32),(.10,-.39,4.94,.235)],
            ["343543","46424A","44383E"])
    creature_legs(asset,heavy=True)
    for side,name in [(-1,"ArmR"),(1,"ArmL")]:
        shoulder=(side*.98,-.33,4.22)
        elbow=(side*1.59,-.22,3.39)
        wrist=(side*2.16,-.64 if side<0 else -.98,2.45 if side<0 else 2.64)
        arm=part(asset,name,shoulder,ao=.34)
        faceted(arm,[(*shoulder,.38),(side*1.28,-.27,3.88,.345),(*elbow,.214),
                     (side*1.91,-.44,3.02,.202),(*wrist,.108)],
                ["49434C","403C49","352F38","483640"])
        faceted(arm,[(side*1.39,-.51,3.76,.115),(side*1.68,-.46,3.28,.11),
                     (wrist[0],wrist[1]-.05,wrist[2],.066)],
                ["65423F","46323A","43343E"],5)
        claws(arm,wrist,side,"44343B","76605E",length=1.08,spread=1.24)
    ring_head(asset,(.12,-1.06,5.23),(.06,-.53,4.61))


def ring_head(asset,center,pivot):
    head=part(asset,"Head",pivot,ao=.37,ao_dist=.50)
    glow=part(asset,"MawGlow",attach="Head",material="Neon",ao=0,grad=0,cast=False)
    # One continuous mesh from the back of the cranium through the lip into the throat.
    profile=[(.15,-.67),(.67,-.56),(1.04,-.27),(1.25,.10),(1.32,.38),
             (1.23,.64),(1.11,.70),(.98,.57),(.89,.40),(.86,.30),
             (.78,.23),(.75,.17),(.67,.12),(.65,.01),(.57,-.09),
             (.52,-.12),(.44,-.21),(.37,-.25),(.27,-.35),(.085,-.49)]
    shell_colors=["332A35","4F3439","674039","8F4E39","B56B46",
                  "D68D57","873E30","583139","38252C","6A393A",
                  "36262C","553239","2A2229","513235","32232A",
                  "533232","261E26","4E2D2D","211C23"]
    def wobble(angle, profile_index):
        weight=1 if profile_index<8 else .45
        return 1+weight*(.038*math.sin(5*angle)+.033*math.cos(9*angle))
    head.lathe(profile,lambda i:shell_colors[i],c=center,rot=(90,0,0),
               seg=36,rfn=wobble,smooth=False,caps=True)
    x,y,z=center
    # Visible ridges and individual inward-facing teeth at different depths.
    for radius,depth,count,shade in [(.89,.45,16,"C4A086"),(.57,-.05,11,"B88768"),(.35,-.25,9,"E8B685")]:
        for j in range(count):
            angle=(j+.25)*math.tau/count
            ca,sa=math.cos(angle),math.sin(angle)
            length=.116+.064*(.5+.5*math.sin(j*2.1))
            faceted(head,[(x+ca*radius,y-depth,z+sa*radius,.054),
                         (x+ca*(radius-length*.50),y-depth+.04,z+sa*(radius-length*.50),.036),
                         (x+ca*(radius-length),y-depth+.09,z+sa*(radius-length),.006)],
                    [shade,"EAD2B8"],5)
    for radius,depth,color in [(.255,-.323,"C35C36"),(.172,-.412,"FFAB63"),(.089,-.474,"FFE1A3")]:
        ring(glow,(x,y-depth,z),radius,.021,color,seg=24)
    glow.sphere((x,y+.515,z),(.037,.023,.040),"FFF2C3",sub=2,smooth=False)
    # Angle the entire cavity and taper it vertically as one head group.
    tilt=Matrix.Rotation(math.radians(-9),3,"Y")@Matrix.Rotation(math.radians(6),3,"Z")
    anchor=Vector(center)
    for mesh in (head,glow):
        for vertex in mesh.bm.verts:
            local=vertex.co-anchor
            local.z*=1.12
            vertex.co=anchor+tilt@local
        mesh.bm.normal_update()


def cave_creature():
    asset=kit.asset("CaveDweller")
    body=part(asset,"Body",ao=.34)
    torso(body,[(2.51,.15,.38,.28),(2.86,.14,.47,.32),(3.24,.09,.35,.27),
                (3.81,-.04,.48,.33),(4.25,-.27,.76,.40),(4.59,-.34,.70,.37),
                (4.81,-.44,.42,.31),(5.02,-.60,.22,.21)],
          ["40373E","342D34","3C343B","443B43","494047","3F3742","3E343A"])
    # Raised ribs and flaked stone on the hunched back.
    for side in (-1,1):
        for j in range(4):
            z=4.23-j*.26
            faceted(body,[(side*(.54-j*.046),-.42,z,.068),
                          (side*.35,-.64+j*.044,z-.09,.072),
                          (side*.11,-.58+j*.048,z-.13,.034)],
                    ["595058","473D46"],5)
        for j in range(3):
            body.sphere((side*(.42+j*.11),.02+j*.02,4.62-j*.14),
                        (.23,.28,.35),"5B545B",rot=(0,side*28,0),sub=1,smooth=False)
    for j in range(5):
        z=3.29+j*.27
        body.sphere((.01,.39-j*.025,z),(.142,.19,.18),"524852",sub=1,smooth=False)
    creature_legs(asset)
    for side,name in [(-1,"ArmR"),(1,"ArmL")]:
        shoulder=(side*.67,-.31,4.46)
        elbow=(side*(1.11 if side<0 else 1.35),-.03,3.31 if side<0 else 3.52)
        wrist=(side*(1.48 if side<0 else 1.79),-.62 if side<0 else -.38,1.96 if side<0 else 2.31)
        arm=part(asset,name,shoulder,ao=.30)
        faceted(arm,[(*shoulder,.258),(side*.91,-.21,4.07,.22),(*elbow,.135),
                     (side*1.40,-.28,2.82,.119),(*wrist,.084)],
                ["4D444A","534A50","3C343A","332C35"])
        arm.sphere(elbow,(.18,.19,.18),"61555A",sub=1,smooth=False)
        claws(arm,wrist,side,"3A323B","756C6F",length=.96,spread=.88)
    h=part(asset,"Head",(0,-.55,4.85),ao=.27)
    glow=part(asset,"FaceGlow",attach="Head",material="Neon",ao=0,grad=0,cast=False)
    # Carve the face into the same shell as the skull, with no separate faceplate.
    outline=[(-.25,6.56),(.24,6.58),(.47,6.26),(.52,5.92),(.47,5.46),
             (.29,4.97),(.02,4.75),(-.28,4.88),(-.46,5.31),(-.53,5.79),(-.45,6.22)]
    section_params=[(-.30,.54,.82),(-.51,.87,.98),(-.82,1,1),
                    (-1.10,.96,.96),(-1.19,.80,.78),(-1.13,.75,.73)]
    sections=[[(x*sx,y+(z-5.74)*.08,5.74+(z-5.74)*sz) for x,z in outline]
              for y,sx,sz in section_params]
    h.loft(sections,lambda i:["423842","4A414A","4E444E","39323C","211C26"][i],
           cap_start=True,cap_end=True,smooth=False)
    for side in (-1,1):
        faceted(h,[(side*.39,-1.16,6.13,.087),(side*.48,-1.16,5.84,.09),
                   (side*.47,-1.13,5.50,.078),(side*.34,-1.09,5.12,.050)],
                ["4B4148","544951","40363C","342B33"],5)
        eye_z=5.94+side*.018
        h.sphere((side*.219,-1.24,eye_z),(.114,.048,.098),"120F17",sub=2,smooth=False)
        glow.sphere((side*.219,-1.292,eye_z),(.055,.029,.059),"FFF3D8",sub=2,smooth=False)
    poly(h,[(-.295,5.62),(.27,5.61),(.293,5.16),(.167,5.012),(-.204,5.03),(-.31,5.16)],
         -1.265,.032,"0E0D14",bevel=.018)
    for j,length in enumerate((.19,.35,.33,.20)):
        x=(j-1.5)*.132
        poly(glow,[(x-.042,5.59),(x+.045,5.59),(x+.033,5.59-length),(x-.033,5.58-length)],
             -1.302,.043,"EDE1CD" if j in (0,3) else "FFEBDB",bevel=.011)
    for x in (-.12,.11):
        box(glow,(x,-1.30,5.095),(.056,.043,.071),"BCA99F",bevel=.011)
    # A slight roll makes the pose uncanny without moving the head hinge.
    anchor=Vector((0,-.55,4.85))
    tilt=Matrix.Rotation(math.radians(8),3,"Y")@Matrix.Rotation(math.radians(-7),3,"X")
    for mesh in (h,glow):
        for vertex in mesh.bm.verts:
            vertex.co=anchor+tilt@(vertex.co-anchor)
        mesh.bm.normal_update()


def build():
    for role in ("Farmer","Punk","Assassin","Chief"):
        build_deer(role)
    ring_creature()
    cave_creature()
