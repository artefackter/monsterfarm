"""Third approval pass, focused on the deer face and CaveDweller's rear knees."""
import math
from mathutils import Matrix, Vector

import assets_monster_prototypes as base
import assets_monster_prototypes_v2 as previous
from assets_deer import beam, box, poly, ring
import kit
import claw_geometry

JOINTS = base.JOINTS


def deer_face(asset, role, expression=None):
    aggressive = expression in ("Aggressive", "AggressiveV2")
    anchor = Vector((0, -.43, 4.84))
    head = base.part(asset, "Head", anchor, ao=.23, ao_dist=.35)
    base.torso(head, [(4.91,-.40,.29,.26),(5.15,-.45,.49,.39),
                      (5.57,-.49,.64,.48),(6.03,-.45,.66,.48),
                      (6.34,-.38,.57,.39),(6.55,-.32,.35,.27)],
               ["633522","723D26","7D452B","865036","9F6246"])

    for side in (-1, 1):
        rise = .055 if side < 0 else -.045
        ear_outline = [(side*.46,-.57,6.17),(side*.70,-.63,6.43+rise),
                       (side*1.13,-.59,6.38+rise),(side*1.01,-.58,6.15+rise),
                       (side*.85,-.58,5.95+rise),(side*.59,-.55,5.96)]
        ear_inner = [(side*.49,-.60,6.17),(side*.70,-.677,6.355+rise),
                     (side*1.047,-.637,6.321+rise),(side*.956,-.624,6.143+rise),
                     (side*.825,-.627,6.023+rise),(side*.61,-.597,6.024)]
        ear_back = [(x*.98,y+.22,z-.045) for x,y,z in ear_outline]
        head.loft([ear_back,ear_outline,ear_inner],
                  lambda i: ("633522","925340")[i],smooth=False)
        head.loft([ear_inner,[(x*.998,y-.022,z) for x,y,z in ear_inner]],
                  "E88797",smooth=False)

        # The reference has two tilted, uninterrupted white ovals and very dark pupils.
        eye_x = side*(.34 if side<0 else .337)
        eye_z = 6.125+rise*.35
        tilt = (0,side*-21,0)
        head.sphere((eye_x,-.972,eye_z),(.275,.184,.365),"FFF9ED",
                    rot=tilt,sub=3,smooth=True)
        head.sphere((eye_x+side*.036,-1.127,eye_z+.061),
                    (.165,.064,.239) if aggressive else (.187,.064,.265),
                    "F34736" if aggressive else "0E0D12",rot=tilt,sub=3,smooth=True)
        if aggressive:
            beam(head,(side*.105,-1.124,6.315),(side*.54,-1.08,6.48),
                 .082,.090,"3D2728")

    # A continuous peach rim frames a deep vertical, toothless opening.
    opening = [(-.330,5.635),(-.323,5.255),(-.298,4.764),(-.173,4.604),
               (-.067,4.550),(.097,4.549),(.207,4.606),(.307,4.759),
               (.327,5.227),(.342,5.638),(.228,5.741),(-.216,5.741)]
    mouth_sections = [(-.943,1.08,.95),(-1.329,1,1),(-1.369,.79,.82),
                      (-1.248,.74,.80),(-1.073,.63,.75)]
    mouth_center=5.31 if expression=="Passive" else 5.16
    mouth_scale=.20 if expression=="Passive" else 1
    head.loft([[(x*sx,y-(z-5.08)*.08,mouth_center+(z-5.16)*sz*mouth_scale) for x,z in opening]
               for y,sx,sz in mouth_sections],
              lambda i: ["A87754","EAC09D","765348","161419"][i],
              cap_start=True,cap_end=True,smooth=False)
    if expression=="AggressiveV2":
        for i in range(4):
            x=(i-1.5)*.145
            upper=(.235,.315,.285,.220)[i]
            lower=(.255,.300,.245,.285)[i]
            poly(head,[(x-.055,5.515),(x+.055,5.515),(x+.010,5.515-upper)],
                 -1.385,.070,"FFF0D2",bevel=.004)
            poly(head,[(x-.053,4.682),(x+.053,4.682),(x-.008,4.682+lower)],
                 -1.365,.065,"F0DCBA",bevel=.004)

    snout = [(-.345,5.759),(-.233,6.020),(-.079,6.135),(.059,6.146),
             (.228,6.020),(.346,5.771),(.236,5.561),(.020,5.463),(-.208,5.555)]
    head.loft([[(x*sx,y,5.81+(z-5.81)*sz) for x,z in snout]
               for y,sx,sz in [(-1.019,1,.99),(-1.412,1,1),(-1.517,.86,.86)]],
              lambda i: ("C9926B","F1C5A3")[i],smooth=False)
    head.sphere((.017,-1.533,5.902),(.131,.083,.145),"17151A",
                rot=(0,-10,0),sub=2,smooth=False)

    for side in (-1, 1):
        rise = .18 if side < 0 else -.14
        trunk=[(side*.390,-.29,6.398,.167),(side*.535,-.19,6.82,.147),
               (side*.762,-.10,7.14,.130),(side*1.211,.014,7.35,.111),
               (side*1.474,.039,7.59,.073),(side*1.731,-.092,7.94+rise,.008)]
        tips = "773D9C" if role == "Punk" else "3D343D"
        base.faceted(head,trunk,["20181D","241A23","291F27","302530",tips],6)
        base.faceted(head,[(side*.76,-.102,7.16,.103),(side*.56,-.14,7.67,.082),
                           (side*.54,-.18,8.15+rise,.052),(side*.62,-.23,8.42+rise,.008)],
                      ["241A23","2A2029",tips],6)
        base.faceted(head,[(side*1.203,.01,7.34,.099),(side*1.298,.02,7.72,.068),
                           (side*1.288,-.06,8.10+rise,.050),(side*1.193,-.16,8.30+rise,.008)],
                      ["271C24","2E242B",tips],6)
        if role == "Punk":
            ring(head,(side*1.29,.015,7.71),.126,.033,base.STEEL,seg=10)

    # Lift headwear clear of the larger eyes while retaining the outfit variants.
    existing_vertices = set(head.bm.verts)
    previous.deer_headwear(head,role)
    for vertex in head.bm.verts:
        if vertex not in existing_vertices:
            vertex.co.z += {"Farmer":.22,"Chief":.13,"Assassin":.10}.get(role,0)
            vertex.co.y += .05
    tilt = Matrix.Rotation(math.radians({"Farmer":-7,"Punk":4,"Assassin":-8,"Chief":2}.get(role,0)),3,"Y")
    for vertex in head.bm.verts:
        vertex.co = anchor + tilt @ (vertex.co - anchor)
    head.bm.normal_update()


def build_deer(role):
    asset = kit.asset("Deer_"+role)
    base.deer_body(asset,role)
    base.deer_limbs(asset,role)
    deer_face(asset,role)


def cave_crouch(name="CaveDweller"):
    asset = kit.asset(name)
    body = base.part(asset,"Body",ao=.26)
    # A low spine makes the raised rear knees visible even from the front.
    sections=[(-1.04,1.91,.30,.30),(-.72,1.82,.61,.43),
              (-.36,1.68,.58,.43),(.11,1.52,.43,.33),
              (.58,1.40,.34,.30),(.98,1.38,.45,.36),(1.26,1.36,.31,.29)]
    rows=[[(rx*math.cos(i*math.tau/10),y,z+rz*math.sin(i*math.tau/10)) for i in range(10)]
          for y,z,rx,rz in sections]
    body.loft(rows,lambda i:["232027","211E24","1D1B20","1C1920","201D23","1E1A21"][i],
              smooth=False)

    for side,name in [(-1,"ArmR"),(1,"ArmL")]:
        shoulder = (side*.54,-.68,1.92)
        elbow = (side*1.14,-.54 if side<0 else -.65,1.21)
        wrist = (side*1.42,-1.43 if side<0 else -1.64,.235)
        arm = base.part(asset,name,shoulder,ao=.32)
        base.faceted(arm,[(*shoulder,.245),(side*.84,-.57,1.65,.209),
                           (*elbow,.138),(side*1.31,(elbow[1]+wrist[1])*.5,.68,.103),
                           (*wrist,.081)],
                      ["25222A","232027","211D25","201C24"],5)
        shadow_paw(arm,wrist[0],wrist[1],.183,.73)

    for side,name in [(-1,"LegR"),(1,"LegL")]:
        hip = (side*.387,.80,1.42)
        knee = (side*1.12,.62 if side<0 else .73,3.31 if side<0 else 3.10)
        hock = (side*1.56,1.89 if side<0 else 1.79,1.24)
        ankle = (side*1.47,2.02 if side<0 else 1.97,.243)
        leg = base.part(asset,name,hip,ao=.35)
        # Thigh rises outward over the torso, then the shin folds back towards the foot.
        base.faceted(leg,[(*hip,.247),
                           (side*.710,.67 if side<0 else .81,2.08,.205),
                           (*knee,.159),
                           (side*1.43,1.26 if side<0 else 1.33,2.25,.121),
                           (*hock,.101),(*ankle,.083)],
                      ["231E26","26212A","28232B","211D24","201C23"],5)
        shadow_paw(leg,ankle[0],ankle[1],.181,.53)

    cave_head(asset)
    return asset


def shadow_paw(mesh,x,y,width,reach):
    claw_geometry.paw(mesh,x,y,width,reach,skin="242029",nail="4D4347",edge="877B74")


def cave_head(asset):
    pivot=(0,-1.01,1.99)
    head=base.part(asset,"Head",pivot,ao=.22,ao_dist=.28)
    glow=base.part(asset,"FaceGlow",attach="Head",material="Neon",ao=0,grad=0,cast=False)
    # An almost featureless head with a deep open mouth, four upper and four lower teeth.
    box(head,(0,-1.245,3.275),(.87,.67,.84),"211D25",bevel=.035)
    box(head,(0,-1.034,2.575),(.68,.325,1.22),"1D1922",bevel=.026)
    box(head,(0,-1.341,2.083),(.742,.51,.214),"241E26",bevel=.026)
    box(head,(0,-1.233,2.580),(.645,.026,.958),"100D15",bevel=.014)
    for side in (-1,1):
        box(head,(side*.325,-1.278,2.548),(.106,.303,.890),"201A24",bevel=.016)
        box(glow,(side*.216,-1.592,3.435),(.093,.044,.087),"FFF4DE",bevel=.004)
    for j in range(4):
        x=(j-1.5)*.144
        upper=.298 if j in (0,3) else .450
        lower=.406 if j in (0,3) else .234
        box(head,(x,-1.505,2.861),(.090,.102,.155),"754034",bevel=.012)
        box(head,(x,-1.505,2.212),(.091,.101,.142),"754034",bevel=.012)
        box(glow,(x,-1.544,2.905-upper*.5),(.068,.065,upper),"FBE6D0",bevel=.008)
        box(glow,(x,-1.544,2.169+lower*.5),(.068,.065,lower),"FBE6D0",bevel=.008)


def outfit(asset,role,ringmaw):
    # Costumes mount behind the face and above the grounded limbs.
    body=base.part(asset,"Outfit",attach="Body")
    head=base.part(asset,"Headwear",attach="Head")
    back_z=2.53 if ringmaw else 1.98
    head_y=-1.96 if ringmaw else -1.21
    head_z=4.10 if ringmaw else 3.715
    if role=="Farmer":
        head.cyl((0,head_y,head_z+.068),.61,.61,.105,"E7AB42",rot=(4,-9,0),seg=16,smooth=False)
        head.cyl((0,head_y,head_z+.227),.378,.335,.285,"F3BB51",rot=(4,-9,0),seg=12,smooth=False)
        head.cyl((0,head_y,head_z+.153),.384,.371,.102,"AA4937",rot=(4,-9,0),seg=12,smooth=False)
        for side in (-1,1):
            box(body,(side*.39,.215,back_z-.18),(.29,1.31,.46),"3E628D",rot=(-9,0,0),bevel=.039)
            beam(body,(side*.34,-.532,back_z+.033),(side*.35,.831,back_z-.15),.14,.081,"638BB4")
            box(body,(side*.54,-.269,back_z-.055),(.084,.184,.178),"DEAB50",bevel=.024)
        # A small provision basket secured on the back.
        box(body,(0,.28,back_z+.09),(.66,.60,.20),"805332",bevel=.04)
        for side in (-1,1):
            box(body,(side*.315,.28,back_z+.23),(.075,.60,.232),"B27943")
            box(body,(0,.28+side*.268,back_z+.23),(.65,.076,.227),"A56B3A")
        for j in range(3):
            x=(j-1)*.17
            body.cyl((x,.25,back_z+.29),.045,.083,.23,"DA762D",seg=6,smooth=False)
            beam(body,(x,.24,back_z+.405),(x+.061,.25,back_z+.535),.044,.044,"679A3F")
    elif role=="Punk":
        for i in range(5):
            box(head,(0,head_y+.21+i*.085,head_z+.072+.10*math.sin(i*math.pi/4)),
                (.21,.13,.245),"A44FBC",rot=(-17,0,0),bevel=.024)
        for side in (-1,1):
            box(body,(side*.484,.02,back_z-.16),(.154,.84,.372),"302A38",rot=(-9,0,0),bevel=.036)
            for i in range(4):
                body.cyl((side*.573,-.278+i*.188,back_z-.12),.068,0,.084,
                         "C9C6D3",rot=(0,side*90,0),seg=4,smooth=False)
        box(body,(0,.32,back_z-.013),(.79,.30,.117),"79438E",bevel=.038)
        for j in range(9):
            x=(j-4)*.104
            ring(body,(x,-.457,back_z+.06-.063*math.sin(j*math.pi/8)),.069,.023,
                 base.STEEL,rot=(90,0,j%2*62),seg=8)
    else:
        # A short angled hood leaves the eyes and both tooth rows visible.
        if ringmaw:
            center=Vector((.13,-1.98,2.78))
            tilt=Matrix.Rotation(math.radians(-9),3,"Y")@Matrix.Rotation(math.radians(6),3,"Z")
            angles=[math.radians(-18+i*216/12) for i in range(13)]
            rows=[[center+tilt@Vector((radius*math.cos(a),-depth,radius*1.12*math.sin(a)))
                   for a in angles]
                  for depth,radius in [(-.53,.81),(-.31,1.054),(-.09,1.214),(.15,1.312)]]
            head.loft(rows,"673540",wrap=False,cap_start=False,cap_end=False,smooth=False)
            for start,end in zip(rows[-1],rows[-1][1:]):
                beam(head,start,end,.087,.090,"955362")
        else:
            hood_z=head_z-.085
            outline=[(-.51,hood_z-.75),(-.51,hood_z-.22),(-.34,hood_z+.145),
                     (0,hood_z+.236),(.34,hood_z+.145),(.51,hood_z-.22),(.51,hood_z-.75)]
            hood_y=head_y-.06
            head.loft([[(x,hood_y,z) for x,z in outline],
                       [(x*.91,hood_y+.37,z-.09) for x,z in outline]],
                      "673540",wrap=False,cap_start=False,cap_end=False,smooth=False)
            for a,b in zip(outline,outline[1:]):
                beam(head,(a[0],hood_y,a[1]),(b[0],hood_y,b[1]),.097,.101,"8F4850")
        cape=[(-.52,-.42,back_z-.028),(.52,-.42,back_z-.028),(.49,.97,back_z-.31),
              (.22,1.12,back_z-.40),(0,.99,back_z-.42),(-.27,1.12,back_z-.36),(-.49,.96,back_z-.31)]
        body.loft([cape,[(x,y,z-.057) for x,y,z in cape]],"3C2836",smooth=False)
        for side in (-1,1):
            beam(body,(side*.443,-.38,back_z-.08),(side*.434,.66,back_z-.23),.14,.10,"793C45")
        box(body,(.43,.13,back_z-.147),(.106,.21,.19),"A99691",rot=(-8,0,0),bevel=.025)


def build():
    for role in ("Farmer","Punk","Assassin","Chief"):
        build_deer(role)
    previous.ring_quadruped()
    cave_crouch()
    for role in ("Farmer","Punk","Assassin"):
        outfit(cave_crouch("CaveDweller_"+role),role,ringmaw=False)
        outfit(previous.ring_quadruped("RingMaw_"+role),role,ringmaw=True)
