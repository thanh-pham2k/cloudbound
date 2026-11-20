"""Extract the 8 Base Asset Cheatsheet Combat VFX sheets (001..008, 3x2 each) into assets/survivor/."""
from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

from prepare_base_cheatsheet_pack import _find_cut, crop_alpha, remove_white_bg

ROOT = Path(__file__).resolve().parents[2]
INBOX = ROOT / "assets/inbox"
ARCHIVE = ROOT / "assets/archive/adapted/survivor/vfx_cheatsheet_v1"
SURVIVOR = ROOT / "assets/survivor"
VFX_STORE = SURVIVOR / "vfx_cheatsheet"


def source_path(prefix: str) -> Path:
    for folder in (INBOX, ARCHIVE):
        matches = sorted(folder.glob(f"{prefix}-*.png"))
        if matches:
            return matches[0]
    raise FileNotFoundError(f"Missing VFX source sheet {prefix}")


def remove_white_bg_vfx(cell: Image.Image, outlined: bool = False) -> Image.Image:
    """Remove white background cleanly for glowing VFX using soft un-premultiply on exterior glow."""
    if outlined:
        return remove_white_bg(cell, clear_holes=False)

    rgb = np.array(cell.convert("RGB"), dtype=np.float32)
    min_c = rgb.min(axis=2)
    max_c = rgb.max(axis=2)
    chroma = max_c - min_c

    # Distance from pure white (0 = pure white, 255 = rich dark/saturated color).
    ink = np.maximum(255.0 - min_c, chroma)

    # Interior hot-white cores (surrounded by colored VFX) should stay opaque white.
    bg_seed = ink < 10.0
    border = np.zeros(bg_seed.shape, dtype=bool)
    border[[0, -1], :] = True
    border[:, [0, -1]] = True
    exterior_bg = ndimage.binary_propagation(border & bg_seed, mask=(ink < 28.0))

    # Smooth alpha ramp for glowing edges connected to exterior background.
    alpha_f = np.clip((ink - 6.0) / 110.0, 0.0, 1.0)
    # Keep enclosed hot-white cores solid opaque.
    interior_core = ~ndimage.binary_dilation(exterior_bg, iterations=12)
    alpha_f = np.where(interior_core, np.maximum(alpha_f, 1.0), alpha_f)
    alpha_f = np.where(exterior_bg & (ink < 8.0), 0.0, alpha_f)

    # Un-premultiply RGB against white background for translucent glow pixels.
    safe_a = np.maximum(alpha_f, 0.08)[..., None]
    unpremul = np.clip((rgb - 255.0 * (1.0 - safe_a)) / safe_a, 0.0, 255.0)
    final_rgb = np.where(alpha_f[..., None] < 0.99, unpremul, rgb)

    out = np.zeros((rgb.shape[0], rgb.shape[1], 4), dtype=np.uint8)
    out[:, :, :3] = np.round(final_rgb).astype(np.uint8)
    out[:, :, 3] = np.round(alpha_f * 255.0).astype(np.uint8)
    return Image.fromarray(out)


def split_vfx_grid(img: Image.Image, cols: int = 3, rows: int = 2, outlined: bool = False) -> list[Image.Image]:
    rgb = np.array(img.convert("RGB"), dtype=np.int16)
    non_bg = (rgb.min(axis=2) < 238) | ((rgb.max(axis=2) - rgb.min(axis=2)) > 18)
    row_profile = non_bg.sum(axis=1)
    row_rad = max(8, img.height // (rows * 10))
    ys = [0] + [_find_cut(row_profile, round(r * img.height / rows), row_rad) for r in range(1, rows)] + [img.height]
    col_rad = max(8, img.width // (cols * 8))
    cells = []
    for r in range(rows):
        y0, y1 = ys[r], ys[r + 1]
        col_profile = non_bg[y0:y1, :].sum(axis=0)
        xs = [0] + [_find_cut(col_profile, round(c * img.width / cols), col_rad) for c in range(1, cols)] + [img.width]
        for c in range(cols):
            box = (xs[c], y0, xs[c + 1], y1)
            cells.append(crop_alpha(remove_white_bg_vfx(img.crop(box), outlined=outlined)))
    return cells


def sync_vfx_manifests() -> None:
    counts = {}
    for sub in ("combat", "vfx"):
        mp = SURVIVOR / sub / "manifest.json"
        if not mp.exists():
            continue
        data = json.loads(mp.read_text(encoding="utf-8"))
        updated = 0

        def walk(obj):
            nonlocal updated
            if isinstance(obj, dict):
                for k, v in obj.items():
                    if isinstance(v, dict) and "size" in v and isinstance(v["size"], list) and len(v["size"]) == 2:
                        for name in (v.get("name"), v.get("id"), k):
                            if isinstance(name, str):
                                fp = SURVIVOR / sub / (name if name.endswith(".png") else f"{name}.png")
                                if fp.exists():
                                    w, h = Image.open(fp).size
                                    if v["size"] != [w, h]:
                                        v["size"] = [w, h]
                                        updated += 1
                                    break
                    walk(v)
            elif isinstance(obj, list):
                for item in obj:
                    if isinstance(item, dict) and "size" in item and isinstance(item["size"], list) and len(item["size"]) == 2:
                        name = item.get("name") or item.get("id")
                        if isinstance(name, str):
                            fp = SURVIVOR / sub / (name if name.endswith(".png") else f"{name}.png")
                            if fp.exists():
                                w, h = Image.open(fp).size
                                if item["size"] != [w, h]:
                                    item["size"] = [w, h]
                                    updated += 1
                    walk(item)

        walk(data)
        mp.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
        counts[sub] = updated
    print("Synced VFX manifests:", counts)


def main() -> None:
    VFX_STORE.mkdir(parents=True, exist_ok=True)
    # (code, name, outlined, index -> runtime targets relative to assets/survivor/)
    specs = [
        ("001", "slash", False, {
            0: ["vfx/melee_spark_00.png", "combat/slash_00.png"],
            1: ["vfx/melee_arc_01.png", "combat/slash_01.png"],
            2: ["vfx/melee_arc_02.png", "combat/slash_02.png", "combat/slash_03.png"],
            3: ["vfx/melee_orbit_fade.png", "combat/slash_06.png", "combat/slash_07.png"],
            4: ["vfx/melee_heavy_arc.png", "vfx/melee_arc_03.png", "combat/slash_04.png", "combat/slash_05.png"],
            5: ["vfx/melee_cross_slash.png", "vfx/melee_impact_star.png"],
        }),
        ("002", "arrow_flight", True, {
            0: ["combat/arrow_fly_00.png", "vfx/arrow_trail_00.png"],
            1: ["combat/arrow_fly_01.png", "vfx/arrow_trail_01.png"],
            2: ["combat/arrow_fly_02.png", "vfx/arrow_trail_02.png"],
            3: ["combat/arrow_release.png", "vfx/bow_release_burst.png"],
            4: ["vfx/arrow_volley_trail.png"],
            5: ["combat/arrow_shatter.png", "vfx/arrow_hit_shatter.png"],
        }),
        ("003", "hit_spark", False, {
            0: ["combat/hit_light.png", "vfx/arrow_hit_spark.png"],
            1: ["combat/hit_spark.png"],
            2: ["combat/hit_shards.png"],
            3: ["vfx/bow_spark.png"],
            4: ["combat/hit_sweep.png"],
            5: ["combat/arrow_spark.png"],
        }),
        ("004", "hit_burst", False, {
            0: ["combat/hit_burst.png", "vfx/arrow_hit_burst.png"],
            1: ["combat/hit_heavy_crit.png", "vfx/melee_combo_burst.png"],
            3: ["combat/arrow_burst.png"],
        }),
        ("005", "magic_charge", False, {
            0: ["combat/magic_charge_00.png", "vfx/magic_charge_00.png"],
            1: ["combat/magic_charge_01.png", "vfx/magic_charge_01.png"],
            2: ["combat/magic_orb_00.png", "vfx/magic_charge_02.png"],
            3: ["vfx/magic_aoe_00.png"],
            4: ["combat/magic_orb_01.png", "vfx/magic_bolt_00.png", "vfx/magic_comet_02.png"],
            5: ["vfx/magic_cast_pillar.png"],
        }),
        ("006", "magic_impact", False, {
            0: ["combat/magic_impact_00.png", "vfx/magic_aoe_01.png"],
            1: ["combat/magic_impact_01.png", "vfx/magic_aoe_02.png"],
            2: ["combat/magic_impact_02.png", "vfx/magic_aoe_03.png"],
            3: ["combat/magic_impact_03.png"],
            4: ["vfx/magic_wave_03.png"],
        }),
        ("007", "boss_telegraph", False, {
            0: ["vfx/boss_ring_00.png"],
            1: ["combat/boss_telegraph_ring.png", "vfx/boss_ring_01.png"],
            2: ["vfx/boss_shock_ripple.png"],
            4: ["combat/boss_rage_vortex.png", "vfx/boss_rage_pillar.png"],
            5: ["vfx/boss_danger_alert.png"],
        }),
        ("008", "boss_slam", False, {
            0: ["vfx/boss_slam_spike.png"],
            1: ["combat/boss_slam_burst.png", "vfx/boss_nova_burst.png"],
            2: ["combat/boss_shock_ring.png"],
            3: ["combat/boss_ground_crack.png", "vfx/boss_magma_crack.png"],
            4: ["combat/boss_rock_debris.png", "vfx/boss_boulder_burst.png"],
            5: ["combat/boss_dust_billow.png", "vfx/boss_dust_cloud.png"],
        }),
    ]

    manifest: dict[str, dict] = {}
    for code, name, outlined, mapping in specs:
        src = source_path(code)
        cells = split_vfx_grid(Image.open(src), 3, 2, outlined=outlined)
        saved_all = []
        for idx, cell in enumerate(cells):
            out = VFX_STORE / f"{name}_{idx:02d}.png"
            cell.save(out)
            saved_all.append(str(out.relative_to(ROOT)))
            for rel in mapping.get(idx, []):
                cell.save(SURVIVOR / rel)
        manifest[code] = {
            "vfx": name,
            "source": str((ARCHIVE / src.name).relative_to(ROOT)),
            "frames": saved_all,
            "runtime_targets": [p for paths in mapping.values() for p in paths],
        }
        print(f"[{code}] {name}: extracted 6 frames + {len(manifest[code]['runtime_targets'])} runtime targets")

    (VFX_STORE / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    sync_vfx_manifests()


if __name__ == "__main__":
    main()
