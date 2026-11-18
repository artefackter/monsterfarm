"""Thin the authored orb grid without changing the mouth seam or other mesh islands."""
from collections import defaultdict
from copy import deepcopy
import json
from math import cos, pi, sin
from pathlib import Path
import sys

import numpy as np

ROOT = Path(__file__).resolve().parent
ART = ROOT.parent
sys.path.insert(0, str(ART / 'srp-optimized-v1'))
from compact_glb import GLB, Writer

BASE = ART / 'floating-grin-v4'
FORMS = ART / 'floating-grin-forms-v1'


def shell_grid(positions, lunging):
    # Identify the two latitude grids of the approved sculpt in the published GLB.
    # Multiple render vertices can represent one point along a shading seam.
    points, vertex_to_point = np.unique(positions, axis=0, return_inverse=True)
    buckets = defaultdict(list)
    for index, p in enumerate(points):
        buckets[tuple(np.rint(p * 1000).astype(int))].append(index)

    def point(phi, latitude):
        x = 1.19 * cos(latitude) * sin(phi)
        y = 1.235 * sin(latitude)
        z = 1.12 * cos(latitude) * cos(phi)
        if lunging:
            y, z = cos(.135)*y - sin(.135)*z - .42, sin(.135)*y + cos(.135)*z + 2
        target = np.array([x, 5.38 + y, z])
        key = tuple(np.rint(target * 1000).astype(int))
        candidates = buckets.get(key, [])
        if not candidates:
            candidates = np.flatnonzero(np.max(abs(points - target), axis=1) < .00001)
        match = [i for i in candidates if np.max(abs(points[i] - target)) < .00001]
        assert len(match) == 1, (phi, latitude, target, match)
        return match[0]

    lower, upper = [], []
    for j in range(66):
        if j <= 30:
            t = j / 15 - 1
            phi = .835 * t
            middle = -.726 + .324*t*t - .045*t
            half = .224 * max(0, 1-t*t)**.85
            hi, lo = middle + half, middle - half
        else:
            phi = .835 + (2*pi-1.67) * (j-30)/36
            hi = lo = -.447 + .09*(j-30)/36
        lower.append([point(phi, -pi/2 + (lo + pi/2)*k/9) for k in range(10)])
        upper.append([point(phi, hi + (pi/2-hi)*k/18) for k in range(19)])
    return np.asarray(lower), np.asarray(upper), vertex_to_point


def retopologize(source, prim, lunging):
    pos = source.array(prim['attributes']['POSITION'])
    normals = source.array(prim['attributes']['NORMAL'])
    triangles = source.array(prim['indices'], False).reshape(-1, 3)
    lower, upper, point_ids = shell_grid(pos, lunging)
    selected = np.isin(point_ids[triangles], np.unique(np.r_[lower.ravel(), upper.ravel()])).all(1)
    assert selected.sum() == 66 * 52
    surface = triangles[selected]
    render_vertex = {}
    for vertex in np.unique(surface):
        key = point_ids[vertex]
        if key in render_vertex:
            # Tiny discrepancies in split normals occur after the wardrobe meshes are joined.
            ref = render_vertex[key]
            assert np.dot(normals[ref], normals[vertex]) > .9995
        else:
            render_vertex[key] = vertex

    # Keep every front longitude and both lip contours. Retain full latitude
    # density at the two sides that define the front portrait's silhouette.
    cols = list(range(31)) + list(range(32,66,2))
    replacement = []
    def triangle(a,b,c):
        if len({a,b,c}) < 3:
            return
        tri = [render_vertex[k] for k in (a,b,c)]
        p,q,r = pos[tri]
        if np.dot(np.cross(q-p,r-p), normals[tri].sum(0)) < 0:
            tri.reverse()
        replacement.append(tri)

    for grid, rows in ((lower,[0,2,4,6,8,9]), (upper,[0,1,2,3,4,5,7,9,11,13,15,17,18])):
        for first, second in zip(cols, cols[1:]+cols[:1]):
            a = b = 0
            left = range(grid.shape[1]) if first in (36,60) else rows
            right = range(grid.shape[1]) if second in (36,60) else rows
            for height in sorted(set(left[1:]) | set(right[1:])):
                if height in right:
                    triangle(grid[first,a],grid[second,b],grid[second,height])
                    b = height
                if height in left:
                    triangle(grid[first,a],grid[second,b],grid[first,height])
                    a = height

    # The sole boundary of the new shell must be exactly the old mouth opening.
    def boundary(faces):
        ids = point_ids[faces]
        edges = np.sort(np.concatenate([ids[:,[0,1]],ids[:,[1,2]],ids[:,[2,0]]]),axis=1)
        edge, count = np.unique(edges,axis=0,return_counts=True)
        assert count.max() == 2
        return edge[count==1]
    np.testing.assert_array_equal(boundary(surface), boundary(replacement))
    return np.vstack([triangles[~selected], replacement]), triangles[~selected]


def optimize(path):
    source = GLB(path)
    doc = deepcopy(source.doc)
    mesh, = doc['meshes']
    prim, = mesh['primitives']
    old_attrs = prim['attributes'].copy()
    old_indices = source.array(prim['indices'], False)
    indices, protected = retopologize(source, prim, path.stem.endswith('Aggressive'))
    used, inverse = np.unique(indices, return_inverse=True)
    output_indices = inverse.reshape(-1,1)
    writer = Writer()
    def store(index, values, component=None):
        a = source.doc['accessors'][index]
        view = source.doc['bufferViews'][a['bufferView']]
        return writer.array(values,component or a['componentType'],a['type'],view.get('target'),
                            a.get('normalized',False),'min' in a)
    for name, index in old_attrs.items():
        values = source.array(index,False)[used]
        component = None
        if name == 'WEIGHTS_0':
            assert np.all(values[:,0]==65535) and np.all(values[:,1:]==0)
            values = values // 257
            component = 5121
        prim['attributes'][name] = store(index, values, component)
    prim['indices'] = store(prim['indices'],output_indices)
    def copy_accessor(ref,key):
        index = ref[key]
        ref[key] = store(index,source.array(index,False))
    for skin in doc['skins']:
        copy_accessor(skin,'inverseBindMatrices')
    for animation in doc.get('animations',[]):
        for sampler in animation['samplers']:
            for key in ('input','output'):
                copy_accessor(sampler,key)

    out = ROOT/'models'/path.name
    writer.save(doc,out)
    reread = GLB(out)
    new_prim = reread.doc['meshes'][0]['primitives'][0]
    ix = reread.array(new_prim['indices'],False).reshape(-1,3)
    for name, old in old_attrs.items():
        before = source.array(old)
        after = reread.array(new_prim['attributes'][name])
        np.testing.assert_array_equal(after,before[used])
        np.testing.assert_array_equal(after[ix[:len(protected)]],before[protected])
    assert source.doc['nodes']==reread.doc['nodes'] and source.doc['materials']==reread.doc['materials']
    for old,new in zip(source.doc['skins'],reread.doc['skins']):
        assert old['joints']==new['joints']
        np.testing.assert_array_equal(source.array(old['inverseBindMatrices']),reread.array(new['inverseBindMatrices']))
    for old,new in zip(source.doc.get('animations',[]),reread.doc.get('animations',[])):
        assert old['channels']==new['channels'] and old['name']==new['name']
        for a,b in zip(old['samplers'],new['samplers']):
            for key in ('input','output'):
                np.testing.assert_array_equal(source.array(a[key]),reread.array(b[key]))
    return dict(input_bytes=len(source.raw),output_bytes=len(reread.raw),input_triangles=len(old_indices)//3,
                triangles=len(ix),protected_triangles=len(protected),input_vertices=len(source.array(old_attrs['POSITION'])),
                vertices=len(used),bones=len(doc['skins'][0]['joints']),
                animations=[a['name'] for a in doc.get('animations',[])])


if __name__=='__main__':
    from hashlib import sha256
    approval=json.loads((BASE/'approval.json').read_text())
    assert all(sha256((BASE/name).read_bytes()).hexdigest()==meta['sha256'] for name,meta in approval['files'].items())
    files=sorted((BASE/'models').glob('*.glb'))+sorted((FORMS/'models').glob('*.glb'))
    assert len(files)==8
    stats={p.stem:optimize(p) for p in files}
    (ROOT/'models.json').write_text(json.dumps(stats,indent=2)+'\n')
    print([(name,spec['triangles'],spec['output_bytes']) for name,spec in stats.items()])
