import pathlib,re,json,sqlite3,sys
root=pathlib.Path('/home/gamedev/Darklord')
db=sqlite3.connect('file:/home/gamedev/darklord-dgi/catalog.sqlite?mode=ro',uri=True)
def resolve(g):
 return [x[0] for x in db.execute('select path from assets where guid=?',(g,))]
def field(s,k):
 m=re.search(r'^  '+re.escape(k)+r': (.*)$',s,re.M)
 return m[1] if m else None
def blocks(s):
 return {i:(t,b) for t,i,b in re.findall(r'^--- !u!(\d+) &(\d+)\n(.*?)(?=^--- !u!|\Z)',s,re.M|re.S)}
def inspect(path):
 bs=blocks((root/path).read_text())
 render={field(b,'m_GameObject'):b for t,b in bs.values() if t=='199'}
 result=[]
 for i,(t,b) in bs.items():
  if t!='198':continue
  go=field(b,'m_GameObject');gid=re.search(r'\d+',go)[0]
  curves={}
  for key in ['startLifetime','startSpeed','startSize','startRotation','gravityModifier','rateOverTime','rate']:
   m=re.search(r'^    '+key+r':\n(.*?)(?=^    \w|^  \w|\Z)',b,re.M|re.S)
   if m:
    curves[key]={k:float(v) for k,v in re.findall(r'^      (minMaxState|scalar|minScalar): ([0-9.eE+-]+)',m[1],re.M)}
  materials=[]
  for g in sorted(set(re.findall(r'guid: ([a-f0-9]{32})',render.get(go,'')))):
   for p in resolve(g):
    if p.endswith('.mat'):
     textures={k:resolve(v) for k,v in re.findall(r'- (_\w+):\s*m_Texture: \{[^}]*guid: ([a-f0-9]{32})',(root/p).read_text())}
     for k,v in re.findall(r'name: (_\w+)\s+second:\s+m_Texture: \{[^}]*guid: ([a-f0-9]{32})',(root/p).read_text()):
      textures[k]=resolve(v)
     materials.append({'path':p,'textures':textures})
  result.append({'id':i,'name':field(bs[gid][1],'m_Name'),'duration':float(field(b,'lengthInSec')),'loop':field(b,'looping')=='1','curves':curves,'materials':materials,'render_mode':field(render.get(go,''),'m_RenderMode'),'raw_modules':re.findall(r'^  (\w+Module):',b,re.M)})
 return result
paths=sys.argv[1:] or ['Client/Assets/Resources/Effect/skill/player/FS_W/FS_W_attack001.prefab','Client/Assets/Resources/Effect/skill/hurt/FS_hti.prefab']
out={p:inspect(p) for p in paths}
pathlib.Path('/home/gamedev/darklord-dgi/particle-index.json').write_text(json.dumps(out,indent=2))
for p,rows in out.items():
 print(p,len(rows))
 for r in rows:print(r['name'],r['curves'],[(m['path'],m['textures']) for m in r['materials']])
