#!/usr/bin/env python3
"""Extract real 2D Chinese mythology props and character/enemy/boss sprites
from assets/inbox/ sheets and route character sprites through gameforge-kit's
planner, normalizer, atlas packer, validator, and Godot SpriteFrames exporter.
"""

from __future__ import annotations

import collections
import sys
from pathlib import Path
from PIL import Image

PROJECT_ROOT = Path(__file__).resolve().parents[2]
TOOLKIT_SPRITES = PROJECT_ROOT / "tools" / "gameforge-kit" / "scripts" / "sprites"
sys.path.insert(0, str(TOOLKIT_SPRITES))

from atlas_packer import pack_task_atlas  # noqa: E402
from batch_planner import create_batch_manifest  # noqa: E402
from frame_normalizer import normalize_task  # noqa: E402
from godot_exporter import export_godot_spriteframes  # noqa: E402
from sprite_common import save_json  # noqa: E402
from validators import validate_atlas_structure  # noqa: E402

INBOX = PROJECT_ROOT / "assets" / "inbox"


def remove_light_bg(crop: Image.Image, thresh: int = 232, chroma: int = 16) -> Image.Image:
    rgba = crop.convert("RGBA")
    w, h = rgba.size
    px = rgba.load()

    def is_bg(r: int, g: int, b: int) -> bool:
        return r >= thresh and g >= thresh and b >= thresh and (max(r, g, b) - min(r, g, b)) <= chroma

    vis = bytearray(w * h)
    q: collections.deque[tuple[int, int]] = collections.deque()
    for x in range(w):
        for y in (0, h - 1):
            if is_bg(*px[x, y][:3]):
                vis[y * w + x] = 1
                q.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if not vis[y * w + x] and is_bg(*px[x, y][:3]):
                vis[y * w + x] = 1
                q.append((x, y))
    while q:
        cx, cy = q.popleft()
        px[cx, cy] = (0, 0, 0, 0)
        for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
            if 0 <= nx < w and 0 <= ny < h:
                idx = ny * w + nx
                if not vis[idx] and is_bg(*px[nx, ny][:3]):
                    vis[idx] = 1
                    q.append((nx, ny))

    # Strip 1px near-white halo adjacent to alpha=0
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            r, g, b, a = px[x, y]
            if a > 0 and r >= 215 and g >= 215 and b >= 215 and (max(r, g, b) - min(r, g, b)) <= 16:
                if any(px[nx, ny][3] == 0 for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1))):
                    px[x, y] = (0, 0, 0, 0)
    return rgba


def split_frames_by_columns(cell: Image.Image, expected_count: int) -> list[Image.Image]:
    """Slice a horizontal strip by finding vertical transparent gaps between sprites,
    falling back to equal-width slicing only if fewer than expected_count blobs exist.
    """
    clean = remove_light_bg(cell)
    w, h = clean.size
    px = clean.load()

    # Vertical projection: find X intervals with opaque pixels
    col_has_fg = [any(px[x, y][3] > 20 for y in range(h)) for x in range(w)]
    spans: list[tuple[int, int]] = []
    in_span = False
    start = 0
    for x, has in enumerate(col_has_fg):
        if has and not in_span:
            in_span = True
            start = x
        elif not has and in_span:
            if x - start >= 12:
                spans.append((start, x))
            in_span = False
    if in_span and w - start >= 12:
        spans.append((start, w))

    # Merge tiny gaps (< 4px) if we got too many fragments (e.g. detached dust/sparkles)
    while len(spans) > expected_count:
        best_i = min(range(len(spans) - 1), key=lambda i: spans[i + 1][0] - spans[i][1])
        spans[best_i : best_i + 2] = [(spans[best_i][0], spans[best_i + 1][1])]

    if len(spans) != expected_count:
        step = w / float(expected_count)
        spans = [(int(round(i * step)), int(round((i + 1) * step))) for i in range(expected_count)]

    frames: list[Image.Image] = []
    for x0, x1 in spans:
        sub = clean.crop((x0, 0, x1, h))
        bbox = sub.getbbox()
        if bbox:
            sub = sub.crop(bbox)
        sw, sh = sub.size
        scale = min(104.0 / max(sw, 1), 96.0 / max(sh, 1))
        nw = max(1, int(round(sw * scale)))
        nh = max(1, int(round(sh * scale)))
        resized = sub.resize((nw, nh), Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
        ox = (128 - nw) // 2
        oy = 112 - nh
        canvas.paste(resized, (ox, oy), resized)
        frames.append(canvas)
    return frames


def pick_indices(frames: list[Image.Image], target_count: int) -> list[Image.Image]:
    if len(frames) == target_count:
        return frames
    if target_count == 2 and len(frames) >= 3:
        return [frames[0], frames[-1]]
    if target_count == 4 and len(frames) == 6:
        return [frames[0], frames[1], frames[3], frames[5]]
    return [frames[min(len(frames) - 1, int(round(i * (len(frames) - 1) / max(target_count - 1, 1))))] for i in range(target_count)]


def extract_b02_pillar() -> None:
    src = INBOX / "image.png"
    if not src.is_file():
        return
    im = Image.open(src).convert("RGBA")
    # Jade stone pillar with glowing cyan runes at top-right (1395..1536, 85..395)
    pillar = im.crop((1395, 85, 1536, 395))
    bbox = pillar.getbbox()
    if bbox:
        pillar = pillar.crop(bbox)
    pw, ph = pillar.size
    scale = min(108.0 / pw, 176.0 / ph)
    nw = max(1, int(round(pw * scale)))
    nh = max(1, int(round(ph * scale)))
    resized = pillar.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (128, 192), (0, 0, 0, 0))
    canvas.paste(resized, ((128 - nw) // 2, 180 - nh), resized)
    out_path = PROJECT_ROOT / "assets" / "base" / "environment" / "architecture" / "arch_jade_pillar_01.png"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out_path)
    print(f"[ok] Extracted pillar -> {out_path.relative_to(PROJECT_ROOT)}")


def export_character_via_toolkit(char_id: str, frames_map: dict[tuple[str, str], list[Image.Image]]) -> None:
    manifest = create_batch_manifest(
        profile_path=Path("profiles/cloudbound_isometric.json"),
        character_id=char_id,
        adapter="inbox_sheet_extractor",
        project_root=PROJECT_ROOT,
        output_dir="assets/generated",
        work_dir=".gameforge/work",
    )
    manifest["godot_output_dir"] = str(PROJECT_ROOT / "assets" / "generated" / "sprites" / char_id)

    for task in manifest["tasks"]:
        key = (task["animation"], task["direction"])
        raw_frames = frames_map.get(key) or frames_map.get((task["animation"], "down"))
        chosen = pick_indices(raw_frames, int(task["frame_count"]))
        for idx, job in enumerate(task["frames"]):
            src_path = Path(job["source_path"])
            src_path.parent.mkdir(parents=True, exist_ok=True)
            chosen[idx].save(src_path)
            job["state"] = "GENERATED"

        task.update(normalize_task(manifest, task))
        task.update(pack_task_atlas(manifest, task))
        val = validate_atlas_structure(manifest, task)
        if val.get("status") == "FAIL":
            print(f"[WARN] {task['task_id']}: {val}")

    manifest_path = PROJECT_ROOT / ".gameforge" / "work" / "reports" / manifest["batch_id"] / "batch-manifest.json"
    save_json(manifest_path, manifest)
    res = export_godot_spriteframes(manifest)
    print(f"[ok] {char_id}: exported {len(res['animations_exported'])} anims -> {res['tres_path']}")


def extract_hero() -> None:
    im = Image.open(INBOX / "image copy.png")
    rows = {
        "idle": (95, 228, 4),
        "walk": (245, 372, 6),
        "attack": (395, 522, 6),
        "hurt": (710, 835, 3),
        "death": (870, 995, 6),
    }
    cols = {
        "down": (118, 445),
        "up": (475, 815),
        "right": (835, 1180),
    }
    frames_map: dict[tuple[str, str], list[Image.Image]] = {}
    for anim, (y0, y1, count) in rows.items():
        for d, (x0, x1) in cols.items():
            frames_map[(anim, d)] = split_frames_by_columns(im.crop((x0, y0, x1, y1)), count)
    export_character_via_toolkit("player_hero", frames_map)


def extract_enemies() -> None:
    im = Image.open(INBOX / "image copy 2.png")
    enemies = {
        "enemy_melee": {"down": (105, 175), "up": (178, 245), "right": (245, 315)},
        "enemy_ranged": {"down": (405, 475), "up": (480, 548), "right": (550, 622)},
        "enemy_tank": {"down": (708, 785), "up": (788, 865), "right": (868, 945)},
    }
    anims = {
        "idle": (248, 445, 4),
        "walk": (458, 740, 6),
        "attack": (758, 1048, 6),
        "hurt": (1065, 1230, 3),
        "death": (1245, 1525, 6),
    }
    for eid, dir_rows in enemies.items():
        frames_map: dict[tuple[str, str], list[Image.Image]] = {}
        for anim, (x0, x1, count) in anims.items():
            for d, (y0, y1) in dir_rows.items():
                frames_map[(anim, d)] = split_frames_by_columns(im.crop((x0, y0, x1, y1)), count)
        export_character_via_toolkit(eid, frames_map)


def extract_boss() -> None:
    im = Image.open(INBOX / "image copy 3.png")
    rows = {
        "idle": (400, 1360, 20, 122, 4),
        "walk": (400, 1360, 136, 246, 6),
        "attack": (400, 1360, 392, 506, 6),
        "hurt": (400, 895, 515, 620, 3),
        "death": (400, 1360, 756, 868, 6),
    }
    frames_map: dict[tuple[str, str], list[Image.Image]] = {}
    for anim, (x0, x1, y0, y1, count) in rows.items():
        frames_map[(anim, "down")] = split_frames_by_columns(im.crop((x0, y0, x1, y1)), count)
    export_character_via_toolkit("boss_thunder_warden", frames_map)


def main() -> int:
    extract_b02_pillar()
    extract_hero()
    extract_enemies()
    extract_boss()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
