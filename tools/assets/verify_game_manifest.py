#!/usr/bin/env python3
"""Verify docs/manifests/game_assets.json against workspace. Fail on missing/mismatch/VPS deps."""
from __future__ import annotations
import hashlib, json, pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "docs" / "manifests" / "game_assets.json"
FORBIDDEN_RUNTIME = re.compile(r"/home/gamedev/(Darklord|darklord-dgi|lunex-asset-library)(/|$)")
RUNTIME_GLOBS = [
    "client/**/*.gd",
    "client/**/*.tscn",
    "client/**/*.tres",
    "client/**/*.json",
]


def sha256(p: pathlib.Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def main() -> int:
    fails = []
    if not MANIFEST.is_file():
        print("FAIL missing", MANIFEST)
        return 2
    data = json.loads(MANIFEST.read_text())
    files = data.get("files", [])
    if not files:
        fails.append("empty manifest")
    for entry in files:
        rel = entry["path"]
        p = ROOT / rel
        if not p.is_file():
            fails.append(f"missing {rel}")
            continue
        if p.stat().st_size != int(entry["size"]):
            fails.append(f"size mismatch {rel}")
        if sha256(p) != entry["sha256"]:
            fails.append(f"sha256 mismatch {rel}")
    # Runtime must not hardcode VPS original trees (tools/ excluded)
    for pattern in ("client/**/*.gd", "client/**/*.tscn", "client/**/*.json"):
        for p in ROOT.glob(pattern):
            if not p.is_file():
                continue
            try:
                text = p.read_text(errors="ignore")
            except Exception:
                continue
            if FORBIDDEN_RUNTIME.search(text):
                fails.append(f"runtime VPS path in {p.relative_to(ROOT)}")
    # particle-index absolute mesh paths
    pi = ROOT / "assets/studio/particle-index.json"
    if pi.is_file() and "/home/gamedev/" in pi.read_text(errors="ignore"):
        fails.append("assets/studio/particle-index.json contains absolute VPS paths")

    if fails:
        print("MANIFEST_VERIFY_FAIL", len(fails))
        for f in fails[:40]:
            print(" -", f)
        return 1
    print(f"MANIFEST_VERIFY_OK count={len(files)} bytes={data.get('total_bytes')}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
