"""A contracted, living RingMaw muzzle replaces the flat closed mouth cover."""
import math
from mathutils import Matrix,Vector
import assets_monster_prototypes as base
import assets_monster_forms_v3 as previous

JOINTS=previous.JOINTS
FORMS=previous.FORMS
CHECKS=previous.CHECKS


def ring_head(asset,form):
    center=Vector((.13,-1.98,2.78))
    pivot=(.10,-1.38,2.61)
    if form=='Aggressive':
        base.ring_head(asset,center,pivot)
        return
    head=base.part(asset,'Head',pivot,ao=.29,ao_dist=.35)
    glow=base.part(asset,'MawGlow',attach='Head',material='Neon',ao=0,grad=0,cast=False)
    tilt=Matrix.Rotation(math.radians(-9),3,'Y')@Matrix.Rotation(math.radians(6),3,'Z')
    # The entire muzzle contracts into thick, folded lips. No plate is laid over an open cavity.
    sections=[(-.65,.21,.27,.00),(-.42,.49,.60,.012),(-.15,.67,.85,.026),
              (.10,.71,.91,.041),(.33,.64,.83,.052),(.51,.52,.66,.051),
              (.65,.45,.43,.038),(.74,.415,.22,.020),(.82,.39,.065,.006),
              (.895,.37,.006,.0)]
    rings=[]
    for depth,rx,rz,fold in sections:
        ring=[]
        for j in range(48):
            angle=j*math.tau/48
            wobble=1+.042*math.sin(5*angle+.4)+.020*math.cos(7*angle)
            crease=fold*math.cos(4*angle+.35)
            bulge=.055*math.sin(angle)**4 if depth>.1 else 0
            local=Vector((rx*math.cos(angle)*wobble,
                          -depth-crease-bulge,rz*math.sin(angle)*wobble))
            ring.append(center+tilt@local)
        rings.append(ring)
    colors=['342B35','49333A','51363E','54373D','58393F',
            '5C393F','5D373E','58333C','281E27']
    head.loft(rings,lambda i:colors[i],smooth=True,cap_start=True,cap_end=True)
    # Hidden vestigial throat light retains the authored attachment without a visible aperture.
    glow.sphere(center+Vector((0,.10,0)),(.012,.012,.014),'6D443D',sub=1,smooth=False)
    for p in asset.parts:
        if p.name!='Headwear':continue
        for v in p.bm.verts:
            if '_Assassin_' in asset.name:
                local=v.co-center
                local.x*=.82;local.z*=.77
                v.co=center+local
            else:
                v.co.z-=.30
        p.bm.normal_update()


def build(cave_head_builder=None):
    previous.build(ring_head_builder=ring_head,cave_head_builder=cave_head_builder)
    for name,pair in FORMS.items():
        if name.startswith('RingMaw'):
            CHECKS[pair['Passive']].update({'closedMouthConstruction':'Contracted volumetric lips with a sealed horizontal seam.',
                                             'flatCoverPlate':False})
