#!/usr/bin/env python3
"""Pack art/export/*.json into one .glb for Studio's File > Import 3D.

Each mesh is its own node named `<Asset>__<Part>`; the importer turns each node into one MeshPart.
Vertices are already in Roblox axes and centred on their bounding box.
COLOR_0 is written in sRGB-as-stored because _Probe verifies how the importer treats it.
"""
import json, os, struct, sys, argparse
parser=argparse.ArgumentParser()
parser.add_argument("--linear",action="store_true")
parser.add_argument("--manifest",help="Only package meshes listed in this manifest")
parser.add_argument("--name",default="DigAZombie_Art")
args=parser.parse_args()

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "export"))
OUT = os.path.join(ROOT, args.name+".glb")
GAMMA_LINEAR = "--linear" in sys.argv  # store colours as linear (spec) instead of raw sRGB


def to_linear(x):
    return x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4


def main():
    names = sorted(f[:-5] for f in os.listdir(ROOT) if f.endswith(".json") and not f.startswith("_"))
    if args.manifest:
        selected=json.load(open(args.manifest))
        wanted={p["mesh"] for parts in selected.values() for p in parts}
        names=[n for n in names if n in wanted]
        assert set(names)==wanted,"Missing mesh JSON"
    meshes = [json.load(open(os.path.join(ROOT, n + ".json"))) for n in names]
    # probe: a small quad of known colours, read back after import to learn the colour handling
    probe = {"name": "_Probe.Main", "v": [-1, 0, -1, 1, 0, -1, 1, 0, 1, -1, 0, 1], "n": [0, 1, 0] * 4,
             "c": [0x808080, 0x404040, 0xC08040, 0xFFFFFF], "t": [0, 2, 1, 0, 3, 2]}
    if not args.manifest: meshes.append(probe)
    blob = bytearray()
    views, accessors, gmeshes, nodes = [], [], [], []

    def add(data, target, ctype, count, atype, **extra):
        while len(blob) % 4:
            blob.append(0)
        views.append({"buffer": 0, "byteOffset": len(blob), "byteLength": len(data), **({"target": target} if target else {})})
        blob.extend(data)
        accessors.append({"bufferView": len(views) - 1, "componentType": ctype, "count": count, "type": atype, **extra})
        return len(accessors) - 1

    for m in meshes:
        v, n, c, t = m["v"], m["n"], m["c"], m["t"]
        count = len(v) // 3
        xs, ys, zs = v[0::3], v[1::3], v[2::3]
        pos = add(struct.pack(f"<{len(v)}f", *v), 34962, 5126, count, "VEC3",
                  min=[min(xs), min(ys), min(zs)], max=[max(xs), max(ys), max(zs)])
        nor = add(struct.pack(f"<{len(n)}f", *n), 34962, 5126, count, "VEC3")
        col = []
        for rgb in c:
            r, g, b = (rgb >> 16 & 255) / 255, (rgb >> 8 & 255) / 255, (rgb & 255) / 255
            if GAMMA_LINEAR:
                r, g, b = to_linear(r), to_linear(g), to_linear(b)
            col += [r, g, b, 1.0]
        colr = add(struct.pack(f"<{len(col)}f", *col), 34962, 5126, count, "VEC4")
        idx = add(struct.pack(f"<{len(t)}I", *t), 34963, 5125, len(t), "SCALAR")
        gmeshes.append({"name": m["name"], "primitives": [{"attributes": {"POSITION": pos, "NORMAL": nor, "COLOR_0": colr}, "indices": idx, "material": 0}]})
        nodes.append({"name": m["name"].replace(".", "__"), "mesh": len(gmeshes) - 1})
    while len(blob) % 4:
        blob.append(0)
    gltf = {
        "asset": {"version": "2.0", "generator": "DigAZombie art pipeline"},
        "scene": 0, "scenes": [{"name": args.name, "nodes": list(range(len(nodes)))}],
        "nodes": nodes, "meshes": gmeshes, "accessors": accessors, "bufferViews": views,
        "buffers": [{"byteLength": len(blob)}],
        "materials": [{"name": "Art", "pbrMetallicRoughness": {"baseColorFactor": [1, 1, 1, 1], "metallicFactor": 0, "roughnessFactor": 0.8}}],
    }
    js = json.dumps(gltf, separators=(",", ":")).encode()
    js += b" " * ((4 - len(js) % 4) % 4)
    with open(OUT, "wb") as f:
        f.write(struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(blob)))
        f.write(struct.pack("<II", len(js), 0x4E4F534A)); f.write(js)
        f.write(struct.pack("<II", len(blob), 0x004E4942)); f.write(blob)
    print(f"{OUT}: {len(nodes)} meshes, {os.path.getsize(OUT) / 1e6:.1f} MB, colours {'linear' if GAMMA_LINEAR else 'sRGB as stored'}")


main()
