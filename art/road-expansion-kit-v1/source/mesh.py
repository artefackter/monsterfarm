"""Flat-shaded, palette-textured GLBs. Authoring in studs: x along road, y across, z up."""
import json
import math
import struct
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSETS = {}
LAYOUTS = {}

def add(a,b): return tuple(x+y for x,y in zip(a,b))
def sub(a,b): return tuple(x-y for x,y in zip(a,b))
def mul(a,k): return tuple(x*k for x in a)
def cross(a,b): return (a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0])
def unit(a): return mul(a,1/math.sqrt(sum(x*x for x in a)))
def gltf(v): return (v[0],v[2],-v[1])
def color(hexcode):
    def linear(n):
        s=n/255
        return s/12.92 if s<=.04045 else ((s+.055)/1.055)**2.4
    return tuple(round(linear(int(hexcode[i:i+2],16))*65535) for i in (0,2,4))+(65535,)

class Asset:
    def __init__(self, biome, name, title, group):
        self.name=name
        self.biome=biome
        self.title=title
        self.group=group
        self.faces=defaultdict(list)
        assert name not in ASSETS
        ASSETS[name]=self

    def poly(self, vertices, faces, tint, light=False):
        for face in faces:
            self.faces[tint if light else 'Matte'].append(([vertices[i] for i in face],tint))

    def box(self, pos, size, tint, roll=0, tilt=0, light=False):
        x,y,z=pos
        ca,sa=math.cos(math.radians(roll)),math.sin(math.radians(roll))
        cb,sb=math.cos(math.radians(tilt)),math.sin(math.radians(tilt))
        pts=[]
        for iz in (-1,1):
            for ix,iy in [(-1,-1),(1,-1),(1,1),(-1,1)]:
                u,v,w=ix*size[0]/2,iy*size[1]/2,iz*size[2]/2
                u,w=u*cb+w*sb,-u*sb+w*cb
                pts.append((x+u*ca-v*sa,y+u*sa+v*ca,z+w))
        self.poly(pts,[(3,2,1,0),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],tint,light)

    def pipe(self, a,b,r,tint, r2=None,n=10,light=False):
        axis=unit(sub(b,a))
        side=unit(cross(axis,(0,0,1) if abs(axis[2])<.94 else (0,1,0)))
        other=cross(axis,side)
        pts=[]
        for pos,radius in [(a,r),(b,r if r2 is None else r2)]:
            for i in range(n):
                angle=math.tau*i/n
                pts.append(add(pos,mul(add(mul(side,math.cos(angle)),mul(other,math.sin(angle))),radius)))
        faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]
        faces.extend((i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n))
        self.poly(pts,faces,tint,light)

    def disc(self,x,y,bottom,r,h,tint,n=20,light=False):
        self.pipe((x,y,bottom),(x,y,bottom+h),r,tint,n=n,light=light)

    def band(self,x,y,z,r,width,h,tint,n=48,start=0,end=math.tau):
        for i in range(n):
            angles=[start+(end-start)*k/n for k in (i,i+1)]
            p=[(x+rr*math.cos(t),y+rr*math.sin(t),zz) for zz in (z,z+h) for t,rr in [(angles[0],r-width),(angles[0],r),(angles[1],r),(angles[1],r-width)]]
            faces=[(0,3,2,1),(4,5,6,7),(1,2,6,5),(3,0,4,7)]
            if end-start < math.tau-1e-8 and i==0: faces.append((0,1,5,4))
            if end-start < math.tau-1e-8 and i==n-1: faces.append((2,3,7,6))
            self.poly(p,faces,tint)

    def mesh_data(self):
        out=[]
        for group,faces in self.faces.items():
            vertices={};indices=[]
            for pts,tint in faces:
                normal=gltf(unit(cross(sub(pts[1],pts[0]),sub(pts[2],pts[0]))))
                ids=[]
                for corner,pt in enumerate(pts):
                    a=math.tau*corner/len(pts)
                    offset=(.002*math.cos(a),.002*math.sin(a))
                    key=(tuple(round(i,6) for i in gltf(pt)),tuple(round(i,6) for i in normal),color(tint),offset)
                    if key not in vertices:vertices[key]=len(vertices)
                    ids.append(vertices[key])
                for j in range(1,len(ids)-1):indices.extend((ids[0],ids[j],ids[j+1]))
            out.append((group,list(vertices),indices))
        return out

def write(path,placements,data,palette_png,palette_uv):
    blob=bytearray();views=[];acc=[];nodes=[];meshes=[];mats=[];material_ids={};mesh_ids={}
    def buf(vals,fmt,ct,kind,width,target,**kwargs):
        blob.extend(bytes(-len(blob)%4))
        raw=struct.pack('<'+str(len(vals))+fmt,*vals)
        views.append(dict(buffer=0,byteOffset=len(blob),byteLength=len(raw),target=target));blob.extend(raw)
        acc.append(dict(bufferView=len(views)-1,componentType=ct,count=len(vals)//width,type=kind,**kwargs))
        return len(acc)-1
    views.append(dict(buffer=0,byteOffset=0,byteLength=len(palette_png)))
    blob.extend(palette_png)
    for name,at,angle in placements:
        if name not in mesh_ids:
            prims=[]
            for group,verts,idx in data[name]:
                if group not in material_ids:
                    mat=dict(name=group,pbrMetallicRoughness=dict(baseColorTexture={"index":0},roughnessFactor=.88,metallicFactor=0))
                    if group!='Matte':mat['emissiveFactor']=[v/65535 for v in color(group)[:3]]
                    material_ids[group]=len(mats);mats.append(mat)
                pts,_,cols,offsets=zip(*verts)
                flat=lambda ar:[v for t in ar for v in t]
                pa=buf(flat(pts),'f',5126,'VEC3',3,34962,min=list(map(min,zip(*pts))),max=list(map(max,zip(*pts))))
                uvs=[round((center+delta)*65535) for col,offset in zip(cols,offsets)
                     for center,delta in zip(palette_uv[col],offset)]
                uv=buf(uvs,'H',5123,'VEC2',2,34962,normalized=True)
                # The maximum index value of each glTF component type is reserved.
                assert max(idx)<65535
                fmt,ct=('B',5121) if max(idx)<255 else ('H',5123)
                ix=buf(idx,fmt,ct,'SCALAR',1,34963)
                # All faces are flat. glTF derives their normals from winding.
                # mesh_data still splits creases for importers that average shared vertices.
                prims.append(dict(attributes={'POSITION':pa,'TEXCOORD_0':uv},indices=ix,material=material_ids[group]))
            mesh_ids[name]=len(meshes);meshes.append(dict(name=name,primitives=prims))
        t=math.radians(angle)/2
        nodes.append(dict(name=name,mesh=mesh_ids[name],translation=gltf(at),rotation=[0,math.sin(t),0,math.cos(t)],extras={'placement':ASSETS[name].group}))
    doc=dict(asset=dict(version='2.0',generator='Road Expansion Kit'),scene=0,scenes=[dict(nodes=list(range(len(nodes))))],nodes=nodes,meshes=meshes,materials=mats,buffers=[dict(byteLength=len(blob))],bufferViews=views,accessors=acc)
    doc.update(images=[dict(name='RoadPalette',bufferView=0,mimeType='image/png')],
               samplers=[dict(magFilter=9728,minFilter=9728,wrapS=33071,wrapT=33071)],
               textures=[dict(source=0,sampler=0,name='RoadPalette')])
    js=json.dumps(doc,separators=(',',':')).encode();js+=b' '*(-len(js)%4);blob.extend(bytes(-len(blob)%4))
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_bytes(struct.pack('<III',0x46546c67,2,28+len(js)+len(blob))+struct.pack('<II',len(js),0x4e4f534a)+js+struct.pack('<II',len(blob),0x004e4942)+blob)
