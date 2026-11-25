# CHAR05

Аудит питомцев: масштаб, анимации, VFX, follow, отсутствие проваливания

## Acceptance
Питомцы корректно следуют; матрица совместимости; ресурсы offsets

## Evidence
- `pet_follow.gd` + `pet_XN_pet_*.tres` lateral offsets
- `CHAR_MOUNT_PET_SMOKE_OK` follow moves with actor for 4 classes
- VFX/scale polish and ground collision still open
