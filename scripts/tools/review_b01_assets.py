#!/usr/bin/env python3
"""Non-destructive visual/structural review of Cloudbound B01 base art.

This is a review tool, not an automatic approval gate. A passing edge test
cannot prove visually seamless geometry or that platforms are navigable.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageChops, ImageStat

EXISTING = {
    'ground_jade_tile_01': ('ground', (128, 128), 'repeat'),
    'ground_jade_tile_02': ('ground', (128, 128), 'repeat'),
    'ground_cloud_tile_01': ('ground', (128, 128), 'repeat'),
    'ground_rune_center_01': ('ground', (128, 128), 'static'),
    'ground_grass_stone_transition_01': ('ground', (128, 128), 'transition'),
    'platform_cloud_edge_01': ('platforms', (256, 128), 'edge'),
    'platform_cloud_corner_01': ('platforms', (128, 128), 'corner'),
    'bridge_stone_01': ('bridges', (256, 128), 'bridge'),
    'bridge_stone_02': ('bridges', (256, 128), 'bridge'),
    'stairs_stone_01': ('bridges', (128, 128), 'stairs'),
}
# Proposed names for independently authored parts, not present in main at review time.
REVISED_REQUIRED = {
    'platforms': [*(f'platform_cloud_edge_{d}_01' for d in ('north', 'south', 'east', 'west')),
                  *(f'platform_cloud_corner_{d}_01' for d in ('nw', 'ne', 'sw', 'se'))],
    'bridges': ['bridge_stone_entrance_01', 'bridge_stone_middle_01',
                'bridge_stone_extension_01', 'bridge_stone_exit_01'],
    'ground': ['ground_stone_tile_01', *(f'ground_grass_stone_edge_{d}_01' for d in ('north','south','east','west')),
               *(f'ground_grass_stone_outer_{d}_01' for d in ('nw','ne','sw','se')),
               *(f'ground_grass_stone_inner_{d}_01' for d in ('nw','ne','sw','se'))],
}


def edge_stats(im: Image.Image) -> dict:
    im = im.convert('RGBA')
    left, right = im.crop((0,0,1,im.height)).tobytes(), im.crop((im.width-1,0,im.width,im.height)).tobytes()
    top, bottom = im.crop((0,0,im.width,1)).tobytes(), im.crop((0,im.height-1,im.width,im.height)).tobytes()
    def mean_abs(a, b):
        return round(sum(abs(a[i]-b[i]) for i in range(len(a))) / len(a), 3)
    def mirror_diff(axis):
        flip = im.transpose(Image.Transpose.FLIP_LEFT_RIGHT if axis=='x' else Image.Transpose.FLIP_TOP_BOTTOM)
        return round(sum(ImageStat.Stat(ImageChops.difference(im.convert('RGB'), flip.convert('RGB'))).mean)/3, 3)
    return {'left_right_rgba_mae':mean_abs(left,right),
            'top_bottom_rgba_mae':mean_abs(top,bottom),
            'horizontal_mirror_mae':mirror_diff('x'),
            'vertical_mirror_mae':mirror_diff('y')}


def fit_thumb(im, box):
    v=im.copy().convert('RGBA');v.thumbnail(box,Image.Resampling.LANCZOS);return v


def draw_tileability(root:Path, dst:Path):
    tiles = []
    for name in ('ground_jade_tile_01', 'ground_jade_tile_02', 'ground_cloud_tile_01'):
        p = root / 'assets/base/environment/ground' / f'{name}.png'
        if p.exists(): tiles.append((name, Image.open(p).convert('RGBA')))
    if not tiles: return None
    cell=128; gap=20; pad=24
    canvas=Image.new('RGB',(len(tiles)*(cell*5+gap)+gap,cell*5+100),(24,36,57));d=ImageDraw.Draw(canvas)
    for k,(name,im) in enumerate(tiles):
        x=gap+k*(cell*5+gap);d.text((x,14),name,fill='white')
        for yy in range(5):
            for xx in range(5): canvas.paste(im,(x+xx*cell,pad+yy*cell+20), im)
    d.text((gap,cell*5+65),'OFFLINE PREVIEW - visual review required; Godot rendering not tested',fill=(248,200,130))
    dst.parent.mkdir(parents=True,exist_ok=True);canvas.save(dst)
    return str(dst)


def draw_assembly(root:Path, dst:Path):
    base=root/'assets/base/environment'
    grass=base/'ground/ground_jade_tile_01.png';cloud=base/'ground/ground_cloud_tile_01.png'
    if not grass.exists() or not cloud.exists():return None
    canvas=Image.new('RGBA',(1440,710),(35,58,96,255));d=ImageDraw.Draw(canvas)
    def paste_asset(rel,x,y):
        p=base/rel
        if p.exists():
            with Image.open(p) as im:
                im=im.convert('RGBA');canvas.alpha_composite(im,(x,y))
    for ix,(x,tex) in enumerate([(95,grass),(810,cloud)]):
        with Image.open(tex) as im:
            im=im.convert('RGBA')
            for yy in range(3):
                for xx in range(3):canvas.alpha_composite(im,(x+128*xx,130+128*yy))
    paste_asset('ground/ground_rune_center_01.png',95+128,130+128)
    paste_asset('platforms/platform_cloud_edge_01.png',95+128,130+384-24)
    paste_asset('platforms/platform_cloud_corner_01.png',95,130+384-24)
    paste_asset('bridges/bridge_stone_01.png',480,250)
    paste_asset('bridges/stairs_stone_01.png',810+128,130+384-20)
    d.text((28,20),'B01 OFFLINE GEOMETRY REVIEW (not Godot screenshot)',fill=(255,245,220))
    d.text((28,42),'Illustrates missing geometry joints; not a validated navigable layout',fill=(255,190,130))
    dst.parent.mkdir(parents=True,exist_ok=True);canvas.convert('RGB').save(dst)
    return str(dst)


def review(root:Path,output:Path) -> dict:
    issues=[];out=[];pbase=root/'assets/base/environment'
    for name,(folder,dims,role) in EXISTING.items():
        path=pbase/folder/f'{name}.png';entry={'id':name,'path':str(path.relative_to(root)),'role':role}
        if not path.exists():
            entry['status']='FAILED';issues.append(f'Missing required B01 PNG: {entry["path"]}');out.append(entry);continue
        try:
            raw=path.read_bytes();entry['sha256']=hashlib.sha256(raw).hexdigest()
            with Image.open(path) as im:
                entry['dimensions']=list(im.size);entry['mode']=im.mode
                if im.size != dims: issues.append(f'{name}: expected {dims}, found {im.size}')
                if im.mode != 'RGBA':issues.append(f'{name}: mode {im.mode}, expected RGBA')
                v=im.convert('RGBA')
                lo,hi=v.getchannel('A').getextrema();entry['alpha_range']=[lo,hi]
                if role in ('bridge','stairs','edge','corner') and lo==255:
                    issues.append(f'{name}: no transparent exterior')
                if role=='repeat':
                    entry['edges']=edge_stats(v)
                    if entry['edges']['left_right_rgba_mae']>6 or entry['edges']['top_bottom_rgba_mae']>6:
                        issues.append(f'{name}: edge mismatch in four-side repetition')
                    if entry['edges']['horizontal_mirror_mae']<3 and entry['edges']['vertical_mirror_mae']<3:
                        issues.append(f'{name}: highly symmetric mirrored texture; visible repetitive pattern likely')
        except Exception as ex:issues.append(f'{name}: could not parse PNG ({ex})')
        entry['status']='REVIEW_REQUIRED' if any(x.startswith(name+':') for x in issues) else 'STRUCTURAL_CHECK_ONLY'
        out.append(entry)
    missing=[]
    for folder,names in REVISED_REQUIRED.items():
        for name in names:
            if not (pbase/folder/f'{name}.png').is_file():missing.append(f'assets/base/environment/{folder}/{name}.png')
    if missing:issues.append(f'Missing {len(missing)} revised edge/corner/connector/transition modules')
    issues.extend([
        'No registered physical connector anchors/collision footprints for bridge, stairs and island rims; cannot certify alignment',
        'Contact-sheet illustrations are NOT independent transparent modules and must not be auto-approved',
        'Visual seam checks cannot prove correct physical connectivity or walkable collision geometry',
    ])
    result={'batch':'B01','status':'REVIEW_REQUIRED','source':'Local filesystem review, not Godot execution',
            'inputs_sha256':[{'asset_id':x['id'],'sha256':x.get('sha256')} for x in out],
            'checked_assets':out,'missing_revised_modules':missing,'issues':issues,
            'godot_headless':{'status':'NOT_RUN','reason':'Run separate Godot scene on a machine with Godot installed'},
            'approval':'BLOCKED: visual and runtime evidence absent; approved assets were not overwritten'}
    output.parent.mkdir(parents=True,exist_ok=True);output.write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    draw_tileability(root,output.parent/'b01_repeat_5x5_review.png')
    draw_assembly(root,output.parent/'b01_offline_assembly_review.png')
    return result


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--project-root',type=Path,default=Path.cwd())
    ap.add_argument('--report',type=Path,default=None)
    args=ap.parse_args();root=args.project_root.resolve()
    report=(args.report if args.report is not None else root/'assets/previews/b01_validation_review.json').resolve()
    if not (root/'project.godot').exists():ap.error(f'Not a Godot project: {root}')
    result=review(root,report)
    print(f'B01 {result["status"]}: {len(result["checked_assets"])} existing assets, '
          f'{len(result["missing_revised_modules"])} missing revised modules; report: {report}')
    return 2 if result['status']=='REVIEW_REQUIRED' else 0

if __name__=='__main__':raise SystemExit(main())
