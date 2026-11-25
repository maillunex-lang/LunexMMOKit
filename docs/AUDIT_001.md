# LUNEX-AUDIT-001 — архитектурные исправления

Конечная цель продукта: **Closed Beta 0.1.0** (`docs/BETA_001.md`).

## Статус FIX

| FIX | Статус | Доказательство |
|-----|--------|----------------|
| FIX-001 NavMesh | **исправлено** | Bake из StaticBody; `nav_obstacle_smoke` → `NAV_OBSTACLE_SMOKE_OK` (path around block, rebake) |
| FIX-002 Пути VPS | **исправлено** | `LunexAssets`; нет `/home/gamedev` в play/training |
| FIX-003 Undo place | **исправлено** | instance `add_do_reference` |
| FIX-004 Owner protect | **частично** | generated split + lock + timestamped backup on Write lock; confirm file for force |
| FIX-005 Nav Undo | **исправлено** | restore mesh + revision |
| FIX-006 Stable IDs | **частично** | typed UUID; Duplicate Selected tool mints new id |
| FIX-007 Validator | **частично** | richer checks + issue panel |
| FIX-008 Combat | **частично** | damage deferred to hit/projectile arrive via `combat_runtime`; still local prototype |
| FIX-009 Session | **частично** | GameSession + ashen/ruins sync; `SESSION_LOOP_SMOKE_OK` anti-dupe; server authority later |
| FIX-010 Mobile HUD | **частично** | `game_hud.tscn` + GFX Low/Med/High/Max stub |
| FIX-011 World Editor | **частично** | categories, backup, duplicate IDs; DnD/preview still thin |
| FIX-012 Integration | **частично** | `tools/run_audit_smokes.sh` → `ALL_AUDIT_SMOKES_OK` |
| FIX-013 GitHub/docs | **частично** | BETA roadmap; CI go+roadmap; geometry gitignored |
| FIX-014 Visual/CHAR | **не исправлено** | после закрытия B0 |

## Команды
```bash
bash tools/run_audit_smokes.sh
# INTEGRATION_AUDIT_SMOKE_OK / NAV_OBSTACLE_SMOKE_OK / SESSION_LOOP_SMOKE_OK / go test OK
```

## Server scaffold (путь к бете)
`server/cmd/lunexd` health + `migrations/001_init.sql` + compose без publish ports. Не объявлять онлайн-готовым.
