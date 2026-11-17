"""Render the source under the adapted model's exact camera for fair comparison."""
import bpy
from pathlib import Path
ROOT=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'models/ParasiteAdapted.blend'))
scene=bpy.context.scene
# The saved adapted scene already has the final three-quarter comparison camera.
for co in scene.collection.children:
    if co.name=='Presentation_only':continue
    co.hide_render=co.name!='ParasiteExisting'
    co.hide_viewport=co.name!='ParasiteExisting'
scene.render.filepath=str(ROOT/'previews/ParasiteExisting_ThreeQuarter.png')
bpy.ops.render.render(write_still=True)
