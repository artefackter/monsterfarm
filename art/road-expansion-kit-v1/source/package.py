"""Build a deterministic ZIP of the kit after regenerating models and previews."""
from pathlib import Path
from tempfile import TemporaryDirectory
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

ROOT = Path(__file__).resolve().parents[1]
CONTENTS = (
    'ASSEMBLY.md', 'index.html', 'catalog.json', 'layouts.json',
    'models/*/*.glb', 'samples/*.glb', 'sky/*.png', 'textures/*.png',
    'previews/*.jpg', 'source/*.py',
)


def main():
    target = ROOT / 'Road_Expansion_Kit_v1.zip'
    paths = sorted(path for pattern in CONTENTS for path in ROOT.glob(pattern))
    with TemporaryDirectory(dir=ROOT) as temp:
        output = Path(temp) / target.name
        with ZipFile(output, 'w') as archive:
            for path in paths:
                entry = ZipInfo(path.relative_to(ROOT).as_posix())
                entry.create_system = 3
                entry.external_attr = 0o100644 << 16
                archive.writestr(entry, path.read_bytes(), ZIP_DEFLATED, compresslevel=9)
        with ZipFile(output) as archive:
            if archive.testzip() is not None:
                raise ValueError('Archive CRC check failed')
        output.replace(target)


if __name__ == '__main__':
    main()
