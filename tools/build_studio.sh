#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
python3 - <<'PY'
import zipfile,pathlib,json,hashlib
r=pathlib.Path('assets/studio')
for e in json.loads((r/'manifest.json').read_text())['files']:
 p=r/e['path']
 assert p.stat().st_size==e['size'] and hashlib.sha256(p.read_bytes()).hexdigest()==e['sha256'],p
with zipfile.ZipFile('client/studio_payload.zip','w',zipfile.ZIP_DEFLATED) as z:
 for p in sorted(r.rglob('*')):
  if p.is_file(): z.write(p,p.relative_to(r))
PY
godot --headless --path client --editor --quit
godot --headless --path client --export-debug "Android Studio" ../build/LunexCharacterStudio.apk
