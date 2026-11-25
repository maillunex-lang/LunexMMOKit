# CHAR03

Аудит крыльев: спина, масштаб, симметрия, материалы, анимации, клиппинг с телом и маунтом

## Acceptance
Контрольные скриншоты крыльев на 4 классах; ресурсы крепления; дефекты исправлены или зафиксированы

## Evidence
- `wing_*.tres` marker `E_back2`; `Equipment.equip_accessory` + `prepare_accessory_visuals` hides untextured glow
- Studio/runtime share API; wing-audit screens ×4; `CHAR_MOUNT_PET_SMOKE_OK` visuals fixed
- Clip vs mount / glow texture path still partial
