import bpy, math, json, sys
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parent; PROJECT=ROOT.parent.parent
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
M={}; catalog=[]; current=[]
def mat(h):
 if h not in M:
  m=bpy.data.materials.new(h); m.diffuse_color=tuple(int(h[i:i+2],16)/255 for i in (0,2,4))+(1,);m.use_nodes=True;m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=m.diffuse_color;m.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.65;M[h]=m
 return M[h]
def finish(o,n,c):
 o.name=n;o.data.materials.append(mat(c));current.append(o);return o
def box(n,p,s,c,bevel=.07):
 bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=bpy.context.object;o.scale=s;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bevel:
  b=o.modifiers.new('Soft edges','BEVEL');b.width=bevel;b.segments=2;bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=b.name)
 return finish(o,n,c)
def ball(n,p,s,c):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6,location=p);o=bpy.context.object;o.scale=s;return finish(o,n,c)
def cyl(n,p,r,d,c,rot=(0,0,0)):
 bpy.ops.mesh.primitive_cylinder_add(vertices=16,radius=r,depth=d,location=p,rotation=rot);return finish(bpy.context.object,n,c)
def rod(n,a,b,r,c):
 o=cyl(n,(Vector(a)+Vector(b))/2,r,(Vector(b)-Vector(a)).length,c);o.rotation_euler=(Vector(b)-Vector(a)).to_track_quat('Z','Y').to_euler();return o
def torus(n,p,r,t,c,rot=(0,0,0)):
 bpy.ops.mesh.primitive_torus_add(major_segments=24,minor_segments=6,location=p,major_radius=r,minor_radius=t,rotation=rot);return finish(bpy.context.object,n,c)
def prism(n,pts,y,depth,c):
 v=[(x,y+dy,z) for dy in (-depth/2,depth/2) for x,z in pts];k=len(pts);f=[tuple(reversed(range(k))),tuple(range(k,2*k))]+[(i,(i+1)%k,(i+1)%k+k,i+k) for i in range(k)]
 me=bpy.data.meshes.new(n);me.from_pydata(v,[],f);o=bpy.data.objects.new(n,me);bpy.context.collection.objects.link(o);return finish(o,n,c)
def begin():
 global current;current=[]
def save(name,group):
 bpy.ops.object.select_all(action='DESELECT')
 for o in current:o.select_set(True)
 bpy.context.view_layer.objects.active=current[0]
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 bpy.ops.export_scene.gltf(filepath=str(ROOT/'models'/f'{name}.glb'),use_selection=True,export_format='GLB')
 points=[o.matrix_world@Vector(v) for o in current for v in o.bound_box]; bounds=[[min(v[i] for v in points),max(v[i] for v in points)] for i in range(3)]
 catalog.append(dict(name=name,group=group,objects=len(current),triangles=sum(len(o.data.loop_triangles) if o.data.loop_triangles else sum(len(p.vertices)-2 for p in o.data.polygons) for o in current),bounds=bounds))
 coll=bpy.data.collections.new(name);bpy.context.scene.collection.children.link(coll)
 for o in current:
  for c in list(o.users_collection):c.objects.unlink(o)
  coll.objects.link(o)
 return coll
# Shared grave silhouette: raised round arch, inset panel, carved friendly zombie emblem.
for i,(kind,body,trim) in enumerate([('Wooden','A86B3C','E5AC5F'),('Stone','9693BA','C9C5E6'),('Marble','D6E2E8','F1FAFF'),('Golden','E8A820','FFE37A'),('Lunar','7567BC','BCEAFF')]):
 begin();box('Foundation',(0,0,.16),(2,.95,.32),'62607D');box('Foot',(0,0,.4),(1.65,.70,.2),trim)
 shape=[(-.75,.45),(.75,.45),(.75,1.9)]+[(.75*math.cos(a),1.9+.75*math.sin(a)) for a in [j*math.pi/12 for j in range(1,13)]]
 prism('Arch',shape,0,.38,trim)
 inner=[(x*.83,.52+(z-.45)*.89) for x,z in shape];prism('Inset',inner,-.225,.08,body)
 # raised face emblem instead of illegible lettering
 ball('ZombieFace',(0,-.31,1.62),(.43,.07,.38),trim)
 for x in (-.16,.16):box('Eye',(x,-.395,1.67),(.12,.035,.16),body,.025)
 box('Grin',(0,-.395,1.43),(.29,.03,.10),body,.02)
 if kind=='Wooden':
  for z in (.68,.9,2.08):box('WoodSeam',(0,-.28,z),(1.18,.02,.025),'775033',0)
 if kind=='Marble':
  for x in (-.4,.43):rod('Vein',(x,-.28,.8),(x+.12,-.28,1.2),.012,'ADC2CF')
 if kind=='Lunar':
  torus('MoonHalo',(0,-.34,2.15),.16,.035,trim,(math.pi/2,0,0))
  for x in (-.52,.52):ball('Crystal',(x,-.35,.62),(.1,.1,.2),'76D9ED')
 for x in (-.85,.85):
  for d in (-.12,.12):rod('Grass',(x,-.27,.28),(x+d,-.3,.61),.035,'6CB550')
 save('Grave_'+kind,'graves')
# Pavilions sharing modular architecture, with distinctive identifying props.
for title,accent in [('Weapons','51C6D5'),('Brawler','8FCF46'),('Pets','F2BA4F'),('Quests','B897ED'),('Rewards','E9B842'),('Help','EACD89')]:
 begin();box('StoneBase',(0,0,.15),(5,3.4,.3),'8D87A2');box('Counter',(0,-.45,1.5),(4.3,1.25,1.3),'A66B39');box('CounterTop',(0,-.5,2.23),(4.6,1.6,.2),'E2B875')
 for x in (-2,2):
  for y in (-1,1):box('Post',(x,y,2.4),(.22,.22,4.3),'654334')
 for side in (-1,1):
  o=box('Roof',(side*1.2,0,4.8),(2.9,3.8,.22),'743F96');o.rotation_euler.y=side*math.radians(25)
  for j in range(6):
   o=box('RoofTile',(side*(.2+j*.4),0,5.32-j*.185),(.43,3.85,.09),'9758B5',.025);o.rotation_euler.y=side*math.radians(25)
 box('Sign',(0,-1.94,4.08),(3.8,.18,.65),'E4BC78');box('SignInset',(0,-2.04,4.08),(3.45,.03,.45),accent)
 for j in range(8):box('AwningStripe',(-2+j*.57,-1.65,3.63),(.57,1.3,.10),accent if j%2 else 'FFF0D1')
 for x in (-2.15,2.15):box('Lantern',(x,-1.2,3),(.30,.30,.5),'FFD77B')
 if title=='Weapons':
  for z in (2.7,3.2):box('RackRifle',(0,.75,z),(2.5,.15,.17),'49576A');box('Stock',(-1,.75,z),(.55,.2,.35),'AD6F38')
 elif title=='Brawler':
  for x in (-.45,.45):ball('Glove',(x,-2.13,4.1),(.28,.18,.25),'DB6069')
 elif title=='Pets':
  for x in (-1,0,1):ball('Pet',(x,-.55,2.55),(.33,.28,.3),['8BCBD9','A6D66A','DFB3D7'][int(x+1)])
 elif title=='Quests':
  for x in (-1,0,1):box('Parchment',(x,.4,2.95),(.6,.05,.8),'FFF0CE')
 elif title=='Rewards':box('Chest',(0,-.4,2.65),(2.2,1,.65),'834BA5');box('ChestBand',(0,-.94,2.65),(.22,.06,.65),'FFD365')
 else:box('OpenBook',(0,-.55,2.4),(1.4,.8,.12),'FFE6B8')
 save('Pavilion_'+title,'center')
begin();cyl('Basin',(0,0,.4),2.5,.8,'827D9B');cyl('Slime',(0,0,.83),2.18,.08,'8FD743');cyl('Pedestal',(0,0,1.12),.65,.55,'9E96B8')
for s in (-1,1):rod('Claw',(s*.3,0,1.3),(s*.9,0,2.25),.23,'8E82AB');rod('Finger',(s*.9,0,2.25),(s*.5,-.15,2.6),.16,'B6A8CA')
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=.65,location=(0,0,2.75));finish(bpy.context.object,'Crystal','BE7AE8');save('SlimeFountain','center')
begin()
for x in (-1.2,1.2):box('Leg',(x,0,.5),(.2,.7,1),'655174')
for y in (-.3,0,.3):box('Seat',(0,y,1),(3,.22,.12),'A67443')
for z in (1.45,1.75):box('Back',(0,.48,z),(3,.15,.2),'A67443')
save('Bench','center')
begin();cyl('Foot',(0,0,.1),.35,.2,'6A567B');cyl('Post',(0,0,1.5),.08,2.8,'594464');box('Lamp',(0,0,3),(.45,.45,.65),'FFD485');box('Cap',(0,0,3.4),(.65,.65,.15),'725087');save('Lantern','center')
# Purpose built weapon/alchemy bench, not an anonymous carpenter table.
begin();box('Floor',(0,0,.1),(5,3,.2),'89809D')
for x in (-1.9,1.9):
 for y in (-.9,.9):box('Leg',(x,y,1),(.3,.3,2),'654334')
box('Shelf',(0,0,.5),(4.2,2.3,.18),'A77747');box('Desk',(0,0,2),(4.7,2.6,.28),'D29F61');box('Backboard',(0,1.03,3.1),(4.4,.18,2),'7F4A95')
for x in (-1.5,-.5,.5,1.5):rod('ToolHandle',(x,.82,2.7),(x,.82,3.45),.06,'E1B76D');box('ToolHead',(x,.82,3.5),(.35,.1,.16),'BBC7D0')
box('Vice',(-1.4,-.45,2.3),(.8,.7,.4),'647B8E');box('WeaponMat',(.25,-.1,2.18),(1.8,1.3,.04),'4C776F');box('RifleReceiver',(.25,-.1,2.3),(1.25,.3,.2),'6A7487');rod('Barrel',(.8,-.1,2.3),(1.55,-.1,2.3),.07,'909AAB')
for x in (.8,1.3,1.8):cyl('Mutagen',(x,.45,2.45),.12,.5,'91D65B');cyl('BottleCap',(x,.45,2.73),.14,.08,'9A5CC1')
rod('LampArm',(-2,1,3),(-2,-.2,3.8),.07,'6C537C');ball('Lamp',(-2,-.2,3.8),(.28,.28,.18),'FFD676');save('WeaponWorkbench','workbench')
# True geometry-preserving recolour proposal of existing vertex-colour Parasite meshes.
f=PROJECT/'art/export/collection-v2/road-v3/root-archetypes-v1';manifest=json.loads((f/'_manifest.json').read_text())
begin()
for p in manifest['Parasite_Root_Aggressive']:
 d=json.loads((f/(p['mesh']+'.json')).read_text());v=d['v'];t=d['t'];off=p['offset'];verts=[(v[i]+off[0],-(v[i+2]+off[2]),v[i+1]+off[1]) for i in range(0,len(v),3)];me=bpy.data.meshes.new(p['part']);me.from_pydata(verts,[],[t[i:i+3] for i in range(0,len(t),3)]);o=bpy.data.objects.new(p['part'],me);bpy.context.collection.objects.link(o)
 # raise shadow floor, keep mouth deep; normals and vertex count untouched
 col=me.color_attributes.new(name='Color',type='FLOAT_COLOR',domain='POINT')
 for j,c in enumerate(d['c']):
  rgb=[(c>>s&255)/255 for s in (16,8,0)];lum=sum(rgb)/3
  if lum>.12 and lum<.62:rgb=[min(1,x*1.24+.085) for x in rgb]
  col.data[j].color=tuple(rgb)+(1,)
 m=bpy.data.materials.new('ParasiteVertex');m.use_nodes=True;node=m.node_tree.nodes.new('ShaderNodeVertexColor');node.layer_name='Color';m.node_tree.links.new(node.outputs['Color'],m.node_tree.nodes['Principled BSDF'].inputs['Base Color']);o.data.materials.append(m);current.append(o)
save('Parasite_LightCandidate','monster-lighting')
# Arrange separate source collections for browsable native file, render each group.
for group in ('graves','center','workbench','monster-lighting'):
 entries=[r for r in catalog if r['group']==group]; spacing=3.1 if group=='graves' else 7
 for r in catalog:
  co=bpy.data.collections[r['name']];co.hide_render=r['group']!=group
 for i,r in enumerate(entries):
  for o in bpy.data.collections[r['name']].objects:o.location.x+=(i-(len(entries)-1)/2)*spacing
 bpy.ops.object.camera_add(location=(len(entries)*spacing*.45,-len(entries)*spacing*.9,max(7,len(entries)*spacing*.6)));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,1.4))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=max(8,len(entries)*spacing*1.13);bpy.context.scene.camera=cam
 scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=16;scene.cycles.use_denoising=True;scene.render.resolution_x=1800;scene.render.resolution_y=850;scene.render.resolution_percentage=100;scene.world.color=(.25,.25,.25);scene.view_settings.view_transform='AgX'
 if group=='graves':
  for pos,energy,size in [((2,-10,16),2400,10),((-10,0,8),1800,9),((8,8,12),2200,8)]:
   bpy.ops.object.light_add(type='AREA',location=pos);l=bpy.context.object;l.data.energy=energy;l.data.shape='DISK';l.data.size=size;l.rotation_euler=(-l.location).to_track_quat('-Z','Y').to_euler()
 scene.render.filepath=str(ROOT/'previews'/f'{group}.png');bpy.ops.render.render(write_still=True);bpy.data.objects.remove(cam,do_unlink=True)
 for i,r in enumerate(entries):
  for o in bpy.data.collections[r['name']].objects:o.location.x-=(i-(len(entries)-1)/2)*spacing
for co in bpy.data.collections:
 co.hide_render=False
# Spread collections in source file; each exported GLB retains origin at base.
for i,r in enumerate(catalog):
 for o in bpy.data.collections[r['name']].objects:o.location.x+=(i%5)*8;o.location.y+=(i//5)*9
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'models'/'ReviewPack.blend'))
(ROOT/'models'/'catalog.json').write_text(json.dumps(catalog,indent=2))
print('REVIEW_MODELS_COMPLETE',len(catalog))
