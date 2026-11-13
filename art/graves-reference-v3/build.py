"""Standalone grave proposals. Does not open or modify the Roblox place."""
import bpy, math, json, sys
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parent
for d in ('models', 'previews'):
    (ROOT/d).mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
M = {}; parts = []; catalog = []

def material(name, color, metal=0, rough=.4, glow=0):
    if name in M: return M[name]
    m = bpy.data.materials.new(name); m.use_nodes = True
    def lin(c):
        c = int(c,16)/255
        return c/12.92 if c <= .04045 else ((c+.055)/1.055)**2.4
    rgba = tuple(lin(color[i:i+2]) for i in (0,2,4))+(1,)
    m.diffuse_color=rgba; s=m.node_tree.nodes.get('Principled BSDF')
    s.inputs['Base Color'].default_value=rgba
    s.inputs['Metallic'].default_value=metal; s.inputs['Roughness'].default_value=rough
    s.inputs['Emission Color'].default_value=rgba; s.inputs['Emission Strength'].default_value=glow
    M[name]=m; return m

def finish(o, name, mat, bevel=0):
    o.name=name; o.data.materials.append(mat)
    if bevel:
        b=o.modifiers.new('Rounded sculpted edges','BEVEL');b.width=bevel;b.segments=3
        bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=b.name)
    for p in o.data.polygons:p.use_smooth=True
    n=o.modifiers.new('Weighted normals','WEIGHTED_NORMAL');n.keep_sharp=True;n.weight=50
    bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=n.name)
    parts.append(o);return o

def box(name,p,s,m,b=.04):
    bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=bpy.context.object;o.scale=s
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return finish(o,name,m,b)

def poly(name,pts,y,d,m,b=.025):
    k=len(pts);v=[(x,y+dy,z) for dy in (-d/2,d/2) for x,z in pts]
    f=[tuple(range(k)),tuple(reversed(range(k,2*k)))]+[(i,i+k,(i+1)%k+k,(i+1)%k) for i in range(k)]
    me=bpy.data.meshes.new(name);me.from_pydata(v,[],f);me.update()
    o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o)
    # Recalculate normals because artwork polygons can have either winding.
    bpy.context.view_layer.objects.active=o;o.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.object.mode_set(mode='OBJECT');o.select_set(False)
    return finish(o,name,m,b)

def arch(name,w,bottom,spring,y,d,m,bevel=.055):
    pts=[(-w,bottom),(w,bottom),(w,spring)]
    pts += [(w*math.cos(i*math.pi/24),spring+w*math.sin(i*math.pi/24)) for i in range(1,25)]
    return poly(name,pts,y,d,m,bevel)

def stroke(name,points,r,m,smooth=False):
    c=bpy.data.curves.new(name,'CURVE');c.dimensions='3D';c.resolution_u=1;c.bevel_depth=r;c.bevel_resolution=2
    if smooth:
        s=c.splines.new('BEZIER');s.bezier_points.add(len(points)-1)
        for p,v in zip(s.bezier_points,points):p.co=v;p.handle_left_type='AUTO';p.handle_right_type='AUTO'
        c.resolution_u=6
    else:
        s=c.splines.new('POLY');s.points.add(len(points)-1)
        for p,v in zip(s.points,points):p.co=(*v,1)
    o=bpy.data.objects.new(name,c);bpy.context.collection.objects.link(o)
    bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o;bpy.ops.object.convert(target='MESH')
    return finish(bpy.context.object,name,m)

def leaf(name,base,tip,width,m):
    a=Vector(base); b=Vector(tip);v=b-a;side=Vector((v.z,0,-v.x)).normalized()*width
    mid=a+v*.48
    verts=[tuple(a),tuple(mid+side),tuple(b),tuple(mid-side),tuple(mid+Vector((0,-width*.45,0)))]
    me=bpy.data.meshes.new(name);me.from_pydata(verts,[],[(0,1,4),(1,2,4),(2,3,4),(3,0,4),(0,3,2,1)])
    o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o);return finish(o,name,m,.008)

def curved_outline(points, samples=5):
    """Closed Catmull-Rom contour, used for soft sculpted silhouettes."""
    out=[];n=len(points)
    for i in range(n):
        p0=Vector(points[(i-1)%n]);p1=Vector(points[i]);p2=Vector(points[(i+1)%n]);p3=Vector(points[(i+2)%n])
        for j in range(samples):
            t=j/samples
            p=.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t*t+(-p0+3*p1-3*p2+p3)*t*t*t)
            out.append(tuple(p))
    return out

def ellipse(name,x,z,rx,rz,y,depth,mat,angle=0):
    a=math.radians(angle)
    pts=[]
    for j in range(32):
        t=j*math.tau/32;px=rx*math.cos(t);pz=rz*math.sin(t)
        pts.append((x+px*math.cos(a)-pz*math.sin(a),z+px*math.sin(a)+pz*math.cos(a)))
    return poly(name,pts,y,depth,mat,min(depth*.35,.018))

def pebble(name,p,scale,mat):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=1,location=p)
    o=bpy.context.object;o.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return finish(o,name,mat)

def soft_leaf(name,base,tip,width,mat):
    a=Vector(base);b=Vector(tip);direction=b-a;side=Vector((direction.z,0,-direction.x)).normalized()
    verts=[]
    for t in (0,.2,.45,.7,.90,1):
        center=a+direction*t;center.y-=.15*math.sin(t*math.pi)
        w=width*math.sin(t*math.pi)**.7
        verts.extend([tuple(center-side*w),tuple(center+Vector((0,-w*.35,0))),tuple(center+side*w)])
    faces=[]
    for j in range(5):
        for k in (0,1):
            i=j*3+k;faces.append((i,i+1,i+4,i+3))
    me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update()
    o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o)
    bpy.context.view_layer.objects.active=o;o.select_set(True)
    mod=o.modifiers.new('Solid leaf','SOLIDIFY');mod.thickness=.015
    bpy.ops.object.modifier_apply(modifier=mod.name);o.select_set(False)
    return finish(o,name,mat)

base=material('Rock • soft plum','4E4165',0,.8)
grass=material('Grass • spring green','72C92A',0,.7)
grasslight=material('Grass • lime tips','A2E33A',0,.65)
soil=material('Rock • warm facets','67547D',0,.78)
palettes=[
 ('Wooden','BC763D','E7B36C','704022',0),
 ('Stone','8B9BB6','C7DAEC','405575',0),
 ('Marble','D3E9DB','F5F6DB','789D92',.03),
 ('Golden','FFC20A','FFDE46','9B5709',.34),
 ('Lunar','7961D1','C4DFFF','3D2B7B',.12),
]
if '--gold-only' in sys.argv:palettes=[p for p in palettes if p[0]=='Golden']
for kind,bodyhex,rimhex,darkhex,metal in palettes:
    parts=[]
    body=material(kind+' • body',bodyhex,metal,.43)
    rim=material(kind+' • soft rim',rimhex,metal,.38)
    dark=material(kind+' • inset shadow',darkhex,.03,.64)
    # A squat wonky slab on a single irregular stone, without formal plinth steps.
    rockshape=[(-1.31,.10),(-1.21,-.43),(-.64,-.67),(.50,-.66),(1.28,-.38),(1.34,.12),(.91,.55),(-.81,.56)]
    verts=[(x,y,z) for z in (0,.27) for x,y in rockshape];n=len(rockshape)
    faces=[tuple(reversed(range(n))),tuple(range(n,n*2))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    me=bpy.data.meshes.new('Lopsided rock');me.from_pydata(verts,[],faces)
    o=bpy.data.objects.new('Base / single soft rock',me);bpy.context.collection.objects.link(o);finish(o,o.name,base,.115)
    pebble('Base / little stone',(-1.03,-.37,.23),(.28,.22,.12),soil)
    pebble('Base / little stone',(.94,.22,.25),(.22,.19,.10),soil)
    start=len(parts)
    outline=[(-.77,.26),(.77,.26),(.89,.40),(.98,1.57),(1.01,1.88),(.88,2.20),(.50,2.52),(.03,2.64),(-.49,2.54),(-.88,2.27),(-1.02,1.93),(-.98,1.56),(-.90,.45)]
    shape=curved_outline(outline,4)
    poly('Headstone / pudgy asymmetrical body',shape,.01,.54,body,.09)
    poly('Headstone / single thick rounded rim',[(x*.99,.29+(z-.29)*.98) for x,z in shape],-.25,.19,rim,.075)
    poly('Headstone / warm panel shadow',[(x*.82,.39+(z-.29)*.88) for x,z in shape],-.367,.045,dark,.045)
    poly('Headstone / soft inset',[(x*.785,.42+(z-.29)*.85) for x,z in shape],-.400,.055,body,.045)
    # Short, soft side tabs make the silhouette feel like a toy.
    for side in (-1,1):
        o=box('Shoulder / rounded tab',(side*.97,-.015,1.77+side*.09),(.24,.65,.34),rim,.095)
        o.rotation_euler.y=math.radians(side*-8)
    # This emblem has round cheeks, unequal oval eyes, a floppy quiff and a gappy smile.
    face_start=len(parts)
    head_controls=[(-.49,.18),(-.39,.40),(-.11,.46),(.28,.40),(.48,.22),(.48,-.12),(.33,-.36),(.05,-.44),(-.27,-.39),(-.48,-.23)]
    head=curved_outline(head_controls,5)
    poly('Face / shallow outline',[(x*1.05,1.43+z*1.05) for x,z in head],-.460,.065,dark,.027)
    poly('Face / round squishy cheeks',[(x,1.43+z) for x,z in head],-.505,.10,rim,.035)
    hair=[(-.54,.24),(-.56,.43),(-.39,.60),(-.17,.64),(-.03,.78),(.16,.82),(.15,.64),(.39,.57),(.55,.38),(.32,.41),(.29,.22),(.10,.34),(-.06,.20),(-.20,.32),(-.38,.21)]
    poly('Face / floppy fringe shadow',[(x,1.43+z) for x,z in hair],-.537,.09,dark,.035)
    poly('Face / floppy rounded fringe',[(x*.99,1.456+z) for x,z in hair],-.582,.095,rim,.045)
    # Eye inlays are broad and rounded; no square sockets or straight mouth.
    ellipse('Face / big curious eye',-.22,1.48,.125,.157,-.563,.026,dark,-14)
    ellipse('Face / small cheeky eye',.205,1.49,.095,.114,-.563,.026,dark,17)
    ellipse('Face / big eye glint',-.247,1.535,.029,.036,-.581,.018,rim,-14)
    ellipse('Face / small eye glint',.183,1.525,.022,.027,-.581,.018,rim,17)
    # A tiny crooked oval nose, with a generous crescent grin.
    ellipse('Face / button nose',.005,1.32,.037,.046,-.564,.025,dark,-22)
    mouth=curved_outline([(-.255,-.22),(-.10,-.245),(.09,-.22),(.27,-.13),(.25,-.29),(.09,-.385),(-.10,-.37),(-.23,-.31)],5)
    poly('Face / happy crooked open smile',[(x,1.43+z) for x,z in mouth],-.564,.027,dark,.012)
    o=box('Face / big single tooth',(-.085,-.588,1.175),(.112,.035,.105),rim,.025);o.rotation_euler.y=math.radians(-10)
    o=box('Face / little lower tooth',(.118,-.588,1.102),(.073,.031,.065),rim,.021);o.rotation_euler.y=math.radians(14)
    # One lifted eyebrow and dimples reinforce the mischievous expression.
    stroke('Face / lifted brow',[(-.36,-.565,1.745),(-.26,-.565,1.795),(-.15,-.565,1.785)],.020,dark,True)
    for x,z in ((-.35,1.24),(.35,1.30)):
        ellipse('Face / dimple',x,z,.025,.018,-.559,.018,dark)
    # Rotate the entire emblem, including its inlays, for a natural wonky pose.
    angle=math.radians(9);pivot=Vector((0,-.50,1.45))
    from mathutils import Matrix
    rot=Matrix.Rotation(angle,4,'Y')
    for o in parts[face_start:]:
        o.matrix_world=Matrix.Translation(pivot)@rot@Matrix.Translation(-pivot)@o.matrix_world
    # Simple puffy earth/cloud embossing at the bottom, not an architectural border.
    cloud=curved_outline([(-.57,.57),(-.53,.70),(-.40,.72),(-.34,.64),(-.24,.80),(-.10,.80),(-.025,.67),(.12,.71),(.23,.64),(.34,.72),(.48,.70),(.56,.58)],4)
    # Only use the upper silhouette; a little filled relief reads better at icon size.
    upper=[(-.57,.57),(-.53,.70),(-.40,.72),(-.34,.64),(-.24,.80),(-.10,.80),(-.025,.67),(.12,.71),(.23,.64),(.34,.72),(.48,.70),(.56,.58)]
    stroke('Ornament / little puffy cloud',[(x,-.446,z) for x,z in upper],.028,rim,True)
    if kind=='Wooden':
        for x in (-.62,.60):
            stroke('Wood / curved grain',[(x,-.438,.86),(x-.02,-.438,1.12),(x+.035,-.438,1.46),(x,-.438,1.79)],.012,dark,True)
        ellipse('Wood / knot',-.58,.99,.045,.07,-.445,.018,dark,-12)
    elif kind=='Stone':
        stroke('Stone / little crack',[(-.56,-.438,2.16),(-.47,-.438,2.04),(-.50,-.438,1.95)],.015,dark)
    elif kind=='Marble':
        vein=material('Marble • jade veins','99C2B0',0,.55)
        stroke('Marble / one flowing vein',[(.56,-.438,1.76),(.60,-.438,1.92),(.48,-.438,2.06),(.51,-.438,2.19)],.012,vein,True)
    elif kind=='Lunar':
        ice=material('Lunar • ice inlay','A8F1FF',.08,.43,.08)
        cres=[(-.29+.105*math.cos(math.radians(a)),2.24+.105*math.sin(math.radians(a))) for a in range(60,301,6)]
        cres += [(-.2375+.0909*math.cos(math.radians(a)),2.24+.0909*math.sin(math.radians(a))) for a in range(270,89,-6)]
        poly('Lunar / tiny crescent',cres,-.455,.035,ice,.007)
        for side in (-1,1):
            o=pebble('Lunar / rounded little crystal',(side*.83,-.35,.39),(.12,.11,.20),ice)
    # A small sideways lean is part of the mesh design, rather than a render trick.
    pivot=Vector((0,0,.27));rot=Matrix.Rotation(math.radians(-5),4,'Y')
    for o in parts[start:]:o.matrix_world=Matrix.Translation(pivot)@rot@Matrix.Translation(-pivot)@o.matrix_world
    # Broad curved grass is asymmetrical, like the reference's little green tufts.
    for side in (-1,1):
        for j,(dx,h) in enumerate(((-.24,.21),(-.13,.39),(0,.44),(.17,.33),(.31,.18))):
            bx=side*(1.04 if side==1 else 1.02);by=-.36 if side==1 else -.20
            soft_leaf('Grass / fat curved blade',(bx,by,.20),(bx+dx,by-.06,.20+h),.075,grasslight if j%2 else grass)
    collection=bpy.data.collections.new('Grave_'+kind);bpy.context.scene.collection.children.link(collection)
    for o in parts:
        for c in list(o.users_collection):c.objects.unlink(o)
        collection.objects.link(o)
    bpy.ops.object.select_all(action='DESELECT')
    for o in parts:o.select_set(True)
    bpy.context.view_layer.objects.active=parts[0]
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    bpy.ops.export_scene.gltf(filepath=str(ROOT/'models'/('Grave_'+kind+'.glb')),use_selection=True,export_format='GLB')
    triangles=0
    for o in parts:o.data.calc_loop_triangles();triangles+=len(o.data.loop_triangles)
    coords=[o.matrix_world@Vector(v) for o in parts for v in o.bound_box]
    bounds=[[min(v[i] for v in coords),max(v[i] for v in coords)] for i in range(3)]
    catalog.append(dict(name='Grave_'+kind,triangles=triangles,objects=len(parts),bounds=bounds))

for co in bpy.data.collections:
    if co.name.startswith('Grave_'):co.hide_render=True
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=40;scene.cycles.use_denoising=True
scene.render.resolution_x=1000;scene.render.resolution_y=1060;scene.render.resolution_percentage=100
scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.38,.38,.40,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.7
scene.view_settings.view_transform='AgX'
floor=material('Review only • floor','F1EADB',0,.85)
box('REVIEW ONLY / floor',(0,0,-.14),(200,200,.2),floor,0)
for p,e,size in [((-3,-4,7),600,4),((4,-1,5),350,4),((1,4,6),650,3)]:
    bpy.ops.object.light_add(type='AREA',location=p);o=bpy.context.object;o.data.energy=e;o.data.shape='DISK';o.data.size=size;o.rotation_euler=(Vector((0,0,1.3))-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add();cam=bpy.context.object;cam.data.type='ORTHO';cam.data.ortho_scale=3.8;scene.camera=cam
def render(name,filename,position,target=(0,0,1.30),scale=3.8):
    for row in catalog:bpy.data.collections[row['name']].hide_render=row['name']!=name
    target=Vector(target);cam.location=target+Vector(position);cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=scale
    scene.render.filepath=str(ROOT/'previews'/filename);bpy.ops.render.render(write_still=True)
for row in catalog:
    if '--lunar-render-only' not in sys.argv or row['name']=='Grave_Lunar':
        render(row['name'],row['name']+'.png',(2.55,-7,2.5))
if '--lunar-render-only' not in sys.argv:
    render('Grave_Golden','Golden_front.png',(0,-8,.9))
    render('Grave_Golden','Golden_back.png',(-3,7,2.8))
    render('Grave_Golden','Golden_face.png',(1.3,-8,1.1),(0,-.15,1.47),1.75)
for i,row in enumerate(catalog):
    co=bpy.data.collections[row['name']];co.hide_render=False
    for o in co.objects:o.location.x+=(i-(len(catalog)-1)/2)*3.25
cam.location=(8,-17,11);cam.rotation_euler=(Vector((0,0,1.3))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=18
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'models'/'Graves_Reference_V3.blend'))
(ROOT/'models'/'catalog.json').write_text(json.dumps(catalog,indent=2))
print('GRAVES_REVIEW_COMPLETE',json.dumps(catalog))
