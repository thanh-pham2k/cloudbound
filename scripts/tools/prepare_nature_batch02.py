"""Extract the supplied RGB sheet and assemble nature on the approved tree markers."""
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'assets/inbox/002-tao-asset-theo-prompt-vua-cung-cap.png'
ART = ROOT / 'assets/sprites/batch02'
DATA = ROOT / 'assets/blueprints/terrain_batch01'
DOC = ROOT / 'docs/nature-batch02'
NAMES = ('peach_a', 'peach_b', 'peach_c', 'green_a', 'green_b',
         'bush_green', 'bush_flowering', 'grass_tuft')
SCALE = 0.26

def components(mask):
    labels, count = ndimage.label(mask)
    return [labels == i for i in range(1, count + 1)
            if np.count_nonzero(labels == i) > 100]

def main():
    ART.mkdir(parents=True, exist_ok=True)
    source = Image.open(SOURCE)
    assert source.size == (1774, 887) and source.mode == 'RGB'
    xs, ys = (0, 444, 887, 1331, 1774), (0, 444, 887)
    sprites, manifest = {}, {}
    for i, name in enumerate(NAMES):
        row, col = divmod(i, 4)
        box = (xs[col], ys[row], xs[col + 1], ys[row + 1])
        rgb = np.asarray(source.crop(box))
        # The checkerboard is baked RGB. Retain the single colored silhouette,
        # including its interior pixels. Neutral white pockets remain transparent.
        colored = (np.ptp(rgb, axis=2) > 12) | (rgb.min(axis=2) < 212)
        labels, _ = ndimage.label(colored)
        counts = np.bincount(labels.ravel())
        counts[0] = 0
        mask = labels == counts.argmax()
        assert mask.any() and not (mask[[0, -1]].any() or mask[:, [0, -1]].any()), name
        # Interior colors belong to the sprite even if they match matte thresholds.
        mask = ndimage.binary_fill_holes(mask) & (colored | (rgb.min(axis=2) < 235))
        rgba = Image.fromarray(np.dstack((rgb, mask.astype('uint8') * 255)))
        crop = rgba.getbbox()
        rgba = rgba.crop(crop)
        rgba.save(ART / f'{name}.png')
        alpha = np.asarray(rgba)[:, :, 3] > 0
        # Bottom rows describe the actual trunk/ground contact, not canopy center.
        foot_x = float(np.where(alpha[-min(8, rgba.height):])[1].mean() + 0.5)
        sprites[name] = (rgba, foot_x)
        manifest[name] = dict(cell=box, crop_within_cell=crop, size=rgba.size,
                              ground_anchor=[round(foot_x, 3), rgba.height])
    ids = np.array(Image.open(DATA / 'approved_class_ids.png'))
    land = np.array(Image.open(DATA / 'land_mask.png')) > 0
    path = np.array(Image.open(DATA / 'path_mask.png')) > 0
    cliff = np.array(Image.open(DATA / 'cliff_mask.png')) > 0
    rim = np.array(Image.open(DATA / 'boundary_rim_mask.png')) > 0
    nook = np.array(Image.open(DATA / 'secret_nook_mask.png')) > 0
    ground = land & ~(cliff | rim)
    protected = ndimage.binary_dilation(path | nook, iterations=8)
    occupied = np.zeros_like(land)
    blocked = np.zeros_like(land)
    placements = []

    def place(name, x, y, radius=0):
        sprite, foot = sprites[name]
        width, height = (round(v * SCALE) for v in sprite.size)
        left, top = round(x - foot * SCALE), y - height
        alpha = np.array(sprite.getchannel('A').resize((width, height), Image.Resampling.NEAREST)) > 0
        # Include one pixel of raster uncertainty at filtered sprite edges.
        region = np.s_[top-1:top+height+1, left-1:left+width+1]
        visible = ndimage.binary_dilation(np.pad(alpha, 1))
        if np.any(visible & (protected[region] | occupied[region] | ~land[region])):
            return False
        if not ground[y, x] or protected[y, x]:
            return False
        if radius:
            body = Image.new('1', (land.shape[1], land.shape[0]))
            ImageDraw.Draw(body).ellipse((x-radius, y-radius, x+radius, y+radius), fill=1)
            footprint = np.array(body)
            if np.any(footprint & (~ground | protected | blocked)):
                return False
            blocked[:] |= footprint
        occupied[region] |= visible
        placements.append(dict(sprite=name, x=x, y=y, radius=radius))
        return True

    for cls, variants in [(7, NAMES[3:5]), (8, NAMES[:3])]:
        for i, marker in enumerate(components(ids == cls)):
            y, x = ndimage.center_of_mass(marker)
            candidates = sorted(zip(*np.where(marker)), key=lambda p: (p[0]-y)**2+(p[1]-x)**2)
            # Prefer the marker center; require any adjustment to remain inside it.
            for cy, cx in candidates:
                if place(variants[i % len(variants)], int(cx), int(cy), 9):
                    break
            else:
                raise ValueError(f'Tree at {x:.1f}, {y:.1f} cannot fit the approved marker')

    for name, x, y in [('bush_green', 730, 505), ('bush_flowering', 820, 450),
                       ('bush_green', 970, 910), ('bush_flowering', 470, 953),
                       ('grass_tuft', 300, 923), ('grass_tuft', 614, 645),
                       ('grass_tuft', 910, 510), ('grass_tuft', 635, 991)]:
        place(name, x, y)

    assert set(p['sprite'] for p in placements) == set(NAMES), placements
    free = ground & ~blocked
    clearance = ndimage.distance_transform_edt(free) > 8
    labels, _ = ndimage.label(clearance)
    landmarks = json.loads((DATA / 'layout.json').read_text())['landmarks']
    route_labels = {key: int(labels[y, x]) for key, (x, y) in landmarks.items()}
    assert len(set(route_labels.values())) == 1 and next(iter(route_labels.values())) > 0
    assert not np.any(blocked & protected)

    scene = ['[gd_scene load_steps=10 format=3]', '']
    for i, name in enumerate(NAMES, 1):
        scene.append(f'[ext_resource type="Texture2D" path="res://assets/sprites/batch02/{name}.png" id="{i}"]')
    scene += ['', '[sub_resource type="CircleShape2D" id="TreeFoot"]', 'radius = 9.0',
              '', '[node name="Nature" type="Node2D"]', 'y_sort_enabled = true', 'z_index = 1']
    for i, item in enumerate(placements, 1):
        name = item['sprite']
        node = f'{name}_{i:02}'
        tree = bool(item['radius'])
        scene += ['', f'[node name="{node}" type="{"StaticBody2D" if tree else "Node2D"}" parent="."]',
                  f'position = Vector2({item["x"]}, {item["y"]})']
        if tree:
            scene += ['collision_layer = 2', 'collision_mask = 0', '',
                      f'[node name="Footprint" type="CollisionShape2D" parent="{node}"]',
                      'shape = SubResource("TreeFoot")']
        sprite, foot = sprites[name]
        scene += ['', f'[node name="Sprite" type="Sprite2D" parent="{node}"]',
                  f'texture = ExtResource("{NAMES.index(name)+1}")', 'texture_filter = 2',
                  'centered = false', f'offset = Vector2({-foot:.3f}, {-sprite.height})',
                  f'scale = Vector2({SCALE}, {SCALE})']
    (ROOT / 'scenes/hoa_qua_son_nature.tscn').write_text('\n'.join(scene)+'\n')
    report = dict(source=str(SOURCE.relative_to(ROOT)), sha256=hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
                  source_size=source.size, source_mode=source.mode, assets=manifest, scale=SCALE,
                  placements=placements, route_components=route_labels,
                  protected_collision_pixels=int(np.count_nonzero(blocked & protected)),
                  check='PASS')
    (DOC / 'validation.json').write_text(json.dumps(report, indent=2)+'\n')
    print('PASS:', len(manifest), 'extractions,', len(placements), 'placements;', route_labels)

if __name__ == '__main__':
    main()
