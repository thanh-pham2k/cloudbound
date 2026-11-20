#!/usr/bin/env python3
"""Extract Purple Slime (4x2), Wild Boar (4x2), and Portrait Icons (3x2)
from assets/inbox/ into assets/survivor/ and assets/survivor/summon/,
and sync all manifests.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "tools"))

from prepare_base_cheatsheet_pack import split_grid as _split_grid_img
from prepare_summon_ui_pack import sync_all_manifests

INBOX = ROOT / "assets" / "inbox"
OUT_BASE = ROOT / "assets" / "survivor"
OUT_SUMMON = OUT_BASE / "summon"
OUT_PACK = OUT_BASE / "slime_boar_portraits_cheatsheet"


def split_grid(path: Path, cols: int, rows: int, **kwargs) -> list[Image.Image]:
    with Image.open(path) as im:
        return _split_grid_img(im.convert("RGBA"), cols, rows, **kwargs)


def main() -> None:
    OUT_PACK.mkdir(parents=True, exist_ok=True)
    rows: list[dict] = []

    # 1. Purple Slime (4x2)
    src_slime = "001-create-a-clean-2d-game-character-animation-sprite-sheet-arra.png"
    for idx, img in enumerate(split_grid(INBOX / src_slime, 4, 2, clear_holes=False)):
        pack_p = OUT_PACK / f"slime_{idx:02d}.png"
        target = OUT_BASE / f"slime_{idx:02d}.png"
        img.save(pack_p)
        img.save(target)
        rows.append({"key": f"slime_{idx:02d}", "source": src_slime, "size": [img.width, img.height], "target": str(target.relative_to(ROOT))})

    # 2. Wild Boar (4x2)
    src_boar = "002-create-a-clean-2d-game-character-animation-sprite-sheet-arra.png"
    for idx, img in enumerate(split_grid(INBOX / src_boar, 4, 2, clear_holes=False)):
        pack_p = OUT_PACK / f"boar_{idx:02d}.png"
        target = OUT_BASE / f"boar_{idx:02d}.png"
        img.save(pack_p)
        img.save(target)
        rows.append({"key": f"boar_{idx:02d}", "source": src_boar, "size": [img.width, img.height], "target": str(target.relative_to(ROOT))})

    # 3. Portrait Icons (3x2)
    src_portraits = "003-create-a-clean-2d-game-character-portrait-icon-sheet-arrange.png"
    portrait_names = [
        "portrait_staff",
        "portrait_archer",
        "portrait_mage",
        "portrait_tank",
        "portrait_healer",
        "portrait_elite",
    ]
    for name, img in zip(portrait_names, split_grid(INBOX / src_portraits, 3, 2, clear_holes=False)):
        pack_p = OUT_PACK / f"{name}.png"
        target = OUT_SUMMON / f"{name}.png"
        img.save(pack_p)
        img.save(target)
        rows.append({"key": name, "source": src_portraits, "size": [img.width, img.height], "target": str(target.relative_to(ROOT))})

    (OUT_PACK / "manifest.json").write_text(
        json.dumps({"pack": "slime_boar_portraits_cheatsheet_v1", "count": len(rows), "items": rows}, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"Extracted {len(rows)} assets (8 slime + 8 boar + 6 portraits)")
    sync_all_manifests()


if __name__ == "__main__":
    main()
