import json,pathlib,sys,yaml,struct
root=pathlib.Path(sys.argv[1]); base=pathlib.Path(sys.argv[2])
deps=json.loads((base/'city-dependencies.json').read_text())
manifest={r['source']:r for r in json.loads((base/'city-glb/manifest.json').read_text()) if 'file' in r}
rows=[]
for asset,v in deps.items():
 for m in v['meshes']:
    row=dict(prefab=asset,component=m['id'],object=m['object'],status='unresolved')
    if len(m['assets'])==1:
        p=m['assets'][0]; meta=yaml.safe_load((root/(p+'.meta')).read_text(encoding='utf-8-sig'))
        name=meta.get('ModelImporter',{}).get('fileIDToRecycleName',{}).get(m['ref']['fileID'])
        entry=manifest.get(p)
        if entry and name:
            raw=(base/'city-glb'/entry['file']).read_bytes()
            n=struct.unpack_from('<I',raw,12)[0]; gltf=json.loads(raw[20:20+n])
            matches=[i for i,node in enumerate(gltf.get('nodes',[])) if node.get('name')==name and 'mesh' in node]
            row.update(source=p,name=name,glb=entry['file'],matches=matches,status='exact' if len(matches)==1 else 'review')
    rows.append(row)
(base/'city-mesh-bindings.json').write_text(json.dumps(rows,indent=2))
from collections import Counter
print(Counter(r['status'] for r in rows))
