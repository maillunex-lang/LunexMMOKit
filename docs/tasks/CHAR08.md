# CHAR08

Единый Attachment System: редактируемые ресурсы Position/Rotation/Scale/Socket/Class/IDs

Status: **done**

## Acceptance
Нет жёстких per-item поправок в игровом коде; общие и override ресурсы; runtime читает те же .tres

## Evidence
AttachmentOffset + AttachmentLibrary; 11 default .tres (weapons/wings/pets/mount seats); `equipment.equip_weapon` / `equip_accessory` read resources only; Studio «Крепления» panel save/reset to `user://` overrides; `CHAR_ATTACHMENT_SMOKE_OK`.
