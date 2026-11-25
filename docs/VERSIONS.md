# Toolchain versions (F03)

| Component | Version | Notes |
|-----------|---------|-------|
| Godot | 4.7.2 stable | `/usr/local/bin/godot` |
| Go | 1.22.x (`GOTOOLCHAIN=auto`) | Local `tools/sdk/go` gitignored |
| PostgreSQL | 16 alpine | `docker compose -p lunexmmokit` — no host ports |
| Android SDK | /opt/android-sdk | debug APK via export_presets |

Never commit signing keys or `.env` secrets. `build/*.apk` gitignored.
