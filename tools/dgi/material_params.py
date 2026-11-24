import sqlite3,json,re,pathlib
root=pathlib.Path('/home/gamedev/Darklord')
db=sqlite3.connect('file:/home/gamedev/darklord-dgi/catalog.sqlite?mode=ro',uri=True)
out={}
for i in ['100011000','200011000','300011000','400011000']:
 v=json.loads(db.execute('select data from visual_models where id=?',(i,)).fetchone()[0])
 mats=[]
 for p in v['prefab_dependencies']:
  if '/Materials/' not in p or not p.endswith('.mat'):continue
  s=(root/p).read_text()
  params={k:float(x) for k,x in re.findall(r'^    - (_(?:SpecPower2?|SpecIntensity2?|EnableCutout|Cutout|EnableFlow)): ([0-9.eE+-]+)$',s,re.M)}
  textures={}
  for k,g in re.findall(r'- (_\w+):\s*m_Texture: \{[^}]*guid: ([a-f0-9]{32})',s):
   paths=db.execute('select path from assets where guid=?',(g,)).fetchall()
   textures[k]={'guid':g,'paths':[x[0] for x in paths]}
  mats.append({'source':p,'params':params,'textures':textures})
 out[i]=mats
pathlib.Path('/home/gamedev/darklord-dgi/material-params.json').write_text(json.dumps(out,indent=2))
print({k:len(v) for k,v in out.items()})
