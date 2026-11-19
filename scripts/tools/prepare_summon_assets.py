"""Extract the 10 commander sheets as named RGBA parts and record provenance."""
import argparse
import hashlib
import io
import json
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

from prepare_survivor_enemies import extract, put

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/archive/adapted/survivor/summon"
DEST = ROOT / "assets/survivor/summon"
SHEETS = {
    1: "portrait_staff portrait_archer portrait_mage portrait_tank portrait_healer portrait_plain portrait_elite portrait_ready",
    2: "tray card card_hover card_selected card_disabled price_plate capacity_plate tier_button",
    3: "staff bow mage_staff shield healer_staff elite_shield elite_bow elite_staff medicine armor horn beads",
    4: "unit_00 unit_01 unit_02 unit_03 unit_04 unit_05 unit_06 unit_07 unit_08 unit_09 unit_10 unit_11",
    5: "purchase_flash purchase_gold purchase_success summon_ring summon_column redeploy roster_full rejected",
    6: "strike_spark impact_star guard_ring guard_dome heal_sparks heal_floor heal_column heal_plus guard_upgrade heal_upgrade guard_break heal_swirl",
    7: "role_staff role_archer role_mage role_tank role_healer status_damage status_speed status_target status_hp status_defense status_upgrade status_army",
    8: "ai_advance ai_guard ai_attack ai_reinforce ai_retreat ai_danger ai_heal ai_breach",
    9: "upgrade_spark upgrade_burst upgrade_spiral upgrade_star upgrade_attack upgrade_defense upgrade_heal upgrade_speed upgrade_level upgrade_crown upgrade_evolve upgrade_confirm",
    10: "shop_tab shop_tab_active card_rare card_legend train_button info_button confirm_badge sale_badge locked_badge close_badge selection_glow reroll_badge",
}
COLUMN_CUTS = {
    2: [(0, 521, 917, 1354, 1774), (0, 455, 936, 1420, 1774)],
    10: [(0, 362, 733, 1078, 1448), (0, 385, 725, 1070, 1448), (0, 369, 716, 1094, 1448)],
}
ROW_CUTS = {3: (0, 370, 731, 1086), 10: (0, 375, 698, 1086)}


def black_matte(cell: Image.Image) -> tuple:
    pixels = np.array(cell)
    colors = pixels[:, :, :3].astype(float)
    brightness = colors.max(axis=2)
    strength = np.clip((brightness - 7) / 215.0, 0.0, 1.0)
    pixels[:, :, 3] = (strength * 255).round().astype(np.uint8)
    pixels[:, :, :3] = np.clip(colors / np.maximum(strength[:, :, None], 0.03), 0, 255).astype(np.uint8)
    islands, _ = ndimage.label(pixels[:, :, 3] > 0, structure=np.ones((3, 3)))
    areas = np.bincount(islands.ravel())
    pixels[(areas < 30)[islands], 3] = 0
    pixels[pixels[:, :, 3] == 0, :3] = 0
    sprite = Image.fromarray(pixels)
    bounds = sprite.getbbox()
    if bounds is None:
        raise ValueError("Empty effect cell")
    return sprite.crop(bounds), bounds


def build(check: bool) -> None:
    if not check:
        DEST.mkdir(parents=True, exist_ok=True)
    manifest = {}
    for index, ids in SHEETS.items():
        names = ids.split()
        source, = SOURCE.glob(f"{index:03d}-*.png")
        original = Image.open(source)
        native = "A" in original.mode
        rgba = original.convert("RGBA")
        rows = len(names) // 4
        ys = ROW_CUTS.get(index, tuple(round(i * rgba.height / rows) for i in range(rows + 1)))
        columns = tuple(round(i * rgba.width / 4) for i in range(5))
        frames = []
        for i, name in enumerate(names):
            row, col = divmod(i, 4)
            xs = COLUMN_CUTS.get(index, [columns] * rows)[row]
            cell = rgba.crop((xs[col], ys[row], xs[col + 1], ys[row + 1]))
            sprite, box = black_matte(cell) if index == 5 else extract(cell, native)
            # Transparent inset protects the silhouette when mipmapped.
            inset = 3
            output = Image.new("RGBA", (sprite.width + 2 * inset, sprite.height + 2 * inset))
            output.paste(sprite, (inset, inset))
            lo, hi = output.getchannel("A").getextrema()
            if lo != 0 or hi < 32:
                raise ValueError(f"Unexpected alpha in {name}: {lo}..{hi}")
            pivot_y = output.height - inset if index == 4 else output.height / 2
            stream = io.BytesIO()
            output.save(stream, format="PNG", optimize=True)
            put(DEST / f"{name}.png", stream.getvalue(), check)
            frames.append({"id": name, "cell": [col, row],
                           "crop": [xs[col] + box[0], ys[row] + box[1], sprite.width, sprite.height],
                           "size": list(output.size), "pivot": [output.width / 2, pivot_y],
                           "alpha_range": [lo, hi]})
        manifest[f"{index:03d}"] = {
            "source": source.relative_to(ROOT).as_posix(),
            "sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
            "source_size": list(original.size),
            "source_mode": original.mode,
            "background": "native alpha" if native else ("black matte keyed" if index == 5 else "light matte keyed"),
            "frames": frames,
        }
    put(DEST / "manifest.json", (json.dumps(manifest, indent=2) + "\n").encode(), check)
    print(f"{'Verified' if check else 'Built'} {len(manifest)} sheets, {sum(len(s['frames']) for s in manifest.values())} sprites")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    build(parser.parse_args().check)
