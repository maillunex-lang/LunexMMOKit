# CHARACTER-AUDIT — Darklord visual assembly in Godot 4

Source of truth: Unity Darklord under `/home/gamedev/Darklord` (read-only). Runtime preview: Lunex Character Studio (`client/scenes/training`, private exports in `/home/gamedev/darklord-dgi/exports`). EDITOR-001: attachment data must live in editable Godot resources shared by Studio and game.

## Class map
| Studio GLB | Weapon ID | Role (HEROES.md / models) |
|---|---|---|
| 10001.glb | 100011000 | Warrior (sword) |
| 20001.glb | 200011000 | Archer (bow) |
| 30001.glb | 300011000 | Mage (staff) |
| 40001.glb | 400011000 | Assassin (dual blades) |

Sockets observed in GLB markers: `DM_R_Hand2`, `DM_L_Hand2`, `E_back2`/`E_back`, `Horse_E_back2`/`Horse_E_back`, `E_fire`. Unity `CActorObject.ChangeWeapon` resets weapon container local TRS to identity on the hand socket; assassin splits `DM_R_wuqi01`/`DM_L_wuqi01` with prefab child basis (body2 Z-180, body1 negative X scale).

## Baseline defects (not accepted)
- Weapon grip screens (`*-stand-grip.png`): clipping into torso/hip for archer, mage, assassin; warrior grip framing incomplete. Dual-blade idle still offset per ASSEMBLY.md.
- Hardcoded dual transforms in `client/actors/equipment.gd` (`_right_blade_transform` / `_left_blade_transform`) violate resource-driven Attachment System.
- Wings/pets/mounts toggled in Studio; seat pose, wing scale, pet follow and rider sync not visually signed off. Mount fix screens exist (`mount-fix-*.png`) but per-anim/per-class matrix incomplete.
- `rig_visual_verified: false` on all four export JSON manifests.
- Body materials/shader adapted; costume part gaps (warrior waist) need audit CHAR06.

## Attachment System
- Resource: `AttachmentOffset` — position, rotation_degrees, scale, socket, class_id, model_id, equipment_id, mount_id, animation_overrides, notes.
- Library: `res://content/attachments/` defaults + `user://attachments/overrides/` for editor saves.
- Runtime and editor must resolve the same resources; no parallel config.

## Screenshot protocol
Xvfb + Godot Compatibility/llvmpipe. Angles: front, back, side, 45°, hand close-up, wing root close-up, mount seat close-up. Store under `/home/gamedev/darklord-dgi/screens/character-audit/`. Visual inspection required; log-only passes are insufficient.

## Roadmap
CHARACTER-AUDIT-001 → CHAR02..CHAR07 parallelizable after inventory; CHAR08 Attachment System; EDIT01 editor; CHAR10 matrix. CAPAPK must consume Attachment System for city preview heroes.

## Socket finding (CHAR02/CHAR08)
`DM_R_Hand2` / `DM_L_Hand2` live under `Bip001 Prop1` (animated Node3D). In stand they sit near the hip, not the palm — parenting weapons there makes swords float at the waist. Skeleton bones `Bip001 R Hand` / `Bip001 L Hand` are the correct runtime sockets. AttachmentOffset now has `socket_mode` (`bone`|`marker`); defaults use bones. Grip XYZ still needs visual tuning via Studio editor (EDIT01).
