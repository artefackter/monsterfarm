"""Self-contained GLB export + structural validation. Python standard library only."""
from pathlib import Path
import json, struct, math, hashlib

ROOT=Path(__file__).resolve().parents[1]
catalog=json.loads((ROOT/'catalog.json').read_text())
ASSETS=catalog['assets']
BIOMES=['backrooms','blood_mine','village','city','parasitown']

def linear(v):return v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4
def hexlinear(h):return [linear(int(h[i:i+2],16)/255) for i in (0,2,4)]

def write_glb(path, layout):
    blob=bytearray();views=[];acc=[];nodes=[];roots=[];meshes=[]
    mats=[{'name':'BakedVertexColor','pbrMetallicRoughness':{'baseColorFactor':[1,1,1,1],'metallicFactor':0,'roughnessFactor':.88}}]
    def add(values,fmt,component,kind,count,target,**extras):
        blob.extend(b'\0'*(-len(blob)%4));buf=struct.pack('<'+str(len(values))+fmt,*values)
        views.append(dict(buffer=0,byteOffset=len(blob),byteLength=len(buf),target=target));blob.extend(buf)
        acc.append(dict(bufferView=len(views)-1,componentType=component,count=count,type=kind,**extras))
        return len(acc)-1
    for name,loc in layout.items():
        a=ASSETS[name];children=[]
        for p in a['parts']:
            geo=json.loads((ROOT/'geometry'/(p['mesh']+'.json')).read_text())
            v,n,c,t=geo['v'],geo['n'],geo['c'],geo['t'];num=len(v)//3
            normals=[]
            for j in range(0,len(n),3):
                length=math.sqrt(sum(q*q for q in n[j:j+3]));assert length>.9
                normals.extend(q/length for q in n[j:j+3])
            pa=add(v,'f',5126,'VEC3',num,34962,min=[min(v[i::3]) for i in range(3)],max=[max(v[i::3]) for i in range(3)])
            na=add(normals,'f',5126,'VEC3',num,34962)
            color=[round(linear((rgb>>shift&255)/255)*65535) for rgb in c for shift in [16,8,0]]
            ca=add(color,'H',5123,'VEC3',num,34962,normalized=True)
            ia=add(t,'H' if num<65536 else 'I',5123 if num<65536 else 5125,'SCALAR',len(t),34963)
            mi=0
            if 'emission_srgb' in p:
                mi=len(mats);mats.append(dict(name=p['mesh'],pbrMetallicRoughness=dict(baseColorFactor=[1,1,1,1],metallicFactor=0,roughnessFactor=.8),emissiveFactor=hexlinear(p['emission_srgb'])))
            meshes.append(dict(name=p['mesh'],primitives=[dict(attributes=dict(POSITION=pa,NORMAL=na,COLOR_0=ca),indices=ia,material=mi)]))
            children.append(len(nodes));nodes.append(dict(name=name+'__'+p['part'],mesh=len(meshes)-1,translation=p['offset'],extras=dict(asset=name,part=p['part'],roblox_material=p['material'],default_collision=False)))
        roots.append(len(nodes));nodes.append(dict(name=name,children=children,translation=loc,extras={k:a[k] for k in ['placement','pivot','front_axis','intended_studs_per_unit','note']}))
    doc=dict(asset=dict(version='2.0',generator='GrowAMonster local biome model review v1'),scene=0,scenes=[dict(name=path.stem,nodes=roots)],nodes=nodes,meshes=meshes,materials=mats,accessors=acc,bufferViews=views,buffers=[dict(byteLength=len(blob))])
    js=json.dumps(doc,separators=(',',':')).encode();js+=b' '*(-len(js)%4);blob.extend(b'\0'*(-len(blob)%4))
    raw=struct.pack('<III',0x46546c67,2,28+len(js)+len(blob))+struct.pack('<II',len(js),0x4E4F534A)+js+struct.pack('<II',len(blob),0x004E4942)+blob
    path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(raw)

LAYOUT={
 'backrooms': {'BR_WallPanel':[-35,0,0], 'BR_DoorPartition':[1,0,-1], 'BR_CornerPartition':[32,0,-1], 'BR_Pillar':[-20,0,-24], 'BR_Fluorescent':[12,0,-24]},
 'blood_mine': {'BM_EntranceOpen':[-58,0,0], 'BM_EntranceBoarded':[0,0,0], 'BM_RockWall':[58,0,0], 'BM_OreCluster':[-65,0,-29], 'BM_Minecart':[-42,0,-29], 'BM_RailBroken':[-17,0,-29], 'BM_TimberPile':[12,0,-29], 'BM_Torch':[38,0,-29], 'SH_Rubble':[64,0,-29]},
 'village': {'AV_HouseLongA':[-34,0,0], 'AV_HouseLongB':[34,0,0], 'AV_FenceBroken':[-53,0,-28], 'AV_Well':[-30,0,-28], 'AV_Cart':[-5,0,-30], 'AV_DeadTree':[23,0,-30], 'SH_Crate':[48,0,-25], 'SH_Barrel':[56,0,-34]},
 'city': {'AC_FacadeLongA':[-35,0,0], 'AC_FacadeLongB':[35,0,0], 'AC_CarBlue':[-53,0,-28], 'AC_CarRust':[-32,0,-28], 'AC_Streetlight':[-8,0,-30], 'AC_PlanterTree':[18,0,-30], 'SH_Crate':[44,0,-25], 'SH_Barrel':[54,0,-25], 'SH_Rubble':[49,0,-38]},
 'parasitown': {'PT_InfectedFacadeA':[-35,0,0], 'PT_InfectedFacadeB':[35,0,0], 'PT_InfectionPatch':[-50,0,-30], 'PT_WallGrowth':[-20,0,-28], 'PT_ArenaTentacleTall':[14,0,-33], 'PT_ArenaTentacleHook':[46,0,-33]}
}

def verify_glb(path):
    raw=path.read_bytes();magic,ver,total=struct.unpack_from('<III',raw)
    assert magic==0x46546c67 and ver==2 and total==len(raw)
    jlen,jkind=struct.unpack_from('<II',raw,12);assert jkind==0x4e4f534a
    d=json.loads(raw[20:20+jlen]);blen,bkind=struct.unpack_from('<II',raw,20+jlen)
    assert bkind==0x004e4942;buf=raw[28+jlen:];assert len(buf)==blen
    assert len({n['name'] for n in d['nodes']})==len(d['nodes'])
    assert not any(k in d for k in ['images','textures','animations','skins'])
    assert all('uri' not in b for b in d['buffers'])
    def read(ai):
        a=d['accessors'][ai];v=d['bufferViews'][a['bufferView']]
        assert v.get('byteOffset',0)%4==0
        assert v.get('byteOffset',0)+v['byteLength']<=len(buf)
        fmt={5126:'f',5123:'H',5125:'I'}[a['componentType']]
        count=a['count']*{'SCALAR':1,'VEC3':3,'VEC4':4}[a['type']]
        return struct.unpack_from('<'+str(count)+fmt,buf,v.get('byteOffset',0)+a.get('byteOffset',0))
    triangles=0;maxpart=0
    for m in d['meshes']:
        for p in m['primitives']:
            v=read(p['attributes']['POSITION']);n=read(p['attributes']['NORMAL']);t=read(p['indices']);col=read(p['attributes']['COLOR_0'])
            count=len(v)//3;assert len(n)==len(v)==len(col)
            assert all(math.isfinite(x) for x in v+n)
            assert len(t)%3==0 and all(0<=i<count for i in t)
            assert len(t)//3<=10000
            for i in range(0,len(n),3):assert abs(sum(x*x for x in n[i:i+3])-1)<1e-5
            for i in range(0,len(t),3):
                a,b,c=[v[k*3:k*3+3] for k in t[i:i+3]]
                u=[b[j]-a[j] for j in range(3)];w=[c[j]-a[j] for j in range(3)]
                cross=[u[1]*w[2]-u[2]*w[1],u[2]*w[0]-u[0]*w[2],u[0]*w[1]-u[1]*w[0]]
                assert sum(x*x for x in cross)>1e-16
            triangles+=len(t)//3;maxpart=max(maxpart,len(t)//3)
    return dict(file=str(path.relative_to(ROOT)),bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest(),meshes=len(d['meshes']),triangles=triangles,max_part_triangles=maxpart)

for name in ASSETS:write_glb(ROOT/'models'/(name+'.glb'),{name:[0,0,0]})
for biome,layout in LAYOUT.items():
    assert set(layout)=={n for n,a in ASSETS.items() if biome in a['biomes']}
    write_glb(ROOT/'biome-packs'/(biome+'.glb'),layout)
(ROOT/'review-layout.json').write_text(json.dumps(LAYOUT,indent=2))
results=[verify_glb(p) for p in sorted(ROOT.glob('*/*.glb'))]
report=dict(status='PASS',model_count=len(ASSETS),biome_pack_count=len(LAYOUT),unique_triangles=sum(a['triangles'] for a in ASSETS.values()),checks=['valid GLB containers','finite positions','unit normals','index ranges','nonzero triangle areas','unique names','linear vertex colors','no external textures or buffers','each mesh under 10000 triangles','all biome catalog entries exported'],files=results)
(ROOT/'validation.json').write_text(json.dumps(report,indent=2))
print(json.dumps({k:v for k,v in report.items() if k!='files'},indent=2))
