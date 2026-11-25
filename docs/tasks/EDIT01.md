# EDIT01

Визуальный редактор креплений в Character Studio / Asset Library

Status: **done**

## Acceptance
Выбор героя/оружия/крыльев/питомца/маунта; орбита камера; play/pause анимаций; XYZ pos/rot/scale; независимые руки; посадка всадника; save/reset в AttachmentOffset ресурсы; те же ресурсы использует runtime

## Evidence
- Studio «Крепления» panel: XYZ + socket_mode + Dual L/R + axis gizmo
- save/reset → `user://attachments/overrides`; runtime `AttachmentLibrary` reads same
- `EDIT01_ATTACHMENT_EDITOR_SMOKE_OK`
