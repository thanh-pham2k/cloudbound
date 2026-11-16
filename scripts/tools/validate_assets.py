#!/usr/bin/env python3
"""Lightweight repository-level asset validator for Cloudbound.

Validates:
- Output path safety (nothing written inside tools/gameforge-kit/)
- Referenced SpriteFrames .tres existence
- PNG RGBA alpha channel and valid dimensions
- Atlas JSON metadata consistency & frame counts
- Lowercase snake_case filename conventions

Does NOT fail if future asset batches (B01-B06) in assets/source/ or assets/base/
have not yet been delivered.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from PIL import Image

PROJECT_ROOT = Path(__file__).resolve().parents[2]
FILENAME_RE = re.compile(r"^[a-z0-9_.\-]+$")
VALID_BASE_DIMS = {(64, 64), (128, 128), (128, 64), (256, 128), (128, 192), (256, 256)}


def validate_animation_atlases(errors: list[str]) -> None:
    generated = PROJECT_ROOT / "assets" / "generated"
    for group in ("wukong", "enemies", "pickups", "combat_vfx"):
        for metadata in sorted((generated / group).rglob("*.atlas.json")):
            label = metadata.relative_to(PROJECT_ROOT)
            meta = json.loads(metadata.read_text(encoding="utf-8"))
            width, height = meta["frame_width"], meta["frame_height"]
            columns, rows, padding = meta["columns"], meta["rows"], meta["padding"]
            expected_size = (columns * (width + padding) - padding,
                             rows * (height + padding) - padding)
            png = metadata.with_suffix("").with_suffix(".png")
            if not png.is_file():
                errors.append(f"Missing atlas image: {label}")
                continue
            with Image.open(png) as image:
                if image.mode != "RGBA" or image.size != expected_size:
                    errors.append(f"Invalid RGBA atlas dimensions: {label}")
                    continue
                frames = meta["frames"]
                if len(frames) != meta["frame_count"] or not 0 < len(frames) <= columns * rows:
                    errors.append(f"Incorrect frame count: {label}")
                    continue
                seen = set()
                for index, frame in enumerate(frames):
                    x = (index % columns) * (width + padding)
                    y = (index // columns) * (height + padding)
                    if (frame["index"], frame["x"], frame["y"], frame["w"], frame["h"]) != (index, x, y, width, height):
                        errors.append(f"Misaligned cell {index}: {label}")
                        continue
                    cell = image.crop((x, y, x + width, y + height))
                    low, high = cell.getchannel("A").getextrema()
                    if low != 0 or high == 0:
                        errors.append(f"Cell {index} needs visible art and transparent pixels: {label}")
                    pixels = cell.tobytes()
                    if pixels in seen:
                        errors.append(f"Duplicate cell {index}: {label}")
                    seen.add(pixels)


def validate_repo_assets() -> tuple[list[str], list[str]]:
    errors: list[str] = []
    notes: list[str] = []

    profile_path = PROJECT_ROOT / "profiles" / "cloudbound_isometric.json"
    if not profile_path.is_file():
        errors.append("Missing profile: profiles/cloudbound_isometric.json")
        return errors, notes

    profile = json.loads(profile_path.read_text(encoding="utf-8"))
    fw = int(profile["atlas"]["frame_width"])
    fh = int(profile["atlas"]["frame_height"])
    cols = int(profile["atlas"]["columns"])
    anim_cfg = profile.get("animations", {})

    # 1. Check required active SpriteFrames .tres referenced by game
    required_chars = ["player_hero", "enemy_melee", "enemy_ranged", "enemy_tank", "boss_thunder_warden"]
    for cid in required_chars:
        tres = PROJECT_ROOT / "assets" / "generated" / "sprites" / cid / f"{cid}_sprite_frames.tres"
        if not tres.is_file():
            errors.append(f"Missing active SpriteFrames: {tres.relative_to(PROJECT_ROOT)}")

    # 2. Validate generated sprite atlases + metadata
    gen_sprites_dir = PROJECT_ROOT / "assets" / "generated" / "sprites"
    if gen_sprites_dir.is_dir():
        for json_path in sorted(gen_sprites_dir.rglob("*.atlas.json")):
            rel = json_path.relative_to(PROJECT_ROOT)
            if not FILENAME_RE.match(json_path.name):
                errors.append(f"Unexpected filename: {rel}")
            png_path = json_path.with_name(json_path.name.replace(".atlas.json", ".png"))
            if not png_path.is_file():
                errors.append(f"Missing atlas PNG for metadata: {rel}")
                continue

            meta = json.loads(json_path.read_text(encoding="utf-8"))
            frames = meta.get("frames", [])
            with Image.open(png_path) as img:
                if img.mode != "RGBA":
                    errors.append(f"Missing RGBA alpha channel ({img.mode}): {png_path.relative_to(PROJECT_ROOT)}")
                expected_w = fw * max(cols, len(frames))
                if img.height != fh or img.width != expected_w:
                    errors.append(
                        f"Invalid atlas dimensions {img.size} (expected {expected_w}x{fh}): {png_path.relative_to(PROJECT_ROOT)}"
                    )

            # Check frame count against profile animation config
            stem = png_path.stem
            for anim_name, cfg in anim_cfg.items():
                if f"_{anim_name}_" in stem:
                    expected_frames = int(cfg["frames"])
                    if len(frames) != expected_frames:
                        errors.append(f"Incorrect frame count ({len(frames)} != {expected_frames}) in {rel}")
                    break

    # 3. Validate any delivered PNGs in assets/base/ and assets/source/ (skip empty .gitkeep folders)
    for bucket in ("base", "source"):
        bucket_dir = PROJECT_ROOT / "assets" / bucket
        if not bucket_dir.is_dir():
            continue
        pngs = sorted(bucket_dir.rglob("*.png"))
        if not pngs:
            notes.append(f"assets/{bucket}/: 0 PNGs delivered yet (pending future batches)")
            continue
        for png_path in pngs:
            rel = png_path.relative_to(PROJECT_ROOT)
            if not FILENAME_RE.match(png_path.name):
                errors.append(f"Unexpected filename: {rel}")
            with Image.open(png_path) as img:
                if bucket == "base" and img.mode != "RGBA":
                    errors.append(f"Missing RGBA alpha channel ({img.mode}): {rel}")
                if bucket == "base" and img.size not in VALID_BASE_DIMS:
                    errors.append(f"Unexpected base PNG dimensions {img.size} in {rel}")

    # 4. Path safety: ensure no generated artifacts inside tools/gameforge-kit/
    toolkit_gen = PROJECT_ROOT / "tools" / "gameforge-kit" / "assets" / "sprites" / "generated"
    if toolkit_gen.is_dir() and any(p.is_file() and p.name != ".gitkeep" for p in toolkit_gen.rglob("*")):
        errors.append("Unsafe output: generated files found inside tools/gameforge-kit/")

    validate_animation_atlases(errors)
    return errors, notes


def main() -> int:
    errors, notes = validate_repo_assets()
    for n in notes:
        print(f"[INFO] {n}")
    if errors:
        for e in errors:
            print(f"[FAIL] {e}", file=sys.stderr)
        print(f"Asset validation FAILED ({len(errors)} issue(s)).", file=sys.stderr)
        return 1
    print("[PASS] Repository asset validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
