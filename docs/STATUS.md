# Статус на 25.11.2026
Проект LunexMMOKit / Осколки вечности. Полный перенос оригинала Darklord в Godot 4, затем собственные изменения. Оригиналы не изменяются. EDITOR-001 обязателен: нативные сцены и ресурсы, ручные overrides сохраняются.
## Фактический прогресс
- Foundation: каркас и статический CI; полноценный Go/PostgreSQL сервер не реализован.
- DGI: индекс, механики, исходные ID, четыре класса, 600 уровней, 104 анимации, прототипы оружия, VFX и аксессуаров. Полное покрытие не доказано.
- Character Studio: APK 0.1.2 собран, исправлена поза всадника; проверка новой версии на Android и FPS ожидается.
- Мир: пилот арены, 25/25 лучей коллизии, навигация и тесты движения четырёх героев.
- Столица: 328 размещений, 50 GLB, 20 материалов, 22 текстуры; 320 экземпляров в диагностической сцене. Первый рендер не прошёл визуальную приёмку. Сцена на VPS, сборщик в GitHub.
- UI и квесты: исходники обнаружены, полноценный перенос не выполнен.
## Следующая работа
CAP03: восстановить родительские трансформации и ориентацию, повторить рендер. Затем CAP04–06. Параллельные независимые направления: UI01, EDIT01, F03. Серверные и игровые этапы остаются в исходном roadmap.
## Ограничения
Статус done у CAP01/02 означает завершённую диагностику, не готовый город. Частичные результаты записаны в evidence; зависимости и критерии приёмки основных задач сохранены. CI последних коммитов не подтверждён. Не публиковать оригиналы или секреты.

## CAP03: последняя итерация
82cc4b4: v3, 320 экземпляров; 321 применение родительской трансформации включая кандидатов без меша; ширина bounds 1145.6 -> 602.2; рендер сохраняет дефекты ориентации и материалов.

## CAP03 orientation diagnostics
a326765: 145 exact bindings: 71 identity, 64 X -90 degrees, 10 other rotations. v4 no correction and v5 imported local transform both render but bounds height 587.9/823.9; neither accepted. v3 retained. Next inspect source mesh vertices and Unity local basis per asset, active state, terrain.

## Terrain prototype
b3cfd65: v6 terrain shader uses original RGB control and 3 splat textures, tiling 20/40/20; Godot build and render pass, visual parity and orientation remain unverified. Next isolate terrain and outlier meshes.

## Bounds diagnostics
7321bd6: audited 525 mesh instances; crystal effect height 587.86 dominates overview; shadow meshes also outliers. Diagnostic capture hides effects/shadows only in memory, no original or scene deletion. CAP03 visual acceptance pending.

## Isolated terrain
ed5799b: isolated main terrain 247.7 x 249.0, height 20.49; ShaderMaterial bound, screenshot shows separated textured patches rather than continuous ground. Need inspect missing geometry and original terrain topology; no visual acceptance.
