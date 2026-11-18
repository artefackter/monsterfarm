"""Choose the smallest indexed PNG among pixel-identical palette and filter encodings."""
import json
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path
import struct
import zlib

import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parent
SOURCE=ROOT.parent/'floating-grin-forms-v1'/'icons'


def scanlines(pixels):
    val=pixels.astype('i2')
    left=np.zeros_like(val)
    left[:,1:]=val[:,:-1]
    up=np.zeros_like(val)
    up[1:]=val[:-1]
    diag=np.zeros_like(val)
    diag[1:,1:]=val[:-1,:-1]
    predicted=left+up-diag
    a,b,c=abs(predicted-left),abs(predicted-up),abs(predicted-diag)
    paeth=np.where((a<=b)&(a<=c),left,np.where(b<=c,up,diag))
    filters=np.stack([val,val-left,val-up,val-(left+up)//2,val-paeth]).astype('u1')
    rows=np.arange(len(val))
    choices=abs(filters.view('i1').astype('i2')).sum(2).argmin(0)
    for tag in [*range(5),None]:
        kinds=choices if tag is None else np.full(len(rows),tag)
        yield np.column_stack((kinds.astype('u1'),filters[kinds,rows])).tobytes()


def chunk(tag,data):
    return struct.pack('>I',len(data))+tag+data+struct.pack('>I',zlib.crc32(tag+data))


def optimize(path):
    original=path.read_bytes()
    with Image.open(path) as im:
        assert im.mode=='P'
        data=np.array(im)
        rgba=np.array(im.convert('RGBA'))
        width,height=im.size
        palette=np.c_[np.array(im.getpalette(),dtype='u1').reshape(-1,3),
                      np.array(list(im.info['transparency']),dtype='u1')]
    counts=np.bincount(data.ravel(),minlength=len(palette))
    active=np.flatnonzero(counts)
    colors=palette.astype(float)
    colors[:,:3]*=colors[:,3:]/255
    luma=colors[:,:3]@np.array([.213,.715,.072])
    distances=((colors[:,None]-colors[None,:])**2).sum(2)
    chain=[int(active[np.argmax(counts[active])])]
    remaining=set(active)-set(chain)
    while remaining:
        i=min(remaining,key=lambda i:(distances[chain[-1],i],i))
        chain.append(i)
        remaining.remove(i)
    orders=[active,sorted(active,key=lambda i:-counts[i]),sorted(active,key=lambda i:luma[i]),
            sorted(active,key=lambda i:(palette[i,3],luma[i])),chain]
    best=original
    for order in orders:
        order=np.asarray(order)
        table=palette[order]
        lut=np.zeros(len(palette),dtype='u1')
        lut[order]=np.arange(len(order))
        pre=(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',width,height,8,3,0,0,0))+
             chunk(b'PLTE',table[:,:3].tobytes()))
        alpha=table[:,3].tobytes().rstrip(b'\xff')
        if alpha:
            pre+=chunk(b'tRNS',alpha)
        for scan in scanlines(lut[data]):
            for strategy in [zlib.Z_DEFAULT_STRATEGY,zlib.Z_FILTERED]:
                encoder=zlib.compressobj(9,zlib.DEFLATED,15,9,strategy)
                packed=encoder.compress(scan)+encoder.flush()
                candidate=pre+chunk(b'IDAT',packed)+chunk(b'IEND',b'')
                if len(candidate)<len(best):
                    best=candidate
    dest=ROOT/'icons'/path.parent.name/path.name
    dest.parent.mkdir(parents=True,exist_ok=True)
    dest.write_bytes(best)
    with Image.open(dest) as check:
        np.testing.assert_array_equal(np.array(check.convert('RGBA')),rgba)
    return str(path.relative_to(SOURCE)),dict(input_bytes=len(original),output_bytes=len(best),width=width,height=height,
                                              max_RGBA_channel_difference=0)


if __name__=='__main__':
    files=sorted((SOURCE/'ui512').glob('*.png'))+sorted((SOURCE/'small256').glob('*.png'))
    assert len(files)==12
    with ProcessPoolExecutor(max_workers=4) as pool:
        summary=dict(pool.map(optimize,files))
    (ROOT/'icons.json').write_text(json.dumps(summary,indent=2)+'\n')
    print([(p,d['input_bytes']-d['output_bytes']) for p,d in summary.items()])
