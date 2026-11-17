# Animation clips for the game (owner, 2026-11-15: "I've put animations in the project folder, let's try them", then
# "let's adapt the pack's animations to our game in general"): turns a Roblox KeyframeSequence (.rbxmx), a Mixamo
# animation (.fbx) or an action of an animation library (.glb) into Lua modules of joint transforms that the game
# plays itself - CombatPose on a player's Motor6Ds, MutantAnimation on a skinned monster's bones - with no Animation
# asset to publish.
#   .rbxmx  the poses are already Motor6D transforms, named by the joint's Part1
#   .fbx    retargeted: each Mixamo bone's world rotation since the rest pose (the arms taken from the T-pose down to
#           the sides, where R15's hang), moved into Roblox axes (x, y, z) = (-x, z, y) of Blender's, and a joint's
#           transform is its parent's inverse times its own (R15's C0/C1 carry no rotation); the hips' travel, scaled
#           to R15's hip height, goes on LowerTorso
# Each frame is a flat list: per part a quaternion (x, y, z, w), then a position (x, y, z) for the parts in Pos.
# A .glb/.fbx library with many actions (Quaternius' Universal Animation Library: bones pelvis, spine_03, upperarm_r
# ...) is read the same way; name the action after the file: Name=file::Action. A third field scales how far the
# clip travels over the ground (Name=file::Action::0.35): a combo that walks eleven studs is no use on a boss that
# kneels where it is. A fourth field "mirror" swaps left and right (Name=file::Action::1::mirror): the pack's shield
# bash is a left-hand move, and the weapon is in the right.
# Usage: blender --background --factory-startup --python finisher_clips.py -- <out dir> Name=file[::Action[::travel]] [...]
import bpy, sys, os, math
import xml.etree.ElementTree as ET
from mathutils import Matrix, Vector, Quaternion

ARGS = sys.argv[sys.argv.index('--') + 1:]
OUT, JOBS = ARGS[0], [a.split('=', 1) for a in ARGS[1:]]
PARTS = ['LowerTorso', 'UpperTorso', 'Head', 'RightUpperArm', 'RightLowerArm', 'RightHand', 'LeftUpperArm', 'LeftLowerArm',
         'LeftHand', 'RightUpperLeg', 'RightLowerLeg', 'RightFoot', 'LeftUpperLeg', 'LeftLowerLeg', 'LeftFoot']
PARENT = {'LowerTorso': None, 'UpperTorso': 'LowerTorso', 'Head': 'UpperTorso', 'RightUpperArm': 'UpperTorso',
          'RightLowerArm': 'RightUpperArm', 'RightHand': 'RightLowerArm', 'LeftUpperArm': 'UpperTorso',
          'LeftLowerArm': 'LeftUpperArm', 'LeftHand': 'LeftLowerArm', 'RightUpperLeg': 'LowerTorso',
          'RightLowerLeg': 'RightUpperLeg', 'RightFoot': 'RightLowerLeg', 'LeftUpperLeg': 'LowerTorso',
          'LeftLowerLeg': 'LeftUpperLeg', 'LeftFoot': 'LeftLowerLeg'}
MIXAMO = {'LowerTorso': 'Hips', 'UpperTorso': 'Spine2', 'Head': 'Head', 'RightUpperArm': 'RightArm', 'RightLowerArm': 'RightForeArm',
          'RightHand': 'RightHand', 'LeftUpperArm': 'LeftArm', 'LeftLowerArm': 'LeftForeArm', 'LeftHand': 'LeftHand',
          'RightUpperLeg': 'RightUpLeg', 'RightLowerLeg': 'RightLeg', 'RightFoot': 'RightFoot', 'LeftUpperLeg': 'LeftUpLeg',
          'LeftLowerLeg': 'LeftLeg', 'LeftFoot': 'LeftFoot'}
UAL = {'LowerTorso': 'pelvis', 'UpperTorso': 'spine_03', 'Head': 'Head', 'RightUpperArm': 'upperarm_r', 'RightLowerArm': 'lowerarm_r',
       'RightHand': 'hand_r', 'LeftUpperArm': 'upperarm_l', 'LeftLowerArm': 'lowerarm_l', 'LeftHand': 'hand_l',
       'RightUpperLeg': 'thigh_r', 'RightLowerLeg': 'calf_r', 'RightFoot': 'foot_r', 'LeftUpperLeg': 'thigh_l',
       'LeftLowerLeg': 'calf_l', 'LeftFoot': 'foot_l'}
C = Matrix(((-1, 0, 0), (0, 0, 1), (0, 1, 0)))  # Blender axes -> Roblox axes for a figure that faces -Y


def from_rbxmx(path):
    root = ET.parse(path).getroot()
    frames = []
    for kf in root.iter('Item'):
        if kf.get('class') != 'Keyframe':
            continue
        t = float(kf.find('Properties/float[@name="Time"]').text)
        poses = {}
        for pose in kf.iter('Item'):
            if pose.get('class') != 'Pose':
                continue
            props = pose.find('Properties')
            name = props.find('string[@name="Name"]').text
            cf = props.find('CoordinateFrame[@name="CFrame"]')
            v = {c.tag: float(c.text) for c in cf}
            m = Matrix(((v['R00'], v['R01'], v['R02']), (v['R10'], v['R11'], v['R12']), (v['R20'], v['R21'], v['R22'])))
            poses[name] = (m.to_quaternion(), Vector((v['X'], v['Y'], v['Z'])))
        frames.append((t, poses))
    frames.sort(key=lambda f: f[0])
    return frames


MIRROR = Matrix(((-1, 0, 0), (0, 1, 0), (0, 0, 1)))


def other(part):
    return part.replace('Right', '#').replace('Left', 'Right').replace('#', 'Left')


def from_rig(path, action_name=None, travel=1.0, rate=30, mirror=False):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    if path.lower().endswith('.fbx'):
        bpy.ops.import_scene.fbx(filepath=path)
    else:
        bpy.ops.import_scene.gltf(filepath=path)
    arm = next(o for o in bpy.context.scene.objects if o.type == 'ARMATURE')
    if action_name:
        action = bpy.data.actions[action_name]
        arm.animation_data_create()
        arm.animation_data.action = action
        if hasattr(arm.animation_data, 'action_slot') and getattr(action, 'slots', None):
            arm.animation_data.action_slot = action.slots[0]
    action = arm.animation_data.action
    first, last = action.frame_range
    scene = bpy.context.scene
    fps = scene.render.fps
    world = arm.matrix_world
    names = {b.name.split(':')[-1]: b for b in arm.pose.bones}
    table = UAL if 'pelvis' in names else MIXAMO

    def bone(name):
        return names[name]
    ref = {}
    for part, name in table.items():
        pb = bone(name)
        rest = (world @ pb.bone.matrix_local).to_3x3().normalized()
        low = name.lower()
        if 'arm' in low or 'hand' in low:
            # the T- or A-pose arm brought down to the side, where an R15 arm hangs at rest (a hand takes its
            # forearm's line: its own bone points wherever the importer left it)
            src = pb.parent.bone if 'hand' in low else pb.bone
            along = (world.to_3x3() @ (src.tail_local - src.head_local)).normalized()
            rest = along.rotation_difference(Vector((0, 0, -1))).to_matrix() @ rest
        ref[part] = rest
    hips = bone(table['LowerTorso'])
    hips_rest = world @ hips.bone.head_local
    scale = 2.0 / max(0.01, hips_rest.z)  # R15's hips stand about 2 studs up
    frames = []
    HANDS.clear()
    step = fps / rate
    f = first
    while f <= last + 1e-6:
        scene.frame_set(int(math.floor(f)), subframe=f - math.floor(f))
        # where the right hand is, in studs from where the hips stood at rest (for the report: when a blow lands)
        hand = (C @ ((world @ bone(table['LeftHand' if mirror else 'RightHand']).matrix).translation - Vector((hips_rest.x, hips_rest.y, 0)))) * scale
        HANDS.append(((f - first) / fps, Vector((-hand.x, hand.y, hand.z)) if mirror else hand))
        delta = {}
        for part, name in table.items():
            cur = (world @ bone(name).matrix).to_3x3().normalized()
            delta[part] = C @ (cur @ ref[part].inverted()) @ C.transposed()
        if mirror:
            delta = {part: MIRROR @ delta[other(part)] @ MIRROR for part in PARTS}
        poses = {}
        for part in PARTS:
            parent = PARENT[part]
            local = delta[part] if parent is None else delta[parent].inverted() @ delta[part]
            pos = Vector((0, 0, 0))
            if parent is None:
                pos = (C @ ((world @ hips.matrix).translation - hips_rest)) * scale
                pos = Vector((pos.x * travel * (-1 if mirror else 1), pos.y, pos.z * travel))
            poses[part] = (local.to_quaternion(), pos)
        frames.append(((f - first) / fps, poses))
        f += step
    return frames


HANDS = []


# The moments the right hand moves fastest (a blow on its way), with where it is then: seconds, studs a second,
# forward of the start (Roblox -Z), height off the ground, to the right.
def strikes():
    if len(HANDS) < 3:
        return ''
    speed = [0.0]
    for i in range(1, len(HANDS)):
        speed.append((HANDS[i][1] - HANDS[i - 1][1]).length / max(1e-6, HANDS[i][0] - HANDS[i - 1][0]))
    top = max(speed)
    out = []
    for i in range(1, len(speed) - 1):
        if speed[i] >= speed[i - 1] and speed[i] > speed[i + 1] and speed[i] > top * 0.45:
            t, at = HANDS[i]
            out.append('%.2fs %.0f/s fwd %.1f up %.1f right %.1f' % (t, speed[i], -at.z, at.y, at.x))
    reach = max(HANDS, key=lambda h: -h[1].z)
    return ' | '.join(out) + ' || furthest fwd %.1f at %.2fs' % (-reach[1].z, reach[0])


def num(x):
    s = ('%.4f' % x).rstrip('0').rstrip('.')
    return '0' if s in ('-0', '') else s


# One module a clip in the folder OUT (Roblox caps a script at 200,000 characters, and a second of clip is about
# 14,000): shared/Clips/<Name>.lua, each `return {Length, Rate, Source, Parts, Pos, Frames}`.
os.makedirs(OUT, exist_ok=True)
for name, path in JOBS:
    path, _, rest = path.partition('::')
    action_name, _, travel = rest.partition('::')
    travel, _, flag = travel.partition('::')
    frames = from_rbxmx(path) if path.lower().endswith('.rbxmx') else from_rig(path, action_name or None, float(travel) if travel != '' else 1.0, mirror=flag == 'mirror')
    moved = [p for p in PARTS if any(f[1].get(p, (None, Vector()))[1].length > 0.02 for f in frames)]
    length = frames[-1][0]
    rate = (len(frames) - 1) / length if length > 0 else 30
    out = ['-- Generated by art/roblox-import-v1/tools/finisher_clips.py from %s: an animation clip as joint transforms' % (os.path.basename(path) + (action_name and ' ' + action_name or '')),
           '-- for an R15 rig (CombatPose.PlayClip) or a skinned monster (MutantAnimation). Parts names each joint by its',
           '-- Part1; a frame holds, per part, a quaternion (x, y, z, w) and then a position (x, y, z) for the parts in Pos.',
           'return {Length=%s,Rate=%s,Source=%s,Parts={%s},Pos={%s},Frames={' % (
               num(length), num(rate), '"%s"' % (os.path.basename(path) + (action_name and ' ' + action_name or '') + (flag and ' ' + flag or '')),
               ','.join('"%s"' % p for p in PARTS), ','.join('%s=true' % p for p in moved))]
    for _, poses in frames:
        row = []
        for p in PARTS:
            q, pos = poses.get(p, (Quaternion(), Vector()))
            row += [num(q.x), num(q.y), num(q.z), num(q.w)]
            if p in moved:
                row += [num(pos.x), num(pos.y), num(pos.z)]
        out.append(' {' + ','.join(row) + '},')
    out.append('}}')
    with open(os.path.join(OUT, name + '.lua'), 'w', encoding='utf-8', newline='\n') as fh:
        fh.write('\n'.join(out) + '\n')
    hips = [f[1]['LowerTorso'][1] for f in frames]
    print('CLIP', name, len(frames), 'frames', round(length, 3), 's moved', moved, 'hips y first %.2f last %.2f min %.2f max %.2f' % (hips[0].y, hips[-1].y, min(h.y for h in hips), max(h.y for h in hips)),
          'travel fwd %.2f side %.2f (furthest fwd %.2f)' % (-hips[-1].z, hips[-1].x, max(-h.z for h in hips)))
    if not path.lower().endswith('.rbxmx'):
        print('  STRIKES', name, strikes())
print('WROTE', OUT)
