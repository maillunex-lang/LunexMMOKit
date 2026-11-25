# CHAR04

Аудит маунтов: посадка, масштаб, синхрон анимаций, mount/dismount, оружие и крылья верхом

## Acceptance
Все доступные маунты × 4 класса без зависания/проваливания; seat offsets в ресурсах

## Evidence
- `Equipment.mount_actor` / `dismount_actor` → `Horse_E_back2` via `mount_seat_*.tres`
- Studio uses same API; `CHAR_MOUNT_PET_SMOKE_OK` for mount_001 × 4 classes
- Sync of weapon/wing while mounted and mount_002 visual scale still open
