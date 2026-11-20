"""Extract the newly provided combat VFX sheets into assets/survivor/vfx/ without modifying originals."""
import argparse
import hashlib
import io
import json
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/archive/adapted/survivor/vfx"
DEST = ROOT / "assets/survivor/vfx"

# Sheet definitions: id -> (glob_hint, names, rows, mode_note)
SHEETS = {
    1: (
        "advanced-melee-slash-vfx",
        "melee_spark_00 melee_arc_01 melee_arc_02 melee_arc_03 "
        "melee_slam_00 melee_heavy_arc melee_impact_star melee_cloud_trail "
        "melee_thrust melee_cross_slash melee_combo_burst melee_orbit_fade",
        3,
        "Advanced melee slash and combo VFX (4x3 RGBA).",
    ),
    2: (
        "advanced-arrow-projectile-vfx",
        "bow_spark bow_charge_star bow_release_burst bow_power_ring "
        "arrow_trail_00 arrow_trail_01 arrow_trail_02 arrow_volley_trail "
        "arrow_hit_spark arrow_hit_burst arrow_hit_shatter arrow_miss_dust",
        3,
        "Advanced arrow release, travel trail and impact VFX (4x3 RGBA).",
    ),
    3: (
        "advanced-magic-projectile-and",
        "magic_charge_00 magic_charge_01 magic_charge_02 magic_cast_pillar "
        "magic_bolt_00 magic_lance_01 magic_comet_02 magic_wave_03 "
        "magic_aoe_00 magic_aoe_01 magic_aoe_02 magic_aoe_03",
        3,
        "Advanced magic charge, projectiles and AoE explosions (4x3 RGBA, background veil cleaned).",
    ),
    5: (
        "enemy-reaction-overlay-effect",
        "enemy_hurt_flash enemy_heavy_hurt enemy_stun_stars enemy_daze_swirl "
        "enemy_poison_cloud enemy_defeat_puff_00 enemy_defeat_puff_01 enemy_defeat_beam",
        2,
        "Enemy hurt, stun, daze, poison and defeat reaction overlays (4x2 RGBA).",
    ),
    6: (
        "ground-contact-and-motion-fee",
        "dust_step dust_puff dust_dash_arc dust_dash_cloud "
        "dust_land_small dust_land_heavy dust_ring_impact dust_ring_scatter "
        "dust_redeploy dust_summon_beam dust_guard_arch dust_swirl_leaf",
        3,
        "Movement, landing, formation and summon dust VFX (4x3 RGBA).",
    ),
    7: (
        "healing-and-support-skill-vfx",
        "heal_sparkle heal_ring_rise heal_cross_leaf heal_burst_cross "
        "heal_wave_plus support_buff_dome support_shield_up heal_pillar_leaf "
        "guard_blue_shield heal_sprout_glow guard_blue_dome heal_ribbon_rise",
        3,
        "Healing, support buff and defensive shield VFX (4x3 RGBA).",
    ),
    8: (
        "boss-skill-telegraph-and-heav",
        "boss_ring_00 boss_ring_01 boss_pillar_charge boss_danger_alert "
        "boss_slam_spike boss_shock_ripple boss_boulder_burst boss_flame_sweep "
        "boss_magma_crack boss_dust_cloud boss_rage_pillar boss_nova_burst",
        3,
        "Boss telegraph, shockwave and heavy impact VFX (4x3 RGB on black matte keyed to RGBA).",
    ),
}

ROW_CUTS = {
    3: [0, 363, 681, 1086],
    8: [0, 362, 673, 1086],
}

COLUMN_CUTS = {
    2: [[0, 362, 724, 1086, 1448], [0, 362, 713, 1086, 1448], [0, 362, 724, 1086, 1448]],
    3: [[0, 362, 717, 1086, 1448], [0, 359, 703, 1072, 1448], [0, 362, 641, 1081, 1448]],
    8: [[0, 362, 715, 1073, 1448], [0, 362, 719, 1081, 1448], [0, 355, 702, 1050, 1448]],
}


def clean_cell(cell: Image.Image, source_mode: str, sheet: int) -> tuple[Image.Image, tuple[int, int, int, int]]:
    pixels = np.array(cell).copy()
    alpha = pixels[:, :, 3]
    rgb = pixels[:, :, :3].astype(np.float32)

    if source_mode == "RGBA":
        if sheet == 3:
            # Sheet 003 has a background alpha veil (up to ~60) in empty regions.
            chroma = np.ptp(rgb, axis=2)
            veil = (alpha <= 68) & ((chroma < 45) | (alpha <= 24))
            border = np.zeros(veil.shape, dtype=bool)
            border[[0, -1], :] = True
            border[:, [0, -1]] = True
            bg = ndimage.binary_propagation(border & veil, mask=veil)
            alpha[bg] = 0
            alpha[(alpha > 0) & (alpha < 45) & (chroma < 32)] = 0
        else:
            alpha[alpha < 12] = 0
    else:
        # Sheet 008: pure black RGB matte -> luminous un-premultiplied RGBA.
        brightness = rgb.max(axis=2)
        strength = np.clip((brightness - 9.0) / 210.0, 0.0, 1.0)
        # Preserve solid dark brown rock/crack outlines inside the sprite body.
        opaque_core = ndimage.binary_fill_holes(ndimage.binary_closing(strength > 0.22, iterations=3))
        strength = np.where(opaque_core & (brightness > 22.0), np.maximum(strength, 0.92), strength)
        a_u8 = np.clip(np.round(strength * 255.0), 0, 255).astype(np.uint8)
        alpha[:] = a_u8
        a_f = np.maximum(strength[:, :, None], 0.06)
        pixels[:, :, :3] = np.clip(rgb / a_f, 0, 255).astype(np.uint8)

    labels, _ = ndimage.label(alpha > 0, structure=np.ones((3, 3)))
    counts = np.bincount(labels.ravel())
    alpha[(counts < 20)[labels]] = 0
    pixels[:, :, 3] = alpha
    pixels[alpha == 0, :3] = 0

    result = Image.fromarray(pixels)
    bounds = result.getbbox()
    if bounds is None:
        raise ValueError(f"Empty extracted cell in VFX sheet {sheet:03d}")
    return result.crop(bounds), bounds


def put(path: Path, data: bytes, check: bool) -> None:
    if check:
        if not path.exists() or path.read_bytes() != data:
            raise ValueError(f"File differs from expected build: {path.relative_to(ROOT)}")
    else:
        path.write_bytes(data)


def build(check: bool) -> None:
    if not check:
        DEST.mkdir(parents=True, exist_ok=True)
    manifest = {
        "missing_sheets": [
            {
                "sheet": "004",
                "expected": "Hit feedback VFX (normal, heavy, critical, blocked)",
                "status": "MISSING_FROM_INBOX",
                "mitigation": "Reuses validated hit feedback sprites from assets/survivor/combat/ (hit_light, hit_spark, hit_burst, hit_heavy_crit, hit_shards, hit_sweep) plus enemy_hurt_flash / enemy_heavy_hurt (005) and guard_blue_shield / guard_blue_dome (007).",
            }
        ],
        "sheets": {},
    }
    total = 0
    for sheet, (hint, names_spec, rows, note) in SHEETS.items():
        matches = list(SOURCE.glob(f"{sheet:03d}-*{hint}*.png"))
        if len(matches) != 1:
            raise FileNotFoundError(f"Expected 1 source for VFX sheet {sheet:03d} ({hint}), found {matches}")
        source = matches[0]
        original = Image.open(source)
        art = original.convert("RGBA")
        ys = ROW_CUTS.get(sheet, [round(i * art.height / rows) for i in range(rows + 1)])
        default_cols = [round(i * art.width / 4) for i in range(5)]
        names = names_spec.split()
        frames = []
        for idx, name in enumerate(names):
            row, col = divmod(idx, 4)
            xs = COLUMN_CUTS.get(sheet, [default_cols] * rows)[row]
            box = (xs[col], ys[row], xs[col + 1], ys[row + 1])
            sprite, bounds = clean_cell(art.crop(box), original.mode, sheet)
            inset = 3
            canvas = Image.new("RGBA", (sprite.width + inset * 2, sprite.height + inset * 2))
            canvas.paste(sprite, (inset, inset))
            alo, ahi = canvas.getchannel("A").getextrema()
            if alo != 0 or ahi < 120:
                raise ValueError(f"Unexpected alpha range in {name}: {alo}..{ahi}")
            buf = io.BytesIO()
            canvas.save(buf, format="PNG", optimize=True)
            put(DEST / f"{name}.png", buf.getvalue(), check)
            frames.append({
                "id": name,
                "cell": [col, row],
                "source_rect": [box[0] + bounds[0], box[1] + bounds[1], sprite.width, sprite.height],
                "size": list(canvas.size),
                "pivot": [canvas.width / 2.0, canvas.height / 2.0],
                "alpha_range": [alo, ahi],
            })
            total += 1
        manifest["sheets"][f"{sheet:03d}"] = {
            "source": source.relative_to(ROOT).as_posix(),
            "sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
            "source_size": list(original.size),
            "source_mode": original.mode,
            "background": "native RGBA cleaned" if original.mode == "RGBA" else "black matte keyed to RGBA",
            "note": note,
            "frames": frames,
        }

    serialized = (json.dumps(manifest, indent=2) + "\n").encode()
    put(DEST / "manifest.json", serialized, check)
    print(f"{'PASS: Verified' if check else 'Built'} {len(manifest['sheets'])} VFX sheets, {total} RGBA sprites -> {DEST.relative_to(ROOT)}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    build(parser.parse_args().check)
