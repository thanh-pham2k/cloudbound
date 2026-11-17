"""Extract the five concept adaptation sheets without changing their masters."""
from pathlib import Path
import json
import numpy as np
from scipy import ndimage
from PIL import Image, ImageDraw
ROOT = Path(__file__).resolve().parents[2]
NAMES = [
 ['terrain_grass_fill','terrain_dirt_fill','terrain_grass_dirt_transition_a','terrain_grass_dirt_transition_b','terrain_path_curve','terrain_path_fork'],
 ['cliff_tall_a','cliff_tall_b','cliff_outer_corner','cliff_inner_corner','cliff_terrace_connector','cliff_grass_rim'],
 ['waterfall_long','waterfall_crest','waterfall_mist','cloud_bank','distant_mountain_layer','stream_extension'],
 ['hut_main_concept','hut_small_concept','cave_back_wide','cave_front_rim','cave_floor_fill','cave_stairs_wide'],
 ['flower_daisy_cluster','petal_scatter','quest_bubble_available','enemy_alert_marks','chest_reward_rays','dash_dust']]
OUT=ROOT/'assets/sprites/concept';OUT.mkdir(parents=True,exist_ok=True)
manifest=[]
for batch,names in enumerate(NAMES,1):
 source=next((ROOT/'assets/inbox').glob(f'{batch:03d}-use-the-attached*.png'))
 sheet=Image.open(source);cw,ch=sheet.width//3,sheet.height//2
 for i,name in enumerate(names):
  box=((i%3)*cw,(i//3)*ch,(i%3+1)*cw,(i//3+1)*ch)
  cell=sheet.crop(box)
  if name in ['terrain_grass_fill','terrain_dirt_fill','cave_floor_fill']:
   # Exclude generated outlines and gutters; fills intentionally remain opaque.
   cell=cell.crop((24,24,cw-24,ch-24)).convert('RGB').convert('RGBA')
  elif batch==5:
   # White-matte removal preserving the cream/white flower petals and soft FX.
   a=np.array(cell.convert('RGB')).astype(float)
   opacity=np.clip((255-a.min(axis=2)-3)/15,0,1)
   labels,_=ndimage.label(opacity>.05)
   sizes=np.bincount(labels.ravel());keep=sizes>=12;keep[0]=False
   opacity*=keep[labels]
   rgb=np.clip((a-255*(1-opacity[:,:,None]))/np.maximum(opacity[:,:,None],.001),0,255)
   rgba=np.dstack((rgb,(opacity*255))).astype('uint8')
   cell=Image.fromarray(rgba);bbox=cell.getbbox();cell=cell.crop(bbox) if bbox else cell
  else:
   a=np.array(cell.convert('RGBA'))
   labels,n=ndimage.label(a[:,:,3]>32)
   sizes=np.bincount(labels.ravel());keep=sizes>=max(30,int(sizes[1:].max()*.002));keep[0]=False
   a[~keep[labels],3]=0
   a[:,:,3]=np.clip(a[:,:,3].astype(float)*255/254,0,255).astype('uint8')
   cell=Image.fromarray(a);bbox=cell.getbbox();cell=cell.crop(bbox) if bbox else cell
  cell.save(OUT/f'{name}.png')
  manifest.append(dict(name=name,source=str(source.relative_to(ROOT)),cell=i,crop=box,size=cell.size))
# Flatten the slanted top of the source wall into a repeatable vertical strip.
# This derived texture is mapped to the actual boundary, avoiding transparent cracks.
wall=Image.open(OUT/'cliff_tall_a.png').convert('RGBA')
arr=np.array(wall);strip=Image.new('RGBA',(wall.width,256))
for x in range(wall.width):
 ys=np.flatnonzero(arr[:,x,3]>100)
 if len(ys)>20:
  column=wall.crop((x,int(ys[0]),x+1,int(ys[-1])+1)).resize((1,256),Image.Resampling.BICUBIC)
  strip.paste(column,(x,0))
# Remove narrow end caps with insufficient rock height.
strip=strip.crop((int(wall.width*.10),0,int(wall.width*.90),256))
repeat=Image.new('RGBA',(strip.width*2,256))
repeat.paste(strip,(0,0));repeat.paste(strip.transpose(Image.Transpose.FLIP_LEFT_RIGHT),(strip.width,0))
repeat.save(OUT/'cliff_face_strip.png')
for name in ['terrain_grass_fill','terrain_dirt_fill','cave_floor_fill']:
 im=Image.open(OUT/(name+'.png'));w,h=im.size
 tile=Image.new('RGBA',(w*2,h*2));tile.paste(im,(0,0));tile.paste(im.transpose(Image.Transpose.FLIP_LEFT_RIGHT),(w,0))
 tile.paste(tile.crop((0,0,w*2,h)).transpose(Image.Transpose.FLIP_TOP_BOTTOM),(0,h))
 tile.save(OUT/(name+'.png'))
# Feather background-layer cell boundaries; alpha sources contain pale residual edge pixels.
for name in ['distant_mountain_layer','cloud_bank']:
 im=Image.open(OUT/(name+'.png'));a=np.array(im);h,w=a.shape[:2]
 yy,xx=np.mgrid[:h,:w]
 fade=np.minimum(np.minimum(xx,w-1-xx)/(w*.12),np.minimum(yy,h-1-yy)/(h*.15))
 a[:,:,3]=(a[:,:,3]*np.clip(fade,0,1)).astype('uint8')
 Image.fromarray(a).save(OUT/(name+'.png'))
for item in manifest:
 item['size']=Image.open(OUT/(item['name']+'.png')).size
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
preview=Image.new('RGB',(1080,5*220),'#9aa9b8');draw=ImageDraw.Draw(preview)
for i,item in enumerate(manifest):
 im=Image.open(OUT/(item['name']+'.png'));im.thumbnail((170,175));x=(i%6)*180;y=(i//6)*220
 preview.paste(im,(x+(180-im.width)//2,y),im);draw.text((x+2,y+180),item['name'],fill='black')
preview.save('/tmp/concept_extracted.png')
print(f'Extracted {len(manifest)} assets')
