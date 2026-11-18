import json
import tempfile
import zipfile
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parent
SOURCE=ROOT.parent/"pale-grinner-v4"
ICONS=ROOT.parent/"pale-grinner-forms-v1"/"icons"


def pair(before,after):
    return {"before":before,"after":after,"reduction_percent":round(100*(1-after/before),2)}


def comparison():
    renders=Path(tempfile.gettempdir())/"pale-grinner-optimization-review"
    fonts=Path("/System/Library/Fonts/Supplemental")
    font=ImageFont.truetype(str(fonts/"Arial Bold.ttf"),24)
    bg="#20282f"
    grid=Image.new("RGB",(1020,701),bg)
    draw=ImageDraw.Draw(grid)
    for i,label in enumerate(("Одобренная V4","После оптимизации")):
        draw.text((260+500*i,26),label,fill="#faf1e2",font=font,anchor="mm")
    stats={}
    for row,name in enumerate(("PaleGrinner","PaleGrinnerAggressive")):
        layers=[]
        for col,variant in enumerate(("V4","Optimized")):
            with Image.open(renders/f"{name}_{variant}.png") as opened:
                layer=opened.convert("RGBA")
            layers.append(np.array(layer,dtype=float))
            rendered=Image.new("RGB",layer.size,"#394653")
            rendered.paste(layer,(0,0),layer)
            view=rendered.resize((356,318),Image.Resampling.LANCZOS)
            x=16+col*500;y=52+row*324
            draw.rectangle((x,y,x+487,y+317),fill="#394653")
            grid.paste(view,(x+(488-view.width)//2,y))
        a,b=layers
        ma=a[:,:,3]>128;mb=b[:,:,3]>128
        vis=ma|mb
        def composite(image):
            pixels=image[vis]
            return 36+(pixels[:,:3]-36)*pixels[:,3:4]/255
        mse=np.mean((composite(a)-composite(b))**2)
        stats[name]={"silhouette_iou":round(float((ma&mb).sum()/vis.sum()),5),
                     "visible_psnr_db":round(float(-10*np.log10(mse/255**2)),2)}
        assert stats[name]["silhouette_iou"]>.99 and stats[name]["visible_psnr_db"]>32
    grid.save(ROOT/"previews"/"Comparison.jpg",quality=93,subsampling=0)
    return stats


def main():
    models=json.loads((ROOT/"report.json").read_text())
    valid=json.loads((ROOT/"validation.json").read_text())
    packing=json.loads((ROOT/"packing.json").read_text())
    assert models.keys()==valid.keys()==packing.keys() and len(models)==8
    assert all(m["glb"]["passed"] and m["fbx"]["passed"] and m["hand_positions_colours_weights_exact"] for m in valid.values())
    summary={"triangles":pair(sum(m["original_triangles"] for m in models.values()),
                              sum(m["triangles"] for m in models.values())),
             "head_lunge_keys":pair(packing["PaleGrinnerAggressive"]["input_animation_keys"],
                                    packing["PaleGrinnerAggressive"]["animation_keys"]),
             "visual_comparison":comparison(),"roblox_load_time_measured":False}
    for ext in ("glb","fbx","blend"):
        sizes=[sum((root/"models"/(name+"."+ext)).stat().st_size for name in models) for root in (SOURCE,ROOT)]
        summary[ext+"_bytes"]=pair(*sizes)
    for size in ("ui512","small256"):
        paths=sorted((ROOT/"icons"/size).glob("*.png"))
        assert len(paths)==6
        summary[size+"_bytes"]=pair(sum((ICONS/size/p.name).stat().st_size for p in paths),
                                    sum(p.stat().st_size for p in paths))
    (ROOT/"summary.json").write_text(json.dumps(summary,indent=2)+"\n")
    files=[*(ROOT/"models").glob("*.glb"),*(ROOT/"models").glob("*.fbx"),*(ROOT/"models").glob("*.blend"),
           *(ROOT/"icons").glob("*/*.png"),ROOT/"previews"/"Comparison.jpg",ROOT/"summary.json"]
    assert len(files)==38
    path=ROOT/"PaleGrinner_Optimized.zip"
    with zipfile.ZipFile(path,"w",compression=zipfile.ZIP_DEFLATED,compresslevel=8) as archive:
        for f in sorted(files): archive.write(f,f.relative_to(ROOT))
    with zipfile.ZipFile(path) as archive:
        assert archive.testzip() is None
        for f in files: assert archive.read(f.relative_to(ROOT).as_posix())==f.read_bytes()
    print(path.stat().st_size,json.dumps(summary))


if __name__=="__main__":
    main()
