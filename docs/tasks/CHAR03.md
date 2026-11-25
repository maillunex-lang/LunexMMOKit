# CHAR03

Аудит крыльев: спина, масштаб, симметрия, материалы, анимации, клиппинг с телом и маунтом

## Acceptance
Контрольные скриншоты крыльев на 4 классах; ресурсы крепления; дефекты исправлены или зафиксированы

## Evidence
- Resources: `wing_wing_L_01/02.tres` with `socket_mode=marker` on `E_back2`
- Runtime: `Equipment.equip_accessory`
- Smoke: wing→E_back2 on all 4 classes
- Screens: `/home/gamedev/darklord-dgi/screens/wing-audit/{10001,20001,30001,40001}-wing-{back,close}.png`
- Defects logged: missing/white wing materials without Darklord material pack in portable capture; scale/clip vs mount pending
