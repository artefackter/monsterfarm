"""Closed scalp and solid tapered locks. Coordinates share V2's head bind pose."""
from math import sin, cos, pi, exp
import numpy as np

def spline(points, t):
    position=t*(len(points)-1)
    i=min(int(position),len(points)-2)
    u=position-i
    a,b,c,d=points[[max(i-1,0),i,i+1,min(i+2,len(points)-1)]]
    return .5*((2*b)+(-a+c)*u+(2*a-5*b+4*c-d)*u*u+(-a+3*b-3*c+d)*u**3)

def hair_mesh():
    vertices,colors,indices=[],[],[]
    def add(point,color):
        vertices.append(list(point));colors.append(list(color))
        return len(vertices)-1
    def ring_faces(start,count):
        for j in range(count):
            a=start+j;b=start+(j+1)%count
            indices.extend([a,b,a+count,b,b+count,a+count])
    # A rear mass narrows into the nape rather than cutting off in a blunt bob.
    profile=np.array([
        [4.99,.05,.31,.14,.07],[5.16,.08,.32,.33,.13],
        [5.46,.08,.34,.45,.17],[5.83,.06,.31,.50,.22],
        [6.22,.03,.26,.49,.27],[6.65,0,.21,.56,.35],
        [7.02,-.025,.17,.55,.38],[7.28,-.04,.16,.50,.35],
        [7.41,-.038,.13,.39,.27],[7.49,-.05,.10,.27,.18],
        [7.53,-.065,.08,.13,.091]])
    count=28;levels=19
    for i in range(levels):
        z,x,y,rx,ry=spline(profile,i/(levels-1))
        for j in range(count):
            u=2*pi*j/count
            shade=.98+.08*cos(11*u+.8*sin(2*z))+.045*sin(7*u-z)
            add((x+rx*cos(u),y+ry*sin(u),z),np.array([.103,.089,.086])*shade)
        if i:ring_faces((i-1)*count,count)
    for i in (0,levels-1):
        cap=add(tuple(np.mean(vertices[i*count:(i+1)*count],axis=0)),(.108,.092,.086))
        for j in range(count):
            a=i*count+j;b=i*count+(j+1)%count
            indices.extend([cap,b,a] if i==0 else [cap,a,b])
    # Individually combed locks originate on the crown and taper past the cheek.
    # Interior and rear layers have different arcs from the visible temple locks.
    def lock(points,width,thickness,tone):
        path=np.array(points);start=len(vertices);segments=19;sides=7
        for i in range(segments+1):
            t=i/segments
            center=spline(path,t)
            tangent=spline(path,min(1,t+.002))-spline(path,max(0,t-.002))
            tangent/=np.linalg.norm(tangent)
            # Rotate the flattened lock gently around the side of the skull.
            axis=np.array([.18*(1-t),-1.,.04])
            across=np.cross(axis,tangent);across/=np.linalg.norm(across)
            normal=np.cross(tangent,across)
            taper=.018+(sin(pi*t)**.6)*(.62+.38*(1-t)) if i not in (0,segments) else .022
            for j in range(sides):
                a=2*pi*j/sides
                p=center+taper*(width*.86*cos(a)*across+thickness*.77*sin(a)*normal)
                shade=1+.07*cos(2*a+.6*t)+.08*sin(pi*t)
                add(p,np.array(tone)*shade)
            if i:ring_faces(start+(i-1)*sides,sides)
        for offset in (0,segments):
            k=start+offset*sides;cap=add(path[0 if offset==0 else -1],tone)
            for j in range(sides):
                a=k+j;b=k+(j+1)%sides
                indices.extend([cap,b,a] if offset==0 else [cap,a,b])
    char=(.10,.084,.081); walnut=(.124,.101,.093);lit=(.143,.114,.099)
    # Left side, tucked behind the temple with staggered, inward-turning ends.
    lock([(-.08,.03,7.52),(-.42,-.09,7.36),(-.57,-.12,6.95),(-.54,-.10,6.48),(-.49,-.04,6.1),(-.59,.03,5.78),(-.57,.13,5.48)],.16,.078,char)
    lock([(-.12,.12,7.50),(-.47,.08,7.30),(-.57,.01,6.80),(-.52,.10,6.27),(-.60,.17,5.89),(-.67,.13,5.47),(-.54,.03,5.11)],.19,.10,walnut)
    lock([(-.32,.26,7.36),(-.48,.35,7.04),(-.48,.39,6.56),(-.50,.34,6.11),(-.64,.27,5.72),(-.59,.29,5.29),(-.41,.18,5.03)],.17,.09,char)
    lock([(-.37,-.12,7.37),(-.52,-.17,7.09),(-.545,-.18,6.70),(-.53,-.15,6.43),(-.47,-.12,6.21)],.072,.042,lit)
    # Right side has a longer forward wave, a separated shorter curl, and finer ends.
    lock([(-.12,.01,7.52),(.23,-.11,7.46),(.49,-.11,7.21),(.56,-.09,6.86),(.50,-.08,6.46),(.53,-.14,6.12),(.66,-.10,5.81),(.63,-.17,5.45),(.48,-.23,5.13),(.52,-.17,4.98)],.145,.088,walnut)
    lock([(.20,.13,7.46),(.47,.12,7.21),(.56,.09,6.76),(.51,.10,6.36),(.65,.13,6.05),(.74,.09,5.71),(.67,-.01,5.43),(.56,-.08,5.32)],.16,.088,char)
    lock([(.25,.32,7.40),(.47,.39,7.12),(.53,.37,6.65),(.49,.36,6.29),(.59,.31,5.92),(.66,.29,5.59),(.59,.18,5.22),(.42,.11,4.91)],.20,.10,walnut)
    lock([(.43,-.12,7.20),(.53,-.13,6.90),(.50,-.16,6.56),(.49,-.18,6.25),(.58,-.19,5.99),(.67,-.16,5.87)],.062,.034,lit)
    # Isolated wisps leave a little air between the broad locks at the cheek and neck.
    lock([(-.50,-.09,6.92),(-.55,-.16,6.70),(-.59,-.16,6.45),(-.56,-.12,6.21),(-.52,-.09,6.13)],.029,.015,walnut)
    lock([(-.53,.13,6.16),(-.63,.10,5.94),(-.72,.05,5.70),(-.71,.015,5.49),(-.62,.035,5.33)],.037,.023,char)
    lock([(.56,-.04,6.21),(.62,-.13,6.04),(.72,-.12,5.91),(.76,-.08,5.73),(.72,-.07,5.61)],.034,.019,walnut)
    lock([(.64,-.06,5.76),(.63,-.18,5.52),(.55,-.24,5.29),(.45,-.26,5.07),(.43,-.19,4.93)],.032,.016,char)
    # Loose locks descend over the rear mass and break up the nape in profile.
    for x,drop in [(-.32,.12),(-.14,-.04),(.08,.21),(.30,.03)]:
        lock([(x*.3,.21,7.48),(x*.8,.40,7.30),(x,.51,6.96),(x+.045,.55,6.49),
              (x-.04,.51,6.06),(x+.04,.52,5.72),(x+.11,.48,5.39),(x+.06,.39,5.04+drop)],
             .15,.065,char if x<0 else walnut)
    return {'entry':{'part':'Hair','attach':'Head','source_mesh':'Swept tapered locks'},'verts':vertices,'colors':colors,'tris':indices}
