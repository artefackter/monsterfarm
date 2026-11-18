"""Game wardrobe parts fitted to the approved floating head and two wrist pivots."""
from math import cos, pi, sin, tau

import numpy as np
from mathutils import Vector

import kit
from assets_deer import box, poly
from compact_glb import GLB


ROLES = {"Farmer":"Фермер", "Miner":"Шахтёр", "Knight":"Рыцарь",
         "King":"Король", "Punk":"Нефор", "Assassin":"Убийца"}


def library_parts(source, role):
    glb = GLB(source / f"HoodedStranger_{role}.glb")
    # Landmark fit: (source origin, target origin, XYZ scale).
    fits = {
        "Farmer": (6.77, 6.27, (1.19, 1.23, 1.05)),
        "Miner":  (6.77, 6.16, (1.12, 1.15, 1.10)),
        "Knight": (6.66, 6.13, (1.10, 1.10, 1.02)),
        "King":   (6.78, 6.25, (1.14, 1.10, 1.03)),
        "Punk":   (6.99, 6.56, (1.65, 1.77, 1.25)),
    }
    wanted = {}
    if role in fits:
        origin, target, scale = fits[role]
        wanted["Role_Headgear"] = ((0,.08,origin),(0,0,target),scale)
    if role in ("King", "Assassin"):
        wanted["Role_Cape"] = ((0,.50,4.86),(0,.52,4.60),(.77,.88,.265))
    if role == "King":
        wanted["Role_FurCollar"] = ((0,.04,4.92),(0,0,4.27),(.80,1.55,.87))
    for src in glb.doc["meshes"]:
        if src["name"] not in wanted:
            continue
        orig, dest, scale = wanted[src["name"]]
        prim, = src["primitives"]
        attr = prim["attributes"]
        pos = glb.array(attr["POSITION"])[:,[0,2,1]] * [1,-1,1]
        colors = glb.array(attr["COLOR_0"])[:,:3].copy()
        normals = glb.array(attr["NORMAL"])[:,[0,2,1]] * [1,-1,1] / scale
        normals /= np.linalg.norm(normals, axis=1, keepdims=True)
        if role == "Miner":
            # The current game uses unlit grey glass for the miner's headlamp.
            lamp = (pos[:,1] < -1.026) & (colors[:,0] > .3)
            colors[lamp] *= [.47,.56,.80]
        pts = (pos-orig)*scale+dest
        if role == "Punk":
            pts[:,0] += .40*(pos[:,1]-.15) + .27*np.maximum(0,pts[:,2]-6.55)
        yield src["name"], pts, glb.array(prim["indices"]).reshape(-1,3), colors, normals


def ellipse(z, rx, ry, n=24):
    return [(rx*cos(tau*i/n), ry*sin(tau*i/n), z) for i in range(n)]


def neckwear(asset, role):
    p = asset.part("Kerchief", attach="Head")
    p.loft([ellipse(4.27,.68,.65), ellipse(4.37,.83,.78), ellipse(4.46,.87,.83)],
           lambda i: ("962E32","C84936")[i], smooth=False)
    poly(p,[(-.56,4.40),(-.34,4.45),(.5,4.39),(.26,4.14),(-.08,3.88)],
         -.65,.13,"B83B30",bevel=.025)
    poly(p,[(-.46,4.37),(.28,4.37),(-.025,4.09)],-.73,.025,"DF6446",bevel=.012)
    if role == "Farmer":
        p.sphere((.65,-.40,4.36),(.16,.13,.12),"B13C30",sub=1)
    for vertex in p.bm.verts:
        x,y,z=vertex.co
        vertex.co=(.90*x,.90*y,z-.12)


def hood(asset):
    # The rim sits on the forehead, temples and underside, framing the entire face.
    p = asset.part("OpenHood",attach="Head")
    n = 32
    def rim(rx, rz, y, peak):
        out = []
        for i in range(n):
            t = tau*i/n
            top = max(0,sin(t))
            fold = .034*cos(5*t)
            out.append((rx*cos(t)*(1+fold), y+.08*cos(2*t), 5.35+rz*sin(t)+peak*top**9))
        return out
    outer = rim(1.30,1.33,-.55,.18)
    inner = rim(1.055,1.07,-.81,.085)
    # Close the shell at the back and return to the inside of the front rim.
    rings = [inner, rim(1.12,1.14,-.82,.10),outer,rim(1.38,1.37,.05,.20),
             rim(1.25,1.20,.63,.11),rim(.80,.80,1.03,.045),rim(.12,.13,1.26,0)]
    p.loft(rings,lambda j:("84384C","593044","40303F","302833","392C39","302632")[j],
           cap_start=False,cap_end=True,smooth=False)
    p.loft([inner,rim(1.04,1.055,-.72,.07)],"341F2E",cap_start=False,cap_end=False)
    # Two little lapels fold over the cape below the mouth.
    for side in (-1,1):
        poly(p,[(side*.93,4.55),(side*.67,4.22),(side*.22,4.02),(side*.66,4.08)],
             -.46,.095,"692E43",bevel=.02)
    p.sphere((0,-.40,4.06),(.105,.07,.105),"B4AC99",sub=1)


def punk_chain(asset):
    p = asset.part("Chain", attach="Head")
    for i in range(15):
        t = pi*(i+1)/16
        p.torus((.87*cos(t),-.84*sin(t),4.56-.27*sin(t)),.080,.023,"B4B3BF",
                rot=(83,0,(i%2)*42),seg=10,rseg=5)
    for s in (-1,1):
        p.torus((s*1.10,-.20,4.96),.12,.034,"918E9D",rot=(90,0,s*18),seg=12,rseg=5)


CUFFS = {
    "Farmer": ("355E93","5F85AC","C9A652"), "Miner": ("735B3E","B8A58B","B89248"),
    "Knight": ("788896","B4C0C8","D7BD83"), "King": ("742E48","CBA24E","E7C778"),
    "Punk": ("342E3D","7D498C","BCB9C2"), "Assassin": ("342632","77374B","A99AA0"),
}


def wrist(asset, rig, side, role):
    name = "Hand" + side
    joint = rig.data.bones[name]
    origin = joint.head_local
    along = (joint.tail_local-origin).normalized()
    bones = rig.data.bones
    wide = (bones[name+"Finger4"].head_local-bones[name+"Finger1"].head_local).normalized()
    wide = (wide - along*along.dot(wide)).normalized()
    front = along.cross(wide)
    if front.y > 0: front = -front
    breadth = 1.13 if side == "L" else 1.
    length = 1.70 if side == "L" else 1.13
    def pos(u,v,t):
        return origin + breadth*(wide*u+front*v) + along*(length*t)
    def ring(t,rx,ry):
        outline=[(-.73,-1),(.73,-1),(1,-.67),(1,.67),
                 (.73,1),(-.73,1),(-1,.67),(-1,-.67)]
        return [pos(rx*x,ry*y,t) for x,y in outline]
    p = asset.part(name+"_Cuff", attach=name)
    base, trim, rivet = CUFFS[role]
    cuff_length = .32 if role in ("Knight","Assassin") else .19
    p.loft([ring(-.065,.29,.18),ring(-.032,.30,.19),
            ring(cuff_length-.04,.35,.205),ring(cuff_length,.36,.21)],
           lambda j:(trim,base,trim)[j],smooth=False)
    p.sphere(pos(-.14,.185,.065),(.040,.035,.042),rivet,sub=1,smooth=False)
    if role=="Punk":
        for u in (-.18,0,.18):
            a = pos(u,.16,.04)
            p.tube([(*a,.062),(*(a+front*.15),.009)],rivet,seg=6,sub=1,smooth=False)
    if role=="Assassin":
        p.tube([(*pos(-.18,.17,.22),.026),(*pos(0,.216,.15),.026),
                (*pos(.20,.17,.08),.026)],trim,seg=6,sub=1)


def fitted_parts(role, rig):
    kit.ASSETS.clear()
    a = kit.asset("FloatingGrin"+role)
    if role in ("Farmer","Miner"): neckwear(a,role)
    if role=="Assassin": hood(a)
    if role=="Punk": punk_chain(a)
    if role=="King":
        p=a.part("Clasp",attach="Head")
        p.sphere((0,-.84,4.26),(.145,.061,.15),"DDB04D",sub=2,smooth=False)
        p.sphere((0,-.895,4.27),(.071,.034,.087),"B53B50",sub=1,smooth=False)
    for side in "LR": wrist(a,rig,side,role)
    return a
