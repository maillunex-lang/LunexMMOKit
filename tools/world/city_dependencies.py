"""Resolve reusable capital geometry and material dependencies, preserving Unity IDs."""
import json,pathlib,re,sys
from collections import Counter
from scene_inventory import records
root=pathlib.Path(sys.argv[1]); instances=json.load(open(sys.argv[2]))
index={}
for p in root.rglob('*.meta'):
    m=re.search(r'^guid:\s*([0-9a-f]{32})',p.read_text(errors='replace')[:4096],re.M)
    if m:index.setdefault(m[1],[]).append(p.with_suffix(''))
def resolve(g):
    return [str(p.relative_to(root)) for p in index.get(g,[]) if p.is_file()]
def refs(v):
    if isinstance(v,dict):
        if v.get('guid'):yield v['guid']
        for x in v.values():yield from refs(x)
    elif isinstance(v,list):
        for x in v:yield from refs(x)
result={}
for asset in sorted({r['assets'][0] for r in instances}):
    p=root/asset
    rows=list(records(p)) if p.suffix=='.prefab' else []
    meshes=[];materials=[];transforms=[]
    for _,ident,d in rows:
        if 'MeshFilter' in d:
            v=d['MeshFilter']; m=v.get('m_Mesh',{})
            meshes.append(dict(id=ident,object=v.get('m_GameObject'),ref=m,assets=resolve(m.get('guid'))))
        if 'MeshRenderer' in d:
            v=d['MeshRenderer']
            materials.append(dict(id=ident,object=v.get('m_GameObject'),enabled=v.get('m_Enabled'),materials=[dict(ref=m,assets=resolve(m.get('guid'))) for m in v.get('m_Materials',[])]))
        if 'Transform' in d:transforms.append(dict(id=ident,data=d['Transform']))
    result[asset]=dict(meshes=meshes,renderers=materials,transforms=transforms,components=dict(Counter(next(iter(d)) for _,_,d in rows)))
pathlib.Path(sys.argv[3]).write_text(json.dumps(result,ensure_ascii=False,indent=2))
print('PREFABS',len(result),'MESH_FILTERS',sum(len(v['meshes']) for v in result.values()),'RENDERERS',sum(len(v['renderers']) for v in result.values()))
print('UNIQUE_MESH_ASSETS',len({p for v in result.values() for m in v['meshes'] for p in m['assets']}))
print('UNRESOLVED_MESHES',sum(not m['assets'] for v in result.values() for m in v['meshes']))
