import pathlib,sqlite3,json,hashlib,re,xml.etree.ElementTree as ET,sys
root=pathlib.Path('/home/gamedev/Darklord');out=pathlib.Path(sys.argv[1]);db=sqlite3.connect(out/'catalog.sqlite')
db.executescript('DROP TABLE IF EXISTS assets; DROP TABLE IF EXISTS xml_sources; DROP TABLE IF EXISTS code_refs; CREATE TABLE assets(path TEXT PRIMARY KEY,ext TEXT,bytes INTEGER,guid TEXT,clip TEXT); CREATE TABLE xml_sources(path TEXT PRIMARY KEY,status TEXT,data TEXT); CREATE TABLE code_refs(path TEXT,line INTEGER,signature TEXT);')
for p in (root/'Client/Assets').rglob('*'):
 if not p.is_file() or p.suffix.lower() not in {'.fbx','.anim','.controller','.prefab','.unity','.mat','.png','.tga','.jpg','.dds','.wav','.mp3','.shader'}:continue
 m=pathlib.Path(str(p)+'.meta');g=re.search(r'^guid:\s*(\w+)',m.read_text(errors='replace'),re.M) if m.exists() else None
 db.execute('INSERT INTO assets VALUES(?,?,?,?,?)',(str(p.relative_to(root)),p.suffix.lower(),p.stat().st_size,g[1] if g else None,p.stem.split('@',1)[1] if '@' in p.stem else None))
def node(e):return {'tag':e.tag,'attributes':e.attrib,'text':e.text,'children':[node(c) for c in e]}
for p in (root/'Client/Assets').rglob('*.xml'):
 try:s='ok';d=json.dumps(node(ET.parse(p).getroot()),ensure_ascii=False)
 except Exception as e:s='failed';d=str(e)
 db.execute('INSERT INTO xml_sources VALUES(?,?,?)',(str(p.relative_to(root)),s,d))
for p in (root/'server/scenesrv').rglob('*.cpp'):
 for i,l in enumerate(p.read_text(errors='replace').splitlines(),1):
  if re.search(r'\b(?:CalculateDamage|CalcDamage|GetDamage|CalcAttack|CalcHurt|CalcAttr|CalcFightPower)\s*\(',l):db.execute('INSERT INTO code_refs VALUES(?,?,?)',(str(p.relative_to(root)),i,l.strip()[:300]))
db.commit()
r=json.loads((out/'report.json').read_text());r.update(assets=db.execute('SELECT ext,count(*) FROM assets GROUP BY ext').fetchall(),xml=db.execute('SELECT status,count(*) FROM xml_sources GROUP BY status').fetchall(),code_refs=db.execute('SELECT count(*) FROM code_refs').fetchone()[0],integrity=db.execute('PRAGMA integrity_check').fetchone()[0]);(out/'report.json').write_text(json.dumps(r,ensure_ascii=False,indent=2));print(json.dumps(r,ensure_ascii=False));db.close()
