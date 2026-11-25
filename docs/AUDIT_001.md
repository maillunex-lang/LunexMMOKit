# LUNEX-AUDIT-001 — архитектурные исправления

Независимый аудит LunexMMOKit. Расширение контента приостановлено до закрытия критических FIX.
Конечная цель продукта: **Closed Beta 0.1.0** (`docs/BETA_001.md`), не City Preview APK.

## Проверка актуальности (Этап A)

| FIX | Было актуально? | Доказательство до фикса | Статус |
|-----|-----------------|-------------------------|--------|
| FIX-001 NavMesh | Да | `location_navigation.gd` — 4 вершины / 2 треугольника | **частично** |
| FIX-002 Пути VPS | Да | absolutes в eternity/capital/training | **исправлено** (play/training) |
| FIX-003 Undo place | Да | `_undo_place_by_name` по префиксу | **исправлено** |
| FIX-004 Owner protect | Частично | lock/meta; нет split generated | **частично** |
| FIX-005 Nav Undo | Да | `_bake_nav_undo_hint` warning | **исправлено** |
| FIX-006 Stable IDs | Да | kit+unix time | **частично** |
| FIX-007 Validator | Да | примитивные проверки | **частично** |
| FIX-008 Combat | Да | две системы боя | **частично** |
| FIX-009 Session | Да | QuestLog per-scene | **частично** |
| FIX-010 Mobile HUD | Да | клавиатура обязательна | **частично** |
| FIX-011 World Editor | Да | scaffold | **частично** |
| FIX-012 Integration | Да | data smokes | **частично** |
| FIX-013 GitHub/docs | Да | large geometry + CAPAPK goal | **частично** |
| FIX-014 Visual/CHAR | Да | audit open | **не исправлено** (после B0) |

## Git
- Branch: `cursor/lunex-audit-001-1cd3`
- WIP baseline: `d5590dc`
- Large `capital_geometry_v*` untracked via `.gitignore` (no force-push)
- Product goal retargeted: BETA01 Closed Beta 0.1.0

## Доказательства по FIX

### FIX-001 — частично
`location_navigation.gd` печёт NavMesh из `PARSED_GEOMETRY_STATIC_COLLIDERS`, исключает water layer, сохраняет `.tres` в editor, fallback plane если bake пустой. Hero: joystick отменяет auto-path, stuck repath. **Осталось:** интеграционный тест «сдвинул здание → bake → обход» на реальной сцене со StaticBody; bridges/stairs coverage depends on collider authoring.

### FIX-002 — исправлено (runtime)
Autoload `LunexAssets`; eternity_play / capital_play / training_scene без `/home/gamedev` absolutes; `tools/sync_studio_assets.py`; `docs/PORTABILITY.md`. Smoke: `OK no VPS path` ×3. Training tools may use `LUNEX_DARKLORD_ROOT` only.

### FIX-003 — исправлено
`library_dock.gd`: `add_do_reference(n)` + `_do_remove` конкретного узла (не prefix).

### FIX-004 — частично
`owner_protect.gd`; generators default `*_generated.tscn`; force требует confirm file. Owner.lock из редактора. **Осталось:** явный backup UI; гарантированный owner sidecar на каждом save в Godot без Tools menu.

### FIX-005 — исправлено
`_bake_nav_undo` восстанавливает предыдущий `NavigationMesh` + `location_revision` (+ resave `.tres`).

### FIX-006 — частично
`stable_ids.gd` typed UUID instance/type/kind. Editor place uses it. **Осталось:** миграция всех существующих NPC/portal meta; copy-handler в editor.

### FIX-007 — частично
Validator: surface gap, sunk, overlap, unreachable via nav path, missing mesh/material, empty polygons, unsafe spawn, duplicates; issues panel + select. **Осталось:** collision intersection precise; CI headless on full capital.

### FIX-008 — частично
`combat_runtime.gd` wraps timeline + preview_attack + hero_combat; prototype banner. Damage still applied early in hero_combat (local prototype). **Осталось:** defer damage to hit event; projectile flight; server C01.

### FIX-009 — частично
`GameSession` autoload + user:// persist; eternity_play sync on quest/portal/class. **Осталось:** full loop capital→ashen→ruins→capital smoke with reward anti-dupe.

### FIX-010 — частично
`ui/hud/game_hud.tscn` anchors + joystick + attack/skills/interact/portal/goto/vitals/quest. Keyboard optional. **Осталось:** graphics settings panel; multi-aspect device matrix screenshots.

### FIX-011 — частично
Categories/search, owner.lock tool, validate panel, nav undo. Owner RU doc `WORLD_EDITOR_OWNER.md`. **Осталось:** visual previews, true 3D drag-drop, material editor UI.

### FIX-012 — частично
`client/tests/integration_audit_smoke.gd` → `INTEGRATION_AUDIT_SMOKE_OK` (10 checks). **Осталось:** scenarios 4/7/8/11/13 as full playthroughs.

### FIX-013 — частично
Roadmap: AUDIT01 + BETA01; CAPAPK demoted; AGENTS/GAME/STATUS/ARCHITECTURE/PORTABILITY updated; geometry archives gitignored. **Осталось:** CI green confirmation after push.

### FIX-014 — не исправлено
Продолжение CHARACTER-AUDIT после закрытия критических FIX.

## Команда проверки
```bash
GODOT_SILENCE_ROOT_WARNING=1 godot --path client --headless --script res://tests/integration_audit_smoke.gd
```
