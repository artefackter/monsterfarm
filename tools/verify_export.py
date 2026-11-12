#!/usr/bin/env python3
"""Verify the exported snapshot, production sources, and an optional Rojo build."""
import argparse
import hashlib
import json
import subprocess
import tempfile
from pathlib import Path
import xml.etree.ElementTree as ET
from export_snapshot import ROOT, name, scripts


def artlib(root):
    storage = next(x for x in root.findall("Item") if name(x) == "ReplicatedStorage")
    library = next(x for x in storage.findall("Item") if name(x) == "ArtLib")
    keys = {"MeshId", "MeshContent", "TextureID", "TextureContent", "Size", "size", "CFrame", "Material", "Transparency", "Color", "Color3uint8", "CanCollide", "Anchored"}
    return {name(x): {"class": x.attrib["class"], "properties": {p.attrib["name"]: ET.tostring(p, encoding="unicode").strip() for p in x.findall("Properties/*") if p.attrib["name"] in keys}} for x in library.findall("Item")}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rojo", help="Also build the complete project, using this Rojo executable")
    parser.add_argument("--luau-compile", help="Also compile every production script")
    args = parser.parse_args()
    checksums = ROOT / "metadata/checksums.sha256"
    if checksums.exists():
        for line in checksums.read_text(encoding="utf-8").splitlines():
            digest, relative = line.split("  ", 1)
            assert hashlib.sha256((ROOT / relative).read_bytes()).hexdigest() == digest, f"Snapshot changed: {relative}"
    manifest = json.loads((ROOT / "metadata/source-map.json").read_text(encoding="utf-8"))
    for entry in manifest:
        raw = (ROOT / entry["file"]).read_bytes()
        assert len(raw) == entry["bytes"], entry["file"]
        assert hashlib.sha256(raw).hexdigest() == entry["sha256"], entry["file"]
    assert len(list((ROOT / "src").rglob("*.lua"))) == len(manifest)
    if args.luau_compile:
        for entry in manifest:
            result = subprocess.run([args.luau_compile, str(ROOT / entry["file"])], capture_output=True)
            assert result.returncode == 0, entry["file"] + ": " + result.stderr.decode(errors="replace")
    if args.rojo:
        with tempfile.TemporaryDirectory(prefix="growamonster-verify-") as temporary:
            place = Path(temporary) / "build.rbxlx"
            subprocess.run([args.rojo, "build", str(ROOT / "default.project.json"), "-o", str(place)], check=True)
            built = ET.parse(place).getroot()
            expected = {entry["studioPath"]: entry for entry in manifest}
            actual = scripts(built)
            assert len(actual) == len(expected)
            for path, _, source, item in actual:
                entry = expected[path]
                assert item.attrib["class"] == entry["className"], path
                assert hashlib.sha256(source.encode("utf-8")).hexdigest() == entry["sha256"], path
            baseline = json.loads((ROOT / "metadata/artlib-templates.json").read_text(encoding="utf-8"))
            assert artlib(built) == baseline, "ArtLib differs from the Studio snapshot"
            assert not any(name(x) == "GitDealerReviewGallery" for x in built.iter("Item"))
            print(f"Rojo build: {len(actual)} production scripts; {len(baseline)} ArtLib templates match.")
    print(f"PASS: {len(manifest)} production scripts; snapshot integrity verified. Play was not started.")


if __name__ == "__main__":
    main()
