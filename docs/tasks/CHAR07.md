# CHAR07

Синхронизация stand/walk/run/attack/skill/hit/death/mount с Unity hitTime и VFX/audio

Status: **done** (attack001 hit/fire from XML; clip inventory; VFX/audio polish residual)

## Acceptance
Тайминги из исходных XML/DamageCell; тесты без произвольных констант; визуальные кадры удара

## Evidence
- Extract: `tools/dgi/char07_extract_hit_times.py` → `client/content/combat/class_attack_events.json`
- Times: warrior 0.15 hit, archer 0.3 hit, mage 0.5 projectile, assassin 0.4 hit (SkillClassDisplayDesc)
- Training uses `SkillEventsLibrary` (no `CLASS_EVENTS` constants)
- `CHAR07_HIT_TIME_SMOKE_OK`; clips stand/run/attack001/die001/mount_stand ×4
