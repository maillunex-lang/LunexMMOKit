# UI01 — инвентаризация UI (используемый набор)

Полный каталог Darklord `Client/Assets/Resources/UI` (~142 MiB) **не** копируется в GitHub.

## Импортировано в LunexMMOKit (used)
| Ресурс | Путь | Назначение |
|---|---|---|
| Theme | `client/ui/theme/lunex_theme.tres` | Панели/кнопки HUD |
| Icons | `client/ui/theme/icons/*.png` | HP/MP/quest/attack + button fills |
| HUD scene | `client/ui/hud/game_hud.tscn` | Мобильный HUD |

## Источники для будущего выборочного импорта (не в git)
| Источник | Примечание |
|---|---|
| `Darklord/Client/Assets/Resources/UI/` | Атласы/рамки — брать только реально используемые |
| `…/UI/NewFont/simhei.ttf` (~4.5 MiB) | Кандидат шрифта; лицензия/подмножество — отдельно |
| `assets/studio` effects | Не UI; не смешивать с HUD |

## Покрытие
- Theme + базовые иконки: **да** (UI01)
- Полные оригинальные атласы Darklord: **нет** (запрет полного дампа)
- Нативные окна инвентаря/логина: **UI02**

## Правило DR
Новый UI-элемент → только used-файлы в `client/ui/` → манифест → commit/push.
