#!/usr/bin/env python3
"""Generate Phase 3 assembly previews (platform, bridge, transitions) and update
assets/base/environment/b01_metadata.json with real pixel/hash validation results.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageStat

PROJECT_ROOT = Path(__file__).resolve().parents[2]
BASE_ENV = PROJECT_ROOT / "assets" / "base" / "environment"
PREVIEWS = PROJECT_ROOT / "assets" / "previews"


def edge_metrics(im: Image.Image) -> dict[str, float]:
    im = im.convert("RGBA")
    left = im.crop((0, 0, 1, im.height)).tobytes()
    right = im.crop((im.width - 1, 0, im.width, im.height)).tobytes()
    top = im.crop((0, 0, im.width, 1)).tobytes()
    bottom = im.crop((0, im.height - 1, im.width, im.height)).tobytes()

    def mae(a: bytes, b: bytes) -> float:
        return round(sum(abs(a[i] - b[i]) for i in range(len(a))) / len(a), 3)

    flip_x = im.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    flip_y = im.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
    mx = round(sum(ImageStat.Stat(ImageChops.difference(im.convert("RGB"), flip_x.convert("RGB"))).mean) / 3.0, 3)
    my = round(sum(ImageStat.Stat(ImageChops.difference(im.convert("RGB"), flip_y.convert("RGB"))).mean) / 3.0, 3)
    return {"lr_mae": mae(left, right), "tb_mae": mae(top, bottom), "mirror_x_mae": mx, "mirror_y_mae": my}


def build_platform_preview() -> None:
    pdir = BASE_ENV / "platforms"
    gdir = BASE_ENV / "ground"
    canvas = Image.new("RGBA", (640, 640), (35, 58, 96, 255))
    grass = Image.open(gdir / "ground_jade_tile_01.png").convert("RGBA")

    # 3x3 inner grass at grid (1..3, 1..3) -> pixel (128..512, 128..512)
    for gy in range(1, 4):
        for gx in range(1, 4):
            canvas.alpha_composite(grass, (gx * 128, gy * 128))

    # Edges around 3x3
    for i in range(1, 4):
        canvas.alpha_composite(Image.open(pdir / "platform_cloud_edge_north_01.png").convert("RGBA"), (i * 128, 0))
        canvas.alpha_composite(Image.open(pdir / "platform_cloud_edge_south_01.png").convert("RGBA"), (i * 128, 4 * 128))
        canvas.alpha_composite(Image.open(pdir / "platform_cloud_edge_west_01.png").convert("RGBA"), (0, i * 128))
        canvas.alpha_composite(Image.open(pdir / "platform_cloud_edge_east_01.png").convert("RGBA"), (4 * 128, i * 128))

    # Corners
    canvas.alpha_composite(Image.open(pdir / "platform_cloud_corner_nw_01.png").convert("RGBA"), (0, 0))
    canvas.alpha_composite(Image.open(pdir / "platform_cloud_corner_ne_01.png").convert("RGBA"), (4 * 128, 0))
    canvas.alpha_composite(Image.open(pdir / "platform_cloud_corner_sw_01.png").convert("RGBA"), (0, 4 * 128))
    canvas.alpha_composite(Image.open(pdir / "platform_cloud_corner_se_01.png").convert("RGBA"), (4 * 128, 4 * 128))

    canvas.save(PREVIEWS / "b01_platform_assembly_preview.png")


def build_bridge_preview() -> None:
    bdir = BASE_ENV / "bridges"
    canvas = Image.new("RGBA", (720, 220), (35, 58, 96, 255))
    pieces = [
        "bridge_stone_entrance_01.png",
        "bridge_stone_middle_01.png",
        "bridge_stone_extension_01.png",
        "bridge_stone_exit_01.png",
    ]
    for idx, name in enumerate(pieces):
        im = Image.open(bdir / name).convert("RGBA")
        canvas.alpha_composite(im, (24 + idx * 128, 46))
    stairs = Image.open(bdir / "stairs_stone_01.png").convert("RGBA")
    canvas.alpha_composite(stairs, (560, 46))
    canvas.save(PREVIEWS / "b01_bridge_connection_preview.png")


def build_transition_preview() -> None:
    gdir = BASE_ENV / "ground"
    canvas = Image.new("RGBA", (640, 640), (35, 58, 96, 255))
    grass = Image.open(gdir / "ground_jade_tile_01.png").convert("RGBA")
    stone = Image.open(gdir / "ground_stone_tile_01.png").convert("RGBA")
    rune = Image.open(gdir / "ground_rune_center_01.png").convert("RGBA")

    # 5x5 layout: top-left grass, bottom-right stone courtyard with rune center & transitions
    # edge_south has grass on top -> stone on bottom; edge_east has grass on left -> stone on right
    t_top = Image.open(gdir / "ground_grass_stone_edge_south_01.png").convert("RGBA")
    t_left = Image.open(gdir / "ground_grass_stone_edge_east_01.png").convert("RGBA")
    t_corner = Image.open(gdir / "ground_grass_stone_outer_se_01.png").convert("RGBA")
    layout = [
        [grass, grass, grass, grass, grass],
        [grass, grass, t_corner, t_top, t_top],
        [grass, grass, t_left, stone, stone],
        [grass, grass, t_left, stone, rune],
        [grass, grass, t_left, stone, stone],
    ]
    for gy in range(5):
        for gx in range(5):
            canvas.alpha_composite(layout[gy][gx], (gx * 128, gy * 128))
    canvas.save(PREVIEWS / "b01_transition_assembly_preview.png")


def update_metadata() -> None:
    assets_list = []
    repeating = {"ground_jade_tile_01", "ground_jade_tile_02", "ground_cloud_tile_01", "ground_stone_tile_01"}
    for sub in ("ground", "platforms", "bridges"):
        for png in sorted((BASE_ENV / sub).glob("*.png")):
            aid = png.stem
            raw = png.read_bytes()
            sha = hashlib.sha256(raw).hexdigest()
            with Image.open(png) as im:
                dims = [im.width, im.height]
                mode = im.mode
                seam = edge_metrics(im) if aid in repeating else None
                issues = []
                if mode != "RGBA":
                    issues.append(f"Expected RGBA, got {mode}")
                if dims not in ([128, 128], [256, 128]):
                    issues.append(f"Unexpected dimensions {dims}")
                if seam and (seam["lr_mae"] > 6.0 or seam["tb_mae"] > 6.0):
                    issues.append(f"Seam MAE > 6.0: {seam}")

                # Keep backward-compat isolated block transition as REVIEW_REQUIRED,
                # and mark newly extracted directional/bridge modules REVIEW_REQUIRED pending Godot visual sign-off
                if aid == "ground_grass_stone_transition_01":
                    status = "REVIEW_REQUIRED"
                    issues.append("Legacy isolated transition block; use directional 12-tile transition set instead")
                elif issues:
                    status = "FAILED"
                else:
                    status = "PASS"

                assets_list.append({
                    "asset_id": aid,
                    "path": str(png.relative_to(PROJECT_ROOT)),
                    "sha256": sha,
                    "dimensions": {"width": dims[0], "height": dims[1]},
                    "mode": mode,
                    "seam_metrics": seam,
                    "validation_status": status,
                    "issues": issues,
                })

    meta = {
        "schema_version": "1.0.0",
        "asset_id": "b01_ground_and_platforms",
        "asset_type": "environment",
        "project": "cloudbound",
        "generator_id": "b01_revised_contact_sheet_adapter",
        "generator_version": "2.0.0",
        "seed": 0,
        "source": {
            "original": "assets/source/environment/b01/original_contact_sheet.png",
            "revised_sheets": [
                "assets/source/environment/b01/revised/b01_ground_tiles_revised.png",
                "assets/source/environment/b01/revised/b01_platform_modules_revised.png",
                "assets/source/environment/b01/revised/b01_bridge_stairs_revised.png",
                "assets/source/environment/b01/revised/b01_transitions_revised.png",
            ],
        },
        "style": {"perspective": "3_4_top_down", "palette": "jade_cream_sky_gold"},
        "dimensions": {"tile_size": [128, 128], "legacy_wide": [256, 128]},
        "output_formats": ["png_rgba"],
        "validation_status": "REVIEW_REQUIRED",
        "provenance": {"total_assets": len(assets_list), "assets": assets_list},
    }
    (BASE_ENV / "b01_metadata.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
    print(f"[ok] Updated b01_metadata.json ({len(assets_list)} assets)")


def main() -> int:
    build_platform_preview()
    build_bridge_preview()
    build_transition_preview()
    update_metadata()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
