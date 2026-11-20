"""Extract the 8 Base Asset Cheatsheet Enemy Roster sheets (001..008) into assets/survivor/enemies/."""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

from prepare_base_cheatsheet_pack import split_grid

ROOT = Path(__file__).resolve().parents[2]
INBOX = ROOT / "assets/inbox"
ARCHIVE = ROOT / "assets/archive/adapted/survivor/enemies_cheatsheet_v1"
DEST = ROOT / "assets/survivor/enemies"
GUTTER = 6

# (code, enemy_id, rows, tier, clear_holes)
SPECS = [
    ("001", "forest_goblin", 2, "light", True),
    ("002", "stone_golem", 2, "heavy", True),
    ("003", "fire_imp", 2, "light", False),
    ("004", "wooden_treant", 2, "heavy", True),
    ("005", "fire_fox_spirit", 3, "heavy", False),
    ("006", "golden_dragon", 3, "boss", False),
    ("007", "cave_bat", 2, "light", False),
    ("008", "bamboo_snake", 2, "light", True),
]

TIER_CAPS = {
    "light": (176, 140, 128),
    "heavy": (220, 150, 146),
    "boss": (386, 298, 292),
}


def source_path(prefix: str) -> Path:
    for folder in (INBOX, ARCHIVE):
        matches = sorted(folder.glob(f"{prefix}-*.png"))
        if matches:
            return matches[0]
    raise FileNotFoundError(f"Missing enemy source sheet {prefix}")


def build_enemy_atlas(enemy_id: str, frames: list[Image.Image], rows: int, tier: str) -> tuple[list[list[int]], list[int]]:
    cap_w, cap_h, idle_h = TIER_CAPS[tier]
    scale = min(
        idle_h / frames[0].height,
        cap_w / max(p.width for p in frames),
        cap_h / max(p.height for p in frames),
    )
    cell_w, cell_h = cap_w + 2 * GUTTER, cap_h + 2 * GUTTER
    atlas = Image.new("RGBA", (4 * cell_w, rows * cell_h), (0, 0, 0, 0))
    regions: list[list[int]] = []
    for i, pose in enumerate(frames):
        row, col = divmod(i, 4)
        resized = pose.resize(
            (round(pose.width * scale), round(pose.height * scale)),
            Image.Resampling.LANCZOS,
        )
        x = col * cell_w + (cell_w - resized.width) // 2
        y = (row + 1) * cell_h - GUTTER - resized.height
        atlas.alpha_composite(resized, (x, y))
        regions.append([col * cell_w + GUTTER, row * cell_h + GUTTER, cap_w, cap_h])

    atlas.save(DEST / f"{enemy_id}.png")

    if rows == 2:
        clips = (
            ("idle", (0, 1), 4.0, True),
            ("move", (2, 3), 7.0, True),
            ("attack", (4, 5), 8.0, False),
            ("hurt", (6,), 8.0, False),
            ("dead", (7,), 4.0, False),
        )
    else:
        clips = (
            ("idle", (0, 1), 4.0, True),
            ("move", (2, 3), 7.0, True),
            ("attack", (4, 5, 6, 7, 8, 9), 8.0, False),
            ("hurt", (10,), 8.0, False),
            ("dead", (11,), 4.0, False),
        )

    load_steps = len(regions) + 2
    lines = [
        f'[gd_resource type="SpriteFrames" load_steps={load_steps} format=3]',
        "",
        f'[ext_resource type="Texture2D" path="res://assets/survivor/enemies/{enemy_id}.png" id="1"]',
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
    (DEST / f"{enemy_id}.tres").write_text("\n".join(lines) + "\n", encoding="utf-8")
    return regions, [atlas.width, atlas.height]


def main() -> None:
    manifest_path = DEST / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8")) if manifest_path.exists() else {}

    for code, enemy_id, rows, tier, clear_holes in SPECS:
        src = source_path(code)
        frames = split_grid(Image.open(src), 4, rows, clear_holes=clear_holes)
        regions, atlas_size = build_enemy_atlas(enemy_id, frames, rows, tier)
        entry = manifest.get(enemy_id, {})
        entry["source"] = str((ARCHIVE / src.name).relative_to(ROOT))
        entry["atlas"] = f"assets/survivor/enemies/{enemy_id}.png"
        entry["atlas_size"] = atlas_size
        entry["regions"] = regions
        manifest[enemy_id] = entry
        print(f"[{code}] {enemy_id}: built {rows}x4 {tier} atlas {atlas_size[0]}x{atlas_size[1]}")

    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print("Updated", manifest_path.relative_to(ROOT))


if __name__ == "__main__":
    main()
