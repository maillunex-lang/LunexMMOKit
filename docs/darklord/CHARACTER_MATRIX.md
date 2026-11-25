# Character compatibility matrix

Status: open under CHARACTER-AUDIT-001 / CHAR10. Cells: `fail` / `partial` / `open` / `ok` (ok only after screenshot review).

Reviewed 2026-11-25: portable captures + `CHAR_ATTACHMENT_SMOKE_OK` + `CHAR_MOUNT_PET_SMOKE_OK` + `EDIT01_ATTACHMENT_EDITOR_SMOKE_OK`.

| Class | Stand+weapon | Attack grip | Wing | Pet | Mount seat | Notes |
|---|---|---|---|---|---|---|
| 10001 Warrior | partial | partial | partial | partial | partial | Sword R Hand; wing glow hidden; mount Horse_E_back2; pet follow |
| 20001 Archer | partial | open | partial | partial | partial | Bow L Hand; accessories OK in smoke |
| 30001 Mage | partial | open | partial | partial | partial | Staff R Hand; accessories OK in smoke |
| 40001 Assassin | partial | open | partial | partial | partial | Dual angles EDIT01; accessories OK in smoke |

Screens: VPS `darklord-dgi/screens/character-audit/` + `wing-audit/` (set `LUNEX_CHAR_CAPTURE_OUT` for portable recapture).
