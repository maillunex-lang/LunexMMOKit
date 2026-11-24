import sqlite3,json,pathlib,collections,sys,re
out=pathlib.Path(sys.argv[1]);db=sqlite3.connect(out/'catalog.sqlite')
def table(n,side='server'):
 return {i:json.loads(s) for i,s in db.execute('select id,data from records where side=? and name=?',(side,n))}
s=table('SkillConfig.lua');c=table('t_skill.lua.txt','client');a=table('t_skill_action.lua.txt','client');e=table('EffectConfig.lua');p=table('PlayerinfoConfig.lua');prof=table('SkillprofConfig.lua');lv=table('LvupConfig.lua');const=table('ConstsConfig.lua')
assert set(map(int,lv))==set(range(1,601)) and const['40']['val1']==600
db.executescript('DROP TABLE IF EXISTS mechanics; CREATE TABLE mechanics(kind TEXT,id TEXT,data TEXT,PRIMARY KEY(kind,id)); DROP TABLE IF EXISTS link_review; CREATE TABLE link_review(source TEXT,id TEXT,field TEXT,target_id TEXT,classification TEXT,candidates TEXT);')
def put(k,i,v):db.execute('insert into mechanics values(?,?,?)',(k,str(i),json.dumps(v,ensure_ascii=False)))
for i,v in lv.items():put('level',i,v)
for n,k in [('BaseAttrConfig.lua','attribute'),('EquipConfig.lua','equipment'),('FuncOpenConfig.lua','unlock'),('LevelFuncOpenConfig.lua','level_unlock'),('DianfenglvupConfig.lua','peak_level')]:
 for i,v in table(n).items():put(k,i,v)
for i,v in s.items():
 cv=c.get(i,{})
 acts=[a[x] for x in re.findall(r'\d+',str(cv.get('skill_action',''))) if x in a]
 eff=[{'slot':j,'type':v.get('e_type_'+str(j)),'id':v.get('effect_'+str(j)),'candidate_effect':e.get(str(v.get('effect_'+str(j))))} for j in range(1,4) if v.get('effect_'+str(j))]
 put('skill',i,{'server':v,'client':cv or None,'actions':acts,'effects':eff,'next_exists':str(v.get('next_lv')) in s})
for i,v in p.items():
 seeds=set(v['init_skill'].split('#'))|{str(x['parameter_'+i]) for x in prof.values()}
 visited=set();todo=list(seeds)
 while todo:
  x=todo.pop()
  if x in visited or x not in s:continue
  visited.add(x);todo.append(str(s[x].get('next_lv')))
 put('class',i,{'source':v,'profession_roots':sorted(seeds),'reachable_skills':sorted(visited),'missing_roots':sorted(seeds-set(s))})
for i in ['3','6','40','47','56','61','143']:put('constant',i,const[i])
allids=collections.defaultdict(list)
for side,n,i in db.execute('select side,name,id from records'):
 allids[i].append(side+':'+n)
for side,n,i,f,t,x in db.execute('select side,name,id,field,target,target_id from links where resolved=0'):
 candidates=allids[x]
 if f.startswith('effect_'):
  v=c.get(i,{});typ=v.get('e_type_'+f[-1]);classification='typed_effect_requires_dispatch'
 elif f=='modelId':classification='missing_client_model'
 elif f=='default_skill_id':classification='missing_client_skill'
 else:classification='missing_client_action'
 db.execute('insert into link_review values(?,?,?,?,?,?)',(n,i,f,x,classification,json.dumps(candidates)))
db.commit()
report={'mechanics':db.execute('select kind,count(*) from mechanics group by kind').fetchall(),'review':db.execute('select classification,count(*) from link_review group by classification').fetchall(),'classes':[(i,len(json.loads(v)['reachable_skills']),json.loads(v)['missing_roots']) for i,v in db.execute("select id,data from mechanics where kind='class'")],'integrity':db.execute('pragma integrity_check').fetchone()[0]}
assert sum(x[1] for x in report['review'])==705
(out/'mechanics-report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2));print(json.dumps(report,ensure_ascii=False))
