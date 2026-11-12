"""Family-specific extremities, with the approved V4 faces, poses and outfits."""
import assets_monster_prototypes as base
import assets_monster_prototypes_v2 as quadruped
import assets_monster_prototypes_v3 as approved
import assets_monster_prototypes_v4 as poses
import creature_extremities_v6 as limbs
import kit

JOINTS=base.JOINTS


def build(deer_hand_builder=None):
    for role in ("Farmer","Punk","Assassin","Chief"):
        asset=kit.asset("Deer_"+role)
        base.deer_body(asset,role)
        base.deer_limbs(asset,role,hand_builder=deer_hand_builder or limbs.deer_hand)
        approved.deer_face(asset,role)
    quadruped.ring_quadruped(high_knees=True,paw_builder=limbs.ring_paw)
    poses.cave_upright(hand_builder=limbs.cave_hand,foot_builder=limbs.cave_foot)
    for role in ("Farmer","Punk","Assassin"):
        cave=poses.cave_upright("CaveDweller_"+role,
                               hand_builder=limbs.cave_hand,foot_builder=limbs.cave_foot)
        poses.cave_outfit(cave,role)
        ring=quadruped.ring_quadruped("RingMaw_"+role,high_knees=True,
                                     paw_builder=limbs.ring_paw)
        approved.outfit(ring,role,ringmaw=True)
