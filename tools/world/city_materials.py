"""Extract original material parameters and deduplicate converted textures."""
import pathlib,json,re,sys,hashlib
from PIL import Image
from scene_inventory import records
root=pathlib.Path(sys.argv[1]); data=json.load(open(sys.argv[2])); out=pathlib.Path(sys.argv[3]);out.mkdir(parents=True,exist_ok=True)
index={}
for p in root.rglob('*.meta'):
    m=re.search(r'^guid:\s*([0-9a-f]{32})',p.read_text(errors='replace')[:4096],re.M)
    if m:index.setdefault(m[1],[]).append(p.with_suffix(''))
def resolve(g):
    matches=[p for p in index.get(g,[]) if p.is_file()]
    return matches[0] if len(matches)==1 else None
paths={p for v in data.values() for r in v['renderers'] for m in r['materials'] for p in m['assets'] if p.endswith('.mat')}
result={}
for p in sorted(paths):
    try:
        m=next(d['Material'] for _,_,d in records(root/p) if 'Material' in d)
        props=m['m_SavedProperties']; row=dict(shader=m.get('m_Shader'),floats={k:v for a in props.get('m_Floats',[]) if isinstance(a,dict) for k,v in a.items()},colors={k:v for a in props.get('m_Colors',[]) if isinstance(a,dict) for k,v in a.items()},textures={})
        for a in props.get('m_TexEnvs',[]):
            if not isinstance(a,dict):continue
            for k,v in a.items():
                ref=v.get('m_Texture',{});g=ref.get('guid')
                if not g:continue
                src=resolve(g); t=dict(guid=g,scale=v.get('m_Scale'),offset=v.get('m_Offset'))
                if src:
                    try:
                        name=g+'.png'
                        if not (out/name).exists():
                            with Image.open(src) as im:im.convert('RGBA').save(out/name)
                        t.update(file=name,source=str(src.relative_to(root)))
                    except Exception as e:t['error']=str(e)
                else:t['error']='unresolved'
                row['textures'][k]=t
        result[p]=row
    except Exception as e:result[p]={'error':str(e)}
(out/'materials.json').write_text(json.dumps(result,indent=2))
print('MATERIALS',len(result),'ERRORS',sum('error' in r for r in result.values()),'TEXTURES',len(list(out.glob('*.png'))),'TEXTURE_ERRORS',sum('error' in t for r in result.values() for t in r.get('textures',{}).values()))
