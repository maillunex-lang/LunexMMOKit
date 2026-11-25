# CHAR02

Аудит и исправление креплений оружия (руки, рукоять, угол, dual/bow/staff) по Unity

Status: **done**

## Acceptance
Оружие не отрывается и не клипит в stand/attack; правая/левая рука независимы; overrides в ресурсах

## Evidence
- Bone sockets; dual from Unity `CK_W_wuqi_01_pre` (body2 Z180, body1 scale.x=-1)
- `CHAR_ATTACHMENT_SMOKE_OK` includes attack-parent for all 4 classes
- Fine palm micro-tune remains via EDIT01 user:// overrides
