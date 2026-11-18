"""Single continuous palm and five individually skinned digits per hand."""
from math import cos, exp, pi, sin

import bmesh
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree


def make_hand(side, rig, material):
    sign = 1 if side == "R" else -1
    hand = "Hand" + side
    wrist = rig.data.bones[hand].head_local.copy()
    points, faces, weights, anchors = [], [], [], {}
    nails, knuckles = {}, []

    def world(co):
        x, y, depth = co
        return wrist + Vector((sign*x, y, -depth))

    def add(co, groups=None):
        points.append(Vector(co))
        weights.append(groups or {hand: 1})
        return len(points)-1

    def bridge(a, b):
        for i in range(len(a)):
            j = (i+1) % len(a)
            faces.append((a[i], a[j], b[j], b[i]))

    # Four lanes across the knuckles. Each finger shares its root edges with
    # its neighbours, leaving flexible skin between the fingers.
    front, back, flanks = [], [], []
    for level, (depth, center, width, thickness) in enumerate((
            (-.10, -.021, .092, .082), (.075, .012, .145, .119),
            (.177, .040, .198, .130), (.275, .058, .222, .124),
            (.377, .070, .214, .093))):
        rows = [[], []]
        for k in range(9):
            u = (k-4)/4
            x = center + width*u
            y = -.12*depth + .043*u
            d = depth - max(0,level-2)*(.020*u*u + .009*u)
            for surface, row in enumerate(rows):
                direction = 1 if surface else -1
                row.append(add((x, y+direction*thickness*(1-.36*u*u), d)))
        front.append(rows[0]); back.append(rows[1])
        flanks.append([add((points[rows[0][k]]+points[rows[1][k]])/2) for k in (0,8)])
        if level:
            for sheet in (front, back):
                for k in range(8):
                    faces.append((sheet[-2][k], sheet[-2][k+1], sheet[-1][k+1], sheet[-1][k]))
            for flank, col in ((0,0),(1,8)):
                if flank == 0 and level in (2,3):
                    continue  # open socket for the opposed thumb
                for sheet in (front,back):
                    faces.append((sheet[-2][col],sheet[-1][col],flanks[-1][flank],flanks[-2][flank]))
    top = [*front[0],flanks[0][1],*reversed(back[0]),flanks[0][0]]
    pole = add(sum((points[i] for i in top), Vector()) / len(top))
    for i,a in enumerate(top):
        faces.append((a,top[(i+1)%len(top)],pole))

    webs = {0:flanks[-1][0],8:flanks[-1][1]}
    for k in (2,4,6):
        webs[k] = add((points[front[-1][k]]+points[back[-1][k]])/2)

    def digit(index, root, path, radii, initial_axis, across):
        bone = hand+"Finger"+str(index if sign>0 else 4-index)
        base = sum((points[i] for i in root),Vector())/len(root)
        centers = [base]+[base+Vector(offset) for offset in path]
        anchors[bone] = (world(base),world(centers[-1]))
        tip=world(centers[-1]); distal=world(centers[-4])
        nails[bone]=(distal.lerp(tip,.46), (tip-distal).normalized(), radii[-3]*.58)
        knuckles.extend((world(base),world(centers[3])))
        a = Vector(across).normalized()
        tangent = Vector(initial_axis).normalized()
        a = (a-tangent*a.dot(tangent)).normalized()
        b = tangent.cross(a)
        spokes = []
        for ident in root:
            delta = points[ident]-base
            spokes.append(Vector((delta.dot(a),delta.dot(b))).normalized())
        old = root
        for j,(center,radius) in enumerate(zip(centers[1:],radii),1):
            tangent = (centers[min(j+1,len(centers)-1)]-centers[j-1]).normalized()
            axis = (a-tangent*a.dot(tangent)).normalized()
            normal = tangent.cross(axis)
            w = .65 if j == 1 else 1.
            loop = [add(center + radius*(axis*p.x+normal*p.y*.88),
                        {hand:1-w,bone:w}) for p in spokes]
            bridge(old,loop)
            old = loop
        tip = add(centers[-1]+tangent*.010,{bone:1})
        for j,idx in enumerate(old):
            faces.append((idx,old[(j+1)%len(old)],tip))

    for finger,(length,spread,curl,radius) in enumerate((
            (.465,-.048,.056,.059),(.515,-.012,.083,.061),
            (.458,.028,.103,.058),(.347,.061,.114,.050)),1):
        k = (finger-1)*2
        root = [*front[-1][k:k+3],webs[k+2],*reversed(back[-1][k:k+3]),webs[k]]
        path = [(spread*t, curl*t*t*1.65-.031*sin(pi*t), length*t)
                for t in (.12,.38,.55,.76,.91,.98,1.)]
        digit(finger,root,path,[radius*n for n in (1,.88,.94,.78,.73,.57,.32)],
              (0,0,1),(1,0,0))
    thumb_root = [front[1][0],front[2][0],front[3][0],flanks[3][0],
                  back[3][0],back[2][0],back[1][0],flanks[1][0]]
    digit(0,thumb_root,[(-.061,.012,.040),(-.111,.018,.098),(-.158,.045,.17),
          (-.19,.084,.232),(-.197,.113,.263),(-.197,.128,.273)],
          [.089,.080,.073,.065,.051,.029],(-1,0,.65),(0,1,0))

    data = bpy.data.meshes.new(hand+"_Skin")
    data.from_pydata([world(p) for p in points],[],faces)
    obj = bpy.data.objects.new(hand+"_Skin",data)
    rig.users_collection[0].objects.link(obj)
    obj.parent = rig
    data.materials.append(material)
    groups = {name:obj.vertex_groups.new(name=name) for name in (hand,*anchors)}
    for i, item in enumerate(weights):
        for name,w in item.items():
            if w: groups[name].add([i],w,'REPLACE')
    bm = bmesh.new(); bm.from_mesh(data)
    bmesh.ops.delete(bm,geom=[v for v in bm.verts if not v.link_faces],context="VERTS")
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    assert all(e.is_manifold for e in bm.edges)
    bm.to_mesh(data); bm.free()
    bpy.context.view_layer.objects.active=obj
    obj.select_set(True)
    smooth = obj.modifiers.new("Round knuckles and webs","SUBSURF")
    smooth.levels=1
    bpy.ops.object.modifier_apply(modifier=smooth.name)
    data=obj.data
    simplify = obj.modifiers.new("Hand silhouette budget","DECIMATE")
    data.calc_loop_triangles()
    simplify.ratio=min(1.,652/len(data.loop_triangles))
    bpy.ops.object.modifier_apply(modifier=simplify.name)
    data = obj.data
    for f in data.polygons: f.use_smooth=True
    layer = data.color_attributes.new(name="Col",type="BYTE_COLOR",domain="POINT")
    for v, color in zip(data.vertices,layer.data):
        # Muted ivory skin with cooler pink-grey under the curled fingers.
        shade=min(1.,max(.0,(-v.normal.y+1)/2))
        blush=exp(-min((v.co-p).length_squared for p in knuckles)/.009)*shade
        color.color_srgb=(.73+.09*shade,.705+.095*shade-.045*blush,.675+.09*shade-.03*blush,1)
        total=sum(g.weight for g in v.groups)
        for g in v.groups: g.weight/=total
    # Short nail beds conform to the final softened skin and follow the same digit.
    bm=bmesh.new();bm.from_mesh(data)
    surface=BVHTree.FromBMesh(bm)
    deform=bm.verts.layers.deform.active
    colors=bm.verts.layers.color["Col"]
    for name,(center,length,width) in nails.items():
        front=Vector((0,-1,0))
        dorsal=(front-length*front.dot(length)).normalized()
        across=length.cross(dorsal)
        def sample(u,v,h,color):
            point=center+across*(u*width)+length*(v*width*1.52)
            hit,n,_,_=surface.ray_cast(point+dorsal*.16,-dorsal,.27)
            assert hit is not None,(name,u,v)
            vertex=bm.verts.new(hit+dorsal*h)
            vertex[deform][obj.vertex_groups[name].index]=1
            # BMesh byte-colour access is sRGB for these nail-bed values.
            vertex[colors]=color
            return vertex
        old=None
        for scale,height,col in [(1,.0014,(.58,.53,.50,1)),(.80,.0038,(.74,.70,.65,1))]:
            ring=[sample(scale*cos(j*pi/4),scale*sin(j*pi/4),height,col) for j in range(8)]
            if old:
                for j in range(8):
                    f=bm.faces.new((old[j],old[(j+1)%8],ring[(j+1)%8],ring[j]))
                    f.normal_update()
                    if f.normal.dot(dorsal)<0: f.normal_flip()
                    f.smooth=True
            old=ring
        crown=sample(0,0,.005,(.79,.75,.70,1))
        for j in range(8):
            f=bm.faces.new((old[j],old[(j+1)%8],crown))
            f.normal_update()
            if f.normal.dot(dorsal)<0: f.normal_flip()
            f.smooth=True
    bm.to_mesh(data);bm.free()
    return obj,anchors
