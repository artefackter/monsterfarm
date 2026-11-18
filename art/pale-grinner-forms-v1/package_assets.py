"""Export square UI icons and build the standalone art review package."""
import json
import zipfile
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parent
MODELS = json.loads((ROOT / "report.json").read_text())["models"]
FONT_DIR = Path("/System/Library/Fonts/Supplemental")


def export_icon(name):
    path = ROOT / "icons" / "original" / f"{name}.png"
    with Image.open(path) as source:
        image = source.convert("RGBA")
    alpha = image.getchannel("A")
    if alpha.getextrema() != (0, 255):
        raise ValueError(f"Expected transparent and opaque areas in {name}")
    bounds = alpha.point(lambda a: 255 if a > 5 else 0).getbbox()
    x0, y0, x1, y1 = bounds
    subject = image.crop((max(0, x0-2), max(0, y0-2),
                          min(image.width, x1+2), min(image.height, y1+2)))
    dimensions = {}
    for subdirectory, size in (("ui512", 512), ("small256", 256)):
        fitted = ImageOps.contain(subject, (round(.94*size), round(.94*size)),
                                  Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", (size, size))
        canvas.paste(fitted, ((size-fitted.width)//2, (size-fitted.height)//2))
        pixels = np.array(canvas)
        rgb = pixels[:, :, :3]
        rgb[:] = np.clip(np.rint(rgb.astype(float)/4)*4, 0, 255).astype(np.uint8)
        rgb[pixels[:, :, 3] == 0] = 0
        dest = ROOT / "icons" / subdirectory / path.name
        Image.fromarray(pixels).save(dest, optimize=True, compress_level=9)
        with Image.open(dest) as check:
            check.load()
            assert check.size == (size, size)
            assert check.getchannel("A").tobytes() == canvas.getchannel("A").tobytes()
        dimensions[subdirectory] = {"size_px": size, "file_bytes": dest.stat().st_size}
    return dimensions


def compose_review():
    previews = ROOT / "previews"
    panel_width, panel_height = 432, 346
    gap, margin, heading = 12, 24, 70
    paper, ink = "#f3ece1", "#26222a"
    font = ImageFont.truetype(str(FONT_DIR / "Arial Bold.ttf"), 29)
    label = ImageFont.truetype(str(FONT_DIR / "Arial Bold.ttf"), 21)
    small = ImageFont.truetype(str(FONT_DIR / "Arial.ttf"), 16)
    sheet = Image.new("RGB", (margin*2+panel_width*3+gap*2,
                              margin*2+heading+panel_height*2+gap), paper)
    draw = ImageDraw.Draw(sheet)
    draw.text((margin, margin-5), "Бледный оскал", font=font, fill=ink)
    draw.text((margin, margin+32), "3D-модель и 2D-иконка каждого образа", font=small, fill=ink)
    grid = Image.new("RGB", (330*3, 430*2), "#202a33")
    grid_draw = ImageDraw.Draw(grid)
    for i, (name, spec) in enumerate(MODELS.items()):
        col, row = i % 3, i // 3
        x = margin+col*(panel_width+gap)
        y = margin+heading+row*(panel_height+gap)
        half = panel_width//2
        with Image.open(previews / f"{name}_Front.png") as source:
            model = source.convert("RGB")
        sheet.paste(ImageOps.fit(model, (half, 300)), (x, y))
        draw.rectangle((x+half, y, x+panel_width-1, y+299), fill="#d8cbb9")
        with Image.open(ROOT / "icons" / "ui512" / f"{name}.png") as source:
            artwork = source.crop(source.getchannel("A").getbbox())
            artwork.thumbnail((half-12, 273), Image.Resampling.LANCZOS)
        sheet.paste(artwork, (x+half+(half-artwork.width)//2, y+(300-artwork.height)//2), artwork)
        draw.text((x+panel_width//2, y+321), spec["label"], font=label, fill=ink, anchor="mm")
        model.thumbnail((330, 396), Image.Resampling.LANCZOS)
        grid.paste(model, (330*col, 430*row))
        grid_draw.text((330*col+165, 430*row+411),spec["label"],font=label,fill="white",anchor="mm")
    grid.save(previews / "Models.jpg", quality=90)
    sheet.save(previews / "Models_and_icons.jpg", quality=93, subsampling=0)


def main():
    validation = json.loads((ROOT / "validation.json").read_text())
    assert validation["passed"] and validation["results"].keys() == MODELS.keys()
    manifest = {}
    for name, spec in MODELS.items():
        manifest[name] = {**spec, "icons": export_icon(name)}
    (ROOT / "assets.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+"\n")
    compose_review()
    package = ROOT / "PaleGrinner_6_Forms_and_Icons.zip"
    with zipfile.ZipFile(package, "w", zipfile.ZIP_DEFLATED, compresslevel=7) as archive:
        for folder in ("models", "icons", "previews"):
            for path in sorted((ROOT / folder).rglob("*")):
                if path.is_file() and not path.name.startswith("."):
                    archive.write(path, path.relative_to(ROOT))
        for name in ("assets.json", "validation.json"):
            archive.write(ROOT / name, name)
    with zipfile.ZipFile(package) as archive:
        assert archive.testzip() is None
    print(f"{len(MODELS)} models and icons, {package.stat().st_size:,} bytes")


if __name__ == "__main__":
    main()
