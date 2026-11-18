"""A collar-anchored neck with a fully extended bind pose and one lunge clip."""
from math import atan2, cos, pi, sin

import bpy
import bmesh
from mathutils import Matrix, Vector


REST = [Vector(p) for p in ((0,-.12,4.76),(0,-.12,5.06),(0,-.05,5.41),(0,-.035,5.75))]
THRUST = [Vector(p) for p in ((0,-.12,4.76),(0,-.12,5.83),(0,-1.62,4.98),(0,-2.135,5.35))]
HINGE = Vector((0,-.08,5.508))
TRAVEL = Vector((0,-2.10,-.40))
PITCH = .115
JOINTS = 7


def cervical(t,amount):
    a,b,c,d = [p.lerp(q,amount) for p,q in zip(REST,THRUST)]
    u = 1-t
    center = u**3*a+3*u*u*t*b+3*u*t*t*c+t**3*d
    tangent = u*u*(b-a)+2*t*u*(c-b)+t*t*(d-c)
    return center,atan2(-tangent.y,tangent.z)


def head_transform(amount):
    return (Matrix.Translation(HINGE+amount*TRAVEL) @ Matrix.Rotation(amount*PITCH,4,'X')
            @ Matrix.Translation(-HINGE))


def joint_name(i):
    return f"Cervical_{i+1:02}"


def extend_skeleton(bones):
    bones["Head"].transform(head_transform(1),scale=False)
    for i in range(JOINTS):
        joint = bones.new(joint_name(i))
        center,_ = cervical(i/(JOINTS-1),1)
        joint.head = center
        joint.tail = center+Vector((0,0,.09))
        joint.parent = bones["Neck"]


def new_neck(rig,material):
    coords,faces,weights,colors = [],[],[],[]
    slices, sides = 30,24
    for row in range(slices+1):
        t = row/slices
        center,tilt = cervical(t,1.)
        rot = Matrix.Rotation(tilt,3,'X')
        joint_pos = t*(JOINTS-1)
        lo=min(int(joint_pos),JOINTS-2)
        blend=joint_pos-lo
        for col in range(sides):
            a=2*pi*col/sides
            # The paired lateral tendons run along the neck into the jaw.
            tendon=(max(0.,cos(2*a+.85-1.8*t))**6)*sin(pi*t)
            radius=.193+.145*(1-t)**2+.096*t**3+.036*tendon
            point=center+rot@Vector((radius*cos(a),radius*.88*sin(a),0))
            coords.append(point)
            weights.append({joint_name(lo):1-blend,joint_name(lo+1):blend})
            tone=.85+.055*cos(a+.8)+.09*tendon+.045*t
            colors.append((.80*tone,.765*tone,.714*tone,1))
        if row:
            a=(row-1)*sides
            for j in range(sides):
                k=(j+1)%sides
                faces.append((a+j,a+k,a+k+sides,a+j+sides))
    faces.extend([tuple(reversed(range(sides))),tuple(range(slices*sides,(slices+1)*sides))])
    # Fixed triangular throat inset follows the V of the shirt below the moving neck.
    start=len(coords)
    for row,(z,cx,cy,ry) in enumerate(((4.77,.018,-.548,.02),(4.90,.105,-.488,.053),
                                         (5.04,.202,-.391,.092),(5.15,.22,-.289,.123))):
        for j in range(16):
            a=2*pi*j/16
            coords.append(Vector((cx*cos(a),cy+ry*sin(a),z)))
            weights.append({"Chest":1})
            colors.append((.72,.686,.628,1))
        if row:
            b=start+16*(row-1)
            for j in range(16):
                k=(j+1)%16
                faces.append((b+j,b+k,b+k+16,b+j+16))
    faces.extend([tuple(reversed(range(start,start+16))),tuple(range(start+48,start+64))])
    data=bpy.data.meshes.new("Continuous neck")
    data.from_pydata(coords,[],faces)
    bm=bmesh.new();bm.from_mesh(data)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    bm.to_mesh(data);bm.free()
    obj=bpy.data.objects.new("Continuous neck",data)
    rig.users_collection[0].objects.link(obj)
    obj.parent=rig
    data.materials.append(material)
    for f in data.polygons: f.use_smooth=True
    col=data.color_attributes.new(name="Col",type="BYTE_COLOR",domain="POINT")
    groups={name:obj.vertex_groups.new(name=name) for name in [*(joint_name(i) for i in range(JOINTS)),"Chest"]}
    for i,(w,color) in enumerate(zip(weights,colors)):
        col.data[i].color_srgb=color
        for name,value in w.items():
            if value>1e-7: groups[name].add([i],value,'REPLACE')
    return obj


def animate(rig,scene):
    scene.frame_start,scene.frame_end,scene.render.fps=1,37,30
    extended=head_transform(1).inverted()
    # Curves are sampled because neck orientation follows the derivative of a cubic.
    timing=[(1,0.),(5,0.),(14,1.),(19,1.),(37,0.)]
    for frame in range(1,38):
        for (a,v),(b,w) in zip(timing,timing[1:]):
            if a<=frame<=b:
                u=(frame-a)/(b-a)
                amount=v+(w-v)*u*u*(3-2*u)
                break
        mapping={"Head":head_transform(amount)@extended}
        for i in range(JOINTS):
            t=i/(JOINTS-1)
            center0,angle0=cervical(t,1.)
            center,angle=cervical(t,amount)
            mapping[joint_name(i)]=(Matrix.Translation(center) @ Matrix.Rotation(angle-angle0,4,'X')
                                    @ Matrix.Translation(-center0))
        for name,delta in mapping.items():
            bone=rig.pose.bones[name]
            bind=bone.bone.matrix_local
            # All moving joints have the unmoving Neck bone as their immediate parent.
            bone.matrix_basis=bind.inverted()@delta@bind
            bone.keyframe_insert(data_path="location",frame=frame,group=name)
            bone.keyframe_insert(data_path="rotation_quaternion",frame=frame,group=name)
    rig.animation_data.action.name="HeadLunge"
    scene.frame_set(14)
