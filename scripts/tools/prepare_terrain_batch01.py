"""Inspect/split Batch 01 and normalize the approved raster without redesigning it.
No resizing, warping, mirroring or synthesized artwork. Texture joins are blended
in the shader; extracted cells preserve native source geometry.
"""
from pathlib import Path
import json, hashlib
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage
ROOT=Path(__file__).resolve().parents[2]
ATLAS=ROOT/'assets/inbox/001-tao-anh-theo-prompt-vua-cap.png'
SEG=ROOT/'assets/inbox/003-action-tao-anh-theo-prompt-cam-on.png'
OUT=ROOT/'assets/sprites/batch01';DATA=ROOT/'assets/blueprints/terrain_batch01';DOC=ROOT/'docs/terrain-batch01'
NAMES=['grass_fill','dirt_fill','grass_dirt_edge','path_corner','path_t_junction','cliff_straight','cliff_outer_corner','cliff_inner_corner','stone_fill']

def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
 for p in [OUT,DATA,DOC]:p.mkdir(parents=True,exist_ok=True)
 (DOC/'.gdignore').touch()
 source=Image.open(ATLAS).convert('RGBA');w,h=source.size
 assert w%3==0 and h%3==0
 cw,ch=w//3,h//3;entries=[]
 for i,name in enumerate(NAMES):
  # Visually verified 1px dark grid lines. Inset 2px, preserving 414x414 pixels.
  x=(i%3)*cw;y=(i//3)*ch;rect=[x+2,y+2,x+cw-2,y+ch-2]
  cell=source.crop(rect);a=np.array(cell)
  removed=0
  if i in [5,6,7]:
   rgb=a[:,:,:3].astype(int)
   neutral=(rgb.max(2)-rgb.min(2)<16)&(rgb.min(2)>185)
   seeds=np.zeros(neutral.shape,bool);seeds[[0,-1],:]=neutral[[0,-1],:];seeds[:,[0,-1]]=neutral[:,[0,-1]]
   matte=ndimage.binary_propagation(seeds,mask=neutral)
   removed=int(matte.sum());a[matte,3]=0
   cell=Image.fromarray(a)
  cell.save(OUT/(name+'.png'))
  rgb=a[:,:,:3].astype(float)
  def edge(a,b):return round(float(np.abs(a-b).mean()),3)
  entries.append(dict(name=name,row=i//3,column=i%3,cell_rect=[x,y,x+cw,y+ch],content_rect=rect,size=list(cell.size),checkerboard_pixels_removed=removed,
   raw_edge_mae=dict(horizontal=edge(rgb[:,0],rgb[:,-1]),vertical=edge(rgb[0],rgb[-1])),
   placement='material' if i in [0,1,8] else ('native face-strip crop for flat boundary rim' if i==5 else 'extracted; reserved: fixed geometry does not fit the organic mask')))
 # Inspect the actual straight-cliff face: rows 238:262 are all opaque purple rock.
 face=np.array(Image.open(OUT/'cliff_straight.png'))[238:262]
 assert np.all(face[:,:,3]==255)
 assert np.all((face[:,:,0].astype(int)>face[:,:,1]+5)&(face[:,:,2].astype(int)>face[:,:,1]+10))
 manifest=dict(source=str(ATLAS.relative_to(ROOT)),sha256=digest(ATLAS),atlas_size=[w,h],grid=[3,3],native_cell=[cw,ch],gutter_inset=2,uniform_world_scale=.5,
  face_region=[0,238,414,24],tiles=entries,
  issues=['Atlas is RGB, not alpha; transparency-looking checkerboards are baked into cells 6–8.',
   'Grass/dirt fills have nonmatching opposite edges; raw wrap is not assumed seamless.',
   'Only one straight grass/dirt transition; curved segments and junction have fixed incompatible end profiles.',
   'Cliff corner images include large fixed grass areas; they cannot trace every organic boundary without clipping/distortion.',
   'No complete left/right/back-facing cliff and end-cap set. This batch supports a clipped flat boundary rim, not a full raised 3D cliff enclosure.'])
 (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
 # Quantize the supplied anti-aliased/gradient image to the existing class registry.
 registry=json.loads((ROOT/'assets/blueprints/semantic_palette.json').read_text())
 classes={c['id']:c for c in registry['classes']}
 candidate_ids=[1,2,3,5,6,7,8]
 palette=np.array([[int(classes[id]['hex'][j:j+2],16) for j in (1,3,5)] for id in candidate_ids],np.float32)
 im=Image.open(SEG).convert('RGB');rgb=np.array(im,np.float32)
 ids=np.array(candidate_ids,np.uint8)[np.argmin(((rgb[:,:,None,:]-palette)**2).sum(3),2)]
 approved_land=ids!=1
 # Props are placeholders in the approved plan, not terrain in this batch.
 # Houses lie on the plaza: restore dirt underneath; tree circles restore grass.
 terrain=ids.copy();terrain[ids==6]=3;terrain[np.isin(ids,[7,8])]=2
 labels,n=ndimage.label(terrain==3)
 sizes=np.bincount(labels.ravel());sizes[0]=0
 largest=int(np.argmax(sizes));fringe=(terrain==3)&(labels!=largest)
 # Remove tiny nearest-color artifacts along anti-aliased tree-marker boundaries.
 assert sizes[largest]>100000 and (sizes.sum()-sizes[largest])<1000 and np.max(np.delete(sizes,largest))<50
 terrain[fringe]=2
 assert np.array_equal(terrain!=1,approved_land)
 land=terrain!=1;path=terrain==3;cliffs=terrain==5
 # A shallow native face strip is clipped INSIDE the exact perimeter; no wall extrusion.
 inside=ndimage.distance_transform_edt(land)
 rim=land&(inside<=8)&~path&~cliffs
 # Preserve the approved light-green Secret Nook as a grass material variant,
 # not a new semantic class and not an added gameplay object.
 normal=np.array([126,190,85],np.float32);nook_color=np.array([169,219,111],np.float32)
 nook=((rgb-nook_color)**2).sum(2)<((rgb-normal)**2).sum(2)
 roi=np.zeros(land.shape,bool);roi[700:885,855:1065]=True
 nook &= roi & (terrain==2)
 components,_=ndimage.label(nook);label=int(components[790,940]);assert label>0
 nook=components==label
 Image.fromarray(nook.astype('uint8')*255).save(DATA/'secret_nook_mask.png')
 Image.fromarray(ids).save(DATA/'approved_class_ids.png')
 Image.fromarray(terrain).save(DATA/'terrain_ids.png')
 for name,mask in [('land',land),('path',path),('cliff',cliffs),('boundary_rim',rim)]:Image.fromarray(mask.astype('uint8')*255).save(DATA/(name+'_mask.png'))
 lut=np.zeros((256,3),np.uint8)
 for id,c in classes.items():lut[id]=[int(c['hex'][j:j+2],16) for j in (1,3,5)]
 Image.fromarray(lut[terrain]).save(DATA/'terrain_semantic.png')
 # Interior reference points only: geometry remains entirely raster-defined.
 landmarks=dict(village=[365,1080],forest=[720,700],clearing=[525,485],boss_approach=[750,275],secret_nook=[940,790])
 main_route=[[365,1080],[380,930],[435,850],[565,805],[690,760],[735,680],[700,610],[590,565],[525,520],[525,465],[565,420],[650,385],[740,365],[750,315],[750,275]]
 secret_route=[[690,760],[765,785],[830,800],[875,800],[940,790]]
 data=dict(source=str(SEG.relative_to(ROOT)),sha256=digest(SEG),size=list(im.size),pixel_to_world=dict(scale=1.0,origin=[0,0]),palette='../semantic_palette.json',
  geometry='Approved raster normalized by nearest registered class; no smoothing, contour simplification, resampling or silhouette expansion.',
  terrain_only_restoration=dict(building_pixels_to_dirt=int((ids==6).sum()),tree_pixels_to_grass=int(np.isin(ids,[7,8]).sum()),color_fringe_pixels_to_grass=int(fringe.sum())),
  landmarks=landmarks,main_route=main_route,secret_route=secret_route,agent_radius=8,
  materials=dict(grass='grass_fill',path='dirt_fill',cliff_regions='stone_fill',boundary_rim='cliff_straight native face crop'),
  shader_blend_fraction=.12)
 (DATA/'layout.json').write_text(json.dumps(data,indent=2)+'\n')
 # Native-resolution cell review; compositing alpha over a review background only.
 sheet=Image.new('RGB',(cw*3,ch*3+90),'#8295a4');draw=ImageDraw.Draw(sheet)
 for i,e in enumerate(entries):
  cell=Image.open(OUT/(e['name']+'.png'));x=(i%3)*cw;y=(i//3)*(ch+30)
  sheet.paste(cell,(x,y),cell);draw.text((x+8,y+ch-2),f"{i+1}. {e['name']}",fill='white')
 sheet.save(DOC/'atlas-extraction.png')
 print('Extracted 9 native 414x414 assets; approved silhouette preserved; terrain masks prepared.')

if __name__=='__main__':main()
