"""Extract the native Village cells and assemble the approved plaza."""
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'assets/inbox/001-tao-asset-cho-prompt-vua-mo-ta.png'
ART = ROOT / 'assets/sprites/batch03_v2'
DATA = ROOT / 'assets/blueprints/terrain_batch01'
DOC = ROOT / 'docs/village-batch03'
SCALE = 0.26
# Names in sheet order. Direction names describe the façade's viewing angle.
NAMES = (
    'hut_main_left', 'hut_main_right', 'hut_small_left', 'hut_small_right',
    'hut_storage_front', 'well_centerpiece', 'stall_small_front', 'signpost_front',
    'lantern_post_front', 'fence_segment_straight', 'fence_segment_corner', 'crate_stack_small',
)

# Houses use the inward-facing façades, keeping the well and plaza approaches clear.
ITEMS = [
    ('hut_main_left', (247, 1050), (35, 21), (275, 1091)),
    ('hut_small_right', (491, 1069), (32, 22), (471, 1109)),
    ('well_centerpiece', (404, 1068), (24, 12), None),
    ('signpost_front', (459, 975), (7, 5), None),
]

def main():
    source = Image.open(SOURCE)
    assert source.size == (1448, 1086) and source.mode == 'RGB'
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

    ART.mkdir(parents=True, exist_ok=True)
    # Measured clear gutters. The first roof crosses the nominal x=362 split.
    xs, ys = (0, 385, 740, 1090, 1448), (0, 362, 724, 1086)
    extracted = {}
    for i, name in enumerate(NAMES):
        row, col = divmod(i, 4)
        cell = (xs[col], ys[row], xs[col+1], ys[row+1])
        rgb = np.asarray(source.crop(cell))
        foreground = (np.ptp(rgb, axis=2) > 18) | (rgb.max(axis=2) < 155)
        components, _ = ndimage.label(foreground)
        sizes = np.bincount(components.ravel())
        sizes[0] = 0
        # Bright neutral checker squares are baked into RGB, including the
        # openings below roofs and between fence rails. Keep retained RGB intact.
        alpha = components == sizes.argmax()
        assert alpha.any() and not (alpha[[0,-1]].any() or alpha[:,[0,-1]].any()), name
        tile = Image.fromarray(np.dstack((rgb, alpha.astype('uint8')*255)))
        crop = tile.getbbox()
        tile = tile.crop(crop)
        tile.save(ART / f'{name}.png')
        extracted[name] = (tile, cell, crop)
    entries, resources, shapes, nodes = [], [], [], []
    for i, (name, (x, y), (rx, ry), entrance) in enumerate(ITEMS):
        tile, cell, crop = extracted[name]
        scale = SCALE
        solid = np.asarray(tile)[:,:,3] > 0
        foot_x = float(np.where(solid[-min(tile.height,8):])[1].mean()+0.5)
        foot_y = tile.height - (ry * 0.60 / scale if name != "signpost_front" else 0)
        width, height = [round(v*scale) for v in tile.size]
        sprite_mask = np.asarray(tile.getchannel('A').resize((width,height), Image.Resampling.NEAREST)) > 0
        silhouette = ndimage.binary_dilation(np.pad(sprite_mask,1))
        left, top = round(x-foot_x*scale), round(y-foot_y*scale)
        region = np.s_[top-1:top+height+1,left-1:left+width+1]
        assert not np.any(silhouette & (visible[region] | nature_visible[region] | ~land[region])), name
        if name == 'signpost_front':
            assert not np.any(silhouette & path[region] & (yy[region[0]] < 970) & (abs(xx[:, region[1]] - 380) <= 8)), name
        footprint = (abs(xx-x) <= rx) & (abs(yy-y) <= ry)
        assert not np.any(footprint & (~land | cliff | blocked)), name
        if i >= 3:
            assert not np.any(footprint[:970] & path[:970]), name
        visible[region] |= silhouette
        if entrance is not None:
            label = labels[y,x]
            assert label in house_labels and np.all(labels[footprint] == label), name
            house_labels.remove(label)
        blocked |= footprint
        rid = str(i+1)
        resources.append(f'[ext_resource type="Texture2D" path="res://assets/sprites/batch03_v2/{name}.png" id="{rid}"]')
        shapes += [f'[sub_resource type="RectangleShape2D" id="Foot{rid}"]', f'size = Vector2({2*rx}, {2*ry})', '']
        nodes += [f'[node name="{name}" type="StaticBody2D" parent="."]', f'position = Vector2({x}, {y})',
                  'collision_layer = 2', 'collision_mask = 0', '',
                  f'[node name="Footprint" type="CollisionShape2D" parent="{name}"]', f'shape = SubResource("Foot{rid}")', '',
                  f'[node name="Sprite" type="Sprite2D" parent="{name}"]', f'texture = ExtResource("{rid}")',
                  'texture_filter = 2', 'centered = false', f'offset = Vector2({-foot_x:.3f}, {-foot_y:.3f})',
                  f'scale = Vector2({scale}, {scale})', '']
        entries.append(dict(name=name, cell=cell, crop_within_cell=crop, size=tile.size,
                            anchor_in_sprite=[foot_x,foot_y], position=[x,y], footprint_half_size=[rx,ry],
                            approach=entrance, scale=scale))
    # The approved storage marker is intentionally vacant.
    assert len(house_labels) == 1

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

    scene = [f'[gd_scene load_steps={1+2*len(ITEMS)} format=3]', '', *resources, '', *shapes,
             '[node name="Village" type="Node2D"]', 'y_sort_enabled = true', 'z_index = 1', '', *nodes]
    (ROOT / 'scenes/hoa_qua_son_village.tscn').write_text('\n'.join(scene))
    report = dict(source=str(SOURCE.relative_to(ROOT)), sha256=hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
                  source_size=source.size, source_mode=source.mode, scale=SCALE,
                  assets=[dict(name=name, cell=cell, crop_within_cell=crop, size=tile.size)
                          for name,(tile,cell,crop) in extracted.items()], placements=entries, agent_radius=radius, route_components=route_labels)
    (DOC / 'validation.json').write_text(json.dumps(report, indent=2)+'\n')
    print('PASS: twelve crops, two approved hut footprints, no sprite overlaps, all approaches and routes connected')

if __name__ == '__main__':
    main()
