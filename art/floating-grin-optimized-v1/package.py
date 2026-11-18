"""Compare like-for-like runtime assets and check every archived byte."""
from hashlib import sha256
import json
from pathlib import Path
from tempfile import gettempdir
from zipfile import ZIP_DEFLATED, ZipFile

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parent
WORK=Path(gettempdir())/'floating-grin-runtime-comparison'


def comparison():
    names=['FloatingGrin','FloatingGrinAggressive','FloatingGrinKing']
    labels=['База','Рывок','Король']
    sheet=Image.new('RGB',(800,800),'#20272c')
    draw=ImageDraw.Draw(sheet)
    fonts=Path('/System/Library/Fonts/Supplemental')
    head=ImageFont.truetype(str(fonts/'Arial Bold.ttf'),21)
    label=ImageFont.truetype(str(fonts/'Arial.ttf'),17)
    for i,title in enumerate(['До оптимизации','После оптимизации']):
        draw.text((218+i*385,24),title,anchor='mm',fill='#f4f3ec',font=head)
    stats={}
    for r,name in enumerate(names):
        row_y=45+250*r
        mask=[]
        bg=(114,133,146,255)
        pixels=[]
        for c,version in enumerate(('before','after')):
            with Image.open(WORK/(name+'_'+version+'.png')) as im:
                image=im.convert('RGBA')
                mask.append(np.array(image.getchannel('A'))>=128)
                comp=Image.alpha_composite(Image.new('RGBA',image.size,bg),image).convert('RGB')
            pixels.append(np.array(comp,dtype=float))
            x=28+c*385
            draw.rounded_rectangle((x,row_y,x+360,row_y+239),radius=8,fill=bg[:3])
            side=231
            sheet.paste(comp.resize((side,side),Image.Resampling.LANCZOS),(x+(360-side)//2,row_y+3))
            draw.text((x+9,row_y+218),labels[r],anchor='lm',fill='#1c252d',font=label)
        a,b=mask
        visible=a|b
        iou=np.count_nonzero(a&b)/np.count_nonzero(visible)
        mse=np.mean((pixels[0][visible]-pixels[1][visible])**2)
        stats[name]=dict(silhouette_iou=round(float(iou),5),visible_psnr_db=round(float(10*np.log10(255**2/mse)),2))
        assert iou>.985 and stats[name]['visible_psnr_db']>30,(name,stats[name])
    path=ROOT/'previews'/'Comparison.jpg'
    path.parent.mkdir(exist_ok=True)
    sheet.save(path,quality=91,subsampling=0)
    return stats


def pair(before,after):
    return dict(before=before,after=after,saved_percent=round((1-after/before)*100,2))


def aggregate(rows,first,second):
    return pair(sum(row[first] for row in rows),sum(row[second] for row in rows))


def main():
    models=json.loads((ROOT/'models.json').read_text())
    icons=json.loads((ROOT/'icons.json').read_text())
    imported=json.loads((ROOT/'import-check.json').read_text())
    assert len(models)==8 and set(models)==set(imported)
    assert len(icons)==12 and all(d['max_RGBA_channel_difference']==0 for d in icons.values())
    stats={'models_bytes':aggregate(models.values(),'input_bytes','output_bytes'),
           'triangles':aggregate(models.values(),'input_triangles','triangles'),
           'render_vertices':aggregate(models.values(),'input_vertices','vertices'),
           'icons_bytes':aggregate(icons.values(),'input_bytes','output_bytes'),
           'render_comparisons':comparison(),'blender_imports':len(imported),'studio_load_time_measured':False}
    for size in ('ui512','small256'):
        which=[d for name,d in icons.items() if name.startswith(size+'/')]
        assert len(which)==6
        stats[size+'_bytes']=aggregate(which,'input_bytes','output_bytes')
    inputs=[stats['models_bytes'],stats['icons_bytes']]
    stats['total_bytes']=aggregate(inputs,'before','after')
    paths=[*(ROOT/'models').glob('*.glb'),*(ROOT/'icons').glob('*/*.png')]
    assert len(paths)==20
    archive=ROOT/'FloatingGrin_Optimized.zip'
    with ZipFile(archive,'w',compression=ZIP_DEFLATED,compresslevel=9) as z:
        for p in sorted(paths):
            z.write(p,p.relative_to(ROOT))
    with ZipFile(archive) as z:
        assert z.testzip() is None and len(z.namelist())==len(paths)
        for p in paths:
            assert z.read(str(p.relative_to(ROOT)))==p.read_bytes()
    stats['zip_bytes']=archive.stat().st_size
    stats['zip_sha256']=sha256(archive.read_bytes()).hexdigest()
    (ROOT/'summary.json').write_text(json.dumps(stats,indent=2)+'\n')
    print(json.dumps(stats,indent=2))


if __name__=='__main__':
    main()
