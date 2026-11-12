"""Stylized Roblox weapon meshes with separate moving parts and authored grips."""
import math

from mathutils import Vector

import kit
import items_v3 as weapons
from assets_v3 import box, ANCHORS

JOINTS = {}
DARK = "343B48"
EDGE = "8293A0"
BLACK = "1B242E"
WOOD = "9E5D38"
ACCENT = "D79D57"
OLIVE = "686D49"


def attach_points(asset, grip, support, muzzle, **points):
    JOINTS[asset.name] = {name:list(kit.to_rbx(pos))
                          for name,pos in dict(Grip=grip,SupportHand=support,
                                               Muzzle=muzzle,**points).items()}


def part(asset,name):
    return asset.part(name,ao=.31,ao_dist=.15,grad=.073)


def muzzle(mesh,x,front,back,z,radius,color=DARK):
    # Open bore with a dark interior face behind the lip.
    profile=[(radius*.85,-(back-front)),(radius,-(back-front)+.025),
             (radius,-.029),(radius*.92,0),(radius*.61,.002),
             (radius*.61,-.13),(radius*.15,-.14)]
    mesh.lathe(profile,lambda i: [color,color,color,"6F7D89","202833","18212A"][i],
               c=(x,front,z),rot=(90,0,0),seg=14,smooth=False,caps=True)


def stock(mesh,begin,end,color,bottom=-.30):
    outline=[(begin,-.005),(begin+.25,-.011),(end-.068,bottom),
             (end,bottom+.06),(end,.211),(begin+.17,.261),(begin,.196)]
    mesh.prism(outline,.342,color,rot=(0,0,90),bevel=.039,seg=1,smooth=False)
    box(mesh,(0,end+.014,(bottom+.19)*.5),(.365,.106,.19-bottom),BLACK,.027)
    for side in (-1,1):
        box(mesh,(side*.180,end-.236,-.064),(.027,.293,.142),color,.015)


def rail(mesh,start,end,z):
    box(mesh,(0,(start+end)*.5,z),(.266,end-start,.08),DARK,.014)
    for j in range(round((end-start)/.108)):
        box(mesh,(0,start+.049+j*.108,z+.054),(.294,.051,.045),EDGE,.008)


def port(main,bolt,y,z):
    box(main,(-.247,y,z),(.024,.514,.173),BLACK,.013)
    box(bolt,(-.261,y+.075,z),(.033,.28,.132),EDGE,.014)
    box(bolt,(-.329,y+.19,z-.045),(.15,.095,.065),DARK,.016)


def pulik():
    a=kit.asset("GunM249")
    main=part(a,"Main"); mag=part(a,"Magazine"); bolt=part(a,"Bolt")
    bipod=part(a,"Bipod"); butt=part(a,"Stock")
    box(main,(0,-.034,.129),(.47,1.38,.45),DARK,.063)
    box(main,(0,-.137,.406),(.434,1.193,.153),"56636A",.040)
    box(main,(0,-1.03,.088),(.54,.843,.45),OLIVE,.057)
    for side in (-1,1):
        for j in range(5):
            box(main,(side*.278,-1.32+j*.141,.159),(.032,.084,.137),BLACK,.012)
        weapons.screw(main,side*.248,.421,.17)
    muzzle(main,0,-2.21,-1.28,.205,.103)
    muzzle(main,0,-2.32,-2.06,.205,.133,"556270")
    box(main,(0,-1.88,.402),(.13,.112,.284),BLACK,.016)
    rail(main,-.688,.388,.513)
    # Offset carrying handle and a chunky ammunition box below the feed cover.
    main.tube([(.159,-1.03,.333,.044),(.217,-1.19,.574,.049),
               (.241,-1.06,.698,.055),(.239,-.615,.695,.056),
               (.184,-.496,.608,.043)],DARK,seg=6,sub=2)
    box(mag,(.045,-.234,-.299),(.52,.814,.575),OLIVE,.066)
    box(mag,(.045,-.234,-.055),(.553,.853,.132),"848765",.037)
    box(mag,(.318,-.209,-.303),(.031,.552,.305),"4E563F",.028)
    for j in range(3):
        box(mag,(.339,-.419+j*.20,-.301),(.024,.068,.278),"657257",.013)
    for j in range(6):
        y=-.5+j*.073
        main.cyl((.284,y,.226),.036,.036,.168,"C69A52",rot=(0,90,0),seg=8,smooth=False)
    weapons.grip(main,.356,-.372); weapons.trigger(main,.071,-.115)
    stock(butt,.62,1.674,OLIVE,bottom=-.352)
    port(main,bolt,.115,.251)
    box(main,(0,-1.566,.126),(.293,.151,.244),"56616D",.024)
    box(bipod,(0,-1.577,.004),(.31,.149,.130),DARK,.022)
    for side in (-1,1):
        weapons.box(bipod,(side*.22,-1.52,-.307),(.075,.084,.645),DARK,.012,
                    rot=(12,-side*24,0))
        box(bipod,(side*.34,-1.458,-.605),(.204,.194,.075),BLACK,.021)
    attach_points(a,(0,.323,-.120),(0,-1.037,-.161),(0,-2.322,.205),
                  MagazinePivot=(.045,-.234,-.075),BoltPivot=(-.261,.115,.251),
                  BipodPivot=(0,-1.561,-.044))


def double_barrel():
    a=kit.asset("GunDouble")
    main=part(a,"Main"); barrels=part(a,"Barrels"); fore=part(a,"Foregrip")
    box(main,(0,.161,.08),(.495,.694,.411),"7E8A92",.074)
    box(main,(0,.421,.252),(.38,.285,.091),DARK,.021)
    box(main,(0,.627,.278),(.102,.22,.092),BLACK,.021,rot=(8,0,-21))
    stock(main,.423,1.674,WOOD,bottom=-.341)
    box(main,(0,.546,-.147),(.319,.391,.333),WOOD,.063,rot=(19,0,0))
    weapons.trigger(main,.352,-.117)
    main.tube([(0,.290,-.177,.023),(0,.211,-.289,.023),
               (0,.274,-.317,.019)],"B8A382",seg=5,sub=2)
    for side in (-1,1):
        muzzle(barrels,side*.121,-2.291,-.098,.192,.121,"465564")
        muzzle(barrels,side*.121,-.383,-.126,.192,.134,"63717D")
        main.cyl((side*.258,-.102,.080),.104,.104,.042,"BCC6CC",
                 rot=(0,90,0),seg=12,smooth=False)
        box(main,(side*.255,.218,.106),(.028,.233,.067),"A5A08E",.012)
    box(barrels,(0,-1.269,.298),(.087,2.023,.047),DARK,.011)
    barrels.sphere((0,-2.142,.355),.037,ACCENT,sub=2)
    box(fore,(0,-.851,.017),(.511,1.037,.267),WOOD,.068)
    for side in (-1,1):
        for j in range(4):
            box(fore,(side*.258,-1.12+j*.168,.043),(.022,.077,.134),"855039",.014)
    attach_points(a,(0,.495,-.107),(0,-.855,-.116),(0,-2.293,.192),
                  MuzzleL=(.121,-2.293,.192),MuzzleR=(-.121,-2.293,.192),
                  Hinge=(0,-.102,.080))


def pump():
    a=kit.asset("GunPump")
    main=part(a,"Main"); slide=part(a,"Pump"); bolt=part(a,"Bolt"); butt=part(a,"Stock")
    box(main,(0,-.042,.133),(.47,1.194,.395),"4A525F",.055)
    box(main,(0,-.031,.345),(.392,1.025,.102),DARK,.025)
    muzzle(main,0,-2.35,-.592,.204,.135)
    muzzle(main,0,-1.963,-.593,-.045,.115,BLACK)
    box(main,(0,-1.988,.072),(.292,.092,.416),"687580",.026)
    box(main,(0,-2.244,.365),(.073,.107,.109),DARK,.013)
    box(main,(0,-2.246,.421),(.043,.054,.025),ACCENT,.008)
    box(slide,(0,-1.221,-.045),(.527,.762,.387),"7F4D32",.062)
    for j in range(8):
        y=-1.56+j*.096
        box(slide,(0,y,-.072),(.553,.042,.364),"B97643" if j%2 else "A8693B",.021)
    weapons.grip(main,.349,-.366,"3D414A"); weapons.trigger(main,.071,-.113)
    stock(butt,.556,1.528,"7F4D32",bottom=-.362)
    port(main,bolt,-.051,.21)
    attach_points(a,(0,.331,-.119),(0,-1.224,-.226),(0,-2.352,.204),
                  PumpPivot=(0,-1.221,-.045),BoltPivot=(-.261,-.051,.21))


def mp5():
    a=kit.asset("GunMP5")
    main=part(a,"Main"); mag=part(a,"Magazine"); bolt=part(a,"Bolt"); butt=part(a,"Stock")
    box(main,(0,-.102,.136),(.363,1.313,.373),"4A5362",.052)
    box(main,(0,-.17,.34),(.331,1.32,.137),DARK,.036)
    box(main,(0,-.897,.129),(.423,.69,.318),"333D49",.066)
    muzzle(main,0,-1.655,-1.206,.174,.098)
    muzzle(main,0,-1.745,-1.592,.174,.120,"667483")
    for side in (-1,1):
        for j in range(5):
            box(main,(side*.215,-1.134+j*.107,.104),(.026,.050,.132),"556270",.012)
        box(butt,(side*.137,.994,.171),(.095,.987,.098),EDGE,.019)
        weapons.screw(main,side*.189,.397,.132)
    box(butt,(0,1.478,.007),(.339,.127,.582),DARK,.035)
    box(butt,(0,1.535,-.013),(.368,.081,.527),BLACK,.026)
    main.torus((0,-1.366,.458),.119,.034,BLACK,rot=(90,0,0),seg=14,rseg=5)
    box(main,(0,-1.367,.337),(.112,.136,.204),DARK,.023)
    box(main,(0,-1.367,.441),(.039,.051,.120),EDGE,.012)
    main.cyl((0,.322,.471),.093,.093,.104,BLACK,seg=12,smooth=False)
    box(main,(0,.33,.535),(.083,.083,.023),EDGE,.008)
    box(main,(0,-.191,-.101),(.350,.376,.155),DARK,.033)
    rings=[]
    for z,y,depth in [(-.141,-.184,.156),(-.303,-.214,.153),
                       (-.52,-.281,.148),(-.726,-.367,.148)]:
        rings.append([(-.109,y-depth,z),(.109,y-depth,z),(.109,y+depth,z),(-.109,y+depth,z)])
    mag.loft(rings,"465362",smooth=False)
    box(mag,(0,-.376,-.738),(.269,.338,.066),"677586",.024,rot=(-15,0,0))
    for side in (-1,1):
        box(mag,(side*.115,-.267,-.467),(.025,.093,.385),"596977",.013,rot=(-22,0,0))
    weapons.grip(main,.303,-.363,"394350"); weapons.trigger(main,.046,-.091)
    port(main,bolt,-.034,.209)
    attach_points(a,(0,.296,-.111),(0,-.885,-.062),(0,-1.747,.174),
                  MagazinePivot=(0,-.184,-.14),BoltPivot=(-.261,-.034,.209))


def kalash_preview():
    weapons.rifle("AK")
    asset=kit.ASSETS["V3_GunAK"]
    magazine=next(mesh for mesh in asset.parts if mesh.name=="Magazine")
    for vertex in magazine.bm.verts:
        vertex.co.x *= -1
        vertex.co.y = -.52 - vertex.co.y
    magazine.bm.normal_update()
    JOINTS[asset.name] = {key:list(kit.to_rbx(pos)) for key,pos in ANCHORS[asset.name].items()}


def build():
    pulik()
    double_barrel()
    pump()
    mp5()
    kalash_preview()
