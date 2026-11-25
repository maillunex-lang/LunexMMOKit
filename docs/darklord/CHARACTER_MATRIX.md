# Character compatibility matrix

Status: closed under CHARACTER-AUDIT-001 / CHAR10 (residual costume gaps → CHAR06). Cells: `fail` / `partial` / `open` / `ok`.

Reviewed 2026-11-25: `CHAR10_CAPTURE_OK 40` + wing/mount sets; Unity dual TRS from `CK_W_wuqi_01_pre.prefab`; smokes green.

| Class | Stand+weapon | Attack grip | Wing | Pet | Mount seat | Notes |
|---|---|---|---|---|---|---|
| 10001 Warrior | ok | ok | partial | partial | partial | Identity hand; attack keeps parent; wing glow sanitized |
| 20001 Archer | ok | ok | partial | partial | partial | L Hand + Z90; attack-parent OK |
| 30001 Mage | ok | ok | partial | partial | partial | Identity staff; attack-parent OK |
| 40001 Assassin | ok | ok | partial | partial | partial | Unity body2 Z180 / body1 scale.x=-1 |

Wing/pet/mount: attach+smoke OK; visual polish (scale/VFX/clip) residual, not blockers for CHAR10 matrix.
Screens: `darklord-dgi/screens/char10-matrix/` (+ `wing/`, `mount/`). Recapture: `LUNEX_CHAR_CAPTURE_OUT=... xvfb-run godot --path client ... char10_matrix_capture.gd`.
