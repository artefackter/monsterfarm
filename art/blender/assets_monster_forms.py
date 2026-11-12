"""Local appearance and pose states for all twelve approved creature variants."""
import copy
import math
from mathutils import Matrix,Vector
import kit
import assets_monster_prototypes_v6 as collection
import assets_monster_prototypes_v3 as faces

JOINTS={}
FORMS={}


def clone_part(source,asset):
    p=asset.part(source.name,tint=source.tint,attach=source.attach,
                 material=source.material,transparency=source.transparency,
                 ao=source.ao,ao_dist=source.ao_dist,grad=source.grad,
                 collide=source.collide,cast=source.cast)
    p.bm.free();p.bm=source.bm.copy()
    p.layer=p.bm.faces.layers.int.get('c');p.colors=list(source.colors)
    p.colfn=source.colfn
    return p


def joint(asset,name):
    return Vector(kit.to_rbx(JOINTS[asset.name][name]))


def pose_group(asset,group,angles=(0,0,0),offset=(0,0,0)):
    pivot=joint(asset,group)
    rotation=(Matrix.Rotation(math.radians(angles[2]),4,'Z') @
              Matrix.Rotation(math.radians(angles[1]),4,'Y') @
              Matrix.Rotation(math.radians(angles[0]),4,'X'))
    transform=Matrix.Translation(pivot+Vector(offset))@rotation@Matrix.Translation(-pivot)
    for p in asset.parts:
        if p.name==group or p.attach==group:
            for v in p.bm.verts:v.co=transform@v.co
            p.bm.normal_update()


def ring_iris(asset):
    head=next(p for p in asset.parts if p.name=='Head')
    center=Vector((.13,-1.98,2.78))
    tilt=Matrix.Rotation(math.radians(-9),3,'Y')@Matrix.Rotation(math.radians(6),3,'Z')
    def at(radius,angle,depth):
        local=Vector((math.cos(angle)*radius,-depth,math.sin(angle)*radius*1.12))
        return center+tilt@local
    # Closed petal plates cover the recessed fang rows while leaving a small iris.
    for i in range(12):
        angle=i*math.tau/12
        delta=math.tau/12
        head.loft([[at(1.14,angle,.70),at(1.14,angle+delta,.70),
                    at(.19,angle+delta+.16,.76),at(.19,angle+.16,.76)],
                   [at(1.145,angle,.727),at(1.145,angle+delta,.727),
                    at(.19,angle+delta+.16,.78),at(.19,angle+.16,.78)]],
                  '824D3C' if i%2 else '9B6246',smooth=False)


def cave_expression(asset,form):
    for p in asset.parts:
        if p.name not in ('Head','FaceGlow'):
            continue
        if form=='Passive':
            for v in p.bm.verts:
                if v.co.z<5.49:
                    v.co.z=5.49+(v.co.z-5.49)*.17
            p.bm.normal_update()
        else:
            for v in p.bm.verts:
                if v.co.z<5.49:
                    v.co.z=5.49+(v.co.z-5.49)*1.11
            if p.name=='FaceGlow':
                for face in p.bm.faces:
                    if face.calc_center_median().z>5.9:
                        face[p.layer]=p._cid('FF6245')
            p.bm.normal_update()
    if form=='Passive':
        pose_group(asset,'Head',offset=(0,0,-.55))


def build():
    collection.build()
    sources=list(kit.ASSETS.values())
    source_joints=copy.deepcopy(collection.JOINTS)
    kit.ASSETS.clear()
    for source in sources:
        FORMS[source.name]={}
        for form in ('Passive','Aggressive'):
            a=kit.asset(source.name+'_'+form)
            JOINTS[a.name]=copy.deepcopy(source_joints[source.name])
            for p in source.parts:
                if source.name.startswith('Deer_') and p.name=='Head':continue
                clone_part(p,a)
            if source.name.startswith('Deer_'):
                faces.deer_face(a,source.name.split('_')[1],expression=form)
                if form=='Aggressive':
                    pose_group(a,'Head',(9,0,0))
                    for side,group in ((-1,'ArmR'),(1,'ArmL')):
                        pose_group(a,group,(-15,-side*10,0))
            elif source.name.startswith('RingMaw'):
                if form=='Passive':
                    ring_iris(a)
                    pose_group(a,'Head',(-5,0,0))
                else:
                    pose_group(a,'Head',(8,0,0))
            else:
                cave_expression(a,form)
                if form=='Aggressive':
                    pose_group(a,'Head',(5,0,0))
                    for side,group in ((-1,'ArmR'),(1,'ArmL')):
                        pose_group(a,group,(-10,-side*6,0))
            FORMS[source.name][form]=a.name
