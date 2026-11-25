#!/usr/bin/env python3
"""Build docs/manifests/game_assets.json for used LunexMMOKit game resources only.
Does not scan Darklord / darklord-dgi / lunex-asset-library.
"""
from __future__ import annotations
import hashlib, json, pathlib, sys, time

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "manifests" / "game_assets.json"

# Relative roots that belong in the shippable game (used assets)
SCAN = [
    ("assets/studio", "studio"),
    ("client/world/library", "world_library"),
    ("client/world/locations", "locations"),
    ("client/world/models", "world_models"),
    ("client/content", "content"),
    ("client/ui", "ui"),
    ("client/addons/lunex_world_editor", "editor"),
    ("client/combat", "combat"),
    ("client/actors", "actors"),
    ("client/network", "network"),
    ("client/core", "core"),
    ("shared", "shared"),
    ("server/migrations", "migrations"),
]

INCLUDE_EXT = {
    ".glb", ".gltf", ".png", ".jpg", ".jpeg", ".tga", ".webp",
    ".tres", ".tscn", ".gd", ".gdshader", ".json", ".ogg", ".wav", ".mp3",
    ".ttf", ".otf", ".svg", ".import", ".uid", ".cfg", ".sql",
}

SKIP_PARTS = {".godot", "__pycache__", "imported/capital_geometry", "backups"}


def sha256(p: pathlib.Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def category_for(rel: str, bucket: str) -> str:
    low = rel.lower()
    if "kit" in low or bucket == "world_library":
        if "/meshes/" in low:
            return "mesh"
        if "/textures/" in low:
            return "texture"
        if "/kits/" in low:
            return "kit_scene"
    if low.endswith(".glb") or low.endswith(".gltf"):
        return "model"
    if low.endswith((".png", ".jpg", ".jpeg", ".tga", ".webp")):
        return "texture"
    if low.endswith(".tscn"):
        return "scene"
    if low.endswith(".gdshader"):
        return "shader"
    if low.endswith((".ogg", ".wav", ".mp3")):
        return "audio"
    if low.endswith(".sql"):
        return "migration"
    if "quest" in low:
        return "quest_data"
    if "hero" in low or "class" in low:
        return "game_data"
    return bucket


def main() -> int:
    files = []
    hashes: dict[str, list[str]] = {}
    for rel_root, bucket in SCAN:
        base = ROOT / rel_root
        if not base.exists():
            continue
        for p in base.rglob("*"):
            if not p.is_file():
                continue
            if any(s in str(p) for s in SKIP_PARTS):
                continue
            if p.suffix.lower() not in INCLUDE_EXT and p.name not in ("manifest.json",):
                continue
            rel = p.relative_to(ROOT).as_posix()
            digest = sha256(p)
            hashes.setdefault(digest, []).append(rel)
            files.append({
                "id": f"asset:{digest[:12]}:{pathlib.Path(rel).name}",
                "category": category_for(rel, bucket),
                "path": rel,
                "size": p.stat().st_size,
                "sha256": digest,
                "version": 1,
                "source": "lunex_adapted" if rel.startswith("assets/studio") else "lunex_authored",
                "provenance": "Darklord-adapted (not original project)" if "studio" in rel or "library" in rel else "Lunex",
                "dependencies": [],
                "purpose": bucket,
                "license_status": "restricted_adapted_runtime" if "studio" in rel or "library" in rel else "project",
            })
    duplicates = {h: paths for h, paths in hashes.items() if len(paths) > 1}
    payload = {
        "version": 1,
        "generated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "product": "Осколки вечности",
        "note": "Used game resources only. Original Darklord / full DGI / full asset library are NOT included.",
        "count": len(files),
        "total_bytes": sum(f["size"] for f in files),
        "duplicate_sha256_groups": len(duplicates),
        "duplicates": [{"sha256": h, "paths": paths} for h, paths in sorted(duplicates.items())[:50]],
        "files": sorted(files, key=lambda x: x["path"]),
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")
    print(f"MANIFEST_OK count={payload['count']} bytes={payload['total_bytes']} dup_groups={payload['duplicate_sha256_groups']} -> {OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
