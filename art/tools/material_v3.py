"""Original seamless shallow-inset square weave. No borrowed texture/studs.
Produces an 8-stud tile, 4x4 bevelled insets, OpenGL tangent-space normals.
"""
from pathlib import Path
import math,struct,zlib,json
OUT=Path(__file__).resolve().parents[1]/'textures'/'v3';OUT.mkdir(parents=True,exist_ok=True)
N=512;CELL=128

def height(x,y):
 u=(x%CELL)/CELL-.5;v=(y%CELL)/CELL-.5
 # A clipped-corner inset, not an extruded stud. Alternating short diagonal grain.
 distance=max(abs(u),abs(v),(abs(u)+abs(v))*.62)
 t=max(0,min(1,(.41-distance)/.045));t=t*t*(3-2*t)
 return -.035*t

def png(path,rows):
 data=b''.join(b'\0'+bytes(row) for row in rows)
 def chunk(k,v):return struct.pack('>I',len(v))+k+v+struct.pack('>I',zlib.crc32(k+v)&0xffffffff)
 path.write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',N,N,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(data,9))+chunk(b'IEND',b''))
colors=[];normals=[]
for y in range(N):
 cr=[];nr=[]
 for x in range(N):
  h=height(x+.5,y+.5);shade=round(255*(.985+h*.8));cr.extend([shade]*3)
  dx=(height(x+1,y)-height(x-1,y))/(16/N);dy=(height(x,y+1)-height(x,y-1))/(16/N)
  v=(-dx,dy,1);l=math.sqrt(sum(a*a for a in v));nr.extend(round(max(0,min(255,127+128*a/l))) for a in v)
 colors.append(cr);normals.append(nr)
png(OUT/'GrowVoxel_Color.png',colors);png(OUT/'GrowVoxel_Normal.png',normals)
(OUT/'material.json').write_text(json.dumps({'name':'GrowVoxelV3','BaseMaterial':'SmoothPlastic','StudsPerTile':8,'ColorMap':'GrowVoxel_Color.png','NormalMap':'GrowVoxel_Normal.png','normalConvention':'OpenGL tangent space; flat=127,127,255','source':'Original analytical height field, material_v3.py','documentation':'https://create.roblox.com/docs/reference/engine/classes/MaterialVariant'},indent=2))
print('2 seamless 512x512 maps written')
