#!/usr/bin/env python3
"""D03 — used-asset GLB export status for four model types + accessories.

Does not re-run FBX conversion (expensive / VPS Darklord). Verifies portable
assets/studio exports import prerequisites and writes docs/darklord/D03_EXPORT.json.
"""
from __future__ import annotations

import hashlib
import json
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
STUDIO = ROOT / "assets" / "studio" / "exports"


def sha256(p: Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def glb_meta(p: Path) -> dict:
    data = p.read_bytes()
    if data[:4] != b"glTF":
        return {"ok": False, "error": "not_glb"}
    chunk_len, chunk_type = struct.unpack_from("<I4s", data, 12)
    if chunk_type != b"JSON":
        return {"ok": False, "error": "no_json_chunk"}
    js = json.loads(data[20 : 20 + chunk_len])
    return {
        "ok": True,
        "meshes": len(js.get("meshes", [])),
        "materials": len(js.get("materials", [])),
        "images": len(js.get("images", [])),
        "animations": len(js.get("animations", [])),
        "skins": len(js.get("skins", [])),
        "nodes": len(js.get("nodes", [])),
    }


def entry(rel: str, kind: str) -> dict:
    p = ROOT / rel
    if not p.is_file():
        return {"path": rel, "kind": kind, "ok": False, "error": "missing"}
    meta = glb_meta(p)
    meta.update(
        {
            "path": rel,
            "kind": kind,
            "size": p.stat().st_size,
            "sha256": sha256(p),
        }
    )
    return meta


def main() -> int:
    required = [
        ("assets/studio/exports/10001.glb", "actor_warrior"),
        ("assets/studio/exports/20001.glb", "actor_archer"),
        ("assets/studio/exports/30001.glb", "actor_mage"),
        ("assets/studio/exports/40001.glb", "actor_assassin"),
        ("assets/studio/exports/weapon-100011000.glb", "weapon_sword"),
        ("assets/studio/exports/weapon-200011000.glb", "weapon_bow"),
        ("assets/studio/exports/weapon-300011000.glb", "weapon_staff"),
        ("assets/studio/exports/weapon-400011000.glb", "weapon_dual"),
        ("assets/studio/exports/accessories/wing.glb", "wing"),
        ("assets/studio/exports/accessories/pet.glb", "pet"),
        ("assets/studio/exports/accessories/mount.glb", "mount"),
        ("assets/studio/exports/accessories/wing-02.glb", "wing_alt"),
        ("assets/studio/exports/accessories/pet-02.glb", "pet_alt"),
        ("assets/studio/exports/accessories/mount-02.glb", "mount_alt"),
    ]
    files = [entry(rel, kind) for rel, kind in required]
    ok = all(f.get("ok") for f in files)
    # four actor types must have skins+animations for Godot character import
    actors = [f for f in files if f["kind"].startswith("actor_")]
    actor_ok = all(f.get("skins", 0) > 0 and f.get("animations", 0) > 0 for f in actors if f.get("ok"))
    report = {
        "status": "ok" if ok and actor_ok else "partial",
        "godot_import_ready": ok and actor_ok,
        "four_model_types": {
            "actors": 4 if actor_ok else sum(1 for f in actors if f.get("ok")),
            "weapons": sum(1 for f in files if f["kind"].startswith("weapon_") and f.get("ok")),
            "accessories": sum(
                1
                for f in files
                if f["kind"] in ("wing", "pet", "mount", "wing_alt", "pet_alt", "mount_alt") and f.get("ok")
            ),
        },
        "files": files,
        "gaps": [],
        "note": "FBX→GLB conversion remains private (tools/dgi/convert_model.py + Darklord). This stage verifies portable used-asset pack in assets/studio.",
    }
    if not ok:
        report["gaps"].append("missing_or_invalid_glb")
    if not actor_ok:
        report["gaps"].append("actor_missing_skin_or_animations")
    docs = ROOT / "docs" / "darklord"
    docs.mkdir(parents=True, exist_ok=True)
    (docs / "D03_EXPORT.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    (docs / "D03.md").write_text(
        "# D03 — Export status\n\n"
        f"- status: `{report['status']}`\n"
        f"- godot_import_ready: {report['godot_import_ready']}\n"
        f"- types: {report['four_model_types']}\n"
        f"- gaps: {', '.join(report['gaps']) if report['gaps'] else 'none'}\n"
        "- tool: `tools/dgi/d03_export_status.py`\n"
        "- full FBX pipeline stays VPS-side; used assets verified in `assets/studio/exports`\n",
        encoding="utf-8",
    )
    # portable smoke: ensure studio manifest lists actors
    man = ROOT / "assets" / "studio" / "manifest.json"
    if man.is_file():
        m = json.loads(man.read_text())
        paths = {e["path"] for e in m.get("files", [])}
        for rel, _ in required[:8]:
            short = rel.replace("assets/studio/", "")
            if short not in paths and rel not in paths:
                # manifest paths are relative to studio root
                alt = "/".join(Path(rel).parts[2:])
                if alt not in paths:
                    report["gaps"].append(f"manifest_missing:{alt}")
    print(
        f"D03_OK status={report['status']} import_ready={report['godot_import_ready']} "
        f"actors={report['four_model_types']['actors']} weapons={report['four_model_types']['weapons']} "
        f"accessories={report['four_model_types']['accessories']}"
    )
    return 0 if report["status"] == "ok" else 1


if __name__ == "__main__":
    sys.exit(main())
