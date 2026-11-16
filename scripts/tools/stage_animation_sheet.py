"""Stage a transparent AI sprite sheet for the GameForge sprite pipeline."""

import argparse
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageFilter


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("character")
    parser.add_argument("animation")
    parser.add_argument("--direction", default="down")
    parser.add_argument("--columns", type=int, required=True)
    parser.add_argument("--rows", type=int, default=2)
    parser.add_argument("--scale", type=float, required=True)
    parser.add_argument("--fps", type=float, required=True)
    parser.add_argument("--loop", action="store_true")
    parser.add_argument("--alpha-core", type=int, default=128)
    parser.add_argument("--edge-radius", type=int, default=8)
    parser.add_argument("--project-root", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--work-dir", type=Path, required=True)
    args = parser.parse_args()

    root = args.project_root.resolve()
    profile = json.loads((root / "profiles/wukong_gate_a.json").read_text())
    profile["atlas"].update(columns=args.columns, rows=args.rows)
    name = f"{args.animation}_{args.direction}"
    task_id = f"{args.character}_{name}"
    stage = args.work_dir / task_id
    stage.mkdir(parents=True, exist_ok=True)
    output = args.output_dir / args.character

    with Image.open(args.source) as sheet:
        if sheet.mode != "RGBA":
            parser.error("Source must have an RGBA alpha channel.")
        frames = []
        for row in range(args.rows):
            for column in range(args.columns):
                index = row * args.columns + column
                cell = sheet.crop((
                    column * sheet.width // args.columns,
                    row * sheet.height // args.rows,
                    (column + 1) * sheet.width // args.columns,
                    (row + 1) * sheet.height // args.rows,
                ))
                alpha = cell.getchannel("A")
                core = alpha.point(lambda value: 255 if value >= args.alpha_core else 0)
                mask = core.filter(ImageFilter.MaxFilter(args.edge_radius * 2 + 1))
                cleaned = ImageChops.multiply(alpha, mask)
                bounds = cleaned.getbbox()
                if bounds is None or bounds[0] == 0 or bounds[1] == 0 or bounds[2] == cell.width or bounds[3] == cell.height:
                    parser.error(f"Cell {index + 1} is empty or touches its crop boundary.")
                cell.putalpha(cleaned)
                cell = cell.crop(bounds)
                cell = cell.resize(
                    tuple(max(1, round(size * args.scale)) for size in cell.size),
                    Image.Resampling.LANCZOS,
                )
                filename = f"frame_{index + 1:02}.png"
                source_path = stage / filename
                cell.save(source_path)
                frames.append({
                    "index": index,
                    "source_path": str(source_path),
                    "normalized_path": str(output / "frames" / name / filename),
                })

    manifest = {
        "profile": profile,
        "batch_id": task_id,
        "report_path": str(stage / "validation.json"),
        "project": "cloudbound",
        "character_id": args.character,
        "tasks": [{
            "task_id": task_id,
            "animation": args.animation,
            "direction": args.direction,
            "fps": args.fps,
            "loop": args.loop,
            "frame_count": len(frames),
            "frames": frames,
            "atlas_png_path": str(output / f"{task_id}.png"),
            "atlas_json_path": str(output / f"{task_id}.atlas.json"),
        }],
    }
    manifest_path = stage / "batch-manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
    print(manifest_path)


if __name__ == "__main__":
    main()
