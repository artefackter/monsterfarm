"""Prepare both UI sizes and the role-by-role comparison from the six illustrations."""
import json
from pathlib import Path
import sys
from tempfile import TemporaryDirectory
from zipfile import ZipFile, ZIP_DEFLATED

from PIL import Image, ImageChops, ImageDraw, ImageFont, ImageOps

ROOT = Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT.parent/"pale-grinner-optimized-v1"))
from icons import optimize


def ui_images(name, scratch):
    with Image.open(ROOT/"icons/original"/(name+".png")) as file:
        source = file.convert("RGBA")
    alpha = source.getchannel("A")
    assert alpha.getextrema() == (0,255), name
    bounds = alpha.point(lambda a: 255 if a>8 else 0).getbbox()
    padded = (max(0,bounds[0]-3),max(0,bounds[1]-3),
              min(source.width,bounds[2]+3),min(source.height,bounds[3]+3))
    subject = source.crop(padded)
    result = {}
    for size, sub in ((512,"ui512"),(256,"small256")):
        fitted = ImageOps.contain(subject,(round(.94*size),round(.94*size)),Image.Resampling.LANCZOS)
        tile = Image.new("RGBA",(size,size))
        tile.paste(fitted,((size-fitted.width)//2,(size-fitted.height)//2))
        raw = scratch/f"{name}-{size}.png"
        tile.save(raw)
        output = ROOT/"icons"/sub/(name+".png")
        result[sub] = optimize(raw,output)
        with Image.open(output) as packed:
            assert packed.size==(size,size)
            opacity = packed.convert("RGBA").getchannel("A")
            assert min(opacity.getbbox()[:2]) >= int(.02*size)
    return result


def review(specs):
    tile_w, tile_h, pad = 376, 250, 14
    sheet = Image.new("RGB",(pad+3*(tile_w+pad),58+2*(tile_h+pad)),"#e9e3dc")
    draw = ImageDraw.Draw(sheet)
    fonts=Path("/System/Library/Fonts/Supplemental")
    title=ImageFont.truetype(str(fonts/"Arial Bold.ttf"),24)
    body=ImageFont.truetype(str(fonts/"Arial.ttf"),15)
    role_font=ImageFont.truetype(str(fonts/"Arial Bold.ttf"),18)
    draw.text((pad,6),"Парящий оскал",font=title,fill="#28232b")
    draw.text((pad,34),"В каждой паре слева модель, справа иконка",font=body,fill="#49424c")
    for i,(name,spec) in enumerate(specs.items()):
        x = pad+(i%3)*(tile_w+pad)
        y = 58+(i//3)*(tile_h+pad)
        draw.rounded_rectangle((x,y,x+tile_w-1,y+tile_h-1),radius=10,fill="#fbf7f0")
        draw.text((x+tile_w//2,y+15),spec["label"],font=role_font,fill="#312935",anchor="mm")
        for j,path in enumerate([ROOT/"previews/cutouts"/(name+".png"),ROOT/"icons/ui512"/(name+".png")]):
            with Image.open(path) as source:
                rgba=source.convert("RGBA")
            art=rgba.crop(rgba.getchannel("A").getbbox())
            art.thumbnail((tile_w//2-14,tile_h-48),Image.Resampling.LANCZOS)
            sheet.paste(art,(x+j*tile_w//2+(tile_w//2-art.width)//2,y+32+(tile_h-40-art.height)//2),art)
    output=ROOT/"previews/Models_and_icons.jpg"
    sheet.save(output,quality=94,subsampling=0,optimize=True)
    return output


if __name__=="__main__":
    specs=json.loads((ROOT/"models.json").read_text())
    valid=json.loads((ROOT/"validation.json").read_text())
    assert len(specs)==6 and len(valid)==12
    with TemporaryDirectory() as folder:
        icons={name:ui_images(name,Path(folder)) for name in specs}
    (ROOT/"icons.json").write_text(json.dumps(icons,indent=2)+"\n")
    preview=review(specs)
    files=[ROOT/"models"/(name+ext) for name in specs for ext in (".glb",".fbx",".blend")]
    files += [ROOT/"icons"/folder/(name+".png") for name in specs for folder in ("ui512","small256")]
    files.append(preview)
    archive=ROOT/"FloatingGrin_6_Forms_and_Icons.zip"
    with ZipFile(archive,"w",ZIP_DEFLATED,compresslevel=9) as z:
        for path in files: z.write(path,path.relative_to(ROOT))
    with ZipFile(archive) as z:
        assert z.testzip() is None and len(z.namelist())==31
        assert all(z.read(str(p.relative_to(ROOT)))==p.read_bytes() for p in files)
    print(archive.name,archive.stat().st_size,"bytes")
