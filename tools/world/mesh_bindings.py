"""Resolve Unity mesh fileIDs from FBX importer metadata."""
import argparse, pathlib, json
import yaml
from scene_inventory import records
def bindings(scene,root):
    index={}
    for f in (root/'Client/Assets').rglob('*.meta'):
        if f.name.lower().endswith('.fbx.meta'):
            d=yaml.load(f.read_text(encoding='utf-8-sig'),Loader=getattr(yaml,'CSafeLoader',yaml.SafeLoader))
            index[d['guid']]=(f.with_suffix(''),d.get('ModelImporter',{}).get('fileIDToRecycleName',{}))
    result=[]
    for _,ident,d in records(scene):
        if 'MeshFilter' not in d: continue
        v=d['MeshFilter']; ref=v.get('m_Mesh',{}); guid=ref.get('guid',''); fid=ref.get('fileID',0)
        entry=index.get(guid)
        name=entry[1].get(fid) if entry else None
        result.append(dict(component=ident,object=v.get('m_GameObject',{}).get('fileID'),guid=guid,file_id=fid,mesh=name,asset=str(entry[0].relative_to(root)) if entry else None))
    return result
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('root',type=pathlib.Path);p.add_argument('scene',type=pathlib.Path);a=p.parse_args()
    print(json.dumps(bindings(a.scene,a.root),ensure_ascii=False,indent=2))
