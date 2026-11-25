#!/usr/bin/env python3
"""D04 — scene/collision/navigation status for converted capital + play locations."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def count_in_file(path: Path, pattern: str) -> int:
    if not path.is_file():
        return 0
    return len(re.findall(pattern, path.read_text(errors="ignore")))


def main() -> int:
    locs = {
        "eternity_capital": ROOT / "client/world/locations/eternity_capital/eternity_capital.tscn",
        "eternity_play": ROOT / "client/world/locations/eternity_capital/eternity_play.tscn",
        "ashen_outskirts": ROOT / "client/world/locations/ashen_outskirts",
        "shard_ruins": ROOT / "client/world/locations/shard_ruins",
    }
    capital = locs["eternity_capital"]
    report = {
        "status": "ok",
        "capital": {
            "path": str(capital.relative_to(ROOT)) if capital.is_file() else None,
            "bytes": capital.stat().st_size if capital.is_file() else 0,
            "static_bodies": count_in_file(capital, r'type="StaticBody3D"'),
            "collision_shapes": count_in_file(capital, r'type="CollisionShape3D"'),
            "nav_regions": count_in_file(capital, r'type="NavigationRegion3D"'),
            "mesh_instances": count_in_file(capital, r'type="MeshInstance3D"'),
        },
        "play_scenes": {},
        "coord_compare": None,
        "gaps": [],
        "note": "Conversion tools live under tools/world/*; this stage verifies portable converted scenes + route prerequisites.",
    }
    for name in ("eternity_play",):
        p = locs[name]
        report["play_scenes"][name] = {
            "exists": p.is_file(),
            "bytes": p.stat().st_size if p.is_file() else 0,
        }
    for name in ("ashen_outskirts", "shard_ruins"):
        d = locs[name]
        scenes = list(d.glob("*.tscn")) if d.is_dir() else []
        report["play_scenes"][name] = {"dir": d.is_dir(), "scenes": [s.name for s in scenes]}
    compare = ROOT / "docs/darklord/city-coord-compare-v7.json"
    if compare.is_file():
        raw = json.loads(compare.read_text())
        report["coord_compare"] = {
            "path": str(compare.relative_to(ROOT)),
            "keys": list(raw)[:12] if isinstance(raw, dict) else {"type": type(raw).__name__},
        }
    else:
        report["gaps"].append("missing_coord_compare")
    cap = report["capital"]
    play_gd = ROOT / "client/world/locations/eternity_capital/eternity_play.gd"
    report["runtime_nav"] = {
        "eternity_play_ensures_nav": play_gd.is_file()
        and "_ensure_nav" in play_gd.read_text(errors="ignore")
        and "NavigationRegion3D" in play_gd.read_text(errors="ignore"),
        "location_navigation_gd": (ROOT / "client/world/location_navigation.gd").is_file(),
    }
    if not capital.is_file():
        report["status"] = "fail"
        report["gaps"].append("missing_capital_scene")
    else:
        if cap["static_bodies"] < 10:
            report["gaps"].append("few_collisions")
        # Nav is baked at play-time (eternity_play._ensure_nav), not stored in capital.tscn
        if not report["runtime_nav"]["eternity_play_ensures_nav"]:
            report["gaps"].append("no_runtime_nav")
        if report["gaps"]:
            report["status"] = "partial"
        else:
            report["status"] = "ok"
    docs = ROOT / "docs" / "darklord"
    docs.mkdir(parents=True, exist_ok=True)
    (docs / "D04_SCENE.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    (docs / "D04.md").write_text(
        "# D04 — Scene conversion status\n\n"
        f"- status: `{report['status']}`\n"
        f"- capital collisions: {cap.get('static_bodies')} shapes={cap.get('collision_shapes')} nav={cap.get('nav_regions')}\n"
        f"- gaps: {', '.join(report['gaps']) if report['gaps'] else 'none'}\n"
        "- tool: `tools/dgi/d04_scene_status.py`\n"
        "- route smoke: `tools/run_audit_smokes.sh` → nav_obstacle_smoke\n",
        encoding="utf-8",
    )
    print(
        f"D04_OK status={report['status']} collisions={cap.get('static_bodies')} "
        f"nav={cap.get('nav_regions')} meshes={cap.get('mesh_instances')}"
    )
    return 0 if report["status"] in ("ok", "partial") else 1


if __name__ == "__main__":
    sys.exit(main())
