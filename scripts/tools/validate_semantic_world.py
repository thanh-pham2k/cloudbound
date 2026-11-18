"""Validate semantic meaning, color consistency and gameplay clearance from saved artifacts."""
from pathlib import Path
import json
import numpy as np
from scipy import ndimage
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets/blueprints/semantic_world_v3'

def validate():
 layout=json.loads((OUT/'layout.json').read_text());palette=json.loads((OUT/layout['palette']).resolve().read_text())
 shape=(layout['size'][1],layout['size'][0]);fail=[];metrics={}
 def check(ok,message):
  if not ok:fail.append(message)
 def read(name):
  im=Image.open(OUT/name);check(im.size==tuple(layout['size']),f'Size mismatch: {name}');return np.array(im)
 surface=read('surface_ids.png');semantic=read('semantic_ids.png');colors=read('semantic_colors.png')
 collision=read('collision_mask.png')>0;walk=read('walkable_mask.png')>0;corridor=read('protected_corridor.png')>0
 classes={c['id']:c for c in palette['classes']}
 lut=np.zeros((256,3),dtype='uint8')
 for id,c in classes.items():lut[id]=[int(c['hex'][j:j+2],16) for j in (1,3,5)]
 check(set(np.unique(semantic))<=set(classes),'Unregistered semantic IDs')
 check(colors.shape==shape+(3,) and np.array_equal(colors,lut[semantic]),'RGB mask disagrees with canonical class palette')
 land=np.isin(surface,[2,3]);check(np.all(walk==(land&~collision)),'Walkability not derived from ground + collision')
 check(not np.any(corridor&~land),'Protected route leaves the plateau')
 check(not np.any(corridor&collision),'A collider blocks protected route')
 ids=[o['id'] for o in layout['objects']];check(len(ids)==len(set(ids)),'Duplicate instance IDs')
 check(set(np.unique(read('instance_ids.png')))==set(ids)|{0},'Instance mask IDs disagree with blueprint')
 r=int(layout['scale']['agent_radius']);yy,xx=np.mgrid[-r:r+1,-r:r+1];disk=xx*xx+yy*yy<=r*r
 agent_space=ndimage.binary_erosion(walk,structure=disk,border_value=0)
 components,count=ndimage.label(agent_space,structure=np.ones((3,3),dtype='uint8'))
 x,y=layout['spawn'];label=components[y,x];check(label>0,'Spawn has no agent clearance')
 reachable=(components==label)&(label>0)
 def point_ok(point):
  x,y=map(int,point);return 0<=x<shape[1] and 0<=y<shape[0] and bool(reachable[y,x])
 check(point_ok(layout['goal']),'Forest endpoint is disconnected from spawn')
 targets=[]
 visual_overlap=0
 outside_footprints=0
 for o in layout['objects']:
  if o['role']=='obstacle':
   mask=Image.new('L',tuple(layout['size']));ImageDraw.Draw(mask).rectangle(tuple(o['visual_envelope']),fill=255)
   overlap=int(np.count_nonzero((np.array(mask)>0)&corridor))
   visual_overlap+=overlap
   check(overlap==0,f"Visual envelope overlaps route: {o['name']} ({overlap}px)")
   footprint=Image.new('L',tuple(layout['size']));ImageDraw.Draw(footprint).rectangle(tuple(o['footprint']),fill=255)
   outside=int(np.count_nonzero((np.array(footprint)>0)&~land))
   outside_footprints+=outside
   check(outside==0,f"Footprint leaves ground: {o['name']}")
  if o['door']:
   check(point_ok(o['door']),f"Door unreachable with agent clearance: {o['name']}");targets.append(o['name']+':door')
  elif o['role']=='interaction':
   check(point_ok(o['anchor']),f"Interaction point unreachable: {o['name']}");targets.append(o['name'])
  x0,y0,x1,y1=o['visual_envelope']
  check(x0>=32 and y0>=32 and x1<shape[1]-32 and y1<shape[0]-32,f"Object too close to canvas edge: {o['name']}")
 # Every route sample must be in the same navigable component; not only its endpoints.
 route_mask=Image.new('L',tuple(layout['size']));ImageDraw.Draw(route_mask).line([tuple(p) for p in layout['route']],fill=255,width=1)
 check(np.all(reachable[np.array(route_mask)>0]),'Route centerline is not fully navigable')
 metrics.update(instances=len(ids),reachable_targets=len(targets),agent_radius=r,path_width=layout['path_width'],protected_width=layout['protected_width'],semantic_colors=len(np.unique(colors.reshape(-1,3),axis=0)),registered_colors=len(classes),reachable_pixels=int(reachable.sum()),protected_collision_overlap=int((corridor&collision).sum()),protected_visual_overlap=visual_overlap,footprint_outside_ground=outside_footprints)
 report=dict(passed=not fail,checks='Canonical palette, IDs, ground footprints, corridor visibility, agent-eroded connectivity, all entrances and interactions',metrics=metrics,failures=fail)
 (OUT/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
 return report

if __name__=='__main__':
 report=validate();print(json.dumps(report,indent=2));raise SystemExit(0 if report['passed'] else 1)
