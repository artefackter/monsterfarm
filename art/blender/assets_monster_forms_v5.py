"""CaveDweller throws its head back exactly 30 degrees and opens its jaws farther."""
import math
from mathutils import Matrix,Vector
import assets_monster_forms_v4 as previous
import assets_monster_forms_v2 as anatomy
import assets_monster_forms as posing

JOINTS=previous.JOINTS
FORMS=previous.FORMS
CHECKS=previous.CHECKS
HEAD_TILT_BACK_DEGREES=30


def cave_head(asset,form):
    anatomy.cave_head(asset,form,passive_jaw_z=4.683,
                      aggressive_jaw_z=4.280,fold_passive_fangs=False)
    aggressive=form=='Aggressive'
    if aggressive:
        # Facing -Y: a negative X pitch rotates the face upward and the crown backward.
        posing.pose_group(asset,'Head',(-HEAD_TILT_BACK_DEGREES,0,0))
    data=CHECKS[asset.name]
    data['headTiltBackDegrees']=HEAD_TILT_BACK_DEGREES if aggressive else 0
    data['headPitchBlenderXDegrees']=-HEAD_TILT_BACK_DEGREES if aggressive else 0
    data['headPivot']=list(JOINTS[asset.name]['Head'])
    data['headwearFollowsHead']=True
    if aggressive:
        rotation=Matrix.Rotation(math.radians(-HEAD_TILT_BACK_DEGREES),3,'X')
        up=rotation@Vector((0,0,1))
        assert abs(math.degrees(math.acos(up.z))-HEAD_TILT_BACK_DEGREES)<.0001
        assert up.y>0


def build():
    previous.build(cave_head_builder=cave_head)
    for name,pair in FORMS.items():
        if not name.startswith('CaveDweller'):continue
        passive,aggressive=(CHECKS[pair[state]] for state in ('Passive','Aggressive'))
        assert aggressive['headTiltBackDegrees']==30
        assert passive['headTiltBackDegrees']==0
        assert aggressive['mouthOpeningHeight']>1.05
        assert aggressive['mouthOpeningHeight']>passive['mouthOpeningHeight']*1.5
