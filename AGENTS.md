# AI entrypoint
Read this file, then docs/NEXT.md. Do not scan the whole repo or Darklord.
Run python3 tools/roadmap.py next. Read only the task card, its listed domain document, and files in scope. Inspect dependencies only if necessary.
Do not treat a plan as implemented. Never mark done without evidence. Update task status, evidence and NEXT via roadmap.py; commit and push only after checks. Check CI; if unavailable record pending. Never expose credentials or private assets. Never delete original Darklord or modify other projects. No production migrations or deployment without approval. Stop on destructive changes, licensing uncertainty, or failed dependencies.


All content tasks must satisfy docs/EDITOR.md (EDITOR-001). Do not replace native editable scenes with runtime-only construction. Preserve manual edits on reimport.

After every implementation iteration, including partial progress, update roadmap.json evidence via roadmap.py, STATUS.md, relevant task card and domain report. Regenerate ROAD.md and NEXT.md, validate, commit and push; verify remote HEAD and record CI availability. Do not mark incomplete acceptance as done.

World building follows docs/darklord/WORLD_DESIGN_002.md: hand-authored Godot locations using Darklord art; do not resume 1:1 Unity capital repair as the primary path.
