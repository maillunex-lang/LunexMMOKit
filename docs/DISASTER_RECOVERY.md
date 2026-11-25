# DISASTER-RECOVERY-001

Потеря текущего VPS **не** должна означать потерю разработки «Осколки вечности».

## Принципы
1. Один репозиторий: `https://github.com/maillunex-lang/LunexMMOKit`
2. Одна библиотека **используемых** игровых ресурсов в репо (`assets/studio`, `client/world/library`, …)
3. Оригинальный Darklord / полная DGI / полная Lunex Asset Library — **не** в GitHub и не runtime-зависимость
4. База игроков и секреты — **отдельные** зашифрованные бэкапы вне VPS
5. Не плодить копии проекта на диске

## Быстрое восстановление (новый VPS)
См. `docs/DEPLOY_VPS.md` и `docs/RESTORE.md`.

## Windows-редактирование
См. `docs/INSTALL_WINDOWS.md`.

## Манифест
`docs/manifests/game_assets.json` + `python3 tools/assets/verify_game_manifest.py`

## Изолированная проверка
`bash tools/recovery/isolated_recovery_smoke.sh` — без доступа к Darklord/DGI/asset-library; манифест + audit smokes + Postgres migrate.

## Этапы
DR-01…DR-09 — карточка `docs/tasks/DR01.md`, дорожная карта `DR01` (блокер BETA01).

## Evidence (2026-11-25)
| Метрика | Значение |
|---|---|
| Used assets (manifest) | 359 файлов / ~124.6 MiB |
| Дубликаты SHA256 (группы) | 12 (в основном алиасы текстур hash-name ↔ friendly) |
| Library meshes GLB | ≥33 в `client/world/library/meshes` |
| Runtime client → VPS paths | 0 (CLIENT_CLEAN) |
| `ISOLATED_RECOVERY_SMOKE_OK` | да (манифест + Godot smokes + migrate) |
| CI job `portability` | foundation.yml |

## Ограничения (явно)
1. **Windows Godot UI** и **чистая bare-metal VPS install** не прогонялись на этой машине — только скрипты/доки + isolated smoke.
2. Полный набор звуков/VFX/персонажей для беты ещё не весь в used-library (расширяется по правилу «добавил контент → в манифест»).
3. Внешнее хранилище бэкапов (rclone/B2/S3) требует согласования учётных данных владельца; скрипты готовы, ключи не в репо.
4. Инструменты импорта в `tools/dgi/` могут ссылаться на `/home/gamedev/...` — это **только** для конвертации оригиналов, не runtime.
5. 12 групп дубликатов SHA256 оставлены как совместимые алиасы текстур; удаление — отдельная чистка после проверки ссылок сцен.
