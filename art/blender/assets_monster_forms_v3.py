"""CaveDweller keeps its open, visible-fanged mouth in both appearance states."""
import assets_monster_forms_v2 as previous

JOINTS=previous.JOINTS
FORMS=previous.FORMS
CHECKS=previous.CHECKS


def cave_head(asset,form):
    previous.cave_head(asset,form,passive_jaw_z=4.683,
                       aggressive_jaw_z=4.530,fold_passive_fangs=False)


def build(ring_head_builder=None,cave_head_builder=None):
    previous.build(cave_head_builder=cave_head_builder or cave_head,ring_head_builder=ring_head_builder)
    for name,pair in FORMS.items():
        if not name.startswith('CaveDweller'):continue
        passive,aggressive=(CHECKS[pair[state]] for state in ('Passive','Aggressive'))
        assert passive['mouthOpen'] and aggressive['mouthOpen']
        assert not passive['fangsFolded'] and not aggressive['fangsFolded']
        assert aggressive['mouthOpeningHeight']>passive['mouthOpeningHeight']
