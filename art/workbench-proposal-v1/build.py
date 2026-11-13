"""Local approval draft. Does not connect to Studio or modify runtime sources.
Blender Z-up -> Roblox Y-up; one authored primitive per Roblox Part.
Run: blender -b --python art/workbench-proposal-v1/build.py
"""
import bpy, json, math
from pathlib import Path
from mathutils import Vector, Matrix

ROOT = Path(__file__).resolve().parent
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
parts, materials = [], {}

def mat(color, glow=False):
    key=(color,glow)
    if key not in materials:
        rgb=[int(color[i:i+2],16)/255 for i in (0,2,4)]
        linear=[v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in rgb]
        m=bpy.data.materials.new(color);m.diffuse_color=(*linear,1);m.use_nodes=True
        p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*linear,1)
        p.inputs['Roughness'].default_value=.7
        if glow:
            p.inputs['Emission Color'].default_value=(*linear,1);p.inputs['Emission Strength'].default_value=1.8
        materials[key]=m
    return materials[key]

def piece(name,pos,size,color,shape='Block',rot=(0,0,0),material='SmoothPlastic'):
    if shape=='Block': bpy.ops.mesh.primitive_cube_add(size=1)
    elif shape=='Ball': bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=8,radius=.5)
    else: bpy.ops.mesh.primitive_cylinder_add(vertices=12,radius=.5,depth=1)
    o=bpy.context.object;o.name=name;o.location=pos;o.scale=size
    o.rotation_euler=tuple(math.radians(a) for a in rot)
    o.data.materials.append(mat(color,material=='Neon'))
    parts.append((o,shape,color,material))
    return o

def box(n,p,s,c,**kw):return piece(n,p,s,c,**kw)
def rod(n,a,b,r,c,material='Metal'):
    a,b=Vector(a),Vector(b)
    o=piece(n,(a+b)/2,(2*r,2*r,(b-a).length),c,'Cylinder',material=material)
    o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return o

wood,edge,dark,iron,steel,brass='805334','AF7849','483229','343B43','A2AEB1','BC914F'
# Stout joinery and distinct planks. Open back keeps the garden visible.
for x in (-2.85,2.85):
    for y in (-1.05,1.05):
        box('OakLeg',(x,y,1.48),(.55,.55,2.96),dark)
        box('IronFoot',(x,y,.23),(.59,.59,.43),iron)
        box('LegCollar',(x,y,2.51),(.59,.59,.24),iron)
for y in (-1.12,1.12):box('Apron',(0,y,2.65),(6.35,.22,.57),wood)
for y in (-.97,-.32,.33,.98):box('LowerShelf',(0,y,.78),(6.25,.61,.22),wood)
for i in range(5):box('TopPlank',(0,-1.36+i*.68,3.12),(7,.65,.4),edge if i%2 else wood)
for x in (-3.3,3.3):
    box('TopIronStrap',(x,0,3.335),(.16,3.32,.035),iron)
    for y in (-1.36,1.36):piece('Rivet',(x,y,3.37),(.12,.12,.07),brass,'Ball')
# Short rear rail, with a little centre crest rather than a tall solid wall.
for x in (-3.05,3.05):
    box('RackPost',(x,1.35,4.22),(.26,.3,2.2),dark)
    piece('PostFinial',(x,1.35,5.41),(.38,.38,.38),brass,'Ball')
for z in (3.7,4.95):box('ToolRail',(0,1.4,z),(6.25,.23,.24),dark)
box('CrestPlaque',(0,1.25,5.1),(1.12,.28,.88),iron,rot=(0,-4,0))
piece('Skull',(0,1.06,5.19),(.58,.15,.47),'E0CE9F','Ball')
box('SkullJaw',(0,1.04,4.98),(.32,.11,.17),'E0CE9F')
for x in (-.14,.14):piece('EyeSocket',(x,.98,5.2),(.14,.07,.15),dark,'Ball')
# Hammer, wrench and screwdriver have readable silhouettes.
rod('HammerHandle',(-2.25,1.05,3.85),(-2.03,1.05,4.8),.085,edge,'Wood')
box('HammerHead',(-2.04,1.05,4.77),(.73,.28,.29),steel,rot=(0,-12,0))
box('WrenchShaft',(-1.02,1.04,4.24),(.16,.17,.92),steel,rot=(0,10,0))
box('WrenchHeel',(-1.08,1.04,3.86),(.28,.2,.22),steel)
for x in (-1.14,-.83):box('WrenchJaw',(x,1.04,4.78),(.16,.2,.32),steel)
box('WrenchBridge',(-.985,1.04,4.6),(.47,.2,.15),steel)
box('DriverGrip',(1.02,1.02,4.08),(.23,.23,.5),'7A586F')
box('DriverShaft',(1.02,1.02,4.58),(.07,.07,.55),steel)
for x in (-2.1,-1,1.02):rod('ToolHook',(x,1.38,4.96),(x,1,4.96),.055,brass)
# Folded purple mat anchors the weapon silhouette.
box('WorkMat',(-.45,-.32,3.35),(3.55,1.65,.045),'51445E')
for x in (-2.15,1.25):box('MatBorder',(x,-.32,3.377),(.035,1.55,.012),'A78AAB')
box('RifleStock',(-1.6,-.4,3.56),(1,.42,.28),edge,rot=(0,0,-7))
box('RifleReceiver',(-.43,-.4,3.56),(1.45,.31,.28),iron)
box('RifleTopRail',(-.45,-.4,3.74),(1,.2,.08),steel)
rod('RifleBarrel',(.3,-.4,3.58),(1.45,-.4,3.58),.075,steel)
rod('RifleMuzzle',(1.37,-.4,3.58),(1.64,-.4,3.58),.1,iron)
box('RifleGrip',(-.8,-.62,3.5),(.25,.43,.18),dark,rot=(0,0,-15))
box('DetachedMagazine',(.18,-.9,3.47),(.5,.32,.17),iron,rot=(0,0,-18))
# Actual two-jaw vise and screw handle, placed at the left front edge.
box('ViseBase',(-2.7,-.7,3.48),(1,.9,.25),iron)
box('ViseBody',(-2.7,-.67,3.77),(.54,.65,.46),iron)
for y in (-1.12,-.45):
    box('ViseJaw',(-2.7,y,4.01),(.88,.22,.39),iron)
    box('ViseJawFace',(-2.7,y,4.21),(.89,.23,.07),steel)
rod('ViseScrew',(-2.7,-.62,3.83),(-2.7,-1.62,3.83),.09,steel)
rod('ViseHandle',(-3,-1.62,3.51),(-2.4,-1.62,4.15),.055,steel)
# Mutagen bottle rack and little hardware tray.
box('BottleRack',(2.34,.83,3.46),(1.17,.63,.23),dark)
for x,h in ((2.04,.59),(2.63,.83)):
    piece('MutagenBottle',(x,.83,3.58+h/2),(.34,.34,h),'669970','Cylinder')
    piece('MutagenLiquid',(x,.625,3.58+h*.4),(.22,.055,h*.49),'A2EB72','Ball',material='Neon')
    piece('BottleNeck',(x,.83,3.6+h),(.19,.19,.18),'82A58F','Cylinder')
    piece('BottleCork',(x,.83,3.73+h),(.22,.22,.12),edge,'Cylinder')
box('HardwareTray',(2.38,-.65,3.4),(1,.8,.13),iron)
for x,y in ((2.12,-.76),(2.45,-.5),(2.62,-.83)):
    piece('SpareBolt',(x,y,3.52),(.15,.15,.18),brass,'Cylinder')
# Warm caged lantern, attached to the right post.
rod('LanternBracket',(3.05,1.35,5.23),(3.36,.53,5.23),.07,iron)
rod('LanternHook',(3.36,.53,5.23),(3.36,.53,4.96),.05,iron)
for z in (4.05,4.89):box('LanternCap',(3.36,.53,z),(.64,.61,.13),iron)
piece('LanternGlow',(3.36,.53,4.48),(.35,.33,.61),'FFD28A','Ball',material='Neon')
for x in (3.12,3.6):
    for y in (.3,.76):rod('LanternCage',(x,y,4.09),(x,y,4.86),.035,brass)
# Supply crate and spare iron on lower shelf.
box('SupplyCrate',(-1.7,0,1.32),(1.7,1.42,.86),dark)
for z in (1.05,1.36,1.67):box('CrateSlat',(-1.7,-.73,z),(1.75,.1,.23),edge)
for x in (-2.35,-1.05):box('CrateBrace',(x,-.8,1.36),(.14,.08,.86),wood)
for i in range(3):box('SpareMetal',(.45+i*.5,.2,1.03),(.37,1.4,.25),iron)

# Export the exact same primitive layout as a self-contained, inactive module.
# The module only creates geometry when Build is explicitly called after approval.
conversion=Matrix(((1,0,0),(0,0,1),(0,-1,0)))
rows=[]
for o,shape,color,material in parts:
    r=o.rotation_euler.to_matrix();p=conversion@o.location
    if shape=='Cylinder':
        # Roblox cylinders use local X as their length axis.
        basis=Matrix(((0,1,0),(0,0,1),(1,0,0)))
        rr=conversion@r@basis;s=(o.scale.z,o.scale.x,o.scale.y)
    else:
        rr=conversion@r@conversion.transposed();s=(o.scale.x,o.scale.z,o.scale.y)
    rows.append(dict(name=o.name,shape=shape,color=color,material=material,size=list(s),cf=list(p)+[rr[i][j] for i in range(3) for j in range(3)]))
(ROOT/'parts.json').write_text(json.dumps(rows,indent=2))
def nums(v):return ','.join(f'{n:.6g}' for n in v)
lua=['-- APPROVAL DRAFT: not installed in the game. No asset dependencies.',
     'local Workbench = {}','function Workbench.Build(parent, origin)',
     ' origin = origin or CFrame.identity'," local model = Instance.new('Model'); model.Name = 'Workbench'",
     ' local function part(name, size, cf, color, material, shape)',
     "  local p = Instance.new('Part'); p.Name = name; p.Size = size; p.CFrame = origin * cf",
     '  p.Color = Color3.fromHex(color); p.Material = Enum.Material[material]; p.Shape = Enum.PartType[shape]',
     '  p.Anchored = true; p.CanCollide = false; p.CanTouch = false; p.CanQuery = false; p.Parent = model',
     ' end']
for q in rows:
    lua.append(f' part("{q["name"]}",Vector3.new({nums(q["size"])}),CFrame.new({nums(q["cf"])}),"{q["color"]}","{q["material"]}","{q["shape"]}")')
lua+=[' model.Parent = parent',' return model','end','return Workbench']
(ROOT/'WorkbenchDraft.lua').write_text('\n'.join(lua)+'\n')
bpy.ops.object.select_all(action='DESELECT')
for o,*_ in parts:o.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(ROOT/'Workbench.glb'),use_selection=True,export_format='GLB')

# Preview stage is excluded from the game model.
bpy.ops.mesh.primitive_plane_add(size=200);ground=bpy.context.object;ground.name='PreviewGround';ground.data.materials.append(mat('555D48'))
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=40;scene.cycles.use_denoising=True
scene.render.resolution_x=1400;scene.render.resolution_y=1200;scene.render.resolution_percentage=100
scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.22,.25,.3,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.6
scene.view_settings.view_transform='AgX'
for pos,power,size in (((-3,-6,10),1400,7),((5,3,8),1700,6),((-6,3,5),800,5)):
    bpy.ops.object.light_add(type='AREA',location=pos);o=bpy.context.object;o.data.energy=power;o.data.shape='DISK';o.data.size=size;o.rotation_euler=(Vector((0,0,2.5))-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add();cam=bpy.context.object;scene.camera=cam;cam.data.type='ORTHO';cam.data.ortho_scale=10.4
for name,pos in [('preview',(9,-15,10)),('front',(-4,-17,8))]:
    cam.location=pos;cam.rotation_euler=(Vector((0,0,2.65))-cam.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=str(ROOT/(name+'.png'));bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'Workbench.blend'))
print('APPROVAL_DRAFT',len(parts),'parts; Studio and runtime sources unchanged')
