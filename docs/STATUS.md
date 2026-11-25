# Статус 25.11.2026
LunexMMOKit / Осколки вечности. Полный перенос Darklord в Godot 4, затем собственные изменения. EDITOR-001: нативные редактируемые сцены, ресурсы и сохранение ручных overrides. Оригиналы read-only.
## Реализовано частично
- Foundation: Godot 4.7.2, каркас, статический CI. Go/PostgreSQL игровой сервер не готов.
- DGI: 1560 Lua источников, 20462 ресурса, 4 класса, 600 уровней, 104 клипа; формулы, оружие, аксессуары, VFX и аудио в прототипе.
- Character Studio APK 0.1.2 собран; установка новой версии и FPS не подтверждены.
- Пилот арены: 25/25 collision rays, navigation path, тесты движения 4 героев, виртуальный джойстик без tap-to-move.
- Столица V7: 320 размещений, 526 мешей; per-mesh basis (hierarchy ±90° → identity; changdeng glb_basis); dm04 fallback exact; 3 jz01 mesh source_missing. Architecture without effects 602×77×358. Visual acceptance NOT passed.
- Attachment System (CHAR08): AttachmentOffset .tres + library; socket_mode bone|marker; оружие на Bip001 R/L Hand (не Prop1/DM_*_Hand2); Studio «Крепления». Grip XYZ ещё не принят.
## Текущий этап
Параллельно: CAP03 (город, визуальная приёмка) и CHARACTER-AUDIT-001 / CHAR08 (персонажи и крепления). CAP03 не закрыт: кристалл/эффекты → CAP04, splat islands, missing jz01 meshes.
## Очередь
CAP03 -> CAP04 -> CAP05 -> CAPAPK -> CAP06. Параллельно CHARACTER-AUDIT-001 → CHAR02..CHAR07, CHAR08 → EDIT01, CHAR10. CAPAPK должен использовать Attachment System.
## Проверки
CAP01/02 диагностика завершена. CAP03 v7 screens на VPS (Xvfb). CI последних коммитов проверить после push. Оригиналы Darklord не удалялись.
