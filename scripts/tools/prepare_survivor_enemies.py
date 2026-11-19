"""Build runtime enemy atlases and Godot SpriteFrames from the 27 inbox PNGs.

Requires Pillow, NumPy and SciPy. The originals are read-only.
"""
import argparse
import hashlib
import io
import json
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / "assets/survivor/enemies"
IDS = (
    "forest_goblin shadow_wolf stone_golem goblin_archer mushroom_monster cave_bat "
    "bamboo_snake demon_rabbit armored_turtle stone_beetle wooden_treant fire_imp "
    "poison_toad ice_spirit mini_slime slime_splitter shaman_goblin ghost_lantern "
    "armored_goblin_captain giant_slime fire_fox_spirit iron_beetle phantom_wolf "
    "ancient_treant nine_tailed_fox bull_demon_king golden_dragon"
).split()
HEAVY = {3, 9, 10, 11, 16}
# Actual gutter cuts on tighter rows. Coordinates are in original pixels.
COLUMN_CUTS = {
    16: [(0, 387, 780, 1140, 1536)] * 2,
    17: [(0, 444, 887, 1330, 1774), (0, 444, 887, 1321, 1774)],
    19: [(0, 362, 724, 1086, 1448), (0, 365, 700, 1080, 1448), (0, 360, 721, 1068, 1448)],
    20: [(0, 362, 724, 1067, 1448), (0, 362, 715, 1086, 1448), (0, 362, 724, 1068, 1448)],
    21: [(0, 362, 723, 1080, 1448), (0, 362, 720, 1082, 1448), (0, 363, 718, 1070, 1448)],
    22: [(0, 362, 724, 1084, 1448), (0, 362, 721, 1067, 1448), (0, 362, 717, 1071, 1448)],
    23: [(0, 375, 724, 1077, 1448), (0, 364, 725, 1082, 1448), (0, 366, 723, 1077, 1448)],
    24: [(0, 368, 722, 1084, 1448), (0, 344, 718, 1086, 1448), (0, 368, 725, 1070, 1448)],
    25: [(0, 366, 718, 1078, 1448), (0, 366, 713, 1067, 1448), (0, 366, 725, 1068, 1448)],
    26: [(0, 382, 722, 1087, 1448), (0, 357, 714, 1069, 1448), (0, 354, 699, 1058, 1448)],
    27: [(0, 352, 701, 1072, 1448), (0, 354, 712, 1077, 1448), (0, 354, 713, 1071, 1448)],
}
ROW_CUTS = {24: (0, 350, 691, 1086)}
GUTTER = 6


def source_cell(art: Image.Image, box: tuple, index: int, pose: int) -> tuple:
    if index != 26 or pose not in (0, 1):
        return art.crop(box), box
    # Three detached alert marks belong to the second Bull pose. The cape
    # from the first pose extends further right below those marks.
    left, top, right, bottom = box
    if pose == 1:
        left = 348
    cell = art.crop((left, top, right, bottom))
    pixels = np.array(cell)
    if pose == 0:
        pixels[:130, 348 - left:, 3] = 0
    else:
        pixels[130:, :382 - left, 3] = 0
    return Image.fromarray(pixels), (left, top, right, bottom)


def extract(cell: Image.Image, native_alpha: bool) -> tuple[Image.Image, tuple]:
    pixels = np.array(cell)
    alpha = pixels[:, :, 3]
    if not native_alpha:
        rgb = pixels[:, :, :3].astype(np.int16)
        neutral = (np.ptp(rgb, axis=2) <= 13) & (rgb.min(axis=2) >= 218)
        border = np.zeros(neutral.shape, dtype=bool)
        border[[0, -1], :] = True
        border[:, [0, -1]] = True
        outside = ndimage.binary_propagation(border & neutral, mask=neutral)
        alpha[outside] = 0
        # Feather only the transition connected to the baked matte.
        rim = ndimage.binary_dilation(outside) & ~outside
        strength = np.maximum(np.ptp(rgb, axis=2) * 10, (248 - rgb.min(axis=2)) * 8)
        alpha[rim] = np.minimum(alpha[rim], np.clip(strength[rim], 0, 255))
    else:
        alpha[alpha < 12] = 0
    islands, _ = ndimage.label(alpha > 0, structure=np.ones((3, 3)))
    counts = np.bincount(islands.ravel())
    alpha[(counts < 20)[islands]] = 0
    pixels[alpha == 0, :3] = 0
    result = Image.fromarray(pixels)
    bounds = result.getbbox()
    if not bounds:
        raise ValueError("An enemy cell has no visible pixels")
    return result.crop(bounds), bounds


def clips(index: int) -> dict:
    if index <= 18:
        return {
            "idle": [0], "move": [1, 2, 3], "attack": [4, 5],
            "hurt": [6], "dead": [7],
        }
    attack = [1, 4, 5, 8, 6, 7]
    if index == 20:
        attack = [1, 4, 5, 8, 9, 7]
    return {
        "idle": [0], "move": [2, 3], "attack": attack,
        "hurt": [6, 10] if index == 20 else [9, 10], "dead": [11],
    }


def sprite_frames(id_: str, boxes: list, animation: dict) -> bytes:
    text = ["[gd_resource type=\"SpriteFrames\" format=3]", "",
            f'[ext_resource type="Texture2D" path="res://assets/survivor/enemies/{id_}.png" id="1"]']
    for i, (x, y, w, h) in enumerate(boxes):
        text.extend(["", f'[sub_resource type="AtlasTexture" id="Frame_{i}"]',
                     'atlas = ExtResource("1")', f"region = Rect2({x}, {y}, {w}, {h})", "filter_clip = true"])
    text.extend(["", "[resource]", "animations = ["])
    entries = []
    for name, indexes in animation.items():
        frame_text = ', '.join(f'{{"duration": 1.0, "texture": SubResource("Frame_{i}")}}' for i in indexes)
        looping = "true" if name in ("idle", "move") else "false"
        speed = 6.0 if name == "idle" else (9.0 if name == "move" else 11.0)
        entries.append(f'{{"frames": [{frame_text}], "loop": {looping}, "name": &"{name}", "speed": {speed}}}')
    return ("\n".join(text) + "\n" + ",\n".join(entries) + "\n]\n").encode()


def put(path: Path, payload: bytes, check: bool) -> None:
    if check:
        if path.read_bytes() != payload:
            raise ValueError(f"Generated asset differs: {path}")
    else:
        path.write_bytes(payload)


def build(check: bool) -> None:
    if not check:
        DEST.mkdir(parents=True, exist_ok=True)
    manifest = {}
    for index, id_ in enumerate(IDS, 1):
        prefix = id_.replace("_", "-")
        source, = (ROOT / "assets/inbox").glob(f"{index:03d}-*for-{prefix}-*.png")
        original = Image.open(source)
        art = original.convert("RGBA")
        native_alpha = "A" in original.mode
        rows = 2 if index <= 18 else 3
        ys = ROW_CUTS.get(index, tuple(round(i * art.height / rows) for i in range(rows + 1)))
        default_xs = tuple(round(i * art.width / 4) for i in range(5))
        frames = []
        for i in range(4 * rows):
            row, col = divmod(i, 4)
            xs = COLUMN_CUTS.get(index, [default_xs] * rows)[row]
            box = (xs[col], ys[row], xs[col + 1], ys[row + 1])
            cell, box = source_cell(art, box, index, i)
            pose, bounds = extract(cell, native_alpha)
            crop = [box[0] + bounds[0], box[1] + bounds[1], *pose.size]
            frames.append((pose, crop))

        tier = "boss" if index >= 24 else ("heavy" if index >= 19 or index in HEAVY else "light")
        # Two texture pixels per gameplay pixel. Keep silhouettes in the
        # existing lane envelopes and preserve one scale for the whole clip.
        cap_w, cap_h, idle_h = {"light": (176, 140, 128), "heavy": (220, 150, 146),
                                "boss": (386, 298, 292)}[tier]
        scale = min(idle_h / frames[0][0].height, cap_w / max(p.width for p, _ in frames),
                    cap_h / max(p.height for p, _ in frames))
        cell_width, cell_height = cap_w + 2 * GUTTER, cap_h + 2 * GUTTER
        atlas = Image.new("RGBA", (4 * cell_width, rows * cell_height))
        regions = []
        entries = []
        for i, (pose, crop) in enumerate(frames):
            row, col = divmod(i, 4)
            pose = pose.resize((round(pose.width * scale), round(pose.height * scale)), Image.Resampling.LANCZOS)
            if pose.getchannel("A").getextrema()[1] < 20:
                raise ValueError(f"Pose alpha is too low: {id_}:{i}")
            x, y = col * cell_width + GUTTER, row * cell_height + GUTTER
            atlas.paste(pose, (x + (cap_w - pose.width) // 2, y + cap_h - pose.height))
            regions.append([x, y, cap_w, cap_h])
            entries.append({"index": i, "crop": crop, "region": regions[-1]})
        buffer = io.BytesIO()
        atlas.save(buffer, format="PNG", optimize=True)
        put(DEST / f"{id_}.png", buffer.getvalue(), check)
        poses = clips(index)
        put(DEST / f"{id_}.tres", sprite_frames(id_, regions, poses), check)
        manifest[id_] = {
            "sheet": index, "source": str(source.relative_to(ROOT)), "source_size": list(original.size),
            "source_mode": original.mode,
            "source_alpha_range": list(original.getchannel("A").getextrema()) if native_alpha else None,
            "sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
            "atlas_size": list(atlas.size), "tier": tier, "pivot": [cap_w / 2, cap_h],
            "gameplay_scale": 0.5, "clips": poses, "frames": entries,
        }
    put(DEST / "manifest.json", (json.dumps(manifest, indent=2) + "\n").encode(), check)
    print(f"{'Verified' if check else 'Built'} {len(manifest)} atlases and {sum(len(e['frames']) for e in manifest.values())} frames")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="verify the generated files without writing")
    build(parser.parse_args().check)
