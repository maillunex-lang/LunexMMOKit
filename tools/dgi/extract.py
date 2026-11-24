"""Read-only literal Lua extraction. Never evaluates Lua."""
import re,json,sqlite3,pathlib,hashlib,sys,collections
ROOT=pathlib.Path('/home/gamedev/Darklord')
OUT=pathlib.Path(sys.argv[1])
OUT.mkdir(parents=True,exist_ok=True)
token=re.compile(r'\s+|--\[\[.*?\]\]|--[^\n]*|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|[-+]?(?:0[xX][0-9a-fA-F]+|(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?)|[A-Za-z_]\w*|.',re.S)
def parse(s):
 ts=[m.group() for m in token.finditer(s) if not m.group().isspace() and not m.group().startswith('--')]
 i=ts.index('{')
 def val():
  nonlocal i
  t=ts[i];i+=1
  if t=='{':
   a=[];d={}
   while ts[i]!='}':
    if ts[i]=='[':
     i+=1;k=val()
     if ts[i:i+2]!=[']','=']:raise ValueError('key')
     i+=2;d[str(k)]=val()
    elif i+1<len(ts) and ts[i+1]=='=':
     k=ts[i];i+=2;d[k]=val()
    else:a.append(val())
    if ts[i] in (',',';'):i+=1
    elif ts[i]!='}':raise ValueError('separator '+ts[i])
   i+=1
   if d:
    for j,v in enumerate(a,1):d[str(j)]=v
    return d
   return a
  if t[0] in ('"',"'"):
   return re.sub(r'\\([\\\"\'nrt])',lambda m:{'n':'\n','r':'\r','t':'\t'}.get(m[1],m[1]),t[1:-1])
  if t in ('true','false','nil'):return {'true':True,'false':False,'nil':None}[t]
  if t.lower() in ('nan','inf','infinity'):return {'__lua_nonfinite__':t}
  try:return int(t,0)
  except ValueError:
   try:return float(t)
   except ValueError:raise ValueError('unsupported '+t)
 return val()
def decode(b):
 for enc in ('utf-8-sig','gb18030'):
  try:return b.decode(enc),enc
  except UnicodeError:pass
 return b.decode('latin1'),'latin1'
db=sqlite3.connect(OUT/'catalog.tmp.sqlite')
db.executescript('DROP TABLE IF EXISTS records; DROP TABLE IF EXISTS sources; DROP TABLE IF EXISTS links; CREATE TABLE sources(side TEXT,name TEXT,path TEXT,sha256 TEXT,encoding TEXT,status TEXT,detail TEXT,rows INTEGER,PRIMARY KEY(side,name)); CREATE TABLE records(side TEXT,name TEXT,id TEXT,data TEXT,PRIMARY KEY(side,name,id)); CREATE TABLE links(side TEXT,name TEXT,id TEXT,field TEXT,target TEXT,target_id TEXT,resolved INTEGER);')
for side,folder,glob in [('server','server/data/config','*.lua'),('client','Client/Assets/Resources/Lua/Data','*.lua.txt')]:
 for p in sorted((ROOT/folder).glob(glob)):
  b=p.read_bytes();s,enc=decode(b);name=p.name;status='ok';detail='';n=0
  try:
   obj=parse(s); keys=re.search(r'local\s+keys\s*=\s*(\{[^}]*\})',s)
   ks=parse(keys[1]) if keys else None
   rows=obj.items() if isinstance(obj,dict) else enumerate(obj,1)
   batch=[]
   for k,v in rows:
    if ks and isinstance(v,list):
     if len(v)!=len(ks):raise ValueError('schema length mismatch '+str(k))
     v=dict(zip(ks,v))
    batch.append((side,name,str(k),json.dumps(v,ensure_ascii=False,allow_nan=False)))
   db.executemany('INSERT INTO records VALUES(?,?,?,?)',batch);n=len(batch)
  except Exception as e:status='failed';detail=str(e)[:300]
  db.execute('INSERT INTO sources VALUES(?,?,?,?,?,?,?,?)',(side,name,str(p.relative_to(ROOT)),hashlib.sha256(b).hexdigest(),enc,status,detail,n))
db.commit()
rules=[('client','t_playerinfo.lua.txt','init_skill','t_skill.lua.txt'),('client','t_monster.lua.txt','modelId','t_model.lua.txt'),('client','t_monster.lua.txt','default_skill_id','t_skill.lua.txt'),('client','t_skill.lua.txt','skill_action','t_skill_action.lua.txt'),('client','t_skill.lua.txt','effect_1','t_effect.lua.txt'),('client','t_skill.lua.txt','effect_2','t_effect.lua.txt'),('client','t_skill.lua.txt','effect_3','t_effect.lua.txt'),('server','PlayerinfoConfig.lua','init_skill','SkillConfig.lua'),('server','MonsterConfig.lua','default_skill_id','SkillConfig.lua')]
for side,name,field,target in rules:
 ids={r[0] for r in db.execute('SELECT id FROM records WHERE side=? AND name=?',(side,target))}
 for rid,data in db.execute('SELECT id,data FROM records WHERE side=? AND name=?',(side,name)):
  v=json.loads(data)
  if not isinstance(v,dict):continue
  for x in str(v.get(field,'')).split('#'):
   if x.isdigit() and int(x)>0:db.execute('INSERT INTO links VALUES(?,?,?,?,?,?,?)',(side,name,rid,field,target,x,int(x in ids)))
db.commit()
report={'sources':db.execute('SELECT side,status,count(*),sum(rows) FROM sources GROUP BY side,status').fetchall(),'failures':db.execute("SELECT side,name,detail FROM sources WHERE status!='ok'").fetchall(),'links':db.execute('SELECT side,name,field,count(*),sum(resolved) FROM links GROUP BY side,name,field').fetchall(),'integrity':db.execute('PRAGMA integrity_check').fetchone()[0]}
db.close()
(OUT/'catalog.tmp.sqlite').replace(OUT/'catalog.sqlite')
(OUT/'report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2))
print(json.dumps(report,ensure_ascii=False)[:10000])
