"""Extract the native Village cells and assemble the approved plaza."""
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'assets/inbox/002-tao-asset-theo-prompt-vua-cung-cap (1).png'
ART = ROOT / 'assets/sprites/batch03'
DATA = ROOT / 'assets/blueprints/terrain_batch01'
DOC = ROOT / 'docs/village-batch03'
SCALE = 0.26
# Ordered by atlas cell. Bounds are collider half-extents, at the ground anchor.
ITEMS = [
    ('hut_main', (247, 1050), (42, 26), (225, 1094)),
    ('hut_small', (491, 1069), (40, 28), (472, 1115)),
    ('hut_storage', (366, 1139), (43, 26), (361, 1183)),
    ('well_stone', (322, 1090), (15, 11), None),
    ('signpost_wood', (427, 979), (4, 4), None),
    ('fence_wood', (221, 1125), (40, 5), None),
    ('lantern_post', (308, 986), (7, 5), None),
    ('wooden_crate', (530, 1118), (13, 10), None),
]

def main():
    source = Image.open(SOURCE)
    assert source.size == (1774, 887) and source.mode == 'RGB'
    ids = np.asarray(Image.open(DATA / 'approved_class_ids.png'))
    land, path, cliff, nook = [
        np.asarray(Image.open(DATA / f'{name}_mask.png')) > 0
        for name in ('land', 'path', 'cliff', 'secret_nook')
    ]
    labels, _ = ndimage.label(ids == 6)
    house_labels = set(np.unique(labels)) - {0}
    nature = json.loads((ROOT / 'docs/nature-batch02/validation.json').read_text())
    blocked = np.zeros_like(land)
    nature_visible = np.zeros_like(land)
    visible = np.zeros_like(land)
    yy, xx = np.ogrid[:land.shape[0], :land.shape[1]]
    for prop in nature['placements']:
        x, y, radius = prop['x'], prop['y'], prop['radius']
        if radius:
            blocked |= (xx-x)**2 + (yy-y)**2 <= radius**2
        tile = Image.open(ROOT / f'assets/sprites/batch02/{prop["sprite"]}.png')
        foot_x, foot_y = nature['assets'][prop['sprite']]['ground_anchor']
        width, height = [round(v * nature['scale']) for v in tile.size]
        left, top = round(x-foot_x*nature['scale']), round(y-foot_y*nature['scale'])
        nature_visible[top:top+height, left:left+width] |= np.asarray(
            tile.getchannel('A').resize((width,height), Image.Resampling.NEAREST)) > 0

    xs, ys = (0,444,887,1331,1774), (0,444,887)
    entries, resources, shapes, nodes = [], [], [], []
    for i, (name, (x, y), (rx, ry), entrance) in enumerate(ITEMS):
        row, col = divmod(i, 4)
        cell = (xs[col], ys[row], xs[col+1], ys[row+1])
        rgb = np.asarray(source.crop(cell))
        foreground = (np.ptp(rgb, axis=2) > 12) | (rgb.min(axis=2) < 220)
        components, _ = ndimage.label(foreground)
        sizes = np.bincount(components.ravel())
        sizes[0] = 0
        # Keep the colored object component and neutral interior detail,
        # leaving bright open gaps transparent without changing source RGB.
        alpha = ndimage.binary_fill_holes(components == sizes.argmax())
        alpha &= foreground | (rgb.min(axis=2) < 235)
        assert alpha.any() and not (alpha[[0,-1]].any() or alpha[:,[0,-1]].any()), name
        tile = Image.fromarray(np.dstack((rgb, alpha.astype('uint8')*255)))
        crop = tile.getbbox()
        tile = tile.crop(crop)
        tile.save(ART / f'{name}.png')
        solid = np.asarray(tile)[:,:,3] > 0
        foot_x = float(np.where(solid[-min(tile.height,8):])[1].mean()+0.5)
        foot_y = tile.height - (ry * 0.60 / SCALE if i < 4 else 0)
        width, height = [round(v*SCALE) for v in tile.size]
        sprite_mask = np.asarray(tile.getchannel('A').resize((width,height), Image.Resampling.NEAREST)) > 0
        silhouette = ndimage.binary_dilation(np.pad(sprite_mask,1))
        candidates = [(x,y)] if i < 3 else sorted(
            ((x+dx,y+dy) for dx in range(-150,151,5) for dy in range(-120,121,5)
             if 175 <= x+dx <= 557 and 969 <= y+dy <= 1180),
            key=lambda p: (p[0]-x)**2+(p[1]-y)**2)
        reserved = [(365,1080), *(obj[3] for obj in ITEMS if obj[3])]
        for px, py in candidates:
            left, top = round(px-foot_x*SCALE), round(py-foot_y*SCALE)
            region = np.s_[top-1:top+height+1,left-1:left+width+1]
            if np.any(silhouette & (visible[region] | nature_visible[region] | ~land[region])):
                continue
            if i >= 3 and any(abs(px-ax) <= rx+14 and abs(py-ay) <= ry+14 for ax,ay in reserved):
                continue
            footprint = (abs(xx-px) <= rx) & (abs(yy-py) <= ry)
            if np.any(footprint & (~land | cliff | blocked)):
                continue
            if i >= 3 and np.any(footprint[:970] & path[:970]):
                continue
            x,y = px,py
            break
        else:
            raise ValueError(f'No clear placement for {name}')
        visible[region] |= silhouette
        if i < 3:
            label = labels[y,x]
            assert label in house_labels and np.all(labels[footprint] == label), name
            house_labels.remove(label)
        blocked |= footprint
        rid = str(i+1)
        resources.append(f'[ext_resource type="Texture2D" path="res://assets/sprites/batch03/{name}.png" id="{rid}"]')
        shapes += [f'[sub_resource type="RectangleShape2D" id="Foot{rid}"]', f'size = Vector2({2*rx}, {2*ry})', '']
        nodes += [f'[node name="{name}" type="StaticBody2D" parent="."]', f'position = Vector2({x}, {y})',
                  'collision_layer = 2', 'collision_mask = 0', '',
                  f'[node name="Footprint" type="CollisionShape2D" parent="{name}"]', f'shape = SubResource("Foot{rid}")', '',
                  f'[node name="Sprite" type="Sprite2D" parent="{name}"]', f'texture = ExtResource("{rid}")',
                  'texture_filter = 2', 'centered = false', f'offset = Vector2({-foot_x:.3f}, {-foot_y:.3f})',
                  f'scale = Vector2({SCALE}, {SCALE})', '']
        entries.append(dict(name=name, cell=cell, crop_within_cell=crop, size=tile.size,
                            anchor_in_sprite=[foot_x,foot_y], position=[x,y], footprint_half_size=[rx,ry],
                            approach=entrance))
    assert not house_labels

    radius = 8
    targets = json.loads((DATA / 'layout.json').read_text())['landmarks']
    free = land & ~cliff & ~blocked
    reachable, _ = ndimage.label(ndimage.distance_transform_edt(free) > radius)
    for item in entries:
        if item['approach']:
            targets[item['name']] = item['approach']
    route_labels = {name: int(reachable[y,x]) for name,(x,y) in targets.items()}
    assert len(set(route_labels.values())) == 1 and next(iter(route_labels.values())) > 0, route_labels
    # Outside the village plaza, ensure continuous dirt at agent clearance.
    trail = path & ~blocked
    trail_labels, _ = ndimage.label(ndimage.distance_transform_edt(trail) > radius)
    points = [(380,930),(720,700),(525,485),(750,275),(865,797)]
    assert len({trail_labels[y,x] for x,y in points}) == 1 and trail_labels[930,380] > 0
    assert not np.any(blocked & nook)

    scene = ['[gd_scene load_steps=17 format=3]', '', *resources, '', *shapes,
             '[node name="Village" type="Node2D"]', 'y_sort_enabled = true', 'z_index = 1', '', *nodes]
    (ROOT / 'scenes/hoa_qua_son_village.tscn').write_text('\n'.join(scene))
    report = dict(source=str(SOURCE.relative_to(ROOT)), sha256=hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
                  source_size=source.size, source_mode=source.mode, scale=SCALE,
                  assets=entries, agent_radius=radius, route_components=route_labels)
    (DOC / 'validation.json').write_text(json.dumps(report, indent=2)+'\n')
    print('PASS: eight crops, three approved footprints, no sprite overlaps, all approaches and routes connected')

if __name__ == '__main__':
    main()
