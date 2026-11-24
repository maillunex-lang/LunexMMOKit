"""Conservative base-model exporter; refuses ambiguous or costume substitutions."""
import argparse,json,sqlite3,pathlib,subprocess,hashlib,struct
p=argparse.ArgumentParser();p.add_argument('id');p.add_argument('--output',required=True);a=p.parse_args()
db=sqlite3.connect('file:/home/gamedev/darklord-dgi/catalog.sqlite?mode=ro',uri=True)
r=db.execute('select data from visual_models where id=?',(a.id,)).fetchone()
if not r:raise SystemExit('Unknown model ID')
v=json.loads(r[0]);meshes=v['folder_meshes']
if len(meshes)!=1 or v['prefab_meshes']!=meshes:raise SystemExit('Requires explicit mesh/rig assembly review')
src=meshes[0];prefix='Client/Assets/AssetsRaw/'
if not src.startswith(prefix):raise SystemExit('Unsupported source root')
key=hashlib.sha256(src[len(prefix):].encode()).hexdigest()[:24]
out=pathlib.Path(a.output).resolve()
if out.suffix!='.glb' or out.is_relative_to('/home/gamedev/Darklord'):raise SystemExit('Unsafe output')
out.parent.mkdir(parents=True,exist_ok=True)
subprocess.run(['python3','/home/gamedev/lunex-asset-library/tools/darklord3d/export.py',key,str(out)],check=True)
b=out.read_bytes();assert b[:4]==b'glTF';j=json.loads(b[20:20+struct.unpack_from('<I',b,12)[0]])
assert j.get('meshes')
report={'id':a.id,'sha256':hashlib.sha256(b).hexdigest(),'meshes':len(j['meshes']),'skins':len(j.get('skins',[])),'animations':len(j.get('animations',[])),'images':len(j.get('images',[])),'rig_visual_verified':False}
out.with_suffix('.json').write_text(json.dumps(report,indent=2));print(report)
