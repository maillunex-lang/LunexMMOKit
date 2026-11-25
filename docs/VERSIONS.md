# Toolchain versions (F03)

| Component | Version | Notes |
|-----------|---------|-------|
| Godot | 4.7.2 stable | CI / VPS `/usr/local/bin/godot` |
| Go | 1.22.x | Local under `tools/sdk/go` (gitignored) or system PATH |
| PostgreSQL | 16 | `server/docker-compose.yml` isolated network |
| Android target | API per export preset | Devices ≥6 GB RAM (beta) |

Do not commit signing keys or `.env` with secrets.
