"""Offline review only. Does not modify game source, Studio, or source meshes."""
import bpy, math, json, random
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parent
PROJECT = ROOT.parent.parent
ROOT.mkdir(exist_ok=True)
for folder in ('models', 'previews'):
    (ROOT / folder).mkdir(exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
random.seed(27)

def linear(x):
    return x / 12.92 if x <= .04045 else ((x + .055) / 1.055) ** 2.4

materials = {}
def mat(color):
    if color not in materials:
        m = bpy.data.materials.new(color)
        m.use_nodes = True
        rgb = tuple(linear(int(color[i:i+2], 16) / 255) for i in (0, 2, 4)) + (1,)
        m.diffuse_color = rgb
        bsdf = m.node_tree.nodes.get('Principled BSDF')
        bsdf.inputs['Base Color'].default_value = rgb
        bsdf.inputs['Roughness'].default_value = .78
        materials[color] = m
    return materials[color]

def collection(name):
    co = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(co)
    return co

def move(o, co):
    for old in list(o.users_collection):
        old.objects.unlink(o)
    co.objects.link(o)
    return o

def mesh(name, vertices, faces, co, color):
    me = bpy.data.meshes.new(name)
    me.from_pydata(vertices, [], faces)
    me.update()
    o = bpy.data.objects.new(name, me)
    co.objects.link(o)
    if color:
        me.materials.append(mat(color))
    return o

def ellipsoid(name, p, scale, co, color, segments=12):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=8, location=p)
    o = bpy.context.object
    o.name = name
    o.scale = scale
    o.data.materials.append(mat(color))
    return move(o, co)

def limb(name, a, b, radius_a, radius_b, co, color, segments=10):
    a, b = Vector(a), Vector(b)
    bpy.ops.mesh.primitive_cone_add(vertices=segments, radius1=radius_a, radius2=radius_b,
                                    depth=(b-a).length, location=(a+b)/2)
    o = bpy.context.object
    o.name = name
    o.rotation_euler = (b-a).to_track_quat('Z', 'Y').to_euler()
    o.data.materials.append(mat(color))
    return move(o, co)

report = {}
def imported(name, folder, asset, brighten=False):
    co = collection(name)
    entries = json.loads((folder / '_manifest.json').read_text())[asset]
    count = 0
    for p in entries:
        d = json.loads((folder / (p['mesh'] + '.json')).read_text())
        v, t, off = d['v'], d['t'], p['offset']
        # Rotate the source's front (-Z) to Blender front (-Y), preserving winding.
        vv = [(-v[i]-off[0], v[i+2]+off[2], v[i+1]+off[1]) for i in range(0, len(v), 3)]
        o = mesh(p['part'], vv, [t[i:i+3] for i in range(0,len(t),3)], co, None)
        ca = o.data.color_attributes.new(name='Color', type='FLOAT_COLOR', domain='POINT')
        for j, c in enumerate(d['c']):
            rgb = [(c >> s & 255)/255 for s in (16,8,0)]
            # Lift all flesh, including the darkest limbs; preserve eyes, teeth and mouth cavity.
            if brighten and p['part'] != 'EyesGlow':
                red_flesh = rgb[0] > rgb[1]*1.25 and rgb[2] > rgb[1]*1.12
                if red_flesh:
                    rgb = [min(.90, rgb[0]*.91+.25), min(.84, rgb[1]*.90+.22), min(.86, rgb[2]*.90+.20)]
                    count += 1
            ca.data[j].color = tuple(linear(x) for x in rgb)+(1,)
        m = bpy.data.materials.new(name+'_'+p['part'])
        m.use_nodes = True
        node = m.node_tree.nodes.new('ShaderNodeVertexColor')
        node.layer_name = 'Color'
        bsdf = m.node_tree.nodes.get('Principled BSDF')
        m.node_tree.links.new(node.outputs['Color'], bsdf.inputs['Base Color'])
        bsdf.inputs['Roughness'].default_value = .78
        o.data.materials.append(m)
    report[name] = {'asset':asset, 'recolored_vertices':count, 'geometry':'unchanged'}
    return co

parasite_folder = PROJECT/'art/export/collection-v2/road-v3/root-archetypes-v1'
parasite_before = imported('Parasite_Before', parasite_folder, 'Parasite_Root_Aggressive')
parasite_after = imported('Parasite_Proposed', parasite_folder, 'Parasite_Root_Aggressive', True)
ring_before = imported('RingMaw_Source', PROJECT/'art/export/collection-v2/release-v1/monsters', 'RingMaw_Aggressive')
ring = collection('RingMaw_Proposed')

# Keep the source model's four-limb stance, contact points, and hunched body.
# Only recolor its body/limbs; replace the head separately.
skin, light, tendon = '938379', 'A39487', '796B62'
for original in ring_before.objects:
    if original.name.split('.')[0] in ('Head', 'MawGlow'):
        continue
    # Blender can suffix duplicate names: use the source mesh name for filtering.
    base_name = original.data.name.split('.')[0]
    if base_name in ('Head', 'MawGlow'):
        continue
    o = original.copy()
    o.data = original.data.copy()
    ring.objects.link(o)
    o.name = 'Quadruped_' + base_name
    ca = o.data.color_attributes.get('Color')
    for datum in ca.data:
        rgb = datum.color[:3]
        # Decode linear colors, lift the dark flesh, and retain existing variation.
        srgb = [12.92*x if x <= .0031308 else 1.055*x**(1/2.4)-.055 for x in rgb]
        lum = sum(srgb)/3
        if lum < .62:
            base = .33 + lum*.57
            datum.color = tuple(linear(min(.88,base+delta)) for delta in (.055,.015,-.015))+(1,)
    # Copied materials already read the Color vertex attribute.

# The second reference's broad rusty rim and deep funnel. No spherical pumpkin shell.
zc = 2.695
hx, hy = .144, -2.096
n = 64
profile = [(1.27,.31),(1.43,.08),(1.45,-.22),(1.33,-.49),(1.18,-.48),
           (1.04,-.32),(.83,-.10),(.60,.10),(.37,.24),(.23,.29)]
vertices=[]
for k,(r,y) in enumerate(profile):
    for i in range(n):
        a=2*math.pi*i/n
        irregular=1+.018*math.sin(7*a)+.014*math.sin(13*a+.7)
        vertices.append((hx+r*math.cos(a)*irregular,hy+y,zc+r*math.sin(a)*irregular))
faces=[]
for k in range(len(profile)-1):
    for i in range(n):
        faces.append((k*n+i,k*n+(i+1)%n,(k+1)*n+(i+1)%n,(k+1)*n+i))
head=mesh('Head_Funnel',vertices,faces,ring,None)
palette=['984B26','AF652D','C27A37','CF8D48','94542C','614338','594138','4A3530','332725']
for h in palette: head.data.materials.append(mat(h))
for poly in head.data.polygons:
    band=poly.index//n
    poly.material_index=band
    # Broad, faceted variations across the lip, rather than uniform toy plastic.
    if band in (0,1,2,3) and (poly.index%n)//4%3==0:
        poly.material_index=max(0,band-1)
ellipsoid('Throat',(hx,hy+.39,zc),(.245,.10,.245),ring,'211C1B',20)
for i in range(24):
    a=2*math.pi*(i+.5)/24
    outer=(hx+.40*math.cos(a),hy+.205,zc+.40*math.sin(a))
    inner=(hx+.255*math.cos(a+.045),hy+.20,zc+.255*math.sin(a+.045))
    limb('Tooth_'+str(i),outer,inner,.050,.008,ring,'E9D9B9',6)
# A few fissures in the outer rim; a short crooked growth from the reference.
for a in (.30,2.1,3.7,5.45):
    p=(hx+1.19*math.cos(a),hy-.489,zc+1.19*math.sin(a))
    q=(hx+1.42*math.cos(a+.035),hy-.26,zc+1.42*math.sin(a+.035))
    limb('RimFissure',p,q,.018,.028,ring,'77432B',5)
limb('StemBase',(hx-.66,hy+.10,zc+1.12),(hx-.92,hy+.13,zc+1.49),.14,.11,ring,tendon,8)
limb('StemTip',(hx-.92,hy+.13,zc+1.49),(hx-1.28,hy+.13,zc+1.57),.11,.025,ring,tendon,8)

models=[parasite_before,parasite_after,ring_before,ring]
scene=bpy.context.scene
scene.render.engine='CYCLES'
scene.cycles.samples=24
scene.cycles.use_denoising=True
scene.render.resolution_x=850
scene.render.resolution_y=1050
scene.render.resolution_percentage=100
scene.view_settings.view_transform='Standard'
scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.16,.19,.23,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.6
for p,power,size in [((4,-6,10),1000,7),((-5,-3,6),650,6),((1,5,9),1100,5)]:
    bpy.ops.object.light_add(type='AREA',location=p)
    o=bpy.context.object
    o.data.energy=power*.72
    o.data.shape='DISK'
    o.data.size=size
    o.rotation_euler=(Vector((0,0,3.5))-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.035))
floor=bpy.context.object
floor.name='Review_Backdrop'
floor.data.materials.append(mat('29343F'))
bpy.ops.object.camera_add()
cam=bpy.context.object
scene.camera=cam
cam.data.type='ORTHO'
def render(co,name,front=False,detail=False,side=False):
    for c in models:c.hide_render=c!=co
    bpy.context.view_layer.update()
    pts=[o.matrix_world@Vector(v) for o in co.objects for v in o.bound_box]
    lo=Vector(tuple(min(p[i] for p in pts) for i in range(3)))
    hi=Vector(tuple(max(p[i] for p in pts) for i in range(3)))
    center=(lo+hi)/2
    if detail:
        center=Vector((hx,hy,zc));cam.data.ortho_scale=3.9
        cam.location=center+Vector((.25,-11,.35))
    else:
        cam.data.ortho_scale=max((hi.z-lo.z)*1.16,(hi.x-lo.x)*1.32)
        cam.location=center+Vector((11 if side else (0 if front else 3.6),-10 if side else -14,3.3 if side else 1.6))
    cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler()
    if not detail:
        bpy.context.view_layer.update()
        projected=[cam.matrix_world.inverted()@p for p in pts]
        aspect=scene.render.resolution_x/scene.render.resolution_y
        cam.data.ortho_scale=max(max(abs(p.y) for p in projected)*2,
                                max(abs(p.x) for p in projected)*2/aspect)*1.12
    scene.render.filepath=str(ROOT/'previews'/f'{name}.png')
    bpy.ops.render.render(write_still=True)

for co in models:
    render(co,co.name)
render(ring,'RingMaw_Front',front=True)
render(ring,'RingMaw_Stance',side=True)
render(ring,'RingMaw_MawDetail',detail=True)
for co in (parasite_after,ring):
    co.hide_render=False
    bpy.ops.object.select_all(action='DESELECT')
    for o in co.objects:o.select_set(True)
    bpy.context.view_layer.objects.active=list(co.objects)[0]
    bpy.ops.export_scene.gltf(filepath=str(ROOT/'models'/f'{co.name}.glb'),use_selection=True,export_format='GLB')
    report[co.name]={**report.get(co.name,{}),'objects':len(co.objects),
                    'triangles':sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in co.objects)}
for co in models:co.hide_render=co!=ring
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'models/MonsterReview.blend'))
(ROOT/'report.json').write_text(json.dumps(report,indent=2))
print('MONSTER_REVIEW_COMPLETE')
