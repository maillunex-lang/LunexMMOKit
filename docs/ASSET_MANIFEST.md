# Манифест игровых ресурсов

Машина: `docs/manifests/game_assets.json`

Сборка:
```bash
python3 tools/assets/build_game_manifest.py
python3 tools/assets/verify_game_manifest.py
```

## Политика
- Только **используемые** ресурсы нашей игры
- Одна копия модели/текстуры → много сцен ссылаются на неё (`client/world/library`, `assets/studio`)
- Оригинальный Darklord / полная библиотека — вне git
- При добавлении нового контента: адаптировать → проверить дубликаты SHA256 → манифест → commit/push → CI

## Поля
id, category, path, size, sha256, version, source, provenance, dependencies, purpose, license_status
