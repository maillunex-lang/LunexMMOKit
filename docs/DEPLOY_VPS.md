# Развёртывание на новом Ubuntu VPS

Не привязано к IP текущего сервера.

## Требования
- Ubuntu 22.04+ (рекомендуется)
- Docker + Compose plugin
- Домен (опционально, для HTTPS)
- ≥4 ГБ RAM для сервера беты; Android-сборки лучше на отдельной машине/CI

## Шаги
1. `git clone https://github.com/maillunex-lang/LunexMMOKit.git && cd LunexMMOKit`
2. `sudo mkdir -p /etc/lunex && sudo cp deploy/env.example /etc/lunex/lunex.env`
3. Отредактируйте `/etc/lunex/lunex.env` (пароль БД, домен)
4. `sudo bash deploy/install_vps.sh`
5. Проверка: `docker compose -p lunexmmokit ps` и health внутри сети (см. `tools/verify_auth_http.sh`)
6. Поставьте reverse proxy (Caddy/Nginx) на `LUNEX_DOMAIN` → `127.0.0.1:18080` если опубликовали порт на loopback
7. Восстановите базу игроков из внешнего бэкапа: `docs/RESTORE.md`

## Android APK
На VPS с Android SDK / или на CI:
```bash
godot --path client --headless --export-debug "Android City" build/LunexCityPreview.apk
```
Ключи подписи — только во внешнем секрет-хранилище, не в git.

## Изоляция
Compose-проект `lunexmmokit` не должен пересекаться с чужими контейнерами на том же хосте.
