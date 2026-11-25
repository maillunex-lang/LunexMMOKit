# Установка и редактирование на Windows (без программирования)

## Что нужно
1. GitHub-аккаунт с доступом к `maillunex-lang/LunexMMOKit`
2. Godot **4.7.x** (тот же major/minor, что в `docs/VERSIONS.md`)
3. ~2 ГБ свободного места для клона

## Шаги
1. Скачайте репозиторий: Code → Download ZIP **или** `git clone https://github.com/maillunex-lang/LunexMMOKit.git`
2. Откройте Godot → **Import** → укажите папку `LunexMMOKit/client` (файл `project.godot`)
3. Дождитесь импорта (появятся `.import` рядом с текстурами/GLB)
4. Включите плагин: Project → Project Settings → Plugins → **Lunex World Editor**
5. Откройте сцену `world/locations/eternity_capital/eternity_capital.tscn` или `eternity_play.tscn`
6. Запуск игры: F5 (главная сцена — `eternity_play`)

## Редактирование города
См. `docs/WORLD_EDITOR_OWNER.md`: киты слева, Place / двойной клик, Ctrl+S, Tools → Lunex: Write owner.lock, Bake NavigationMesh, Validate.

## Если чего-то нет
- Запустите проверку: на машине с Python `python tools/assets/verify_game_manifest.py`
- Не скачивайте оригинальный Darklord для обычной игры — всё нужное уже в `assets/studio` и `client/world/library`
- Не открывайте `tools/`-скрипты исследования Unity как «игру»

## Чего нельзя
- Не кладите пароли и keystore в проект
- Не удаляйте `*.owner.lock` без бэкапа сцены
