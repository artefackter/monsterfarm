"""Conservative RGB precision reduction; preserve every alpha sample exactly."""
from pathlib import Path
import hashlib,json,zipfile
import numpy as np
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parent
SOURCE=ROOT.parent/'pets-melee-icons-v1'
manifest=json.loads((SOURCE/'manifest.json').read_text())
protected={str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in SOURCE.rglob('*') if p.is_file()}
rows=[]
for asset in manifest['assets']:
    row={'id':asset['id'],'label':asset['label'],'suggested_icon_key':asset['suggested_icon_key'],'profiles':{}}
    for profile,size in [('ui512',512),('small256',256)]:
        p=SOURCE/asset['variants'][profile]['file'];im=Image.open(p);a=np.array(im)
        q=a.copy()
        q[:,:,:3]=np.clip(np.rint(a[:,:,:3].astype(np.float32)/4)*4,0,255).astype(np.uint8)
        q[q[:,:,3]==0,:3]=0
        path=ROOT/'icons'/profile/p.name;path.parent.mkdir(parents=True,exist_ok=True)
        Image.fromarray(q).save(path,optimize=True,compress_level=9)
        check=np.array(Image.open(path));assert np.array_equal(check,q)
        assert np.array_equal(a[:,:,3],check[:,:,3])
        visible=a[:,:,3]>0
        diff=np.abs(a[:,:,:3].astype(np.int16)-check[:,:,:3].astype(np.int16))[visible]
        assert int(diff.max())<=2
        assert path.stat().st_size<p.stat().st_size
        row['profiles'][profile]={'file':str(path.relative_to(ROOT)),'size':[size,size],'source_bytes':p.stat().st_size,'bytes':path.stat().st_size,'max_rgb_error_255':int(diff.max()),'mean_rgb_error_255':float(diff.mean()),'alpha_exact':True,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
    rows.append(row)
assert all(hashlib.sha256(Path(p).read_bytes()).hexdigest()==sha for p,sha in protected.items())
totals={profile:{'before':sum(r['profiles'][profile]['source_bytes'] for r in rows),'after':sum(r['profiles'][profile]['bytes'] for r in rows)} for profile in ('ui512','small256')}
for value in totals.values():value['saved_percent']=round((1-value['after']/value['before'])*100,2)
report={'passed':True,'integrated':False,'count':len(rows),'format':'PNG RGBA8','method':'RGB rounded to nearest multiple of 4; alpha unchanged; invisible RGB zeroed; PNG compression level 9','original_full_resolution_bytes':manifest['original_bytes'],'totals':totals,'protected_source_files':len(protected),'assets':rows}
(ROOT/'manifest.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')

# Review only: compare previous 512 files with compressed files, using both backgrounds.
sheet=Image.new('RGBA',(1280,1450),'#F7E8C7');d=ImageDraw.Draw(sheet)
font=lambda n:ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',n)
d.text((25,18),'До сжатия / После сжатия',font=font(34),fill='#511A3D')
d.text((25,65),'512 px PNG, отображение 128 px • прозрачность сохранена',font=font(22),fill='#511A3D')
for i,row in enumerate(rows):
    y=110+i*145
    d.text((20,y+54),row['label'],font=font(22),fill='#511A3D')
    for j,bg in enumerate(('#FFF5DD','#252034')):
        x=320+j*470
        d.rounded_rectangle((x,y,x+440,y+137),radius=10,fill=bg)
        for k,path in enumerate((SOURCE/'icons/ui512'/f"{row['id']}.png",ROOT/'icons/ui512'/f"{row['id']}.png")):
            sheet.alpha_composite(Image.open(path).resize((128,128),Image.Resampling.LANCZOS),(x+35+k*215,y+4))
(ROOT/'previews').mkdir(exist_ok=True)
sheet.convert('RGB').save(ROOT/'previews/Compression_Comparison.png',optimize=True)
for profile in ('ui512','small256'):
    with zipfile.ZipFile(ROOT/f'Roblox_Icons_{profile}.zip','w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
        for p in sorted((ROOT/'icons'/profile).glob('*.png')):z.write(p,p.name)
        z.write(ROOT/'README.txt','README.txt');z.write(ROOT/'manifest.json','manifest.json')
    with zipfile.ZipFile(ROOT/f'Roblox_Icons_{profile}.zip') as z:assert z.testzip() is None
print(json.dumps({'passed':True,'totals':totals,'source_files_unchanged':len(protected)},indent=2))
