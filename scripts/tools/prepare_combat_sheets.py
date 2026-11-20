"""Extract the 10 Monkey Army combat & VFX sheets into assets/survivor/combat/ without modifying originals."""
import argparse
import hashlib
import io
import json
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/inbox"
DEST = ROOT / "assets/survivor/combat"

# Sheet definitions: id -> (glob_hint, frame_names_or_prefix, rows, kind, visual_note)
SHEETS = {
    3: (
        "archer-monkey",
        "archer",
        3,
        "character",
        "MODEL_MISMATCH: depicts yellow tunic + green belt monkey instead of shared red-bandana baby monkey; extracted for manifest audit, not used as runtime body to preserve ONE shared baby monkey model.",
    ),
    4: (
        "magic-monkey",
        "mage",
        3,
        "character",
        "Matches shared baby monkey model (red bandana, cream belly, brown fur); 3 casting variations (4 frames each).",
    ),
    5: (
        "defensive-combat",
        "tank",
        2,
        "character",
        "Matches shared baby monkey model; RGB source with light matte removed. Row 0 = guard/block, Row 1 = shield bash.",
    ),
    6: (
        "healing-animation",
        "healer",
        2,
        "character",
        "Matches shared baby monkey model; RGB source with light matte removed. 2 healing cast variations (4 frames each).",
    ),
    7: (
        "melee-slash-vfx",
        "slash",
        2,
        "vfx_sequence",
        "8-frame sequential golden crescent slash VFX (native RGBA).",
    ),
    8: (
        "arrow-combat-vfx",
        "arrow_release arrow_fly_00 arrow_fly_01 arrow_fly_02 arrow_spark arrow_burst arrow_shatter arrow_ground_dust",
        2,
        "vfx",
        "Modular arrow combat VFX (native RGBA with faint background veil cleaned).",
    ),
    9: (
        "magic-combat-vfx",
        "magic_charge_00 magic_charge_01 magic_orb_00 magic_orb_01 magic_impact_00 magic_impact_01 magic_impact_02 magic_impact_03",
        2,
        "vfx",
        "Advanced magic combat VFX: charge, flying orb, and 4-frame AoE detonation (native RGBA).",
    ),
    10: (
        "hit-feedback-vfx",
        "hit_light hit_spark hit_burst hit_heavy_crit dust_small dust_large hit_shards hit_sweep",
        2,
        "vfx",
        "Combat hit feedback & dust VFX (native RGBA with semi-transparent background veil removed).",
    ),
    11: (
        "boss-heavy-attack",
        "boss_telegraph_ring boss_slam_burst boss_shock_ring boss_rock_debris boss_rage_vortex boss_flame_wave boss_ground_crack boss_dust_billow",
        2,
        "vfx",
        "Advanced Boss heavy attack VFX (RGB source with baked checkerboard/light matte removed).",
    ),
    12: (
        "sequential-animation-sprite-sheet-for-the-sta",
        "staff",
        3,
        "character",
        "Matches shared baby monkey model; 3 melee staff attack variations (horizontal slash, overhead slam, thrust).",
    ),
}

ROW_CUTS = {
    6: [0, 443, 887],
    8: [0, 443, 887],
    9: [0, 443, 887],
    10: [0, 443, 887],
}

COLUMN_CUTS = {
    8: [[0, 444, 827, 1221, 1774], [0, 444, 887, 1330, 1774]],
    9: [[0, 444, 845, 1266, 1774], [0, 431, 767, 1314, 1774]],
    10: [[0, 423, 818, 1272, 1774], [0, 356, 836, 1261, 1774]],
}


def clean_cell(cell: Image.Image, source_mode: str, sheet: int, kind: str) -> tuple[Image.Image, tuple[int, int, int, int]]:
    pixels = np.array(cell).copy()
    alpha = pixels[:, :, 3]
    rgb = pixels[:, :, :3].astype(np.int16)
    chroma = np.ptp(rgb, axis=2)
    brightest = rgb.max(axis=2)
    darkest = rgb.min(axis=2)

    if source_mode == "RGBA":
        if sheet == 8:
            # Strip faint background alpha veil (<= 24) connected to border, preserve soft glow near opaque art.
            veil = alpha <= 28
            border = np.zeros(veil.shape, dtype=bool)
            border[[0, -1], :] = True
            border[:, [0, -1]] = True
            bg = ndimage.binary_propagation(border & veil, mask=veil)
            alpha[bg] = 0
            alpha[alpha < 14] = 0
        elif sheet == 10:
            # Sheet 010 has a wide semi-transparent gray/cream veil (alpha up to ~115) in empty space.
            veil = (alpha <= 125) & ((chroma < 72) | (alpha <= 45))
            border = np.zeros(veil.shape, dtype=bool)
            border[[0, -1], :] = True
            border[:, [0, -1]] = True
            bg = ndimage.binary_propagation(border & veil, mask=veil)
            alpha[bg] = 0
            # Softly clean any remaining faint gray veil fringe around sparks.
            fringe = (alpha > 0) & (alpha < 115) & (chroma < 65)
            alpha[fringe] = 0
        else:
            alpha[alpha < 12] = 0
    else:
        if kind == "character":
            # Clean white RGB background on 005 & 006: flood-fill border neutral bright pixels + smooth edge decontam.
            neutral = (chroma <= 14) & (darkest >= 225)
            border = np.zeros(neutral.shape, dtype=bool)
            border[[0, -1], :] = True
            border[:, [0, -1]] = True
            bg = ndimage.binary_propagation(border & neutral, mask=neutral)
            alpha[bg] = 0
            # Anti-aliased halo pixels adjacent to background
            edge = ndimage.binary_dilation(bg, iterations=2) & (~bg)
            edge_whiteness = np.clip((darkest[edge] - 180) / 72.0, 0.0, 1.0)
            edge_neutral = np.clip(1.0 - chroma[edge] / 36.0, 0.0, 1.0)
            halo = edge_whiteness * edge_neutral
            new_a = np.clip((1.0 - halo) * 255.0, 0, 255).astype(np.uint8)
            alpha[edge] = new_a
            # Decontaminate white from semi-transparent edge pixels
            a_f = np.maximum(alpha[edge].astype(np.float32)[:, None] / 255.0, 0.08)
            pixels[edge, :3] = np.clip((rgb[edge] - 254.0 * (1.0 - a_f)) / a_f, 0, 255).astype(np.uint8)
        else:
            # Sheet 011: Boss VFX on baked light gray/white checkerboard (lum >= 242, chroma <= 3).
            # Use chroma + darkness against matte to preserve glowing red/orange/gold flames and brown rocks.
            strength = np.maximum((chroma - 7) * 9.5, (238 - brightest) * 6.5)
            opacity = np.clip(strength, 0, 255)
            # Fill interior bright white flame cores that are enclosed by opaque fire/sparks.
            core = ndimage.binary_fill_holes(ndimage.binary_closing(opacity > 105, iterations=5))
            opacity[core & (brightest > 220) & (chroma <= 24)] = 252
            # Remove residual border-connected very faint specks from checkerboard.
            low = opacity < 18
            border = np.zeros(low.shape, dtype=bool)
            border[[0, -1], :] = True
            border[:, [0, -1]] = True
            opacity[ndimage.binary_propagation(border & low, mask=low)] = 0
            alpha[:] = opacity.astype(np.uint8)
            a_f = np.maximum(alpha.astype(np.float32)[:, :, None] / 255.0, 0.05)
            pixels[:, :, :3] = np.clip((rgb - 248.0 * (1.0 - a_f)) / a_f, 0, 255).astype(np.uint8)

    # Remove tiny isolated dust speckles.
    labels, _ = ndimage.label(alpha > 0, structure=np.ones((3, 3)))
    counts = np.bincount(labels.ravel())
    min_area = 12 if kind == "vfx_sequence" else 28
    alpha[(counts < min_area)[labels]] = 0
    pixels[:, :, 3] = alpha
    pixels[alpha == 0, :3] = 0

    result = Image.fromarray(pixels)
    bounds = result.getbbox()
    if bounds is None:
        raise ValueError(f"Empty extracted cell in sheet {sheet:03d}")
    return result.crop(bounds), bounds


def foot_anchor_x(sprite: Image.Image) -> float:
    a = np.array(sprite)[:, :, 3] > 64
    h, w = a.shape
    band_top = max(0, int(h * 0.86))
    ys, xs = np.nonzero(a[band_top:, :])
    if xs.size == 0:
        return w / 2.0
    return float(xs.mean())


def put(path: Path, data: bytes, check: bool) -> None:
    if check:
        if not path.exists() or path.read_bytes() != data:
            raise ValueError(f"File differs from expected build: {path.relative_to(ROOT)}")
    else:
        path.write_bytes(data)


def build(check: bool) -> None:
    if not check:
        DEST.mkdir(parents=True, exist_ok=True)
    manifest = {}
    for sheet, (hint, names_spec, rows, kind, visual_note) in SHEETS.items():
        matches = list(SOURCE.glob(f"{sheet:03d}-*{hint}*.png"))
        if len(matches) != 1:
            raise FileNotFoundError(f"Expected 1 source for sheet {sheet:03d} ({hint}), found {matches}")
        source = matches[0]
        original = Image.open(source)
        art = original.convert("RGBA")
        ys = ROW_CUTS.get(sheet, [round(i * art.height / rows) for i in range(rows + 1)])
        names = names_spec.split()
        if len(names) == 1:
            names = [f"{names[0]}_{i:02d}" for i in range(rows * 4)]

        # Pre-extract cells so vfx_sequence can share a registered canvas.
        extracted = []
        for idx, name in enumerate(names):
            row, col = divmod(idx, 4)
            default_cols = [round(i * art.width / 4) for i in range(5)]
            xs = COLUMN_CUTS.get(sheet, [default_cols] * rows)[row]
            box = (xs[col], ys[row], xs[col + 1], ys[row + 1])
            sprite, bounds = clean_cell(art.crop(box), original.mode, sheet, kind)
            extracted.append((idx, name, row, col, box, sprite, bounds))

        seq_canvas = None
        if kind == "vfx_sequence":
            max_w = max(b[2] - b[0] for *_, b in extracted)
            max_h = max(b[3] - b[1] for *_, b in extracted)
            seq_canvas = (max_w + 16, max_h + 16)

        frames = []
        for idx, name, row, col, box, sprite, bounds in extracted:
            x, y = box[0] + bounds[0], box[1] + bounds[1]
            native = [x, y, sprite.width, sprite.height]
            inset = 3
            if kind == "character":
                fx = foot_anchor_x(sprite)
                half = int(np.ceil(max(fx, sprite.width - fx))) + inset
                out_w = half * 2
                out_h = sprite.height + inset * 2
                canvas = Image.new("RGBA", (out_w, out_h))
                paste_x = half - round(fx)
                canvas.paste(sprite, (paste_x, inset))
                sprite = canvas
                pivot = [half, out_h - inset]
            elif kind == "vfx_sequence":
                cw, ch = seq_canvas
                # Preserve relative position within each cell around cell center so the slash sweeps naturally.
                cell_cx = (box[2] - box[0]) * 0.5
                cell_cy = (box[3] - box[1]) * 0.5
                rel_x = bounds[0] - cell_cx
                rel_y = bounds[1] - cell_cy
                canvas = Image.new("RGBA", (cw, ch))
                px = int(round(cw * 0.5 + rel_x))
                py = int(round(ch * 0.5 + rel_y))
                px = max(2, min(cw - sprite.width - 2, px))
                py = max(2, min(ch - sprite.height - 2, py))
                canvas.paste(sprite, (px, py))
                sprite = canvas
                pivot = [cw / 2.0, ch / 2.0]
            else:
                canvas = Image.new("RGBA", (sprite.width + inset * 2, sprite.height + inset * 2))
                canvas.paste(sprite, (inset, inset))
                sprite = canvas
                pivot = [sprite.width / 2.0, sprite.height / 2.0]

            alo, ahi = sprite.getchannel("A").getextrema()
            if alo != 0 or ahi < 120:
                raise ValueError(f"Unexpected alpha range in {name}: {alo}..{ahi}")

            buf = io.BytesIO()
            sprite.save(buf, format="PNG", optimize=True)
            put(DEST / f"{name}.png", buf.getvalue(), check)
            frames.append({
                "id": name,
                "cell": [col, row],
                "source_rect": native,
                "size": list(sprite.size),
                "pivot": pivot,
                "alpha_range": [alo, ahi],
                "integrated": sheet != 3,
            })

        bg_desc = (
            "native RGBA cleaned"
            if original.mode == "RGBA"
            else ("white matte flood-removed + edge decontaminated" if kind == "character" else "checkerboard light matte keyed")
        )
        manifest[f"{sheet:03d}"] = {
            "source": source.relative_to(ROOT).as_posix(),
            "sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
            "source_size": list(original.size),
            "source_mode": original.mode,
            "kind": kind,
            "background": bg_desc,
            "visual_consistency": visual_note,
            "integrated": sheet != 3,
            "frames": frames,
        }

    serialized = (json.dumps(manifest, indent=2) + "\n").encode()
    put(DEST / "manifest.json", serialized, check)
    total = sum(len(s["frames"]) for s in manifest.values())
    print(f"{'PASS: Verified' if check else 'Built'} {len(manifest)} combat sheets, {total} RGBA sprites -> {DEST.relative_to(ROOT)}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="verify extracted PNGs and manifest without writing")
    build(parser.parse_args().check)
