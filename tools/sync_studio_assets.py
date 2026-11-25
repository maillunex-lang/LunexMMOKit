#!/usr/bin/env python3
"""Copy adapted GLB/json from a local DGI export tree into assets/studio and refresh manifest.
Does NOT touch original Darklord sources. Dev/VPS helper for FIX-002 portability.
"""
from __future__ import annotations
import argparse, hashlib, json, pathlib, shutil, sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
DEST = ROOT / "assets" / "studio"

def sha256(p: pathlib.Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default=str(pathlib.Path.home() / "darklord-dgi"), help="Adapted DGI root")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()
    src = pathlib.Path(args.src)
    exports = src / "exports"
    if not exports.is_dir():
        print("MISSING_EXPORTS", exports)
        return 2
    DEST.mkdir(parents=True, exist_ok=True)
    (DEST / "exports").mkdir(parents=True, exist_ok=True)
    files = []
    patterns = ["10001.glb", "20001.glb", "30001.glb", "40001.glb",
                "weapon-100011000.glb", "weapon-200011000.glb",
                "weapon-300011000.glb", "weapon-400011000.glb",
                "training-monster.glb"]
    for name in patterns:
        s = exports / name
        if not s.is_file():
            print("SKIP", name)
            continue
        d = DEST / "exports" / name
        print("COPY", s, "->", d)
        if not args.dry_run:
            shutil.copy2(s, d)
        files.append({"path": f"exports/{name}", "size": d.stat().st_size if d.is_file() else s.stat().st_size,
                      "sha256": sha256(d if d.is_file() else s)})
    for meta in ("material-params.json", "particle-index.json"):
        s = src / meta
        if s.is_file():
            d = DEST / meta
            print("COPY", s, "->", d)
            if not args.dry_run:
                shutil.copy2(s, d)
            files.append({"path": meta, "size": (d if d.is_file() else s).stat().st_size,
                          "sha256": sha256(d if d.is_file() else s)})
    manifest = {"version": 1, "files": files}
    man_path = DEST / "manifest.json"
    if not args.dry_run:
        man_path.write_text(json.dumps(manifest, indent=2) + "\n")
    print("MANIFEST", man_path, "entries", len(files))
    return 0

if __name__ == "__main__":
    sys.exit(main())
