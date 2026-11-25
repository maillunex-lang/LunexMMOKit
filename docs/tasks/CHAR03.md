# CHAR03

Аудит крыльев: спина, масштаб, симметрия, материалы, анимации, клиппинг с телом и маунтом

Status: **done**

## Acceptance
Контрольные скриншоты крыльев на 4 классах; ресурсы крепления; дефекты исправлены или зафиксированы

## Evidence
- marker `E_back2` + slight back offset; `prepare_accessory_visuals` hides untextured glow
- Screens: char10-matrix/wing/*; wing-on-mount smoke OK
- Residual: perfect glow PBR / deep mount clip — logged, not blocking
