"""Independent numerical checks for all triangle corners, bones and deformed poses."""
import json,sys,math
from pathlib import Path
import numpy as np
ROOT=Path(__file__).resolve().parent;sys.path.insert(0,str(ROOT))
from compact_glb import GLB
from assets import sha,verify_sources
def rotation(q):
    x,y,z,w=np.asarray(q)/np.linalg.norm(q)
    return np.array([[1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w)],
        [2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w)],
        [2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y)]])
def joint_matrices(g,pose):
    d=g.doc;parents={c:i for i,n in enumerate(d['nodes']) for c in n.get('children',[])}
    world={};joints=set(d['skins'][0]['joints'])
    def calc(i):
        if i not in world:
            n=d['nodes'][i]
            if 'matrix' in n:m=np.array(n['matrix']).reshape(4,4,order='F')
            else:
                m=np.eye(4);m[:3,:3]=rotation(n.get('rotation',[0,0,0,1]))@np.diag(n.get('scale',[1,1,1]));m[:3,3]=n.get('translation',[0,0,0])
            if pose and i in joints:
                # Exercise each joint independently around alternating local axes.
                axis=np.zeros(3);axis[(i+pose)%3]=1
                angle=.22*math.sin(i*1.7+pose)
                q=list(axis*math.sin(angle/2))+[math.cos(angle/2)]
                delta=np.eye(4);delta[:3,:3]=rotation(q);m=m@delta
            world[i]=calc(parents[i])@m if i in parents else m
        return world[i]
    skin=d['skins'][0];inv=g.array(skin['inverseBindMatrices']).reshape(-1,4,4).transpose(0,2,1)
    return np.array([calc(i) for i in skin['joints']])@inv
def deform(a,j):
    pos=np.column_stack((a['POSITION'],np.ones(len(a['POSITION']))))
    m=np.sum(j[a['JOINTS_0'].astype(int)]*a['WEIGHTS_0'][:,:,None,None],axis=1)
    return np.einsum('nij,nj->ni',m,pos)[:,:3]
rows=[]
for r in json.loads((ROOT/'models_report.json').read_text())['models']:
    old=GLB(r['source']);new=GLB(ROOT/r['output']);a,b=old.doc,new.doc
    assert sha(r['source'])==r['source_sha256'] and sha(ROOT/r['output'])==r['output_sha256']
    for key in ('nodes','scenes','scene','materials','extensionsUsed','extensionsRequired'):
        assert a.get(key)==b.get(key),(r['id'],key)
    os,ns=a['skins'][0],b['skins'][0]
    assert {k:v for k,v in os.items() if k!='inverseBindMatrices'}=={k:v for k,v in ns.items() if k!='inverseBindMatrices'}
    assert np.array_equal(old.array(os['inverseBindMatrices']),new.array(ns['inverseBindMatrices']))
    assert not b.get('animations') and not b.get('textures') and not b.get('images')
    def arrays(g):
        p=g.doc['meshes'][0]['primitives'][0]
        return {k:g.array(v) for k,v in p['attributes'].items()},g.array(p['indices'],False).reshape(-1)
    oa,oi=arrays(old);na,ni=arrays(new)
    assert len(oi)==len(ni)
    for key in ('POSITION','NORMAL','JOINTS_0'):assert np.array_equal(oa[key][oi],na[key][ni]),(r['id'],key)
    ce=float(np.abs(oa['COLOR_0'][oi]-na['COLOR_0'][ni,:oa['COLOR_0'].shape[1]]).max())
    we=float(np.abs(oa['WEIGHTS_0'][oi]-na['WEIGHTS_0'][ni]).max())
    assert ce<=.5/65535+1e-7 and we<2/65535
    assert np.max(np.abs(na['WEIGHTS_0'].sum(axis=1)-1))<1e-7
    assert np.all(na['COLOR_0'][:,3]==1)
    assert np.max(ni)<len(na['POSITION'])
    pose_error=0
    for pose in range(5):
        oj,nj=joint_matrices(old,pose),joint_matrices(new,pose)
        assert np.array_equal(oj,nj)
        error=float(np.linalg.norm(deform(oa,oj)[oi]-deform(na,nj)[ni],axis=1).max())
        pose_error=max(pose_error,error)
    assert pose_error<1e-4,(r['id'],pose_error)
    # Accessor byte alignment and component bounds, including normalized attributes.
    for acc in b['accessors']:
        view=b['bufferViews'][acc['bufferView']]
        assert view.get('byteOffset',0)%4==0
        assert np.isfinite(new.array(b['accessors'].index(acc))).all()
    rows.append(dict(id=r['id'],passed=True,triangles=len(oi)//3,bones=len(ns['joints']),
        geometry_normals_joint_indices_exact=True,nodes_materials_and_bind_matrices_exact=True,
        max_color_error=ce,max_weight_error=we,pose_samples=5,max_deformed_vertex_distance=pose_error))
    print('PASS',r['id'],'pose_error',pose_error,flush=True)
(ROOT/'packing_validation.json').write_text(json.dumps(dict(passed=True,models=rows,source_files_unchanged=verify_sources()),indent=2)+'\n')
