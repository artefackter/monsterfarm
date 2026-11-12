"""Reviewed forms: deer teeth, closed RingMaw, and a fixed-anatomy CaveDweller jaw."""
import copy
import math
import bmesh
from mathutils import Matrix,Vector
import kit
import assets_monster_prototypes as base
import assets_monster_prototypes_v3 as faces
import assets_monster_prototypes_v6 as collection
import assets_monster_forms as previous
import creature_extremities_v6 as limbs
from assets_deer import box

JOINTS=previous.JOINTS
FORMS={}
CHECKS={}


def corrected_deer_hand(mesh,wrist,side,color,tip,length=.53,spread=1,curled=False):
    before=set(mesh.bm.verts)
    limbs.deer_hand(mesh,wrist,side,color,tip,length,spread,curled)
    if curled:
        return # The grasp continues to wrap around the existing tool shaft.
    x,y,z=wrist
    added=set(mesh.bm.verts)-before
    # Neutral forearms: thumb toward -Y (the face), palms/claw hooks toward the body.
    # Swapping the two axes also corrects the old handedness of the free hands.
    for vertex in added:
        dx,dy=vertex.co.x-x,vertex.co.y-y
        vertex.co.x=x+side*dy
        vertex.co.y=y+side*dx
    affected=[face for face in mesh.bm.faces if all(v in added for v in face.verts)]
    bmesh.ops.recalc_face_normals(mesh.bm,faces=affected)
    mesh.bm.normal_update()


def closed_ring(asset):
    head=next(p for p in asset.parts if p.name=='Head')
    center=Vector((.13,-1.98,2.78))
    tilt=Matrix.Rotation(math.radians(-9),3,'Y')@Matrix.Rotation(math.radians(6),3,'Z')
    def at(radius,angle,depth):
        return center+tilt@Vector((math.cos(angle)*radius,-depth,math.sin(angle)*radius*1.12))
    for i in range(12):
        a=i*math.tau/12;b=(i+1)*math.tau/12
        # Solid triangular petal tips meet at the center: no iris aperture is left.
        head.loft([[at(1.15,a,.704),at(1.15,b,.704),at(0,0,.79)],
                   [at(1.15,a,.735),at(1.15,b,.735),at(0,0,.83)]],
                  '82513E' if i%2 else '996044',smooth=False)
    seal=at(0,0,.835)
    head.sphere(seal,(.055,.031,.062),'A66D4E',sub=1,smooth=False)


def cave_head(asset,form,passive_jaw_z=5.335,aggressive_jaw_z=4.683,fold_passive_fangs=True):
    """One skull and one jaw; bone/teeth dimensions stay fixed between states."""
    aggressive=form=='Aggressive'
    pivot=Vector(kit.to_rbx(JOINTS[asset.name]['Head']))
    head=base.part(asset,'Head',pivot,ao=.22,ao_dist=.28)
    glow=base.part(asset,'FaceGlow',attach='Head',material='Neon',ao=0,grad=0,cast=False)
    # The skull, hat position, neck and eye sockets never change size or height.
    box(head,(0,-.665,5.875),(.87,.67,.84),'211D25',bevel=.035)
    box(head,(0,-.423,5.02),(.30,.32,.80),'201B23',bevel=.025)
    jaw_z=aggressive_jaw_z if aggressive else passive_jaw_z
    box(head,(0,-.761,jaw_z),(.742,.51,.214),'241E26',bevel=.026)
    lower_edge=jaw_z+.107
    mouth_height=5.455-lower_edge
    if mouth_height>.001:
        box(head,(0,-.653,lower_edge+mouth_height*.5),(.645,.026,mouth_height),
            '100D15',bevel=.005)
        for side in (-1,1):
            box(head,(side*.325,-.698,lower_edge+mouth_height*.5),
                (.106,.303,mouth_height),'201A24',bevel=.005)
    for side in (-1,1):
        box(glow,(side*.216,-1.012,6.035),(.093,.044,.087),
            'FF3D32' if aggressive else 'FFF4DE',bevel=.004)

    # The same eight fangs hinge inside the jaw/skull when closed; none are squashed.
    def fang(x,root_z,length,upper):
        root=Vector((x,-.964,root_z))
        sign=-1 if upper else 1
        before=set(glow.bm.verts)
        box(glow,(x,-.964,root_z+sign*length*.5),(.068,.065,length),
            'FBE6D0',bevel=.008)
        if not aggressive and fold_passive_fangs:
            rotation=Matrix.Rotation(math.radians(90 if upper else -90),3,'X')
            for vertex in set(glow.bm.verts)-before:
                vertex.co=root+rotation@(vertex.co-root)
        box(head,(x,-.925,root_z+sign*.045),(.09,.102,.11),'754034',bevel=.010)
    lengths=[]
    for j in range(4):
        x=(j-1.5)*.144
        upper=.298 if j in (0,3) else .450
        lower=.406 if j in (0,3) else .234
        fang(x,5.505,upper,True)
        fang(x,jaw_z+.086,lower,False)
        lengths.extend((upper,lower))
    glow.bm.normal_update()
    CHECKS[asset.name]={'skullSize':[.87,.67,.84],'skullCenter':[0,-.665,5.875],
                        'jawSize':[.742,.51,.214],'jawCenterZ':jaw_z,
                        'fangLengths':lengths,'eyeColor':'red' if aggressive else 'ivory',
                        'mouthOpen':mouth_height>.30,'mouthOpeningHeight':mouth_height,
                        'fangsFolded':not aggressive and fold_passive_fangs}


def build(cave_head_builder=None,ring_head_builder=None):
    collection.build(deer_hand_builder=corrected_deer_hand)
    sources=list(kit.ASSETS.values())
    source_joints=copy.deepcopy(collection.JOINTS)
    kit.ASSETS.clear()
    for source in sources:
        FORMS[source.name]={}
        for form in ('Passive','Aggressive'):
            a=kit.asset(source.name+'_'+form)
            JOINTS[a.name]=copy.deepcopy(source_joints[source.name])
            deer=source.name.startswith('Deer_')
            ring=source.name.startswith('RingMaw')
            for p in source.parts:
                if deer and p.name=='Head':continue
                if not deer and not ring and p.name in ('Head','FaceGlow'):continue
                if ring and ring_head_builder and p.name in ('Head','MawGlow'):continue
                previous.clone_part(p,a)
            if deer:
                faces.deer_face(a,source.name.split('_')[1],expression=form+'V2')
                if form=='Aggressive':
                    previous.pose_group(a,'Head',(9,0,0))
                    for side,group in ((-1,'ArmR'),(1,'ArmL')):
                        previous.pose_group(a,group,(-15,-side*10,0))
                CHECKS[a.name]={'mouthOpen':True,'hasFangs':form=='Aggressive',
                                'thumbsPointForward':True,'clawHooksPointTowardPalm':True}
            elif ring:
                if ring_head_builder:ring_head_builder(a,form)
                if form=='Passive':
                    if not ring_head_builder:closed_ring(a)
                    previous.pose_group(a,'Head',(-5,0,0))
                else:
                    previous.pose_group(a,'Head',(8,0,0))
                CHECKS[a.name]={'ringClosed':form=='Passive','centerApertureRadius':0 if form=='Passive' else .19}
            else:
                (cave_head_builder or cave_head)(a,form)
                if form=='Aggressive':
                    for side,group in ((-1,'ArmR'),(1,'ArmL')):
                        previous.pose_group(a,group,(-10,-side*6,0))
            FORMS[source.name][form]=a.name
    for name,pair in FORMS.items():
        if name.startswith('CaveDweller'):
            passive,aggressive=(CHECKS[pair[state]] for state in ('Passive','Aggressive'))
            for field in ('skullSize','skullCenter','jawSize','fangLengths'):
                assert passive[field]==aggressive[field],(name,field)
