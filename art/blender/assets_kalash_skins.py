"""Three original Kalash finishes on the existing weapon, with fixed curved magazine."""
import math
from mathutils import Vector
import kit
import items_v3 as weapons
from assets_v3 import ANCHORS, box

JOINTS={}
STYLES=("Asiimov","GoldenDragon","Cyberpunk")
PALETTES={
    "Asiimov":{"body":"E8EBE7","wood":"F0F1E9","metal":"AAB6BF", "dark":"222B35", "accent":"F57F24"},
    "GoldenDragon":{"body":"292C31","wood":"21262B","metal":"C39841", "dark":"151D24", "accent":"F1C761"},
    "Cyberpunk":{"body":"AEBAC1","wood":"46535F","metal":"D6E2E8", "dark":"1C2934", "accent":"37DFC9"},
}


def panel(mesh,side,points,color,x=.174,depth=.003):
    """Flush paint facet, authored on both sides in (longitudinal Y, height Z)."""
    def surface(z):
        return x(z) if callable(x) else x
    mesh.loft([[(side*(surface(z)+delta),y,z) for y,z in points]
               for delta in (0,depth)],color,smooth=False)


def stroke(mesh,side,path,color,width=.012,x=.176):
    for a,b in zip(path,path[1:]):
        dy,dz=b[0]-a[0],b[1]-a[1]
        length=math.hypot(dy,dz)
        if length<1e-6:
            continue
        uy,uz=-dz/length*width*.5,dy/length*width*.5
        panel(mesh,side,[(a[0]+uy,a[1]+uz),(b[0]+uy,b[1]+uz),
                         (b[0]-uy,b[1]-uz),(a[0]-uy,a[1]-uz)],color,x=x)


def mag_y(z):
    samples=[(-.04,-.26),(-.27,-.27),(-.50,-.34),(-.72,-.47),(-.83,-.58)]
    for (za,ya),(zb,yb) in zip(samples,samples[1:]):
        if zb<=z<=za:
            return ya+(yb-ya)*(z-za)/(zb-za)
    return samples[0][1] if z>-.04 else samples[-1][1]


def stock_surface(z):
    return .126+.050*(z+.20)/.56


def repaint(mesh,style):
    palette=PALETTES[style]
    for face in mesh.bm.faces:
        old=mesh.colors[face[mesh.layer]]
        pos=face.calc_center_median()
        color=old
        if old==weapons.WALNUT:
            color=palette['wood']
        elif old==weapons.DARK:
            color=palette['dark']
            if mesh.name=='Main' and -.745<pos.y<.55 and pos.z>-.058:
                color=palette['body']
            elif mesh.name=='Magazine':
                color=palette['body'] if style!='GoldenDragon' else '292D30'
        elif old in (weapons.STEEL,weapons.EDGE,'58626C'):
            color=palette['metal']
        if mesh.name=='Bolt':
            color=palette['metal'] if old!=weapons.DARK else palette['dark']
        face[mesh.layer]=mesh._cid(color)
    mesh.ao=.20
    mesh.ao_dist=.12
    mesh.grad=.035


def asiimov(parts):
    main,mag,stock=(parts[k] for k in ('Main','Magazine','Stock'))
    orange='F57F24'; dark='202A34'; white='EDF0E9'
    for side in (-1,1):
        # Broad, clean panel blocks stay legible at the scale of a phone HUD.
        panel(main,side,[(-.58,-.052),(-.27,-.052),(-.43,.26),(-.72,.26)],orange)
        stroke(main,side,[(-.46,-.044),(-.62,.26)],dark,.024,x=.179)
        panel(main,side,[(.22,-.051),(.44,-.051),(.56,.245),(.35,.245)],dark)
        stroke(main,side,[(.26,-.040),(.39,.242)],orange,.037,x=.179)
        for j in range(3):
            y=-.18+j*.10
            panel(main,side,[(y,.034),(y+.043,.034),(y+.043,.058),(y,.058)],dark)
        panel(main,side,[(-1.124,.006),(-.75,.006),(-.83,.234),(-1.124,.234)],orange,x=.218)
        stroke(main,side,[(-1.05,.013),(-.972,.235)],dark,.034,x=.222)
        panel(stock,side,[(.81,-.145),(1.06,-.145),(1.30,.123),(1.05,.123)],orange,x=stock_surface)
        stroke(stock,side,[(1.03,-.13),(1.26,.123)],dark,.037,x=lambda z:stock_surface(z)+.004)
        # Orange spine follows the corrected curve toward the muzzle.
        for za,zb in [(-.10,-.27),(-.27,-.50),(-.50,-.72),(-.72,-.79)]:
            panel(mag,side,[(mag_y(za)-.145,za),(mag_y(za)-.04,za),
                            (mag_y(zb)-.04,zb),(mag_y(zb)-.145,zb)],orange,x=.134)
        for z in (-.33,-.57):
            panel(mag,side,[(mag_y(z)+.02,z+.028),(mag_y(z)+.16,z+.028),
                            (mag_y(z)+.13,z-.022),(mag_y(z)-.01,z-.022)],dark,x=.140)
        box(main,(side*.159,.34,-.43),(.016,.18,.23),orange,.006,rot=(12,0,0))
    box(main,(0,-.36,.400),(.246,.21,.015),orange,.003)


def dragon_head(mesh,side,y,z,scale,x):
    # Original horned dragon silhouette: raised brow, long muzzle, forked horns.
    shape=[(-.42,-.10),(-.26,-.23),(-.05,-.19),(.08,-.10),(.36,-.07),
           (.42,.04),(.25,.13),(.08,.14),(-.07,.30),(-.13,.11),
           (-.26,.30),(-.23,.08),(-.39,.15)]
    panel(mesh,side,[(y+u*scale,z+v*scale) for u,v in shape],'F5CD6B',x=x)
    panel(mesh,side,[(y-.16*scale,z+.025*scale),(y+.05*scale,z-.005*scale),
                     (y-.10*scale,z-.075*scale)],'17252B',x=lambda h:(x(h) if callable(x) else x)+.004)


def golden_dragon(parts):
    main,mag,stock=(parts[k] for k in ('Main','Magazine','Stock'))
    gold='E6B94F'; darkgold='7E632E'
    for side in (-1,1):
        stroke(main,side,[(.46,.213),(-.69,.213)],gold,.018)
        stroke(main,side,[(.46,-.034),(-.68,-.034)],gold,.018)
        path=[(.42,.06),(.24,.16),(.02,.14),(-.14,.035),(-.33,.055),(-.43,.14)]
        stroke(main,side,path,darkgold,.051)
        stroke(main,side,[(y,z+.013) for y,z in path],gold,.023,x=.180)
        dragon_head(main,side,-.52,.125,.28,.181)
        for j in range(6):
            y=.30-j*.13
            panel(main,side,[(y,.130),(y-.035,.172),(y-.072,.123),(y-.025,.090)],
                  'F3D681' if j%2 else 'B68A39',x=.182)
        for j in range(4):
            y=-1.08+j*.10
            panel(main,side,[(y,.05),(y+.05,.11),(y+.09,.05),(y+.05,-.005)],gold,x=.218)
        stroke(main,side,[(-1.12,.22),(-.66,.22)],gold,.019,x=.218)
        # Large dragon head on the butt, with a separate sinuous gold tail.
        dragon_head(stock,side,1.15,-.02,.38,stock_surface)
        stroke(stock,side,[(.79,-.13),(.90,-.08),(.88,.04),(.98,.10),(1.08,.03)],
               gold,.024,x=stock_surface)
        for j,z in enumerate((-.18,-.30,-.42,-.54,-.66)):
            y=mag_y(z)
            for k in (-1,0,1):
                center=y+k*.115+(j%2)*.025
                panel(mag,side,[(center-.04,z+.036),(center+.04,z+.036),
                                (center+.052,z),(center,z-.041),(center-.052,z)],
                      gold if (j+k)%3 else darkgold,x=.135)
        stroke(mag,side,[(mag_y(z)-.20,z) for z in (-.12,-.27,-.50,-.72,-.79)],gold,.017,x=.140)
        box(main,(side*.159,.34,-.43),(.015,.17,.27),darkgold,.010,rot=(12,0,0))
    box(main,(0,-.18,.401),(.20,.98,.016),gold,.006)


def cyberpunk(asset,parts):
    main,mag,stock=(parts[k] for k in ('Main','Magazine','Stock'))
    cyan='37DFC9'; dark='223A48'
    glow=asset.part('Glow',attach='Main',material='Neon',ao=0,grad=0,cast=False)
    for side in (-1,1):
        panel(main,side,[(-.68,-.042),(.46,-.042),(.46,.135),(-.68,.135)],dark)
        paths=[[(.40,.07),(.21,.07),(.14,.15),(-.08,.15),(-.17,.05),(-.50,.05)],
               [(.38,.196),(.25,.196),(.16,.241),(-.17,.241)],
               [(-.33,.15),(-.43,.215),(-.61,.215)]]
        for path in paths:
            stroke(main,side,path,cyan,.014,x=.179)
        for y,z in ((.40,.07),(-.50,.05),(-.61,.215)):
            panel(glow,side,[(y-.022,z-.022),(y+.022,z-.022),
                            (y+.022,z+.022),(y-.022,z+.022)],cyan,x=.184)
        for j in range(4):
            y=-1.07+j*.105
            panel(main,side,[(y,.002),(y+.044,.002),(y+.044,.20),(y,.20)],cyan,x=.219)
        stroke(stock,side,[(.79,-.13),(.94,-.13),(1.04,.08),(1.27,.08),(1.36,.01)],
               cyan,.026,x=stock_surface)
        stroke(stock,side,[(.83,.08),(.94,.08),(1.0,.13)],'CFEBEE',.012,x=stock_surface)
        for shift in (-.11,.10):
            stroke(mag,side,[(mag_y(z)+shift,z) for z in (-.10,-.27,-.50,-.72,-.79)],
                   cyan,.024,x=.137)
        for z in (-.23,-.46,-.68):
            stroke(mag,side,[(mag_y(z)-.10,z),(mag_y(z)+.10,z)],dark,.035,x=.141)
        box(main,(side*.159,.34,-.43),(.016,.17,.24),cyan,.009,rot=(12,0,0))
    box(main,(0,-.18,.401),(.21,.22,.015),cyan,.003)


def build():
    weapons.rifle('AK')
    original=kit.ASSETS.pop('V3_GunAK')
    for style in STYLES:
        asset=kit.asset('Kalash_'+style)
        for source in original.parts:
            p=asset.part(source.name,attach=source.name,ao=.20,ao_dist=.12,grad=.035)
            p.bm.free()
            p.bm=source.bm.copy()
            p.layer=p.bm.faces.layers.int.get('c')
            p.colors=list(source.colors)
            if p.name=='Magazine':
                for vertex in p.bm.verts:
                    vertex.co.x*=-1
                    vertex.co.y=-.52-vertex.co.y
                p.bm.normal_update()
            repaint(p,style)
        parts={p.name:p for p in asset.parts}
        if style=='Asiimov':asiimov(parts)
        elif style=='GoldenDragon':golden_dragon(parts)
        else:cyberpunk(asset,parts)
        JOINTS[asset.name]={key:list(kit.to_rbx(pos)) for key,pos in ANCHORS['V3_GunAK'].items()}
        # The pivot matches the top of the corrected magazine rather than its mass center.
        JOINTS[asset.name]['MagazinePivot']=list(kit.to_rbx((0,-.26,-.04)))
