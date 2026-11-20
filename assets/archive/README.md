# Asset archive

New source sheets go in `assets/inbox/`. Move validated source sheets here after extraction and update the corresponding extractor and manifest.

Survivor originals (Base Asset Cheatsheet packs) are grouped under `adapted/survivor/`:

- `cheatsheet_v1/` contains 11 sheets aligned to the Base Asset Cheatsheet (5 Monkey Combat Roles, portraits/role badges, HUD/banners, Sun Wukong, Boar Boss, Golden Dragon, and environment props).
- `enemies_cheatsheet_v1/` contains 8 sheets aligned to the Base Asset Cheatsheet Enemy Roster (Forest Goblin, Stone Golem, Fire Imp, Treant, White Fox Spirit, Golden Dragon, Cave Bat, and Bamboo Snake).
- `equipment_cheatsheet_v1/` contains 2 sheets aligned to the Base Asset Cheatsheet Weapons & Equipment (8 core weapons/role staves and 8 elite/shop upgrade icons).
- `collectibles_cheatsheet_v1/` contains 7 sheets (3x2 each) aligned to the Base Asset Cheatsheet Collectibles & Items (Gold, Gold Stack, Peach, Crystal, Chest, Heart, and XP Star with drop/trail/collect VFX).
- `vfx_cheatsheet_v1/` contains 8 sheets (3x2 each) aligned to the Base Asset Cheatsheet Combat VFX (Slash, Arrow Flight, Hit Spark, Hit Burst, Magic Charge, Magic Impact, Boss Telegraph, and Boss Slam Burst).
- `summon_ui_cheatsheet_v1/` contains 12 sheets aligned to the Base Asset Cheatsheet Summon, UI, HUD, Upgrade, Support/Buff VFX, Tactical Icons, Overlay FX, and Monkey Ally (12-frame) packs.
- `slime_boar_portraits_cheatsheet_v1/` contains 3 sheets aligned to the Base Asset Cheatsheet Purple Slime (8 frames), Wild Boar (8 frames), and Portrait Icons (6 rounded gold-framed role/commander portraits).

Godot uses the extracted runtime assets in `assets/survivor/`. Earlier legacy source sheets (`base/`, `polish/`, `enemies/`, `summon/`, `combat/`, `vfx/`) have been pruned from the working tree and remain recoverable from Git history.
