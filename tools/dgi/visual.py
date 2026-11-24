"""Index visual references without modifying source files."""
import sqlite3,json,pathlib,re,collections,sys
out=pathlib.Path(sys.argv[1]);root=pathlib.Path('/home/gamedev/Darklord');db=sqlite3.connect(out/'catalog.sqlite')
assets=list(db.execute('select path,ext,guid,clip from assets'))
paths=collections.defaultdict(list);guid=collections.defaultdict(list);folders=collections.defaultdict(list);names=collections.defaultdict(list)
for p,e,g,c in assets:
 q=pathlib.PurePosixPath(p); rel=re.sub(r'^Client/Assets/(Resources|AssetsRaw)/','',p)
 paths[str(pathlib.PurePosixPath(rel).with_suffix('')).lower()].append(p)
 folders[str(pathlib.PurePosixPath(rel).parent).lower()].append((p,e,c))
 names[q.stem.lower()].append(p)
 if g:guid[g].append(p)
db.executescript('DROP TABLE IF EXISTS visual_refs; DROP TABLE IF EXISTS visual_models; DROP TABLE IF EXISTS prefab_refs; CREATE TABLE visual_refs(source TEXT,id TEXT,field TEXT,value TEXT,status TEXT,targets TEXT); CREATE TABLE visual_models(id TEXT PRIMARY KEY,data TEXT); CREATE TABLE prefab_refs(path TEXT,guid TEXT,targets TEXT);')
def rows(n):return {i:json.loads(s) for i,s in db.execute("select id,data from records where side='client' and name=?",(n,))}
def ref(n,i,f,v,targets,status=None):
 targets=sorted(set(targets));db.execute('insert into visual_refs values(?,?,?,?,?,?)',(n,i,f,str(v),status or ('missing' if not targets else 'exact' if len(targets)==1 else 'multiple'),json.dumps(targets)))
def pathref(n,i,f,v):
 if not isinstance(v,str) or not v:return
 key=v.replace('\\','/').lower(); hits=paths.get(str(pathlib.PurePosixPath(key).with_suffix('')) if key.endswith(('.prefab','.pfx','.wav','.mp3','.fbx')) else key,[])
 ref(n,i,f,v,hits or names.get(pathlib.PurePosixPath(key).stem,[]),'candidate_basename' if not hits and names.get(pathlib.PurePosixPath(key).stem) else None)
models=rows('t_model.lua.txt');actions=rows('t_skill_action.lua.txt');audio=rows('t_AudioDesc.lua.txt')
for i,v in models.items():
 folder=v.get('animationPath','').lower();fs=folders.get(folder,[]);pref=[]
 for f in ['skl','sklui','skllogin','changeEffect']:
  pathref('t_model',i,f,v.get(f))
  if f=='skl':pref=paths.get(v.get(f,'').lower(),[])
 meshes=[p for p,e,c in fs if e=='.fbx' and not c];clips=[p for p,e,c in fs if e=='.fbx' and c]
 refs=[]
 for p in pref:
  if p.endswith('.prefab'):
   for g in set(re.findall(r'guid:\s*([a-fA-F0-9]{32})',(root/p).read_text(errors='replace'))):
    targets=guid.get(g,[]);refs.extend(targets);db.execute('insert into prefab_refs values(?,?,?)',(p,g,json.dumps(targets)))
 direct=[p for p in refs if p.lower().endswith('.fbx') and '@' not in pathlib.PurePosixPath(p).stem]
 data={'source':v,'prefabs':pref,'folder_meshes':meshes,'prefab_meshes':sorted(set(direct)),'clips':clips,'prefab_dependencies':sorted(set(refs)),'rig_verified':False}
 db.execute('insert into visual_models values(?,?)',(i,json.dumps(data)))
for i,v in actions.items():
 for f in ['skilleffect','skilleffect2','transfer_skilleffect','remain']:pathref('t_skill_action',i,f,v.get(f))
 if v.get('animation'):ref('t_skill_action',i,'animation',v['animation'],[], 'requires_actor_rig')
for i,v in audio.items():
 for f,x in v.items():
  if f.startswith('fileName_'):pathref('t_AudioDesc',i,f,x)
rules={'t_monster.lua.txt':{'modelId':models,'hit_sound':audio,'DeathSound':audio},'t_npc.lua.txt':{'look':models,'UI_look':models},'t_hero.lua.txt':{'model':models,'sound':audio},'t_wing.lua.txt':{'modelID':models,'UImodelID':models},'t_equip.lua.txt':{**{'vmesh'+str(j):models for j in range(1,5)},'tipsModelID':models},'t_skill.lua.txt':{'skill_action':actions,'sound_id':audio,'talk_sound_id':audio,'behit_sound':audio}}
for n,fields in rules.items():
 for i,v in rows(n).items():
  for f,t in fields.items():
   for x in str(v.get(f,'')).split('#'):
    if x.isdigit() and int(x):ref(n,i,f,x,[x] if x in t else [])
  for f in ['born_pfx','foot_pfx','pfx_hurt','pfx_yujing','name_pfx','pfxname1','pfxname2','pfxname3','pfxname4']:pathref(n,i,f,v.get(f))
db.commit()
r={'models':len(models),'models_with_folder_mesh':sum(bool(json.loads(v)['folder_meshes']) for v, in db.execute('select data from visual_models')),'models_with_prefab_mesh':sum(bool(json.loads(v)['prefab_meshes']) for v, in db.execute('select data from visual_models')),'refs':db.execute('select status,count(*) from visual_refs group by status').fetchall(),'prefab_refs':db.execute('select count(*) from prefab_refs').fetchone()[0],'integrity':db.execute('pragma integrity_check').fetchone()[0]}
(out/'visual-report.json').write_text(json.dumps(r,indent=2));print(r)
