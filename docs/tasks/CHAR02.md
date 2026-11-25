# CHAR02

Аудит и исправление креплений оружия (руки, рукоять, угол, dual/bow/staff) по Unity

## Acceptance
Оружие не отрывается и не клипит в stand/attack; правая/левая рука независимы; overrides в ресурсах

## Evidence
Bone sockets `Bip001 R/L Hand`; per-weapon `AttachmentOffset` .tres tuned from portable captures; archer L Hand; dual body1/2; smoke OK. Assassin stand angles + attack grips still partial — continue via EDIT01 gizmo. Screens `*-stand-tuned-*`.
