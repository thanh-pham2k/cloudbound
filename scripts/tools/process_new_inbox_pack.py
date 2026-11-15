#!/usr/bin/env python3
"""Process the 9-sheet Cloudbound asset pack in assets/inbox/ into validated Godot 4 assets:
- B01: Circular arena floor tiles (A001..A009), Grass C (with flowers)
- B02/B03/B08: Architecture, Nature props, Distant islands, Reward chest, Portal FX
- Hero (image copy 3.png), Slime (image copy 4.png), Demon (image copy 5.png), Boss (image copy 6.png)
  routed through tools/gameforge-kit/scripts/sprites/
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


def remove_navy_bg(crop: Image.Image) -> Image.Image:
    """Flood-fill dark navy backdrop from border; preserves dark character outlines."""
    rgba = crop.convert("RGBA")
    w, h = rgba.size
    px = rgba.load()

    def is_navy(r: int, g: int, b: int) -> bool:
        return r < 36 and g < 48 and b < 78 and b >= r + 6

    visited = bytearray(w * h)
    q: collections.deque[tuple[int, int]] = collections.deque()
    for x in range(w):
        for y in (0, h - 1):
            if is_navy(*px[x, y][:3]):
                visited[y * w + x] = 1
                q.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if not visited[y * w + x] and is_navy(*px[x, y][:3]):
                visited[y * w + x] = 1
                q.append((x, y))

    while q:
        cx, cy = q.popleft()
        px[cx, cy] = (0, 0, 0, 0)
        for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
            if 0 <= nx < w and 0 <= ny < h:
                idx = ny * w + nx
                if not visited[idx] and is_navy(*px[nx, ny][:3]):
                    visited[idx] = 1
                    q.append((nx, ny))

    # Clean 1px navy fringe adjacent to transparent pixels
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if r < 65 and g < 85 and b < 125 and b > r + 10:
                if any(px[nx, ny][3] == 0 for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1))):
                    px[x, y] = (0, 0, 0, 0)
    return rgba


def remove_white_bg(crop: Image.Image, thresh: int = 224, chroma: int = 20) -> Image.Image:
    """Flood-fill white/light-gray checkerboard backdrop from border."""
    rgba = crop.convert("RGBA")
    w, h = rgba.size
    px = rgba.load()

    def is_bg(r: int, g: int, b: int) -> bool:
        return r >= thresh and g >= thresh and b >= thresh and (max(r, g, b) - min(r, g, b)) <= chroma

    visited = bytearray(w * h)
    q: collections.deque[tuple[int, int]] = collections.deque()
    for x in range(w):
        for y in (0, h - 1):
            if is_bg(*px[x, y][:3]):
                visited[y * w + x] = 1
                q.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if not visited[y * w + x] and is_bg(*px[x, y][:3]):
                visited[y * w + x] = 1
                q.append((x, y))

    while q:
        cx, cy = q.popleft()
        px[cx, cy] = (0, 0, 0, 0)
        for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
            if 0 <= nx < w and 0 <= ny < h:
                idx = ny * w + nx
                if not visited[idx] and is_bg(*px[nx, ny][:3]):
                    visited[idx] = 1
                    q.append((nx, ny))
    return rgba


def fit_bottom_center(crop: Image.Image, target_w: int, target_h: int, foot_y: int, margin: int = 6, fixed_scale: float | None = None) -> Image.Image:
    bbox = crop.getbbox()
    trimmed = crop.crop(bbox) if bbox else crop
    cw, ch = trimmed.size
    avail_w = max(1, target_w - 2 * margin)
    avail_h = max(1, foot_y - margin)
    scale = min(avail_w / cw, avail_h / ch)
    if fixed_scale is not None:
        scale = min(scale, fixed_scale)
    nw = max(1, int(round(cw * scale)))
    nh = max(1, int(round(ch * scale)))
    resized = trimmed.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))
    canvas.paste(resized, ((target_w - nw) // 2, foot_y - nh), resized)
    return canvas


def split_by_blobs_or_n(rgba: Image.Image, n: int, min_gap: int = 2) -> list[Image.Image]:
    """Split a cleaned RGBA row into n sprites by finding horizontal foreground runs
    separated by transparent columns (falling back to uniform n-split if fewer than n runs).
    """
    w, h = rgba.size
    px = rgba.load()
    runs: list[tuple[int, int]] = []
    in_fg = False
    xs = 0
    for x in range(w):
        fg = sum(1 for y in range(h) if px[x, y][3] > 20)
        if fg >= 2 and not in_fg:
            in_fg = True
            xs = x
        elif fg < 2 and in_fg:
            if x - xs >= 14:
                runs.append((xs, x))
            in_fg = False
    if in_fg and w - xs >= 14:
        runs.append((xs, w))

    if len(runs) == n:
        frames: list[Image.Image] = []
        for rx0, rx1 in runs:
            sub = rgba.crop((rx0, 0, rx1, h))
            bbox = sub.getbbox()
            frames.append(sub.crop(bbox) if bbox else sub)
        return frames

    # Fallback: uniform split on foreground span
    return split_row_n(rgba, 0, w, 0, h, n)


def strip_gridlines_and_checkerboard(im: Image.Image) -> Image.Image:
    """Remove both dark-navy outer frames/lines AND interior light checkerboard/gridlines."""
    step1 = remove_navy_bg(im)
    step2 = remove_white_bg(step1, thresh=205, chroma=18)
    # Remove any isolated 1-3px neutral/gray divider columns/rows (>=80% grayish pixels)
    w, h = step2.size
    px = step2.load()
    for x in range(w):
        non_trans = [px[x, y] for y in range(h) if px[x, y][3] > 0]
        if non_trans and len(non_trans) >= max(8, int(0.65 * h)):
            gray_cnt = sum(1 for r, g, b, _ in non_trans if min(r, g, b) >= 95 and max(r, g, b) - min(r, g, b) <= 26)
            if gray_cnt >= 0.8 * len(non_trans):
                for y in range(h):
                    px[x, y] = (0, 0, 0, 0)
    for y in range(h):
        non_trans = [px[x, y] for x in range(w) if px[x, y][3] > 0]
        if non_trans and len(non_trans) >= max(8, int(0.65 * w)):
            gray_cnt = sum(1 for r, g, b, _ in non_trans if min(r, g, b) >= 95 and max(r, g, b) - min(r, g, b) <= 26)
            if gray_cnt >= 0.8 * len(non_trans):
                for x in range(w):
                    px[x, y] = (0, 0, 0, 0)
    return step2


def clean_cell_bg(cell: Image.Image) -> Image.Image:
    """Pad cell by 1px and flood-fill any remaining light checkerboard from all 4 edges,
    and strip any thin neutral-gray cell border rows at top/bottom.
    """
    padded = Image.new("RGBA", (cell.width + 2, cell.height + 2), (255, 255, 255, 255))
    padded.paste(cell, (1, 1))
    cleaned = remove_white_bg(padded, thresh=205, chroma=18)
    inner = cleaned.crop((1, 1, cell.width + 1, cell.height + 1))
    w, h = inner.size
    px = inner.load()
    for y in (0, 1, h - 2, h - 1):
        if 0 <= y < h:
            non_trans = [px[x, y] for x in range(w) if px[x, y][3] > 0]
            if non_trans and len(non_trans) >= int(0.45 * w):
                gray_cnt = sum(1 for r, g, b, _ in non_trans if min(r, g, b) >= 85 and max(r, g, b) - min(r, g, b) <= 26)
                if gray_cnt >= 0.8 * len(non_trans):
                    for x in range(w):
                        px[x, y] = (0, 0, 0, 0)
    bbox = inner.getbbox()
    return inner.crop(bbox) if bbox else inner


def split_row_n(rgba: Image.Image, x0: int, x1: int, y0: int, y1: int, n: int) -> list[Image.Image]:
    """Split a horizontal row into n uniform cells and trim each cell."""
    px = rgba.load()
    xs = [x for x in range(x0, x1) if any(px[x, y][3] > 0 for y in range(y0, y1))]
    if not xs:
        return []
    xmin, xmax = min(xs), max(xs) + 1
    span = xmax - xmin
    cuts = [xmin]
    for i in range(1, n):
        ideal = xmin + int(round(i * span / n))
        lo = max(cuts[-1] + 8, ideal - 8)
        hi = min(xmax - 8, ideal + 8)
        if lo <= hi:
            best_x = min(range(lo, hi + 1), key=lambda x: sum(1 for y in range(y0, y1) if px[x, y][3] > 20))
            cuts.append(best_x)
        else:
            cuts.append(ideal)
    cuts.append(xmax)
    frames: list[Image.Image] = []
    for i in range(n):
        cx0, cx1 = cuts[i], cuts[i + 1]
        sub = rgba.crop((cx0, y0, cx1, y1))
        bbox = sub.getbbox()
        frames.append(sub.crop(bbox) if bbox else sub)
    return frames


def resample_indices(total: int, target: int) -> list[int]:
    if total == target:
        return list(range(total))
    if target == 1:
        return [0]
    return [min(total - 1, int(round(i * (total - 1) / (target - 1)))) for i in range(target)]


def extract_environment_and_props() -> None:
    ground_dir = PROJECT_ROOT / "assets" / "base" / "environment" / "ground"
    arch_dir = PROJECT_ROOT / "assets" / "base" / "environment" / "architecture"
    deco_dir = PROJECT_ROOT / "assets" / "base" / "environment" / "decorations"
    props_dir = PROJECT_ROOT / "assets" / "base" / "props"
    vfx_dir = PROJECT_ROOT / "assets" / "base" / "vfx"
    for d in (ground_dir, arch_dir, deco_dir, props_dir, vfx_dir):
        d.mkdir(parents=True, exist_ok=True)

    # B01 Circular Arena Floor (A001..A009)
    im_b01 = Image.open(INBOX_DIR / "image.png")
    arena_boxes = [
        (36, 675, 129, 729), (148, 675, 239, 729), (258, 675, 345, 728),
        (37, 755, 130, 843), (148, 755, 240, 843), (258, 755, 345, 843),
        (36, 868, 129, 956), (149, 870, 240, 957), (259, 869, 345, 956),
    ]
    for idx, box in enumerate(arena_boxes, start=1):
        tile = remove_navy_bg(im_b01.crop(box)).resize((128, 128), Image.Resampling.LANCZOS)
        tile.save(ground_dir / f"ground_arena_tile_{idx:02d}.png")

    # B02 Architecture & Props
    im_b02 = Image.open(INBOX_DIR / "image copy.png")
    fit_bottom_center(remove_navy_bg(im_b02.crop((24, 124, 308, 362))), 256, 256, 236, 6).save(arch_dir / "arch_village_house_01.png")
    fit_bottom_center(remove_navy_bg(im_b02.crop((524, 138, 830, 368))), 256, 256, 236, 6).save(arch_dir / "arch_celestial_gate_01.png")
    fit_bottom_center(remove_navy_bg(im_b02.crop((1036, 125, 1352, 378))), 256, 256, 236, 4).save(arch_dir / "arch_heaven_gateway_01.png")
    fit_bottom_center(remove_navy_bg(im_b02.crop((1076, 484, 1212, 678))), 128, 192, 176, 6).save(arch_dir / "arch_jade_pillar_01.png")
    fit_bottom_center(remove_navy_bg(im_b02.crop((1374, 504, 1512, 672))), 128, 128, 116, 6).save(deco_dir / "deco_incense_brazier_01.png")
    fit_bottom_center(remove_navy_bg(im_b02.crop((44, 494, 170, 555))), 128, 128, 114, 4).save(deco_dir / "deco_wooden_fence_01.png")
    fit_bottom_center(remove_navy_bg(im_b02.crop((36, 790, 138, 938))), 128, 128, 116, 6).save(deco_dir / "deco_cloud_lantern_01.png")

    # B03 Nature & Distant Islands
    im_b03 = Image.open(INBOX_DIR / "image copy 2.png")
    fit_bottom_center(remove_navy_bg(im_b03.crop((26, 138, 288, 368))), 256, 256, 236, 6).save(deco_dir / "deco_peach_bonsai_01.png")
    fit_bottom_center(remove_navy_bg(im_b03.crop((542, 138, 848, 368))), 256, 256, 236, 6).save(deco_dir / "deco_green_tree_01.png")
    fit_bottom_center(remove_navy_bg(im_b03.crop((30, 504, 204, 628))), 128, 128, 114, 6).save(deco_dir / "deco_bush_01.png")
    fit_bottom_center(remove_navy_bg(im_b03.crop((428, 534, 570, 628))), 128, 128, 114, 6).save(deco_dir / "deco_cloud_rock_01.png")
    fit_bottom_center(remove_navy_bg(im_b03.crop((260, 756, 510, 926))), 256, 256, 230, 6).save(deco_dir / "bg_distant_island_01.png")
    fit_bottom_center(remove_navy_bg(im_b03.crop((740, 814, 950, 900))), 256, 128, 114, 6).save(deco_dir / "bg_cloud_bank_01.png")

    # B08 Reward Chest & 8-frame Portal Energy
    im_b08 = Image.open(INBOX_DIR / "image copy 8.png")
    fit_bottom_center(remove_navy_bg(im_b08.crop((895, 505, 1040, 620))), 128, 128, 114, 8).save(props_dir / "prop_reward_chest_01.png")
    # Portal Energy 8 frames (2x4 grid at x=1170..1505, y=200..445)
    p_frames: list[Image.Image] = []
    for ry0, ry1 in ((202, 310), (328, 436)):
        for i in range(4):
            x0 = 1176 + i * 82
            cell = remove_white_bg(im_b08.crop((x0, ry0, x0 + 78, ry1)), thresh=218, chroma=24)
            p_frames.append(fit_bottom_center(cell, 128, 128, 116, 8))
    for i, pf in enumerate(p_frames):
        pf.save(vfx_dir / f"vfx_heaven_portal_{i:02d}.png")

    print("[ok] Extracted B01 arena floor, B02/B03 props, B08 chest & portal FX")


def extract_hero() -> dict[tuple[str, str], list[Image.Image]]:
    im = Image.open(INBOX_DIR / "image copy 3.png")
    rows = {
        "idle": (158, 268, 4),
        "walk": (296, 392, 6),
        "attack": (435, 516, 8),
        "hurt": (690, 782, 4),
        "death": (822, 906, 6),
    }
    dirs = {
        "down": (428, 786),
        "right": (795, 1151),
        "up": (1160, 1521),
    }
    out: dict[tuple[str, str], list[Image.Image]] = {}
    for anim, (y0, y1, n) in rows.items():
        for d, (x0, x1) in dirs.items():
            band = remove_navy_bg(im.crop((x0, y0, x1, y1)))
            out[(anim, d)] = split_by_blobs_or_n(band, n)
    return out


def extract_slime() -> dict[tuple[str, str], list[Image.Image]]:
    im = Image.open(INBOX_DIR / "image copy 4.png")
    bands = [
        ("idle", "down", 12, 96, 4, 710),
        ("idle", "right", 98, 170, 4, 710),
        ("idle", "up", 172, 248, 4, 710),
        ("walk", "down", 258, 330, 7, 1260),
        ("walk", "right", 332, 394, 7, 1260),
        ("walk", "up", 395, 456, 7, 1260),
        ("attack", "down", 468, 525, 7, 1260),
        ("attack", "right", 527, 582, 7, 1260),
        ("attack", "up", 583, 638, 7, 1260),
        ("hurt", "down", 646, 703, 4, 710),
        ("hurt", "right", 704, 760, 4, 710),
        ("hurt", "up", 761, 816, 4, 710),
        ("death", "down", 825, 887, 7, 1260),
        ("death", "right", 888, 947, 7, 1260),
        ("death", "up", 950, 1012, 7, 1260),
    ]
    out: dict[tuple[str, str], list[Image.Image]] = {}
    for anim, d, y0, y1, n, max_x in bands:
        band = strip_gridlines_and_checkerboard(im.crop((8, y0, max_x, y1)))
        out[(anim, d)] = [clean_cell_bg(f) for f in split_by_blobs_or_n(band, n)]
    return out


def extract_demon() -> dict[tuple[str, str], list[Image.Image]]:
    im = Image.open(INBOX_DIR / "image copy 5.png")
    bands = [
        ("idle", "down", 8, 67, 4),
        ("idle", "right", 69, 127, 4),
        ("idle", "up", 130, 190, 4),
        ("walk", "down", 198, 258, 6),
        ("walk", "right", 259, 320, 6),
        ("walk", "up", 321, 382, 6),
        ("attack", "down", 389, 449, 8),
        ("attack", "right", 450, 511, 8),
        ("attack", "up", 513, 573, 8),
        ("hurt", "down", 581, 640, 4),
        ("hurt", "right", 641, 702, 4),
        ("hurt", "up", 703, 762, 4),
        ("death", "down", 771, 832, 6),
        ("death", "right", 834, 896, 6),
        ("death", "up", 898, 962, 6),
    ]
    out: dict[tuple[str, str], list[Image.Image]] = {}
    for anim, d, y0, y1, n in bands:
        band = strip_gridlines_and_checkerboard(im.crop((235, y0, 1506, y1)))
        out[(anim, d)] = [clean_cell_bg(f) for f in split_by_blobs_or_n(band, n)]
    return out


def extract_boss() -> dict[tuple[str, str], list[Image.Image]]:
    im = Image.open(INBOX_DIR / "image copy 6.png")
    rows = {
        "idle": (104, 200, 6),
        "walk": (214, 310, 6),
        "attack": (444, 564, 8),  # Attack Slam
        "hurt": (578, 670, 4),
        "death": (824, 974, 8),
    }
    out: dict[tuple[str, str], list[Image.Image]] = {}
    for anim, (y0, y1, n) in rows.items():
        band = strip_gridlines_and_checkerboard(im.crop((422, y0, 1508, y1)))
        frames = [clean_cell_bg(f) for f in split_by_blobs_or_n(band, n)]
        for d in ("down", "right", "up"):
            out[(anim, d)] = frames
    return out


def export_character(char_id: str, frames_map: dict[tuple[str, str], list[Image.Image]]) -> None:
    profile_path = PROJECT_ROOT / "profiles" / "cloudbound_isometric.json"
    manifest = create_batch_manifest(
        profile_path=profile_path,
        character_id=char_id,
        adapter="inbox_pack_v2",
        project_root=PROJECT_ROOT,
        output_dir="assets/generated",
        work_dir=".gameforge/work",
    )
    manifest["godot_output_dir"] = str(PROJECT_ROOT / "assets" / "generated" / "sprites" / char_id)

    all_frames = [f for flist in frames_map.values() for f in flist if f.width > 0 and f.height > 0]
    widths = sorted(f.width for f in all_frames)
    heights = sorted(f.height for f in all_frames)
    med_w = widths[len(widths) // 2] if widths else 64
    med_h = heights[len(heights) // 2] if heights else 64
    uniform_scale = min(104.0 / med_w, 94.0 / med_h)

    for task in manifest["tasks"]:
        anim = task["animation"]
        direction = task["direction"]
        target_count = int(task["frame_count"])
        raw_frames = frames_map[(anim, direction)]
        idxs = resample_indices(len(raw_frames), target_count)
        for idx, job in enumerate(task["frames"]):
            src_path = Path(job["source_path"])
            src_path.parent.mkdir(parents=True, exist_ok=True)
            fitted = fit_bottom_center(raw_frames[idxs[idx]], 128, 128, foot_y=112, margin=6, fixed_scale=uniform_scale)
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
    dest = PROJECT_ROOT / "assets" / "archive" / f"inbox_pack_{stamp}"
    dest.mkdir(parents=True, exist_ok=True)
    for png in sorted(INBOX_DIR.glob("*.png")):
        shutil.move(str(png), str(dest / png.name))
        imp = png.with_suffix(".png.import")
        if imp.is_file():
            imp.unlink()
    print(f"[ok] Archived inbox PNGs -> {dest.relative_to(PROJECT_ROOT)}")


def main() -> int:
    extract_environment_and_props()
    export_character("player_hero", extract_hero())
    export_character("enemy_ranged", extract_slime())
    export_character("enemy_melee", extract_demon())
    export_character("boss_thunder_warden", extract_boss())
    archive_inbox()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
