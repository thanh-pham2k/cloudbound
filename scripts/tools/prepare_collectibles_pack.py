"""Extract the 7 Base Asset Cheatsheet Collectibles & Items sheets (001..007, 3x2 each) into assets/survivor/."""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

from prepare_base_cheatsheet_pack import split_grid

ROOT = Path(__file__).resolve().parents[2]
INBOX = ROOT / "assets/inbox"
ARCHIVE = ROOT / "assets/archive/adapted/survivor/collectibles_cheatsheet_v1"
SURVIVOR = ROOT / "assets/survivor"
COLLECTIBLES = SURVIVOR / "collectibles"


def source_path(prefix: str) -> Path:
    for folder in (INBOX, ARCHIVE):
        matches = sorted(folder.glob(f"{prefix}-*.png"))
        if matches:
            return matches[0]
    raise FileNotFoundError(f"Missing collectible source sheet {prefix}")


def sync_all_manifests() -> None:
    # 1. assets/survivor/manifest.json (source_rect)
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

    # 2. summon & polish manifests (size)
    counts = {"base": base_updated}
    for sub in ("summon", "polish"):
        mp = SURVIVOR / sub / "manifest.json"
        if not mp.exists():
            continue
        data = json.loads(mp.read_text(encoding="utf-8"))
        updated = 0

        def walk(obj):
            nonlocal updated
            if isinstance(obj, dict):
                for k, v in obj.items():
                    if isinstance(v, dict) and "size" in v and isinstance(v["size"], list) and len(v["size"]) == 2:
                        for name in (v.get("name"), v.get("id"), k):
                            if isinstance(name, str):
                                fp = SURVIVOR / sub / (name if name.endswith(".png") else f"{name}.png")
                                if fp.exists():
                                    w, h = Image.open(fp).size
                                    if v["size"] != [w, h]:
                                        v["size"] = [w, h]
                                        updated += 1
                                    break
                    walk(v)
            elif isinstance(obj, list):
                for item in obj:
                    if isinstance(item, dict) and "size" in item and isinstance(item["size"], list) and len(item["size"]) == 2:
                        name = item.get("name") or item.get("id")
                        if isinstance(name, str):
                            fp = SURVIVOR / sub / (name if name.endswith(".png") else f"{name}.png")
                            if fp.exists():
                                w, h = Image.open(fp).size
                                if item["size"] != [w, h]:
                                    item["size"] = [w, h]
                                    updated += 1
                    walk(item)

        walk(data)
        mp.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
        counts[sub] = updated
    print("Synced manifests:", counts)


def main() -> None:
    COLLECTIBLES.mkdir(parents=True, exist_ok=True)
    # (code, item_id, index -> runtime target paths)
    specs = [
        ("001", "gold", {
            0: ["gold.png", "gold_icon.png", "polish/shop_coin.png", "summon/purchase_gold.png"],
            3: ["polish/gold_drop.png"],
            4: ["polish/gold_trail.png"],
            5: ["polish/gold_collect.png"],
        }),
        ("002", "gold_stack", {
            1: ["gold_stack.png"],
        }),
        ("003", "peach", {
            0: ["peach.png"],
        }),
        ("004", "crystal", {
            0: ["crystal.png"],
        }),
        ("005", "chest", {
            0: ["chest.png", "polish/shop_chest.png"],
        }),
        ("006", "heart", {
            0: ["heart.png"],
        }),
        ("007", "xp", {
            0: ["xp.png"],
            1: ["xp_large.png"],
            3: ["polish/xp_drop.png"],
            4: ["polish/xp_trail.png"],
            5: ["polish/xp_collect.png"],
        }),
    ]

    manifest: dict[str, dict] = {}
    for code, item_id, mapping in specs:
        src = source_path(code)
        cells = split_grid(Image.open(src), 3, 2, clear_holes=False)
        saved_all = []
        for idx, cell in enumerate(cells):
            out = COLLECTIBLES / f"{item_id}_{idx:02d}.png"
            cell.save(out)
            saved_all.append(str(out.relative_to(ROOT)))
            for rel in mapping.get(idx, []):
                cell.save(SURVIVOR / rel)
        manifest[code] = {
            "item": item_id,
            "source": str((ARCHIVE / src.name).relative_to(ROOT)),
            "frames": saved_all,
            "runtime_targets": [p for paths in mapping.values() for p in paths],
        }
        print(f"[{code}] {item_id}: extracted 6 frames + {len(manifest[code]['runtime_targets'])} runtime targets")

    (COLLECTIBLES / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    sync_all_manifests()


if __name__ == "__main__":
    main()
