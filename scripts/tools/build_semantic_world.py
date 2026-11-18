"""Create a gameplay-first semantic plan. It is authored geometry, not image inference.
Run with --render-only after editing layout.json. All mask colors use the shared registry.
"""
from pathlib import Path
import json
import sys
import numpy as np
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets/blueprints/semantic_world_v3'
DOC=ROOT/'docs/semantic-world-v3'
SIZE=(1536,1024)

def smooth(points,n=2):
 for _ in range(n):
  points=[p for a,b in zip(points,points[1:]+points[:1]) for p in ([.75*a[0]+.25*b[0],.75*a[1]+.25*b[1]],[.25*a[0]+.75*b[0],.25*a[1]+.75*b[1]])]
 return points

def author_layout():
 objects=[]
 def add(name,kind,anchor,size,footprint=(0,0),door=None,role='obstacle'):
  x,y=anchor;w,h=size
  objects.append(dict(id=len(objects)+1,name=name,kind=kind,anchor=anchor,size=size,
   visual_envelope=[x-w/2,y-h,x+w/2,y+10],footprint=[x-footprint[0],y-footprint[1],x+footprint[0],y+footprint[1]],
   door=door,role=role,level=0))
 add('house_west','building',[210,610],[170,175],[66,26],[295,650])
 add('house_northwest','building',[470,540],[220,200],[82,28],[470,595])
 add('house_southwest','building',[320,810],[170,175],[66,26],[430,810])
 add('green_tree_north','tree_green',[655,410],[110,125],[13,10])
 add('green_tree_south','tree_green',[930,800],[130,130],[14,10])
 add('peach_tree_west','tree_peach',[805,340],[170,160],[16,11])
 add('peach_tree_north','tree_peach',[1020,240],[170,160],[16,11])
 add('peach_tree_east','tree_peach',[1390,490],[170,160],[16,11])
 add('peach_tree_south','tree_peach',[1110,650],[170,160],[16,11])
 add('rock_west','rock',[160,705],[70,48],[24,15])
 add('rock_east','rock',[1260,650],[70,48],[24,15])
 add('spawn_disc','spawn',[500,730],[65,22],role='marker')
 add('elder','npc',[525,640],[48,72],role='interaction')
 add('hero','player',[585,710],[48,70],role='dynamic')
 add('peach_1','pickup',[930,370],[36,35],role='interaction')
 add('peach_2','pickup',[1130,260],[36,35],role='interaction')
 add('peach_3','pickup',[1280,530],[36,35],role='interaction')
 return dict(schema_version=2,palette='../semantic_palette.json',size=SIZE,
  provenance='Authored gameplay-first semantic reconstruction v3. Not a pixel segmentation of the v2 illustration.',
  scale=dict(units_per_pixel=1,agent_radius=20,visual_safety_margin=20),
  land=smooth([[90,540],[110,430],[200,345],[350,300],[500,315],[620,285],[680,220],[800,180],[910,135],[1080,110],[1240,100],[1380,150],[1440,260],[1410,380],[1440,510],[1370,620],[1250,700],[1120,740],[1020,820],[870,885],[690,900],[510,890],[320,880],[190,820],[120,730]]),
  plaza=[120,450,860,865],
  route=[[500,730],[630,700],[735,620],[890,530],[930,440],[1060,360],[1190,300],[1260,220]],
  path_width=120,protected_width=160,
  spawn=[500,730],goal=[1260,220],
  objects=objects,level_count=1,
  notes=['All buildings are on west/southwest margins of the clearing. No house occupies the village-to-forest throat.',
   'Visual envelopes, not only trunk/base colliders, are excluded from the protected main route.',
   'Footprints block movement; canopies and roofs only affect visibility.',
   'Every door and pickup must be reachable from spawn with a 20-pixel-radius agent.',
   'Concept illustration is a downstream reference, never authority for label colors or collision.'])

def capsule(points,width):
 im=Image.new('L',SIZE);d=ImageDraw.Draw(im);r=width/2
 d.line([tuple(p) for p in points],fill=255,width=int(width))
 for x,y in points:d.ellipse((x-r,y-r,x+r,y+r),fill=255)
 return im

def render(layout):
 global SIZE
 SIZE=tuple(layout['size'])
 palette=json.loads((OUT/layout['palette']).resolve().read_text())
 by_name={c['name']:c for c in palette['classes']}
 ids=Image.new('L',SIZE,1);d=ImageDraw.Draw(ids)
 land=Image.new('L',SIZE);ImageDraw.Draw(land).polygon([tuple(p) for p in layout['land']],fill=255)
 # The visible front-facing cliff skirt lies below the same land contour.
 pts=layout['land'];start=max(range(len(pts)),key=lambda i:pts[i][0]);edge=pts[start:]+[pts[0]]
 d.polygon([tuple(p) for p in edge]+[(x,y+72) for x,y in edge[::-1]],fill=5)
 ids.paste(2,(0,0),land)
 dirt=capsule(layout['route'],layout['path_width'])
 ImageDraw.Draw(dirt).ellipse(tuple(layout['plaza']),fill=255)
 dirt_arr=(np.array(dirt)>0)&(np.array(land)>0)
 ids.paste(3,(0,0),Image.fromarray(dirt_arr.astype('uint8')*255))
 ids.save(OUT/'surface_ids.png')
 semantic=ids.copy();instance=Image.new('I',SIZE);collision=Image.new('L',SIZE)
 visual_envelopes=Image.new('L',SIZE)
 for obj in sorted(layout['objects'],key=lambda v:v['anchor'][1]):
  mask=Image.new('L',SIZE);md=ImageDraw.Draw(mask)
  x,y=obj['anchor'];w,h=obj['size'];kind=obj['kind']
  if kind=='building':
   md.polygon([(x-w/2,y-h*.63),(x-w*.26,y-h),(x+w*.27,y-h),(x+w/2,y-h*.62),(x+w*.40,y-h*.60),(x+w*.40,y),(x-w*.40,y),(x-w*.40,y-h*.60)],fill=255)
  elif kind.startswith('tree_'):
   md.rectangle((x-w*.08,y-h*.55,x+w*.08,y),fill=255)
   md.ellipse((x-w*.50,y-h*.88,x+w*.15,y-h*.35),fill=255)
   md.ellipse((x-w*.18,y-h,x+w*.30,y-h*.37),fill=255)
   md.ellipse((x-w*.06,y-h*.85,x+w*.50,y-h*.32),fill=255)
  elif kind=='rock':
   md.polygon([(x-w/2,y-h*.2),(x-w*.35,y-h*.75),(x,y-h),(x+w*.35,y-h*.7),(x+w/2,y),(x-w*.25,y)],fill=255)
  else:
   md.ellipse((x-w/2,y-h,x+w/2,y),fill=255)
  semantic.paste(by_name[kind]['id'],(0,0),mask)
  instance.paste(obj['id'],(0,0),mask)
  if obj['role']=='obstacle':
   ImageDraw.Draw(collision).rectangle(tuple(obj['footprint']),fill=255)
   ImageDraw.Draw(visual_envelopes).rectangle(tuple(obj['visual_envelope']),fill=255)
 semantic.save(OUT/'semantic_ids.png');instance.convert('I;16').save(OUT/'instance_ids.png')
 collision.save(OUT/'collision_mask.png');visual_envelopes.save(OUT/'obstacle_visual_envelopes.png')
 walk=((np.array(land)>0)&(np.array(collision)==0)).astype('uint8')*255
 Image.fromarray(walk).save(OUT/'walkable_mask.png')
 protected=capsule(layout['route'],layout['protected_width']);protected.save(OUT/'protected_corridor.png')
 height=Image.fromarray((np.array(land)>0).astype('uint8'));height.save(OUT/'height_ids.png')
 lut=np.zeros((256,3),dtype='uint8')
 for c in palette['classes']:lut[c['id']]=[int(c['hex'][i:i+2],16) for i in (1,3,5)]
 color=Image.fromarray(lut[np.array(semantic)])
 color.save(OUT/'semantic_colors.png')
 overview=color.copy();dr=ImageDraw.Draw(overview)
 dr.line([tuple(p) for p in layout['route']],fill='white',width=4)
 for obj in layout['objects']:
  x,y=obj['anchor'];dr.text((x+3,y+4),obj['name'],fill='black',stroke_width=1,stroke_fill='white')
  if obj['door']:
   x,y=obj['door'];dr.ellipse((x-5,y-5,x+5,y+5),fill='white',outline='black',width=2)
 overview.save(DOC/'layout-review.png')
 board=Image.new('RGB',(SIZE[0]+300,SIZE[1]),'white');board.paste(color,(0,0));bd=ImageDraw.Draw(board)
 bd.text((SIZE[0]+20,24),'SEMANTIC PALETTE v1',fill='black')
 for i,c in enumerate(palette['classes']):
  y=65+i*51;bd.rectangle((SIZE[0]+20,y,SIZE[0]+52,y+28),fill=c['hex']);bd.text((SIZE[0]+64,y),f"{c['id']:02d} {c['name']}\n{c['hex']}",fill='black')
 board.save(DOC/'semantic-map-legend.png')

if __name__=='__main__':
 OUT.mkdir(parents=True,exist_ok=True);DOC.mkdir(parents=True,exist_ok=True)
 if '--render-only' in sys.argv:layout=json.loads((OUT/'layout.json').read_text())
 else:
  layout=author_layout();(OUT/'layout.json').write_text(json.dumps(layout,indent=2)+'\n')
 render(layout)
 print('Rendered authored semantic world v3; validate before accepting.')
