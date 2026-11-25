"""Recover prefab transform overrides missing from stripped Unity scene records."""
import json,sys,pathlib
from scene_inventory import records
instances=json.load(open(sys.argv[1])); deps=json.load(open(sys.argv[2]))
scene=list(records(pathlib.Path(sys.argv[3])))
stripped={}
for _,ident,d in scene:
    if 'Transform' in d:
        t=d['Transform']; p=t.get('m_PrefabInternal',{}).get('fileID',0)
        if p:stripped.setdefault(str(p),[]).append(dict(id=ident,source=t.get('m_PrefabParentObject',{}).get('fileID')))
out=[]
for r in instances:
    asset=r['assets'][0]; roots=[t for t in deps[asset]['transforms'] if not t['data'].get('m_Father',{}).get('fileID')]
    root=roots[0] if len(roots)==1 else None
    targets={str(m['target']['fileID']) for m in r['overrides'] if m['propertyPath'].startswith('m_LocalPosition.')}
    target=root['id'] if root else next(iter(targets)) if len(targets)==1 else None
    t=root['data'] if root else {}
    pos=dict(t.get('m_LocalPosition',dict(x=0,y=0,z=0)))
    rot=dict(t.get('m_LocalRotation',dict(x=0,y=0,z=0,w=1)))
    scale=dict(t.get('m_LocalScale',dict(x=1,y=1,z=1)))
    fields={'m_LocalPosition':pos,'m_LocalRotation':rot,'m_LocalScale':scale}
    for m in r['overrides']:
        if str(m['target']['fileID'])!=target:continue
        field,_,axis=m['propertyPath'].partition('.')
        if field in fields and axis in fields[field]:fields[field][axis]=float(m['value'])
    out.append(dict(id=r['id'],asset=asset,parent=r['parent'],target=target,position=[pos['x'],pos['y'],-pos['z']],rotation=[-rot['x'],-rot['y'],rot['z'],rot['w']],scale=[scale['x'],scale['y'],scale['z']],stripped=stripped.get(r['id'],[]),overrides=r['overrides']))
pathlib.Path(sys.argv[4]).write_text(json.dumps(out,indent=2))
print('PLACEMENTS',len(out),'ROOT_RESOLVED',sum(bool(r['target']) for r in out),'STRIPPED_LINKS',sum(bool(r['stripped']) for r in out))
