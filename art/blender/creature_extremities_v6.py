"""Three distinct anatomies. Linear sections keep fingers and talons crisp."""
from mathutils import Vector
from claw_geometry import _frame, talon


def sweep(mesh, sections, color, profile=None):
    profile = profile or [(-.5,-.28),(-.30,-.5),(.30,-.5),(.5,-.28),
                          (.5,.28),(.30,.5),(-.30,.5),(-.5,.28)]
    centers=[Vector(s[:3]) for s in sections]
    rings=[]
    for i,(_,_,_,width,depth) in enumerate(sections):
        direction=centers[min(i+1,len(centers)-1)]-centers[max(i-1,0)]
        across,normal=_frame(direction)
        rings.append([centers[i]+across*(u*width)+normal*(v*depth) for u,v in profile])
    mesh.loft(rings,color,smooth=False)


def deer_hand(mesh,wrist,side,color,tip,length=.53,spread=1,curled=False):
    """Narrow three-finger grasp, opposing thumb, black hooked keratin tips."""
    x,y,z=wrist
    # The palm tapers to the wrist and has a triangular knuckle line.
    palm=[(-.5,-.25),(-.32,-.5),(.32,-.5),(.5,-.25),
          (.40,.35),(0,.5),(-.40,.35)]
    mesh.loft([[(x+u*w,y+v*d,level) for u,v in palm]
               for level,w,d in [(z+.035,.17,.16),(z-.115,.31,.18),
                                  (z-.235,.265,.15)]],color,smooth=False)
    if curled:
        # Each finger wraps around the vertical shaft at y-.21, at its own height.
        for i in range(3):
            level=z-.075-i*.075
            sweep(mesh,[(x+side*.105,y-.045,level,.073,.067),
                        (x+side*.130,y-.17,level-.017,.077,.066),
                        (x+side*.070,y-.285,level-.025,.060,.052),
                        (x-side*.050,y-.302,level+.006,.043,.037)],color)
            talon(mesh,(x-side*.050,y-.302,level+.006),
                  (x-side*.115,y-.267,level+.028),
                  (x-side*.106,y-.188,level+.023),.042,.039,"211C23","332B32")
        sweep(mesh,[(x-side*.108,y-.018,z-.02,.086,.073),
                    (x-side*.167,y-.133,z+.008,.071,.062),
                    (x-side*.137,y-.259,z-.022,.051,.043)],color)
        talon(mesh,(x-side*.137,y-.259,z-.022),
              (x-side*.058,y-.302,z-.060),(x+side*.015,y-.252,z-.069),
              .048,.047,"211C23","332B32")
        return

    scale=length/.53
    for i,(offset,drop,fan) in enumerate([(-.108,.57,-.105),(0,.70,0),(.108,.54,.105)]):
        start=(x+offset,y-.035,z-.205)
        joint=(x+offset+fan*.55,y-.092,z-.205-drop*.49*scale)
        end=(x+offset+fan,y-.185,z-.205-drop*.79*scale)
        sweep(mesh,[(*start,.077,.072),
                    (*joint,.063,.061),(*end,.043,.043)],color)
        talon(mesh,end,(end[0]+fan*.15,y-.29,z-.205-drop*.98*scale),
              (end[0]-fan*.03,y-.365,z-.205-drop*.97*scale),
              .047,.055,"211C23","332B32")
    sweep(mesh,[(x-side*.121,y+.014,z-.078,.087,.078),
                (x-side*.265,y-.110,z-.202,.067,.061),
                (x-side*.291,y-.237,z-.317,.043,.045)],color)
    talon(mesh,(x-side*.291,y-.237,z-.317),
          (x-side*.247,y-.331,z-.387),(x-side*.145,y-.347,z-.371),
          .050,.052,"211C23","332B32")


def ring_paw(mesh,x,y,width,reach,hind=False):
    """A low heavy reptilian pad: three foretoes, two broader rear toes, side spur."""
    skin="41343D"
    # Eight-sided, broad heel; the front is scalloped into substantial toes.
    outline=[(-.72,.22),(.72,.22),(1.12,.035),(.91,-.16),
             (.45,-.24),(-.45,-.24),(-.91,-.16),(-1.12,.035)]
    mesh.loft([[(x+u*width*scale,y+v,level) for u,v in outline]
               for level,scale in [(.014,.85),(.13,1),(.29,.76)]],skin,smooth=False)
    count=2 if hind else 3
    for i in range(count):
        offset=(i-(count-1)*.5)*width*(.97 if hind else .77)
        fan=offset*.40
        full_reach=reach*(1.09 if i==count//2 else .94)
        thick=width*(.74 if hind else .60)
        sweep(mesh,[(x+offset,y-.09,.17,thick,.15),
                    (x+offset+fan*.55,y-full_reach*.40,.15,thick*1.06,.17),
                    (x+offset+fan,y-full_reach*.67,.095,thick*.69,.115)],skin)
        # Short dorsal scales emphasize the pressure-bearing knuckle rather than fingers.
        sweep(mesh,[(x+offset,y-.12,.255,thick*.74,.045),
                    (x+offset+fan*.70,y-full_reach*.42,.221,thick*.58,.036)],
              "67505B",profile=[(-.5,-.5),(0,.5),(.5,-.5)])
        talon(mesh,(x+offset+fan,y-full_reach*.64,.105),
              (x+offset+fan*1.18,y-full_reach*.89,.072),
              (x+offset+fan*1.05,y-full_reach*1.08,.019),
              thick*.72,.13,"796B59","BAAD90")
    side=1 if x>0 else -1
    talon(mesh,(x+side*width*.90,y+.03,.175),
          (x+side*width*1.42,y-.035,.161),
          (x+side*width*1.51,y-.162,.07),
          width*.32,.092,"554348","9A8970")


def cave_hand(mesh,wrist,side):
    """Five uneven, very long skeletal digits; the fingertip is the claw itself."""
    x,y,z=wrist
    skin="201B24"
    palm=[(-.5,-.38),(-.28,-.5),(.28,-.5),(.5,-.38),
          (.5,.38),(.28,.5),(-.28,.5),(-.5,.38)]
    mesh.loft([[(x+u*width,y+v*depth,level) for u,v in palm]
               for level,width,depth in [(z+.025,.13,.13),(z-.105,.235,.105),
                                          (z-.226,.212,.078)]],skin,smooth=False)
    for i,(offset,drop,fan) in enumerate([(-.087,.59,-.13),(-.029,.79,-.04),
                                        (.029,.715,.055),(.087,.51,.16)]):
        # The mismatched joints and sideways elbows break the repeated rake silhouette.
        knee_z=z-.218-drop*.48
        end_z=z-.218-drop*.84
        tip_z=z-.218-drop
        sweep(mesh,[(x+offset,y-.012,z-.187,.043,.046),
                    (x+offset+fan*.45,y-.092,knee_z,.050,.043),
                    (x+offset+fan*.80,y-.158,end_z,.026,.029),
                    (x+offset+fan,y-.240,tip_z,.0035,.006)],
              lambda j: [skin,"29222E","1B1720"][j])
    sweep(mesh,[(x-side*.085,y+.006,z-.060,.057,.059),
                (x-side*.207,y-.035,z-.237,.053,.047),
                (x-side*.297,y-.130,z-.430,.032,.031),
                (x-side*.249,y-.243,z-.557,.0035,.005)],skin)


def cave_foot(mesh,x,y,width,reach):
    """Narrow bony heel and three long black toes, separate from the broad RingMaw paw."""
    skin="211C25"
    outline=[(-.52,.12),(.52,.12),(.72,-.04),(.63,-.17),
             (0,-.205),(-.63,-.17),(-.72,-.04)]
    mesh.loft([[(x+u*width,y+v,level) for u,v in outline]
               for level in (.014,.155,.242)],skin,smooth=False)
    for offset,factor,fan in [(-width*.45,.84,-.08),(0,1.17,0),
                              (width*.45,.94,.08)]:
        sweep(mesh,[(x+offset,y-.11,.125,.060,.069),
                    (x+offset+fan*.45,y-reach*.47,.105,.053,.059),
                    (x+offset+fan,y-reach*factor*.83,.047,.029,.038),
                    (x+offset+fan*1.12,y-reach*factor,.017,.004,.006)],
              skin)
