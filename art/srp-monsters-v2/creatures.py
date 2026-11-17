"""Three standalone SRP studies and one existing-model adaptation in the style of the approved Dredge.

New geometry; Z up, front -Y. Original silhouettes take priority over generic
monster embellishments. The owner explicitly requested adapting the existing Parasite instead of creating a new Crux.
"""
import math
import json
import sys
from pathlib import Path
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).resolve().parent/'tools'))
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'blender'))
import kit

RIGS={};DETAILS={};IMPORTED={}
RED='78313B';FLESH='A64E50';MUSCLE='8E3C41';DARK='342A31'
BLACK='15171C';BONE='D6BC94';PALE='E3CDA9';BROWN='574048'

def part(a,name,attach=None):
    return a.part(name,attach=attach or name,ao=.31,ao_dist=.36,grad=.06)

def box(p,c,s,col,**kw):
    return p.box(c,s,col,bevel=kw.pop('bevel',.025),seg=1,smooth=False,**kw)

def bone(r,name,start,end,parent):r[name]=(tuple(start),tuple(end),parent)

def beam(p,a,b,w,d,col,bevel=.08):
    a,b=Vector(a),Vector(b)
    e=(b-a).to_track_quat('Z','Y').to_euler()
    box(p,(a+b)/2,(w,d,(b-a).length),col,
        rot=tuple(math.degrees(x) for x in e),bevel=min(w,d)*bevel)

def segment(p,a,b,ra,rb,col,n=8):
    a,b=Vector(a),Vector(b);q=(b-a).to_track_quat('Z','Y')
    rings=[]
    for t,r in ((0,ra),(.14,ra*1.02),(.86,rb*1.02),(1,rb)):
        c=a.lerp(b,t)
        rings.append([c+q@Vector((math.cos(j*math.tau/n)*r,math.sin(j*math.tau/n)*r*.84,0)) for j in range(n)])
    p.loft(rings,col,smooth=False)

def blade(p,points,col,r,n=5):
    p.tube([(*c,max(.012,r*(1-i/(len(points)-1))**.65)) for i,c in enumerate(points)],
           col,seg=n,sub=1,smooth=False)

def poly(p,outline,y,depth,col):
    p.prism(outline,depth,col,c=(0,y,0),bevel=.015,smooth=False)

def start(name):
    a=kit.asset(name);r={};RIGS[name]=r
    bone(r,'Root',(0,0,0),(0,0,.5),None)
    return a,r

def finish(a,r,reference,focus,scale,description):
    minimum=min(v.co.z for pr in a.parts for v in pr.bm.verts)
    size={'Crux':1.5,'PrimitiveSummoner':1.20,'AdaptedViscera':1.20}.get(a.name,1.0)
    for pr in a.parts:
        for v in pr.bm.verts:
            v.co.z-=minimum;v.co*=size
    for bn,(aa,bb,parent) in list(r.items()):
        if bn=='Root':continue
        r[bn]=((aa[0]*size,aa[1]*size,(aa[2]-minimum)*size),
               (bb[0]*size,bb[1]*size,(bb[2]-minimum)*size),parent)
    DETAILS[a.name]={'reference':reference,
                     'focus':(focus[0]*size,focus[1]*size,(focus[2]-minimum)*size),
                     'close_scale':scale*size,'interpretation':description}

def adventurer():
    a,r=start('AssimilatedAdventurer')
    bone(r,'Pelvis',(0,0,2.0),(0,0,2.65),'Root')
    bone(r,'Body',(0,0,2.58),(0,0,4.32),'Pelvis')
    bone(r,'Neck',(0,0,4.30),(0,0,4.65),'Body')
    bone(r,'Head',(0,0,4.64),(0,0,6.15),'Neck')
    p=part(a,'Pelvis');box(p,(0,.03,2.43),(1.10,.68,.58),'55535A',bevel=.06)
    p=part(a,'Body');box(p,(0,.27,3.50),(1.40,.42,1.95),'625B59',bevel=.055,taper=1.12)
    # Open torso: two splayed flaps with inward pointing teeth; no solid
    # plate or painted oval across the opening.
    box(p,(0,-.005,3.50),(.56,.22,1.52),'42252E',bevel=.08)
    segment(p,(0,-.19,2.77),(0,-.19,4.31),.13,.17,'B78479',n=6)
    for j in range(5):box(p,(0,-.34,2.93+j*.26),(.27,.12,.16),'D0AB96',bevel=.025)
    for s,side in ((-1,'R'),(1,'L')):
        bn='ChestFlap'+side
        bone(r,bn,(s*.66,.04,4.28),(s*.87,-.43,2.76),'Body')
        p=part(a,bn)
        poly(p,[(s*.22,2.74),(s*.73,2.68),(s*1.03,4.15),(s*.68,4.43),
                (s*.42,4.12)],-.31,.36,'70605A')
        poly(p,[(s*.28,2.86),(s*.56,2.80),(s*.87,4.14),(s*.66,4.29),
                (s*.46,4.03)],-.51,.11,RED)
        for j in range(7):
            z=2.98+j*.184;x=s*(.40+(z-2.98)*.17)
            blade(p,[(x,-.59,z+.10),(x-s*.18,-.65,z-.02)],PALE,.070,n=4)
        # An exposed shoulder branch is slim and grows backward.
        bn='Tendril'+side;root=(s*.68,.24,4.19);tip=(s*1.18,.63,4.94)
        bone(r,bn,root,tip,'Body');p=part(a,bn)
        blade(p,[root,(s*1.01,.38,4.40),tip],BLACK,.085)
        shoulder=(s*.94,.02,4.19);elbow=(s*1.36,-.11,3.37);wrist=(s*1.37,-.43,2.69)
        for bn,aa,bb,w,d,col,parent in [
            ('Arm'+side,shoulder,elbow,.49,.52,'6C605B','Body'),
            ('Forearm'+side,elbow,wrist,.45,.48,'685A55','Arm'+side)]:
            bone(r,bn,aa,bb,parent);p=part(a,bn);beam(p,aa,bb,w,d,col)
            mid=Vector(aa).lerp(Vector(bb),.57)
            box(p,mid+Vector((0,-d*.49,0)),(w*.50,.038,.13),'C8B7A3',rot=(0,s*17,0),bevel=.01)
        bn='Hand'+side;bone(r,bn,wrist,(s*1.37,-.48,2.37),'Forearm'+side)
        p=part(a,bn);box(p,(s*1.37,-.47,2.48),(.45,.46,.44),'63544E',bevel=.065)
        hip=(s*.32,.025,2.35);knee=(s*.35,-.015,1.30);ankle=(s*.38,.03,.30)
        for bn,aa,bb,w,d,col,parent in [
            ('Leg'+side,hip,knee,.54,.62,'74767C','Pelvis'),
            ('Shin'+side,knee,ankle,.52,.59,'62656D','Leg'+side)]:
            bone(r,bn,aa,bb,parent);p=part(a,bn);beam(p,aa,bb,w,d,col)
            box(p,(aa[0]+s*.10,-.322,(aa[2]+bb[2])*.5),(.25,.035,.25),'383A42',bevel=.01)
        bn='Foot'+side;bone(r,bn,ankle,(s*.38,-.47,.15),'Shin'+side)
        p=part(a,bn);box(p,(s*.38,-.18,.18),(.58,.99,.34),'44474E',bevel=.06)
    p=part(a,'Neck');segment(p,(0,0,4.30),(0,0,4.83),.22,.22,'AE8170')
    p=part(a,'Head')
    # Source #1 wears a tall grey helmet over a neutral human face.
    box(p,(0,.02,5.27),(1.10,.91,1.23),'79736C',bevel=.075)
    box(p,(0,.08,5.90),(1.25,1.02,.66),'53545B',bevel=.07)
    box(p,(0,-.425,5.68),(1.18,.09,.30),'44464D',bevel=.025)
    for s in (-1,1):
        box(p,(s*.25,-.464,5.25),(.22,.04,.105),BLACK,bevel=.008)
        box(p,(s*.255,-.49,5.24),(.05,.022,.054),'281E24',bevel=.004)
    box(p,(0,-.476,4.94),(.24,.04,.039),'342A2D',bevel=.006)
    box(p,(.36,-.475,5.04),(.13,.04,.025),'594544',bevel=.004)
    finish(a,r,1,(0,-.20,4.13),4.16,
           'Assimilated Adventurer from reference 1: helmeted humanoid, splayed split chest with internal teeth, two arms and two walking legs. Peelflap is the displayed individual name.')

def summoner():
    a,r=start('PrimitiveSummoner')
    bone(r,'Body',(0,.10,2.15),(0,.10,3.65),'Root')
    bone(r,'UpperJaw',(0,.60,3.17),(0,-.75,4.05),'Body')
    bone(r,'LowerJaw',(0,.54,2.20),(0,-.94,1.36),'Body')
    p=part(a,'Body')
    box(p,(0,.52,2.75),(1.93,.94,2.04),'6C433F',bevel=.10)
    box(p,(0,-.02,2.72),(1.54,.15,1.58),'3C2029',bevel=.08)
    # Broad cubic upper flesh jaw. The throat is behind an actual opening.
    p=part(a,'UpperJaw')
    box(p,(0,-.29,3.72),(2.16,1.83,.91),'C6A28B',bevel=.075,taper=.95)
    box(p,(0,-.36,3.23),(2.12,1.83,.16),MUSCLE,bevel=.035)
    for x,z,w in [(-.72,3.90,.13),(-.29,4.13,.16),(.25,3.89,.14),(.78,3.71,.16)]:
        box(p,(x,-1.218,z),(w,.025,.31),RED,bevel=.005)
    for i in range(7):
        x=(i-3)*.275
        blade(p,[(x,-1.05,3.23),(x*.96,-1.08,2.73+(i%2)*.07)],PALE,.093,n=4)
    # Small teeth run around the side lips too, so the mouth has depth.
    for s in (-1,1):
        for j in range(3):
            y=-.65+j*.38
            blade(p,[(s*.95,y,3.23),(s*.88,y,2.86)],BONE,.075,n=4)
    p=part(a,'LowerJaw')
    box(p,(0,-.30,1.60),(2.03,1.80,.56),'A57D6B',bevel=.07)
    box(p,(0,-.34,1.92),(1.84,1.78,.14),FLESH,bevel=.025)
    # The source's lower jaw has two long hanging flanges.
    for s in (-1,1):
        box(p,(s*.82,-.88,1.30),(.38,.60,.78),'B49580',bevel=.045)
        box(p,(s*.58,-1.213,1.49),(.12,.022,.47),RED,bevel=.005)
        beam(p,(s*.84,.42,2.40),(s*.84,-.41,1.75),.29,.35,MUSCLE)
    for i in range(6):
        x=(i-2.5)*.29
        blade(p,[(x,-.97,1.96),(x*.98,-1.01,2.43+(i%2)*.08)],PALE,.087,n=4)
    p=part(a,'Throat','Body')
    for j in range(5):
        beam(p,(-.62,.0,2.03+j*.22),(.62,.0,2.03+j*.22),.12,.15,RED)
    # Exactly four long, raised, angular limbs; no circular spider abdomen.
    for s,side in ((-1,'R'),(1,'L')):
        for j,y in enumerate((-.52,.60)):
            suffix=side+str(j+1)
            root=(s*.88,y,3.36)
            knee=(s*(2.45+j*.24),y+(.28 if j else -.24),5.69-j*.28)
            ankle=(s*(3.12+j*.31),y+(.66 if j else -.64),1.00)
            toe=(s*(3.55+j*.35),y+(.83 if j else -.85),.12)
            for bn,aa,bb,w,d,col,parent in [
                ('Leg'+suffix,root,knee,.45,.55,'786353','Body'),
                ('Shin'+suffix,knee,ankle,.48,.60,'3F3332','Leg'+suffix),
                ('Foot'+suffix,ankle,toe,.39,.56,'28272C','Shin'+suffix)]:
                bone(r,bn,aa,bb,parent);p=part(a,bn);beam(p,aa,bb,w,d,col)
                if bn.startswith('Leg'):
                    aa2=Vector(aa).lerp(Vector(bb),.14);bb2=Vector(aa).lerp(Vector(bb),.90)
                    beam(p,aa2+Vector((0,-.28,0)),bb2+Vector((0,-.28,0)),.11,.025,'9B7B64')
                if bn.startswith('Shin'):
                    beam(p,Vector(aa).lerp(Vector(bb),.03),Vector(aa).lerp(Vector(bb),.30),.51,.63,'56403B')
    finish(a,r,3,(0,-.25,2.90),4.36,
           'Primitive Summoner: two large separate rectangular flesh jaws and four high angular support legs. Upper and lower jaws are independently rigged; no spherical spider abdomen.')

def viscera():
    a,r=start('AdaptedViscera')
    bone(r,'Body',(0,.33,2.61),(0,.40,5.06),'Root')
    bone(r,'Shell',(0,.54,4.56),(0,.64,6.62),'Body')
    bone(r,'Mouth',(0,-.23,3.32),(0,-.45,5.44),'Body')
    p=part(a,'Shell')
    # Thick shell curves away behind the open vertical face. The nested XZ
    # rings form actual depth; no solid disk occupies the opening.
    n=16;cz=4.60
    def ring(y,rx,rz):
        return [(rx*math.cos(j*math.tau/n),y,cz+rz*math.sin(j*math.tau/n)) for j in range(n)]
    p.loft([ring(-.60,1.40,1.94),ring(.28,1.57,2.08),ring(1.10,1.22,1.73),
            ring(1.63,.55,1.05)],RED,cap_start=False,smooth=False)
    # Pale upper mantle over the red shell: large intact patches, not noise.
    angles=[j*math.pi/10 for j in range(11)]
    rings=[]
    for y,rx,rz in [(-.61,1.415,1.96),(.30,1.59,2.10),(1.13,1.24,1.75)]:
        rings.append([(rx*math.cos(t),y,cz+rz*math.sin(t)) for t in angles])
    p.loft(rings,'D0BDB0',cap_start=False,cap_end=False,wrap=False,smooth=False)
    for s in (-1,1):
        for j in range(3):
            z=3.39+j*.65
            box(p,(s*1.45,.35,z),(.15,1.14,.23),'A67871',rot=(0,s*10,0),bevel=.025)
    # Irregular red interruptions in the upper shell, seen in reference 5.
    for s in (-1,1):
        poly(p,[(s*.24,6.59),(s*.60,6.46),(s*.84,6.24),(s*.66,6.12),
                (s*.49,6.40),(s*.27,6.43)],-.625,.07,RED)
    p=part(a,'Mouth')
    p.loft([ring(-.61,1.40,1.94),ring(-.89,1.16,1.65),
            ring(-.12,.77,1.20),ring(.31,.66,1.06)],
           lambda i:[DARK,'302E32','233333'][min(i,2)],cap_start=False,smooth=False)
    # Blue-grey folds recede into the throat. Small isolated pale barbs sit on
    # the rim, while the long tooth rows belong to the arms.
    for j in range(6):
        x=(j-2.5)*.19
        p.tube([(x,.18,3.54,.09),(x,-.01,4.18,.12),(x,.12,5.31,.08)],
               '4A6060' if j%2 else '3A4B50',seg=5,sub=1,smooth=False)
    for s in (-1,1):
        for j in range(4):
            z=3.53+j*.50;x=s*(1.09 if j in (1,2) else .90)
            blade(p,[(x,-.88,z),(x-s*.16,-1.0,z-.20)],BONE,.071,n=4)
    # Eight arms surround the face, project forward in 3D, and fan in height.
    # Each arm has three independently rigged sections and ventral tooth bars.
    tips=[(3.15,-5.10,5.70),(1.60,-3.60,7.65),(-.15,-1.90,8.60),
          (-3.10,-4.50,5.90),(-3.18,-5.20,3.30),(-1.75,-4.10,1.85),
          (1.18,-3.50,1.62),(3.35,-4.90,3.35)]
    for j in range(8):
        theta=math.tau*j/8+math.pi/8;cs=math.cos(theta);sn=math.sin(theta)
        roots=(cs*1.07,-.75,cz+sn*1.48)
        tip=Vector(tips[j]);rootvec=Vector(roots)
        points=[roots,rootvec.lerp(tip,.28)+Vector((cs*.17,.12,sn*.12)),
                rootvec.lerp(tip,.68)+Vector((cs*.14,.0,-sn*.10)),tip]
        previous='Mouth'
        for k,(aa,bb) in enumerate(zip(points,points[1:])):
            bn='Tentacle'+str(j+1).zfill(2)+'_'+str(k+1)
            bone(r,bn,aa,bb,previous);p=part(a,bn)
            width=(.32,.26,.15)[k];depth=(.33,.26,.17)[k]
            beam(p,aa,bb,width,depth,RED if k<2 else DARK,bevel=.045)
            v1,v2=Vector(aa),Vector(bb)
            # Dark red bands wrap the limbs, matching the source's segmentation.
            for t in (.20,.61):
                beam(p,v1.lerp(v2,t),v1.lerp(v2,min(.95,t+.10)),width*1.045,depth*1.045,
                     '4C2931',bevel=.04)
            if k==2:
                beam(p,v1.lerp(v2,.70),v2,width*1.06,depth*1.06,PALE,bevel=.04)
            if k<2:
                inward=Vector((-cs*.28,-.04,-sn*.72)).normalized()
                for t in (.18,.42,.66,.87):
                    root=v1.lerp(v2,t)+inward*(width*.39)
                    end=root+inward*(.44 if k==0 else .53)
                    beam(p,root,end,.09,.10,PALE,bevel=.04)
            previous=bn
    # Six segmented support legs with forked black feet, arranged around the
    # underside rather than aligned on one front plane.
    for s,side in ((-1,'R'),(1,'L')):
        for j,y in enumerate((-.38,.46,1.17)):
            suffix=side+str(j+1)
            root=(s*.90,y,3.05);knee=(s*(1.64+j*.11),y+.10,2.35)
            ankle=(s*(1.79+j*.12),y-.01, .43);toe=(s*(2.27+j*.16),y-.45,.13)
            for bn,aa,bb,w,d,col,parent in [
                ('Leg'+suffix,root,knee,.37,.44,RED,'Body'),
                ('Shin'+suffix,knee,ankle,.23,.31,'5A303A','Leg'+suffix),
                ('Foot'+suffix,ankle,toe,.23,.35,BLACK,'Shin'+suffix)]:
                bone(r,bn,aa,bb,parent);p=part(a,bn);beam(p,aa,bb,w,d,col)
                if bn.startswith('Leg'):
                    beam(p,Vector(aa).lerp(Vector(bb),.53),bb,.42,.49,'66767A')
                if bn.startswith('Shin'):
                    for t in (.23,.55,.83):
                        beam(p,Vector(aa).lerp(Vector(bb),t),Vector(aa).lerp(Vector(bb),t+.07),.25,.33,'302A32')
                if bn.startswith('Foot'):
                    blade(p,[Vector(aa).lerp(Vector(bb),.62),
                             (toe[0]-s*.12,toe[1]+.30,.06),
                             (toe[0]+s*.13,toe[1]+.34,.21)],BLACK,.12)
    finish(a,r,5,(0,-.70,4.63),5.80,
           'Adapted Viscera: thick pale-over-red nautilus-like shell, recessed blue-grey mouth, eight long forward-projecting segmented arms with ventral teeth, six separate support legs. Each arm has three bones.')

def parasite():
    """Adapt actual project mesh vertices, retaining original topology and pivots."""
    folder=Path(__file__).resolve().parents[1]/'export/collection-v2/road-v3/root-archetypes-v1'
    if not folder.exists():folder=Path(__file__).resolve().parent/'source/parasite'
    source_name='Parasite_Root_Aggressive'
    entries=json.loads((folder/'_manifest.json').read_text())[source_name]
    joints=json.loads((folder/'_rig.json').read_text())[source_name]
    for adapted,name in ((False,'ParasiteExisting'),(True,'ParasiteAdapted')):
        a,r=start(name);IMPORTED[name]=[]
        bone(r,'Body',(0,.08,2.30),(0,.08,4.43),'Root')
        for bn,position in joints.items():
            # Inverse of kit.to_rbx; these are the actual model's source pivots.
            head=Vector((-position[0],position[2],position[1]))
            direction=Vector((0,0,.62)) if bn=='Head' or bn.startswith('Tendril') else Vector((0,0,-.62))
            bone(r,bn,head,head+direction,'Root' if bn.startswith('Leg') else 'Body')
        for entry in entries:
            data=json.loads((folder/(entry['mesh']+'.json')).read_text())
            off=entry['offset'];vv=data['v'];pn=entry['part']
            verts=[Vector((-vv[i]-off[0],vv[i+2]+off[2],vv[i+1]+off[1])) for i in range(0,len(vv),3)]
            colors=[]
            for color in data['c']:
                rgb=[(color>>shift&255)/255 for shift in (16,8,0)]
                # Keep the cavity, teeth and the existing red eyes intact.
                if adapted and pn!='EyesGlow' and rgb[0]>rgb[1]*1.25 and rgb[2]>rgb[1]*1.12:
                    lum=max(.25,min(1.30,rgb[0]/.47))
                    target=[min(1,c*lum) for c in kit._rgb(RED)]
                    rgb=[.65*rgb[i]+.35*target[i] for i in range(3)]
                colors.append(tuple(rgb))
            if adapted:
                if pn=='Body':
                    for v in verts:
                        t=max(0,min(1,(v.z-2.70)/1.4))
                        v.x*=1+.13*t
                        if v.y>.08:v.y+=.27*t
                elif pn.startswith('Arm'):
                    pivot=Vector(r[pn][0])
                    for v in verts:
                        delta=v-pivot
                        v.x=pivot.x+delta.x*1.12;v.y=pivot.y+delta.y*1.10
            IMPORTED[name].append({'entry':{'part':pn,'attach':entry['attach'],
                'source_mesh':entry['mesh'],'source_vertex_count':len(verts)},
                'verts':verts,'colors':colors,'tris':data['t']})
        if adapted:
            # Additional folds sit behind the existing head; original tendrils,
            # teeth, hands, feet and their topology remain present.
            p=part(a,'BackGrowth','Body')
            for c,s,rot,col in [((-.48,.84,4.91),(1.65,1.30,1.89),(-8,-19,-8),RED),
                                 ((.53,.91,4.97),(1.27,1.31,1.66),(7,19,8),MUSCLE),
                                 ((-1.01,.72,4.13),(1.01,1.01,1.59),(0,-29,9),FLESH),
                                 ((-.24,.75,5.78),(1.01,1.02,.65),(0,-13,0),RED)]:
                box(p,c,s,col,rot=rot,bevel=.11)
            for s in (-1,1):
                for j in range(3):
                    root=(s*(1.05-j*.17),.75,4.61-j*.42)
                    blade(p,[root,(root[0]+s*.27,.58,3.66-j*.38),
                             (root[0]+s*.15,.42,2.57-j*.29)],RED,.039)
                p=part(a,'ShoulderFold'+('L' if s>0 else 'R'),'ArmL' if s>0 else 'ArmR')
                # Attach these additions to the original whole-arm pivot.
                beam(p,(s*1.34,.28,4.10),(s*1.91,.19,3.65),.29,.26,FLESH)
                poly(p,[(s*1.12,4.29),(s*1.68,4.11),(s*1.89,3.73),
                        (s*1.37,3.88)],.26,.18,RED)
                p=next(pr for pr in a.parts if pr.name=='BackGrowth')
        DETAILS[name]={'reference':4,'focus':(0,-.13,4.70),'close_scale':4.55,
            'interpretation':('Adaptation of the actual existing Parasite_Root_Aggressive. '
                'Original head, eyes, hands, legs, tendrils, triangle topology and source pivots retained; '
                'torso and arms subtly broadened, red folds added behind the head.' if adapted else
                'Unmodified project Parasite_Root_Aggressive geometry and vertex colors for before/after comparison.'),
            'source_asset':source_name,'review_baseline_only':not adapted}

def build():
    adventurer();summoner();parasite();viscera()

def skin_weights(part_name,position,default_bone):
    return {default_bone:1.0}
