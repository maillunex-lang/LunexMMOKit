import sqlite3,json,pathlib,struct,xml.etree.ElementTree as ET,hashlib,sys,collections
out=pathlib.Path(sys.argv[1]);root=pathlib.Path('/home/gamedev/Darklord');db=sqlite3.connect(out/'catalog.sqlite')
db.executescript('DROP TABLE IF EXISTS attachments; DROP TABLE IF EXISTS skill_events; DROP TABLE IF EXISTS accessory_links; DROP TABLE IF EXISTS visual_review; CREATE TABLE attachments(id TEXT PRIMARY KEY,data TEXT); CREATE TABLE skill_events(source TEXT,skill TEXT,ordinal INTEGER,data TEXT); CREATE TABLE accessory_links(source TEXT,id TEXT,field TEXT,model TEXT,resolved INTEGER); CREATE TABLE visual_review(source TEXT,id TEXT,field TEXT,value TEXT,status TEXT);')
def rows(n):return {i:json.loads(s) for i,s in db.execute("select id,data from records where side='client' and name=?",(n,))}
models=rows('t_model.lua.txt');equip=rows('t_equip.lua.txt')
for i,v in rows('t_playerinfo.lua.txt').items():
 if not i.isdigit() or int(i) not in range(1,5):continue
 mid={'1':'30001','2':'20001','3':'10001','4':'40001'}[i];p=out/'exports'/ (mid+'.glb');b=p.read_bytes();j=json.loads(b[20:20+struct.unpack_from('<I',b,12)[0]])
 nodes=[n.get('name','') for n in j['nodes']]
 item=str(v['arm']);weapon=str(equip[item]['vmesh'+i])
 sockets={s:[n for n in nodes if n==s or n==s+'2'] for s in ['DM_R_Hand','DM_L_Hand','E_back','E_fire']}
 data={'body':mid,'item':item,'weapon':weapon,'weapon_exists':weapon in models,'sockets':sockets,'dual':i=='4','mount_socket':'Horse_E_back','transform':'identity','verified_visual':False}
 db.execute('insert into attachments values(?,?)',(i,json.dumps(data)))
for n,fields in [('t_horse.lua.txt',['model'+str(i) for i in range(1,5)]),('t_horseskn.lua.txt',['model'+str(i) for i in range(1,5)]),('t_newwing.lua.txt',['modelID','uimodelID']),('t_newwingskin.lua.txt',['modelID','uimodelID']),('t_hero.lua.txt',['model'])]:
 for i,v in rows(n).items():
  for f in fields:
   for x in str(v.get(f,'')).split('#'):
    if x.isdigit() and int(x):db.execute('insert into accessory_links values(?,?,?,?,?)',(n,i,f,x,int(x in models)))
for p in sorted((root/'Client/Assets/Resources/Data/skill').glob('*.xml')):
 try:tree=ET.parse(p)
 except ET.ParseError:continue
 for t in tree.getroot():
  sid=t.get('skillID') or t.get('id')
  if not sid:continue
  for k,e in enumerate(t.iter()):
   if any(x in e.attrib for x in ['hitTime','fireTime','playTime','skillEfxDelay']):db.execute('insert into skill_events values(?,?,?,?)',(p.name,sid,k,json.dumps({'tag':e.tag,'attributes':e.attrib})))
for n,i,f,v in db.execute("select source,id,field,value from visual_refs where status='missing'"):
 status='unresolved'
 if n=='t_monster.lua.txt' and f=='DeathSound':status='legacy_field_commented_in_CMonsterObject'
 if n=='t_monster.lua.txt' and f=='born_pfx':status='legacy_alias_no_asset_match'
 db.execute('insert into visual_review values(?,?,?,?,?)',(n,i,f,v,status))
db.commit()
r={'attachments':db.execute('select id,data from attachments').fetchall(),'events':db.execute('select source,count(*) from skill_events group by source').fetchall(),'accessories':db.execute('select source,count(*),sum(resolved) from accessory_links group by source').fetchall(),'review':db.execute('select status,count(*) from visual_review group by status').fetchall(),'integrity':db.execute('pragma integrity_check').fetchone()[0]}
(out/'attachments-report.json').write_text(json.dumps(r,indent=2));print(json.dumps(r))
