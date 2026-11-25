#!/usr/bin/env python3
"""D05 — VFX/audio/clip-event converter status from assets/studio/particle-index.json.

Classifies emitters as supported (CPUParticles path) vs unsupported (mesh/custom/missing tex).
Writes docs/darklord/D05_VFX.json + empty overrides stub.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
INDEX = ROOT / "assets" / "studio" / "particle-index.json"
OVERRIDES = ROOT / "client" / "content" / "vfx" / "overrides"


def classify_emitter(em: dict) -> str:
    render_mode = int(em.get("render_mode", 0) or 0)
    if render_mode == 4 and not em.get("mesh_glb"):
        return "unsupported_mesh_missing_glb"
    mats = em.get("materials") or []
    has_tex = False
    for m in mats:
        texts = m.get("textures") or {}
        for key in ("_MainTex", "_Texture", "_Textire", "_wenli"):
            if texts.get(key):
                has_tex = True
                break
    if mats and not has_tex:
        return "unsupported_missing_main_tex"
    # curves/bursts/shape — supported approximately by particle_preview
    return "supported_cpu"


def main() -> int:
    if not INDEX.is_file():
        print("D05_FAIL missing particle-index", file=sys.stderr)
        return 1
    data = json.loads(INDEX.read_text())
    prefabs = []
    unsupported = []
    supported = 0
    total_emitters = 0
    for path, payload in data.items():
        if not isinstance(payload, dict):
            continue
        emitters = payload.get("emitters") or []
        mesh_renderers = payload.get("mesh_renderers") or []
        entry = {
            "prefab": path,
            "emitters": len(emitters),
            "mesh_renderers": len(mesh_renderers),
            "emitter_status": [],
        }
        for em in emitters:
            total_emitters += 1
            st = classify_emitter(em if isinstance(em, dict) else {})
            entry["emitter_status"].append({"name": (em or {}).get("name"), "status": st})
            if st.startswith("supported"):
                supported += 1
            else:
                unsupported.append({"prefab": path, "emitter": (em or {}).get("name"), "status": st})
        prefabs.append(entry)
    OVERRIDES.mkdir(parents=True, exist_ok=True)
    stub = OVERRIDES / "README.md"
    if not stub.is_file():
        stub.write_text(
            "# VFX overrides\n\nManual Godot replacements for unsupported Unity emitters.\n"
            "Keys match particle-index prefab paths.\n",
            encoding="utf-8",
        )
    report = {
        "status": "ok" if supported > 0 else "partial",
        "prefab_count": len(prefabs),
        "emitter_total": total_emitters,
        "supported_cpu": supported,
        "unsupported_count": len(unsupported),
        "unsupported_sample": unsupported[:40],
        "prefabs": prefabs,
        "audio": {
            "note": "Attack audio still resolved via training CLASS_AUDIO / file paths; full bank conversion pending",
            "supported": "mp3_stream_playback",
        },
        "clip_events": {
            "source": "client/content/combat/class_attack_events.json (CHAR07)",
            "sync_test": "client/tests/d05_vfx_sync_smoke.gd",
        },
        "gaps": [],
    }
    if unsupported:
        report["gaps"].append("unsupported_emitters_logged")
    docs = ROOT / "docs" / "darklord"
    docs.mkdir(parents=True, exist_ok=True)
    (docs / "D05_VFX.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    (docs / "D05.md").write_text(
        "# D05 — VFX converter status\n\n"
        f"- status: `{report['status']}`\n"
        f"- prefabs: {report['prefab_count']}, emitters: {report['emitter_total']}, "
        f"supported_cpu: {report['supported_cpu']}, unsupported: {report['unsupported_count']}\n"
        f"- gaps: {', '.join(report['gaps']) if report['gaps'] else 'none'}\n"
        "- tool: `tools/dgi/d05_vfx_status.py`\n"
        "- runtime builder: `client/content/vfx/particle_preview.gd`\n",
        encoding="utf-8",
    )
    print(
        f"D05_OK status={report['status']} prefabs={report['prefab_count']} "
        f"supported={supported} unsupported={len(unsupported)}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
