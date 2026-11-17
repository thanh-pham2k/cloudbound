#!/usr/bin/env python3
"""Extract individual RGBA sprites from the 4 Phase 2 batch sprite sheets."""

from collections import deque
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
INBOX = ROOT / "assets" / "inbox"
OUT = ROOT / "assets" / "sprites"

BATCHES = [
    {
        "file": "001-create-a-2-5d-isometric-game-character-sprite-sheet-containi.png",
        "cols": 3,
        "rows": 2,
        "cells": {
            (0, 0): "characters/player_hero.png",
            (1, 0): "characters/npc_elder.png",
            (2, 0): "characters/npc_guide.png",
            (0, 1): "characters/enemy_boar.png",
            (2, 1): "characters/boss_demon_king.png",
        },
    },
    {
        "file": "002-create-a-2-5d-isometric-game-terrain-tile-sheet-containing-4.png",
        "cols": 2,
        "rows": 2,
        "cells": {
            (0, 0): "tiles/tile_grass.png",
            (1, 0): "tiles/tile_dirt.png",
            (0, 1): "tiles/tile_cave_stone.png",
            (1, 1): "tiles/stairs_stone.png",
        },
    },
    {
        "file": "003-create-a-2-5d-isometric-game-environment-props-sprite-sheet-.png",
        "cols": 3,
        "rows": 2,
        "cells": {
            (0, 0): "environment/hut_main.png",
            (1, 0): "environment/hut_small.png",
            (2, 0): "environment/tree_peach.png",
            (0, 1): "environment/tree_green.png",
            (1, 1): "environment/rock_cluster.png",
            (2, 1): "environment/torch_brazier.png",
        },
    },
    {
        "file": "004-create-a-2-5d-isometric-game-interactive-props-sprite-sheet-.png",
        "cols": 3,
        "rows": 2,
        "cells": {
            (0, 0): "interactables/spawn_disc.png",
            (1, 0): "interactables/peach_pickup.png",
            (2, 0): "interactables/chest_closed.png",
            (0, 1): "interactables/chest_open.png",
            (1, 1): "interactables/gate_locked.png",
            (2, 1): "interactables/gate_unlocked.png",
        },
    },
]


def is_bg_pixel(rgb: np.ndarray) -> np.ndarray:
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    mn = np.minimum(np.minimum(r, g), b)
    mx = np.maximum(np.maximum(r, g), b)
    return (mn >= 235) & ((mx - mn) <= 18)


def extract_cell(cell_img: Image.Image) -> Image.Image:
    rgba = np.array(cell_img.convert("RGBA"))
    h, w, _ = rgba.shape
    bg_candidate = is_bg_pixel(rgba[:, :, :3])

    visited = np.zeros((h, w), dtype=bool)
    q = deque()

    for x in range(w):
        if bg_candidate[0, x]:
            visited[0, x] = True
            q.append((0, x))
        if bg_candidate[h - 1, x]:
            visited[h - 1, x] = True
            q.append((h - 1, x))
    for y in range(h):
        if bg_candidate[y, 0] and not visited[y, 0]:
            visited[y, 0] = True
            q.append((y, 0))
        if bg_candidate[y, w - 1] and not visited[y, w - 1]:
            visited[y, w - 1] = True
            q.append((y, w - 1))

    while q:
        cy, cx = q.popleft()
        for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx] and bg_candidate[ny, nx]:
                visited[ny, nx] = True
                q.append((ny, nx))

    rgba[visited, 3] = 0

    # Soften 1px near-white halo adjacent to transparent background
    alpha = rgba[:, :, 3]
    for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
        shifted = np.roll(alpha == 0, shift=(dy, dx), axis=(0, 1))
        mn = np.min(rgba[:, :, :3], axis=2)
        halo = shifted & (alpha > 0) & (mn >= 205)
        rgba[halo, 3] = np.clip((255 - mn[halo]) * 4, 0, 255).astype(np.uint8)

    out_img = Image.fromarray(rgba, mode="RGBA")
    bbox = out_img.getbbox()
    if bbox is None:
        return out_img

    pad = 4
    left = max(0, bbox[0] - pad)
    top = max(0, bbox[1] - pad)
    right = min(w, bbox[2] + pad)
    bottom = min(h, bbox[3] + pad)
    return out_img.crop((left, top, right, bottom))


def main() -> None:
    count = 0
    for batch in BATCHES:
        src = INBOX / batch["file"]
        if not src.exists():
            raise FileNotFoundError(f"Missing batch sheet: {src}")
        sheet = Image.open(src)
        sw, sh = sheet.size
        cw = sw / batch["cols"]
        ch = sh / batch["rows"]

        for (col, row), rel_out in batch["cells"].items():
            box = (int(round(col * cw)), int(round(row * ch)), int(round((col + 1) * cw)), int(round((row + 1) * ch)))
            cell = sheet.crop(box)
            extracted = extract_cell(cell)
            dst = OUT / rel_out
            dst.parent.mkdir(parents=True, exist_ok=True)
            extracted.save(dst)
            print(f"Extracted {rel_out}: {extracted.size[0]}x{extracted.size[1]} RGBA")
            count += 1

    print(f"Done: extracted {count} RGBA sprites into {OUT}")


if __name__ == "__main__":
    main()
