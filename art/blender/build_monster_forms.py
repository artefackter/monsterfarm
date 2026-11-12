"""Export passive/aggressive appearance prototypes and inspect them in Blender."""
import json
import math
from pathlib import Path
import sys
import bpy
from mathutils import Vector, Matrix

HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE));sys.path.insert(0,str(HERE.parent/'tools'))
import kit
revision_two='--revision-two' in sys.argv
revision_three='--revision-three' in sys.argv
revision_four='--revision-four' in sys.argv
revision_five='--revision-five' in sys.argv
revision_six='--revision-six' in sys.argv
if revision_six:
    import assets_monster_forms_v6 as assets
elif revision_five:
    import assets_monster_forms_v5 as assets
elif revision_four:
    import assets_monster_forms_v4 as assets
elif revision_three:
    import assets_monster_forms_v3 as assets
elif revision_two:
    import assets_monster_forms_v2 as assets
else:
    import assets_monster_forms as assets
from package_monster_prototypes import write_pack

pack_name=('monster-forms-v6' if revision_six else 'monster-forms-v5' if revision_five else 'monster-forms-v4' if revision_four else
           'monster-forms-v3' if revision_three else 'monster-forms-v2' if revision_two else 'monster-forms-v1')
OUT=HERE.parent/'export'/pack_name
if '--output' in sys.argv:OUT=Path(sys.argv[sys.argv.index('--output')+1]).resolve()
PREVIEW=HERE.parent/'preview'/pack_name
OUT.mkdir(parents=True,exist_ok=True);PREVIEW.mkdir(parents=True,exist_ok=True)
assets.build()
manifest,baked,total=kit.export_all(str(OUT))
(OUT/'_manifest.json').write_text(json.dumps(manifest,indent=2))
(OUT/'_rig.json').write_text(json.dumps({'coordinates':'Roblox (-BlenderX, BlenderZ, BlenderY)',
                                      'feetY':0,'joints':assets.JOINTS},indent=2))
(OUT/'_forms.json').write_text(json.dumps({'scope':'Appearance and poses only; no game state changes.',
                                        'forms':assets.FORMS,
                                        'appearanceChecks':getattr(assets,'CHECKS',{})},indent=2))
path,report=write_pack(OUT,manifest,assets.JOINTS,total)
new_path=OUT/'MonsterForms.glb';path.rename(new_path)


def clear():
    for obj in list(bpy.data.objects):bpy.data.objects.remove(obj,do_unlink=True)


clear();bpy.ops.import_scene.gltf(filepath=str(new_path))
actual=[obj for obj in bpy.data.objects if obj.type=='MESH']
expected={f"{name}__{p['part']}":p for name,parts in manifest.items() for p in parts}
assert set(obj.name for obj in actual)==set(expected)
for obj in actual:
    meta=expected[obj.name]
    assert obj.data.color_attributes
    assert obj.parent and obj.parent.name==obj.name.split('__')[0]
    assert len(obj.data.polygons)==meta['tris']
    dims=[obj.dimensions.x,obj.dimensions.z,obj.dimensions.y]
    assert all(abs(a-b)<.012 or (a==.05 and b<=.05) for a,b in zip(meta['size'],dims)),obj.name
report['roundtrip']={'parts':len(actual),'vertexColors':True,'groupsAndDimensionsVerified':True}
report['formPairs']=len(assets.FORMS)
report['scope']='Appearance and poses only.'
report['footClearance']={}
for name,parts in manifest.items():
    minimum=100
    for meta in parts:
        if meta['part'] in ('ArmL','ArmR','LegL','LegR','HandItem'):
            mesh=json.loads((OUT/(meta['mesh']+'.json')).read_text())
            minimum=min(minimum,min(mesh['v'][1::3])+meta['offset'][1])
    assert minimum>=-.002,(name,minimum)
    report['footClearance'][name]=round(minimum,4)
(OUT/'_validation.json').write_text(json.dumps(report,indent=2))
print('VALIDATED',report,flush=True)

FONT=bpy.data.fonts.load('/System/Library/Fonts/Supplemental/Arial Bold.ttf')


def material(name,color):
    m=bpy.data.materials.new(name);m.use_nodes=True
    shader=m.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value=(*[v**2.2 for v in kit._rgb(color)],1)
    shader.inputs['Roughness'].default_value=.76
    return m


def label(text,x,z,size,color='F4EFE4'):
    curve=bpy.data.curves.new(text,'FONT');curve.body=text;curve.font=FONT
    curve.align_x='CENTER';curve.size=size;curve.extrude=.001
    obj=bpy.data.objects.new(text,curve);bpy.context.scene.collection.objects.link(obj)
    obj.location=(x,-3.25,z);obj.rotation_euler=(math.pi/2,0,0)
    curve.materials.append(material('Type',color))


def spawn(name,x=0,z=0,angle=0,parts=None):
    before=set(bpy.data.objects)
    metadata=[p for p in manifest[name] if p['part'] in parts] if parts else manifest[name]
    kit.spawn_preview(baked,name,metadata,(x,0,z),rot_z=angle)
    for obj in set(bpy.data.objects)-before:
        part=obj.name;obj.name=name+'__'+part
        meta=next(p for p in manifest[name] if p['part']==part)
        obj['Attach']=meta['attach'] or part
        obj.data.materials[0].node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.79
        if meta['material']=='Neon':
            tree=obj.data.materials[0].node_tree;shader=tree.nodes.get('Principled BSDF')
            attr=next(node for node in tree.nodes if node.type=='VERTEX_COLOR')
            tree.links.new(attr.outputs['Color'],shader.inputs['Emission Color'])
            shader.inputs['Emission Strength'].default_value=.12 if name.endswith('_Passive') else 1.0


def stage(x,radius):
    bpy.ops.mesh.primitive_cylinder_add(vertices=48,radius=radius,depth=.16,location=(x,0,-.078))
    obj=bpy.context.object;obj.data.materials.append(material('Plinth','465966'))
    bevel=obj.modifiers.new('Rounded edge','BEVEL');bevel.width=.05;bevel.segments=2


def render(name,target,width,size):
    camera=(0,-29,9.1 if name=='deer-forms' else 8.1)
    if name=='deer-claws-correction':camera=(0,-10,3)
    if name=='cavedweller-side':camera=(0,-24,5.3)
    kit.setup_render(str(PREVIEW/(name+'.png')),camera,target,res=size,samples=36,bg='718B9D')
    scene=bpy.context.scene;scene.cycles.use_denoising=True
    scene.camera.data.type='ORTHO';scene.camera.data.ortho_scale=width
    scene.world.node_tree.nodes['Background'].inputs[1].default_value=.70
    for lamp in bpy.data.lights:
        if lamp.type=='SUN':lamp.energy=1.35
    for pos,power,scale,color in [((-6,-12,13),1500,9,(1,.88,.76)),
                                  ((8,-4,8),900,8,(.72,.84,1)),
                                  ((3,6,11),1900,7,(.61,.82,1))]:
        lamp=bpy.data.lights.new('Softbox','AREA');lamp.energy=power
        lamp.shape='DISK';lamp.size=scale;lamp.color=color
        obj=bpy.data.objects.new('Softbox',lamp);scene.collection.objects.link(obj)
        obj.location=pos;obj.rotation_euler=(Vector(target)-obj.location).to_track_quat('-Z','Y').to_euler()
    bpy.ops.render.render(write_still=True)
    print('RENDERED',name,flush=True)


for family,title,file,height,width,distance,radius,target in [
    ('Deer_Punk','ОЛЕНЬ','deer-forms',9.05,15.4,3.8,2.65,(0,0,4.1)),
    ('RingMaw','КОЛЬЦЕВИК','ringmaw-forms',5.1,12.8,3.25,2.8,(0,0,2.15)),
    ('CaveDweller','ПЕЩЕРНИК','cavedweller-forms',7.02,12.0,2.9,2.45,(0,0,3.10)),
    ('Parasite_Punk','ПАРАЗИТ','parasite-forms',7.0,13.0,3.0,2.5,(0,0,3.0)),
    ('Stalker_Punk','СТАЛКЕР','stalker-forms',7.7,12.5,2.9,2.45,(0,0,3.35)),
]:
    if family.startswith(('Parasite','Stalker')) and not revision_six:continue
    if revision_six and family not in ('Parasite_Punk','Stalker_Punk','CaveDweller'):continue
    if revision_three and family!='CaveDweller':continue
    if revision_four and family!='RingMaw':continue
    if revision_five and family!='CaveDweller':continue
    clear()
    bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.17))
    bpy.context.object.data.materials.append(material('Backdrop','6A8294'))
    for state,x,angle,caption,color in [('Passive',-distance,-12,'ПАССИВНАЯ','B8E5BD'),
                                       ('Aggressive',distance,-18,'АГРЕССИВНАЯ','FFC0A4')]:
        if revision_four and state=='Passive':angle=-30
        spawn(family+'_'+state,x,angle=angle);stage(x,radius)
        label(caption,x,.12,.26,color)
    label(title,0,height,.38)
    render(file,target,width,(1900,1200 if family!='RingMaw' else 1000))

if revision_five or revision_six:
    clear()
    bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.17))
    bpy.context.object.data.materials.append(material('Backdrop','6A8294'))
    for state,x,caption,color in [('Passive',-2.9,'ПАССИВНАЯ','B8E5BD'),
                                   ('Aggressive',2.9,'НАКЛОН НАЗАД 30°','FFC0A4')]:
        spawn('CaveDweller_'+state,x,angle=-90);stage(x,2.4)
        label(caption,x,.12,.22,color)
    label('ПЕЩЕРНИК / ВИД СБОКУ',0,6.65,.32)
    render('cavedweller-side',(0,0,3.15),11.9,(1900,1200))

if revision_two:
    clear()
    for x,angle,caption in [(-.72,0,'СПЕРЕДИ'),(.72,-90,'СБОКУ')]:
        before=set(bpy.data.objects)
        spawn('Deer_Punk_Passive',parts={'ArmL'})
        for obj in set(bpy.data.objects)-before:
            obj.matrix_world=(Matrix.Translation((x,0,1.45)) @
                              Matrix.Rotation(math.radians(angle),4,'Z') @
                              Matrix.Translation(-Vector((1.74,-.4,2.36))))
        label(caption,x,.16,.12)
    render('deer-claws-correction',(0,0,1.0),3.25,(1700,1100))

clear()
for i,name in enumerate(manifest):spawn(name,(i%6-2.5)*7,z=10*(i//6))
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'MonsterForms.blend'))
