"""Resolve Unity scene prefab instances without modifying source assets."""
import argparse,json,pathlib,re
from collections import Counter
from scene_inventory import records
def inventory(root,scene):
    assets=root/'Client/Assets'
    index={}
    for p in assets.rglob('*.meta'):
        m=re.search(r'^guid:\s*([0-9a-f]{32})',p.read_text(errors='replace')[:4096],re.M)
        if m:index.setdefault(m[1],[]).append(p.with_suffix(''))
    instances=[]
    for _,ident,d in records(scene):
        if 'Prefab' not in d:continue
        v=d['Prefab']; ref=v.get('m_ParentPrefab',{}); guid=ref.get('guid','')
        mod=v.get('m_Modification',{})
        matches=[p for p in index.get(guid,[]) if p.is_file()]
        instances.append(dict(id=ident,guid=guid,parent=mod.get('m_TransformParent',{}).get('fileID'),assets=[str(p.relative_to(assets)) for p in matches],overrides=mod.get('m_Modifications',[]),removed=mod.get('m_RemovedComponents',[])))
    return instances
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('root',type=pathlib.Path);p.add_argument('scene',type=pathlib.Path);p.add_argument('output',type=pathlib.Path);a=p.parse_args()
    rows=inventory(a.root,a.scene)
    a.output.write_text(json.dumps(rows,ensure_ascii=False,indent=2))
    print('INSTANCES',len(rows),'RESOLVED',sum(len(r['assets'])==1 for r in rows),'UNIQUE',len({r['guid'] for r in rows}), 'TYPES',Counter(pathlib.Path(r['assets'][0]).suffix for r in rows if len(r['assets'])==1))
    print('TOP',Counter(r['assets'][0] for r in rows if len(r['assets'])==1).most_common(8))
