# Character compatibility matrix

Status: open under CHARACTER-AUDIT-001 / CHAR10. Cells: `fail` / `partial` / `open` / `ok` (ok only after screenshot review).

Reviewed 2026-11-25 portable captures (`*-stand-tuned-*.png`, `wing-audit/*`) + `CHAR_ATTACHMENT_SMOKE_OK`.

| Class | Stand+weapon | Attack grip | Wing | Pet | Mount seat | Notes |
|---|---|---|---|---|---|---|
| 10001 Warrior | partial | partial | partial | open | open | Sword on `Bip001 R Hand`; stand front grip OK; hand closeup minor handle clip |
| 20001 Archer | partial | open | partial | open | open | Bow on `Bip001 L Hand`; stand front looks good |
| 30001 Mage | partial | open | partial | open | open | Staff on R Hand after reducing bad yaw; stand front OK |
| 40001 Assassin | partial | open | partial | open | open | Dual body1/2 on L/R hands; stand angles still wrong — EDIT01 |

Wings: `equip_accessory` → marker `E_back2` on all 4 classes (smoke OK). Capture without Darklord material pack shows white/untextured wing panels on some classes — materials/CHAR03 follow-up.

Screens: `/home/gamedev/darklord-dgi/screens/character-audit/` and `.../wing-audit/`.
