"""Export and render local, approval-only Kalash skin prototypes."""
import json
import math
from pathlib import Path
import struct
import sys
import hashlib

import bpy
from mathutils import Vector

HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE))
sys.path.insert(0,str(HERE.parent/'tools'))
import kit
import assets_kalash_skins as assets
from package_monster_prototypes import write_pack

OUT=HERE.parent/'export'/'kalash-skins-v1'
if '--output' in sys.argv:OUT=Path(sys.argv[sys.argv.index('--output')+1]).resolve()
PREVIEW=HERE.parent/'preview'/'kalash-skins-v1'
OUT.mkdir(parents=True,exist_ok=True)
PREVIEW.mkdir(parents=True,exist_ok=True)
assets.build()
manifest,baked,total=kit.export_all(str(OUT))
(OUT/'_manifest.json').write_text(json.dumps(manifest,indent=2))
(OUT/'_rig.json').write_text(json.dumps(assets.JOINTS,indent=2))
path,report=write_pack(OUT,manifest,assets.JOINTS,total,weapons=True)

# Per-finish PBR properties survive GLB import; glow is confined to tiny indicators.
data=path.read_bytes()
json_length=struct.unpack_from('<I',data,12)[0]
document=json.loads(data[20:20+json_length])
binary=data[28+json_length:]
document['materials']=[
    {'name':'Painted alloy','pbrMetallicRoughness':{'baseColorFactor':[1,1,1,1],'metallicFactor':.20,'roughnessFactor':.36}},
    {'name':'Dragon alloy','pbrMetallicRoughness':{'baseColorFactor':[1,1,1,1],'metallicFactor':.64,'roughnessFactor':.29}},
    {'name':'Teal indicators','pbrMetallicRoughness':{'baseColorFactor':[1,1,1,1],'metallicFactor':0,'roughnessFactor':.35},'emissiveFactor':[.05,.8,.65]},
]
for mesh in document['meshes']:
    material=2 if mesh['name'].endswith('.Glow') else 1 if 'GoldenDragon' in mesh['name'] else 0
    for primitive in mesh['primitives']:primitive['material']=material
encoded=json.dumps(document,separators=(',',':')).encode()
encoded+=b' '*(-len(encoded)%4)
path.write_bytes(struct.pack('<III',0x46546C67,2,28+len(encoded)+len(binary))+
                 struct.pack('<II',len(encoded),0x4E4F534A)+encoded+
                 struct.pack('<II',len(binary),0x004E4942)+binary)
new_path=OUT/'KalashSkins.glb'
path.rename(new_path)
report['bytes']=new_path.stat().st_size
report['sha256']=hashlib.sha256(new_path.read_bytes()).hexdigest()


def clear():
    for obj in list(bpy.data.objects):bpy.data.objects.remove(obj,do_unlink=True)


clear()
bpy.ops.import_scene.gltf(filepath=str(new_path))
actual=[obj for obj in bpy.data.objects if obj.type=='MESH']
expected={f"{name}__{p['part']}":p for name,parts in manifest.items() for p in parts}
assert set(obj.name for obj in actual)==set(expected)
for obj in actual:
    meta=expected[obj.name]
    assert obj.data.color_attributes and len(obj.data.polygons)==meta['tris']
    assert obj.parent and obj.parent.name==obj.name.split('__')[0]
    dims=[obj.dimensions.x,obj.dimensions.z,obj.dimensions.y]
    assert all(abs(a-b)<.012 or (a==.05 and b<=.05) for a,b in zip(meta['size'],dims)),obj.name
report['roundtrip']={'parts':len(actual),'vertexColors':True,'movingPartsAndDimensionsVerified':True}
report['skinNames']=list(assets.STYLES)
(OUT/'_validation.json').write_text(json.dumps(report,indent=2))
print('VALIDATED',report,flush=True)
if '--export-only' in sys.argv:
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'KalashSkins.blend'))
    sys.exit(0)

FONT=bpy.data.fonts.load('/System/Library/Fonts/Supplemental/Arial Bold.ttf')


def label(text,z,size=.19,color='F1E9DB'):
    font=bpy.data.curves.new(text,'FONT');font.body=text;font.font=FONT
    font.align_x='CENTER';font.size=size;font.extrude=.001
    obj=bpy.data.objects.new(text,font);bpy.context.scene.collection.objects.link(obj)
    obj.location=(0,-.8,z);obj.rotation_euler=(math.pi/2,0,0)
    mat=bpy.data.materials.new('Type');mat.diffuse_color=(*kit._rgb(color),1)
    font.materials.append(mat)


def spawn(style,z=0,angle=80):
    name='Kalash_'+style
    before=set(bpy.data.objects)
    kit.spawn_preview(baked,name,manifest[name],(0,0,z),rot_z=angle)
    for obj in set(bpy.data.objects)-before:
        part=obj.name
        obj.name=name+'__'+part
        obj['Attach']=next(p['attach'] for p in manifest[name] if p['part']==part)
        shader=obj.data.materials[0].node_tree.nodes.get('Principled BSDF')
        shader.inputs['Metallic'].default_value=.64 if style=='GoldenDragon' else .20
        shader.inputs['Roughness'].default_value=.29 if style=='GoldenDragon' else .36
        if part=='Glow':
            tree=obj.data.materials[0].node_tree
            vertex=next(n for n in tree.nodes if n.type=='VERTEX_COLOR')
            tree.links.new(vertex.outputs['Color'],shader.inputs['Emission Color'])
            shader.inputs['Emission Strength'].default_value=.8


def render(name,target,width,size):
    camera=(0,-17,4.6 if name=='kalash-skins' else 3.4)
    kit.setup_render(str(PREVIEW/(name+'.png')),camera,target,res=size,samples=40,bg='394B5C')
    scene=bpy.context.scene;scene.cycles.use_denoising=True
    scene.camera.data.type='ORTHO';scene.camera.data.ortho_scale=width
    scene.world.node_tree.nodes['Background'].inputs[1].default_value=.62
    for lamp in bpy.data.lights:
        if lamp.type=='SUN':lamp.energy=1.4
    for pos,power,scale,color in [((-4,-6,9),1050,6,(1,.88,.73)),
                                  ((4,-1,6),1100,5,(.65,.85,1)),
                                  ((0,5,7),1800,5,(.74,.88,1))]:
        lamp=bpy.data.lights.new('Softbox','AREA');lamp.energy=power
        lamp.shape='DISK';lamp.size=scale;lamp.color=color
        obj=bpy.data.objects.new('Softbox',lamp);scene.collection.objects.link(obj)
        obj.location=pos;obj.rotation_euler=(Vector(target)-obj.location).to_track_quat('-Z','Y').to_euler()
    bpy.ops.render.render(write_still=True)
    print('RENDERED',name,flush=True)


clear()
for style,z,title,color in [('Asiimov',2.0,'ASIIMOV','FF9A43'),
                           ('GoldenDragon',0,'GOLDEN DRAGON','F4CD70'),
                           ('Cyberpunk',-2.0,'CYBERPUNK','4CE2D2')]:
    spawn(style,z)
    label(title,z+.90,.21,color)
label('КАЛАШ / СКИНЫ',3.18,.24)
render('kalash-skins',(0,0,.0),6.15,(1750,1750))
for style in assets.STYLES:
    clear();spawn(style)
    label(style.upper() if style!='GoldenDragon' else 'GOLDEN DRAGON',.78,.18)
    render(style.lower(),(0,0,-.05),4.20,(1700,900))
clear()
for i,style in enumerate(assets.STYLES):spawn(style,i*2)
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'KalashSkins.blend'))
