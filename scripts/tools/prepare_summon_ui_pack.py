#!/usr/bin/env python3
"""Extract and adapt the 12 Summon / UI / HUD / Upgrade / Support / Monkey Ally
sheets from assets/inbox/ into assets/survivor/, summon/, polish/, and vfx/,
and sync all manifest dimensions.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "tools"))

from prepare_base_cheatsheet_pack import split_grid as _split_grid_img
from prepare_vfx_cheatsheet_pack import split_vfx_grid as _split_vfx_grid_img


def split_grid(path: Path, cols: int, rows: int, **kwargs) -> list[Image.Image]:
    with Image.open(path) as im:
        return _split_grid_img(im.convert("RGBA"), cols, rows, **kwargs)


def split_vfx_grid(path: Path, cols: int, rows: int, **kwargs) -> list[Image.Image]:
    with Image.open(path) as im:
        return _split_vfx_grid_img(im.convert("RGBA"), cols, rows, **kwargs)

INBOX = ROOT / "assets" / "inbox"
OUT_BASE = ROOT / "assets" / "survivor"
OUT_SUMMON = OUT_BASE / "summon"
OUT_POLISH = OUT_BASE / "polish"
OUT_VFX = OUT_BASE / "vfx"
OUT_PACK = OUT_BASE / "summon_ui_cheatsheet"


def _save_targets(img: Image.Image, targets: list[Path], manifest_rows: list[dict], key: str, source: str) -> None:
    OUT_PACK.mkdir(parents=True, exist_ok=True)
    pack_path = OUT_PACK / f"{key}.png"
    img.save(pack_path)
    saved_rel = []
    for target in targets:
        target.parent.mkdir(parents=True, exist_ok=True)
        img.save(target)
        saved_rel.append(str(target.relative_to(ROOT)))
    manifest_rows.append(
        {
            "key": key,
            "source": source,
            "pack_file": str(pack_path.relative_to(ROOT)),
            "size": [img.width, img.height],
            "targets": saved_rel,
        }
    )


def sync_all_manifests() -> None:
    # 1) assets/survivor/manifest.json (sheets dict -> frames list with source_rect)
    base_manifest = OUT_BASE / "manifest.json"
    counts: dict[str, int] = {}
    if base_manifest.exists():
        base_data = json.loads(base_manifest.read_text(encoding="utf-8"))
        base_updated = 0
        for sheet in base_data.values():
            if not isinstance(sheet, dict):
                continue
            for frame in sheet.get("frames", []):
                if not isinstance(frame, dict) or "name" not in frame or "source_rect" not in frame:
                    continue
                fp = OUT_BASE / f"{frame['name']}.png"
                if fp.exists():
                    with Image.open(fp) as im:
                        w, h = im.size
                    if frame["source_rect"][2] != w or frame["source_rect"][3] != h:
                        frame["source_rect"][2] = w
                        frame["source_rect"][3] = h
                        base_updated += 1
        base_manifest.write_text(json.dumps(base_data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        counts["base"] = base_updated

    # 2) sub-manifests using recursive size sync
    for sub in ("summon", "polish", "combat", "vfx"):
        mpath = OUT_BASE / sub / "manifest.json"
        if not mpath.exists():
            continue
        data = json.loads(mpath.read_text(encoding="utf-8"))
        updated = 0

        def walk(obj) -> None:
            nonlocal updated
            if isinstance(obj, dict):
                for k, v in obj.items():
                    if isinstance(v, dict) and "size" in v and isinstance(v["size"], list) and len(v["size"]) == 2:
                        for name in (v.get("name"), v.get("id"), k):
                            if isinstance(name, str):
                                fp = OUT_BASE / sub / (name if name.endswith(".png") else f"{name}.png")
                                if fp.exists():
                                    with Image.open(fp) as im:
                                        w, h = im.size
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
                            fp = OUT_BASE / sub / (name if name.endswith(".png") else f"{name}.png")
                            if fp.exists():
                                with Image.open(fp) as im:
                                    w, h = im.size
                                if item["size"] != [w, h]:
                                    item["size"] = [w, h]
                                    updated += 1
                    walk(item)

        walk(data)
        mpath.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        counts[sub] = updated
    print("Synced manifests:", counts)


def main() -> None:
    manifest_rows: list[dict] = []

    # 1. Summon UI Feedback VFX (3x2, glowing VFX)
    src = "001-create-a-clean-2d-game-summon-ui-feedback-vfx-sprite-sheet-a.png"
    cells = split_vfx_grid(INBOX / src, 3, 2, outlined=False)
    mapping_1 = [
        ("ui_fx_ring_idle", [OUT_SUMMON / "selection_glow.png", OUT_POLISH / "rally_ring.png"]),
        ("ui_fx_ring_pulse", [OUT_SUMMON / "purchase_flash.png", OUT_POLISH / "reward_flash.png"]),
        ("ui_fx_column_beam", [OUT_POLISH / "rally_beam.png", OUT_VFX / "dust_summon_beam.png"]),
        ("ui_fx_column_burst", [OUT_SUMMON / "redeploy.png", OUT_POLISH / "reinforcement.png"]),
        ("ui_fx_purchase_success", [OUT_SUMMON / "purchase_success.png", OUT_POLISH / "shop_success.png"]),
        ("ui_fx_upgrade_chevrons", [OUT_POLISH / "shop_upgrade.png", OUT_POLISH / "level_beam.png"]),
    ]
    for img, (key, targets) in zip(cells, mapping_1):
        _save_targets(img, targets, manifest_rows, key, src)

    # 2. UI Frames (3x2, outlined UI)
    src = "002-create-a-clean-2d-game-ui-frame-sprite-sheet-arranged-in-a-s.png"
    cells = split_grid(INBOX / src, 3, 2, clear_holes=False)
    mapping_2 = [
        ("ui_frame_locked", [OUT_BASE / "card_locked.png", OUT_SUMMON / "card_disabled.png", OUT_POLISH / "shop_locked.png", OUT_POLISH / "shop_closed.png"]),
        ("ui_frame_hover", [OUT_SUMMON / "card_hover.png", OUT_SUMMON / "card_rare.png", OUT_POLISH / "shop_card.png"]),
        ("ui_frame_active", [OUT_BASE / "card_active.png", OUT_SUMMON / "card_selected.png", OUT_SUMMON / "card_legend.png"]),
        ("ui_frame_tab", [OUT_SUMMON / "shop_tab_active.png", OUT_SUMMON / "shop_tab.png"]),
        ("ui_frame_plate", [OUT_BASE / "price.png", OUT_SUMMON / "price_plate.png", OUT_SUMMON / "capacity_plate.png", OUT_SUMMON / "tier_button.png"]),
        ("ui_frame_disabled_btn", [OUT_BASE / "buy_disabled.png", OUT_POLISH / "shop_low_gold.png"]),
    ]
    for img, (key, targets) in zip(cells, mapping_2):
        _save_targets(img, targets, manifest_rows, key, src)

    # 3. HUD Icon Mini Frame (3x2, outlined HUD)
    src = "003-create-a-clean-2d-game-hud-icon-mini-frame-sprite-sheet-arra.png"
    cells = split_grid(INBOX / src, 3, 2, clear_holes=False)
    mapping_3 = [
        ("hud_army_icon", [OUT_BASE / "army_icon.png", OUT_SUMMON / "status_army.png", OUT_POLISH / "stand_together.png"]),
        ("hud_monkey_badge", [OUT_SUMMON / "portrait_plain.png", OUT_SUMMON / "portrait_ready.png"]),
        ("hud_boss_alert", [OUT_BASE / "boss_alert.png", OUT_POLISH / "warning_boss.png", OUT_VFX / "boss_danger_alert.png"]),
        ("hud_pause_icon", [OUT_BASE / "pause_icon.png"]),
        ("hud_xp_frame", [OUT_BASE / "xp_frame.png"]),
        ("hud_level_badge", [OUT_BASE / "level_badge.png"]),
    ]
    for img, (key, targets) in zip(cells, mapping_3):
        _save_targets(img, targets, manifest_rows, key, src)

    # 4. UI Buttons (3x2, outlined UI)
    src = "004-create-a-clean-2d-game-ui-button-sprite-sheet-arranged-in-a-.png"
    cells = split_grid(INBOX / src, 3, 2, clear_holes=False)
    mapping_4 = [
        ("btn_play", [OUT_BASE / "play.png", OUT_BASE / "start_icon.png"]),
        ("btn_refresh", [OUT_BASE / "restart.png", OUT_BASE / "refresh.png", OUT_SUMMON / "reroll_badge.png", OUT_POLISH / "shop_refresh.png"]),
        ("btn_home", [OUT_BASE / "home.png"]),
        ("btn_settings", [OUT_BASE / "settings.png", OUT_BASE / "settings_icon.png", OUT_SUMMON / "info_button.png"]),
        ("btn_confirm", [OUT_BASE / "confirm.png", OUT_SUMMON / "confirm_badge.png", OUT_POLISH / "shop_confirm.png"]),
        ("btn_cancel", [OUT_BASE / "cancel.png", OUT_SUMMON / "close_badge.png", OUT_SUMMON / "rejected.png"]),
    ]
    for img, (key, targets) in zip(cells, mapping_4):
        _save_targets(img, targets, manifest_rows, key, src)

    # 5. UI Banners (2x2, outlined UI)
    src = "005-create-a-clean-2d-game-ui-banner-sprite-sheet-arranged-in-a-.png"
    cells = split_grid(INBOX / src, 2, 2, clear_holes=False)
    mapping_5 = [
        ("banner_title", [OUT_BASE / "title.png"]),
        ("banner_pause", [OUT_BASE / "pause_banner.png"]),
        ("banner_shop", [OUT_BASE / "shop_banner.png"]),
        ("banner_tray", [OUT_SUMMON / "tray.png"]),
    ]
    for img, (key, targets) in zip(cells, mapping_5):
        _save_targets(img, targets, manifest_rows, key, src)

    # 6. UI Overlay Celebration & Defeat FX (3x2, glowing VFX)
    src = "006-create-a-clean-2d-game-ui-overlay-celebration-defeat-fx-spri.png"
    cells = split_vfx_grid(INBOX / src, 3, 2, outlined=False)
    mapping_6 = [
        ("overlay_victory_flare", [OUT_POLISH / "victory_burst.png", OUT_POLISH / "victory_flare.png"]),
        ("overlay_victory_petals", [OUT_POLISH / "victory_petals.png", OUT_POLISH / "blossom.png"]),
        ("overlay_victory_spark", [OUT_POLISH / "victory_spark.png", OUT_POLISH / "level_glint.png"]),
        ("overlay_defeat_break", [OUT_POLISH / "defeat_break.png", OUT_POLISH / "defeat_beam.png"]),
        ("overlay_defeat_smoke", [OUT_POLISH / "defeat_smoke.png"]),
        ("overlay_defeat_petals", [OUT_POLISH / "defeat_petals.png"]),
    ]
    for img, (key, targets) in zip(cells, mapping_6):
        _save_targets(img, targets, manifest_rows, key, src)

    # 7. Summon VFX (3x2, glowing golden VFX)
    src = "001-create-a-clean-2d-game-summon-vfx-sprite-sheet-arranged-in-a.png"
    cells = split_vfx_grid(INBOX / src, 3, 2, outlined=False)
    mapping_7 = [
        ("summon_vfx_ring_idle", [OUT_BASE / "summon.png", OUT_POLISH / "summon_00.png", OUT_POLISH / "arrival_00.png"]),
        ("summon_vfx_ring_active", [OUT_SUMMON / "summon_ring.png", OUT_POLISH / "summon_01.png", OUT_POLISH / "arrival_01.png"]),
        ("summon_vfx_ring_burst", [OUT_BASE / "spawn.png", OUT_POLISH / "summon_02.png", OUT_POLISH / "summon_03.png", OUT_POLISH / "arrival_02.png", OUT_POLISH / "arrival_03.png"]),
        ("summon_vfx_beam_thin", [OUT_POLISH / "summon_04.png", OUT_POLISH / "arrival_04.png"]),
        ("summon_vfx_beam_full", [OUT_SUMMON / "summon_column.png", OUT_POLISH / "summon_05.png", OUT_POLISH / "summon_06.png", OUT_POLISH / "arrival_05.png", OUT_POLISH / "arrival_06.png"]),
        ("summon_vfx_dissipate", [OUT_POLISH / "summon_07.png", OUT_POLISH / "arrival_07.png"]),
    ]
    for img, (key, targets) in zip(cells, mapping_7):
        _save_targets(img, targets, manifest_rows, key, src)

    # 8. Upgrade / Level-Up VFX (3x2, glowing golden VFX)
    src = "002-create-a-clean-2d-game-upgrade-level-up-vfx-sprite-sheet-arr.png"
    cells = split_vfx_grid(INBOX / src, 3, 2, outlined=False)
    mapping_8 = [
        ("upgrade_vfx_level", [OUT_BASE / "upgrade.png", OUT_SUMMON / "upgrade_level.png"]),
        ("upgrade_vfx_burst", [OUT_SUMMON / "upgrade_burst.png", OUT_POLISH / "command_spark.png"]),
        ("upgrade_vfx_spiral", [OUT_SUMMON / "upgrade_spiral.png"]),
        ("upgrade_vfx_spark", [OUT_SUMMON / "upgrade_spark.png"]),
        ("upgrade_vfx_evolve", [OUT_SUMMON / "upgrade_evolve.png"]),
        ("upgrade_vfx_confirm", [OUT_SUMMON / "upgrade_confirm.png"]),
    ]
    for img, (key, targets) in zip(cells, mapping_8):
        _save_targets(img, targets, manifest_rows, key, src)

    # 9. UI Upgrade Badge Icons (3x2, outlined icons)
    src = "003-create-a-clean-2d-game-ui-upgrade-badge-icon-sheet-arranged-.png"
    cells = split_grid(INBOX / src, 3, 2, clear_holes=False)
    mapping_9 = [
        ("badge_upgrade_attack", [OUT_SUMMON / "upgrade_attack.png", OUT_SUMMON / "status_damage.png"]),
        ("badge_upgrade_defense", [OUT_SUMMON / "upgrade_defense.png", OUT_SUMMON / "status_defense.png"]),
        ("badge_upgrade_speed", [OUT_SUMMON / "upgrade_speed.png", OUT_SUMMON / "status_speed.png"]),
        ("badge_upgrade_heal", [OUT_SUMMON / "upgrade_heal.png"]),
        ("badge_upgrade_hp", [OUT_SUMMON / "status_hp.png"]),
        ("badge_upgrade_forge", [OUT_SUMMON / "status_upgrade.png", OUT_POLISH / "shop_equip.png"]),
    ]
    for img, (key, targets) in zip(cells, mapping_9):
        _save_targets(img, targets, manifest_rows, key, src)

    # 10. Support & Buff VFX (3x2, glowing VFX)
    src = "004-create-a-clean-2d-game-support-buff-vfx-sprite-sheet-arrange.png"
    cells = split_vfx_grid(INBOX / src, 3, 2, outlined=False)
    mapping_10 = [
        ("support_guard_ring", [OUT_SUMMON / "guard_ring.png"]),
        ("support_guard_dome", [OUT_SUMMON / "guard_dome.png", OUT_VFX / "guard_blue_dome.png", OUT_VFX / "support_buff_dome.png"]),
        ("support_guard_buff", [OUT_SUMMON / "guard_upgrade.png", OUT_VFX / "guard_blue_shield.png", OUT_VFX / "support_shield_up.png", OUT_POLISH / "reserve_guard.png"]),
        ("support_heal_ring", [OUT_SUMMON / "heal_floor.png", OUT_SUMMON / "heal_swirl.png", OUT_VFX / "heal_ring_rise.png", OUT_VFX / "heal_sprout_glow.png"]),
        ("support_heal_beam", [OUT_SUMMON / "heal_column.png", OUT_SUMMON / "heal_sparks.png", OUT_VFX / "heal_pillar_leaf.png", OUT_VFX / "heal_ribbon_rise.png", OUT_VFX / "heal_sparkle.png"]),
        ("support_heal_burst", [OUT_SUMMON / "heal_plus.png", OUT_SUMMON / "heal_upgrade.png", OUT_VFX / "heal_burst_cross.png", OUT_VFX / "heal_cross_leaf.png", OUT_VFX / "heal_wave_plus.png"]),
    ]
    for img, (key, targets) in zip(cells, mapping_10):
        _save_targets(img, targets, manifest_rows, key, src)

    # 11. Tactical HUD Icons (4x2, outlined icons)
    src = "005-create-a-clean-2d-game-tactical-hud-icon-sheet-arranged-in-a.png"
    cells = split_grid(INBOX / src, 4, 2, clear_holes=False)
    mapping_11 = [
        ("tactical_reinforce", [OUT_SUMMON / "ai_reinforce.png", OUT_POLISH / "command_standard.png", OUT_POLISH / "warning_flag.png"]),
        ("tactical_advance", [OUT_SUMMON / "ai_advance.png", OUT_POLISH / "command_arrow.png", OUT_POLISH / "warning_green.png"]),
        ("tactical_attack", [OUT_SUMMON / "ai_attack.png", OUT_SUMMON / "status_target.png", OUT_POLISH / "warning_orange.png"]),
        ("tactical_guard", [OUT_SUMMON / "ai_guard.png"]),
        ("tactical_heal", [OUT_SUMMON / "ai_heal.png"]),
        ("tactical_retreat", [OUT_SUMMON / "ai_retreat.png"]),
        ("tactical_danger", [OUT_BASE / "alert.png", OUT_SUMMON / "ai_danger.png", OUT_POLISH / "warning_gold.png", OUT_POLISH / "danger_ping.png"]),
        ("tactical_breach", [OUT_BASE / "alert_large.png", OUT_SUMMON / "ai_breach.png", OUT_POLISH / "warning_breach.png", OUT_POLISH / "warning_red.png", OUT_SUMMON / "roster_full.png"]),
    ]
    for img, (key, targets) in zip(cells, mapping_11):
        _save_targets(img, targets, manifest_rows, key, src)

    # 12. Monkey Ally Character Animation (4x3, outlined character)
    src = "006-create-a-clean-2d-game-character-animation-sprite-sheet-arra.png"
    cells = split_grid(INBOX / src, 4, 3, clear_holes=False)
    for idx, img in enumerate(cells):
        _save_targets(
            img,
            [
                OUT_BASE / f"monkey_{idx:02d}.png",
                OUT_SUMMON / f"unit_{idx:02d}.png",
                OUT_POLISH / f"soldier_{idx:02d}.png",
            ],
            manifest_rows,
            f"monkey_ally_{idx:02d}",
            src,
        )

    pack_manifest = OUT_PACK / "manifest.json"
    pack_manifest.write_text(
        json.dumps({"pack": "summon_ui_cheatsheet_v1", "count": len(manifest_rows), "items": manifest_rows}, indent=2, ensure_ascii=False)
        + "\n",
        encoding="utf-8",
    )
    total_targets = sum(len(r["targets"]) for r in manifest_rows)
    print(f"Extracted {len(manifest_rows)} subimages -> {total_targets} runtime targets")

    sync_all_manifests()


if __name__ == "__main__":
    main()
