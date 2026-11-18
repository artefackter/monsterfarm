from copy import deepcopy
from pathlib import Path
import json
import sys
import numpy as np

ROOT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT.parent/"srp-optimized-v1"))
from compact_glb import GLB, Writer, unique_vertices


def animation_tracks(source,doc,writer):
    defaults={"translation":[0,0,0],"rotation":[0,0,0,1],"scale":[1,1,1]}
    counts=[0,0]
    for action in doc.get("animations",[]):
        old=action["samplers"]
        channels,samplers=[],[]
        for channel in action["channels"]:
            sampler=old[channel["sampler"]]
            times=source.array(sampler["input"])
            values=source.array(sampler["output"])
            assert sampler.get("interpolation","LINEAR") in ("LINEAR","STEP")
            counts[0]+=len(times)
            path=channel["target"]["path"]
            if np.all(values==values[0]):
                node=doc["nodes"][channel["target"]["node"]]
                default=np.array(node.get(path,defaults[path]),dtype=np.float32)
                if np.array_equal(values[0],default) or (path=="rotation" and np.array_equal(values[0],-default)):
                    continue
                times,values=times[:1],values[:1]
            else:
                # Interior keys on a constant plateau have no effect under either interpolation.
                changed=np.any(values[1:]!=values[:-1],axis=1)
                keep=np.r_[True,changed[:-1]|changed[1:],True]
                times,values=times[keep],values[keep]
            counts[1]+=len(times)
            channels.append({**channel,"sampler":len(samplers)})
            samplers.append({**sampler,"input":writer.array(times,5126,"SCALAR",bounds=True),
                             "output":writer.array(values,5126,"VEC4" if path=="rotation" else "VEC3")})
        action.update(channels=channels,samplers=samplers)
    return counts


def pack(path):
    source=GLB(path)
    doc=deepcopy(source.doc)
    assert len(doc["meshes"])==len(doc["skins"])==len(doc["materials"])==1
    prim,=doc["meshes"][0]["primitives"]
    arrays={k:source.array(v) for k,v in prim["attributes"].items()}
    assert set(arrays)=={"POSITION","NORMAL","COLOR_0","JOINTS_0","WEIGHTS_0"}
    assert not doc.get("images") and not doc.get("extensionsRequired")
    normal=arrays["NORMAL"]
    rounded=np.rint(normal*65535.)/65535.
    arrays["NORMAL"]=(rounded/np.linalg.norm(rounded,axis=1,keepdims=True)).astype("<f4")
    colors=np.rint(arrays["COLOR_0"]*65535).astype("<u2")
    if colors.shape[1]==3: colors=np.c_[colors,np.full(len(colors),65535,dtype="<u2")]
    arrays["COLOR_0"]=colors
    weights=arrays["WEIGHTS_0"].astype(float)
    weights/=weights.sum(axis=1,keepdims=True)
    packed=np.rint(weights*65535).astype(int)
    packed[np.arange(len(weights)),weights.argmax(axis=1)]+=65535-packed.sum(axis=1)
    assert packed.min()>=0 and packed.max()<=65535
    arrays["WEIGHTS_0"]=packed.astype("<u2")
    arrays["JOINTS_0"]=arrays["JOINTS_0"].astype("u1")
    a,remap=unique_vertices(arrays)
    source_indices=source.array(prim["indices"],False).ravel()
    ix=remap[source_indices].reshape(-1,1)
    assert len(a["POSITION"])<65536
    w=Writer()
    prim["attributes"]={
        "POSITION":w.array(a["POSITION"],5126,"VEC3",34962,bounds=True),
        "NORMAL":w.array(a["NORMAL"],5126,"VEC3",34962),
        "COLOR_0":w.array(a["COLOR_0"],5123,"VEC4",34962,True),
        "WEIGHTS_0":w.array(a["WEIGHTS_0"],5123,"VEC4",34962,True),
        "JOINTS_0":w.array(a["JOINTS_0"],5121,"VEC4",34962)}
    prim["indices"]=w.array(ix,5123,"SCALAR",34963)
    skin=doc["skins"][0]
    skin["inverseBindMatrices"]=w.array(source.array(skin["inverseBindMatrices"]),5126,"MAT4")
    keys=animation_tracks(source,doc,w)
    draft=path.with_suffix(".pending")
    w.save(doc,draft)
    check=GLB(draft)
    new_prim=check.doc["meshes"][0]["primitives"][0]
    new_indices=check.array(new_prim["indices"],False).ravel()
    original=source.doc["meshes"][0]["primitives"][0]
    tolerances={"POSITION":0,"NORMAL":.00003,"JOINTS_0":0,"WEIGHTS_0":2/65535,"COLOR_0":1/65535}
    for name,limit in tolerances.items():
        before=source.array(original["attributes"][name])[source_indices]
        after=check.array(new_prim["attributes"][name])[new_indices,:before.shape[1]]
        assert np.max(np.abs(after.astype(float)-before))<=limit,name
    draft.replace(path)
    return {"vertices":len(a["POSITION"]),"input_animation_keys":keys[0],"animation_keys":keys[1]}


if __name__=="__main__":
    summary={p.stem:pack(p) for p in sorted((ROOT/"models").glob("*.glb"))}
    (ROOT/"packing.json").write_text(json.dumps(summary,indent=2)+"\n")
