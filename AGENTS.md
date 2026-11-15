# Game Asset & Project Workflow — Đường Đến Thiên Giới (Cloudbound)

Toolkit: `tools/gameforge-kit/` (pinned Git Submodule)

## Asset Pipeline Rules
- Read `tools/gameforge-kit/AGENTS.md` and the relevant `SKILL.md` under `tools/gameforge-kit/skills/` before running asset tasks.
- Use toolkit CLI scripts (`batch_planner.py`, `frame_normalizer.py`, `atlas_packer.py`, `validators.py`, `godot_exporter.py`, `build_viewer.py`); do not duplicate asset-generation logic.
- Store game-specific profiles in `profiles/` inside this repository.
- Always pass `--project-root .`, `--output-dir assets/generated`, and `--work-dir .gameforge/work` so nothing is written inside `tools/gameforge-kit/`.
- Never edit or auto-update `tools/gameforge-kit/` unless explicitly requested.
- Report missing dependencies (`blender`, `godot`, AI API) and failed validations honestly. When `blender` is unavailable, use procedural placeholder sprite frames routed through `gameforge-kit` normalizer/packer/exporter.
