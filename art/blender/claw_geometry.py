"""Angular digits and ridged keratin talons for the articulated monster meshes."""
from mathutils import Vector

def _frame(direction):
    axis = direction.normalized()
    across = Vector((1, 0, 0))
    if abs(axis.dot(across)) > .9:
        across = Vector((0, 1, 0))
    across = (across - axis * across.dot(axis)).normalized()
    return across, axis.cross(across).normalized()


def digit_link(mesh, start, end, width, depth, color):
    start, end = Vector(start), Vector(end)
    across, normal = _frame(end - start)
    corners = [(-.5,-.32),(-.32,-.5),(.32,-.5),(.5,-.32),
               (.5,.32),(.32,.5),(-.32,.5),(-.5,.32)]
    mesh.loft([
        [center+across*(u*width*scale)+normal*(v*depth*scale) for u,v in corners]
        for center,scale in [(start,.94),(start.lerp(end,.78),.88),(end,.68)]
    ],color,smooth=False)


def finger(mesh, start, joint, end, width, depth, color):
    start, joint, end = Vector(start), Vector(joint), Vector(end)
    incoming, outgoing = (joint-start).normalized(), (end-joint).normalized()
    tangent = (incoming+outgoing).normalized()
    corners = [(-.5,-.28),(-.30,-.5),(.30,-.5),(.5,-.28),
               (.5,.28),(.30,.5),(-.30,.5),(-.5,.28)]
    # A continuous skin surface swells slightly around the joint, without a cuff.
    stations = [(start,incoming,.92),
                (start.lerp(joint,.72),incoming,1.01),
                (joint,tangent,1.07),
                (joint.lerp(end,.30),outgoing,.85),
                (end,outgoing,.70)]
    rings=[]
    for center,direction,scale in stations:
        across,normal = _frame(direction)
        rings.append([center+across*(u*width*scale)+normal*(v*depth*scale)
                      for u,v in corners])
    mesh.loft(rings,color,smooth=False)


def talon(mesh, root, bend, tip, width, depth, color, edge):
    root, bend, tip = Vector(root), Vector(bend), Vector(tip)
    across, normal = _frame(bend-root)
    # The five-sided section forms a long dorsal ridge and a thinner cutting edge.
    profile = [(-.50,-.23),(0,.61),(.50,-.23),(.28,-.46),(-.28,-.46)]
    mesh.loft([
        [center+across*(x*width*scale)+normal*(y*depth*scale) for x,y in profile]
        for center,scale in [(root,1),(bend,.57),(tip,.018)]
    ],lambda i: color if i==0 else edge,smooth=False)


def hand(mesh, wrist, side, color, tip, length=1, spread=1, curled=False, digits=4):
    x,y,z = wrist
    palm_width = .37*spread
    palm = [(-.50,-.33),(-.33,-.5),(.33,-.5),(.50,-.33),
            (.50,.33),(.33,.5),(-.33,.5),(-.50,.33)]
    mesh.loft([
        [(x+u*palm_width*scale, y-.052+v*.23, level) for u,v in palm]
        for level,scale in [(z+.035,.57),(z-.105,1),(z-.238,.89)]
    ],color,smooth=False)
    spacing=.108*spread
    for i in range(digits):
        offset=(i-(digits-1)*.5)*spacing
        drop=length*(.81 if i in (0,digits-1) else .99)
        start=(x+offset,y-.070,z-.202)
        if curled:
            knuckle=(x+offset,y-.232,z-.285)
            end=(x+offset,y-.353,z-.152)
            claw_bend=(x+offset,y-.326,z-.040)
            claw_tip=(x+offset,y-.230,z-.059)
        else:
            knuckle=(x+offset*1.30+side*.029,y-.108,z-.263-drop*.36)
            end=(x+offset*1.62+side*.056,y-.240,z-.272-drop*.72)
            claw_bend=(x+offset*1.72+side*.063,y-.370,z-.280-drop*.93)
            claw_tip=(x+offset*1.61+side*.045,y-.458,z-.281-drop)
        finger(mesh,start,knuckle,end,.067*spread,.075,color)
        talon(mesh,end,claw_bend,claw_tip,.059*spread,.067,tip,"81726B")
    thumb=(x-side*.14*spread,y-.055,z-.048)
    thumb_joint=(x-side*.28*spread,y-.191,z-.165)
    thumb_end=(x-side*.315*spread,y-.282,z-.271)
    finger(mesh,thumb,thumb_joint,thumb_end,.085*spread,.087,color)
    talon(mesh,thumb_end,(x-side*.302*spread,y-.380,z-.319),
          (x-side*.216*spread,y-.416,z-.333),.066*spread,.069,tip,"81726B")


def paw(mesh, x, y, width, reach, skin="3E333C", nail="645349", edge="A18E78"):
    # A compact weight-bearing pad replaces the round ball-shaped palm.
    outline = [(-.78,.20),(.78,.20),(1,.05),(.94,-.16),
               (.53,-.225),(-.53,-.225),(-.94,-.16),(-1,.05)]
    mesh.loft([
        [(x+u*width*scale,y+v,level) for u,v in outline]
        for level,scale in [(.014,.85),(.087,1),(.222,.88)]
    ],skin,smooth=False)
    spacing=width*.51
    for i in range(4):
        offset=(i-1.5)*spacing
        finger_reach=reach*(.87 if i in (0,3) else 1)
        first=(x+offset,y-.146,.139)
        knuckle=(x+offset*1.14,y-finger_reach*.43,.121)
        root=(x+offset*1.31,y-finger_reach*.65,.097)
        bend=(x+offset*1.40,y-finger_reach*.87,.052)
        tip=(x+offset*1.38,y-finger_reach,.016)
        finger(mesh,first,knuckle,root,width*.205,.073,skin)
        talon(mesh,root,bend,tip,width*.217,.067,nail,edge)
