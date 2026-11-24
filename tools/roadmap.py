import argparse,json,pathlib
root=pathlib.Path(__file__).resolve().parents[1]
path=root/'docs/roadmap.json'
tasks=json.loads(path.read_text())
by={t['id']:t for t in tasks}
def validate():
 assert len(by)==len(tasks)
 seen=set()
 for t in tasks:
  assert set(t['depends'])<=seen, t['id']
  assert t['status'] in ('todo','doing','blocked','done')
  assert all((root/f).is_file() for f in t['read'])
  assert (root/'docs/tasks'/ (t['id']+'.md')).is_file()
  if t['status']=='done':
   assert t['evidence'] and all(by[d]['status']=='done' for d in t['depends'])
  seen.add(t['id'])
def next_task():
 return next((t for t in tasks if t['status'] in ('todo','doing') and all(by[d]['status']=='done' for d in t['depends'])),None)
def save():
 path.write_text(json.dumps(tasks,ensure_ascii=False,indent=2)+'\n')
 t=next_task()
 (root/'docs/NEXT.md').write_text('# Next\n'+(f"Task: {t['id']} — {t['work']}\nRead: docs/tasks/{t['id']}.md, "+', '.join(t['read']) if t else 'No ready task; inspect blockers.')+'\n')
 (root/'docs/ROAD.md').write_text('# Roadmap\nRead AGENTS.md and NEXT.md first. Machine source: roadmap.json. Task cards: tasks/.\n\n'+'\n'.join(f"- {t['id']} [{t['status']}] {t['work']} (deps: {', '.join(t['depends'])})" for t in tasks)+'\n')
p=argparse.ArgumentParser()
p.add_argument('action',choices=['next','validate','status','update'])
p.add_argument('id',nargs='?')
p.add_argument('--state',choices=['todo','doing','blocked','done'])
p.add_argument('--evidence',default='')
a=p.parse_args()
validate()
if a.action=='next':
 t=next_task()
 print(json.dumps(t,ensure_ascii=False,indent=2))
elif a.action=='status':
 for s in ('done','doing','blocked','todo'): print(s,sum(t['status']==s for t in tasks))
elif a.action=='update':
 assert a.id in by and a.state
 t=by[a.id]
 assert t['status']!='done', 'Completed task immutable; create follow-up'
 if a.state in ('doing','done'): assert all(by[d]['status']=='done' for d in t['depends'])
 if a.state in ('done','blocked'): assert a.evidence.strip()
 t.update(status=a.state,evidence=a.evidence)
 validate();save()
else: print('Roadmap valid:',len(tasks),'tasks')
