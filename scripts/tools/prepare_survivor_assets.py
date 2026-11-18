"""Extract the supplied Survivor sheets without modifying the originals.

Requires Pillow, NumPy and SciPy. Run from any working directory.
"""
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / "assets/survivor"
NAMES = {
    1: "grass grass_light grass_dark clearing clearing_light clearing_dark meadow meadow_flowers meadow_sparse",
    2: "peach_tree peach_small green_tree green_small bush flower_bush rock flowers",
    3: "hero",
    4: "monkey",
    5: "hero_staff staff bow magic shield peach_bomb spear sword arrow magic_bolt golden_bolt peach_bolt",
    6: "slime",
    7: "boar",
    8: "boss",
    9: "gold gold_stack xp xp_large heart peach chest crystal",
    10: "slash_small slash slash_large impact velocity ground_hit dust dust_large",
    11: "mana magic_hit curse curse_hit rune summon magic_burst enchant",
    12: "hp_frame xp_frame gold_icon army_icon timer_frame level_badge pause_icon shop_icon boss_hp danger_dot settings_icon start_icon",
    13: "shop_banner card card_active card_locked buy buy_disabled cancel refresh recruit upgrade confirm price",
    14: "title play pause_banner settings victory defeat restart home",
    15: "lane_green lane_gold lane_alt spawn alert alert_large boss_alert dash",
}
ROWS = {1: 3, 3: 3, 4: 3, 5: 3, 12: 3, 13: 3}
# These sheets do not follow a uniform 4-column grid.
COLUMN_CUTS = {
    2: [[0, 530, 875, 1360, 1774], [0, 450, 880, 1320, 1774]],
    10: [[0, 445, 864, 1362, 1774], [0, 448, 875, 1325, 1774]],
    12: [[0, 437, 878, 1104, 1448], [0, 463, 850, 1125, 1448], [0, 681, 883, 1135, 1448]],
    13: [[0, 476, 785, 1120, 1448], [0, 439, 870, 1128, 1448], [0, 376, 723, 1016, 1448]],
    14: [[0, 583, 1047, 1466, 1774], [0, 568, 1036, 1408, 1774]],
}
ROW_CUTS = {2: [0, 494, 887], 5: [0, 388, 745, 1086],
            10: [0, 480, 887], 12: [0, 347, 705, 1086], 13: [0, 443, 711, 1086]}


def extract(cell, sheet):
    pixels = np.array(cell.convert("RGBA"))
    alpha = pixels[:, :, 3]
    if sheet in (2, 5):
        alpha[alpha < 8] = 0
    else:
        rgb = pixels[:, :, :3].astype(np.int16)
        chroma = np.ptp(rgb, axis=2)
        if sheet in (10, 11, 15):
            # Soft effects fade into near-neutral backdrops. Remove the
            # neutral pattern even where it continues inside a glowing ring.
            alpha[:] = np.minimum(alpha, np.clip((chroma - 8) * 10, 0, 255))
        else:
            neutral = (chroma < 15) & (rgb.min(axis=2) > 180)
            border = np.zeros(neutral.shape, dtype=bool)
            border[[0, -1], :] = True
            border[:, [0, -1]] = True
            alpha[ndimage.binary_propagation(border & neutral, mask=neutral)] = 0

    # Discard isolated background speckles, keeping small accent groups.
    labels, _ = ndimage.label(alpha > 0, structure=np.ones((3, 3)))
    counts = np.bincount(labels.ravel())
    alpha[(counts < 30)[labels]] = 0
    result = Image.fromarray(pixels)
    bounds = result.getbbox()
    if not bounds:
        raise ValueError(f"Empty cell in sheet {sheet}")
    return result.crop(bounds), bounds


def main():
    DEST.mkdir(exist_ok=True)
    manifest = {}
    for sheet, entries in NAMES.items():
        source, = (ROOT / "assets/inbox").glob(f"{sheet:03d}-*.png")
        art = Image.open(source)
        rows = ROWS.get(sheet, 2)
        cols = 3 if sheet == 1 else 4
        ys = ROW_CUTS.get(sheet, [round(i * art.height / rows) for i in range(rows + 1)])
        names = entries.split()
        actor = len(names) == 1
        if actor:
            names = [f"{entries}_{i:02d}" for i in range(rows * cols)]
        frames = []
        for index, name in enumerate(names):
            row, col = divmod(index, cols)
            xs = COLUMN_CUTS.get(sheet, [[round(i * art.width / cols) for i in range(cols + 1)]] * rows)[row]
            box = (xs[col], ys[row], xs[col + 1], ys[row + 1])
            cell = art.crop(box)
            if sheet == 1:
                # Keep away from AI-generated joins between the adjacent fills.
                bounds = (6, 6, cell.width - 6, cell.height - 6)
                sprite = cell.crop(bounds)
            else:
                sprite, bounds = extract(cell, sheet)
            sprite.save(DEST / f"{name}.png", optimize=True)
            frames.append({"name": name, "source_rect": [
                box[0] + bounds[0], box[1] + bounds[1], sprite.width, sprite.height]})
        manifest[f"{sheet:03d}"] = {
            "source": str(source.relative_to(ROOT)), "size": list(art.size),
            "sha256": hashlib.sha256(source.read_bytes()).hexdigest(), "frames": frames,
        }
    (DEST / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")


if __name__ == "__main__":
    main()
