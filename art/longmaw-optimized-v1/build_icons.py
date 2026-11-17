"""Deterministic resampling and PNG compression, no regeneration or design edits."""
import json
import math
from PIL import Image,ImageChops,ImageStat
from assets import ROOT,icons,verify_sources,sha

verify_sources();rows=[]
for asset in icons():
    source=asset['source'];im=Image.open(source);assert im.mode=='RGBA' and im.size==(1254,1254)
    row={'id':asset['id'],'role':asset['role'],'ru':asset['ru'],'source':source,
         'source_sha256':sha(source),'source_bytes':len(open(source,'rb').read()),
         'source_size':list(im.size),'variants':{}}
    for profile,size in [('ui512',512),('small256',256),('large1024',1024)]:
        output=ROOT/'icons'/profile/(asset['id']+'.png');output.parent.mkdir(parents=True,exist_ok=True)
        resized=im.resize((size,size),Image.Resampling.LANCZOS)
        resized.save(output,format='PNG',optimize=True,compress_level=9)
        loaded=Image.open(output)
        assert loaded.mode=='RGBA' and loaded.size==(size,size)
        assert loaded.tobytes()==resized.tobytes()
        assert loaded.getchannel('A').getextrema()[0]==0
        assert loaded.getchannel('A').getextrema()[1]>=250
        comparisons=[]
        for display in (64,96,128):
            a=im.resize((display,display),Image.Resampling.LANCZOS)
            b=loaded.resize((display,display),Image.Resampling.LANCZOS)
            mask=ImageChops.lighter(a.getchannel('A'),b.getchannel('A')).point(lambda v:255 if v>16 else 0)
            for bg in ('#EDE6F2','#20212B'):
                left=Image.new('RGBA',a.size,bg);left.alpha_composite(a)
                right=Image.new('RGBA',b.size,bg);right.alpha_composite(b)
                stats=ImageStat.Stat(ImageChops.difference(left.convert('RGB'),right.convert('RGB')),mask)
                rms=math.sqrt(sum(x*x for x in stats.rms)/3)
                comparisons.append({'display_px':display,'background':bg,
                    'rmse_255':round(rms,4),'psnr_db':round(20*math.log10(255/max(rms,1e-9)),2)})
        row['variants'][profile]={'file':str(output.relative_to(ROOT)),'bytes':output.stat().st_size,
            'size':[size,size],'sha256':sha(output),'png_encoding_lossless_after_resize':True,
            'rgba8_base_level_bytes':size*size*4,'ui_comparison':comparisons}
    rows.append(row)
    print('ICON',asset['id'],row['source_bytes'],'->',row['variants']['ui512']['bytes'],flush=True)
(ROOT/'icons_report.json').write_text(json.dumps({'passed':True,'artwork_regenerated':False,
    'alpha_resampled_with_artwork':True,'source_files_unchanged':verify_sources(),'icons':rows},ensure_ascii=False,indent=2)+'\n')
