#!/usr/bin/env python3
"""Extract, adapt, tile-fix, validate, and preview Batch 01 (Ground & Platforms)
from assets/source/environment/b01/original_contact_sheet.png.
"""

from __future__ import annotations

import collections
import json
import math
from pathlib import Path
from PIL import Image, ImageDraw

PROJECT_ROOT = Path(__file__).resolve().parents[2]
SOURCE_SHEET = PROJECT_ROOT / "assets" / "source" / "environment" / "b01" / "original_contact_sheet.png"
BASE_ENV = PROJECT_ROOT / "assets" / "base" / "environment"
PREVIEWS_DIR = PROJECT_ROOT / "assets" / "previews"


def remove_exterior_background(img: Image.Image) -> tuple[Image.Image, list[tuple[int, int, int, int]]]:
    """Flood-fill remove near-white/gray checkerboard background from exterior only."""
    rgba = img.convert("RGBA")
    w, h = rgba.size
    px = rgba.load()

    def is_bg(r: int, g: int, b: int) -> bool:
        return r >= 232 and g >= 232 and b >= 232 and (max(r, g, b) - min(r, g, b)) <= 12

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

    # Soften 1px anti-aliased fringe adjacent to transparent background
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if r >= 215 and g >= 215 and b >= 215 and (max(r, g, b) - min(r, g, b)) <= 14:
                has_trans_nb = any(
                    px[nx, ny][3] == 0
                    for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1))
                )
                if has_trans_nb:
                    px[x, y] = (r, g, b, 0)

    # Connected components
    fg_vis = bytearray(w * h)
    boxes: list[tuple[int, int, int, int]] = []
    for y in range(h):
        for x in range(w):
            idx = y * w + x
            if px[x, y][3] > 0 and not fg_vis[idx]:
                fg_vis[idx] = 1
                dq = collections.deque([(x, y)])
                minx = maxx = x
                miny = maxy = y
                cnt = 0
                while dq:
                    cx, cy = dq.popleft()
                    cnt += 1
                    minx = min(minx, cx)
                    maxx = max(maxx, cx)
                    miny = min(miny, cy)
                    maxy = max(maxy, cy)
                    for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                        if 0 <= nx < w and 0 <= ny < h:
                            nidx = ny * w + nx
                            if px[nx, ny][3] > 0 and not fg_vis[nidx]:
                                fg_vis[nidx] = 1
                                dq.append((nx, ny))
                if cnt > 2000:
                    boxes.append((minx, miny, maxx + 1, maxy + 1))

    return rgba, boxes


def fit_aspect_rgba(crop: Image.Image, target_w: int, target_h: int, margin: int = 4) -> Image.Image:
    """Scale crop proportionally to fit within (target_w - 2*margin, target_h - 2*margin) centered."""
    avail_w = target_w - 2 * margin
    avail_h = target_h - 2 * margin
    cw, ch = crop.size
    scale = min(avail_w / cw, avail_h / ch)
    nw = max(1, int(round(cw * scale)))
    nh = max(1, int(round(ch * scale)))
    resized = crop.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))
    ox = (target_w - nw) // 2
    oy = (target_h - nh) // 2
    canvas.paste(resized, (ox, oy), resized)
    return canvas


def make_seamless_tile(patch: Image.Image, size: int = 128) -> Image.Image:
    """Create a 100% seamless repeating tile using 4-way mirror reflection of a clean interior patch."""
    half = size // 2
    q = patch.convert("RGBA").resize((half, half), Image.Resampling.LANCZOS)
    q_h = q.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    q_v = q.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
    q_hv = q_h.transpose(Image.Transpose.FLIP_TOP_BOTTOM)

    out = Image.new("RGBA", (size, size))
    out.paste(q, (0, 0))
    out.paste(q_h, (half, 0))
    out.paste(q_v, (0, half))
    out.paste(q_hv, (half, half))
    return out


def compute_edge_seam_diff(img: Image.Image) -> dict[str, float]:
    """Measure mean absolute pixel difference across opposite tile edges."""
    w, h = img.size
    px = img.load()
    lr_diff = 0.0
    for y in range(h):
        p1 = px[0, y]
        p2 = px[w - 1, y]
        lr_diff += sum(abs(p1[c] - p2[c]) for c in range(3)) / 3.0
    lr_diff /= h

    tb_diff = 0.0
    for x in range(w):
        p1 = px[x, 0]
        p2 = px[x, h - 1]
        tb_diff += sum(abs(p1[c] - p2[c]) for c in range(3)) / 3.0
    tb_diff /= w

    return {"lr_mean_diff": round(lr_diff, 3), "tb_mean_diff": round(tb_diff, 3)}


def sort_boxes_by_rows(boxes: list[tuple[int, int, int, int]]) -> list[tuple[int, int, int, int]]:
    """Sort 10 boxes into top-to-bottom rows, left-to-right within each row."""
    rows: list[list[tuple[int, int, int, int]]] = []
    for b in sorted(boxes, key=lambda item: item[1]):
        cy = (b[1] + b[3]) / 2.0
        placed = False
        for r in rows:
            rcy = (r[0][1] + r[0][3]) / 2.0
            if abs(cy - rcy) < 120.0:
                r.append(b)
                placed = True
                break
        if not placed:
            rows.append([b])
    ordered: list[tuple[int, int, int, int]] = []
    for r in rows:
        ordered.extend(sorted(r, key=lambda item: item[0]))
    return ordered


def main() -> int:
    if not SOURCE_SHEET.is_file():
        raise FileNotFoundError(f"Missing source contact sheet: {SOURCE_SHEET}")

    raw = Image.open(SOURCE_SHEET)
    rgba_sheet, raw_boxes = remove_exterior_background(raw)
    ordered = sort_boxes_by_rows(raw_boxes)
    if len(ordered) != 10:
        raise RuntimeError(f"Expected 10 assets in contact sheet, found {len(ordered)}: {ordered}")

    # Mapping of ordered components (row-major):
    # Row 0: [0]=jade_01, [1]=jade_02, [2]=rune_center
    # Row 1: [3]=cloud_edge, [4]=cloud_corner, [5]=bridge_01, [6]=bridge_02
    # Row 2: [7]=stairs_01, [8]=cloud_tile, [9]=transition_01
    outputs: list[dict] = []

    def crop_box(idx: int) -> Image.Image:
        return rgba_sheet.crop(ordered[idx])

    # 1. Repeating ground tiles (synthesized from clean interior surface, avoiding edge outlines/dirt/flowers)
    jade1_crop = crop_box(0)
    gw, gh = jade1_crop.size
    jade1_patch = jade1_crop.crop((int(gw * 0.20), int(gh * 0.22), int(gw * 0.66), int(gh * 0.56)))
    jade1_tile = make_seamless_tile(jade1_patch, 128)
    jade1_path = BASE_ENV / "ground" / "ground_jade_tile_01.png"
    jade1_tile.save(jade1_path)

    jade2_crop = crop_box(1)
    g2w, g2h = jade2_crop.size
    jade2_patch = jade2_crop.crop((int(g2w * 0.24), int(g2h * 0.24), int(g2w * 0.72), int(g2h * 0.66)))
    jade2_tile = make_seamless_tile(jade2_patch, 128)
    jade2_path = BASE_ENV / "ground" / "ground_jade_tile_02.png"
    jade2_tile.save(jade2_path)

    cloud_crop = crop_box(8)
    cw, ch = cloud_crop.size
    cloud_patch = cloud_crop.crop((int(cw * 0.18), int(ch * 0.18), int(cw * 0.82), int(ch * 0.80)))
    cloud_tile = make_seamless_tile(cloud_patch, 128)
    cloud_path = BASE_ENV / "ground" / "ground_cloud_tile_01.png"
    cloud_tile.save(cloud_path)

    # 2. Centerpiece & transition
    rune_tile = fit_aspect_rgba(crop_box(2), 128, 128, margin=2)
    rune_path = BASE_ENV / "ground" / "ground_rune_center_01.png"
    rune_tile.save(rune_path)

    trans_tile = fit_aspect_rgba(crop_box(9), 128, 128, margin=2)
    trans_path = BASE_ENV / "ground" / "ground_grass_stone_transition_01.png"
    trans_tile.save(trans_path)

    # 3. Platforms
    edge_img = fit_aspect_rgba(crop_box(3), 256, 128, margin=4)
    edge_path = BASE_ENV / "platforms" / "platform_cloud_edge_01.png"
    edge_img.save(edge_path)

    corner_img = fit_aspect_rgba(crop_box(4), 128, 128, margin=4)
    corner_path = BASE_ENV / "platforms" / "platform_cloud_corner_01.png"
    corner_img.save(corner_path)

    # 4. Bridges & Stairs
    bridge1_img = fit_aspect_rgba(crop_box(5), 256, 128, margin=4)
    bridge1_path = BASE_ENV / "bridges" / "bridge_stone_01.png"
    bridge1_img.save(bridge1_path)

    bridge2_img = fit_aspect_rgba(crop_box(6), 256, 128, margin=4)
    bridge2_path = BASE_ENV / "bridges" / "bridge_stone_02.png"
    bridge2_img.save(bridge2_path)

    stairs_img = fit_aspect_rgba(crop_box(7), 128, 128, margin=4)
    stairs_path = BASE_ENV / "bridges" / "stairs_stone_01.png"
    stairs_img.save(stairs_path)

    specs = [
        ("ground_jade_tile_01", jade1_path, True, "PASS", "Seamless 128x128 repeating jade grass tile"),
        ("ground_jade_tile_02", jade2_path, True, "PASS", "Seamless 128x128 repeating lime-jade grass variant"),
        ("ground_cloud_tile_01", cloud_path, True, "PASS", "Seamless 128x128 repeating cloud surface tile"),
        ("ground_rune_center_01", rune_path, False, "PASS", "128x128 stone/gold rune centerpiece"),
        ("ground_grass_stone_transition_01", trans_path, False, "REVIEW_REQUIRED", "Isolated block transition; requires edge-matched tile repaint if used in seamless TileMapLayer"),
        ("platform_cloud_edge_01", edge_path, False, "PASS", "256x128 cloud platform edge with 2.5D underside thickness"),
        ("platform_cloud_corner_01", corner_path, False, "PASS", "128x128 cloud platform corner"),
        ("bridge_stone_01", bridge1_path, False, "PASS", "256x128 stone bridge with corner pillars"),
        ("bridge_stone_02", bridge2_path, False, "PASS", "256x128 stone bridge variant"),
        ("stairs_stone_01", stairs_path, False, "PASS", "128x128 stone stairs"),
    ]

    for aid, path, is_repeating, status, notes in specs:
        with Image.open(path) as im:
            seam = compute_edge_seam_diff(im) if is_repeating else None
            if is_repeating and (seam["lr_mean_diff"] > 6.0 or seam["tb_mean_diff"] > 6.0):
                status = "FAILED"
            outputs.append({
                "asset_id": aid,
                "path": str(path.relative_to(PROJECT_ROOT)),
                "format": "PNG",
                "mode": im.mode,
                "dimensions": {"width": im.width, "height": im.height},
                "repeating_tile": is_repeating,
                "seam_metrics": seam,
                "validation_status": status,
                "notes": notes,
            })

    # Write B01 metadata compatible with gameforge-kit asset_metadata.schema.json
    meta_doc = {
        "schema_version": "1.0.0",
        "asset_id": "b01_ground_and_platforms",
        "asset_type": "environment",
        "project": "cloudbound",
        "generator_id": "b01_contact_sheet_adapter",
        "generator_version": "1.0.0",
        "seed": 0,
        "source": {"contact_sheet": str(SOURCE_SHEET.relative_to(PROJECT_ROOT))},
        "style": {"perspective": "3_4_top_down", "palette": "jade_cream_sky_gold"},
        "dimensions": {"tile_size": [128, 128], "wide_piece": [256, 128]},
        "output_formats": ["png_rgba"],
        "validation_status": "REVIEW_REQUIRED",
        "provenance": {"assets": outputs},
    }
    (BASE_ENV / "b01_metadata.json").write_text(json.dumps(meta_doc, indent=2), encoding="utf-8")

    # Generate previews
    PREVIEWS_DIR.mkdir(parents=True, exist_ok=True)
    _build_contact_sheet_preview(outputs)
    _build_tileability_preview(jade1_tile, jade2_tile, cloud_tile)
    _build_assembly_preview(jade1_tile, rune_tile, edge_img, bridge1_img, stairs_img)

    for o in outputs:
        print(f"[{o['validation_status']}] {o['asset_id']} ({o['dimensions']['width']}x{o['dimensions']['height']}) seam={o['seam_metrics']}")
    return 0


def _build_contact_sheet_preview(outputs: list[dict]) -> None:
    cols = 5
    cell_w, cell_h = 280, 180
    sheet = Image.new("RGBA", (cols * cell_w, 2 * cell_h), (24, 34, 52, 255))
    draw = ImageDraw.Draw(sheet)
    for idx, item in enumerate(outputs):
        r, c = divmod(idx, cols)
        x0, y0 = c * cell_w, r * cell_h
        draw.rectangle([x0 + 6, y0 + 6, x0 + cell_w - 6, y0 + cell_h - 6], outline=(85, 115, 150, 255), width=2)
        with Image.open(PROJECT_ROOT / item["path"]) as im:
            thumb = fit_aspect_rgba(im, cell_w - 24, cell_h - 48, margin=4)
            sheet.paste(thumb, (x0 + 12, y0 + 10), thumb)
        label = f"{item['asset_id']} [{item['validation_status']}]"
        draw.text((x0 + 12, y0 + cell_h - 28), label, fill=(235, 245, 255, 255))
    sheet.save(PREVIEWS_DIR / "b01_contact_sheet.png")


def _build_tileability_preview(t1: Image.Image, t2: Image.Image, t3: Image.Image) -> None:
    tile_sz = 128
    gap = 24
    panel_w = tile_sz * 3
    canvas = Image.new("RGBA", (panel_w * 3 + gap * 4, panel_w + 56), (24, 34, 52, 255))
    draw = ImageDraw.Draw(canvas)
    for p_idx, (name, tile) in enumerate([("jade_01 (3x3)", t1), ("jade_02 (3x3)", t2), ("cloud_01 (3x3)", t3)]):
        ox = gap + p_idx * (panel_w + gap)
        oy = 40
        draw.text((ox, 14), name, fill=(240, 230, 170, 255))
        for gy in range(3):
            for gx in range(3):
                canvas.paste(tile, (ox + gx * tile_sz, oy + gy * tile_sz))
    canvas.save(PREVIEWS_DIR / "b01_tileability_test.png")


def _build_assembly_preview(
    jade: Image.Image,
    rune: Image.Image,
    edge: Image.Image,
    bridge: Image.Image,
    stairs: Image.Image,
) -> None:
    canvas = Image.new("RGBA", (900, 560), (42, 72, 118, 255))
    # Left 3x3 grass island + center rune
    for gy in range(3):
        for gx in range(3):
            canvas.paste(jade, (64 + gx * 128, 120 + gy * 128))
    canvas.paste(rune, (64 + 128, 120 + 128), rune)
    # Cloud platform rim below left island
    canvas.paste(edge, (128, 450), edge)
    # Stone bridge connecting left to right
    canvas.paste(bridge, (410, 230), bridge)
    # Right platform + stairs
    for gy in range(2):
        for gx in range(2):
            canvas.paste(jade, (620 + gx * 128, 170 + gy * 128))
    canvas.paste(stairs, (680, 390), stairs)
    canvas.save(PREVIEWS_DIR / "b01_assembly_preview.png")


if __name__ == "__main__":
    raise SystemExit(main())
