"""Build private portable studio cache, never modify source assets."""
import argparse, json, shutil, hashlib
from pathlib import Path
p=argparse.ArgumentParser()
p.add_argument("destination",type=Path)
a=p.parse_args()
src=Path("/home/gamedev/Darklord")
dgi=Path("/home/gamedev/darklord-dgi")
out=a.destination.resolve()
if out.exists(): raise SystemExit("Destination must not exist")
out.mkdir(parents=True)
def copy(source, relative):
    target=out/relative
    target.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(source,target)
for name in ["10001","20001","30001","40001","weapon-100011000","weapon-200011000","weapon-300011000","weapon-400011000"]:
    copy(dgi/"exports"/(name+".glb"),"exports/"+name+".glb")
for f in (dgi/"exports/accessories").glob("*.glb"): copy(f,"exports/accessories/"+f.name)
def rewrite(v):
    if isinstance(v,dict): return {k:rewrite(x) for k,x in v.items()}
    if isinstance(v,list): return [rewrite(x) for x in v]
    if isinstance(v,str):
        if v.startswith("Client/Assets/") and Path(v).suffix.lower() in (".png",".tga",".jpg",".jpeg",".webp"):
            if (src/v).is_file(): copy(src/v,"source/"+v)
        if v.startswith(str(dgi/"exports/meshes")+"/") and Path(v).is_file():
            rel="exports/meshes/"+Path(v).name
            copy(Path(v),rel)
            return "@CACHE@/"+rel
    return v
for name in ["material-params.json","particle-index.json"]:
    (out/name).write_text(json.dumps(rewrite(json.loads((dgi/name).read_text())),ensure_ascii=False))
for name in ["FS_Atk_01.mp3","ZS_Atk_01.mp3","SS_Atk_01.wav","assassinatorattack01.mp3"]:
    rel="Client/Assets/Resources/Sound/skill/"+name
    copy(src/rel,"source/"+rel)
files=[{"path":str(f.relative_to(out)),"size":f.stat().st_size,"sha256":hashlib.sha256(f.read_bytes()).hexdigest()} for f in sorted(out.rglob("*")) if f.is_file()]
(out/"manifest.json").write_text(json.dumps({"version":1,"files":files},indent=2))
print(len(files),"files",sum(f["size"] for f in files),"bytes")
