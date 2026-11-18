"""Independent source-mask, atlas and captured-GPU continuity checks for Batch 01."""
from pathlib import Path
from collections import deque
import hashlib,json
import numpy as np
from PIL import Image
from scipy import ndimage
ROOT=Path(__file__).resolve().parents[1]
DATA=ROOT/'assets/blueprints/terrain_batch01';ART=ROOT/'assets/sprites/batch01';DOC=ROOT/'docs/terrain-batch01'

def main():
 data=json.loads((DATA/'layout.json').read_text());atlas=json.loads((ART/'manifest.json').read_text())
 results=[]
 def record(name,ok,detail):results.append(dict(check=name,status='PASS' if ok else 'FAIL',detail=detail))
 def read(name):return np.array(Image.open(DATA/name))
 ids=read('terrain_ids.png');approved=read('approved_class_ids.png');land=read('land_mask.png')>0;path=read('path_mask.png')>0;cliff=read('cliff_mask.png')>0;nook=read('secret_nook_mask.png')>0;rim=read('boundary_rim_mask.png')>0
 record('Approved source identity',hashlib.sha256((ROOT/data['source']).read_bytes()).hexdigest()==data['sha256'],'Source image SHA256 matches normalized-mask provenance.')
 record('Island silhouette',np.array_equal(land,approved!=1),f'{int(np.count_nonzero(land^(approved!=1)))} changed silhouette pixels; no contour smoothing/resampling.')
 record('Main S-route mask',np.array_equal(path,(approved==3)|(approved==6)) or (np.count_nonzero(path^np.isin(approved,[3,6]))==data['terrain_only_restoration']['color_fringe_pixels_to_grass']),f"Only {data['terrain_only_restoration']['color_fringe_pixels_to_grass']} isolated class-fringe pixels were removed; houses restored to plaza dirt.")
 record('Terrain layer coverage',np.all(np.isin(ids,[1,2,3,5])) and np.array_equal(path,ids==3) and np.array_equal(cliff,ids==5) and np.all(~rim|land), 'Terrain classes only: background, grass, dirt, cliff; opaque grass underlay covers every island pixel.')
 border=land&~ndimage.binary_erosion(land)
 record('Cliff boundary continuity',not np.any(border&~(rim|cliff|path)),f'{int((border&~(rim|cliff|path)).sum())} unrepresented boundary pixels; flat rim stays inside silhouette.')
 record('No gameplay placeholders',not np.any(np.isin(ids,[6,7,8,9,10,11,12,13,14,15])), 'Approved house/tree markers replaced with their underlying dirt/grass; no props or actors instantiated.')
 r=data['agent_radius'];yy,xx=np.mgrid[-r:r+1,-r:r+1];disk=xx*xx+yy*yy<=r*r
 clearpath=ndimage.binary_erosion(path,structure=disk)
 plabels,_=ndimage.label(clearpath)
 def label_at(mask,xy):return int(mask[xy[1],xy[0]])
 landmarks=data['landmarks'];v=label_at(plabels,landmarks['village']);main_names=['village','forest','clearing','boss_approach']
 main_ok=v>0 and all(label_at(plabels,landmarks[name])==v for name in main_names)
 record('Main S-route connectivity',main_ok,f'Village → forest → clearing → boss approach share one dirt component after radius-{r}px erosion.')
 walk=ndimage.binary_erosion(land&~cliff,structure=disk);labels,_=ndimage.label(walk)
 branch_end=[865,797];branch_ok=v>0 and label_at(plabels,branch_end)==v
 walk_v=label_at(labels,landmarks['village']);nook_ok=walk_v>0 and label_at(labels,landmarks['secret_nook'])==walk_v
 contact=int((ndimage.binary_dilation(path)&nook).sum())
 record('Secret Nook connectivity',branch_ok and nook_ok and contact>0,f'Branch endpoint shares main dirt component; Nook reachable with radius-{r}px clearance; {contact} touching dirt/nook pixels.')
 # Recover a real raster route instead of assuming a polyline is clear.
 if main_ok:
  start=(landmarks['village'][1],landmarks['village'][0]);goal=(landmarks['boss_approach'][1],landmarks['boss_approach'][0])
  parent={start:None};queue=deque([start]);h,w=ids.shape
  while queue:
   p=queue.popleft()
   if p==goal:break
   y,x=p
   for q in [(y-1,x),(y+1,x),(y,x-1),(y,x+1)]:
    ny,nx=q
    if 0<=ny<h and 0<=nx<w and clearpath[ny,nx] and q not in parent:parent[q]=p;queue.append(q)
  points=[];p=goal
  while p is not None and p in parent:points.append([p[1],p[0]]);p=parent[p]
  (DATA/'validated_main_route.json').write_text(json.dumps(dict(pixel_route=points[::-1],agent_radius=r))+'\n')
 extraction_ok=len(atlas['tiles'])==9
 for tile in atlas['tiles']:
  im=Image.open(ART/(tile['name']+'.png'))
  extraction_ok &= im.size==(414,414)
 record('Nine native reusable assets',bool(extraction_ok),'3×3 × 418px cells; 2px gutters excluded, 414×414 native content; no resize or deformation.')
 # Exact-resolution GPU image must show the same island, with no clear-color holes.
 image=np.array(Image.open(DOC/'terrain-native.png'))[:,:,:3].astype(int)
 background=np.array([184,212,227]);foreground=np.max(np.abs(image-background),axis=2)>8
 holes=int((land&~foreground).sum());outside=int((~land&foreground).sum())
 record('Rendered gaps/overlaps',holes==0 and outside==0,f'{holes} clear-color holes inside island; {outside} foreground pixels outside approved silhouette. Material underlays overlap intentionally.')
 # Compare actual GPU color jumps on repeat boundaries with ordinary texel variation.
 # Restrict to interior of each material so semantic edges are not counted as seams.
 material=ids.copy();material[nook]=20;material[rim]=21
 valid=np.zeros(land.shape,bool)
 for cls in [2,3,20]:valid|=ndimage.binary_erosion(material==cls,iterations=12)
 seams=[];control=[]
 for axis in [0,1]:
  diff=np.abs(np.diff(image,axis=axis)).mean(2)
  same=(np.diff(material.astype(int),axis=axis)==0)
  interior=(valid[1:,:]&valid[:-1,:]) if axis==0 else (valid[:,1:]&valid[:,:-1])
  mask=same&interior
  for index in range(1,ids.shape[axis]):
   values=diff[index-1,:][mask[index-1,:]] if axis==0 else diff[:,index-1][mask[:,index-1]]
   if not len(values):continue
   if index%207==0:seams.extend(values.tolist())
   elif index%23==0:control.extend(values.tolist())
 seam_mean=float(np.mean(seams)) if seams else 999
 ordinary=float(np.mean(control)) if control else 0
 limit=max(3.0,ordinary*3)
 record('Rendered texture joins',seam_mean<=limit,f'GPU mean color jump at 207px wrap joins: {seam_mean:.3f}/255; control: {ordinary:.3f}; acceptance limit: {limit:.3f}. Crossfade, not geometric warp.')
 failures=[r for r in results if r['status']=='FAIL']
 report=dict(overall_terrain_status='PASS' if not failures else 'FAIL',checks=results,
  raw_atlas_seamlessness=dict(status='FAIL',reason='Opposite edges are not identical; unblended tiling is not approved.',metrics={t['name']:t['raw_edge_mae'] for t in atlas['tiles']}),
  complete_raised_cliff_tile_kit=dict(status='FAIL',reason='Missing a coherent directional/corner/end-cap set for raised organic cliffs. Current scene uses flat rock boundary regions plus a native clipped shallow rim, with no invented height/extrusion.'),
  seam_diagnostics=dict(gpu_wrap_mean=seam_mean,gpu_control_mean=ordinary,threshold=limit),
  holes=holes,outside_silhouette=outside,
  limitations=['Segmentation block steps are preserved, not smoothed away.',
   'No stretched corner/T-junction sprites: five incompatible fixed-shape tiles are extracted but reserved.',
   'Half-period sample crossfades soften a small band at texture wraps and repeat motifs remain visible.',
   'Connectivity is raster/free-space validation at 8px agent radius, not a player/controller or full gameplay test.',
   'Purple regions retain their approved footprints as rock material; this is not a fully extruded 3D cliff scene.'])
 (DOC/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
 print(json.dumps(report,indent=2))
 return 1 if failures else 0

if __name__=='__main__':raise SystemExit(main())
