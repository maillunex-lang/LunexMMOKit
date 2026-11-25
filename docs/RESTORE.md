# Восстановление базы на новом сервере

1. Поднимите Postgres (`docs/DEPLOY_VPS.md`)
2. Скопируйте файл бэкапа с внешнего хранилища
3. Проверьте SHA256
4. Восстановите в **изолированную** БД сначала:
```bash
export LUNEX_RESTORE_FILE=backups/lunex-pg-XXXX.sql.gz
export LUNEX_RESTORE_DB=lunex_restore
bash deploy/restore_postgres.sh
```
5. Проверьте `\dt` и выборку accounts/characters
6. Для боевого переключения согласуйте downtime и переименуйте БД / смените `LUNEX_DATABASE_URL`

Никогда не публикуйте дампы в GitHub.
