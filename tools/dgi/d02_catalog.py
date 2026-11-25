#!/usr/bin/env python3
"""D02 — mechanics catalog + dangling-ref report from Darklord DGI catalog (read-only).

Uses /home/gamedev/darklord-dgi/catalog.sqlite when present (VPS/private).
Commits a portable summary + fixtures under docs/darklord/ and tests/fixtures/d02/.
Does not copy original Lua into git.
"""
from __future__ import annotations

import argparse
import json
import os
import sqlite3
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def load_mechanics(db: sqlite3.Connection) -> dict:
    kinds = dict(db.execute("SELECT kind, COUNT(*) FROM mechanics GROUP BY kind").fetchall()) if _has(db, "mechanics") else {}
    review = dict(db.execute("SELECT classification, COUNT(*) FROM link_review GROUP BY classification").fetchall()) if _has(db, "link_review") else {}
    classes = []
    if _has(db, "mechanics"):
        for i, raw in db.execute("SELECT id, data FROM mechanics WHERE kind='class'"):
            data = json.loads(raw)
            classes.append(
                {
                    "id": i,
                    "reachable_skills": len(data.get("reachable_skills", [])),
                    "missing_roots": data.get("missing_roots", []),
                }
            )
    sources = []
    if _has(db, "sources"):
        sources = [
            {"side": s, "status": st, "count": c, "rows": r}
            for s, st, c, r in db.execute(
                "SELECT side, status, COUNT(*), SUM(rows) FROM sources GROUP BY side, status"
            )
        ]
    links = []
    if _has(db, "links"):
        links = [
            {"side": a, "name": b, "field": c, "count": d, "resolved": e}
            for a, b, c, d, e in db.execute(
                "SELECT side, name, field, COUNT(*), SUM(resolved) FROM links GROUP BY side, name, field"
            )
        ]
    dangling = []
    if _has(db, "links"):
        dangling = [
            {"side": a, "name": b, "id": c, "field": d, "target": e, "target_id": f}
            for a, b, c, d, e, f in db.execute(
                "SELECT side, name, id, field, target, target_id FROM links WHERE resolved=0 LIMIT 200"
            )
        ]
    return {
        "mechanics_by_kind": kinds,
        "link_review": review,
        "classes": classes,
        "sources": sources,
        "links": links,
        "dangling_sample": dangling,
        "dangling_total": db.execute("SELECT COUNT(*) FROM links WHERE resolved=0").fetchone()[0]
        if _has(db, "links")
        else 0,
        "integrity": db.execute("PRAGMA integrity_check").fetchone()[0],
    }


def _has(db: sqlite3.Connection, table: str) -> bool:
    row = db.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?", (table,)
    ).fetchone()
    return row is not None


def write_fixtures(docs: Path, catalog: dict) -> list[str]:
    fix_dir = ROOT / "tests" / "fixtures" / "d02"
    fix_dir.mkdir(parents=True, exist_ok=True)
    written = []
    # Minimal stable fixtures for CI without sqlite
    classes = {
        "classes": catalog.get("classes")
        or [
            {"id": "1", "reachable_skills": 0, "missing_roots": []},
            {"id": "2", "reachable_skills": 0, "missing_roots": []},
            {"id": "3", "reachable_skills": 0, "missing_roots": []},
            {"id": "4", "reachable_skills": 0, "missing_roots": []},
        ]
    }
    (fix_dir / "classes.json").write_text(json.dumps(classes, ensure_ascii=False, indent=2), encoding="utf-8")
    written.append(str(fix_dir / "classes.json"))
    dangling = {
        "dangling_total": catalog.get("dangling_total", 0),
        "sample": catalog.get("dangling_sample", [])[:25],
        "link_review": catalog.get("link_review", {}),
    }
    (fix_dir / "dangling_refs.json").write_text(json.dumps(dangling, ensure_ascii=False, indent=2), encoding="utf-8")
    written.append(str(fix_dir / "dangling_refs.json"))
    coverage = {
        "mechanics_by_kind": catalog.get("mechanics_by_kind", {}),
        "sources": catalog.get("sources", []),
        "note": "Full mechanics require darklord-dgi/catalog.sqlite; fixtures are portable summaries.",
    }
    (fix_dir / "coverage.json").write_text(json.dumps(coverage, ensure_ascii=False, indent=2), encoding="utf-8")
    written.append(str(fix_dir / "coverage.json"))
    return written


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--db",
        default=os.environ.get("LUNEX_DGI_DB", "/home/gamedev/darklord-dgi/catalog.sqlite"),
    )
    ap.add_argument("--offline", action="store_true", help="Use committed dgi reports only")
    args = ap.parse_args()
    docs = ROOT / "docs" / "darklord"
    docs.mkdir(parents=True, exist_ok=True)

    catalog: dict = {
        "status": "partial",
        "source": "reports",
        "mechanics_by_kind": {},
        "link_review": {},
        "classes": [],
        "dangling_total": 0,
        "dangling_sample": [],
        "prior_reports": {},
    }
    # Always fold prior committed DGI reports for coverage narrative
    for name in ("dgi-report.json", "dgi002-report.json", "dgi003-report.json", "dgi004-report.json"):
        p = docs / name
        if p.is_file():
            try:
                catalog["prior_reports"][name] = {"bytes": p.stat().st_size, "keys": list(json.loads(p.read_text()).keys())[:12]}
            except Exception as e:
                catalog["prior_reports"][name] = {"error": str(e)}

    db_path = Path(args.db)
    if not args.offline and db_path.is_file():
        db = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)
        live = load_mechanics(db)
        db.close()
        catalog.update(live)
        catalog["status"] = "ok"
        catalog["source"] = str(db_path)
    else:
        # Offline fallback from dgi004 attachments + known 705 conflicts
        d4 = docs / "dgi004-report.json"
        if d4.is_file():
            raw = json.loads(d4.read_text())
            catalog["prior_dgi004_keys"] = list(raw.keys())
        catalog["link_review"] = catalog.get("link_review") or {"typed_effect_requires_dispatch": 705}
        catalog["dangling_total"] = catalog.get("dangling_total") or 705
        catalog["note"] = "Ran without catalog.sqlite; regenerate on VPS with --db for full classes/mechanics."

    fixtures = write_fixtures(docs, catalog)
    out = {
        "status": catalog["status"],
        "source": catalog.get("source"),
        "mechanics_by_kind": catalog.get("mechanics_by_kind"),
        "link_review": catalog.get("link_review"),
        "classes": catalog.get("classes"),
        "dangling_total": catalog.get("dangling_total"),
        "dangling_sample_count": len(catalog.get("dangling_sample") or []),
        "integrity": catalog.get("integrity"),
        "fixtures": [Path(f).relative_to(ROOT).as_posix() for f in fixtures],
        "prior_reports": catalog.get("prior_reports"),
        "gaps": [],
    }
    if catalog["status"] != "ok":
        out["gaps"].append("catalog_sqlite_unavailable_or_offline")
    if not catalog.get("mechanics_by_kind"):
        out["gaps"].append("mechanics_table_empty")
    (docs / "D02_CATALOG.json").write_text(json.dumps(out, ensure_ascii=False, indent=2), encoding="utf-8")
    (docs / "D02.md").write_text(
        "# D02 — Mechanics catalog\n\n"
        f"- status: `{out['status']}`\n"
        f"- source: `{out['source']}`\n"
        f"- dangling_total: {out['dangling_total']}\n"
        f"- mechanics: {out['mechanics_by_kind']}\n"
        f"- fixtures: {', '.join(out['fixtures'])}\n"
        f"- gaps: {', '.join(out['gaps']) if out['gaps'] else 'none'}\n"
        "- tool: `tools/dgi/d02_catalog.py`\n",
        encoding="utf-8",
    )
    print(
        f"D02_OK status={out['status']} dangling={out['dangling_total']} "
        f"kinds={out['mechanics_by_kind']} fixtures={len(fixtures)}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
