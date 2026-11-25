# AI entrypoint
Read this file, then docs/NEXT.md. Do not scan the whole repo or Darklord.
Run python3 tools/roadmap.py next. Read only the task card, its listed domain document, and files in scope. Inspect dependencies only if necessary.
Do not treat a plan as implemented. Never mark done without evidence. Update task status, evidence and NEXT via roadmap.py; commit and push only after checks. Check CI; if unavailable record pending. Never expose credentials or private assets. Never delete original Darklord or modify other projects. No production migrations or deployment without approval. Stop on destructive changes, licensing uncertainty, or failed dependencies.

## Product goal (BETA-001)
End goal is **Closed Beta 0.1.0 «Осколки вечности»** — online authoritative MMORPG (Go + PostgreSQL + Godot Android). See docs/BETA_001.md.
City Preview APK is internal smoke only, not the ship target. Do not stop after a demo scene.

## Disaster recovery (permanent — DISASTER-RECOVERY-001)
- One game, one repo (`LunexMMOKit`), one used-asset library inside the repo. No extra full project copies on disk.
- GitHub must contain everything needed to develop, edit in Godot on Windows, run server, migrate DB schema, and build APK for **our** game.
- Never commit original Darklord / full DGI / full Lunex Asset Library / secrets / player DB dumps / signing keys.
- Runtime must not require `/home/gamedev/Darklord`, `darklord-dgi`, or `lunex-asset-library`. Import tools may use `LUNEX_DARKLORD_ROOT` / `LUNEX_DGI_ROOT`.
- When adding content: adapt → dedupe SHA256 → add to project → update `docs/manifests/game_assets.json` → commit/push → CI.
- Player DB backups are encrypted and stored **off** the current VPS (`docs/BACKUP.md`). DR docs: `docs/DISASTER_RECOVERY.md`.
- `DR01` blocks `BETA01`.

## Active priority
While AUDIT01 / DR01 are open, prefer portability and architecture over mass new locations. Keep LUNEX-AUDIT-001 in force.

All content tasks must satisfy docs/EDITOR.md (EDITOR-001). Do not replace native editable scenes with runtime-only construction. Preserve manual edits on reimport.

After every implementation iteration, including partial progress, update roadmap.json evidence via roadmap.py, STATUS.md, relevant task card and domain report. Regenerate ROAD.md and NEXT.md, validate, commit and push; verify remote HEAD and record CI availability. Do not mark incomplete acceptance as done.

World building follows docs/darklord/WORLD_DESIGN_002.md: hand-authored Godot locations using Darklord art; do not resume 1:1 Unity capital repair as the primary path.
Server remains authoritative; client is presentation + input. No offline fake-MMO as the beta.
