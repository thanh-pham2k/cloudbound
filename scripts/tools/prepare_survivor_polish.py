"""Extract the 14 Survivor polish sheets without modifying the source PNGs."""
import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / "assets/survivor/polish"
SHEETS = {
    2: ("animation-sprite-sheet-for-sun", "wukong", 3, "commander pose"),
    3: ("animation-sprite-sheet-for-the-existing-baby", "soldier", 3, "shared soldier pose"),
    4: ("sequential-summoning", "summon", 2, "summoning sequence"),
    5: ("animation-sprite-sheet-of-a-baby-monkey-being", "arrival", 2, "magical arrival silhouette"),
    6: ("commander-and-formation", "command_arrow rally_ring command_standard stand_together shift_dust rally_beam reserve_guard command_spark", 2, "independent effect"),
    7: ("weapon-combat-effects", "staff_arc ruyi_arc staff_contact staff_dust bow_release arrow_streak arrow_contact arrow_ground magic_cast magic_bolt magic_contact magic_area", 3, "independent effect"),
    8: ("enemy-spawning", "enemy_entry boar_entry slime_entry enemy_death enemy_chip enemy_hit slime_death boar_death", 2, "independent effect"),
    9: ("boar-king-boss-combat", "boss_entry boss_shockwave boss_warning boss_charge boss_impact boss_slam boss_rage boss_death", 2, "independent effect"),
    10: ("combat-feedback", "hit_chip hit_flash hit_heavy hit_critical move_dust impact_dust attack_swish guard_flash guard_break daze danger_ping reward_flash", 3, "independent effect"),
    11: ("gold-and-xp-collection", "gold_drop gold_collect gold_trail level_glint xp_drop xp_collect xp_trail level_beam", 2, "independent effect"),
    12: ("shop-interaction", "shop_success shop_coin shop_recruit shop_equip shop_upgrade shop_chest shop_card shop_refresh shop_low_gold shop_locked shop_confirm shop_closed", 3, "independent effect"),
    13: ("gameplay-warning", "warning_green warning_gold warning_orange warning_red warning_flag reinforcement warning_boss warning_breach", 2, "independent effect"),
    14: ("victory-and-defeat", "victory_burst victory_petals victory_spark victory_flare defeat_break defeat_smoke defeat_beam defeat_petals", 2, "independent effect"),
    15: ("ambient-nature", "grass_00 grass_01 grass_02 grass_03 blossom leaf pollen breeze", 2, "ambient effect"),
}
ROW_CUTS = {7: [0, 375, 687, 1086], 10: [0, 365, 718, 1086], 12: [0, 369, 726, 1086]}
COLUMN_CUTS = {
    7: [[0, 362, 724, 1060, 1448], [0, 362, 724, 1075, 1448], [0, 362, 724, 1045, 1448]],
    11: [[0, 443, 865, 1328, 1774], [0, 443, 887, 1330, 1774]],
    12: [[0, 376, 704, 1071, 1448], [0, 379, 730, 1052, 1448], [0, 370, 727, 1047, 1448]],
    14: [[0, 438, 855, 1255, 1774], [0, 444, 885, 1315, 1774]],
}
# Screen-space foot anchors from the source sheets, one X per pose.
FOOT_X = {
    2: [194, 551, 876, 1267, 192, 549, 933, 1259, 193, 553, 884, 1270],
    3: [204, 544, 899, 1246, 196, 562, 897, 1254, 187, 540, 893, 1260],
}
SUMMON_Y = [235, 284, 301, 318, 753, 741, 730, 722]
RESERVED = {
    "reserve_guard": "No guard order",
    "hit_critical": "No critical-hit mechanic",
    "guard_flash": "No shield block",
    "guard_break": "No guard break",
    "daze": "No stun mechanic",
    "shop_upgrade": "Weapons are equipped, not leveled",
    "shop_chest": "No loot chest in the shop",
    "shop_card": "No upgrade cards",
    "shop_refresh": "Fixed shop inventory",
    "shop_locked": "No unlock mechanic",
}


def extract(cell, mode, sheet):
    pixels = np.array(cell)
    alpha = pixels[:, :, 3]
    rgb = pixels[:, :, :3].astype(np.int16)
    if mode == "RGBA":
        alpha[alpha < 12] = 0
    else:
        chroma = np.ptp(rgb, axis=2)
        brightest = rgb.max(axis=2)
        if sheet in (5, 12):
            neutral = (chroma < 12) & (rgb.min(axis=2) > 219)
            border = np.zeros(neutral.shape, dtype=bool)
            border[[0, -1], :] = True
            border[:, [0, -1]] = True
            alpha[ndimage.binary_propagation(border & neutral, mask=neutral)] = 0
        else:
            # Estimate alpha against the baked light matte. Use both chroma
            # and darkness so purple smoke and pale blue glows survive.
            strength = np.maximum((chroma - 6) * (12 if sheet == 4 else 10),
                                  (238 - brightest) * 6)
            opacity = np.clip(strength, 0, 255)
            if sheet != 4:
                core = ndimage.binary_fill_holes(ndimage.binary_closing(opacity > 125, iterations=2))
                opacity[core & (brightest > 248) & (chroma <= 11)] = 245
            alpha[:] = opacity
            # Decontaminate white from partially transparent effect edges.
            a = np.maximum(alpha.astype(np.float32)[:, :, None] / 255, 0.04)
            pixels[:, :, :3] = np.clip((rgb - 250.0 * (1.0 - a)) / a, 0, 255).astype(np.uint8)
    labels, _ = ndimage.label(alpha > 0, structure=np.ones((3, 3)))
    counts = np.bincount(labels.ravel())
    alpha[(counts < (15 if sheet == 4 else 35))[labels]] = 0
    # Clear hidden RGB to improve compression and give the importer a clean edge.
    pixels[alpha == 0, :3] = 0
    if sheet == 5:
        pixels[alpha > 0, :3] = (255, 220, 135)
    result = Image.fromarray(pixels)
    bounds = result.getbbox()
    if bounds is None:
        raise ValueError(f"Empty extracted cell in sheet {sheet:03d}")
    return result.crop(bounds), bounds


def main(check=False):
    if not check:
        DEST.mkdir(exist_ok=True)
    manifest = {}
    for sheet, (hint, names, rows, role) in SHEETS.items():
        source, = (ROOT / "assets/inbox").glob(f"{sheet:03d}-*{hint}*.png")
        original = Image.open(source)
        art = original.convert("RGBA")
        ys = ROW_CUTS.get(sheet, [round(i * art.height / rows) for i in range(rows + 1)])
        names = names.split()
        if len(names) == 1:
            names = [f"{names[0]}_{i:02d}" for i in range(rows * 4)]
        frames = []
        limits = []
        for index, name in enumerate(names):
            row, col = divmod(index, 4)
            xs = COLUMN_CUTS.get(sheet, [[round(i * art.width / 4) for i in range(5)]] * rows)[row]
            box = (xs[col], ys[row], xs[col + 1], ys[row + 1])
            sprite, bounds = extract(art.crop(box), original.mode, sheet)
            x, y = box[0] + bounds[0], box[1] + bounds[1]
            pivot = [sprite.width / 2, sprite.height / 2]
            if sheet in FOOT_X:
                pivot = [FOOT_X[sheet][index] - x, sprite.height]
            elif sheet == 4:
                pivot = [sprite.width / 2, SUMMON_Y[index] - y]
            elif sheet in (5, 15) and (sheet == 5 or index < 4):
                pivot = [sprite.width / 2, sprite.height]
            native = [x, y, sprite.width, sprite.height]
            if sheet in FOOT_X:
                # Godot's centered sprite now places X at the source foot
                # anchor. The bottom edge remains the ground contact.
                left = max(int(pivot[0]), sprite.width - int(pivot[0]))
                padded = Image.new("RGBA", (left * 2, sprite.height))
                padded.paste(sprite, (left - int(pivot[0]), 0))
                sprite, pivot = padded, [left, sprite.height]
            elif sheet in (4, 5):
                # Register animated effects on matching canvases. The common
                # pivot allows the ring to grow without sliding on the ground.
                canvas = Image.new("RGBA", (448, 490))
                canvas.paste(sprite, (224 - round(pivot[0]), 340 - round(pivot[1])))
                sprite, pivot = canvas, [224, 340]
            output = DEST / f"{name}.png"
            alo, ahi = sprite.getchannel("A").getextrema()
            if alo != 0 or ahi < 32:
                raise ValueError(f"Unexpected alpha range for {name}: {alo}..{ahi}")
            if not all(0 <= coordinate <= bound for coordinate, bound in zip(pivot, sprite.size)):
                raise ValueError(f"Pivot falls outside {name}: {pivot}")
            if check:
                with Image.open(output) as saved:
                    if saved.mode != "RGBA" or saved.size != sprite.size or saved.tobytes() != sprite.tobytes():
                        raise ValueError(f"Extracted image differs from its source: {name}")
            else:
                sprite.save(output, optimize=True)
            frames.append({"name": name, "cell": [col, row], "source_rect": native,
                           "size": list(sprite.size), "pivot": pivot, "alpha_range": [alo, ahi],
                           "use": RESERVED.get(name, role), "integrated": name not in RESERVED})
            if min(bounds[0], bounds[1], box[2] - box[0] - bounds[2], box[3] - box[1] - bounds[3]) < 2:
                limits.append(name)
        manifest[f"{sheet:03d}"] = {
            "source": str(source.relative_to(ROOT)), "size": list(original.size),
            "source_mode": original.mode, "source_alpha_range": list(original.getchannel("A").getextrema()) if original.mode == "RGBA" else None,
            "background": "native alpha cleaned" if original.mode == "RGBA" else "baked light matte removed",
            "sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
            "near_cell_boundary": limits, "frames": frames,
        }
    path = DEST / "manifest.json"
    serialized = json.dumps(manifest, indent=2) + "\n"
    if check:
        if path.read_text() != serialized:
            raise ValueError("Manifest differs from current source hashes, dimensions or pivots")
        count = sum(len(sheet["frames"]) for sheet in manifest.values())
        print(f"PASS: {count} RGBA sprites and {len(manifest)} source sheets match the integration manifest")
    else:
        path.write_text(serialized)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="verify the PNGs and manifest without writing files")
    main(parser.parse_args().check)
