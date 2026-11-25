# Архитектура
Клиент Godot 4.x, Android landscape (цель бета: устройства ≥6 ГБ ОЗУ).
**Сервер авторитетный** (обязательно для Closed Beta 0.1.0): авторизация, позиции, бой, урон, HP, XP, предметы, валюта, квесты, лут, монстры, переходы локаций.
Клиент: отображение, ввод, VFX/SFX. Локальный slice — прототип до N02/C01, не продукт.

Игровые данные отделены от логики. Исходники Darklord — только чтение (импорт-инструменты).
Адаптированные runtime-ассеты: `res://` / `assets/studio` / `client/world/library` / `user://` cache + `docs/manifests/game_assets.json` (не абсолютные пути VPS в runtime). DR: `docs/DISASTER_RECOVERY.md`.

## Модули
client/core: жизненный цикл, AssetPaths, GameSession; world: зоны; actors; combat (визуал поверх серверных событий); network; ui (мобильный HUD .tscn); content.
server: Go симуляция, PostgreSQL, HTTPS/WebSocket. shared: контракты. tools: импорт. tests: интеграционные сценарии.
Админка: O01. Изолированный compose; не трогать чужие сервисы VPS.

## Выбранный стек
Go, PostgreSQL, HTTPS/WebSocket, Docker Compose. Версии закрепить в F03. Не публиковать порты без согласования.

## Native editor contract
See [EDITOR-001](EDITOR.md). Owner edits на Windows в Godot; generated ≠ owner scenes. Server validates exported data.

## Product
See [BETA-001](BETA_001.md). End goal is online Closed Beta, not City Preview APK.
