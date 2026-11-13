"""Package the approved local geometry as a standalone Roblox Model.

No Studio connection, uploads, runtime-source edits or project-file changes.
Run with Python 3 after build.py if geometry is regenerated.
"""
import json
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent
SHAPES = {"Ball": 0, "Block": 1, "Cylinder": 2}
MATERIALS = {"SmoothPlastic": 272, "Metal": 1088, "Wood": 512, "Neon": 288}
CF_FIELDS = ["X", "Y", "Z"] + [f"R{i}{j}" for i in range(3) for j in range(3)]


def prop(parent, kind, name, value):
    ET.SubElement(parent, kind, name=name).text = str(value)


def export():
    rows = json.loads((ROOT / "parts.json").read_text())
    root = ET.Element("roblox", version="4")
    model = ET.SubElement(root, "Item", {"class": "Model", "referent": "RBXWorkbench"})
    props = ET.SubElement(model, "Properties")
    prop(props, "string", "Name", "WeaponWorkbench")
    # Explicit ground-centre pivot makes manual placement straightforward.
    pivot = ET.SubElement(props, "OptionalCoordinateFrame", name="WorldPivotData")
    frame = ET.SubElement(pivot, "CFrame")
    for field, value in zip(CF_FIELDS, [0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1]):
        ET.SubElement(frame, field).text = str(value)
    for index, row in enumerate(rows):
        item = ET.SubElement(model, "Item", {"class": "Part", "referent": f"RBXPart{index}"})
        props = ET.SubElement(item, "Properties")
        prop(props, "string", "Name", row["name"])
        for key, value in (("Anchored", "true"), ("CanCollide", "false"),
                           ("CanTouch", "false"), ("CanQuery", "false")):
            prop(props, "bool", key, value)
        prop(props, "Color3uint8", "Color3uint8", int(row["color"], 16))
        prop(props, "token", "Material", MATERIALS[row["material"]])
        prop(props, "token", "shape", SHAPES[row["shape"]])
        for key in ("TopSurface", "BottomSurface"):
            prop(props, "token", key, 0)
        size = ET.SubElement(props, "Vector3", name="size")
        for axis, value in zip(("X", "Y", "Z"), row["size"]):
            ET.SubElement(size, axis).text = format(value, ".9g")
        frame = ET.SubElement(props, "CoordinateFrame", name="CFrame")
        for field, value in zip(CF_FIELDS, row["cf"]):
            ET.SubElement(frame, field).text = format(value, ".9g")
    ET.indent(root)
    target = ROOT / "WeaponWorkbench.rbxmx"
    ET.ElementTree(root).write(target, encoding="utf-8", xml_declaration=True)
    print(f"Exported {target.name}: one Model, {len(rows)} anchored Parts, no scripts.")


if __name__ == "__main__":
    export()
