"""Offline replacement kit for the plaza reference. Blender Z-up, front -Y, units ~= studs."""
import bpy, math, random, json, sys
from pathlib import Path
from mathutils import Vector, Matrix

ROOT=Path(__file__).resolve().parent
for d in ('models','previews'):(ROOT/d).mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
random.seed(237)
M={}; parts=[]; roots={}; catalog=[]; anchors={}; active_role='Structure'

def material(name,h,metal=0,rough=.65,glow=0):
    if name in M:return M[name]
    def lin(c):
        c=int(c,16)/255;return c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4
    rgba=tuple(lin(h[i:i+2]) for i in (0,2,4))+(1,)
    m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=rgba
    bs=m.node_tree.nodes['Principled BSDF'];bs.inputs['Base Color'].default_value=rgba
    bs.inputs['Metallic'].default_value=metal;bs.inputs['Roughness'].default_value=rough
    bs.inputs['Emission Color'].default_value=rgba;bs.inputs['Emission Strength'].default_value=glow
    M[name]=m;return m

wood=material('Walnut beams','70412C');woodlight=material('Honey planks','B97A3D');woodedge=material('Wood cut ends','D59A51')
wooddark=material('Wood deep joints','482C29');purple=material('Purple roof','733A9C');purples=[material('Tile '+str(i),h) for i,h in enumerate(['8344AD','9450B9','744198','A35EC1'])]
violetdark=material('Roof underlay','4D2A69');gold=material('Brass','E9AD25',.42,.36);goldlight=material('Gold highlight','FFE275',.28,.38)
stone=material('Warm grey stone','92869A');stones=[material('Stone '+str(i),h) for i,h in enumerate(['ADA0B0','9A8DA0','B4A3AC','8E8299'])]
ink=material('Dark plum ink','39283E');iron=material('Lamp dark iron','423346',.2,.55);paper=material('Cream parchment','FFE2A2');white=material('Awning cream','FFF1CE')
teal=material('Gunsmith teal','58BFC3');lime=material('Brawler lime','A5CC37');amber=material('Pet shop amber','F2BC48');pink=material('Quest lavender','CF8BED')
leaves=[material('Foliage '+str(i),h) for i,h in enumerate(['639227','81AA2D','9BB936','467D2D','A9C743'])]
soil=material('Soil','62513D');lawn=material('Flower bed grass','6C9735');flower=material('Lavender petals','AA5FCA');flowerlight=material('Flower highlights','D197E8')
stem=material('Plant stems','4D7E2D');mushred=material('Mushroom red','E54A4B');petblue=material('Pet blue','58AEDC');petgreen=material('Pet green','B8D63D');petpink=material('Pet pink','F3BBCE')
glow=material('Warm lantern glow','FFD45C',0,.35,2.6);slime=material('Glowing lime slime','BAF323',0,.3,.42);slimebright=material('Slime highlights','E1FF64',0,.25,.7)
crystal=material('Amethyst','BD4DEF',.12,.3,.12);crystalhi=material('Amethyst highlights','EA8BFF',.1,.24,.22)

def role(name):
    global active_role;active_role=name

def finish(o,name,mat,bevel=0,smooth=True):
    o.name=name;o.data.materials.append(mat);o['role']=active_role
    if bevel:
        mod=o.modifiers.new('Soft edges','BEVEL');mod.width=bevel;mod.segments=2
        bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
    for p in o.data.polygons:p.use_smooth=smooth
    if smooth:
        mod=o.modifiers.new('Weighted normals','WEIGHTED_NORMAL');mod.keep_sharp=True
        bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
    parts.append(o);return o

def box(name,p,s,m,bevel=.07,rot=(0,0,0)):
    bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=bpy.context.object;o.scale=s
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    finish(o,name,m,min(bevel,min(s)*.4));o.rotation_euler=tuple(math.radians(a) for a in rot);return o

def ball(name,p,s,m,sub=2,smooth=True):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub,radius=1,location=p);o=bpy.context.object;o.scale=s if hasattr(s,'__len__') else (s,s,s)
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);return finish(o,name,m,smooth=smooth)

def cyl(name,p,r,d,m,vertices=16,bevel=.04,rot=(0,0,0),r2=None):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices,radius1=r,radius2=r if r2 is None else r2,depth=d,location=p)
    o=bpy.context.object;finish(o,name,m,bevel);o.rotation_euler=tuple(math.radians(a) for a in rot);return o

def rod(name,a,b,r,m,r2=None,vertices=10):
    a=Vector(a);b=Vector(b);o=cyl(name,(a+b)/2,r,(b-a).length,m,vertices,.018,r2=r2)
    o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return o

def torus(name,p,r,t,m,rot=(0,0,0),segments=32):
    bpy.ops.mesh.primitive_torus_add(major_segments=segments,minor_segments=6,major_radius=r,minor_radius=t,location=p)
    o=bpy.context.object;finish(o,name,m);o.rotation_euler=tuple(math.radians(a) for a in rot);return o

def mesh(name,verts,faces,m,bevel=0,smooth=True):
    me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update()
    o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o)
    bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.object.mode_set(mode='OBJECT');o.select_set(False)
    return finish(o,name,m,bevel,smooth)

def poly(name,pts,y,d,m,bevel=.035):
    n=len(pts);verts=[(x,y+dy,z) for dy in (-d/2,d/2) for x,z in pts]
    faces=[tuple(range(n)),tuple(reversed(range(n,n*2)))]+[(i,i+n,(i+1)%n+n,(i+1)%n) for i in range(n)]
    return mesh(name,verts,faces,m,bevel)

def tube(name,points,r,m,soft=True):
    c=bpy.data.curves.new(name,'CURVE');c.dimensions='3D';c.bevel_depth=r;c.bevel_resolution=1;c.resolution_u=5
    if soft:
        s=c.splines.new('BEZIER');s.bezier_points.add(len(points)-1)
        for p,v in zip(s.bezier_points,points):p.co=v;p.handle_left_type='AUTO';p.handle_right_type='AUTO'
    else:
        s=c.splines.new('POLY');s.points.add(len(points)-1)
        for p,v in zip(s.points,points):p.co=(*v,1)
    o=bpy.data.objects.new(name,c);bpy.context.collection.objects.link(o)
    bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o;bpy.ops.object.convert(target='MESH');return finish(bpy.context.object,name,m)

def sector(name,r1,r2,a0,a1,z,d,m,steps=8,bevel=.025):
    pts=[(r*math.cos(a0+(a1-a0)*i/steps),r*math.sin(a0+(a1-a0)*i/steps)) for r,ir in ((r2,range(steps+1)),(r1,range(steps,-1,-1))) for i in ir]
    n=len(pts);verts=[(x,y,zz) for zz in (z-d/2,z+d/2) for x,y in pts]
    faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return mesh(name,verts,faces,m,bevel)

FONT=next((p for p in ['/System/Library/Fonts/Supplemental/Arial Bold.ttf','/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf','C:/Windows/Fonts/arialbd.ttf'] if Path(p).is_file()),None)
font=bpy.data.fonts.load(FONT) if FONT else None
def text(name,value,p,size,m,maxwidth=None):
    c=bpy.data.curves.new(name,'FONT');c.body=value;c.align_x='CENTER';c.align_y='CENTER';c.size=size;c.extrude=.012;c.bevel_depth=.004;c.bevel_resolution=0;c.resolution_u=4
    if font:c.font=font
    o=bpy.data.objects.new(name,c);bpy.context.collection.objects.link(o);o.location=p;o.rotation_euler=(math.pi/2,0,0)
    bpy.context.view_layer.update()
    if maxwidth and o.dimensions.x>maxwidth:o.scale*=maxwidth/o.dimensions.x
    bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o;bpy.ops.object.convert(target='MESH')
    return finish(bpy.context.object,name,m,smooth=False)

def begin():
    global parts,anchors;parts=[];anchors={};role('Structure')

def anchor(name,p):anchors[name]=p

def save(name,label,category,colliders=None):
    """Consolidate by function, retain semantic child meshes and export at the ground origin."""
    bpy.ops.object.select_all(action='DESELECT')
    groups={}
    for o in parts:groups.setdefault(o['role'],[]).append(o)
    out=[]
    for group,objects in groups.items():
        bpy.ops.object.select_all(action='DESELECT')
        for o in objects:o.select_set(True)
        bpy.context.view_layer.objects.active=objects[0]
        if len(objects)>1:bpy.ops.object.join()
        o=bpy.context.object;o.name=name+'__'+group
        bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
        bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
        # Compact material slots after joining repeated roof tiles and fixtures.
        unique=[];mapping={}
        for i,m in enumerate(o.data.materials):
            if m not in unique:unique.append(m)
            mapping[i]=unique.index(m)
        indices=[mapping[p.material_index] for p in o.data.polygons];o.data.materials.clear()
        for m in unique:o.data.materials.append(m)
        for p,i in zip(o.data.polygons,indices):p.material_index=i
        out.append(o)
    root=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(root)
    root['asset_name']=name;root['units']='stud';root['front']='-Y';root['ground_origin']=True
    for o in out:o.parent=root
    for n,p in anchors.items():
        a=bpy.data.objects.new(name+'__ANCHOR_'+n,None);a['anchor_name']=n;bpy.context.collection.objects.link(a);a.location=p;a.parent=root;a.empty_display_size=.3
    bpy.ops.object.select_all(action='DESELECT');root.select_set(True)
    for o in root.children:o.select_set(True)
    bpy.context.view_layer.objects.active=root
    bpy.ops.export_scene.gltf(filepath=str(ROOT/'models'/(name+'.glb')),export_format='GLB',use_selection=True,export_extras=True)
    tris=0
    for o in out:o.data.calc_loop_triangles();tris+=len(o.data.loop_triangles)
    coords=[o.matrix_world@Vector(v) for o in out for v in o.bound_box]
    bounds=[[round(min(v[i] for v in coords),4),round(max(v[i] for v in coords),4)] for i in range(3)]
    row=dict(name=name,label=label,category=category,triangles=tris,meshes=len(out),bounds=bounds,anchors=anchors.copy(),colliders=colliders or [])
    catalog.append(row);roots[name]=root;root.hide_render=True;root.hide_set(True)
    # Object-level hiding on the root does not propagate; children are controlled explicitly.
    for o in root.children:o.hide_render=True;o.hide_set(True)
    return root

def lantern(p,scale=1):
    x,y,z=p;s=scale
    def q(a,b,c):return (x+a*s,y+b*s,z+c*s)
    old=active_role;role('Glow');box('Lantern honey glass',q(0,0,0),(.52*s,.52*s,.79*s),glow,.04*s)
    role('Fixtures')
    for xx in (-.31,.31):
        for yy in (-.31,.31):rod('Lantern corner',q(xx,yy,-.45),q(xx*.82,yy*.82,.45),.045*s,iron)
    box('Lantern foot',q(0,0,-.47),(.76*s,.76*s,.13*s),iron,.04*s)
    cyl('Lantern peaked cap',q(0,0,.53),.57*s,.30*s,iron,4,.025*s,r2=.27*s,rot=(0,0,45))
    ball('Lantern finial',q(0,0,.76),.1*s,gold,1)
    role(old)

def crate(p,s=1):
    x,y,z=p;box('Crate box',(x,y,z+.52*s),(1.05*s,1*s,1.04*s),woodlight,.04*s)
    for xx in (-.48,.48):box('Crate edge',(x+xx*s,y-.53*s,z+.52*s),(.11*s,.08*s,1.08*s),gold,.015)
    for zz in (.06,1.0):box('Crate edge',(x,y-.53*s,z+zz*s),(1.08*s,.08*s,.11*s),gold,.015)
    for sign in (-1,1):box('Crate cross',(x,y-.59*s,z+.53*s),(.09*s,.07*s,1.22*s),woodedge,.015,rot=(0,sign*42,0))

def barrel(p,s=1):
    x,y,z=p;cyl('Barrel',(x,y,z+.63*s),.45*s,1.26*s,woodlight,12,.05)
    for h in (.15,1.08):torus('Barrel hoop',(x,y,z+h*s),.448*s,.045*s,iron,segments=12)
    cyl('Barrel lid',(x,y,z+1.28*s),.40*s,.05*s,woodedge,12,.015)

def rifle(p,s=1,m=None,tilt=0):
    start=len(parts);x,y,z=p;m=m or ink
    box('Rifle body',(x,y,z),(1.28*s,.18*s,.24*s),m,.03)
    box('Rifle stock',(x-.80*s,y,z-.07*s),(.55*s,.24*s,.38*s),woodedge if m==ink else m,.05)
    rod('Rifle barrel',(x+.58*s,y,z+.04*s),(x+1.38*s,y,z+.04*s),.065*s,m)
    box('Rifle magazine',(x+.20*s,y,z-.28*s),(.23*s,.20*s,.39*s),m,.025,rot=(0,-18,0))
    box('Rifle handle',(x-.22*s,y,z-.24*s),(.16*s,.18*s,.30*s),m,.025,rot=(0,18,0))
    if tilt:
        rot=Matrix.Translation(Vector(p))@Matrix.Rotation(math.radians(tilt),4,'Y')@Matrix.Translation(-Vector(p))
        for o in parts[start:]:o.matrix_world=rot@o.matrix_world

def paw(p,s=1,m=goldlight):
    x,y,z=p;ball('Paw pad',(x,y,z-.09*s),(.28*s,.10*s,.23*s),m)
    for xx,zz,rr in ((-.31,.19,.105),(-.12,.34,.12),(.14,.34,.12),(.33,.17,.105)):
        ball('Paw toe',(x+xx*s,y,z+zz*s),(rr*s,.095*s,rr*1.2*s),m)

def glove(p,s=1):
    x,y,z=p;red=material('Brawler red gloves','D94A43')
    ball('Glove',(x,y,z),(.30*s,.18*s,.36*s),red)
    ball('Glove thumb',(x+.22*s,y-.04*s,z-.04*s),(.15*s,.16*s,.20*s),red)
    box('Glove cuff',(x,y,z-.32*s),(.34*s,.28*s,.18*s),white,.06*s)

def open_book(p,s=1):
    x,y,z=p
    for sign in (-1,1):
        box('Book purple cover',(x+sign*.38*s,y,z),( .81*s,.98*s,.10*s),purple,.025,rot=(0,sign*13,0))
        box('Book pages',(x+sign*.35*s,y,z+.09*s),(.72*s,.89*s,.11*s),paper,.035,rot=(0,sign*13,0))
        for j in range(5):
            box('Book ink line',(x+sign*.38*s,y-.30*s+j*.14*s,z+.19*s-sign*.01*s),(.45*s,.025*s,.012*s),woodlight,.003)
    rod('Book spine',(x,y-.48*s,z+.1*s),(x,y+.48*s,z+.1*s),.035*s,gold)

def pet(p,col,kind=0):
    x,y,z=p
    ball('Pet round body',(x,y,z+.43),(.47,.39,.43),col)
    for sign in (-1,1):
        ball('Pet foot',(x+sign*.29,y-.15,z+.10),(.17,.17,.13),col)
        ball('Pet cheek',(x+sign*.32,y-.31,z+.36),(.15,.10,.13),col)
        ball('Pet black eye',(x+sign*.17,y-.363,z+.52),(.065,.038,.083),ink)
        ball('Pet eye shine',(x+sign*.17-.016,y-.397,z+.55),(.018,.013,.025),white,1)
        if kind==0:cyl('Pet horn',(x+sign*.28,y,z+.91),.13,.40,goldlight,8,.02,r2=.015,rot=(0,sign*18,0))
        elif kind==1:ball('Pet ear',(x+sign*.32,y,z+.82),(.14,.13,.30),col)
        else:poly('Pet ear',[(x+sign*.20,z+.68),(x+sign*.44,z+1.0),(x+sign*.49,z+.64)],y,.22,col,.035)
    ball('Pet nose',(x,y-.405,z+.39),(.045,.03,.035),ink,1)
    tube('Pet smile',[(x-.12,y-.40,z+.29),(x,y-.42,z+.25),(x+.12,y-.40,z+.29)],.019,ink)

def gable_roof(width,depth,eave,rise,accent=purple):
    """Individual rounded shingles over two real sloped roof slabs."""
    role('Roof');half=width/2;angle=math.atan2(rise,half);length=math.hypot(half,rise)
    for side in (-1,1):
        box('Roof timber underlay',(side*half/2,0,eave+rise/2),(length+.20,depth,.24),violetdark,.055,rot=(0,side*math.degrees(angle),0))
        for row in range(4):
            dist=(row+.47)*length/4
            for j in range(7):
                yy=-depth/2+(j+.5)*depth/7+(row%2)*.18
                o=box('Purple scalloped roof tile',(side*dist*math.cos(angle),yy,eave+rise-dist*math.sin(angle)+.19),(length/4+.18,depth/7-.05,.17),random.choice(purples),.09,rot=(0,side*math.degrees(angle),0))
        rod('Front coloured gable bar',(0,-depth/2-.07,eave+rise+.23),(side*(half+.05),-depth/2-.07,eave-.05),.15,accent,vertices=8)
        rod('Rear gable bar',(0,depth/2+.07,eave+rise+.23),(side*(half+.05),depth/2+.07,eave-.05),.12,wood)
    rod('Purple roof ridge',(0,-depth/2-.18,eave+rise+.24),(0,depth/2+.18,eave+rise+.24),.19,purples[1])
    role('Structure')

def signboard(title,z,width=8.8,y=-4.48):
    role('SignFrame');box('Sign dark wooden frame',(0,y,z),(width+.32,.31,1.52),wooddark,.15)
    box('Sign warm inset',(0,y-.18,z),(width,.12,1.26),paper,.12)
    for x in (-width/2+.18,width/2-.18):ball('Sign brass nail',(x,y-.26,z),.055,gold,1)
    role('SignText');text('Replaceable Russian title',title,(0,y-.27,z),1.02,ink,width-.6)
    role('Structure')

def awning(accent,width=9.7,z=6.7):
    role('Awning')
    count=8;stripe=width/count
    for j in range(count):
        col=accent if j%2==0 else white;x=-width/2+(j+.5)*stripe
        # Curved sloping fabric profile with a hanging scalloped front.
        profile=[(-3.25,z+.5),(-3.85,z+.44),(-4.4,z+.16),(-4.92,z-.18)]
        verts=[(x+xx,yy,zz) for xx in (-stripe/2+.018,stripe/2-.018) for yy,zz in profile]
        o=mesh('Striped canvas',verts,[(k,k+1,k+5,k+4) for k in range(3)],col)
        mod=o.modifiers.new('Canvas thickness','SOLIDIFY');mod.thickness=.045;bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
        pts=[(x-stripe*.48,z-.16),(x+stripe*.48,z-.16),(x+stripe*.44,z-.45),(x+stripe*.26,z-.57),(x-stripe*.26,z-.57),(x-stripe*.44,z-.45)]
        poly('Scalloped hanging fabric',pts,-4.93,.07,col,.055)
    role('Structure')

def pavilion(kind,title,accent,small=False):
    begin();w=10.6 if not small else 9.8
    box('Stone foundation',(0,0,.28),(w+1.2,7.6,.56),stone,.13)
    for x in (-4.6,4.6):
        for y in (-2.65,2.65):
            box('Stone post foot',(x,y,.65),(1.16,1.12,1.25),random.choice(stones),.10)
            box('Timber upright',(x,y,4.4),(.54,.58,7.4),wood,.08)
            box('Timber upper collar',(x,y,7.58),(.75,.78,.25),woodedge,.06)
        for y in (-2.65,2.65):rod('Diagonal timber brace',(x,y,6.9),(x-math.copysign(1.45,x),y,8.0),.15,woodlight)
    # Warm plank back and small counter, not a solid opaque kiosk.
    for j in range(9):box('Back wood plank',(-4+j,2.79,4.4),(.96,.20,6.8),woodlight if j%3 else woodedge,.025)
    box('Header front beam',(0,-2.7,7.7),(10,.6,.55),wood,.06)
    gable_roof(12.9,8.5,7.95,3.1,accent)
    # Raised front dormer, its coloured trim carries the unique shop icon.
    role('Roof')
    poly('Front dormer',[(-2.4,8.2),(2.4,8.2),(2.4,9.3),(0,11.2),(-2.4,9.3)],-3.90,.32,wood,.06)
    for side in (-1,1):rod('Dormer coloured trim',(0,-4.13,11.35),(side*2.65,-4.13,9.25),.19,accent)
    role('Emblem')
    if kind=='Weapons':
        rifle((0,-4.18,9.82),.84,teal,22);rifle((0,-4.40,9.82),.84,white,-22)
        role('Roof');box('Stone chimney',(3.6,1.4,10.3),(1.25,1.2,3.2),stone,.10)
        for z in (9.4,10.2,11.0):box('Chimney stone joint',(3.6,.78,z),(1.25,.035,.065),wooddark,.01)
        box('Chimney gold cap',(3.6,1.4,11.92),(1.6,1.55,.26),gold,.06)
    elif kind=='Brawler':
        tube('Glove cords',[(-.45,-4.21,10.8),(-.55,-4.22,10.2),(0,-4.22,10.0),(.52,-4.22,10.7)],.03,white)
        glove((-.43,-4.24,9.9),1.25);glove((.43,-4.24,9.72),1.2)
    elif kind=='Pets':paw((0,-4.22,9.9),1.5)
    elif kind=='Quests':
        box('Scroll sheet',(0,-4.18,9.88),(1.25,.12,1.48),paper,.06,rot=(0,-8,0))
        for z in (9.18,10.58):rod('Scroll rolled end',(-.72,-4.22,z),(.72,-4.22,z),.13,woodedge)
        for z in (9.6,9.85,10.1):box('Scroll markings',(0,-4.28,z),(.75,.025,.045),woodlight,.01)
    elif kind=='Rewards':
        box('Gift icon',(0,-4.2,9.8),(1.25,.25,1.08),gold,.10);box('Gift ribbon',(0,-4.35,9.8),(.22,.07,1.2),goldlight,.02)
        for side in (-1,1):torus('Gift bow',(side*.26,-4.25,10.48),.24,.065,goldlight,(90,0,side*25),20)
    else:
        cyl('Info round medallion',(0,-4.22,9.95),.74,.19,gold,24,.045,(90,0,0))
        torus('Info medallion rim',(0,-4.34,9.95),.65,.055,goldlight,(90,0,0))
        text('Info emblem','i',(0,-4.36,9.98),1.32,white)
    signboard(title,8.12)
    if kind in ('Weapons','Brawler','Pets'):awning(accent)
    role('Fixtures')
    for x in (-4.8,4.8):
        rod('Hanging lantern hook',(x,-2.65,7.35),(x,-3.52,7.35),.065,iron)
        lantern((x,-3.52,6.72),1)
    if kind=='Weapons':
        role('DisplayProps');box('Gun display inset',(0,-1.25,4.65),(7.7,.25,3.6),woodedge,.06)
        for z in (3.65,4.65,5.65):
            box('Gun rack rail',(0,-1.43,z),(7,.15,.11),wood,.02)
            for x in (-1.9,1.9):rifle((x,-1.62,z+.12),1.05)
        box('Gun counter',(0,-1.4,2.45),(9.3,1.65,.37),woodedge,.09)
        for x in (-3.9,3.9):box('Counter leg',(x,-1.4,1.5),(.35,.4,2.5),wood,.03)
        crate((4.6,-3.45,.56),1.15);barrel((-4.9,-3.55,.56),1)
    elif kind=='Brawler':
        role('DisplayProps');rod('Punchbag suspension',(-.4,-1.0,7.4),(-.4,-1.0,6.5),.04,iron)
        cyl('Punchbag leather',(-.4,-1.0,4.8),.67,3.4,material('Punchbag red','C64A42'),16,.16)
        for z in (3.2,3.5,6.15):cyl('Punchbag cream stripe',(-.4,-1.0,z),.69,.16,white,16,.025)
        crate((3.8,-2.8,.56),1.25);crate((2.8,-2.8,.56),1.05);crate((3.85,-2.8,1.9),.8)
        barrel((-4.7,-3.4,.56),.95)
    elif kind=='Pets':
        role('DisplayProps');box('Pet display table',(0,-2.25,2.60),(9.5,2.5,.37),woodedge,.08)
        for x in (-3.9,3.9):box('Pet table leg',(x,-2.25,1.4),(.38,.45,2.5),wood,.035)
        box('Pet straw mat',(0,-2.25,2.84),(8.7,2.1,.14),paper,.07)
        for i,col in enumerate((petblue,petgreen,petpink)):pet((-2.5+i*2.5,-2.5,2.92),col,i)
        barrel((4.9,-3.4,.56),1)
    elif kind=='Quests':
        role('DisplayProps');box('Quest cork panel',(0,-1.20,4.65),(7.7,.35,4.7),wooddark,.12)
        for x,z,tilt in ((-2.3,4.9,-6),(0,4.6,5),(2.25,5.0,-4)):
            box('Quest parchment',(x,-1.43,z),(1.75,.065,2.80),paper,.04,rot=(0,tilt,0))
            ball('Quest red pin',(x,-1.51,z+1.05),.10,mushred,1)
            for k in range(5):box('Quest little ink line',(x,-1.50,z+.57-k*.29),(1.17,.02,.045),woodlight,.005)
        box('Quest front shelf',(0,-2.35,2.3),(9.1,1.5,.35),woodedge,.08)
        for z,col in ((2.63,purple),(2.87,paper)):box('Quest book',(-2.9,-2.25,z),(1.5,.9,.23),col,.035,rot=(0,0,8))
        cyl('Quest ink pot',(2.5,-2.35,2.65),.23,.4,ink,12,.03)
        poly('Quill',[(2.44,2.88),(2.55,3.9),(2.95,4.25),(2.9,3.5)],-2.35,.08,white,.02)
    elif kind=='Help':
        role('DisplayProps');box('Lectern post',(0,-1.55,1.65),(.48,.52,2.3),wood,.04)
        box('Lectern base',(0,-1.55,.65),(2,1.6,.25),wood,.07)
        box('Lectern reading desk',(0,-1.55,2.96),(3.9,2.5,.23),woodedge,.06,rot=(16,0,0))
        open_book((0,-1.62,3.13),2.1)
    elif kind=='Rewards':
        role('Structure');cyl('Reward round step',(0,-1.0,.75),3.25,.4,stone,32,.07)
        cyl('Reward gold dais',(0,-1.0,1.0),2.85,.17,gold,32,.04)
        chest_geometry((0,-1.0,1.09),.85)
    role('Marker');cyl('Interaction circle',(0,-5.1,.08),2.4,.12,accent,48,.02)
    cyl('Interaction inset',(0,-5.1,.15),2.11,.025,white,48,.006)
    torus('Interaction ring',(0,-5.1,.17),1.91,.035,accent,segments=40)
    anchor('Title',(0,-4.75,8.12));anchor('Zone',(0,-5.1,.16));anchor('Vendor',(0,.5,.56));anchor('SignSurface',(0,-4.78,8.12))
    save('Pavilion_'+kind,title,'pavilions',[dict(name='Counter',center=[0,-1.5,1.7],size=[9,2,3.2])] if kind in ('Weapons','Pets') else [])

def chest_geometry(p,s=1):
    x,y,z=p
    role('ChestBody');box('Purple chest',(x,y,z+1.1*s),(4.6*s,3.1*s,2.2*s),purple,.17*s)
    for xx in (-1.82,1.82):box('Chest gold strap',(x+xx*s,y,z+1.08*s),(.36*s,3.24*s,2.26*s),gold,.055)
    box('Chest bottom edging',(x,y,z+.12*s),(4.85*s,3.33*s,.24*s),gold,.055)
    # Barrel-vault lid is an actual half cylinder, with separate animation-ready geometry.
    role('ChestLid')
    shape=[(-1.55,0),(1.55,0)]+[(1.55*math.cos(a),1.55*math.sin(a)) for a in [i*math.pi/16 for i in range(1,17)]]
    # A vault along X: build in YZ and extrude along X.
    n=len(shape);verts=[(x+xx*s,y+u*s,z+(2.2+v*.66)*s) for xx in (-2.30,2.30) for u,v in shape]
    faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    mesh('Rounded purple chest lid',verts,faces,purples[1],.045)
    for xx in (-1.82,1.82):
        tube('Curved golden lid strap',[(x+xx*s,y+1.58*math.cos(i*math.pi/20)*s,z+(2.2+1.04*math.sin(i*math.pi/20))*s) for i in range(21)],.14*s,gold,False)
    box('Chest lid gold front rail',(x,y-1.57*s,z+2.22*s),(4.85*s,.20*s,.22*s),goldlight,.045)
    role('ChestBody');box('Star lock plate',(x,y-1.68*s,z+1.65*s),(.94*s,.23*s,1.12*s),gold,.11)
    star=[(x+(.37 if i%2==0 else .18)*s*math.cos(math.pi/2+i*math.pi/5),z+1.68*s+(.37 if i%2==0 else .18)*s*math.sin(math.pi/2+i*math.pi/5)) for i in range(10)]
    poly('Raised lock star',star,y-1.83*s,.08*s,goldlight,.018)
    role('Glow');box('Chest luminous seam',(x,y-1.565*s,z+2.13*s),(3.3*s,.04*s,.08*s),glow,.015)

for kind,title,accent in [('Weapons','Оружейник',teal),('Brawler','Драчун',lime),('Pets','Питомник',amber),('Quests','Задания',pink),('Rewards','Награды',gold),('Help','Помощь',gold)]:
    pavilion(kind,title,accent,kind in ('Quests','Rewards','Help'))

begin();chest_geometry((0,0,0));anchor('LidPivot',(0,1.55,2.2));save('Reward_Chest','Сундук наград','hero')

# Golden imp champion: a deliberately cheerful mascot with oversized head and curved horns.
begin();role('Pedestal')
cyl('Statue lower step',(0,0,.30),2.3,.6,stone,24,.09)
cyl('Statue upper step',(0,0,.77),1.94,.38,stones[0],24,.08)
cyl('Statue gold disk',(0,0,1.02),1.57,.18,gold,24,.04)
role('Figure')
ball('Imp plump torso',(0,0,2.14),(.69,.43,.90),gold)
for s in (-1,1):
    rod('Imp short leg',(s*.38,0,1.73),(s*.46,-.10,1.16),.20,gold)
    ball('Imp oversized foot',(s*.46,-.22,1.23),(.32,.42,.19),gold)
    tube('Imp jaunty arm',[(s*.56,0,2.60),(s*.86,-.02,2.25),(s*.98,-.14,2.12)],.15,gold)
    ball('Imp hand',(s*1.02,-.14,2.09),(.23,.19,.24),gold)
ball('Imp oversized head',(0,0,3.53),(1.13,.68,.95),gold)
for s in (-1,1):
    # Tapered horn with a swept centre line.
    pts=[(s*.72,0,4.06),(s*1.05,.02,4.30),(s*1.16,.02,4.61),(s*1.02,.02,4.88)]
    for j in range(3):rod('Swept golden horn',pts[j],pts[j+1],(.28,.22,.12)[j],goldlight,r2=(.22,.12,.012)[j])
    ball('Imp pointed ear',(s*1.12,0,3.60),(.35,.23,.18),gold,1)
    ball('Imp eye',(s*.38,-.626,3.70),(.115,.045,.17),ink)
    ball('Imp eye glint',(s*.38-.025,-.667,3.76),(.032,.015,.045),goldlight,1)
mouth=[(-.48,3.40),(-.16,3.32),(.17,3.35),(.49,3.48),(.40,3.16),(.09,3.05),(-.24,3.12)]
poly('Imp crooked smile',mouth,-.65,.045,ink,.045)
for x,z in ((-.24,3.27),(.10,3.22),(.32,3.30)):poly('Imp triangle tooth',[(x-.065,z+.06),(x+.065,z+.06),(x,z-.09)],-.686,.025,goldlight,.012)
anchor('FigureBase',(0,0,1.1));save('Champion_ImpStatue','Золотой чемпион','hero')

# Pergola plus two empty ranking surfaces; statue remains its own model.
begin();role('Structure')
for x in (-8.8,8.8):
    for y in (-.7,2.5):
        box('Pergola post stone foot',(x,y,.7),(1.25,1.3,1.4),stone,.10)
        box('Pergola oak upright',(x,y,5.4),(.65,.68,9.4),wood,.075)
for y in (-.7,2.5):box('Pergola crossbeam',(0,y,10.0),(19.8,.72,.65),wood,.08)
role('Roof')
for j in range(13):box('Purple pergola roof slat',(-9.6+j*1.6,.8,10.35+(j%3)*.04),(1.02,5,.32),purples[j%4],.10,rot=(0,0,(j%3-1)*2))
role('SignFrame');box('Records sign',(0,-1.95,9.94),(10.4,.42,1.85),wooddark,.15);box('Records sign inset',(0,-2.21,9.94),(10,.14,1.5),wood,.10)
role('SignText');text('Records title','Рекорды',(0,-2.32,9.94),1.20,paper,8)
role('Emblem')
for s in (-1,1):
    for k in range(5):ball('Golden laurel leaf',(s*(4.1+.12*math.sin(k*.6)),-2.35,9.52+k*.19),(.11,.04,.20),goldlight,1)
for x in (-5.5,5.5):
    role('Structure');box('Ranking board post',(x,0,2.8),(.37,.45,5.4),wood,.055)
    box('Ranking wood frame',(x,-.20,5.3),(4.8,.45,5.9),woodedge,.14)
    poly('Ranking rounded arch',[(x-2.4,6.9),(x+2.4,6.9),(x+2.4,7.4),(x+1.5,8.0),(x,8.3),(x-1.5,8.0),(x-2.4,7.4)],-.20,.45,woodedge,.07)
    role('RankingSurface');box('Replaceable cream board',(x,-.46,5.2),(4.28,.06,4.5),paper,.08)
    for row in range(6):
        box('Placeholder score row',(x+.23,-.507,6.72-row*.58),(2.98,.025,.23),stones[1],.02)
        ball('Ranking coin',(x-1.7,-.52,6.72-row*.58),(.11,.035,.11),gold if row<3 else purple,1)
    role('Emblem');cyl('Board category roundel',(x,-.49,7.43),.58,.07,purple if x>0 else gold,24,.025,(90,0,0))
    if x>0:paw((x,-.56,7.40),.72,petpink)
    else:
        cyl('Trophy stem',(x,-.60,7.22),.08,.38,goldlight,10,.015)
        cyl('Trophy cup',(x,-.60,7.60),.16,.30,goldlight,12,.02,r2=.29)
        for s in (-1,1):torus('Trophy handle',(x+s*.25,-.6,7.62),.14,.035,goldlight,(90,0,0),16)
    anchor('RankingSurfaceLeft' if x<0 else 'RankingSurfaceRight',(x,-.54,5.2))
    lantern((x/abs(x)*8.8,-1.1,7.7),1.05)
role('Foliage')
for s in (-1,1):
    tube('Pergola winding vine',[(s*8.85,-1,3),(s*8.6,-1,6),(s*8.9,-1,8),(s*7.5,-1,10.6),(s*4.8,-1,10.55)],.075,stem)
    for j in range(10):
        x=s*(8.8-j*.37);z=10.5-.12*j if j<6 else 9.8
        ball('Pergola leafy drape',(x,-1.1,z),(.43,.18,.24),leaves[j%5],1,False)
anchor('ChampionSpot',(0,-.35,0));anchor('Title',(0,-2.32,9.94));save('Records_Pergola','Пергола рекордов','pavilions')

# Radial fountain basin, chunky stone claws, crystal and mesh slime waterfalls.
begin();role('Stonework')
cyl('Basin low footing',(0,0,.22),7.2,.44,stones[1],64,.08)
cyl('Basin inner floor',(0,0,.49),6.58,.30,stone,64,.05)
for i in range(24):
    a0=i*math.tau/24+.012;a1=(i+1)*math.tau/24-.012
    sector('Individual basin rim stone',6.32,7.15,a0,a1,1.04,1.15,stones[i%4],3,.065)
role('Glow');cyl('Lime basin liquid',(0,0,.82),6.29,.09,slime,64,.02)
for rr in (2.2,4.5,5.8):torus('Slime concentric ripple',(0,0,.89),rr,.045,slimebright,segments=64)
for i in range(18):
    a=random.random()*math.tau;r=random.uniform(3,5.8)
    ball('Slime bubble',(r*math.cos(a),r*math.sin(a),.91),(.15,.15,.07),slimebright,1)
role('Stonework');cyl('Central tier',(0,0,1.65),3.02,1.55,stone,24,.10)
for i in range(12):sector('Central tier cap block',2.38,3.22,i*math.tau/12+.02,(i+1)*math.tau/12-.02,2.40,.44,stones[i%4],3,.055)
role('Glow');cyl('Upper slime pool',(0,0,2.61),2.66,.08,slime,40,.015)
for i,a in enumerate((-math.pi/2,.4,2.4)):
    # Continuous rounded ribbon with small puddles at the base.
    points=[(2.50*math.cos(a),2.50*math.sin(a),2.62),(2.82*math.cos(a),2.82*math.sin(a),2.58),(2.96*math.cos(a),2.96*math.sin(a),2.15),(3.02*math.cos(a),3.02*math.sin(a),1.02)]
    tube('Falling slime stream',points,.24,slime)
    ball('Stream impact puddle',(3.02*math.cos(a),3.02*math.sin(a),.94),(.59,.54,.10),slimebright)
for a in (-1.17,2.57):
    tube('Slime over basin edge',[(6.15*math.cos(a),6.15*math.sin(a),.91),(6.66*math.cos(a),6.66*math.sin(a),1.70),(7.12*math.cos(a),7.12*math.sin(a),1.46),(7.35*math.cos(a),7.35*math.sin(a),.22)],.27,slime)
    ball('Overflow puddle',(7.37*math.cos(a),7.37*math.sin(a),.10),(.78,.60,.07),slimebright)
role('Claw');cyl('Claw stem',(0,0,3.33),.90,1.35,stone,16,.10)
ball('Claw palm',(0,0,4.5),(1.60,1.25,1.10),stones[1])
for a in (-2.55,-1.55,-.55,.55,2.0):
    x,y=math.cos(a),math.sin(a)
    tube('Curled stone finger',[(x*.7,y*.7,4.1),(x*1.5,y*1.5,4.6),(x*1.92,y*1.92,5.55),(x*1.70,y*1.70,6.08)],.39,stones[2])
    rod('Stone finger pale claw',(x*1.70,y*1.70,6.08),(x*1.4,y*1.4,6.55),.26,paper,r2=.02)
role('Crystal')
def gem(p,r,h,mat,angle=0):
    x,y,z=p;v=[]
    for zz,rr in ((z,r*.60),(z+h*.45,r),(z+h*.72,r*.65)):
        v.extend((x+rr*math.cos(i*math.tau/6+angle),y+rr*math.sin(i*math.tau/6+angle),zz) for i in range(6))
    v.append((x+r*.13,y-r*.10,z+h));f=[tuple(reversed(range(6)))]+[(j*6+i,j*6+(i+1)%6,(j+1)*6+(i+1)%6,(j+1)*6+i) for j in range(2) for i in range(6)]+[(12+i,12+(i+1)%6,18) for i in range(6)]
    o=mesh('Faceted purple crystal',v,f,mat,smooth=False);o.data.materials.append(crystalhi)
    for p in o.data.polygons:
        if p.index%3==1:p.material_index=1
gem((0,0,5.35),1.13,3.50,crystal,.2);gem((1.05,.35,5.3),.63,2.0,crystal,.5);gem((-.85,-.35,5.1),.57,1.8,crystal,.1)
anchor('Crystal',(0,0,7.0));anchor('Water',(0,0,.90));anchor('Spout',(0,0,2.7));save('Slime_Fountain','Слизневый фонтан с кристаллом','hero',[dict(name='Basin',shape='cylinder',radius=7.2,height=1.6)])

# Standalone reusable decor.
begin();role('BenchFrame')
for x in (-2.6,2.6):
    for y in (-.75,.75):rod('Bench cast-iron leg',(x,y,0),(x,y,1.65),.13,iron)
    rod('Bench seat side rail',(x,-1,1.45),(x,1,1.45),.15,iron)
    rod('Bench back support',(x,.77,.8),(x,1.02,3.6),.14,iron)
    tube('Bench rounded arm',[(x,-.85,1.7),(x,-.85,2.25),(x,.63,2.28)],.12,iron)
role('BenchWood')
for y in (-.67,-.20,.27,.74):box('Bench seat plank',(0,y,1.62),(6.15,.40,.18),woodlight,.05)
for z in (2.35,2.90,3.45):box('Bench back plank',(0,.91,z),(6.15,.18,.43),woodlight,.05)
save('Bench','Лавка','decor')

def streetlamp(banner=False):
    begin();role('Structure');box('Lamp stone foot',(0,0,.28),(1.2,1.2,.56),stone,.10)
    cyl('Lamp iron base',(0,0,.78),.32,.65,iron,12,.035)
    cyl('Lamp tall shaft',(0,0,3.55),.14,5.4,iron,12,.025)
    for z in (1.2,5.7):cyl('Lamp gold collar',(0,0,z),.21,.15,gold,12,.02)
    lantern((0,0,6.55),1.35);anchor('Light',(0,0,6.55))
    if banner:
        role('Structure');rod('Banner arm',(0,0,5.8),(2.65,0,5.8),.09,gold)
        for x in (.65,2.1):torus('Banner suspension loop',(x,0,5.7),.12,.03,iron,(90,0,0),12)
        role('Banner');poly('Purple swallowtail banner',[(.45,5.58),(2.45,5.58),(2.45,2.75),(1.48,3.12),(.45,2.75)],0,.07,purple,.035)
        role('Emblem');paw((1.45,-.075,4.26),1.05,paper)
    save('Lantern_Banner' if banner else 'Lantern','Фонарь со знаменем' if banner else 'Фонарь','decor')
streetlamp();streetlamp(True)

def shrub(p,s=1):
    x,y,z=p
    for j,(dx,dy,dz,rr) in enumerate(((-.5,0,.45,.65),(.35,.10,.60,.85),(0,-.3,.8,.75),(.55,-.2,.3,.50))):
        ball('Faceted shrub leaves',(x+dx*s,y+dy*s,z+dz*s),(rr*s,rr*.85*s,rr*.8*s),leaves[j%5],2,False)

def lavender(p,s=1):
    x,y,z=p
    for j in range(5):
        xx=x+(j-2)*.15*s;zz=z+(1.0+(j%3)*.16)*s
        rod('Lavender stem',(xx,y,z),(xx,y,zz),.022*s,stem,vertices=6)
        for k in range(4):
            for sign in (-1,1):ball('Lavender petals',(xx+sign*.08*s,y,zz-k*.16*s),(.12*s,.11*s,.15*s),flowerlight if k==0 else flower,1)

def mushroom(p,s=1):
    x,y,z=p;cyl('Mushroom cream stalk',(x,y,z+.37*s),.13*s,.74*s,white,10,.04)
    ball('Mushroom red cap',(x,y,z+.76*s),(.48*s,.45*s,.25*s),mushred,2)
    for dx,dy,dz in ((-.20,-.18,.17),(.15,-.15,.20),(0,.17,.23)):
        ball('Mushroom white spot',(x+dx*s,y+dy*s,z+(.76+dz)*s),(.075*s,.075*s,.025*s),white,1)

begin();role('Foliage');shrub((0,0,0),1.4);save('Shrub_Cluster','Кусты','greenery')
begin();role('Mushrooms');mushroom((-.35,0,0),1.1);mushroom((.45,.15,0),.7);save('Mushroom_Cluster','Грибы','greenery')

begin();role('Planter')
box('Flower crate',(0,0,.5),(2.8,1.6,1.0),woodlight,.07)
for x in (-1.25,1.25):box('Planter corner iron strap',(x,-.84,.5),(.16,.06,.95),gold,.025)
box('Planter soil',(0,0,1.01),(2.6,1.4,.08),soil,.02)
role('Foliage')
for x in (-.9,-.3,.4,.95):lavender((x,0,1.0),.9)
save('Planter_Box','Ящик с лавандой','greenery')

begin();role('Stonework')
sector('Curved flowerbed stone base',13,20,-math.radians(24),math.radians(24),.18,.36,stone,16,.055)
role('Soil');sector('Curved garden grass',13.4,19.6,-math.radians(23),math.radians(23),.40,.09,lawn,16,.02)
role('Stonework')
for r1,r2 in ((13,13.48),(19.52,20)):
    for i in range(10):sector('Separate curved curb block',r1,r2,math.radians(-24+i*4.8+.12),math.radians(-24+(i+1)*4.8-.12),.54,.60,stones[i%4],2,.045)
for a in (-24,24):sector('Flowerbed end curb',13,20,math.radians(a-.8),math.radians(a+.8),.54,.60,stone,4,.045)
role('Foliage')
for i,a in enumerate((-19,-13,-6,1,8,15,20)):
    r=17.5+(i%2)*.6;a=math.radians(a);shrub((r*math.cos(a),r*math.sin(a),.43),1.25)
for i,a in enumerate((-20,-14,-7,0,7,14,20)):
    r=14.8+(i%2)*.5;a=math.radians(a);lavender((r*math.cos(a),r*math.sin(a),.45),1.0)
role('Mushrooms');mushroom((18.4,-2.7,.45),1.2);mushroom((14.3,4.9,.45),.65)
anchor('ArcCenter',(0,0,0));save('Flowerbed_Curved','Дуговая клумба','greenery')

begin();role('Trunk')
rod('Oak curved trunk',(0,0,0),(.5,.08,5.3),.56,wood,r2=.37)
for a in (-2,-.7,.7,2):
    rod('Oak root',(0,0,.35),(math.cos(a)*1.2,math.sin(a)*1.1,.02),.20,wood,r2=.05)
    rod('Oak branch',(.30,0,3.1),(math.cos(a)*2,math.sin(a)*1.7,6.5),.25,wood,r2=.11)
role('Foliage')
for j,(x,y,z,s) in enumerate(((-2.2,0,6.8,2.5),(1.9,-.1,7.0,2.6),(0,1.5,7.5,2.7),(0,-1.5,7.8,2.7),(-.9,0,9.0,2.4),(1.1,.2,8.9,2.4))):
    ball('Oak faceted foliage mass',(x,y,z),(s,s*.90,s*.70),leaves[j%5],2,False)
    for k in range(9):
        a=k*math.tau/9;rr=s*.65
        ball('Oak leaf cluster',(x+math.cos(a)*rr,y+math.sin(a)*rr*.85,z+.25+(k%3)*.25),(s*.43,s*.38,s*.31),leaves[(j+k)%5],2,False)
save('Tree_Oak','Мультяшный дуб','greenery')

begin();role('Cable')
points=[(-6+i,0,10-1.5*math.sin(i*math.pi/12)) for i in range(13)]
tube('Sagging festoon cable',points,.035,wooddark,False)
for i in range(1,12,2):
    x=-6+i;z=10-1.5*math.sin(i*math.pi/12)
    rod('Bulb short drop',(x,0,z),(x,0,z-.22),.035,iron)
    role('Glow');ball('Golden festoon bulb',(x,0,z-.38),(.15,.15,.23),glow);role('Cable')
anchor('Left',(-6,0,10));anchor('Right',(6,0,10));save('StringLights_12','Гирлянда 12 студов','decor')

# Complete circular paving, individual bevelled blocks, walkable surface at Z=0.
begin();role('Foundation');cyl('Plaza foundation',(0,0,-.60),41,1.10,stone,96,.10)
tilemats=[material('Paving '+str(i),h) for i,h in enumerate(['BFA491','C3A990','AF9990','B7A091','C9B197'])]
creams=[material('Outer paving '+str(i),h) for i,h in enumerate(['DFBE94','E5C9A4','D8BA95'])]
role('Paving')
for j,(r1,r2) in enumerate(((0.02,7.4),(7.5,10.4),(10.5,13.4),(13.5,16.4),(16.5,19.4),(19.5,22.4),(22.5,25.4),(25.5,28.4),(28.5,31.4),(31.5,34.4),(34.5,37.4),(37.5,40.8))):
    n=max(16,round(math.tau*(r1+r2)/2/2.9));shift=(j%2)*math.pi/n
    for i in range(n):
        role('Paving_'+str(i*8//n));sector('Plaza paving block',r1,r2,i*math.tau/n+shift+.003,(i+1)*math.tau/n+shift-.003,-.04,.24,random.choice(creams if j>=9 else tilemats),2,.035)
role('Curb')
for i in range(80):sector('Plaza outer curb',40.75,41.45,i*math.tau/80+.002,(i+1)*math.tau/80-.002,-.01,.48,stones[i%4],2,.045)
anchor('Center',(0,0,.08));save('Plaza_Paving','Круглое мощение, радиус 41','ground',[dict(name='Ground',shape='cylinder',radius=41,height=1.1,center=[0,0,-.6])])

begin();role('Paving')
for x in (-1.5,1.5):
    for y in (-1.5,1.5):box('Path paving stone',(x,y,0),(2.92,2.92,.30),creams[int((x+y)%3)],.07)
anchor('Start',(0,-3,0));anchor('End',(0,3,0));save('Path_Segment_6','Дорожка 6 × 6','ground')

# Review assembly. Its layout is a proposal, not a modification of the live place.
layout=[];assembly_instances=[]
def place(name,p=(0,0,0),yaw=0,scale=1):
    source=roots[name];root=bpy.data.objects.new(name+'_instance',None);bpy.context.collection.objects.link(root)
    root.location=p;root.rotation_euler.z=math.radians(yaw);root.scale=(scale,)*3 if isinstance(scale,(float,int)) else scale
    for o in source.children:
        if o.type!='MESH':continue
        copy=o.copy();copy.data=o.data;bpy.context.collection.objects.link(copy);copy.parent=root;copy.matrix_parent_inverse=Matrix.Identity(4);copy.hide_render=False
    layout.append(dict(asset=name,position=list(p),yaw=yaw,scale=scale));assembly_instances.append(root);return root

place('Plaza_Paving')
for name,p,yaw in [('Pavilion_Weapons',(-2,26,.10),0),('Pavilion_Brawler',(13,23,.10),-8),('Pavilion_Pets',(28,8,.10),-25),('Pavilion_Quests',(-29,0,.10),25),('Pavilion_Rewards',(-22,-23,.10),12),('Pavilion_Help',(24,-22,.10),-15),('Records_Pergola',(-21,26,.10),12)]:place(name,p,yaw)
place('Champion_ImpStatue',(-21,23.9,.1),12,1.35)
place('Slime_Fountain',(0,0,.10))
for a in (45,135,225,315):place('Flowerbed_Curved',(0,0,.10),a)
for x in (-8,8):place('Bench',(x,-34,.10),-6 if x<0 else 6)
for a in (-130,-105,-75,-45,-20,10,40,70,110,150,175):
    r=37 if a<0 else 25;x=r*math.cos(math.radians(a));y=r*math.sin(math.radians(a))
    place('Lantern_Banner' if a in (-130,-45,150) else 'Lantern',(x,y,.10),a+90)
for p in ((-31,8,.1),(-27,12,.1),(-30,-12,.1),(31,-9,.1),(34,13,.1),(-12,-35,.1),(12,-35,.1),(-3,-35,.1),(3,-35,.1)):
    place('Shrub_Cluster',p,random.random()*360,random.uniform(.85,1.3))
for p in ((-30,6,.1),(-32,-9,.1),(32,-10,.1),(12,-36,.1)):place('Mushroom_Cluster',p,random.random()*360)
for p in ((-31,2,.1),(-12,25,.1),(-30,29,.1),(35,5,.1)):place('Planter_Box',p)
for p in ((-32,29,-.1),(-12,38,-.1),(10,38,-.1),(35,23,-.1),(-40,-9,-.1),(39,-18,-.1)):
    place('Tree_Oak',p,random.random()*360,random.uniform(.95,1.15))
place('StringLights_12',(5.4,27,.35),-5,1.25);place('StringLights_12',(22,17,.25),-33,1.2)
for yaw in (-90,0,90,180):
    a=math.radians(yaw);v=Vector((math.sin(a),-math.cos(a),0))
    for k in range(3):place('Path_Segment_6',tuple(v*(44.6+k*6.02)),yaw)

# Save a combined GLB containing only assembly models (no review lights or ground plane).
bpy.ops.object.select_all(action='DESELECT')
for root in assembly_instances:
    root.select_set(True)
    for o in root.children:o.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(ROOT/'models'/'Plaza_Assembly.glb'),export_format='GLB',use_selection=True,export_extras=True)
(ROOT/'models'/'catalog.json').write_text(json.dumps(dict(version=1,units='stud',blender_front='-Y',blender_up='Z',gltf_up='Y',assets=catalog,layout=layout),ensure_ascii=False,indent=2)+'\n')

scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=40;scene.cycles.use_denoising=True
scene.view_settings.view_transform='AgX';scene.view_settings.look='AgX - Medium High Contrast'
scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.55,.51,.47,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.48
role('REVIEW');groundmat=material('Review lawn','6B8C35');box('REVIEW ONLY grass ground',(0,0,-1.3),(220,220,.5),groundmat,.02)
bpy.ops.object.light_add(type='SUN',location=(-25,-35,60));sun=bpy.context.object;sun.data.energy=1.8;sun.data.color=(1,.92,.80);sun.data.angle=.18;sun.rotation_euler=(math.radians(23),math.radians(-20),math.radians(-28))
bpy.ops.object.light_add(type='AREA',location=(0,-30,55));area=bpy.context.object;area.data.energy=14000;area.data.size=45
bpy.ops.object.camera_add();cam=bpy.context.object;cam.data.type='ORTHO';scene.camera=cam
def aim(p,look,ortho,res):
    cam.location=p;cam.rotation_euler=(Vector(look)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=ortho
    scene.render.resolution_x=res[0];scene.render.resolution_y=res[1];scene.render.resolution_percentage=100
def render(file):
    scene.render.filepath=str(ROOT/'previews'/file);bpy.ops.render.render(write_still=True)
aim((25,-113,87),(0,1,0),105,(2200,1700));render('Plaza_day.png')
aim((0,-110,81),(0,0,0),101,(2000,1700));render('Plaza_front.png')
# A second native source file is a browsable asset library, alongside the assembly file.
aim((25,-113,87),(0,1,0),105,(2200,1700))
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'models'/'Plaza_Assembly.blend'))
for root in assembly_instances:
    root.hide_set(True)
    for o in root.children:o.hide_render=True;o.hide_set(True)
reviewground=bpy.data.objects.get('REVIEW ONLY grass ground');reviewground.hide_render=True
# Independent product renders on a neutral floor, generated from the exported source geometry.
role('REVIEW');neutral=material('Review neutral floor','EBE4DB');floor=box('REVIEW ONLY neutral floor',(0,0,-.40),(200,200,.5),neutral,.02)
sun.data.energy=1.5;area.data.energy=1100;area.location=(0,-9,15);area.data.size=10
for row in catalog:
    if row['name']=='Plaza_Paving':continue
    root=roots[row['name']]
    for o in root.children:o.hide_render=False
    bounds=row['bounds'];center=Vector(tuple((a+b)/2 for a,b in bounds));extent=max(b-a for a,b in bounds)
    if row['name']=='Flowerbed_Curved':offset=Vector((0,-extent*.9,extent*.9))
    else:offset=Vector((extent*.52,-extent*1.65,extent*.68))
    aim(center+offset,center,extent*1.48,(1100,1000));render(row['name']+'.png')
    for o in root.children:o.hide_render=True
for i,row in enumerate(catalog):
    root=roots[row['name']]
    if row['name']=='Plaza_Paving':root.location=(155,40,0)
    else:root.location=((i%5)*22,(i//5)*22,0)
    for o in root.children:o.hide_render=False;o.hide_set(False)
    root.hide_render=False;root.hide_set(False)
floor.hide_render=True
aim((130,-110,145),(75,35,0),240,(2200,1700))
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'models'/'Plaza_Kit.blend'))
print('PLAZA_KIT_COMPLETE',len(catalog),'assets',sum(r['triangles'] for r in catalog),'triangles')
