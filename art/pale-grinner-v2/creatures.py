"""Portrait mesh in a frontal landmark coordinate system. Closed skull and jaw surface."""
from pathlib import Path
from math import sin, cos, pi, sqrt, exp
import sys, importlib.util
import bpy
import numpy as np

ROOT=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('base_creatures',ROOT.parent/'horror-reference-set-v1/creatures.py')
base=importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)
import kit
RIGS,DETAILS=base.RIGS,base.DETAILS
IMPORTED={}
skin_weights=base.skin_weights

# Horizontal contours of the visible face, recorded against the cropped frame.
# Each entry holds height, left/right edge, centre-front depth, and rear depth.
profile=np.array([
 (36,80,102,-.25,.32),(39,62,113,-.36,.39),(46,51,124,-.42,.46),
 (58,45,130,-.47,.49),(76,42,134,-.47,.48),(96,39,135,-.43,.46),
 (111,42,134,-.47,.44),(127,48,128,-.47,.41),(145,53,125,-.46,.37),
 (164,56,125,-.47,.32),(176,56,129,-.42,.29),(190,59,129,-.39,.24),
 (207,66,126,-.42,.21),(219,74,117,-.44,.17),(228,85,103,-.34,.12),
 (230,89,98,-.26,.10)])
scale=.0102
def height(v):return 5.48+(230-v)*scale
def bump(x,y,cx,cy,rx,ry):return exp(-((x-cx)/rx)**2-((y-cy)/ry)**2)
def relief(x,v):
    d=0.
    for cx in (60,115):
        d+=.14*bump(x,v,cx,99,15,10)-.072*bump(x,v,cx,87,19,7)
        d-=.061*bump(x,v,cx,102,6,5)
        d-=.090*bump(x,v,cx,117,15,11)
        d+=.046*bump(x,v,cx,141,12,17)
    d-=.22*bump(x,v,89,124,8,24)+.26*bump(x,v,90,146,9,8)
    for cx in (81,100):d-=.09*bump(x,v,cx,149,5,5)
    mid=189-12*((x-90)/31)**2-.12*(x-90)
    d+=.215*exp(-((x-91)/30)**4-((v-mid)/11)**4)
    d-=.081*bump(x,v,90,211,23,7)
    return d
def portrait():
    image=bpy.data.images.load(str(ROOT/'reference.png'))
    image.colorspace_settings.name='Non-Color'
    pixels=np.array(image.pixels[:]).reshape(image.size[1],image.size[0],4)[::-1,:,:3]
    verts=[];cols=[];tri=[]
    sections=np.unique(np.r_[np.linspace(36,230,46),[93,95,99,101,103,144,148,169,171,175,178,181,187]])
    # Closely sample facial landmarks; broad facets suffice around the rear cranium.
    angles=np.r_[np.linspace(-pi/2,pi/2,50),np.linspace(pi/2,3*pi/2,11)[1:-1]]
    n=len(angles)
    for v in sections:
        left,right,front,back=[np.interp(v,profile[:,0],profile[:,j]) for j in range(1,5)]
        for angle in angles:
            x=(left+right)/2+(right-left)/2*sin(angle)
            facing=max(0,cos(angle))
            depth=(front*facing**.65+relief(x,v)*facing**.42) if facing>0 else back*(-cos(angle))
            verts.append(((x-90)*scale,depth,height(v)))
            px=int(round(x));py=int(round(v))
            rgb=pixels[py,px].astype(float)
            # Restrict sampling to the face. Hair at the outline transitions to modeled hair.
            color=(rgb*.93+.035)*min(1,facing*3)+np.array([.16,.13,.12])*(1-min(1,facing*3))
            cols.append(np.clip(color,0,1).tolist())
    for k in range(len(sections)-1):
        for j in range(n):
            a=k*n+j;b=k*n+(j+1)%n
            tri.extend([a,a+n,b,b,a+n,b+n])
    for row,reverse in [(0,True),(len(sections)-1,False)]:
        start=row*n;mid=len(verts);verts.append(tuple(np.mean(verts[start:start+n],axis=0)));cols.append(cols[start])
        for j in range(n):
            a=start+j;b=start+(j+1)%n
            tri.extend([mid,a,b] if reverse else [mid,b,a])
    return {'entry':{'part':'Portrait','attach':'Head','source_mesh':'Facial landmark reconstruction'},'verts':verts,'colors':cols,'tris':tri}
def oval(p,rows,color):
    p.loft([[(x+rx*cos(j*pi/12),y+ry*sin(j*pi/12),z) for j in range(24)] for z,x,y,rx,ry in rows],color,smooth=True)
def build():
    name='PaleGrinner'
    base.humanoid(name,1)
    a=kit.ASSETS[name]
    for p in list(a.parts):
        if p.name in ('Face','Hair','Neck','Body'):
            p.bm.free();a.parts.remove(p)
    # Swept-back dark hair extends behind the skull down to the collar.
    hair=base.part(a,'Hair','Head')
    oval(hair,[(4.93,.05,.27,.42,.16),(5.14,.02,.27,.64,.24),(5.63,.03,.25,.61,.30),(6.16,.01,.23,.58,.35),(6.65,0,.19,.62,.39),(7.12,-.02,.16,.60,.39),(7.39,-.04,.13,.48,.28),(7.52,-.05,.12,.21,.15),(7.54,-.03,.13,.05,.06)],'211C1B')
    for side in (-1,1):
        for i in range(3):
            x=side*(.47+i*.036)
            hair.tube([(x*.70,.17,7.34,.10),(x,-.015+i*.08,6.97,.09),(x*1.03,-.02+i*.09,6.49,.08),(x*.93,.015+i*.08,5.99,.09),(x*1.14,.045+i*.07,5.57,.098),(x*1.16,.06+i*.08,5.16+i*.06,.06),(x*1.08,.095+i*.09,5.0+i*.055,.014)],['27201D','211B19','302722'][i],seg=7,sub=2,smooth=True)
    neck=base.part(a,'Neck')
    oval(neck,[(4.76,.02,-.13,.20,.19),(4.99,.01,-.12,.30,.22),(5.29,.01,-.08,.28,.24),(5.59,.02,-.04,.24,.24),(5.73,.02,-.04,.21,.23)],'BFB8A9')
    shirt=base.part(a,'Body','Chest')
    rings=[]
    for z,rx,ry in [(2.51,.64,.38),(2.9,.61,.35),(3.42,.56,.33),(4.13,.72,.42),(4.60,.85,.45),(4.79,.98,.42),(4.95,.85,.36),(5.22,.38,.28)]:
        ring=[]
        for j in range(36):
            ang=j*2*pi/36;x=rx*cos(ang);front=max(0,-sin(ang))
            notch=.47*front**10 if z>5.2 else (.12*front**10 if z>4.90 else 0)
            ring.append((x,.04+ry*sin(ang)-(.31*front if z>5.2 else 0),z-notch))
        rings.append(ring)
    shirt.loft(rings,'19191C',smooth=True)
    # Use a visible cream throat taper covered by the black shirt at its deepest point.
    for side in (-1,1):
        shirt.tube([(side*.34,-.28,5.19,.056),(side*.23,-.40,5.03,.052),(side*.10,-.50,4.84,.033),(side*.025,-.55,4.76,.017)],'272426',seg=7,sub=2,smooth=True)
    # Shallow solid inserts clarify the tiny features that the reference resolves.
    features=base.part(a,'EyeAndDentalDetail','Head')
    def surface(x,v):
        left,right,front=[np.interp(v,profile[:,0],profile[:,j]) for j in range(1,4)]
        f=sqrt(max(0,1-((2*x-left-right)/(right-left))**2))
        return ((x-90)*scale,front*f**.65+relief(x,v)*f**.42,height(v))
    for cx,cy in [(61,98),(116,99)]:
        x,y,z=surface(cx,cy)
        features.sphere((x,y-.015,z),(.054,.028,.041),'CDC4A7',sub=2)
        features.sphere((x+.006,y-.041,z+.001),(.029,.012,.025),'221B18',sub=2)
        features.sphere((x+.017,y-.055,z+.015),(.013,.008,.011),'FCF6DF',sub=2)
    for cx,cy,w,h in [(68,174,.048,.034),(74,177,.057,.052),(82,177,.068,.055),(90,174,.048,.041),(98,173,.049,.027)]:
        x,y,z=surface(cx,cy)
        features.box((x,y-.016,z),(w,.039,h),'B7A480',rot=(0,cx%13-6,0),bevel=.008,seg=1)
    # An inset of neck skin meets the sloping shirt-front and closes the neckline.
    throat=base.part(a,'Throat','Neck')
    throat.loft([[(rx*cos(j*pi/9),cy+ry*sin(j*pi/9),z) for j in range(18)] for z,rx,cy,ry in [(4.77,.018,-.548,.02),(4.91,.118,-.485,.055),(5.10,.22,-.393,.09),(5.28,.255,-.27,.13),(5.48,.21,-.16,.14)]],'B6AE9E',smooth=True)
    IMPORTED[name]=[portrait()]
    DETAILS[name].update(focus=(0,-.1,6.17),close_scale=3.14,interpretation='Face and neckline matched to the supplied front view. Profile, rear and lower body interpreted.')
