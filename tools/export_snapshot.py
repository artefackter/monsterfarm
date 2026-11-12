#!/usr/bin/env python3
"""Export a saved Studio place into this repository. Never opens or runs Studio."""
import argparse
import copy
import hashlib
import json
import subprocess
import tempfile
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
SERVICES = (
    "Workspace ReplicatedStorage ReplicatedFirst ServerScriptService ServerStorage "
    "StarterPlayer StarterGui StarterPack Lighting SoundService MaterialService Teams "
    "TextChatService LocalizationService Players HttpService PhysicsService"
).split()
SOURCE_ROOTS = {
    ("ReplicatedStorage", "Shared"): "src/shared",
    ("ServerScriptService",): "src/server",
    ("StarterPlayer", "StarterPlayerScripts"): "src/client",
    ("StarterPlayer", "StarterCharacterScripts"): "src/character",
}


def write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def name(item):
    return item.findtext('./Properties/*[@name="Name"]')


def scripts(root):
    result = []

    def walk(item, parents):
        parts = parents + (name(item),)
        for prefix, folder in SOURCE_ROOTS.items():
            if parts[:len(prefix)] != prefix:
                continue
            if item.attrib["class"] in ("Script", "LocalScript", "ModuleScript"):
                suffix = {"Script": ".server.lua", "LocalScript": ".client.lua", "ModuleScript": ".lua"}[item.attrib["class"]]
                relative = Path(folder).joinpath(*parts[len(prefix):]).with_suffix(suffix)
                source = item.findtext('./Properties/*[@name="Source"]', "")
                result.append((".".join(parts), relative, source, item))
                break
        for child in item.findall("Item"):
            walk(child, parts)

    for service in root.findall("Item"):
        walk(service, ())
    return result


def export_xml(xml_path):
    root = ET.parse(xml_path).getroot()
    entries = scripts(root)
    manifest = []
    for studio_path, relative, source, item in entries:
        target = ROOT / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(source.encode("utf-8"))
        properties = {}
        for prop in item.findall("./Properties/*"):
            key = prop.attrib["name"]
            if key == "Disabled":
                properties[key] = prop.text == "true"
            elif key == "RunContext" and item.attrib["class"] == "Script":
                properties[key] = {"Enum": int(prop.text)}
        if properties:
            write_json(target.with_name(target.name[:-4] + ".meta.json"), {"properties": properties})
        raw = source.encode("utf-8")
        manifest.append({"studioPath": studio_path, "file": relative.as_posix(), "className": item.attrib["class"], "bytes": len(raw), "sha256": hashlib.sha256(raw).hexdigest()})

    # Keep every non-code service object and its settings. The original binary
    # snapshot remains the lossless source of truth for engine properties that
    # this version of Rojo cannot decode (e.g. the new Terrain content-map type).
    shared_strings = root.find("SharedStrings")
    tree = {"$className": "DataModel"}
    for original in root.findall("Item"):
        service = copy.deepcopy(original)
        service_name = name(service)
        if service_name not in SERVICES:
            continue
        if service_name == "ReplicatedStorage":
            for child in list(service.findall("Item")):
                if name(child) == "Shared":
                    service.remove(child)
        elif service_name == "ServerScriptService":
            for child in list(service.findall("Item")):
                service.remove(child)
        elif service_name == "StarterPlayer":
            for child in list(service.findall("Item")):
                if name(child) in ("StarterPlayerScripts", "StarterCharacterScripts"):
                    service.remove(child)
        model = ET.Element("roblox", {"version": "4"})
        model.append(service)
        needed = {x.text for x in service.iter("SharedString")}
        if needed and shared_strings is not None:
            strings = ET.SubElement(model, "SharedStrings")
            for value in shared_strings:
                if value.attrib.get("md5") in needed:
                    strings.append(copy.deepcopy(value))
        model_path = ROOT / "assets/runtime" / (service_name + ".rbxmx")
        model_path.parent.mkdir(parents=True, exist_ok=True)
        ET.ElementTree(model).write(model_path, encoding="utf-8", xml_declaration=True)
        tree[service_name] = {"$path": model_path.relative_to(ROOT).as_posix()}

    tree["ReplicatedStorage"]["Shared"] = {"$path": "src/shared"}
    tree["ServerScriptService"] = {"$className": "ServerScriptService", "$path": "src/server"}
    tree["StarterPlayer"]["StarterPlayerScripts"] = {"$className": "StarterPlayerScripts", "$path": "src/client"}
    tree["StarterPlayer"]["StarterCharacterScripts"] = {"$className": "StarterCharacterScripts", "$path": "src/character"}
    write_json(ROOT / "default.project.json", {"name": "GrowAMonster", "tree": tree})
    write_json(ROOT / "metadata/source-map.json", sorted(manifest, key=lambda x: x["studioPath"]))
    return root, manifest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("snapshot", type=Path)
    parser.add_argument("--rojo", default="rojo")
    args = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix="growamonster-export-") as temporary:
        temporary = Path(temporary)
        tree = {"$className": "DataModel"}
        for service in SERVICES:
            (temporary / "game" / service).mkdir(parents=True)
            tree[service] = {"$className": service, "$path": "game/" + service}
        project = temporary / "default.project.json"
        write_json(project, {"name": "GrowAMonsterExport", "tree": tree, "syncbackRules": {"syncCurrentCamera": True, "syncUnscriptable": True}})
        subprocess.run([args.rojo, "syncback", str(project), "--input", str(args.snapshot.resolve()), "-y"], check=True)
        xml = temporary / "decoded.rbxlx"
        subprocess.run([args.rojo, "build", str(project), "-o", str(xml)], check=True)
        _, manifest = export_xml(xml)
        print(f"Exported {len(manifest)} production scripts and service models. Play was not started.")


if __name__ == "__main__":
    main()
