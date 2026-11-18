"""Palette PNGs at both approved UI sizes, with separately budgeted edge colours."""
import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parent
SOURCE=ROOT.parent/"pale-grinner-forms-v1"/"icons"


def nearest(points,centers):
    # Work on unique colours only and bound the temporary distance matrix.
    norms=(centers*centers).sum(axis=1)
    return np.concatenate([(norms-2*chunk@centers.T).argmin(axis=1)
                           for chunk in np.array_split(points,max(1,len(points)//768))])


def feature(rgba):
    alpha=rgba[:,3:4]/255.
    return np.column_stack((rgba[:,:3]*alpha,rgba[:,3]*1.5))


def palette_for(rgba,capacity):
    colors,back,counts=np.unique(rgba,axis=0,return_inverse=True,return_counts=True)
    back=back.ravel()
    if len(colors)<=capacity:
        return colors,back
    points=feature(colors.astype(np.float32))
    weights=counts.astype(np.float32)
    buckets=[np.arange(len(points))]
    def spread(ids):
        if len(ids)<2: return -1,0
        p=points[ids]; w=weights[ids]
        total=w.sum()
        variance=((p-np.average(p,axis=0,weights=w))**2*w[:,None]).sum(axis=0)
        return float(variance.max()),int(variance.argmax())
    splits=[spread(buckets[0])]
    while len(buckets)<capacity:
        k=max(range(len(splits)),key=lambda i:splits[i][0])
        ids=buckets[k];axis=splits[k][1]
        order=ids[np.argsort(points[ids,axis],kind="stable")]
        wc=weights[order].cumsum()
        cut=min(len(order)-1,int(np.searchsorted(wc,wc[-1]/2))+1)
        buckets[k]=order[:cut];buckets.append(order[cut:])
        splits[k]=spread(buckets[k]);splits.append(spread(buckets[-1]))
    centers=np.array([np.average(points[b],axis=0,weights=weights[b]) for b in buckets],np.float32)
    for _ in range(7):
        ids=nearest(points,centers)
        total=np.bincount(ids,weights,minlength=capacity)
        used=total>0
        for j in range(4):
            centers[used,j]=np.bincount(ids,weights*points[:,j],minlength=capacity)[used]/total[used]
    alpha=np.clip(np.rint(centers[:,3:4]/1.5),1,255)
    palette=np.clip(np.rint(np.column_stack((centers[:,:3]*255/alpha,alpha))),0,255).astype("u1")
    ids=nearest(points,feature(palette.astype(np.float32)))
    return palette,ids[back]


def optimize(path,target):
    with Image.open(path) as opened:
        source=np.array(opened.convert("RGBA"))
    h,w=source.shape[:2]
    flat=source.reshape(-1,4)
    pixels=np.zeros(len(flat),"u1")
    palette=[np.zeros((1,4),"u1")]
    for mask,limit in ((flat[:,3]>=246,197),((flat[:,3]>0)&(flat[:,3]<246),58)):
        p,idx=palette_for(flat[mask],limit)
        pixels[mask]=sum(len(a) for a in palette)+idx
        palette.append(p)
    rgba=np.vstack(palette)
    image=Image.frombytes("P",(w,h),pixels.tobytes())
    image.putpalette(rgba[:,:3].tobytes())
    target.parent.mkdir(parents=True,exist_ok=True)
    image.save(target,transparency=rgba[:,3].tobytes(),optimize=True,compress_level=9)
    with Image.open(target) as opened:
        assert opened.size==(w,h)
        result=np.array(opened.convert("RGBA")).reshape(-1,4)
    assert np.array_equal(flat[:,3]==0,result[:,3]==0)
    visible=flat[:,3]>0
    a,b=(p[visible].astype(np.float64) for p in (flat,result))
    def composite(p,background):
        return background+(p[:,:3]-background)*p[:,3:4]/255
    errors=[composite(a,bg)-composite(b,bg) for bg in (12,240)]
    psnr=min(-10*np.log10(np.mean((e/255)**2)) for e in errors)
    assert psnr>36 and target.stat().st_size<path.stat().st_size,(path,psnr)
    return {"input_bytes":path.stat().st_size,"output_bytes":target.stat().st_size,
            "visible_composite_psnr_db":round(float(psnr),2)}


if __name__=="__main__":
    report={}
    for size in ("ui512","small256"):
        report[size]={p.stem:optimize(p,ROOT/"icons"/size/p.name) for p in sorted((SOURCE/size).glob("*.png"))}
        assert len(report[size])==6
    (ROOT/"icons.json").write_text(json.dumps(report,indent=2)+"\n")
