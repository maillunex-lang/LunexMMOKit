# Статус 25.11.2026
Цель: Closed Beta 0.1.0. Активно: **DR01** (автономия от VPS) + AUDIT residuals.
## DR сегодня
- `.gitignore` разрешает used GLB в `assets/studio` и `client/world/library/meshes`
- Манифест `docs/manifests/game_assets.json` + verify
- `deploy/` install/backup/restore; docs Windows/VPS/DR
- BETA01 зависит от DR01
## Ограничения
- Полный Windows UI / чистый VPS install — не прогнаны на этой машине (см. recovery smoke limitation)
- FIX-014 visual и полный набор звуков/VFX ещё не все в used-library
- Внешний rclone/B2 для бэкапов требует согласования владельца
