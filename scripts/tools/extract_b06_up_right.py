#!/usr/bin/env python3
"""Extract B06 Stone Guardian UP & RIGHT animation frames and route through gameforge-kit, preserving DOWN."""

from collections import deque
from pathlib import Path
import json
import sys

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
KIT_SPRITES = ROOT / "tools/gameforge-kit/scripts/sprites"
sys.path.insert(0, str(KIT_SPRITES))

from atlas_packer import pack_task_atlas  # noqa: E402
from batch_planner import create_batch_manifest  # noqa: E402
from frame_normalizer import normalize_task  # noqa: E402
from godot_exporter import export_godot_spriteframes  # noqa: E402
from sprite_common import save_json  # noqa: E402
from validators import validate_atlas_structure  # noqa: E402

SHEET = ROOT / "assets/inbox/image copy.png"
WORK = ROOT / ".gameforge/work"
OUT = ROOT / "assets/generated"

STRIPS = {
    "up": {
        "idle": ((115, 168), [0, 1, 3, 5], 6),
        "walk": ((172, 224), [0, 1, 3, 5], 6),
        "attack": ((228, 282), [0, 1, 3, 5], 6),
        "hurt": ((349, 400), [0, 2], 4),
        "death": ((464, 522), [0, 2, 5, 7], 8),
    },
    "right": {
        "idle": ((573, 625), [0, 1, 3, 5], 6),
        "walk": ((630, 679), [0, 1, 3, 5], 6),
        "attack": ((684, 740), [0, 1, 3, 5], 6),
        "hurt": ((806, 857), [0, 2], 4),
        "death": ((925, 983), [0, 2, 5, 7], 8),
    },
}


def remove_checkerboard_bg(crop_arr: np.ndarray) -> np.ndarray:
    h, w, _ = crop_arr.shape
    rgb = crop_arr[:, :, :3].astype(np.int16)
    sat = rgb.max(axis=2) - rgb.min(axis=2)
    lum = rgb.mean(axis=2)
    is_bg_cand = (sat <= 24) & (lum >= 165)
    visited = np.zeros((h, w), dtype=bool)
    q: deque[tuple[int, int]] = deque()
    for x in range(w):
        for y in (0, h - 1):
            if is_bg_cand[y, x] and not visited[y, x]:
                visited[y, x] = True
                q.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if is_bg_cand[y, x] and not visited[y, x]:
                visited[y, x] = True
                q.append((y, x))
    while q:
        cy, cx = q.popleft()
        for ny, nx in ((cy - 1, cx), (cy + 1, cx), (cy, cx - 1), (cy, cx + 1)):
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx] and is_bg_cand[ny, nx]:
                visited[ny, nx] = True
                q.append((ny, nx))
    out = crop_arr.copy()
    out[visited, 3] = 0
    return out


def detect_strip_cells(arr: np.ndarray, y0: int, y1: int, expected_n: int) -> list[tuple[int, int]]:
    sub = arr[y0 + 6 : y1 - 6, 408:1225, :3].astype(np.int16)
    col_bright = (sub.sum(axis=2) > 460).mean(axis=0)
    spans: list[tuple[int, int]] = []
    in_s = False
    start = 0
    for x in range(len(col_bright)):
        if col_bright[x] > 0.20 and not in_s:
            in_s = True
            start = x
        elif col_bright[x] <= 0.20 and in_s:
            in_s = False
            if x - start > 45:
                spans.append((start + 408, x + 408))
    if in_s and len(col_bright) - start > 45:
        spans.append((start + 408, len(col_bright) + 408))
    if len(spans) == expected_n:
        return spans
    x_min = 414
    x_max = 1218
    step = (x_max - x_min) / float(expected_n)
    return [(int(x_min + i * step) + 2, int(x_min + (i + 1) * step) - 2) for i in range(expected_n)]


def main() -> int:
    im = Image.open(SHEET).convert("RGBA")
    arr = np.array(im)

    manifest = create_batch_manifest(
        profile_path=Path("profiles/cloudbound_isometric.json"),
        character_id="boss_thunder_warden",
        adapter="b06_up_right_extractor",
        project_root=ROOT,
        output_dir="assets/generated",
        work_dir=".gameforge/work",
    )
    boss_dir = OUT / "sprites/boss_thunder_warden"
    manifest["godot_output_dir"] = str(boss_dir)

    for task in manifest["tasks"]:
        direction = task["direction"]
        anim_name = task["animation"]
        task_id = task["task_id"]

        if direction == "down":
            # Preserve approved DOWN atlas/png untouched
            atlas_json = boss_dir / f"{task_id}.atlas.json"
            atlas_png = boss_dir / f"{task_id}.png"
            task["atlas_json_path"] = str(atlas_json)
            task["atlas_png_path"] = str(atlas_png)
            task["state"] = "PACKED"
            continue

        (y0, y1), indices, total_n = STRIPS[direction][anim_name]
        cells = detect_strip_cells(arr, y0, y1, total_n)
        for out_idx, job in enumerate(task["frames"]):
            src_idx = indices[out_idx]
            x0, x1 = cells[src_idx]
            crop = arr[y0 + 3 : y1 - 3, x0 + 3 : x1 - 3].copy()
            clean = remove_checkerboard_bg(crop)
            img_out = Image.fromarray(clean)
            if direction == "right":
                # Sheet Panel E faces left; mirror horizontally so *_right truly faces right
                img_out = img_out.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            src_path = Path(job["source_path"])
            src_path.parent.mkdir(parents=True, exist_ok=True)
            img_out.save(src_path)
            job["state"] = "GENERATED"

        task.update(normalize_task(manifest, task))
        task.update(pack_task_atlas(manifest, task))
        val = validate_atlas_structure(manifest, task)
        if val.get("status") == "FAIL":
            raise RuntimeError(f"Validation failed for {task_id}: {val}")
        print(f"[OK] Packed {task_id}")

    manifest_path = WORK / "reports" / manifest["batch_id"] / "batch-manifest.json"
    save_json(manifest_path, manifest)
    res = export_godot_spriteframes(manifest)
    print(f"[DONE] Exported {len(res['animations_exported'])} anims -> {res['tres_path']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
