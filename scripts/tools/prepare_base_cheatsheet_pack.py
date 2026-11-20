"""Extract the 11 Base Asset Cheatsheet sprite sheets (001..011) into assets/survivor/."""
from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
INBOX = ROOT / "assets/inbox"
ARCHIVE = ROOT / "assets/archive/adapted/survivor/cheatsheet_v1"
SURVIVOR = ROOT / "assets/survivor"


def source_path(prefix: str) -> Path:
    for folder in (INBOX, ARCHIVE):
        matches = sorted(folder.glob(f"{prefix}-*.png"))
        if matches:
            return matches[0]
    raise FileNotFoundError(f"Missing source sheet {prefix} in inbox or archive")


def remove_white_bg(cell: Image.Image, clear_holes: bool = False) -> Image.Image:
    """Flood-fill remove exterior pure/near-white background while preserving interior whites."""
    rgba = cell.convert("RGBA")
    arr = np.array(rgba, dtype=np.int16)
    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
    bright = np.minimum(np.minimum(r, g), b)
    chroma = np.maximum(np.maximum(r, g), b) - bright

    # Pixels that are very light and nearly neutral can be exterior background.
    bg_candidate = (bright >= 232) & (chroma <= 24)
    border = np.zeros(bg_candidate.shape, dtype=bool)
    border[[0, -1], :] = True
    border[:, [0, -1]] = True
    bg = ndimage.binary_propagation(border & bg_candidate, mask=bg_candidate)

    if clear_holes:
        # Remove large enclosed pure-white holes (e.g. bow interior, tree branch gaps).
        pure_holes = (~bg) & (bright >= 244) & (chroma <= 12)
        hlbl, hcnt = ndimage.label(pure_holes)
        if hcnt > 0:
            hsizes = ndimage.sum(pure_holes, hlbl, range(1, hcnt + 1))
            for idx, sz in enumerate(hsizes, 1):
                if sz >= 120:
                    bg |= (hlbl == idx)
            # Expand slightly into immediate near-white border of those holes.
            bg = ndimage.binary_propagation(bg, mask=bg_candidate)

    # Soften 1px anti-aliased bright fringe touching exterior background.
    fringe_zone = ndimage.binary_dilation(bg, iterations=1) & (~bg)
    soft_white = fringe_zone & (bright >= 210) & (chroma <= 32)

    out = arr.astype(np.uint8)
    out[bg, 3] = 0
    if np.any(soft_white):
        fade = np.clip((248 - bright[soft_white]) * 6, 0, 255).astype(np.uint8)
        out[soft_white, 3] = np.minimum(out[soft_white, 3], fade)

    # Remove tiny isolated stray dust specks (area <= 4 px) far from main sprite.
    alpha_mask = out[:, :, 3] > 24
    labeled, count = ndimage.label(alpha_mask)
    if count > 1:
        sizes = ndimage.sum(alpha_mask, labeled, range(1, count + 1))
        for idx, sz in enumerate(sizes, 1):
            if sz <= 4:
                out[labeled == idx, 3] = 0

    return Image.fromarray(out)


def crop_alpha(img: Image.Image, pad: int = 2) -> Image.Image:
    alpha = np.array(img)[:, :, 3]
    ys, xs = np.where(alpha > 12)
    if len(xs) == 0:
        return img
    x0 = max(0, int(xs.min()) - pad)
    y0 = max(0, int(ys.min()) - pad)
    x1 = min(img.width, int(xs.max()) + 1 + pad)
    y1 = min(img.height, int(ys.max()) + 1 + pad)
    return img.crop((x0, y0, x1, y1))


def _find_cut(profile: np.ndarray, target: int, radius: int) -> int:
    lo = max(1, target - radius)
    hi = min(len(profile) - 1, target + radius)
    if lo >= hi:
        return target
    window = profile[lo:hi]
    min_val = window.min()
    # Prefer the zero/minimum point closest to the ideal grid line.
    candidates = np.where(window == min_val)[0] + lo
    return int(candidates[np.argmin(np.abs(candidates - target))])


def split_grid(img: Image.Image, cols: int, rows: int, clear_holes: bool = False) -> list[Image.Image]:
    rgb = np.array(img.convert("RGB"), dtype=np.int16)
    non_bg = (rgb.min(axis=2) < 236) | ((rgb.max(axis=2) - rgb.min(axis=2)) > 20)

    # Find clean horizontal row cuts near ideal evenly-spaced lines.
    row_profile = non_bg.sum(axis=1)
    row_rad = max(8, img.height // (rows * 10))
    ys = [0] + [_find_cut(row_profile, round(r * img.height / rows), row_rad) for r in range(1, rows)] + [img.height]

    cells = []
    col_rad = max(8, img.width // (cols * 8))
    for r in range(rows):
        y0, y1 = ys[r], ys[r + 1]
        col_profile = non_bg[y0:y1, :].sum(axis=0)
        xs = [0] + [_find_cut(col_profile, round(c * img.width / cols), col_rad) for c in range(1, cols)] + [img.width]
        for c in range(cols):
            box = (xs[c], y0, xs[c + 1], y1)
            cells.append(crop_alpha(remove_white_bg(img.crop(box), clear_holes=clear_holes)))
    return cells


def build_golden_dragon_atlas(frames: list[Image.Image]) -> None:
    """Pack 12 frames (4x3) into golden_dragon.png + golden_dragon.tres matching prepare_survivor_enemies.py."""
    gutter = 6
    cap_w, cap_h, idle_h = 386, 298, 292
    scale = min(
        idle_h / frames[0].height,
        cap_w / max(p.width for p in frames),
        cap_h / max(p.height for p in frames),
    )
    cell_w, cell_h = cap_w + 2 * gutter, cap_h + 2 * gutter
    atlas = Image.new("RGBA", (4 * cell_w, 3 * cell_h), (0, 0, 0, 0))
    regions = []
    for i, pose in enumerate(frames):
        row, col = divmod(i, 4)
        resized = pose.resize(
            (round(pose.width * scale), round(pose.height * scale)),
            Image.Resampling.LANCZOS,
        )
        x = col * cell_w + (cell_w - resized.width) // 2
        y = (row + 1) * cell_h - gutter - resized.height
        atlas.alpha_composite(resized, (x, y))
        regions.append((col * cell_w + gutter, row * cell_h + gutter, cap_w, cap_h))

    dest_png = SURVIVOR / "enemies/golden_dragon.png"
    atlas.save(dest_png)

    # Update golden_dragon.tres matching existing format.
    clips = (
        ("idle", (0, 1), 4.0, True),
        ("move", (2, 3), 7.0, True),
        ("attack", (4, 5, 6, 7, 8, 9), 8.0, False),
        ("hurt", (10,), 8.0, False),
        ("dead", (11,), 4.0, False),
    )
    lines = [
        '[gd_resource type="SpriteFrames" load_steps=14 format=3]',
        "",
        '[ext_resource type="Texture2D" path="res://assets/survivor/enemies/golden_dragon.png" id="1"]',
        "",
    ]
    for i, r in enumerate(regions):
        lines += [
            f'[sub_resource type="AtlasTexture" id="frame_{i}"]',
            'atlas = ExtResource("1")',
            f"region = Rect2({r[0]}, {r[1]}, {r[2]}, {r[3]})",
            "",
        ]
    lines += ["[resource]", "animations = ["]
    for name, indices, speed, loop in clips:
        frames_txt = ", ".join(
            f'{{"duration": 1.0, "texture": SubResource("frame_{i}")}}' for i in indices
        )
        lines.append(
            f'{{"frames": [{frames_txt}], "loop": {"true" if loop else "false"}, '
            f'"name": &"{name}", "speed": {speed:.1f}}},'
        )
    lines.append("]")
    (SURVIVOR / "enemies/golden_dragon.tres").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    manifest: dict[str, dict] = {}

    # 001..005: Monkey Combat Roles
    role_specs = [
        ("001", "staff", 4, 3, True),
        ("002", "archer", 4, 3, True),
        ("003", "mage", 4, 3, False),
        ("004", "tank", 4, 2, True),
        ("005", "healer", 4, 2, False),
    ]
    for code, role, cols, rows, holes in role_specs:
        src = source_path(code)
        cells = split_grid(Image.open(src), cols, rows, clear_holes=holes)
        saved = []
        for idx, cell in enumerate(cells):
            out_path = SURVIVOR / f"combat/{role}_{idx:02d}.png"
            cell.save(out_path)
            saved.append(str(out_path.relative_to(ROOT)))
        manifest[code] = {"role": role, "source": str(src.relative_to(ROOT)), "outputs": saved}
        print(f"[{code}] {role}: extracted {len(saved)} frames")

    # 006: Portraits, Role Badges & Upgrade Icons (4x3)
    src_006 = source_path("006")
    cells_006 = split_grid(Image.open(src_006), 4, 3)
    names_006 = [
        "summon/portrait_staff.png",
        "summon/portrait_archer.png",
        "summon/portrait_mage.png",
        "summon/portrait_tank.png",
        "summon/portrait_healer.png",
        "summon/role_staff.png",
        "summon/role_archer.png",
        "summon/role_mage.png",
        "summon/role_tank.png",
        "summon/role_healer.png",
        "summon/upgrade_star.png",
        "summon/upgrade_crown.png",
    ]
    saved_006 = []
    for cell, rel in zip(cells_006, names_006):
        out_path = SURVIVOR / rel
        cell.save(out_path)
        saved_006.append(str(out_path.relative_to(ROOT)))
    manifest["006"] = {"kind": "ui_icons", "source": str(src_006.relative_to(ROOT)), "outputs": saved_006}
    print(f"[006] ui_icons: extracted {len(saved_006)} icons")

    # 007: Core HUD & Banners (3x3)
    src_007 = source_path("007")
    cells_007 = split_grid(Image.open(src_007), 3, 3)
    targets_007 = [
        ["card.png", "summon/card.png"],
        ["buy.png"],
        ["upgrade.png"],
        ["summon/train_button.png"],
        ["timer_frame.png"],
        ["hp_frame.png"],
        ["boss_hp.png"],
        ["victory.png"],
        ["defeat.png"],
    ]
    saved_007 = []
    for cell, rels in zip(cells_007, targets_007):
        for rel in rels:
            out_path = SURVIVOR / rel
            cell.save(out_path)
            saved_007.append(str(out_path.relative_to(ROOT)))
    manifest["007"] = {"kind": "hud_banners", "source": str(src_007.relative_to(ROOT)), "outputs": saved_007}
    print(f"[007] hud_banners: extracted {len(saved_007)} textures")

    # 008: Sun Wukong (Hero, 4x3) -> polish/wukong_00..11 + hero_00..11
    src_008 = source_path("008")
    cells_008 = split_grid(Image.open(src_008), 4, 3)
    saved_008 = []
    for idx, cell in enumerate(cells_008):
        for rel in (f"polish/wukong_{idx:02d}.png", f"hero_{idx:02d}.png"):
            out_path = SURVIVOR / rel
            cell.save(out_path)
            saved_008.append(str(out_path.relative_to(ROOT)))
    manifest["008"] = {"kind": "hero_wukong", "source": str(src_008.relative_to(ROOT)), "outputs": saved_008}
    print(f"[008] hero_wukong: extracted {len(cells_008)} frames (hero + polish/wukong)")

    # 009: Boar Boss (4x2) -> boss_00..07 (flipped horizontally to match right-facing runtime convention)
    src_009 = source_path("009")
    cells_009 = split_grid(Image.open(src_009), 4, 2)
    saved_009 = []
    for idx, cell in enumerate(cells_009):
        flipped = cell.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        out_path = SURVIVOR / f"boss_{idx:02d}.png"
        flipped.save(out_path)
        saved_009.append(str(out_path.relative_to(ROOT)))
    manifest["009"] = {"kind": "boar_boss", "source": str(src_009.relative_to(ROOT)), "outputs": saved_009}
    print(f"[009] boar_boss: extracted {len(saved_009)} frames (flipped to face right)")

    # 010: Golden Dragon (4x3) -> enemies/golden_dragon.png + .tres
    src_010 = source_path("010")
    cells_010 = split_grid(Image.open(src_010), 4, 3)
    build_golden_dragon_atlas(cells_010)
    manifest["010"] = {
        "kind": "golden_dragon",
        "source": str(src_010.relative_to(ROOT)),
        "outputs": ["assets/survivor/enemies/golden_dragon.png", "assets/survivor/enemies/golden_dragon.tres"],
    }
    print("[010] golden_dragon: rebuilt 4x3 atlas + SpriteFrames .tres")

    # 011: Environment / Terrain Props (4x2)
    src_011 = source_path("011")
    img_011 = Image.open(src_011)
    cells_011 = split_grid(img_011, 4, 2, clear_holes=False)
    # Clear enclosed white gaps between branches on Peach Tree (index 6) and Green Tree (index 7).
    tree_cells = split_grid(img_011, 4, 2, clear_holes=True)
    cells_011[6] = tree_cells[6]
    cells_011[7] = tree_cells[7]
    targets_011 = [
        ["grass.png"],
        ["meadow.png"],
        ["clearing.png"],
        ["rock.png"],
        ["bush.png"],
        ["flowers.png"],
        ["peach_tree.png", "peach_small.png"],
        ["green_tree.png", "green_small.png"],
    ]
    saved_011 = []
    for cell, rels in zip(cells_011, targets_011):
        for rel in rels:
            out_path = SURVIVOR / rel
            cell.save(out_path)
            saved_011.append(str(out_path.relative_to(ROOT)))
    manifest["011"] = {"kind": "environment", "source": str(src_011.relative_to(ROOT)), "outputs": saved_011}
    print(f"[011] environment: extracted {len(saved_011)} textures")

    out_manifest = SURVIVOR / "cheatsheet_manifest.json"
    out_manifest.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print("Wrote", out_manifest.relative_to(ROOT))


if __name__ == "__main__":
    main()
