# LUNEX-AUDIT-001 — архитектурные исправления

Конечная цель: **Closed Beta 0.1.0** (`docs/BETA_001.md`).

## Статус FIX

| FIX | Статус | Доказательство |
|-----|--------|----------------|
| FIX-001 NavMesh | **исправлено** | `NAV_OBSTACLE_SMOKE_OK` |
| FIX-002 Пути VPS | **исправлено** | `LunexAssets`; нет VPS paths в play |
| FIX-003 Undo place | **исправлено** | instance undo |
| FIX-004 Owner protect | **исправлено** | generated split + lock + backup + confirm; ashen/ruins builders |
| FIX-005 Nav Undo | **исправлено** | mesh+revision restore |
| FIX-006 Stable IDs | **частично** | UUID + Duplicate tool; legacy meta migration incomplete |
| FIX-007 Validator | **частично** | richer checks; more CI cases TBD |
| FIX-008 Combat | **частично** | deferred hit/projectile; local prototype until C01 |
| FIX-009 Session | **частично** | `SESSION_LOOP_SMOKE_OK`; server auth now exists (F04) |
| FIX-010 Mobile HUD | **частично** | game_hud + GFX stub |
| FIX-011 World Editor | **частично** | Place+preview+categories; full 3D DnD TBD |
| FIX-012 Integration | **частично** | audit smokes + AUTH_HTTP + postgres migrate |
| FIX-013 GitHub/docs | **частично** | BETA roadmap; CI expanded |
| FIX-014 Visual/CHAR | **не исправлено** | после B0/CHAR tasks |

## Server path
F03/F04 done: versions, debug APK artifact, lunexd+Postgres+auth HTTP.
Next: A01 → N01 (sessions/reconnect against lunexd).
