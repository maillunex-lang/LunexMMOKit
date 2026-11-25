#!/usr/bin/env python3
"""D01 — read-only Darklord inventory: paths, sizes, SHA256, GUID (.meta), Lua/XML/scene counts.

Does not copy asset binaries into the repo. Writes:
  - full index JSONL under OUT (default darklord-dgi)
  - summary + gaps report under docs/darklord/

Re-run must produce identical index_sha256 for acceptance.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
import time
from pathlib import Path

GUID_RE = re.compile(r"guid:\s*([0-9a-fA-F]{32})")

# Scoped roots — full Client dump is huge; inventory the data/content that D01 cares about.
SCOPES = [
    ("server_lua", "server/data/config", ("*.lua",)),
    ("client_lua", "Client/Assets/Resources/Lua/Data", ("*.lua.txt", "*.lua")),
    ("client_xml", "Client/Assets/Resources", ("*.xml",)),
    ("unity_scenes", "Client/Assets", ("*.unity",)),
    ("unity_prefabs", "Client/Assets", ("*.prefab",)),
    ("unity_meta", "Client/Assets", ("*.meta",)),
    ("server_sql", "server", ("*.sql",)),
]


def sha256_file(path: Path, chunk: int = 1024 * 1024) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        while True:
            b = f.read(chunk)
            if not b:
                break
            h.update(b)
    return h.hexdigest()


def iter_files(root: Path, rel: str, patterns: tuple[str, ...]):
    base = root / rel
    if not base.is_dir():
        return
    for pattern in patterns:
        # Prefer non-recursive for meta under whole Assets — too large; use rglob carefully
        yield from base.rglob(pattern)


def collect(root: Path, max_meta: int | None = None) -> list[dict]:
    rows: list[dict] = []
    seen: set[str] = set()
    meta_count = 0
    for scope, rel, patterns in SCOPES:
        for path in sorted(iter_files(root, rel, patterns)):
            if not path.is_file():
                continue
            try:
                rel_path = str(path.relative_to(root)).replace("\\", "/")
            except ValueError:
                continue
            if rel_path in seen:
                continue
            if scope == "unity_meta":
                meta_count += 1
                if max_meta is not None and meta_count > max_meta:
                    continue
            seen.add(rel_path)
            st = path.stat()
            digest = sha256_file(path)
            guid = ""
            if path.suffix == ".meta" or path.name.endswith(".meta"):
                try:
                    text = path.read_text(encoding="utf-8", errors="ignore")[:4000]
                    m = GUID_RE.search(text)
                    if m:
                        guid = m.group(1).lower()
                except OSError:
                    pass
            rows.append(
                {
                    "scope": scope,
                    "path": rel_path,
                    "size": st.st_size,
                    "mtime": int(st.st_mtime),
                    "sha256": digest,
                    "guid": guid,
                }
            )
    rows.sort(key=lambda r: r["path"])
    return rows


def summarize(rows: list[dict], root: Path, elapsed: float, gaps: list[str]) -> dict:
    by_scope: dict[str, dict] = {}
    guids = 0
    total = 0
    for r in rows:
        total += r["size"]
        s = by_scope.setdefault(r["scope"], {"count": 0, "bytes": 0, "guids": 0})
        s["count"] += 1
        s["bytes"] += r["size"]
        if r.get("guid"):
            s["guids"] += 1
            guids += 1
    # index fingerprint over path+sha256 lines
    h = hashlib.sha256()
    for r in rows:
        h.update(f"{r['path']}\t{r['sha256']}\t{r['size']}\n".encode())
    return {
        "root": str(root),
        "generated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "elapsed_sec": round(elapsed, 3),
        "file_count": len(rows),
        "total_bytes": total,
        "guid_count": guids,
        "index_sha256": h.hexdigest(),
        "by_scope": by_scope,
        "gaps": gaps,
        "scopes": [{"id": a, "rel": b, "patterns": list(c)} for a, b, c in SCOPES],
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=os.environ.get("LUNEX_DARKLORD_ROOT", "/home/gamedev/Darklord"))
    ap.add_argument("--out-dir", default="/home/gamedev/darklord-dgi")
    ap.add_argument("--docs", default="")
    ap.add_argument("--max-meta", type=int, default=0, help="Cap .meta files (0 = unlimited)")
    ap.add_argument("--verify", action="store_true", help="Re-run and compare to previous index_sha256")
    args = ap.parse_args()
    root = Path(args.root)
    out_dir = Path(args.out_dir)
    docs = Path(args.docs) if args.docs else Path(__file__).resolve().parents[2] / "docs" / "darklord"
    if not root.is_dir():
        print(f"D01_FAIL root missing {root}", file=sys.stderr)
        return 1
    out_dir.mkdir(parents=True, exist_ok=True)
    docs.mkdir(parents=True, exist_ok=True)

    gaps: list[str] = []
    for scope, rel, _ in SCOPES:
        if not (root / rel).exists():
            gaps.append(f"missing_scope:{scope}:{rel}")

    t0 = time.time()
    max_meta = None if args.max_meta == 0 else args.max_meta
    rows = collect(root, max_meta=max_meta)
    elapsed = time.time() - t0
    if max_meta is not None:
        # detect truncation
        meta_total = sum(1 for _ in (root / "Client/Assets").rglob("*.meta")) if (root / "Client/Assets").is_dir() else 0
        if meta_total > max_meta:
            gaps.append(f"meta_truncated:{max_meta}_of_{meta_total}")

    summary = summarize(rows, root, elapsed, gaps)
    index_path = out_dir / "d01-index.jsonl"
    with index_path.open("w", encoding="utf-8") as f:
        for r in rows:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")
    summary_path = out_dir / "d01-summary.json"
    summary_path.write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")

    # Compact report committed to repo (no full index)
    report = {
        "status": "ok" if not any(g.startswith("missing_scope") for g in gaps) else "partial",
        "index_sha256": summary["index_sha256"],
        "file_count": summary["file_count"],
        "total_bytes": summary["total_bytes"],
        "guid_count": summary["guid_count"],
        "by_scope": summary["by_scope"],
        "gaps": gaps,
        "index_path": str(index_path),
        "note": "Full JSONL stays under darklord-dgi (not copied into git). Re-run --verify for identical index_sha256.",
    }
    docs_report = docs / "D01_INVENTORY.json"
    prev = None
    if docs_report.exists():
        try:
            prev = json.loads(docs_report.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            prev = None
    docs_report.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    (docs / "D01.md").write_text(
        "# D01 — Darklord inventory\n\n"
        f"- index_sha256: `{report['index_sha256']}`\n"
        f"- files: {report['file_count']}, bytes: {report['total_bytes']}, guids: {report['guid_count']}\n"
        f"- full index: `{index_path}` (VPS/private; not in git)\n"
        f"- gaps: {', '.join(gaps) if gaps else 'none'}\n"
        f"- tool: `tools/dgi/inventory_darklord.py`\n"
        f"- verify: `python3 tools/dgi/inventory_darklord.py --verify`\n",
        encoding="utf-8",
    )

    if args.verify and prev and prev.get("index_sha256"):
        if prev["index_sha256"] == report["index_sha256"]:
            print(f"D01_VERIFY_OK index_sha256={report['index_sha256']} files={report['file_count']}")
            return 0
        print(
            f"D01_VERIFY_FAIL prev={prev['index_sha256']} now={report['index_sha256']}",
            file=sys.stderr,
        )
        return 2

    # Always self-verify by recomputing fingerprint from written JSONL
    h = hashlib.sha256()
    with index_path.open("r", encoding="utf-8") as f:
        for line in f:
            r = json.loads(line)
            h.update(f"{r['path']}\t{r['sha256']}\t{r['size']}\n".encode())
    if h.hexdigest() != report["index_sha256"]:
        print("D01_FAIL fingerprint mismatch after write", file=sys.stderr)
        return 1

    print(
        f"D01_OK index_sha256={report['index_sha256']} files={report['file_count']} "
        f"bytes={report['total_bytes']} guids={report['guid_count']} gaps={len(gaps)}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
