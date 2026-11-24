import json,pathlib,os
root=pathlib.Path(__file__).resolve().parents[1]
dest=pathlib.Path('/var/www/MMORPG/progress.json')
data=[{k:t[k] for k in ('id','phase','work','status')} for t in json.loads((root/'docs/roadmap.json').read_text())]
tmp=dest.with_suffix('.tmp');tmp.write_text(json.dumps(data,ensure_ascii=False));os.replace(tmp,dest)
