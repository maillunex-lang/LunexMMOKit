# PORTABILITY-001 / FIX-002
Repository remains public at owner's direction. Include converted runtime models, animation, selected texture/audio dependencies and configuration, not the original Darklord project. Never commit secrets or signing keys.

## Runtime asset resolution (game)
Autoload `LunexAssets` (`client/core/asset_paths.gd`):

1. `LUNEX_STUDIO_CACHE` env (absolute folder with `manifest.json`)
2. Bundled `assets/studio` next to the repo (desktop)
3. `user://studio-cache-v2` (Android / downloaded pack)
4. Optional `LUNEX_DARKLORD_ROOT` — **tools/import only**, not required to play

Play scenes must not hardcode `/home/gamedev/...`. Training/studio tools may use env overrides.

## Windows clone → play
1. `git clone` LunexMMOKit
2. Ensure `assets/studio/` has `manifest.json` + `exports/*.glb` (committed when license allows) **or** copy adapted pack into `%APPDATA%/Godot/app_userdata/LunexMMOKit/studio-cache-v2/` **or** set `LUNEX_STUDIO_CACHE`
3. Open `client/project.godot` in Godot 4
4. Run `eternity_play.tscn`
5. Android export uses same `user://` cache + optional `studio_payload.zip` / HTTPS manifest (`studio_boot.gd`)

## Sync helper
`python3 tools/sync_studio_assets.py` copies from a local darklord-dgi exports dir into `assets/studio` and refreshes SHA256 manifest (dev machine only; does not commit Darklord originals).

## Original Darklord
Read-only on the build machine. Never publish. Absolute paths allowed only under `tools/` importers.
