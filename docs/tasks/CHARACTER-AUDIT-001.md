# CHARACTER-AUDIT-001

Полный визуальный аудит сборки четырёх классов Darklord в Godot 4 против Unity

## Acceptance
Матрица дефектов по классам: скелет, материалы, ориентация, масштаб, анимации; контрольные скриншоты; без ложного done

## Evidence
- Matrix: `docs/darklord/CHARACTER_MATRIX.md` (honest partials)
- Portable smoke: `CHAR_ATTACHMENT_SMOKE_OK bone_sockets+wings+resources`
- Tuned captures: `screens/character-audit/*-tuned-*.png` + `screens/wing-audit/`
- Hip Prop1 false-socket fixed earlier; weapons on hand bones; grip XYZ still provisional (EDIT01)
- Not fully accepted — attack/wing materials/assassin angles remain
