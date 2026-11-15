#!/usr/bin/env python3
"""Generate stylized placeholder sprite frames and run them through gameforge-kit's
normalizer, atlas packer, structural validator, and Godot 4 SpriteFrames exporter.
"""

from __future__ import annotations

import math
import sys
from pathlib import Path
from PIL import Image, ImageDraw

PROJECT_ROOT = Path(__file__).resolve().parents[2]
TOOLKIT_SPRITES = PROJECT_ROOT / "tools" / "gameforge-kit" / "scripts" / "sprites"
sys.path.insert(0, str(TOOLKIT_SPRITES))

from atlas_packer import pack_task_atlas  # noqa: E402
from batch_planner import create_batch_manifest  # noqa: E402
from frame_normalizer import normalize_task  # noqa: E402
from godot_exporter import export_godot_spriteframes  # noqa: E402
from sprite_common import save_json  # noqa: E402
from validators import validate_atlas_structure  # noqa: E402

CHARACTERS = {
    "player_hero": {
        "body": (72, 180, 235, 255),
        "trim": (250, 210, 90, 255),
        "weapon": (180, 245, 255, 255),
        "scale": 1.0,
    },
    "enemy_melee": {
        "body": (220, 75, 95, 255),
        "trim": (90, 30, 50, 255),
        "weapon": (255, 160, 120, 255),
        "scale": 0.92,
    },
    "enemy_ranged": {
        "body": (120, 95, 225, 255),
        "trim": (55, 210, 200, 255),
        "weapon": (170, 240, 255, 255),
        "scale": 0.92,
    },
    "enemy_tank": {
        "body": (130, 140, 155, 255),
        "trim": (225, 165, 70, 255),
        "weapon": (200, 205, 215, 255),
        "scale": 1.2,
    },
    "boss_thunder_warden": {
        "body": (105, 55, 175, 255),
        "trim": (255, 215, 75, 255),
        "weapon": (125, 235, 255, 255),
        "scale": 1.38,
    },
}


def draw_character_frame(
    char_id: str,
    anim: str,
    direction: str,
    frame_idx: int,
    total_frames: int,
    size: tuple[int, int] = (128, 128),
) -> Image.Image:
    cfg = CHARACTERS[char_id]
    w, h = size
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    t = frame_idx / max(total_frames, 1)
    phase = t * math.tau
    s = cfg["scale"]

    cx = w // 2
    foot_y = 112

    bob = 0.0
    lean_x = 0.0
    squash = 1.0
    alpha_mul = 1.0
    tint_hurt = False
    weapon_swing = 0.0

    if anim == "idle":
        bob = math.sin(phase) * 2.5 + math.cos(phase) * 1.2
        lean_x = math.cos(phase) * 0.8
    elif anim == "walk":
        bob = abs(math.sin(phase)) * -5.0 - (frame_idx % 2) * 1.0
        lean_x = math.sin(phase) * 3.5 + math.cos(phase) * 1.5
    elif anim == "attack":
        swing_t = math.sin(t * math.pi + 0.25)
        lean_x = swing_t * (8.0 if direction == "right" else 2.0) + frame_idx * 0.8
        bob = -swing_t * 3.0
        weapon_swing = swing_t + frame_idx * 0.15
    elif anim == "hurt":
        tint_hurt = True
        lean_x = -4.0 if frame_idx == 0 else 2.0
    elif anim == "death":
        squash = max(0.25, 1.0 - t * 0.75)
        alpha_mul = max(0.2, 1.0 - t * 0.75)
        bob = t * 14.0

    body_col = (255, 90, 90, 255) if tint_hurt else cfg["body"]
    trim_col = (255, 200, 200, 255) if tint_hurt else cfg["trim"]
    weapon_col = cfg["weapon"]

    def apply_alpha(col: tuple[int, int, int, int]) -> tuple[int, int, int, int]:
        return (col[0], col[1], col[2], int(col[3] * alpha_mul))

    # Ground shadow
    sh_rx = int(20 * s)
    sh_ry = int(7 * s)
    draw.ellipse(
        [cx - sh_rx, foot_y - sh_ry, cx + sh_rx, foot_y + sh_ry],
        fill=(15, 23, 42, int(90 * alpha_mul)),
    )

    body_w = int(26 * s)
    body_h = int(42 * s * squash)
    head_r = int(13 * s * squash)

    bx = int(cx + lean_x)
    by_bottom = int(foot_y - 4 + bob)
    by_top = by_bottom - body_h

    # Cape / aura for boss or hero
    if char_id in ("boss_thunder_warden", "player_hero"):
        aura_r = int(28 * s)
        draw.ellipse(
            [bx - aura_r, by_top - 4, bx + aura_r, by_bottom + 2],
            outline=apply_alpha((trim_col[0], trim_col[1], trim_col[2], 140)),
            width=2,
        )

    # Torso
    draw.rounded_rectangle(
        [bx - body_w // 2, by_top, bx + body_w // 2, by_bottom],
        radius=max(4, int(8 * s)),
        fill=apply_alpha(body_col),
        outline=apply_alpha((15, 23, 42, 220)),
        width=2,
    )

    # Trim / sash
    draw.rectangle(
        [bx - body_w // 2 + 2, by_top + body_h // 2 - 3, bx + body_w // 2 - 2, by_top + body_h // 2 + 4],
        fill=apply_alpha(trim_col),
    )

    # Head
    hy = by_top - head_r + 2
    draw.ellipse(
        [bx - head_r, hy - head_r, bx + head_r, hy + head_r],
        fill=apply_alpha(body_col),
        outline=apply_alpha((15, 23, 42, 220)),
        width=2,
    )

    # Crown / horns for boss, headband for hero
    if char_id == "boss_thunder_warden":
        draw.polygon(
            [(bx - 12, hy - head_r + 2), (bx - 18, hy - head_r - 12), (bx - 4, hy - head_r)],
            fill=apply_alpha(trim_col),
        )
        draw.polygon(
            [(bx + 12, hy - head_r + 2), (bx + 18, hy - head_r - 12), (bx + 4, hy - head_r)],
            fill=apply_alpha(trim_col),
        )

    # Eyes (except when facing up)
    if direction != "up":
        eye_dx = 5 if direction == "right" else 0
        eye_y = hy + 1
        draw.ellipse([bx - 5 + eye_dx, eye_y - 2, bx - 1 + eye_dx, eye_y + 2], fill=apply_alpha((255, 255, 255, 255)))
        draw.ellipse([bx + 2 + eye_dx, eye_y - 2, bx + 6 + eye_dx, eye_y + 2], fill=apply_alpha((255, 255, 255, 255)))

    # Weapon / attack arc
    wx = bx + (int(16 * s) if direction != "up" else int(12 * s))
    wy = by_top + body_h // 3
    if direction == "down":
        angle = 0.6 + weapon_swing * 1.4
    elif direction == "right":
        angle = -0.3 + weapon_swing * 1.3
    else:
        angle = -1.6 - weapon_swing * 1.1

    w_len = int((28 if char_id == "boss_thunder_warden" else 20) * s)
    wx2 = int(wx + math.cos(angle) * w_len)
    wy2 = int(wy + math.sin(angle) * w_len)
    draw.line([wx, wy, wx2, wy2], fill=apply_alpha(weapon_col), width=max(3, int(4 * s)))

    if anim == "attack" and weapon_swing > 0.35:
        arc_r = int(26 * s)
        draw.arc(
            [bx - arc_r, by_top - 6, bx + arc_r, by_bottom],
            start=-40 if direction == "right" else 20,
            end=80 if direction == "right" else 160,
            fill=apply_alpha(weapon_col),
            width=3,
        )

    return img


def main() -> int:
    profile_path = Path("profiles/cloudbound_isometric.json")
    for char_id in CHARACTERS:
        manifest = create_batch_manifest(
            profile_path=profile_path,
            character_id=char_id,
            adapter="placeholder",
            project_root=PROJECT_ROOT,
            output_dir="assets/generated",
            work_dir=".gameforge/work",
        )
        # Put Godot output in deterministic per-character folder without hash
        manifest["godot_output_dir"] = str(PROJECT_ROOT / "assets" / "generated" / "sprites" / char_id)

        for task in manifest["tasks"]:
            for idx, job in enumerate(task["frames"]):
                src_path = Path(job["source_path"])
                src_path.parent.mkdir(parents=True, exist_ok=True)
                frame_img = draw_character_frame(
                    char_id=char_id,
                    anim=task["animation"],
                    direction=task["direction"],
                    frame_idx=idx,
                    total_frames=int(task["frame_count"]),
                )
                frame_img.save(src_path)
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
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
