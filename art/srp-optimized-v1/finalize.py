"""Create a compact distribution archive, checksums and measured summary."""
import json,sys,zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parent;sys.path.insert(0,str(ROOT))
from assets import verify_sources,sha
for name in ['packing_validation.json','blender_validation.json','visual_validation.json','icons_report.json']:
    assert json.loads((ROOT/name).read_text())['passed'],name
models=json.loads((ROOT/'models_report.json').read_text())['models']
icons=json.loads((ROOT/'icons_report.json').read_text())['icons']
assert len(models)==len(icons)==24
files=[ROOT/m['output'] for m in models]+[ROOT/i['variants']['ui512']['file'] for i in icons]
manifest=dict(status='optimized_offline_copies_pending_visual_approval',game_integrated=False,
    models=[dict(id=m['id'],character=m['character'],role=m['role'],file=m['output'],sha256=sha(ROOT/m['output']),**m['stats']) for m in models],
    icons=[dict(id=i['id'],file=i['variants']['ui512']['file'],sha256=sha(ROOT/i['variants']['ui512']['file']),size=[512,512]) for i in icons])
(ROOT/'runtime_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
(ROOT/'README_RUNTIME.txt').write_text('SRP: 24 compact rigged GLB models + 24 transparent PNG icons at 512px.\nOffline review package; not integrated or uploaded.\nFour characters, six costumes each; no held objects; royal variants are Kings.\nNo animation clips existed in these models; none were added.\nSource geometry, normals, materials, bone names and hierarchy are preserved.\nColors and skin weights are stored as normalized uint16.\nThe original optional KHR_materials_specular extension is preserved.\nNo Draco or meshopt decoder is needed.\nArchive compression reduces delivery/storage size; this ZIP is not a game loading format.\nRoblox import, loading times, FPS and device memory have not been measured.\nSee runtime_manifest.json for exact paths and hashes.\n')
files += [ROOT/'runtime_manifest.json',ROOT/'README_RUNTIME.txt']
zip_path=ROOT/'SRP_24_Models_Icons512.zip'
with zipfile.ZipFile(zip_path,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
    for p in files:z.write(p,str(p.relative_to(ROOT)))
with zipfile.ZipFile(zip_path) as z:
    assert z.testzip() is None
    assert len(z.namelist())==50
    for p in files:assert z.read(str(p.relative_to(ROOT)))==p.read_bytes()
mbefore=sum(m['stats']['input_bytes'] for m in models);mafter=sum(m['stats']['output_bytes'] for m in models)
ibefore=sum(i['source_bytes'] for i in icons)
def result(a,b):return dict(before_bytes=a,after_bytes=b,reduction_percent=round((1-b/a)*100,2))
summary=dict(models=result(mbefore,mafter),icons={s:result(ibefore,sum(i['variants'][s]['bytes'] for i in icons)) for s in ['ui512','small256','large1024']},
    primary_delivery=result(mbefore+ibefore,mafter+sum(i['variants']['ui512']['bytes'] for i in icons)),
    archive=dict(file=zip_path.name,bytes=zip_path.stat().st_size,sha256=sha(zip_path),entries=50,crc_and_unpacked_bytes_verified=True),
    triangles_preserved=sum(m['stats']['triangles'] for m in models),bones_preserved=sum(m['stats']['bones'] for m in models),
    source_files_unchanged=verify_sources(),game_integrated=False,roblox_import_tested=False,load_times_measured=False,
    interpretation='Size comparison covers equivalent GLB + one PNG resolution set, excludes authoring sources, FBX, review images and alternative resolutions. Original folders were retained.')
(ROOT/'summary.json').write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps(summary,indent=2))
