# WORLD-EDITOR-003 — Lunex World Editor (Godot 4 EditorPlugin)

Утверждено к постановке в дорожную карту. Цель: владелец проекта редактирует игровые локации на Windows в нативном редакторе Godot 4 без программирования.

Совместимость: [EDITOR-001](EDITOR.md), [WORLD-DESIGN-002](darklord/WORLD_DESIGN_002.md). Не заменяет Character Studio (крепления) и не отменяет ручные `.tscn`/`.tres` как deliverable.

## Продукт

Нативный `EditorPlugin` в `client/addons/lunex_world_editor/`. Работает внутри Godot Editor (Windows primary). Не runtime-only конструктор и не отдельное Electron/Unity-приложение.

Владелец открывает локацию (например `eternity_capital.tscn`), правит сцену инструментами плагина, сохраняет. Повторный запуск генераторов `tools/world/build_*.gd` **не перезаписывает** ручные правки.

## Функциональные требования

### Библиотека и размещение
- Визуальная библиотека китов из `res://world/library/kits/` (и каталог ENVIRONMENT_LIBRARY): превью, категории, поиск по имени/source ID.
- Drag-and-drop кита в 3D viewport → инстанс PackedScene.
- Move / rotate / scale через стандартные gizmos Godot + при необходимости numeric inspector.
- Snap-to-ground: луч вниз по collision/terrain, выравнивание по нормали (опционально).

### Материалы
- Редактирование материалов/текстур инстанса (albedo, UV scale, roughness) без правки исходного GLB.
- Overrides хранятся на узле/в owner overlay, не в generated import.

### Геймплейные маркеры
Размещение и инспекция сущностей с **стабильными ID** (`stable_id` meta / Resource field):
- NPC (`npc_role`, `stable_id`)
- монстры (`monster_id`, `spawn_group`)
- порталы (`portal_id`, `target_location`)
- точки появления (`PlayerSpawn`, `respawn_id`)

Квестовые цели ссылаются на `stable_id`, не на путь узла и не на мировые координаты. Перемещение NPC не ломает квесты.

### Коллизии и навигация
- При изменении/добавлении/удалении объекта — обновление коллизий инстанса (kit StaticBody или auto box).
- Кнопка **Bake NavigationMesh** для локации (NavigationRegion3D).
- Автобег / auto-path: **только** динамический `NavigationServer3D.map_get_path` по актуальному NavMesh. Запрещены фиксированные цепочки координат как основной способ маршрута.
- Клиентский NavMesh и серверный nav-граф локации согласованы через общий export (`location_nav` / shared contract). Сервер авторитетен для финальной позиции; клиент предсказывает по тому же bake-снимку версии.

### Валидаторы (кнопка / CI-скрипт)
1. Reachability: все важные NPC и квестовые точки достижимы из PlayerSpawn по NavMesh.
2. Auto-path: контрольные маршруты (spawn→NPC, spawn→portal) строятся успешно.
3. Floating: объекты без опоры на землю (зазор > порога).
4. Intersections: грубые AABB-пересечения зданий/коллизий.
5. Unreachable pockets: зоны nav, отрезанные от spawn.

### Undo/Redo
Использовать `EditorUndoRedoManager` Godot для всех операций плагина (place, transform, delete, material override, marker edits).

## Слои данных (анти-overwrite)

```
generated/   — выход генераторов (можно перезаписывать)
owner/       — ручные правки владельца (НИКОГДА не трогать генератором)
runtime/     — собранная сцена = generated ⊕ owner overlay
shared/      — экспорт для сервера (IDs, spawns, nav version)
```

Контракт генераторов WD02 (`build_eternity_capital.gd` и др.):
1. Пишут только в `*_generated.tscn` или требуют явный `--force-overwrite`.
2. Если рядом есть `*.owner.lock` / meta `owner_edited=true` на корне — отказ без force.
3. Owner overlay (`*.owner.tscn` или `LocationOverrides.tres`) мержится при bake/export, не затирается.
4. Provenance: каждый инстанс хранит `kit_id`, `source_id`, `stable_id`.

## Согласование клиент ↔ сервер

| Данные | Клиент | Сервер |
|--------|--------|--------|
| Геометрия/киты | `.tscn` + meshes | не нужны полностью; collision/nav proxy |
| Spawns / NPC / portals | маркеры в сцене | таблицы по `stable_id` |
| Nav | NavigationMesh bake | nav graph / walkable export той же версии |
| Версия локации | `location_revision` | reject устаревший клиент |

Авторитетное движение (N02) опирается на серверный nav; клиентский bake должен совпадать по revision.

## Acceptance (WE03)

1. Плагин включается в Project Settings → Plugins на Windows Godot 4.7.x.
2. Из dock библиотеки перетащить kit → объект в сцене; move/rotate/scale; snap-to-ground.
3. Сменить материал инстанса, сохранить, reopen — override на месте.
4. Поставить NPC/portal/spawn со `stable_id`; квестовая ссылка переживает перемещение NPC.
5. Сдвинуть здание → обновить коллизии → Bake NavMesh → герой (eternity_play / walk test) обходит препятствие по NavMesh (не по записанным точкам).
6. Валидаторы ловят floating / unreachable quest NPC.
7. Undo/Redo восстанавливает place/transform.
8. Повторный `build_eternity_capital.gd` без force **не** затирает owner overlay.
9. Export shared location data содержит `stable_id` + `location_revision`.

## Не в scope WE03
- Полноценный квестовый граф-редактор (отдельная задача).
- Онлайн collaborative editing.
- Замена EDITOR-001 Character attachment UI (EDIT01).
- Массовая генерация всех локаций до приёмки WD02.

## Связанные задачи
- WD02 — библиотека китов и столица (входные данные редактора).
- EDIT02 — регрессия EDITOR-001 + WE03 portability.
- W01/W02 — протяжённые зоны и переходы (потребители editor export).
- N02 — авторитетное движение по согласованному nav.
- CAPAPK — playable APK после визуальной приёмки столицы.
