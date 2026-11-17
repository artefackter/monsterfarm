"""Deterministic PNG resizing/compression; no image generation or artwork edits."""
import json
import math
import sys
from pathlib import Path
from PIL import Image,ImageChops,ImageStat
ROOT=Path(__file__).resolve().parent;sys.path.insert(0,str(ROOT))
from assets import icon_assets,verify_sources,sha

verify_sources();rows=[]
for asset in icon_assets():
    source=Path(asset['source']);im=Image.open(source);assert im.mode=='RGBA' and im.width==im.height
    row={**asset,'source_bytes':source.stat().st_size,'source_sha256':sha(source),'source_size':list(im.size),'variants':{}}
    for profile,size in [('large1024',1024),('ui512',512),('small256',256)]:
        out=ROOT/'icons'/profile/(asset['id']+'.png');out.parent.mkdir(parents=True,exist_ok=True)
        resized=im.resize((size,size),Image.Resampling.LANCZOS)
        resized.save(out,format='PNG',optimize=True,compress_level=9)
        loaded=Image.open(out);assert loaded.mode=='RGBA' and loaded.size==(size,size)
        assert loaded.tobytes()==resized.tobytes()
        assert loaded.getchannel('A').getextrema()==(0,255)
        corners=[loaded.getpixel(pos)[3] for pos in [(0,0),(0,size-1),(size-1,0),(size-1,size-1)]]
        assert max(corners)<=1
        ui=[]
        for display in (64,96,128):
            a=im.resize((display,display),Image.Resampling.LANCZOS);b=loaded.resize((display,display),Image.Resampling.LANCZOS)
            mask=ImageChops.lighter(a.getchannel('A'),b.getchannel('A')).point(lambda v:255 if v>16 else 0)
            for bg in ('#F6EEDC','#151C26'):
                aa=Image.new('RGBA',a.size,bg);aa.alpha_composite(a)
                bb=Image.new('RGBA',b.size,bg);bb.alpha_composite(b)
                diff=ImageChops.difference(aa.convert('RGB'),bb.convert('RGB'))
                stats=ImageStat.Stat(diff,mask)
                rms=math.sqrt(sum(x*x for x in stats.rms)/3)
                ui.append({'display_px':display,'background':bg,'mean_rgb_error_255':round(sum(stats.mean)/3,4),
                           'rmse_255':round(rms,4),'psnr_db':round(20*math.log10(255/max(rms,1e-9)),2)})
        row['variants'][profile]={'file':str(out.relative_to(ROOT)),'bytes':out.stat().st_size,'size':[size,size],
            'rgba8_uncompressed_bytes':size*size*4,'sha256':sha(out),'corner_alpha':corners,'ui_comparison':ui}
    rows.append(row);print('ICON',asset['id'],row['source_bytes'],'->',row['variants']['ui512']['bytes'],flush=True)
(ROOT/'icons_report.json').write_text(json.dumps({'passed':True,'artwork_regenerated':False,'icons':rows},ensure_ascii=False,indent=2)+'\n')
print('ICONS_OPTIMIZED',len(rows),'SOURCES_UNCHANGED',verify_sources(),flush=True)
