import json, pathlib, shutil, subprocess, sys, tempfile
if len(sys.argv) != 3:
    raise SystemExit("usage: convert_mesh_fbx.py INPUT.FBX OUTPUT.glb")
src = pathlib.Path(sys.argv[1]).resolve()
out = pathlib.Path(sys.argv[2]).resolve()
if not src.exists() or src.suffix.lower() != ".fbx":
    raise SystemExit("input must be FBX")
if out.suffix != ".glb" or out.is_relative_to("/home/gamedev/Darklord"):
    raise SystemExit("unsafe output")
out.parent.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix="mesh-fbx-") as t:
    p = pathlib.Path(t)
    (p/"project.godot").write_text("[application]\nconfig/name=\"mesh fbx convert\"\n[rendering]\nrenderer/rendering_method=\"gl_compatibility\"\n")
    shutil.copyfile(src, p/"model.fbx")
    shutil.copyfile("/home/gamedev/LunexMMOKit/tools/dgi/fbx_to_glb.gd", p/"fbx_to_glb.gd")
    (p/"job.json").write_text(json.dumps({"output": str(out)}))
    subprocess.run(["/usr/local/bin/godot", "--headless", "--path", str(p), "--import"], check=True, timeout=120)
    subprocess.run(["/usr/local/bin/godot", "--headless", "--path", str(p), "--script", "res://fbx_to_glb.gd"], check=True, timeout=120)
print(out)
