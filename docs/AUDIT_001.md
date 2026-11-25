# LUNEX-AUDIT-001 — архитектурные исправления

Конечная цель: **Closed Beta 0.1.0** (`docs/BETA_001.md`).

## Статус FIX

| FIX | Статус | Доказательство |
|-----|--------|----------------|
| FIX-001 NavMesh | **исправлено** | `NAV_OBSTACLE_SMOKE_OK` |
| FIX-002 Пути VPS | **исправлено** | `LunexAssets`; CLIENT_CLEAN; DR01 |
| FIX-003 Undo place | **исправлено** | instance undo + `add_do_reference` |
| FIX-004 Owner protect | **исправлено** | generated split + lock + backup + confirm |
| FIX-005 Nav Undo | **исправлено** | mesh+revision restore |
| FIX-006 Stable IDs | **исправлено** | UUID + Duplicate + `migrate_legacy_tree` + editor menu; validator_smoke |
| FIX-007 Validator | **исправлено** | `VALIDATOR_SMOKE_OK` (no_spawn, duplicate_stable_id, migrate) |
| FIX-008 Combat | **частично** | deferred hit/projectile; **local prototype until C01** (ожидаемо) |
| FIX-009 Session | **исправлено** | GameSession + auth bridge; `SESSION_LOOP_SMOKE_OK`; N01 sessions |
| FIX-010 Mobile HUD | **исправлено** | `game_hud.tscn` + joystick/skills; GFX presets stub → P01 |
| FIX-011 World Editor | **частично** | Place near selection/camera + select for native 3D gizmo drag; full custom DnD → WE03 |
| FIX-012 Integration | **исправлено** | audit smokes + validator + a01 + AUTH/N01 |
| FIX-013 GitHub/docs | **исправлено** | BETA+DR docs; CI portability; Foundation green |
| FIX-014 Visual/CHAR | **отложено** | CHARACTER-AUDIT-001 / CHAR02… — не блокер закрытия AUDIT критического пути |

## Критический путь
FIX-001…010 и 012–013 закрыты (008 явно «частично до C01»). FIX-011/014 продолжаются в WE03/CHAR.

## Server path
F03/F04 + N01 sessions: register/login/logout/session/expire-test, two clients, reconnect.
Next after AUDIT: A01 evidence → N01 done → N02 when W02 ready.
