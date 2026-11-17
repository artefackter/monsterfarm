"""Independent comparisons of triangle corners, skeletons, tracks and skinned poses."""
import json
import sys
from pathlib import Path
import numpy as np
ROOT=Path(__file__).resolve().parent;sys.path.insert(0,str(ROOT))
from compact_glb import GLB
from assets import verify_sources,sha

def quaternion_matrix(q):
    q=np.asarray(q,dtype=np.float64)
    x,y,z,w=q/np.linalg.norm(q)
    return np.array([[1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w)],
                     [2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w)],
                     [2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y)]])
def slerp(a,b,t):
    a=np.asarray(a,dtype=np.float64);b=np.asarray(b,dtype=np.float64)
    a=a/np.linalg.norm(a);b=b/np.linalg.norm(b);dot=float(a@b)
    if dot<0:b=-b;dot=-dot
    dot=min(1,max(-1,dot))
    if dot>.9995:
        q=a+(b-a)*t;return q/np.linalg.norm(q)
    angle=np.arccos(dot);return (np.sin((1-t)*angle)*a+np.sin(t*angle)*b)/np.sin(angle)
def interpolate(times,values,t,path,kind):
    if len(times)==1 or t<=times[0]:return values[0]
    if t>=times[-1]:return values[-1]
    i=int(np.searchsorted(times,t,side='right')-1)
    if kind=='STEP':return values[i]
    ratio=(t-times[i])/(times[i+1]-times[i])
    return slerp(values[i],values[i+1],ratio) if path=='rotation' else values[i]*(1-ratio)+values[i+1]*ratio
def world_matrices(g,clip,t):
    d=g.doc;trs=[{k:np.array(n.get(k,default),dtype=float) for k,default in
         [('translation',(0,0,0)),('rotation',(0,0,0,1)),('scale',(1,1,1))]} for n in d['nodes']]
    action=next(a for a in d['animations'] if a['name']==clip)
    for c in action['channels']:
        s=action['samplers'][c['sampler']];path=c['target']['path'];node=c['target']['node']
        trs[node][path]=interpolate(g.array(s['input']).reshape(-1),g.array(s['output']),t,path,s.get('interpolation','LINEAR'))
    parents={c:i for i,n in enumerate(d['nodes']) for c in n.get('children',[])};world={}
    def get(i):
        if i not in world:
            n=d['nodes'][i];v=trs[i]
            if 'matrix' in n:m=np.array(n['matrix']).reshape(4,4,order='F')
            else:
                m=np.eye(4);m[:3,:3]=quaternion_matrix(v['rotation'])@np.diag(v['scale']);m[:3,3]=v['translation']
            world[i]=get(parents[i])@m if i in parents else m
        return world[i]
    return [get(i) for i in range(len(d['nodes']))]
def joint_matrices(g,world):
    skin=g.doc['skins'][0];inverse=g.array(skin['inverseBindMatrices']).reshape(-1,4,4).transpose(0,2,1)
    return np.array([world[i] for i in skin['joints']])@inverse
def deform(a,joints):
    positions=np.column_stack((a['POSITION'],np.ones(len(a['POSITION']))))
    matrix=np.sum(joints[a['JOINTS_0'].astype(int)]*a['WEIGHTS_0'][:,:,None,None],axis=1)
    return np.einsum('nij,nj->ni',matrix,positions)[:,:3]
def primitives(g):
    out={}
    for m in g.doc['meshes']:
        p=m['primitives'][0]
        out[m['name']]=({k:g.array(v) for k,v in p['attributes'].items()},g.array(p['indices'],False).reshape(-1))
    return out
def tracks(g,action):
    return {(g.doc['nodes'][c['target']['node']]['name'],c['target']['path']):(g.array(action['samplers'][c['sampler']]['input']),
            g.array(action['samplers'][c['sampler']]['output']),action['samplers'][c['sampler']].get('interpolation','LINEAR')) for c in action['channels']}

report=json.loads((ROOT/'models_report.json').read_text());checks=[]
for row in report['models']:
    source=GLB(row['source']);out=GLB(ROOT/row['output']);a,b=source.doc,out.doc
    assert sha(row['source'])==row['source_sha256'] and sha(ROOT/row['output'])==row['output_sha256']
    assert not b.get('extensionsRequired') and not b.get('images')
    assert a['materials']==b['materials']
    oldskin,newskin=a['skins'][0],b['skins'][0]
    oldnames=[a['nodes'][i]['name'] for i in oldskin['joints']];newnames=[b['nodes'][i]['name'] for i in newskin['joints']]
    assert oldnames==newnames
    assert np.array_equal(source.array(oldskin['inverseBindMatrices']),out.array(newskin['inverseBindMatrices']))
    for d in (a,b):
        parent={c:i for i,n in enumerate(d['nodes']) for c in n.get('children',[])}
        signature=[(d['nodes'][i]['name'],d['nodes'][parent[i]]['name'] if i in parent else None,
                    {k:v for k,v in d['nodes'][i].items() if k in ('matrix','translation','rotation','scale')}) for i in d['skins'][0]['joints']]
        if d is a:oldsignature=signature
        else:assert signature==oldsignature
    oldprim,newprim=primitives(source),primitives(out);parts=[];max_color=0;max_weight=0
    for name,(oa,oi) in oldprim.items():
        r=row['stats']['part_ranges'][name];na,ni=newprim[r['mesh']]
        ni=ni[r['triangle_start']*3:(r['triangle_start']+r['triangles'])*3]
        assert len(oi)==len(ni)
        for key in ('POSITION','NORMAL','JOINTS_0'):assert np.array_equal(oa[key][oi],na[key][ni]),(row['id'],name,key)
        width=oa['COLOR_0'].shape[1]
        max_color=max(max_color,float(np.abs(oa['COLOR_0'][oi]-na['COLOR_0'][ni,:width]).max()))
        if width==3:assert np.all(na['COLOR_0'][:,3]==1)
        max_weight=max(max_weight,float(np.abs(oa['WEIGHTS_0'][oi]-na['WEIGHTS_0'][ni]).max()))
        assert np.max(np.abs(na['WEIGHTS_0'].sum(axis=1)-1))<1e-7
        parts.append((name,oa,oi,r['mesh'],ni))
    assert max_color<=.5/65535+1e-7 and max_weight<2/65535
    assert {x['name'] for x in b['animations']}=={'Idle','Aggressive'}
    for clip in ('Idle','Aggressive'):
        ac=next(x for x in a['animations'] if x['name']==clip);bc=next(x for x in b['animations'] if x['name']==clip)
        oldtracks,newtracks=tracks(source,ac),tracks(out,bc)
        for key,(times,values,kind) in oldtracks.items():
            if key not in newtracks:
                assert np.array_equal(values,np.broadcast_to(values[0],values.shape));continue
            tt,vv,kk=newtracks[key];assert kind==kk
            if len(tt)==len(times):assert np.array_equal(times,tt) and np.array_equal(values,vv)
            else:assert len(tt)==1 and np.array_equal(values,np.broadcast_to(vv[0],values.shape))
        duration={'Idle':2.4,'Aggressive':1.2}[clip]
        assert abs(max(float(t[-1,0]) for t,_,_ in newtracks.values())-duration)<1e-5
    pose_error=0;bone_error=0
    for clip,duration in [('Idle',2.4),('Aggressive',1.2)]:
        for t in (0,duration*.25,duration*.5,duration*.75,duration,1/60,duration*.37):
            ow,nw=world_matrices(source,clip,t),world_matrices(out,clip,t)
            bone_error=max(bone_error,max(float(np.abs(ow[i]-nw[j]).max()) for i,j in zip(oldskin['joints'],newskin['joints'])))
            oj,nj=joint_matrices(source,ow),joint_matrices(out,nw)
            cache={name:deform(arr,nj) for name,(arr,_) in newprim.items()}
            for name,oa,oi,group,ni in parts:
                difference=deform(oa,oj)[oi]-cache[group][ni]
                pose_error=max(pose_error,float(np.linalg.norm(difference,axis=1).max()))
    assert bone_error<1e-7 and pose_error<1e-4,(row['id'],bone_error,pose_error)
    checks.append({'id':row['id'],'passed':True,'exact_triangle_corner_geometry':True,'exact_normals':True,
        'bone_names_hierarchy_and_bind_matrices_preserved':True,'moving_animation_keys_preserved':True,
        'clips':['Idle','Aggressive'],'pose_samples':14,'max_world_bone_matrix_error':bone_error,
        'max_deformed_vertex_distance':pose_error,'max_linear_color_error':max_color,'max_weight_error':max_weight})
    print('PACKING_VERIFIED',row['id'],'POSE_ERROR',pose_error,flush=True)
unchanged=verify_sources()
(ROOT/'packing_validation.json').write_text(json.dumps({'passed':True,'models':checks,
    'source_files_unchanged':unchanged,'method':'Exact triangle-corner and normal comparisons; all moving samples preserved; independent glTF skin evaluation at 14 times including subframes.'},indent=2)+'\n')
print('ALL_PACKING_VERIFIED',len(checks),flush=True)
