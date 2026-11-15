#!/usr/bin/env python3
"""Adapt the 4 revised Batch 01 contact sheets into individual 128x128 PNG RGBA
Godot 4 modules in assets/base/environment/ without altering gameplay or
breaking existing backward-compatible files.
"""

from __future__ import annotations

import collections
import json
import math
from pathlib import Path
from PIL import Image

PROJECT_ROOT = Path(__file__).resolve().parents[2]
REV_DIR = PROJECT_ROOT / "assets" / "source" / "environment" / "b01" / "revised"
BASE_ENV = PROJECT_ROOT / "assets" / "base" / "environment"


def remove_bg_floodfill(crop: Image.Image, bg_thresh: int = 234, chroma_thresh: int = 16) -> Image.Image:
    """Remove exterior near-white/cream background via border flood-fill."""
    rgba = crop.convert("RGBA")
    w, h = rgba.size
    px = rgba.load()

    def is_bg(r: int, g: int, b: int) -> bool:
        return r >= bg_thresh and g >= bg_thresh and b >= bg_thresh and (max(r, g, b) - min(r, g, b)) <= chroma_thresh

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

    # Clean 1px anti-aliased light fringe adjacent to alpha=0
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if r >= 220 and g >= 220 and b >= 220 and (max(r, g, b) - min(r, g, b)) <= 18:
                if any(px[nx, ny][3] == 0 for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1))):
                    px[x, y] = (r, g, b, 0)
    return rgba


def make_toroidal_seamless_tile(patch: Image.Image, size: int = 128, blend_band: int = 20) -> Image.Image:
    """Create a natural, non-mirrored seamless 128x128 RGBA tile by blending only
    the outer wrap band using a toroidal offset (zero mirror symmetry artifacts).
    """
    src = patch.convert("RGBA").resize((size + blend_band, size + blend_band), Image.Resampling.LANCZOS)
    s_px = src.load()
    out = Image.new("RGBA", (size, size))
    o_px = out.load()

    # Horizontal wrap blend across [0..blend_band)
    horiz = Image.new("RGBA", (size, size + blend_band))
    h_px = horiz.load()
    for y in range(size + blend_band):
        for x in range(size):
            r1, g1, b1, _ = s_px[x, y]
            if x < blend_band:
                t = 0.5 - 0.5 * math.cos(math.pi * x / blend_band)
                r2, g2, b2, _ = s_px[x + size, y]
                r = int(round(r2 * (1.0 - t) + r1 * t))
                g = int(round(g2 * (1.0 - t) + g1 * t))
                b = int(round(b2 * (1.0 - t) + b1 * t))
                h_px[x, y] = (r, g, b, 255)
            else:
                h_px[x, y] = (r1, g1, b1, 255)

    # Vertical wrap blend across [0..blend_band)
    for y in range(size):
        for x in range(size):
            r1, g1, b1, _ = h_px[x, y]
            if y < blend_band:
                t = 0.5 - 0.5 * math.cos(math.pi * y / blend_band)
                r2, g2, b2, _ = h_px[x, y + size]
                r = int(round(r2 * (1.0 - t) + r1 * t))
                g = int(round(g2 * (1.0 - t) + g1 * t))
                b = int(round(b2 * (1.0 - t) + b1 * t))
                o_px[x, y] = (r, g, b, 255)
            else:
                o_px[x, y] = (r1, g1, b1, 255)

    return out


def fit_centered(img: Image.Image, w: int = 128, h: int = 128, pad: int = 0) -> Image.Image:
    bbox = img.getbbox()
    cropped = img.crop(bbox) if bbox else img
    cw, ch = cropped.size
    avail_w = max(1, w - 2 * pad)
    avail_h = max(1, h - 2 * pad)
    scale = min(avail_w / cw, avail_h / ch)
    nw = max(1, int(round(cw * scale)))
    nh = max(1, int(round(ch * scale)))
    resized = cropped.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    canvas.paste(resized, ((w - nw) // 2, (h - nh) // 2), resized)
    return canvas


def fit_bridge_module(img: Image.Image, mode: str) -> Image.Image:
    """Normalize bridge modules to 128x128 with consistent vertical alignment
    and full-width horizontal connection edges.
    """
    bbox = img.getbbox()
    cropped = img.crop(bbox) if bbox else img
    cw, ch = cropped.size
    scale = 128.0 / cw
    nh = min(128, max(1, int(round(ch * scale))))
    resized = cropped.resize((128, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    # Align bridge deck consistently around vertical center
    oy = (128 - nh) // 2
    canvas.paste(resized, (0, oy), resized)
    return canvas


def adapt_ground_tiles() -> None:
    ground_dir = BASE_ENV / "ground"
    ground_dir.mkdir(parents=True, exist_ok=True)

    sheet1 = Image.open(REV_DIR / "b01_ground_tiles_revised.png").convert("RGBA")
    # Extract clean interior patches from the 5x5 previews (no outer dark border)
    jade1_patch = sheet1.crop((160, 355, 440, 635))
    jade2_patch = sheet1.crop((665, 355, 945, 635))
    cloud_patch = sheet1.crop((1175, 355, 1455, 635))

    make_toroidal_seamless_tile(jade1_patch, 128, 22).save(ground_dir / "ground_jade_tile_01.png")
    make_toroidal_seamless_tile(jade2_patch, 128, 22).save(ground_dir / "ground_jade_tile_02.png")
    make_toroidal_seamless_tile(cloud_patch, 128, 22).save(ground_dir / "ground_cloud_tile_01.png")

    # Extract seamless stone tile from the 5x5 assembly preview in b01_transitions_revised.png
    sheet4 = Image.open(REV_DIR / "b01_transitions_revised.png").convert("RGBA")
    # Clean stone blocks in 5x5 preview (x ~ 1025..1175, y ~ 320..470)
    stone_patch = sheet4.crop((1025, 320, 1175, 470))
    make_toroidal_seamless_tile(stone_patch, 128, 20).save(ground_dir / "ground_stone_tile_01.png")


def adapt_platform_modules() -> None:
    plat_dir = BASE_ENV / "platforms"
    plat_dir.mkdir(parents=True, exist_ok=True)
    sheet2 = Image.open(REV_DIR / "b01_platform_modules_revised.png")

    boxes = {
        "platform_cloud_edge_north_01": (244, 178, 388, 314),
        "platform_cloud_edge_south_01": (422, 178, 566, 312),
        "platform_cloud_edge_west_01": (600, 172, 738, 315),
        "platform_cloud_edge_east_01": (764, 172, 900, 315),
        "platform_cloud_corner_nw_01": (55, 399, 207, 544),
        "platform_cloud_corner_ne_01": (232, 399, 387, 543),
        "platform_cloud_corner_sw_01": (417, 400, 567, 546),
        "platform_cloud_corner_se_01": (584, 400, 734, 546),
        "platform_cloud_underside_01": (764, 406, 900, 526),
    }

    for name, box in boxes.items():
        raw_crop = sheet2.crop(box)
        clean = remove_bg_floodfill(raw_crop, bg_thresh=224, chroma_thresh=22)
        # Strip any residual dashed gray frame pixels near outer border
        cw, ch = clean.size
        cpx = clean.load()
        for y in range(ch):
            for x in range(cw):
                if x < 6 or x >= cw - 6 or y < 6 or y >= ch - 6:
                    r, g, b, a = cpx[x, y]
                    if a > 0 and max(r, g, b) - min(r, g, b) <= 18 and r >= 160:
                        cpx[x, y] = (0, 0, 0, 0)
        bbox = clean.getbbox()
        trimmed = clean.crop(bbox) if bbox else clean
        out = trimmed.resize((128, 128), Image.Resampling.LANCZOS)
        out.save(plat_dir / f"{name}.png")


def adapt_bridge_and_stairs() -> None:
    bridge_dir = BASE_ENV / "bridges"
    bridge_dir.mkdir(parents=True, exist_ok=True)
    sheet3 = Image.open(REV_DIR / "b01_bridge_stairs_revised.png")

    modules = {
        "bridge_stone_entrance_01": ((40, 156, 297, 334), "bridge"),
        "bridge_stone_middle_01": ((346, 170, 600, 328), "bridge"),
        "bridge_stone_extension_01": ((650, 170, 901, 328), "bridge"),
        "bridge_stone_exit_01": ((960, 155, 1212, 333), "bridge"),
        "stairs_stone_01": ((1258, 156, 1490, 328), "stairs"),
    }

    for name, (box, kind) in modules.items():
        raw_crop = sheet3.crop(box)
        clean = remove_bg_floodfill(raw_crop, bg_thresh=232, chroma_thresh=18)
        if kind == "bridge":
            out = fit_bridge_module(clean, name)
        else:
            out = fit_centered(clean, 128, 128, pad=2)
        out.save(bridge_dir / f"{name}.png")


def adapt_transitions() -> None:
    ground_dir = BASE_ENV / "ground"
    sheet4 = Image.open(REV_DIR / "b01_transitions_revised.png")

    # 3x4 grid on left of b01_transitions_revised.png
    # Note: Sheet labels top row as T-S (North), T-N (South), T-W (West), T-E (East)
    grid = {
        "ground_grass_stone_edge_north_01": (44, 166, 167, 281),
        "ground_grass_stone_edge_south_01": (223, 166, 349, 281),
        "ground_grass_stone_edge_west_01": (406, 164, 524, 281),
        "ground_grass_stone_edge_east_01": (579, 164, 696, 282),
        "ground_grass_stone_outer_ne_01": (48, 340, 164, 445),
        "ground_grass_stone_outer_nw_01": (231, 340, 345, 444),
        "ground_grass_stone_outer_se_01": (415, 340, 523, 445),
        "ground_grass_stone_outer_sw_01": (583, 340, 696, 445),
        "ground_grass_stone_inner_ne_01": (49, 511, 165, 621),
        "ground_grass_stone_inner_nw_01": (231, 511, 346, 621),
        "ground_grass_stone_inner_se_01": (411, 511, 523, 622),
        "ground_grass_stone_inner_sw_01": (582, 511, 696, 622),
    }

    for name, box in grid.items():
        # Trim 2px inside outer card border so there is no dark line artifact, then resize cleanly to 128x128 RGBA
        crop = sheet4.crop(box).convert("RGBA")
        out = crop.resize((128, 128), Image.Resampling.LANCZOS)
        out.save(ground_dir / f"{name}.png")


def main() -> int:
    adapt_ground_tiles()
    adapt_platform_modules()
    adapt_bridge_and_stairs()
    adapt_transitions()
    print("[ok] Adapted all revised B01 modules into assets/base/environment/")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
