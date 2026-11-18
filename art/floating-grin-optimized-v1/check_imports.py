"""Run the project's deforming-fingers and lunge checks on fresh runtime imports."""
from pathlib import Path
import json
import sys

ROOT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT.parent/'floating-grin-v2'))
from verify import inspect

specs=json.loads((ROOT/'models.json').read_text())
results={name:inspect(ROOT/'models'/(name+'.glb'),stats) for name,stats in specs.items()}
(ROOT/'import-check.json').write_text(json.dumps(results,indent=2)+'\n')
print('Verified',len(results),'imports.')
