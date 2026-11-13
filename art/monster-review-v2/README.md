# Monster visual review, version 2

Offline model and preview assets. The owner approved retaining the RingMaw's four-limb stance and adding these assets to the repository. Nothing in `src`, Studio, the place file, or published assets is modified by these scripts. Importing and connecting the models to the game requires separate authorization.

- Parasite: the project's `Parasite_Root_Aggressive` geometry, with flesh vertex colors lifted across torso, head, arms, legs, and tendrils. Mouth cavity, teeth, and eyes are preserved. The model receives a rigid rotation to face the review camera; topology is unchanged.
- RingMaw: a revised proposal preserving the source model's hunched quadrupedal torso, four limb meshes, and ground contact points. Body vertex colors are lifted. The new head follows the second reference for the broad orange rim, recessed funnel, and small inner tooth ring, with no eye or glowing throat. No external mesh or image texture is embedded.
- Before images use the source meshes in the project, not a capture of the running game. Each comparison uses the same offline studio lighting. This does not establish how either model renders at night in Roblox.
- `models/Parasite_Proposed.glb`, `models/RingMaw_Proposed.glb`: standalone review models. The new RingMaw has separate named parts, but no game rig or animations are connected yet.
- `models/MonsterReview.blend`: editable models and render scene, with separate before/after collections. The proposed RingMaw is visible by default.
- `report.json`: source names and geometry counts.

Regenerate with Blender using `build_preview.py`, then run `compose_review.py` with Python and Pillow. The source art is only read. This folder is intentionally outside the game source tree.
