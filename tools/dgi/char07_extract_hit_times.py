#!/usr/bin/env python3
"""CHAR07 — extract basic-attack hit/fire times from Darklord skill_events into portable JSON."""
from __future__ import annotations

import json
import os
import sqlite3
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
# Studio actor_id → PlayerinfoConfig id
ACTOR_CLASS = {"10001": "3", "20001": "2", "30001": "1", "40001": "4"}


def main() -> int:
    db_path = Path(os.environ.get("LUNEX_DGI_DB", "/home/gamedev/darklord-dgi/catalog.sqlite"))
    out = ROOT / "client" / "content" / "combat" / "class_attack_events.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    if not db_path.is_file():
        print("CHAR07_EXTRACT_FAIL missing", db_path, file=sys.stderr)
        return 1
    db = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)
    payload = {
        "source": "SkillClassDisplayDesc.xml via skill_events",
        "note": "Basic attack = first init_skill id per PlayerinfoConfig",
        "classes": {},
    }
    for actor, pid in ACTOR_CLASS.items():
        raw = db.execute(
            "SELECT data FROM records WHERE side=? AND name=? AND id=?",
            ("server", "PlayerinfoConfig.lua", pid),
        ).fetchone()
        if not raw:
            print("missing playerinfo", pid, file=sys.stderr)
            return 1
        skills = str(json.loads(raw[0])["init_skill"]).split("#")
        basic = skills[0]
        events = []
        for _ord, data in db.execute(
            "SELECT ordinal, data FROM skill_events WHERE skill=? ORDER BY ordinal", (basic,)
        ):
            d = json.loads(data)
            attrs = d.get("attributes") or {}
            tag = d.get("tag") or ""
            if "hitTime" in attrs:
                events.append(
                    {
                        "kind": "hit",
                        "time": float(attrs["hitTime"]),
                        "skill_id": basic,
                        "xml_tag": tag,
                        "source": "SkillClassDisplayDesc.xml",
                    }
                )
            if "fireTime" in attrs:
                events.append(
                    {
                        "kind": "projectile",
                        "time": float(attrs["fireTime"]),
                        "skill_id": basic,
                        "xml_tag": tag,
                        "source": "SkillClassDisplayDesc.xml",
                    }
                )
        # Primary combat event for attack001 preview = first hit or projectile
        primary = next((e for e in events if e["kind"] in ("hit", "projectile")), None)
        payload["classes"][actor] = {
            "playerinfo_id": pid,
            "basic_skill_id": basic,
            "events": events,
            "attack001": primary,
        }
    db.close()
    out.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    # fixtures copy
    fix = ROOT / "tests" / "fixtures" / "char07" / "class_attack_events.json"
    fix.parent.mkdir(parents=True, exist_ok=True)
    fix.write_text(out.read_text(encoding="utf-8"), encoding="utf-8")
    print(f"CHAR07_EXTRACT_OK -> {out.relative_to(ROOT)} classes={list(payload['classes'])}")
    for a, c in payload["classes"].items():
        p = c["attack001"]
        print(f"  {a} skill={c['basic_skill_id']} {p['kind']}@{p['time']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
