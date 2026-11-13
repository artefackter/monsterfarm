"""Standalone grave proposals. Does not open or modify the Roblox place."""
import bpy, math, json
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

base=material('Basalt • plum','393244',0,.72)
baseedge=material('Basalt • upper edge','5B4C66',0,.65)
grass=material('Grass • apple','82BA24',0,.68);grasslight=material('Grass • lime tips','B3DE43',0,.6)
palettes=[
 ('Wooden','B77237','E4A75A','61391F',0),
 ('Stone','7D899D','BEC9D8','3D485C',0),
 ('Marble','DAE8E6','F8F6DF','73958F',.06),
 ('Golden','F7B80B','FFE263','AC620A',.68),
 ('Lunar','6652B4','BCD9FF','2D245B',.25),
]
for kind,bodyhex,rimhex,darkhex,metal in palettes:
    parts=[]
    body=material(kind+' • face',bodyhex,metal,.33 if metal else .53)
    rim=material(kind+' • rim',rimhex,metal,.27 if metal else .44)
    dark=material(kind+' • recessed detail',darkhex,metal*.3,.6)
    # Chunky layered plinth, wide arched headstone and proud outer lip.
    box('Base / lower basalt',(0,0,.13),(2.6,1.38,.26),base,.12)
    box('Base / bevelled upper step',(0,-.015,.31),(2.42,1.22,.20),baseedge,.08)
    box('Foot / broad material shoe',(0,0,.48),(2.09,.85,.22),dark,.075)
    box('Foot / highlight lip',(0,-.06,.57),(2.11,.84,.12),rim,.045)
    arch('Headstone / solid arched body',.94,.53,2.18,.04,.59,body,.075)
    arch('Headstone / raised outer border',.97,.59,2.17,-.245,.18,rim,.055)
    arch('Headstone / recessed outline',.806,.68,2.14,-.35,.08,dark,.035)
    arch('Headstone / inset front panel',.761,.715,2.14,-.403,.085,body,.035)
    # Block-like shoulders echo the stepped outline of the reference.
    for side in (-1,1):
        box('Shoulder / sculpted side block',(side*.93,-.015,2.12),(.23,.73,.39),rim,.07)
        box('Shoulder / lower shadow',(side*.929,-.392,1.94),(.15,.036,.065),dark,.018)
    # Crown band following the arch, with deliberate segment joints.
    for a0,a1 in ((12,55),(59,112),(116,166)):
        pts=[(.874*math.cos(math.radians(a)), -.503, 2.17+.874*math.sin(math.radians(a))) for a in range(a0,a1+1,2)]
        stroke('Crown / curved raised band',pts,.029,rim)
    # Stylised zombie face, with hair and asymmetrical eye sockets.
    face=[(-.43,1.91),(-.39,1.40),(-.26,1.29),(.28,1.29),(.43,1.43),(.43,1.91),(.28,2.03),(-.26,2.03)]
    poly('Emblem / dark carved silhouette',[(x*1.08,1.66+(z-1.66)*1.09) for x,z in face],-.485,.055,dark,.045)
    poly('Emblem / raised zombie face',face,-.539,.105,rim,.055)
    hair=[(-.48,1.92),(-.48,2.07),(-.32,2.19),(-.09,2.22),(.02,2.36),(.18,2.37),(.14,2.22),(.36,2.20),(.51,2.03),(.27,2.09),(.30,1.93),(.10,2.02),(-.04,1.91),(-.16,2.02),(-.32,1.91)]
    poly('Emblem / messy hair silhouette',hair,-.57,.095,dark,.018)
    poly('Emblem / hair highlight',[(x*.94,2.08+(z-2.08)*.88+.024) for x,z in hair],-.627,.043,rim,.018)
    poly('Emblem / left sunken eye',[(-.29,1.79),(-.22,1.85),(-.14,1.78),(-.14,1.66),(-.28,1.66)],-.604,.025,dark,.018)
    poly('Emblem / right sunken eye',[(.13,1.83),(.26,1.80),(.29,1.66),(.14,1.68)],-.604,.025,dark,.016)
    poly('Emblem / little nose',[(-.045,1.63),(.038,1.63),(.068,1.55),(-.055,1.55)],-.606,.022,dark,.012)
    mouth=[(-.23,1.49),(-.12,1.49),(-.12,1.43),(-.015,1.43),(-.015,1.49),(.12,1.49),(.12,1.54),(.23,1.54),(.23,1.37),(-.23,1.37)]
    poly('Emblem / toothy crooked smile',mouth,-.608,.026,dark,.012)
    box('Emblem / single tooth',(.062,-.628,1.469),(.08,.023,.08),rim,.008)
    # Cloud / earth motif along lower edge of the panel.
    cloud=[(-.60,.84),(-.57,.93),(-.45,.95),(-.39,.89),(-.32,1.035),(-.20,1.09),(-.09,1.04),(-.035,.94),(.10,.96),(.18,.89),(.28,.98),(.43,1.01),(.54,.94),(.59,.84)]
    stroke('Ornament / lower cloud outline',[(x,-.465,z) for x,z in cloud],.032,dark,True)
    stroke('Ornament / lower cloud highlight',[(x,-.498,z+.035) for x,z in cloud],.020,rim,True)
    if kind=='Wooden':
        for x in (-.56,.55):
            stroke('Wood / flowing grain',[(x,-.456,.99),(x-.025,-.456,1.32),(x+.025,-.456,1.64),(x-.02,-.456,1.93),(x+.02,-.456,2.26)],.011,dark)
        for side in (-1,1):
            box('Wood / bronze binding',(side*.91,-.024,1.10),(.19,.71,.15),dark,.025)
            box('Wood / square peg',(side*.91,-.397,1.10),(.07,.035,.07),rim,.012)
    elif kind=='Stone':
        stroke('Stone / upper hairline crack',[(-.55,-.458,2.64),(-.49,-.458,2.49),(-.58,-.458,2.39)],.014,dark)
        stroke('Stone / lower corner chip',[(.72,-.458,1.24),(.60,-.458,1.17),(.63,-.458,1.08)],.015,dark)
    elif kind=='Marble':
        vein=material('Marble • veins','9DB6AE',.08,.48)
        for pts in [[(-.69,1.26),(-.58,1.43),(-.61,1.67)],[(.42,2.70),(.31,2.56),(.39,2.45)],[(.58,.79),(.49,.94),(.57,1.08)]]:
            stroke('Marble / subtle mineral vein',[(x,-.456,z) for x,z in pts],.009,vein)
    elif kind=='Golden':
        # Small carved joints, no floating VFX baked into the model.
        for pts in [[(-.70,1.59),(-.62,1.64),(-.59,1.74)]]:
            stroke('Gold / sculpted joint',[(x,-.466,z) for x,z in pts],.016,dark)
    elif kind=='Lunar':
        ice=material('Lunar • pale cyan inlay','9FE9FF',.2,.3,.16)
        # Crescent is solid geometry, rather than a full ring.
        cres=[(.14*math.cos(math.radians(a)),2.68+.14*math.sin(math.radians(a))) for a in range(60,301,6)]
        cres += [(.07+.121*math.cos(math.radians(a)),2.68+.121*math.sin(math.radians(a))) for a in range(270,89,-6)]
        poly('Lunar / crescent inlay',cres,-.469,.035,ice,.006)
        for side in (-1,1):
            bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=1,location=(side*.83,-.41,.70))
            o=bpy.context.object;o.scale=(.11,.12,.25);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);finish(o,'Lunar / crystal',ice)
    # Five broad grass blades on each side; all are real double-sided solids.
    for side in (-1,1):
        for j,(dx,h) in enumerate(((-.24,.23),(-.13,.37),(0,.46),(.16,.34),(.26,.20))):
            leaf('Grass / blade',(side*1.04,-.46,.35),(side*1.04+dx,-.50,.35+h),.065,grasslight if j%2 else grass)
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

# Review studio. This lighting and floor are not included in individual exports.
for co in bpy.data.collections:
    if co.name.startswith('Grave_'):co.hide_render=True
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=32;scene.cycles.use_denoising=True
scene.render.resolution_x=1000;scene.render.resolution_y=1120;scene.render.resolution_percentage=100
scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.28,.28,.34,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.6
scene.view_settings.view_transform='AgX'
floor=material('Review only • floor','E5DFEA',0,.8)
o=box('REVIEW ONLY / floor',(0,0,-.12),(200,200,.2),floor,0)
for p,e,size in [((-3,-4,7),550,4),((4,-1,5),450,3),((1,4,6),750,3)]:
    bpy.ops.object.light_add(type='AREA',location=p);o=bpy.context.object;o.data.energy=e;o.data.shape='DISK';o.data.size=size;o.rotation_euler=(Vector((0,0,1.5))-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add();cam=bpy.context.object;cam.data.type='ORTHO';cam.data.ortho_scale=4.35;scene.camera=cam
def render(name,filename,position):
    for row in catalog:bpy.data.collections[row['name']].hide_render=row['name']!=name
    target=Vector((0,0,1.52));cam.location=target+Vector(position);cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=str(ROOT/'previews'/filename);bpy.ops.render.render(write_still=True)
for row in catalog:render(row['name'],row['name']+'.png',(3.25,-7,3.1))
render('Grave_Golden','Golden_front.png',(0,-8,1.3))
render('Grave_Golden','Golden_back.png',(-3,7,3))
for i,row in enumerate(catalog):
    co=bpy.data.collections[row['name']];co.hide_render=False
    for o in co.objects:o.location.x+=(i-2)*3.25
cam.location=(8,-17,11);cam.rotation_euler=(Vector((0,0,1.4))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=18
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'models'/'Graves_Reference_V2.blend'))
(ROOT/'models'/'catalog.json').write_text(json.dumps(catalog,indent=2))
print('GRAVES_REVIEW_COMPLETE',json.dumps(catalog))
