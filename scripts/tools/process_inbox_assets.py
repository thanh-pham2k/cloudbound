#!/usr/bin/env python3
"""Process art sheets in assets/inbox/ into validated Godot 4 2D assets:
- B02 environment props (assets/base/environment/)
- B03 Hero (player_hero)
- B04 Enemies (enemy_melee = horned demon, enemy_ranged = cloud slime, enemy_tank = stone guardian)
- B05 Boss (boss_thunder_warden = stone guardian boss)
- B06 Heavenly Portal & Gateway (assets/base/vfx/ & assets/base/environment/architecture/)

Routes character/enemy/boss frames through tools/gameforge-kit/scripts/sprites/.
"""

from __future__ import annotations

import collections
import shutil
import sys
from datetime import datetime
from pathlib import Path
from PIL import Image

PROJECT_ROOT = Path(__file__).resolve().parents[2]
INBOX_DIR = PROJECT_ROOT / "assets" / "inbox"
TOOLKIT_SPRITES = PROJECT_ROOT / "tools" / "gameforge-kit" / "scripts" / "sprites"
sys.path.insert(0, str(TOOLKIT_SPRITES))

from atlas_packer import pack_task_atlas  # noqa: E402
from batch_planner import create_batch_manifest  # noqa: E402
from frame_normalizer import normalize_task  # noqa: E402
from godot_exporter import export_godot_spriteframes  # noqa: E402
from sprite_common import save_json  # noqa: E402
from validators import validate_atlas_structure  # noqa: E402


def remove_sheet_bg(
    im: Image.Image,
    seed_thresh: int = 240,
    seed_chroma: int = 12,
    min_region: int = 25,
    grow_thresh: int = 224,
    grow_chroma: int = 20,
) -> Image.Image:
    """Remove white/light-gray sheet background (including enclosed gaps) via BFS flood."""
    rgba = im.convert("RGBA")
    w, h = rgba.size
    px = rgba.load()

    def is_seed(r: int, g: int, b: int) -> bool:
        return r >= seed_thresh and g >= seed_thresh and b >= seed_thresh and (max(r, g, b) - min(r, g, b)) <= seed_chroma

    def is_grow(r: int, g: int, b: int) -> bool:
        return r >= grow_thresh and g >= grow_thresh and b >= grow_thresh and (max(r, g, b) - min(r, g, b)) <= grow_chroma

    visited = bytearray(w * h)
    for y in range(h):
        for x in range(w):
            idx = y * w + x
            if not visited[idx] and is_seed(*px[x, y][:3]):
                comp = [(x, y)]
                visited[idx] = 1
                q = collections.deque([(x, y)])
                touches_border = x == 0 or y == 0 or x == w - 1 or y == h - 1
                while q:
                    cx, cy = q.popleft()
                    for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                        if 0 <= nx < w and 0 <= ny < h:
                            nidx = ny * w + nx
                            if not visited[nidx] and is_grow(*px[nx, ny][:3]):
                                visited[nidx] = 1
                                comp.append((nx, ny))
                                q.append((nx, ny))
                                if nx == 0 or ny == 0 or nx == w - 1 or ny == h - 1:
                                    touches_border = True
                if touches_border or len(comp) >= min_region:
                    for cx, cy in comp:
                        px[cx, cy] = (0, 0, 0, 0)
    return rgba


def fit_bottom_center(crop: Image.Image, target_w: int, target_h: int, foot_y: int, margin: int = 6) -> Image.Image:
    bbox = crop.getbbox()
    trimmed = crop.crop(bbox) if bbox else crop
    cw, ch = trimmed.size
    avail_w = max(1, target_w - 2 * margin)
    avail_h = max(1, foot_y - margin)
    scale = min(avail_w / cw, avail_h / ch)
    nw = max(1, int(round(cw * scale)))
    nh = max(1, int(round(ch * scale)))
    resized = trimmed.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))
    ox = (target_w - nw) // 2
    oy = foot_y - nh
    canvas.paste(resized, (ox, oy), resized)
    return canvas


def split_n_frames(rgba: Image.Image, x0: int, x1: int, y0: int, y1: int, n: int) -> list[Image.Image]:
    """Split a horizontal strip of n frames using local-minimum column energy."""
    px = rgba.load()
    xs = [x for x in range(x0, x1) if any(px[x, y][3] > 0 for y in range(y0, y1))]
    if not xs:
        return []
    xmin, xmax = min(xs), max(xs) + 1
    span = xmax - xmin
    splits = [xmin]
    for k in range(1, n):
        exp = xmin + int(round(k * span / n))
        best_x = exp
        best_score = 10**9
        search_r = 4
        for x in range(max(xmin + 4, exp - search_r), min(xmax - 4, exp + search_r + 1)):
            fg = 0
            for y in range(y0, y1):
                r, g, b, a = px[x, y]
                if a > 0:
                    fg += 1 if (r > 210 and g > 190) else 4
            dist_pen = abs(x - exp) * 0.25
            if fg + dist_pen < best_score:
                best_score = fg + dist_pen
                best_x = x
        splits.append(best_x)
    splits.append(xmax)

    frames: list[Image.Image] = []
    for i in range(n):
        sub = rgba.crop((splits[i], y0, splits[i + 1], y1))
        bbox = sub.getbbox()
        frames.append(sub.crop(bbox) if bbox else sub)
    return frames


def resample_indices(total: int, target: int) -> list[int]:
    if total == target:
        return list(range(total))
    if target == 1:
        return [0]
    return [min(total - 1, int(round(i * (total - 1) / (target - 1)))) for i in range(target)]


def extract_b02_and_b06() -> None:
    arch_dir = PROJECT_ROOT / "assets" / "base" / "environment" / "architecture"
    deco_dir = PROJECT_ROOT / "assets" / "base" / "environment" / "decorations"
    vfx_dir = PROJECT_ROOT / "assets" / "base" / "vfx"
    arch_dir.mkdir(parents=True, exist_ok=True)
    deco_dir.mkdir(parents=True, exist_ok=True)
    vfx_dir.mkdir(parents=True, exist_ok=True)

    sheet_props = Image.open(INBOX_DIR / "image.png").convert("RGBA")
    # Component 4: Jade Pillar (1397, 99, 1529, 350) -> 128x192
    pillar = fit_bottom_center(sheet_props.crop((1397, 99, 1529, 350)), 128, 192, foot_y=176, margin=6)
    pillar.save(arch_dir / "arch_jade_pillar_01.png")

    # Component 3: Celestial Stone Arch (1094, 55, 1381, 403) -> 128x192
    arch = fit_bottom_center(sheet_props.crop((1094, 55, 1381, 403)), 128, 192, foot_y=176, margin=4)
    arch.save(arch_dir / "arch_celestial_gate_01.png")

    # Component 1: Peach Blossom Tree -> 128x128
    peach = fit_bottom_center(sheet_props.crop((487, 37, 821, 390)), 128, 128, foot_y=116, margin=4)
    peach.save(deco_dir / "deco_peach_bonsai_01.png")

    # Component 14: Lantern -> 128x128
    lantern = fit_bottom_center(sheet_props.crop((1389, 407, 1515, 636)), 128, 128, foot_y=116, margin=6)
    lantern.save(deco_dir / "deco_cloud_lantern_01.png")

    # Component 6: Mossy Rock -> 128x128
    rock = fit_bottom_center(sheet_props.crop((405, 460, 614, 586)), 128, 128, foot_y=114, margin=8)
    rock.save(deco_dir / "deco_cloud_rock_01.png")

    # Component 12: Crystal Brazier / Pedestal -> 128x128
    brazier = fit_bottom_center(sheet_props.crop((977, 427, 1133, 643)), 128, 128, foot_y=116, margin=6)
    brazier.save(deco_dir / "deco_incense_brazier_01.png")

    # B06 VFX sheet: Heavenly Gateway + Portal Energy (8 frames)
    sheet_vfx = remove_sheet_bg(Image.open(INBOX_DIR / "image copy 4.png"))
    gw = fit_bottom_center(sheet_vfx.crop((30, 675, 360, 968)), 128, 192, foot_y=176, margin=4)
    gw.save(arch_dir / "arch_heaven_gateway_01.png")

    portal_frames: list[Image.Image] = []
    for ry0, ry1 in ((695, 825), (828, 958)):
        portal_frames.extend(split_n_frames(sheet_vfx, 520, 985, ry0, ry1, 4))
    for i, pf in enumerate(portal_frames):
        fitted = fit_bottom_center(pf, 128, 128, foot_y=116, margin=8)
        fitted.save(vfx_dir / f"vfx_heaven_portal_{i:02d}.png")
    print(f"[ok] Extracted B02 props (6) and B06 portal frames ({len(portal_frames)})")


def extract_hero_frames() -> dict[tuple[str, str], list[Image.Image]]:
    rgba = remove_sheet_bg(Image.open(INBOX_DIR / "image copy.png"))
    rows = {
        "idle": (85, 225, 4),
        "walk": (235, 365, 6),
        "attack": (385, 515, 6),
        "hurt": (695, 815, 3),
        "death": (850, 985, 6),
    }
    dirs = {
        "down": (100, 465),
        "up": (465, 805),
        "right": (805, 1170),
    }
    out: dict[tuple[str, str], list[Image.Image]] = {}
    for anim, (y0, y1, n) in rows.items():
        for d, (x0, x1) in dirs.items():
            out[(anim, d)] = split_n_frames(rgba, x0, x1, y0, y1, n)
    return out


def extract_enemies_frames() -> dict[str, dict[tuple[str, str], list[Image.Image]]]:
    rgba = remove_sheet_bg(Image.open(INBOX_DIR / "image copy 2.png"))
    enemy_rows = {
        "enemy_ranged": {  # Green cloud slime
            "down": (115, 178),
            "up": (190, 250),
            "right": (262, 325),
        },
        "enemy_melee": {  # Small horned demon
            "down": (428, 498),
            "up": (506, 574),
            "right": (582, 652),
        },
        "enemy_tank": {  # Stone guardian
            "down": (755, 825),
            "up": (834, 902),
            "right": (914, 982),
        },
    }
    anims = {
        "idle": (250, 438, 4),
        "walk": (452, 720, 6),
        "attack": (735, 1028, 6),
        "hurt": (1044, 1218, 3),
        "death": (1228, 1532, 6),
    }
    res: dict[str, dict[tuple[str, str], list[Image.Image]]] = {}
    for cid, dmap in enemy_rows.items():
        res[cid] = {}
        for d, (y0, y1) in dmap.items():
            for anim, (x0, x1, n) in anims.items():
                res[cid][(anim, d)] = split_n_frames(rgba, x0, x1, y0, y1, n)
    return res


def extract_boss_frames() -> dict[tuple[str, str], list[Image.Image]]:
    rgba = remove_sheet_bg(Image.open(INBOX_DIR / "image copy 3.png"))
    # Boss sheet has front/3/4 animations + Direction Views (Down, Up, Right) at bottom
    idle_all = split_n_frames(rgba, 455, 1320, 10, 105, 5)[:4]
    walk_all = split_n_frames(rgba, 435, 1415, 108, 200, 6)
    slam_all = split_n_frames(rgba, 445, 1435, 328, 435, 6)
    hurt_all = split_n_frames(rgba, 435, 1435, 438, 528, 6)[:3]
    death_all = split_n_frames(rgba, 435, 1455, 630, 738, 6)
    dir_views = split_n_frames(rgba, 1005, 1500, 810, 930, 3)  # Down, Up, Right

    out: dict[tuple[str, str], list[Image.Image]] = {}
    base = {
        "idle": idle_all,
        "walk": walk_all,
        "attack": slam_all,
        "hurt": hurt_all,
        "death": death_all,
    }
    for anim, frames in base.items():
        out[(anim, "down")] = frames
        out[(anim, "right")] = frames
        # Use Up view for boss "up" idle/walk with subtle squash/stretch breathing
        if anim in ("idle", "walk") and len(dir_views) >= 2:
            up_base = dir_views[1]
            scales = [1.0, 0.98, 0.96, 0.99, 0.95, 0.97]
            up_frames: list[Image.Image] = []
            for fi in range(len(frames)):
                sc = scales[fi % len(scales)]
                nh = max(1, int(round(up_base.height * sc)))
                up_frames.append(up_base.resize((up_base.width, nh), Image.Resampling.LANCZOS))
            out[(anim, "up")] = up_frames
        else:
            out[(anim, "up")] = frames
    return out


def export_character_with_toolkit(char_id: str, frames_map: dict[tuple[str, str], list[Image.Image]]) -> None:
    profile_path = PROJECT_ROOT / "profiles" / "cloudbound_isometric.json"
    manifest = create_batch_manifest(
        profile_path=profile_path,
        character_id=char_id,
        adapter="inbox_sheet",
        project_root=PROJECT_ROOT,
        output_dir="assets/generated",
        work_dir=".gameforge/work",
    )
    manifest["godot_output_dir"] = str(PROJECT_ROOT / "assets" / "generated" / "sprites" / char_id)

    for task in manifest["tasks"]:
        anim = task["animation"]
        direction = task["direction"]
        target_count = int(task["frame_count"])
        raw_frames = frames_map[(anim, direction)]
        idxs = resample_indices(len(raw_frames), target_count)
        for idx, job in enumerate(task["frames"]):
            src_path = Path(job["source_path"])
            src_path.parent.mkdir(parents=True, exist_ok=True)
            fitted = fit_bottom_center(raw_frames[idxs[idx]], 128, 128, foot_y=112, margin=6)
            fitted.save(src_path)
            job["state"] = "GENERATED"

        norm_res = normalize_task(manifest, task)
        task.update(norm_res)
        pack_res = pack_task_atlas(manifest, task)
        task.update(pack_res)
        val_res = validate_atlas_structure(manifest, task)
        if val_res.get("status") == "FAIL":
            raise RuntimeError(f"Validation failed for {task['task_id']}: {val_res}")

    manifest_path = PROJECT_ROOT / ".gameforge" / "work" / "reports" / manifest["batch_id"] / "batch-manifest.json"
    save_json(manifest_path, manifest)
    export_res = export_godot_spriteframes(manifest)
    print(f"[ok] {char_id}: exported {len(export_res['animations_exported'])} anims -> {export_res['tres_path']}")


def archive_inbox() -> None:
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    dest = PROJECT_ROOT / "assets" / "archive" / f"inbox_{stamp}"
    dest.mkdir(parents=True, exist_ok=True)
    for png in sorted(INBOX_DIR.glob("*.png")):
        shutil.move(str(png), str(dest / png.name))
        imp = png.with_suffix(".png.import")
        if imp.is_file():
            imp.unlink()
    print(f"[ok] Archived processed inbox PNGs -> {dest.relative_to(PROJECT_ROOT)}")


def main() -> int:
    extract_b02_and_b06()
    export_character_with_toolkit("player_hero", extract_hero_frames())
    for cid, fmap in extract_enemies_frames().items():
        export_character_with_toolkit(cid, fmap)
    export_character_with_toolkit("boss_thunder_warden", extract_boss_frames())
    archive_inbox()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
