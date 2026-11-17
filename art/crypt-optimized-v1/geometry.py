"""Build the approved standalone crypt. Blender background execution."""
import bpy, bmesh, math, json
from mathutils import Vector, Matrix
from pathlib import Path

PROFILE = 'optimized'
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
groups = {}
materials = {}
active_group = 'Foundation'

def material(name, color, metal=0, rough=.75, glow=0):
    m=bpy.data.materials.new(name); m.use_nodes=True
    def lin(v):
        v=int(v,16)/255
        return v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4
    rgba=tuple(lin(color[i:i+2]) for i in (0,2,4))+(1,)
    m.diffuse_color=rgba
    p=m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value=rgba
    p.inputs['Metallic'].default_value=metal
    p.inputs['Roughness'].default_value=rough
    if glow:
        p.inputs['Emission Color'].default_value=rgba
        p.inputs['Emission Strength'].default_value=glow
    materials[name]=m
    return m

STONE=material('Stone / muted grey lavender','82798C')
EDGE=material('Stone / light edges','A49AAE')
BASE=material('Stone / foundation','686171')
MORTAR=material('Stone / shadow joints','5D5568')
ROOF=material('Roof / charcoal violet','302936')
PANEL=material('Roof / broad panels','3A3043')
BRONZE=material('Trim / aged bronze','9D7953',.18,.58)
IRON=material('Gate / dark iron','393342',.35,.58)
DEEP=material('Interior / deep violet','1B122B')
BONE=material('Skulls / pale stone','BAACB7')
SOCKET=material('Skulls / sockets','332A3A')
PURPLE=material('Inlays / violet','9D42D9',.08,.43,.28)
LIGHT=material('Lanterns / violet light','D997FF',0,.4,2)

def finish(o,name,mat,bevel=0):
    o.name=name; o.data.materials.append(mat)
    bpy.ops.object.select_all(action='DESELECT')
    o.select_set(True); bpy.context.view_layer.objects.active=o
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if PROFILE == 'optimized' and min(o.dimensions) < .20:
        bevel = 0
    if bevel:
        b=o.modifiers.new('Small edge chamfer','BEVEL'); b.width=bevel; b.segments=1
        bpy.ops.object.modifier_apply(modifier=b.name)
    for p in o.data.polygons:p.use_smooth=False
    groups.setdefault(active_group,[]).append(o)
    o.select_set(False)
    return o

def box(name,p,s,mat,bevel=.035,rot=(0,0,0)):
    bpy.ops.mesh.primitive_cube_add(size=1,location=p)
    o=bpy.context.object; o.scale=s
    o.rotation_euler=tuple(math.radians(a) for a in rot)
    return finish(o,name,mat,bevel)

def mesh(name,vertices,faces,mat,bevel=.025):
    me=bpy.data.meshes.new(name); me.from_pydata(vertices,[],faces);me.update()
    bm=bmesh.new();bm.from_mesh(me)
    bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
    bm.to_mesh(me);bm.free()
    o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o)
    return finish(o,name,mat,bevel)

def prism(name,outline,y,depth,mat,bevel=.03):
    n=len(outline)
    v=[(x,y+d,z) for d in (-depth/2,depth/2) for x,z in outline]
    faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]
    faces += [(j,(j+1)%n,(j+1)%n+n,j+n) for j in range(n)]
    return mesh(name,v,faces,mat,bevel)

def slab(name,outline,z,h,mat,bevel=.04):
    n=len(outline)
    v=[(x,y,d) for d in (z,z+h) for x,y in outline]
    return mesh(name,v,[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(j,(j+1)%n,(j+1)%n+n,j+n) for j in range(n)],mat,bevel)

def beam(name,a,b,width,depth,mat,bevel=.025):
    a,b=Vector(a),Vector(b)
    o=box(name,(a+b)/2,(width,depth,(b-a).length),mat,bevel)
    o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler()
    return o

def ball(name,p,s,mat):
    socket = 'socket' in name.lower()
    segments, rings = ((8, 6) if socket else (12, 6)) if PROFILE == 'optimized' else (12, 8)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,radius=1,location=p)
    o=bpy.context.object;o.scale=s
    return finish(o,name,mat)

def taper(name,x,y,z0,z1,base,top,mat,bevel=.035):
    vertices=[(x+sx*w/2,y+sy*d/2,z) for z,w,d in ((z0,*base),(z1,*top)) for sx,sy in ((-1,-1),(1,-1),(1,1),(-1,1))]
    return mesh(name,vertices,[(3,2,1,0),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],mat,bevel)

def arch_outline(radius,bottom,spring,n=16):
    return [(-radius,bottom),(radius,bottom)]+[(radius*math.cos(t*math.pi/n),spring+radius*math.sin(t*math.pi/n)) for t in range(n+1)]

# A clipped stone plinth: clean large shapes rather than rubble.
def clipped(w,d,c):
    return [(-w/2+c,-d/2),(w/2-c,-d/2),(w/2,-d/2+c),(w/2,d/2-c),(w/2-c,d/2),(-w/2+c,d/2),(-w/2,d/2-c),(-w/2,-d/2+c)]
slab('Lower octagonal plinth',clipped(10.9,9.1,.75),0,.32,BASE,.065)
slab('Upper stone apron',clipped(10.35,8.65,.65),.32,.25,STONE,.045)
box('Interior floor',(0,.10,.80),(7.35,6.65,.48),BASE,.035)

active_group='Shell'
# A real hollow shell, with an actual barred opening rather than a door decal.
for x in (-3.42,3.42):box('Side wall',(x,.12,2.99),(.55,6.65,4.0),STONE,.045)
box('Back wall',(0,3.16,2.99),(6.5,.57,4),STONE,.045)
box('Dark interior back',(0,2.84,2.80),(5.9,.045,3.5),DEEP,.01)
# Front wall with a true semicircular doorway cut out of it.
r=1.48;spring=3.18; top=5.0; front=-3.04
for sign in (-1,1):
    box('Front wall pier',(sign*2.38,front,3),(1.82,.58,4.0),STONE,.03)
    pts=[]
    for j in range(9):
        x=r*j/8
        pts.append((sign*x,spring+math.sqrt(max(0,r*r-x*x))))
    pts += [(sign*r,top),(0,top)]
    prism('Stone above arch',pts,front,.58,STONE,.012)
box('Eaves stone band',(0,.12,5.0),(7.65,6.95,.24),BASE,.04)
# Sparse broad courses, with recessed shadow strips.
for side in (-1,1):
    x=side*3.702
    for z in (1.95,3.0,4.05):box('Side mortar course',(x,.1,z),(.018,5.85,.036),MORTAR,.003)
    for y,z in ((-1.9,1.48),(.3,2.5),(1.8,3.55),(-.8,4.5)):
        box('Side short mortar joint',(x,y,z),(.02,.035,.85),MORTAR,.003)
    for z in (2.05,3.2,4.3):box('Front pier course',(side*2.5,-3.341,z),(1.1,.022,.038),MORTAR,.004)

active_group='Roof'
eave=5.14; ridge=7.8; half=4.07
prism('Solid roof', [(-half,eave),(half,eave),(0,ridge)], .10,7.45,ROOF,.055)
# Four broad roof courses per slope; no small tiles.
for sign in (-1,1):
    for j in range(1,5):
        t=j/5
        x=sign*half*t;z=ridge-(ridge-eave)*t
        beam('Broad roof course',(x,-3.57,z+.026),(x,3.79,z+.026),.055,.06,PANEL,.012)
beam('Roof ridge',(0,-3.7,ridge+.025),(0,3.94,ridge+.025),.2,.18,BASE,.035)
# The reference's bronze-edged triangular pediment.
prism('Stone front pediment',[(-3.48,5.10),(3.48,5.10),(0,7.39)],-3.60,.23,STONE,.035)
for x in (-3.5,3.5):beam('Bronze sloping fascia',(x,-3.76,5.10),(0,-3.76,7.45),.19,.15,BRONZE,.025)
beam('Bronze pediment base',(-3.55,-3.76,5.10),(3.55,-3.76,5.10),.20,.15,BRONZE,.025)
box('Pediment diamond frame',(0,-3.76,6.11),(1.02,.16,1.02),BASE,.035,rot=(0,45,0))
box('Pediment violet diamond',(0,-3.855,6.11),(.72,.055,.72),PURPLE,.025,rot=(0,45,0))
# One inset diamond on each visible roof pitch, seated parallel to the pitch.
pitch=math.atan2(ridge-eave,half)
for sign in (-1,1):
    center=Vector((sign*2.03,.5,6.51))
    normal=Vector((sign*math.sin(pitch),0,math.cos(pitch)))
    tangent=Vector((sign*math.cos(pitch),0,-math.sin(pitch)))
    axis=Vector((0,1,0))
    for name,scale,offset,mat in [('Roof diamond frame',1,.018,BRONZE),('Roof violet diamond',.79,.068,PURPLE)]:
        points=[center+tangent*.81*scale+normal*offset,center+axis*.69*scale+normal*offset,center-tangent*.81*scale+normal*offset,center-axis*.69*scale+normal*offset]
        verts=[tuple(p+normal*d) for d in (0,.045) for p in points]
        mesh(name,verts,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],mat,.015)

active_group='Buttresses'
for sign in (-1,1):
    x=sign*4.03;y=2.75
    box('Rear pylon foot',(x,y,.72),(2.0,1.98,.32),BASE,.055)
    taper('Rear tapered pylon',x,y,.88,7.12,(1.65,1.65),(.94,1.0),STONE,.045)
    for z,s in ((1.06,1.7),(3.05,1.44),(5.05,1.22),(7.15,1.32)):
        box('Rear pylon collar',(x,y,z),(s,s,.15),EDGE,.025)
    prism('Rear pointed cap',[(x-.70,7.24),(x+.70,7.24),(x,8.87)],y,1.32,STONE,.04)
    prism('Rear triangular recess',[(x-.45,7.45),(x+.45,7.45),(x,8.49)],y-.674,.045,MORTAR,.012)
    prism('Rear violet triangular inlay',[(x-.32,7.58),(x+.32,7.58),(x,8.30)],y-.705,.038,PURPLE,.012)
    # Front pylons stay low so they frame the arch rather than cover the pediment.
    x=sign*3.07;y=-3.52
    box('Front pylon foot',(x,y,.75),(1.6,1.6,.36),BASE,.05)
    taper('Front tapered pylon',x,y,.93,4.78,(1.35,1.35),(.91,.93),STONE,.04)
    for z,s in ((1.1,1.36),(3.0,1.17),(4.80,1.27)):
        box('Front pylon collar',(x,y,z),(s,s,.16),EDGE,.025)

active_group='Entrance'
# Nine chunky voussoirs, joined edge-to-edge around the doorway.
for j in range(9):
    a=j*math.pi/9;b=(j+1)*math.pi/9
    points=[(r*math.cos(a),spring+r*math.sin(a)),(r*math.cos(b),spring+r*math.sin(b)),((r+.37)*math.cos(b),spring+(r+.37)*math.sin(b)),((r+.37)*math.cos(a),spring+(r+.37)*math.sin(a))]
    prism('Arch stone %02d'%j,points,-3.412,.32,EDGE,.015)
for sign in (-1,1):box('Door jamb',(sign*(r+.18),-3.414,2.09),(.36,.33,2.18),EDGE,.02)
# Closed gate. Bars follow the real arch opening; there is depth behind it.
for j in range(-3,4):
    x=j*.395;bar_top=spring+math.sqrt(r*r-x*x)-.09
    box('Gate vertical bar',(x,-3.412,(1.12+bar_top)/2),(.105,.16,bar_top-1.12),IRON,.016)
for z in (1.85,3.06):box('Gate cross rail',(0,-3.435,z),(2.86,.19,.115),IRON,.018)
box('Gate center plate',(0,-3.55,2.42),(.25,.085,.36),BRONZE,.025)
for side in (-1,1):
    box('Gate hinge',(side*1.41,-3.47,2.1),(.19,.25,.32),IRON,.025)
    box('Gate hinge',(side*1.41,-3.47,3.20),(.19,.25,.32),IRON,.025)
# Four broad stone steps and narrow violet tread runners.
for i in range(4):
    top_z=(i+1)*.28
    y=-6.25+i*.67
    box('Stair %02d'%(i+1),(0,y,top_z/2),(3.52,.76,top_z),STONE,.035)
    box('Violet stair inset %02d'%(i+1),(0,y-.035,top_z+.014),(2.76,.51,.028),PURPLE,.012)
box('Door threshold',(0,-3.65,1.10),(3.52,.68,.20),EDGE,.035)
for side in (-1,1):
    beam('Sloping stair cheek',(side*1.98,-6.59,.34),(side*1.98,-3.34,1.89),.35,.37,STONE,.035)
    beam('Bronze stair edge',(side*1.98,-6.57,.55),(side*1.98,-3.37,2.08),.085,.32,BRONZE,.016)
    box('Stair cheek foot',(side*1.98,-6.55,.22),(.56,.59,.4),BASE,.035)
    box('Stair cheek head',(side*1.98,-3.48,1.62),(.54,.61,.73),EDGE,.035)

active_group='Skulls'
for sign in (-1,1):
    x=sign*3.07;y=-3.94
    ball('Stone skull cranium',(x,y,5.22),(.48,.37,.42),BONE)
    box('Stone skull jaw',(x,y-.035,4.97),(.56,.54,.23),BONE,.045)
    for dx in (-.17,.17):ball('Dark eye socket',(x+dx,y-.323,5.25),(.102,.055,.112),SOCKET)
    prism('Skull nose',[(x-.055,5.08),(x+.055,5.08),(x,5.18)],y-.381,.035,SOCKET,.009)
    for dx in (-.16,0,.16):box('Skull tooth',(x+dx,y-.329,4.905),(.10,.065,.12),BONE,.012)

active_group='Accents'
for sign in (-1,1):
    # A small narrow purple light slit on each side, rather than ornate windows.
    x=sign*3.716
    box('Side slit frame',(x,.05,3.15),(.11,.64,1.43),MORTAR,.055)
    box('Side violet slit',(x+sign*.064,.05,3.15),(.035,.28,1.03),PURPLE,.035)
box('Violet interior floor glow',(0,-1.75,1.057),(1.65,1.65,.025),PURPLE,.015)

active_group='Lanterns'
for sign in (-1,1):
    x=sign*2.91;y=-5.12
    box('Lantern foot',(x,y,.13),(.62,.62,.26),BASE,.045)
    box('Lantern post',(x,y,1.16),(.14,.14,2.03),IRON,.02)
    box('Lantern bottom',(x,y,2.13),(.57,.57,.14),IRON,.025)
    box('Violet lantern pane',(x,y,2.46),(.42,.42,.52),LIGHT,.025)
    for dx in (-.24,.24):
        for dy in (-.24,.24):box('Lantern cage',(x+dx,y+dy,2.46),(.055,.055,.59),IRON,.008)
    taper('Lantern pointed roof',x,y,2.76,3.04,(.69,.69),(.15,.15),IRON,.018)

