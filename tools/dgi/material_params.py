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
  params={k:float(x) for k,x in re.findall(r'^    - (_(?:SpecPower2?|SpecIntensity2?|EnableCutout|Cutout|EnableFlow|FlowIntensity)): ([0-9.eE+-]+)$',s,re.M)}
  for k,vals in re.findall(r'^    - (_FlowAni|_FlowColor): \{([^}]+)\}',s,re.M):
   params[k]=[float(x) for x in re.findall(r'[rgba]: ([0-9.eE+-]+)',vals)]
  flow=re.search(r'- _FlowTex:.*?m_Scale: \{x: ([^,]+), y: ([^}]+)\}.*?m_Offset: \{x: ([^,]+), y: ([^}]+)\}',s,re.S)
  if flow:params['_FlowScale']=[float(x) for x in flow.groups()[:2]];params['_FlowOffset']=[float(x) for x in flow.groups()[2:]]
  textures={}
  for k,g in re.findall(r'- (_\w+):\s*m_Texture: \{[^}]*guid: ([a-f0-9]{32})',s):
   paths=db.execute('select path from assets where guid=?',(g,)).fetchall()
   textures[k]={'guid':g,'paths':[x[0] for x in paths]}
  mats.append({'source':p,'params':params,'textures':textures})
 out[i]=mats
pathlib.Path('/home/gamedev/darklord-dgi/material-params.json').write_text(json.dumps(out,indent=2))
print({k:len(v) for k,v in out.items()})
