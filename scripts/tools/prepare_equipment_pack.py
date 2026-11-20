"""Extract the 2 Base Asset Cheatsheet Weapons & Equipment sheets (001..002) into assets/survivor/."""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

from prepare_base_cheatsheet_pack import split_grid

ROOT = Path(__file__).resolve().parents[2]
INBOX = ROOT / "assets/inbox"
ARCHIVE = ROOT / "assets/archive/adapted/survivor/equipment_cheatsheet_v1"
SURVIVOR = ROOT / "assets/survivor"


def source_path(prefix: str) -> Path:
    for folder in (INBOX, ARCHIVE):
        matches = sorted(folder.glob(f"{prefix}-*.png"))
        if matches:
            return matches[0]
    raise FileNotFoundError(f"Missing equipment source sheet {prefix}")


def sync_manifests() -> None:
    # Sync assets/survivor/manifest.json (source_rect)
    base_mp = SURVIVOR / "manifest.json"
    base_data = json.loads(base_mp.read_text(encoding="utf-8"))
    base_updated = 0
    for sheet in base_data.values():
        for frame in sheet.get("frames", []):
            fp = SURVIVOR / (frame["name"] + ".png")
            if fp.exists() and "source_rect" in frame:
                w, h = Image.open(fp).size
                if frame["source_rect"][2] != w or frame["source_rect"][3] != h:
                    frame["source_rect"][2] = w
                    frame["source_rect"][3] = h
                    base_updated += 1
    base_mp.write_text(json.dumps(base_data, indent=2) + "\n", encoding="utf-8")

    # Sync assets/survivor/summon/manifest.json (size)
    sum_mp = SURVIVOR / "summon/manifest.json"
    sum_data = json.loads(sum_mp.read_text(encoding="utf-8"))
    sum_updated = 0
    for sheet in sum_data.values():
        for frame in sheet.get("frames", []):
            name = frame.get("name") or frame.get("id")
            if not name:
                continue
            fp = SURVIVOR / "summon" / (name if name.endswith(".png") else f"{name}.png")
            if fp.exists() and "size" in frame:
                w, h = Image.open(fp).size
                if frame["size"] != [w, h]:
                    frame["size"] = [w, h]
                    sum_updated += 1
    sum_mp.write_text(json.dumps(sum_data, indent=2) + "\n", encoding="utf-8")
    print(f"Synced manifests: base={base_updated}, summon={sum_updated}")


def main() -> None:
    # Sheet 001: Core Weapons & Role Staves (4x2)
    src1 = source_path("001")
    img1 = Image.open(src1)
    cells1 = split_grid(img1, 4, 2, clear_holes=False)
    cells1_holes = split_grid(img1, 4, 2, clear_holes=True)
    cells1[1] = cells1_holes[1]  # bow interior gap

    targets1 = [
        ["sword.png"],
        ["bow.png", "summon/bow.png"],
        ["staff.png"],
        ["spear.png"],
        ["shield.png", "summon/shield.png"],
        ["rune.png"],
        ["hero_staff.png", "summon/staff.png"],
        ["summon/healer_staff.png"],
    ]
    for cell, rels in zip(cells1, targets1):
        for rel in rels:
            cell.save(SURVIVOR / rel)
    print(f"[001] core weapons: extracted {sum(len(r) for r in targets1)} files")

    # Sheet 002: Elite & Upgrade Shop Equipment (4x2)
    src2 = source_path("002")
    img2 = Image.open(src2)
    cells2 = split_grid(img2, 4, 2, clear_holes=False)
    cells2_holes = split_grid(img2, 4, 2, clear_holes=True)
    for idx in (1, 5, 7):  # elite_bow, beads center, horn cord gap
        cells2[idx] = cells2_holes[idx]

    targets2 = [
        ["summon/elite_staff.png"],
        ["summon/elite_bow.png"],
        ["summon/elite_shield.png"],
        ["summon/mage_staff.png"],
        ["summon/armor.png"],
        ["summon/beads.png"],
        ["summon/medicine.png"],
        ["summon/horn.png"],
    ]
    for cell, rels in zip(cells2, targets2):
        for rel in rels:
            cell.save(SURVIVOR / rel)
    print(f"[002] elite equipment: extracted {sum(len(r) for r in targets2)} files")

    sync_manifests()


if __name__ == "__main__":
    main()
