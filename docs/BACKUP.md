# Резервное копирование базы игроков

GitHub **не** хранит рабочие аккаунты/прогресс.

## Локальный дамп
```bash
export LUNEX_COMPOSE_PROJECT=lunexmmokit
bash deploy/backup_postgres.sh
```
Файлы в `backups/` (в `.gitignore`). Рядом `.sha256`.

## Шифрование
```bash
export LUNEX_BACKUP_PASSPHRASE='...'   # только вне git
bash deploy/backup_postgres.sh         # создаст .sql.gz.gpg
```

## Внешнее хранилище
Настройте rclone remote **не на текущем VPS как единственной копии**:
```bash
export LUNEX_BACKUP_RCLONE_REMOTE='b2:your-bucket/lunex'
bash deploy/backup_postgres.sh
```
Владелец должен подтвердить провайдера (B2/S3/другое). Агент не угадывает секреты.

## Секреты Android / TLS
Хранить отдельно (password manager / sealed store). Не в публичном репозитории.

## Расписание
Cron пример (ежедневно 03:15 UTC):
`15 3 * * * LUNEX_BACKUP_PASSPHRASE=... /opt/LunexMMOKit/deploy/backup_postgres.sh >> /var/log/lunex-backup.log 2>&1`
