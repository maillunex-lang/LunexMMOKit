# Heroes — Darklord baseline
Four source classes: 1 Mage FS_W_01, 2 Archer GJS_M_01, 3 Warrior ZS_M_01, 4 Assassin CK_W_01. Source PlayerinfoConfig.lua and t_playerinfo.lua.txt; archer name inferred from client icon and model family. Preserve source IDs, sex, skill IDs, equipment and class growth. See darklord/classes.json for all source FBX animation paths in four class folders. 145 animation files total; shared rigs and individual clips require verification. No invented healer class in baseline. Camera and controls retained as project design.

## Playable slice wiring (GAME-SLICE)
Extracted baseline: `client/content/heroes/classes_baseline.json` from `t_playerinfo` + `t_doc_playerinfo` + `t_skill` + `t_effect`.

| Studio actor | playerinfo id | Name | Model | Hotbar skill IDs | init_hp |
|---|---|---|---|---|---|
| 10001 | 3 | Воин / 戰士 | ZS_M_01 | 3001001, 3005001, 3006001 | 20000 |
| 20001 | 2 | Лучник / 射手 | GJS_M_01 | 2001001, 2003001, 2004001 | 20000 |
| 30001 | 1 | Маг / 法師 | FS_W_01 | 1001001, 1003001, 1004001 | 20000 |
| 40001 | 4 | Ассасин / 刺客 | CK_W_01 | 4001001, 4003001, 4004001 | 20000 |

Slice uses scaled HP (`init_hp/40`) and damage from `t_effect.percent` / `ex_damage` for local dummy combat. Full CalcDamage parity is FORMULAS.md / C01.
