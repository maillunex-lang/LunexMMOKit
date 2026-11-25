# UI — оригинальный Darklord look (UI01/UI02)

## Принцип
Меню, HUD, кнопки, рамки и иконки берутся из **оригинальных атласов Darklord**, не из процедурных заглушек.

Полный каталог `Client/Assets/Atlas` (~143 MiB) в GitHub **не** копируется. В репозитории — **используемый набор** для Closed Beta HUD/логин/классы/инвентарь.

## Импортировано (`client/ui/darklord/`)
| Атлас | Назначение |
|---|---|
| UICommon / UICommon2 | Рамки окон, кнопки, табы, EXP |
| UIMain / UIMain2 | Боевой HUD, джойстик, скиллы, сумка |
| UIMainTips | Подсказки |
| Login | Логин / выбор роли |
| NewHP / FubenFight | Полосы HP/MP |
| UISkill / skillicon | Иконки умений |
| Item / ItemIco | Слоты/иконки предметов |
| HeadIcons / HeroIco / Chapter / EquipIco | Портреты/экип (для окон) |
| fonts/simhei.ttf + bitmap | CJK HUD-шрифт |

Инструмент: `python3 tools/ui/import_darklord_ui.py` (читает только VPS Darklord; runtime использует `res://ui/darklord/...`).

## Сцены
| Сцена | Скин |
|---|---|
| `ui/hud/game_hud.tscn` | Darklord HP/MP/EXP, skill icons, joystick sprites |
| `ui/menus/auth_panel.tscn` | Login atlas |
| `ui/menus/class_select_panel.tscn` | font_role1..4 |
| `ui/menus/inventory_panel.tscn` | frame1 + item slots |
| `ui/theme/darklord_skin.gd` | Theme builder |

## Не импортировано
Prefabs Unity (~135 MiB), лишние Business/Arena атласы, полный ItemIco2–4 и т.п. — добавлять по мере появления окна в игре (правило DR).
