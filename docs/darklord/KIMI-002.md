# KIMI-002 weapon attachment system

## Source-derived rule

Targeted source files:

- `/home/gamedev/Darklord/Client/Assets/Scripts/Core/Scene/GameObject/ActorLoader.cs`
- `/home/gamedev/Darklord/Client/Assets/Scripts/Core/Actor/CActorObject.cs`
- `/home/gamedev/Darklord/Client/Assets/Scripts/UI/Role/RoleModelShow.cs`
- `/home/gamedev/Darklord/Client/Assets/Resources/Lua/Data/t_model.lua.txt`
- four weapon prefabs under `/home/gamedev/Darklord/Client/Assets/Resources/Animation/player/*/*_01/*_01_pre.prefab`

Facts extracted:

1. `ActorLoader.GetWeaponModelID` selects the weapon model by profession through `vmesh1..vmesh4` and never applies the display transform columns from `t_model.lua.txt`.
2. `ActorLoader.LoadModelObject` only instantiates the configured prefab. It does not apply position or rotation from `t_model.lua.txt`.
3. `CActorObject.ChangeWeapon` attaches the selected weapon object to `DM_R_Hand` and explicitly resets local position, rotation and scale to identity for normal classes.
4. Assassin special case extracts `DM_R_wuqi01` and `DM_L_wuqi01`, parents them to `DM_R_Hand` and `DM_L_Hand`, and also resets those containers to identity. The original empty prefab root is then destroyed.
5. Assassin prefab child transforms that must survive the reset are:
   - `body2` under `DM_R_wuqi01`: rotation quaternion approximately `{x=0.0000009685756, y=-0.00000028312215, z=1, w=-0.000000043711115}`, scale one.
   - `body1` under `DM_L_wuqi01`: rotation near identity, scale `{x=-1, y=1.0000004, z=1.0000001}`.
6. Exported Godot GLBs contain the animated markers `DM_R_Hand2` and, for assassin, `DM_L_Hand2`. The original unsuffixed socket names are absent from the generated GLBs, so the system uses the unique suffixed markers as the runtime sockets.

## Implementation

`client/actors/equipment.gd` now exposes a reusable spec-driven API:

- `darklord_base_weapon_spec(weapon_id)` returns the base weapon attachment rule.
- `equip_weapon(actor, item, weapon_id)` supports single-hand and dual attachment.
- `unequip_weapon(handle)` restores prior parents and transforms.
- Legacy helpers `attach`, `attach_marker` and `attach_dual` remain available.

Current base specs:

| Class | Weapon ID | Mode | Right socket | Left socket | Child transforms |
|---|---|---|---|---|---|
| warrior | 100011000 | single | `DM_R_Hand2` | none | exported GLB root identity |
| archer | 200011000 | single | `DM_R_Hand2` | none | exported GLB root identity |
| mage | 300011000 | single | `DM_R_Hand2` | none | exported GLB root identity |
| assassin | 400011000 | dual | `DM_R_Hand2` | `DM_L_Hand2` | `body2` and `body1` use the source prefab child transforms above |

## Verification so far

Command:

```bash
LIBGL_ALWAYS_SOFTWARE=1 /usr/local/bin/godot --headless --path /tmp/lunex-test-project --script res://test_equipment.gd
```

Result:

```text
TEST 10001 attached=true transform_ok=true right=DM_R_Hand2 left= sampled=9 moved=true
TEST 20001 attached=true transform_ok=true right=DM_R_Hand2 left= sampled=10 moved=true
TEST 30001 attached=true transform_ok=true right=DM_R_Hand2 left= sampled=9 moved=true
TEST 40001 attached=true transform_ok=true right=DM_R_Hand2 left=DM_L_Hand2 sampled=10 moved=true
```

## Not closed yet

This is not visual grip approval. Rendered close-ups are still required in KIMI-009 for stance, run and combat animations, especially archer bow orientation and assassin blade orientation.
