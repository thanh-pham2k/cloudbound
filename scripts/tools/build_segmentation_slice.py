"""Hand-traced semantic reconstruction of the overview, not automatic AI segmentation.
Coordinates refer to the original first panel. The JSON is the editable scene source;
raster masks are review artifacts. Hidden ground is inferred for playability.
"""
from pathlib import Path
import json
import sys
from PIL import Image, ImageDraw, ImageFont
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets/blueprints/segmentation_slice';DOC=ROOT/'docs/segmentation-slice'
OUT.mkdir(parents=True,exist_ok=True);DOC.mkdir(parents=True,exist_ok=True)
source=ROOT/'assets/inbox/002-create-a-3x2-grid-concept-art-sheet-containing-6-separate-cl.png'

def smooth(points, iterations=2):
 for _ in range(iterations):
  points=[q for a,b in zip(points,points[1:]+points[:1]) for q in ([a[0]*.75+b[0]*.25,a[1]*.75+b[1]*.25],[a[0]*.25+b[0]*.75,a[1]*.25+b[1]*.75])]
 return points
# Visible contour and reconstructed ground behind occluding objects.
land=[[21,365],[22,330],[42,320],[58,322],[112,294],[128,303],[150,302],[157,279],[176,260],[201,252],[224,256],[248,246],[275,232],[306,232],[326,246],[333,270],[326,292],[341,315],[330,344],[309,361],[300,382],[278,403],[245,411],[223,422],[200,435],[170,446],[133,452],[99,450],[68,437],[45,419],[25,397]]
dirt=[[52,365],[69,353],[111,350],[144,355],[168,349],[187,341],[195,328],[199,315],[215,305],[228,293],[231,280],[247,267],[264,257],[278,246],[294,243],[308,246],[308,259],[291,265],[279,277],[265,285],[249,293],[243,309],[225,322],[220,337],[213,354],[197,365],[191,379],[196,391],[185,409],[168,419],[140,427],[110,431],[86,423],[64,410],[48,392],[46,378]]
land=smooth(land);dirt=smooth(dirt)
instances=[]
def obj(id,kind,pos,height,footprint=None,role='decoration',level=0):
 instances.append(dict(id=id,kind=kind,anchor=pos,height=height,footprint=footprint or [0,0],role=role,level=level))
obj('hut_main','hut',[95,349],49,[13,7],'obstacle')
obj('hut_left','hut_small',[54,387],36,[11,6],'obstacle')
obj('hut_right','hut_small',[174,391],36,[11,6],'obstacle')
obj('elder_monkey','npc',[126,374],16,role='quest_giver')
obj('spawn','spawn_disc',[112,406],8)
for i,(pos,h) in enumerate([([34,334],35),([116,304],40),([45,410],28),([219,416],30),([326,276],30)]):obj(f'green_{i}','green_tree',pos,h,[3,2],'obstacle')
for i,(pos,h) in enumerate([([177,281],43),([225,291],41),([261,265],42),([319,327],47),([301,367],45),([259,398],43)]):
 obj(f'peach_tree_{i}','peach_tree',pos,h,[3,2],'obstacle',1 if i<3 else 0)
 if i<3:obj(f'peach_{i}','peach',[pos[0]+10,pos[1]+6],8,role='pickup',level=1)
for i,pos in enumerate([[43,351],[142,324],[196,301],[286,294],[274,376],[228,402],[69,430],[316,347]]):obj(f'rock_{i}','rock',pos,14,[5,3],'obstacle')
for i,pos in enumerate([[58,420],[210,405],[149,319],[199,276],[320,301],[287,388]]):obj(f'bush_{i}','bush',pos,11)
for i,pos in enumerate([[73,346],[132,345],[83,432]]):obj(f'fence_{i}','fence',pos,11,[6,2],'obstacle')
obj('bridge','bridge',[174,426],17,role='bridge')
obj('lantern','lantern',[67,398],16,[2,2],'obstacle')
obj('waterfall','waterfall',[178,444],48)
route=[[112,406],[139,398],[159,379],[183,365],[205,347],[209,326],[230,310],[240,291],[260,276],[280,260],[300,253]]
blueprint=dict(version=1,method='manual semantic tracing plus inferred hidden ground; gameplay-adjusted anchors',source=str(source.relative_to(ROOT)),crop=[8,8,506,504],origin=[120,390],units_per_pixel=4.0,
 palette={'background':[184,212,227],'grass':[116,183,96],'dirt':[237,205,151],'water':[89,188,223],'cliff':[137,126,156]},
 surfaces=[dict(id='island_ground',class_id=1,kind='grass',polygon=land,inferred=True),dict(id='village_and_path',class_id=2,kind='dirt',polygon=dirt,inferred=True)],
 # Front edge indexed in clockwise order; back/north is framed by foliage.
 cliff_edge=land[max(range(len(land)),key=lambda i:land[i][0]):]+[land[0]],
 instances=instances,spawn=[112,397],route=route,
 height_regions=[dict(level=1,label='forest rise — visual/inferred, traversable ramp',polygon=[[150,302],[157,279],[176,260],[201,252],[224,256],[248,246],[275,232],[306,232],[326,246],[333,270],[294,292],[245,311],[204,333]])],
 gameplay=dict(pickup_target=3,connections=[dict(from_region='village',to_region='forest',via=route)],notes='Walking remains on a continuous 2D plane. Height masks describe scenery; no jump/elevation mechanic.'),
 correspondence_notes=['Only the overview determines coordinates. Close-up panels guide prop scale.','Ground hidden by roofs/canopies is reconstructed, not extracted from visible pixels.','No claim of pixel-exact automatic segmentation.','The bridge at the village edge is scenery; its water outlet is outside the walkable plateau.'])
if '--render-only' in sys.argv:
 blueprint=json.loads((OUT/'blueprint.json').read_text())
 land=blueprint['surfaces'][0]['polygon'];instances=blueprint['instances'];route=blueprint['route']
else:
 (OUT/'blueprint.json').write_text(json.dumps(blueprint,indent=2)+'\n')
# Generate masks in the source panel coordinate system, with exact class/instance IDs.
crop=Image.open(source).crop(tuple(blueprint['crop'])).convert('RGB');w,h=crop.size
local=lambda points:[(x-8,y-8) for x,y in points]
semantic=Image.new('L',(w,h),0);sd=ImageDraw.Draw(semantic)
# Front wall skirt is a visually inferred region below the land contour.
edge=blueprint['cliff_edge'];skirt=edge+[[x,y+48] for x,y in edge[::-1]]
sd.polygon(local(skirt),fill=4)
for region in blueprint['surfaces']:sd.polygon(local(region['polygon']),fill=region['class_id'])
sd.polygon(local([[167,433],[185,431],[190,492],[172,492]]),fill=3)
semantic.save(OUT/'surface_ids.png')
colored=Image.new('RGB',(w,h));pixels=colored.load();sp=semantic.load();palette=list(blueprint['palette'].values())
for y in range(h):
 for x in range(w):pixels[x,y]=tuple(palette[sp[x,y]])
colored.save(DOC/'surface-map.png')
height=Image.new('L',(w,h),0);hd=ImageDraw.Draw(height);hd.polygon(local(land),fill=1)
for region in blueprint['height_regions']:hd.polygon(local(region['polygon']),fill=region['level']+1)
height.save(OUT/'height_ids.png')
ids=Image.new('I',(w,h));di=ImageDraw.Draw(ids)
instance_review=crop.copy();ir=ImageDraw.Draw(instance_review)
for i,item in enumerate(instances,1):
 x,y=item['anchor'];rx,ry=item['footprint'];rx=max(rx,2);ry=max(ry,2)
 di.ellipse((x-8-rx,y-8-ry,x-8+rx,y-8+ry),fill=i)
 ir.ellipse((x-11,y-11,x-5,y-5),fill='red');ir.text((x-5,y-8),str(i),fill='black',stroke_width=1,stroke_fill='white')
ids.convert('I;16').save(OUT/'instance_ids.png');instance_review.save(DOC/'instance-anchors.png')
gameplay=Image.new('L',(w,h),0);gd=ImageDraw.Draw(gameplay);gd.polygon(local(land),fill=1)
for item in instances:
 if item['role']=='obstacle':
  x,y=item['anchor'];rx,ry=item['footprint'];gd.rectangle((x-8-rx,y-8-ry,x-8+rx,y-8+ry),fill=2)
gd.line(local(route),fill=3,width=3);gameplay.save(OUT/'gameplay_ids.png')
overlay=Image.blend(crop,colored,.45);overlay.save(DOC/'segmentation-overlay.png');crop.save(DOC/'source-overview.png')
board=Image.new('RGB',(w*3,h+50),'white')
for i,(im,label) in enumerate([(crop,'SOURCE OVERVIEW'),(overlay,'HAND-TRACED + INFERRED REGIONS'),(instance_review,'INSTANCE FOOT ANCHORS')]):
 board.paste(im,(i*w,40));ImageDraw.Draw(board).text((i*w+12,14),label,fill='black')
board.save(DOC/'segmentation-review.png')
print(f'Blueprint: {len(instances)} instances, {len(land)} land contour points, 4 ID masks')
