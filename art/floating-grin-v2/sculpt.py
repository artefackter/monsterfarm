"""Parametric portrait and detached hands for Floating Grin; front is -Y."""
from math import asin, cos, sin, pi
from mathutils import Vector

CENTER=Vector((0,0,5.38))
RADII=(1.19,1.12,1.235)
MOUTH=.835
TAU=2*pi


def tint(a,b,t):
    return tuple((x+(y-x)*max(0,min(1,t)))/255 for x,y in zip(a,b))


class Geometry:
    def __init__(self):
        self.points=[];self.colors=[];self.joints=[];self.faces=[];self.smooth=[]

    def point(self,xyz,rgb,bone):
        index=len(self.points)
        self.points.append(Vector(xyz));self.colors.append(rgb);self.joints.append(bone)
        return index

    def face(self,ids,smooth=True):
        ids=tuple(dict.fromkeys(ids))
        if len(ids)>=3:
            self.faces.append(ids);self.smooth.append(smooth)

    def bridge(self,a,b,smooth=True):
        for i in range(len(a)):
            j=(i+1)%len(a)
            self.face((a[i],a[j],b[j],b[i]),smooth)


def shell(phi,lat,depth=0):
    return CENTER+Vector((RADII[0]*cos(lat)*sin(phi),
                          -RADII[1]*cos(lat)*cos(phi)+depth,
                          RADII[2]*sin(lat)))


def lips(phi):
    t=max(-1,min(1,phi/MOUTH))
    mid=-.726+.324*t*t-.045*t
    half=.224*max(0,1-t*t)**.85
    return mid+half,mid-half


def skin(phi,lat):
    t=max(0,sin(lat))**1.3
    rub=.10*(1+cos(2*phi-.4))*max(0,sin(lat))+.035*sin(3*phi+5*lat)
    return tint((12,10,16),(52,23,31),t+rub)


def portrait(g):
    # Longitude strips separate at the mouth and rejoin exactly at both corners.
    front=30
    angles=[-MOUTH+2*MOUTH*i/front for i in range(front+1)]
    angles += [MOUTH+(TAU-2*MOUTH)*i/36 for i in range(1,36)]
    bottom=g.point(CENTER-Vector((0,0,RADII[2])),skin(0,-pi/2),"Head")
    top=g.point(CENTER+Vector((0,0,RADII[2])),skin(0,pi/2),"Head")
    upper=[];lower=[];inside=[]
    for j,phi in enumerate(angles):
        hi,lo=lips(phi if j<=front else MOUTH)
        if j>front:
            # Smoothly close the latitude offset on the rear seam.
            hi=lo=lips(MOUTH)[0]+(lips(-MOUTH)[0]-lips(MOUTH)[0])*(j-front)/36
        def surface(lat):
            return g.point(shell(phi,lat),skin(phi,lat),"Head")
        down=[bottom]+[surface(-pi/2+(lo+pi/2)*k/9) for k in range(1,10)]
        split=0<j<front
        up=[surface(hi) if split else down[-1]]+[surface(hi+(pi/2-hi)*k/18) for k in range(1,18)]+[top]
        lower.append(down);upper.append(up)
        if j<=front:
            if not split:
                inside.append([down[-1]]*9)
            else:
                row=[up[0]]
                fade=(1-(phi/MOUTH)**2)**.75
                for u,depth,c in ((.055,.020,(76,46,51)),(.13,.041,(112,69,67)),
                        (.25,.085,(89,54,56)),(.50,.198,(42,23,31)),
                        (.73,.11,(90,53,57)),(.86,.047,(117,74,74)),(.945,.025,(76,44,51))):
                    scallop=.022*cos((phi/MOUTH+1)*pi*(17 if u<.5 else 16))*sin(pi*u)
                    lat=hi+(lo-hi)*(u+scallop)
                    rgb=tint((18,12,18),c,min(1,fade*1.6))
                    row.append(g.point(shell(phi,lat,depth*fade),rgb,"Head"))
                inside.append(row+[down[-1]])
    for columns in (upper,lower):
        for j,a in enumerate(columns):
            b=columns[(j+1)%len(columns)]
            for k in range(len(a)-1):g.face((a[k],b[k],b[k+1],a[k+1]))
    for j in range(front):
        for k in range(8):
            a,b=inside[j],inside[j+1]
            g.face((a[k+1],b[k+1],b[k],a[k]))
    for side in (-1,1): eye(g,side)
    for upper_row,count in ((True,16),(False,15)):
        for i in range(count):
            span=MOUTH*1.91
            angle=-span/2+(i+.5)*(span/count)+.012*sin(i*8.21)
            tooth(g,angle,i,upper_row,span/count)


def eye(g,side):
    # The slit follows the skin from a fine inner corner to an upswept outer corner.
    rows=[]
    for i in range(13):
        t=i/12
        x=side*((.38 if side<0 else .44)+.344*t)
        lat=(.15 if side<0 else .07)+.154*t+.044*t*t+.008*sin(2*pi*t)
        thick=(.034 if side<0 else .027)*sin(pi*t)**.80 if i not in (0,12) else .001
        phi=asin(x/cos(lat))
        row=[]
        for v in (-1,0,1):
            col=tint((170,143,151),(254,243,222),(.65+.28*sin(pi*t))*(1-.24*abs(v)))
            row.append(g.point(shell(phi,lat+v*thick,-.005-.014*(1-abs(v))*sin(pi*t)),col,"Head"))
        rows.append(row)
    for a,b in zip(rows,rows[1:]):
        for k in (0,1):
            f=(a[k],b[k],b[k+1],a[k+1])
            g.face(f if side>0 else f[::-1])


def tooth(g,phi,index,upper,spacing):
    hi,lo=lips(phi)
    root=hi+(lo-hi)*(.11 if upper else .89)
    direction=-1 if upper else 1
    length=(hi-lo)*((.41 if upper else .29)+.081*sin(3.2+index*2.71))
    lean=.027*sin(index*4.21+(.4 if upper else 2.3))-.012*phi
    rings=[]
    for u,w,d in ((0,.78,.014),(.22,.98,.020),(.62,.86,.022),(.90,.67,.015),(1,.35,.007)):
        ring=[]
        for k in range(8):
            a=TAU*k/8
            angle=phi+lean*u+cos(a)*spacing*.44*w
            lat=root+direction*u*length
            rgb=tint((99,65,69),(228,205,190),.18+.68*sin(u*2.1)+.09*sin(index*3.7)+.07*(-sin(a)))
            ring.append(g.point(shell(angle,lat,.077-.035*sin(u*1.9)+sin(a)*d),rgb,"Head"))
        if rings:g.bridge(rings[-1],ring)
        rings.append(ring)
    g.face(rings[0][::-1]);g.face(rings[-1])


def hand(g,side,bones):
    left=side=="L"
    name="Hand"+side
    wrist=Vector((-2.68,-.05,.38) if left else (1.42,.04,2.41))
    along=Vector((.715,-.12,.69) if left else (.49,-.10,.88)).normalized()
    width=Vector((.26,.91,-.14) if left else (.79,.42,-.39))
    width=(width-along*width.dot(along)).normalized()
    depth=along.cross(width).normalized()
    if depth.y>0: depth=-depth
    def place(u,v,w):
        breadth=1.13 if left else 1.
        reach=1.70 if left else 1.13
        return wrist+breadth*(u*width+v*depth)+reach*w*along
    def octagon(x,y):
        return [(-x*.70,-y),(x*.70,-y),(x,-y*.66),(x,y*.66),
                (x*.70,y),(-x*.70,y),(-x,y*.66),(-x,-y*.66)]
    bones[name]=(wrist,place(0,0,.91),"Root")
    last=None
    for w,rx,ry,x in ((0,.200,.108,.015),(.08,.240,.145,.02),
                       (.30,.325,.164,.01),(.70,.390,.160,0),(.92,.362,.132,0)):
        ring=[g.point(place(u+x,v,w-.065*(abs(u)/rx)**2),
                      tint((16,17,24),(34,34,46),.45+.25*v/ry+.18*w),name)
              for u,v in octagon(rx,ry)]
        if last:g.bridge(last,ring,False)
        else:g.face(ring[::-1],False)
        last=ring
    g.face(last,False)
    # Fingers have softened block edges; one index extends past the folded digits.
    for i in range(5):
        if i==0:
            start=Vector((-.30,.00,.39))
            offsets=[(0,0,0),(-.17,.03,.14),(-.28,.095,.35),(-.30,.15,.52)]
            radius=.125
        else:
            start=Vector((-.266+(i-1)*.179,0,.79+(.02 if i==2 else 0)))
            length=((.90,.71,.59,.48) if left else (.78,.86,.74,.59))[i-1]
            curl=((.045,.26,.32,.36) if left else (.18,.23,.27,.31))[i-1]
            offsets=[(0,0,0),((i-2.5)*.014,.006,length*.41),
                     ((i-2.5)*.025,curl*.30,length*.75),
                     ((i-2.5)*.031,curl,length)]
            radius=(.093,.096,.089,.076)[i-1]
        bn=name+"Finger"+str(i)
        centers=[start+Vector(q) for q in offsets]
        bones[bn]=(place(*centers[0]),place(*centers[-1]),name)
        # Ringed cross-sections form one continuous volume through both knuckles.
        samples=[(centers[0],1),(centers[0].lerp(centers[1],.75),1.02),(centers[1],.97),
                 (centers[1].lerp(centers[2],.77),.91),(centers[2],.93),
                 (centers[2].lerp(centers[3],.82),.79),(centers[3],.64)]
        last=None
        for j,(point,scale) in enumerate(samples):
            tangent=(samples[min(len(samples)-1,j+1)][0]-samples[max(0,j-1)][0]).normalized()
            ax=Vector((1,0,0));ax=(ax-tangent*tangent.dot(ax)).normalized()
            ay=tangent.cross(ax)
            ring=[g.point(place(*(point+u*ax+v*ay)),tint((17,17,25),(38,37,48),.38+.22*v/radius+.14*j/6),bn)
                  for u,v in octagon(radius*scale,radius*scale*.92)]
            if last:g.bridge(last,ring,False)
            else:g.face(ring[::-1],False)
            last=ring
        g.face(last,False)
    return place,width,depth,along
