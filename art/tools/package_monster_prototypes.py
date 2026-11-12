"""Write the vertex-coloured game meshes and their named attachment groups."""
import hashlib
import json
import math
import struct


def write_pack(folder, manifest, rig, triangle_count, *, weapons=False, floating=()):
    binary = bytearray()
    views, accessors, meshes, nodes, roots = [], [], [], [], []

    def accessor(values, fmt, component, kind, count, target, **bounds):
        binary.extend(b"\0" * (-len(binary) % 4))
        data = struct.pack(f"<{len(values)}{fmt}", *values)
        views.append({"buffer":0, "byteOffset":len(binary), "byteLength":len(data),
                      "target":target})
        binary.extend(data)
        accessors.append({"bufferView":len(views)-1,"componentType":component,
                          "count":count,"type":kind,**bounds})
        return len(accessors)-1

    def linear(byte):
        value=byte/255
        return value/12.92 if value<=.04045 else ((value+.055)/1.055)**2.4

    per_model={}
    for i,(name, parts) in enumerate(manifest.items()):
        children=[]
        part_names={p["part"] for p in parts}
        if weapons:
            assert "Main" in part_names and {"Grip","SupportHand","Muzzle"} <= set(rig[name]), name
        elif name in floating:
            assert {"Body","Head","ArmL","ArmR"} <= part_names, name
            assert {"Head","ArmL","ArmR"} <= set(rig[name]), name
            assert not {"LegL","LegR"} & part_names, name
            assert next(p for p in parts if p["part"]=="Body")["transparency"]==1, name
        else:
            assert {"Body","Head","ArmL","ArmR","LegL","LegR"} <= part_names, name
            assert {"Head","ArmL","ArmR","LegL","LegR"} <= set(rig[name]), name
        assert len(part_names)==len(parts)
        for part in parts:
            mesh_name=part["mesh"]
            assert weapons or part["attach"] in part_names, mesh_name
            mesh=json.loads((folder/(mesh_name+".json")).read_text())
            vertices, normals, colors, triangles=(mesh[k] for k in ("v","n","c","t"))
            n=len(colors)
            assert len(vertices)==len(normals)==n*3
            assert 0<len(triangles)<=30000 and len(triangles)%3==0
            assert all(math.isfinite(x) for x in vertices+normals)
            assert all(0<=j<n for j in triangles)
            minimum=[min(vertices[j::3]) for j in range(3)]
            maximum=[max(vertices[j::3]) for j in range(3)]
            pos=accessor(vertices,"f",5126,"VEC3",n,34962,min=minimum,max=maximum)
            nor=accessor(normals,"f",5126,"VEC3",n,34962)
            rgba=[channel for rgb in colors for channel in
                  (linear(rgb>>16&255),linear(rgb>>8&255),linear(rgb&255),1)]
            col=accessor(rgba,"f",5126,"VEC4",n,34962)
            indices=accessor(triangles,"I",5125,"SCALAR",len(triangles),34963)
            meshes.append({"name":mesh_name,"primitives":[{
                "attributes":{"POSITION":pos,"NORMAL":nor,"COLOR_0":col},
                "indices":indices,"material":0,
            }]})
            children.append(len(nodes))
            nodes.append({"name":f"{name}__{part['part']}","mesh":len(meshes)-1,
                          "translation":part["offset"],"extras":{"attach":part["attach"]}})
        roots.append(len(nodes))
        nodes.append({"name":name,"children":children,"translation":[i*7,0,0]})
        per_model[name]={"parts":len(parts),"triangles":sum(p["tris"] for p in parts)}

    document={"asset":{"version":"2.0","generator":"Grow a Monster prototype pack"},
              "scene":0,"scenes":[{"name":"MonsterPrototypes","nodes":roots}],
              "nodes":nodes,"meshes":meshes,"accessors":accessors,"bufferViews":views,
              "buffers":[{"byteLength":len(binary)}],
              "materials":[{"name":"Vertex colors","pbrMetallicRoughness":{
                  "baseColorFactor":[1,1,1,1],"metallicFactor":0,"roughnessFactor":.79}}]}
    encoded=json.dumps(document,separators=(",",":")).encode()
    encoded+=b" "*(-len(encoded)%4)
    binary.extend(b"\0"*(-len(binary)%4))
    path=folder/("WeaponPrototypes.glb" if weapons else "MonsterPrototypes.glb")
    path.write_bytes(struct.pack("<III",0x46546C67,2,28+len(encoded)+len(binary))
                     +struct.pack("<II",len(encoded),0x4E4F534A)+encoded
                     +struct.pack("<II",len(binary),0x004E4942)+binary)
    data=path.read_bytes()
    assert len(data)==struct.unpack_from("<I",data,8)[0]
    return path,{"assets":per_model,"meshCount":len(meshes),"triangles":triangle_count,
                 "bytes":len(data),"sha256":hashlib.sha256(data).hexdigest()}
