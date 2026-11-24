# KIMI-001 technical audit

Source private JSON: `/home/gamedev/darklord-dgi/kimi-audit.json`

Godot: `4.7.2-stable (official)`; audit failures: `0`

## Summary

| Actor | Label | Expected anims | Actual anims | Skeletons | Markers found | Missing required markers | Negative scale nodes | Materials | Textured mats | Weapon materials | Weapon textured | Attachment sample |
|---|---|---:|---:|---:|---|---|---:|---:|---:|---:|---:|---|
| 10001 | warrior | 24 | 24 | 1 | DM_R_Hand2, E_back2 | DM_R_Hand, DM_L_Hand, DM_L_Hand2, DM_R_wuqi01, DM_L_wuqi01, E_fire, E_back, Horse_E_back | 0 | 1 | 1 | 1 | 1 | DM_R_Hand2/moved |
| 20001 | archer | 29 | 29 | 1 | DM_R_Hand2, E_back2 | DM_R_Hand, DM_L_Hand, DM_L_Hand2, DM_R_wuqi01, DM_L_wuqi01, E_fire, E_back, Horse_E_back | 0 | 1 | 1 | 1 | 1 | DM_R_Hand2/moved |
| 30001 | mage | 23 | 23 | 1 | DM_R_Hand2, E_back2, E_fire | DM_R_Hand, DM_L_Hand, DM_L_Hand2, DM_R_wuqi01, DM_L_wuqi01, E_back, Horse_E_back | 0 | 1 | 1 | 1 | 1 | DM_R_Hand2/moved |
| 40001 | assassin | 28 | 28 | 1 | DM_L_Hand2, DM_R_Hand2, E_back2 | DM_R_Hand, DM_L_Hand, DM_R_wuqi01, DM_L_wuqi01, E_fire, E_back, Horse_E_back | 1 | 1 | 1 | 1 | 1 | DM_R_Hand2/moved |

## Detailed findings

### 10001 — warrior

- Weapon: `100011000`
- Bounds size: `[0.416332, 2.21181, 1.537339]`
- Skeleton `Skeleton3D` bones: 31
  - bone `Bip001 Spine` parent=0 rest_origin=[0.08982, -0.000141, 0.0]
  - bone `Bip001 Spine1` parent=1 rest_origin=[0.177386, -0.000185, 0.0]
  - bone `Bip001 L Hand` parent=14 rest_origin=[0.321543, 0.0, 0.0]
  - bone `Bip001 R Hand` parent=20 rest_origin=[0.321543, 0.0, 0.0]
- Markers:
  - `DM_R_Hand2` at `/root/warrior/DM_mount/Bip001/Bip001 Prop1/DM_R_Hand2` origin=[0.0, 0.0, -0.044839]
  - `E_back2` at `/root/warrior/DM_mount/Bip001/Skeleton3D/Bip001 Spine1/E_back2` origin=[0.214678, -0.363902, -2e-06]
- Animation categories:
  - player `AnimationPlayer`: {'attack': 4, 'death': 1, 'dodge': 0, 'hit': 2, 'idle': 1, 'other': 8, 'run': 4, 'skill': 4, 'victory': 0, 'walk': 0}
- Materials:
  - body `body` surface=0 mat=Material #2 tex=<embedded> 512x512 blend=0 transp=0
  - weapon `body` surface=0 mat=Material #26 tex=<embedded> 256x256 blend=0 transp=0
- Negative scale nodes:
- Weapon body children:
- Attachment sample:
  - marker `DM_R_Hand2` sampled=9 all_moved=True
    - attack001: moved=True weapon_origin=[-0.119418, 1.623414, -0.540024]
    - attack002: moved=True weapon_origin=[0.543723, 1.337175, 0.109792]
    - attack003: moved=True weapon_origin=[0.147315, 0.161863, 1.418021]
    - attack_run: moved=True weapon_origin=[-0.321582, 1.132013, 0.336164]
    - attack_stand: moved=True weapon_origin=[-0.344636, 1.170657, 0.174563]
    - skill001: moved=True weapon_origin=[0.22589, 1.237254, 0.869022]
    - skill002: moved=True weapon_origin=[-0.219931, 1.297544, 1.01576]
    - skill003: moved=True weapon_origin=[-0.507068, 1.26485, -8.550273]

### 20001 — archer

- Weapon: `200011000`
- Bounds size: `[0.655364, 2.158905, 1.151075]`
- Skeleton `Skeleton3D` bones: 40
  - bone `Bip001 Spine` parent=0 rest_origin=[0.08982, -0.000141, 0.0]
  - bone `Bip001 Spine1` parent=1 rest_origin=[0.177386, -0.000185, 0.0]
  - bone `Bip001 L Hand` parent=14 rest_origin=[0.321543, 0.0, 0.0]
  - bone `Bip001 R Hand` parent=20 rest_origin=[0.321543, 0.0, 0.0]
- Markers:
  - `DM_R_Hand2` at `/root/archer/DM_mount/Bip001/Bip001 Prop2/DM_R_Hand2` origin=[0.0, 0.0, 0.0]
  - `E_back2` at `/root/archer/DM_mount/Bip001/Skeleton3D/Bip001 Spine1/E_back2` origin=[0.214679, -0.363902, -2e-06]
- Animation categories:
  - player `AnimationPlayer`: {'attack': 5, 'death': 1, 'dodge': 0, 'hit': 2, 'idle': 2, 'other': 11, 'run': 4, 'skill': 4, 'victory': 0, 'walk': 0}
- Materials:
  - body `body` surface=0 mat=GJS_M_01 tex=<embedded> 512x512 blend=0 transp=0
  - weapon `body1` surface=0 mat=Material #34 tex=<embedded> 512x512 blend=0 transp=0
- Negative scale nodes:
- Weapon body children:
  - `body1` parent=DM_L_Hand origin=[0.0, 0.0, 0.0] quat=[0.737277, -0.67559, 0.0, 0.0] negative=False
- Attachment sample:
  - marker `DM_R_Hand2` sampled=10 all_moved=True
    - attack001: moved=True weapon_origin=[0.265795, 0.926513, 0.816632]
    - attack002: moved=True weapon_origin=[0.48009, 1.217643, 0.779767]
    - attack003: moved=True weapon_origin=[-0.158895, 1.445159, 0.771292]
    - attack004: moved=True weapon_origin=[-0.376632, 1.139374, 1.076803]
    - attack_run: moved=True weapon_origin=[0.985581, 1.401169, 0.111892]
    - attack_stand: moved=True weapon_origin=[-0.147123, 0.76265, 0.638276]
    - skill001: moved=True weapon_origin=[-0.015196, 1.466484, 0.772504]
    - skill002: moved=True weapon_origin=[0.185607, 2.908734, -0.675824]

### 30001 — mage

- Weapon: `300011000`
- Bounds size: `[0.851419, 2.102011, 1.007787]`
- Skeleton `Skeleton3D` bones: 41
  - bone `Bip001 Spine` parent=0 rest_origin=[0.071939, -0.000115, 0.0]
  - bone `Bip001 Spine1` parent=1 rest_origin=[0.144075, -0.00016, 0.0]
  - bone `Bip001 L Hand` parent=6 rest_origin=[0.335704, 0.0, 0.0]
  - bone `Bip001 R Hand` parent=12 rest_origin=[0.335704, 0.0, 0.0]
- Markers:
  - `DM_R_Hand2` at `/root/mage/DM_mount/Bip001/Bip001 Prop1/DM_R_Hand2` origin=[0.0, 0.0, 0.0]
  - `E_back2` at `/root/mage/DM_mount/Bip001/Skeleton3D/Bip001 Spine1/E_back2` origin=[0.131099, -0.202065, 0.0]
  - `E_fire` at `/root/mage/E_Root/E_fire` origin=[0.052661, -1.048439, 1.597521]
- Animation categories:
  - player `AnimationPlayer`: {'attack': 4, 'death': 1, 'dodge': 0, 'hit': 2, 'idle': 1, 'other': 7, 'run': 4, 'skill': 4, 'victory': 0, 'walk': 0}
- Materials:
  - body `body` surface=0 mat=Material #25 tex=<embedded> 512x512 blend=0 transp=4
  - weapon `body` surface=0 mat=Material #13 tex=<embedded> 256x256 blend=0 transp=0
- Negative scale nodes:
- Weapon body children:
- Attachment sample:
  - marker `DM_R_Hand2` sampled=9 all_moved=True
    - attack001: moved=True weapon_origin=[0.350085, 1.830864, 0.605393]
    - attack002: moved=True weapon_origin=[-0.372745, 1.57655, -0.656706]
    - attack003: moved=True weapon_origin=[0.503394, 2.158861, 0.06024]
    - attack_run: moved=True weapon_origin=[-0.245775, 1.414002, -0.519032]
    - attack_stand: moved=True weapon_origin=[-0.124617, 0.974597, 0.191873]
    - skill001: moved=True weapon_origin=[-0.325416, 2.075107, 0.104726]
    - skill002: moved=True weapon_origin=[-0.661837, 1.020248, -0.034538]
    - skill003: moved=True weapon_origin=[0.393322, 2.248078, -3.39123]

### 40001 — assassin

- Weapon: `400011000`
- Bounds size: `[0.519013, 2.232127, 1.018631]`
- Skeleton `Skeleton3D` bones: 44
  - bone `Bip001 Spine` parent=0 rest_origin=[0.071939, -0.000115, 0.0]
  - bone `Bip001 Spine1` parent=1 rest_origin=[0.144075, -0.00016, 0.0]
  - bone `Bip001 L Hand` parent=6 rest_origin=[0.335704, 0.0, 0.0]
  - bone `Bip001 R Hand` parent=12 rest_origin=[0.335704, 0.0, 0.0]
- Markers:
  - `DM_L_Hand2` at `/root/assassin/DM_mount/Bip001/Bip001 Prop2/DM_L_Hand2` origin=[0.0, 0.0, 0.0]
  - `DM_R_Hand2` at `/root/assassin/DM_mount/Bip001/Bip001 Prop1/DM_R_Hand2` origin=[0.0, 0.0, 0.0]
  - `E_back2` at `/root/assassin/DM_mount/Bip001/Skeleton3D/Bip001 Spine1/E_back2` origin=[0.272326, -0.262334, 0.0]
- Animation categories:
  - player `AnimationPlayer`: {'attack': 5, 'death': 1, 'dodge': 0, 'hit': 1, 'idle': 3, 'other': 10, 'run': 4, 'skill': 4, 'victory': 0, 'walk': 0}
- Materials:
  - body `body` surface=0 mat=Material #25 tex=<embedded> 512x512 blend=0 transp=0
  - weapon `body2` surface=0 mat=Material #26 tex=<embedded> 256x256 blend=0 transp=0
- Negative scale nodes:
  - `/root/assassin/DM_mount/Bip001/Skeleton3D/Bone041` det=-1.0 scale=[-1.0, -1.0, -1.0]
- Weapon body children:
  - `body1` parent=CK_W_wuqi_01 origin=[0.0, 0.0, 0.0] quat=[0.0, 0.0, 0.0, 1.0] negative=False
  - `body2` parent=CK_W_wuqi_01 origin=[0.0, 0.0, 0.0] quat=[0.0, 0.0, 0.0, 1.0] negative=False
- Attachment sample:
  - marker `DM_R_Hand2` sampled=10 all_moved=True
    - attack001: moved=True weapon_origin=[0.515146, 0.60963, -0.284079]
    - attack002: moved=True weapon_origin=[0.491967, 0.98129, 0.066307]
    - attack003: moved=True weapon_origin=[0.57818, 0.680523, 0.340099]
    - attack004: moved=True weapon_origin=[0.564038, 0.807786, -0.085693]
    - attack_run: moved=True weapon_origin=[-0.362342, 1.212868, -7.44466]
    - attack_stand: moved=True weapon_origin=[-0.026167, 1.054309, -6.943974]
    - skill001: moved=True weapon_origin=[0.10224, 1.03455, -7.669048]
    - skill002: moved=True weapon_origin=[-0.757661, 2.286483, -7.120508]
