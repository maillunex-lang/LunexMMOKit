#!/usr/bin/env python3
"""Convert FBX → GLB with nearby Darklord TGA/PNG textures staged for Godot import."""
import hashlib, pathlib, re, shutil, subprocess, sys, tempfile
if len(sys.argv) != 3:
    raise SystemExit("usage: convert_kit_fbx.py INPUT.FBX OUTPUT.glb")
src = pathlib.Path(sys.argv[1]).resolve()
out = pathlib.Path(sys.argv[2]).resolve()
assert src.suffix.lower() == ".fbx" and out.suffix == ".glb"
DARK = pathlib.Path("/home/gamedev/Darklord/Client/Assets")
TEX_ROOTS = [
    DARK / "AssetsRaw/Scene/texture",
    DARK / "AssetsRaw/Scene/scene_texture",
    DARK / "AssetsRaw/Scene/fbx",
]
# Collect texture basenames referenced by FBX (often .psd → use .tga)
raw = src.read_bytes()
refs = {m.decode("utf-8", "ignore") for m in re.findall(rb"[\w./\\\-]+\.(?:tga|psd|png|jpg)", raw, re.I)}
bases = set()
for r in refs:
    b = pathlib.Path(r.replace("\\", "/")).name
    bases.add(pathlib.Path(b).stem.lower())

def find_tex(stem: str):
    for root in TEX_ROOTS:
        for ext in (".tga", ".png", ".jpg"):
            hits = list(root.rglob(stem + ext)) + list(root.rglob(stem + ext.upper()))
            # case-insensitive fallback
            if not hits:
                hits = [p for p in root.rglob("*") if p.suffix.lower() == ext and p.stem.lower() == stem]
            if hits:
                return hits[0]
    return None

with tempfile.TemporaryDirectory(prefix="kit-fbx-") as t:
    p = pathlib.Path(t)
    (p / "project.godot").write_text(
        '[application]\nconfig/name="kit fbx convert"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n'
    )
    shutil.copyfile(src, p / "model.fbx")
    staged = 0
    for stem in sorted(bases):
        tex = find_tex(stem)
        if not tex:
            continue
        # Stage under several names Godot/FBX may look for
        for name in (tex.name, stem + tex.suffix.lower(), stem + ".tga", stem + ".psd"):
            # Can't fake real PSD; skip writing binary as .psd
            if name.lower().endswith(".psd"):
                continue
            dest = p / pathlib.Path(name).name
            if not dest.exists():
                try:
                    shutil.copyfile(tex, dest)
                    staged += 1
                except Exception:
                    pass
    shutil.copyfile("/home/gamedev/LunexMMOKit/tools/dgi/fbx_to_glb.gd", p / "fbx_to_glb.gd")
    (p / "job.json").write_text('{"output":"%s"}' % str(out))
    out.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["/usr/local/bin/godot", "--headless", "--path", str(p), "--import"], check=True, timeout=180)
    subprocess.run(["/usr/local/bin/godot", "--headless", "--path", str(p), "--script", "res://fbx_to_glb.gd"], check=True, timeout=180)
print({"out": str(out), "refs": sorted(bases), "staged": staged})
