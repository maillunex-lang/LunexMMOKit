# LunexMMOKit — Осколки вечности

3D online MMORPG for Android (Godot 4) + authoritative Go/PostgreSQL server.
**Product goal:** Closed Beta 0.1.0 (not a City Preview demo).

## Clone → play / edit
- **Windows (Godot):** `docs/INSTALL_WINDOWS.md`
- **New VPS:** `docs/DEPLOY_VPS.md`
- **Disaster recovery:** `docs/DISASTER_RECOVERY.md`
- **Asset manifest:** `docs/ASSET_MANIFEST.md`

```bash
git clone https://github.com/maillunex-lang/LunexMMOKit.git
cd LunexMMOKit
python3 tools/assets/verify_game_manifest.py
# Open client/project.godot in Godot 4.7.x
```

## Layout
- `client/` — Godot game + World Editor
- `server/` — lunexd + migrations
- `assets/studio/` — adapted runtime characters/weapons (used set only)
- `client/world/library/` — shared environment kits/meshes/textures
- `deploy/` — VPS install, backup, restore
- `docs/` — roadmap, DR, design

Original Darklord sources stay **outside** this repository (read-only on build machines).
