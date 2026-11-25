# Статус 25.11.2026
LunexMMOKit / Осколки вечности. Полный перенос Darklord в Godot 4, затем собственные изменения. EDITOR-001: нативные редактируемые сцены, ресурсы и сохранение ручных overrides. Оригиналы read-only.
## Реализовано
- Foundation: Godot 4.7.2, каркас, статический CI.
- CAP01–CAP03: столица с parent transforms, per-mesh basis, coord compare 320/320 ≤1m, close architecture renders.
- Attachment System (CHAR08): AttachmentOffset + bone sockets Bip001 R/L Hand; Studio «Крепления».
## В работе
- CAP04: 8 missing placements classified; water/crystal_mesh/walksurface in v8; water flat. Effect spiral, lighting, splat polish open.
- CHARACTER-AUDIT-001 / CHAR02: grip XYZ still partial after bone attach.
## Очередь
CAP04 -> CAP05 -> CAPAPK -> CAP06. Параллельно CHAR02–CHAR10 / EDIT01.
## Проверки
CI last pushes green. CAP03 closed with evidence. Private screens on VPS under darklord-dgi/screens.
