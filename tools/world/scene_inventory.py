"""Read Unity YAML scene records without executing source code."""
import argparse, collections, json, pathlib, re
import yaml

def records(path):
    text=path.read_text(encoding='utf-8-sig')
    parts=re.split(r'^--- !u!(\d+) &(-?\d+)(?: stripped)?\s*$',text,flags=re.M)
    for i in range(1,len(parts),3):
        data=yaml.safe_load(parts[i+2])
        if isinstance(data,dict):
            yield parts[i],parts[i+1],data

def inspect(path,root):
    counts=collections.Counter()
    refs=set()
    transforms=[]
    objects={}
    errors=[]
    for kind,ident,data in records(path):
        name,value=next(iter(data.items()))
        counts[name]+=1
        if name=='GameObject':
            objects[ident]=value.get('m_Name','')
        if name=='Transform':
            transforms.append(dict(id=ident,object=str(value.get('m_GameObject',{}).get('fileID',0)),parent=str(value.get('m_Father',{}).get('fileID',0)),position=value.get('m_LocalPosition'),rotation=value.get('m_LocalRotation'),scale=value.get('m_LocalScale')))
        def walk(v):
            if isinstance(v,dict):
                if v.get('guid'): refs.add(str(v['guid']))
                for x in v.values(): walk(x)
            elif isinstance(v,list):
                for x in v: walk(x)
        walk(value)
    for t in transforms: t['name']=objects.get(t['object'],'')
    return dict(path=str(path.relative_to(root)),counts=dict(counts),guids=sorted(refs),transforms=transforms)

def main():
    p=argparse.ArgumentParser()
    p.add_argument('root',type=pathlib.Path)
    p.add_argument('output',type=pathlib.Path)
    a=p.parse_args()
    scenes=[]; errors=[]
    for f in sorted((a.root/'Client/Assets/Scene').rglob('*.unity')):
        try: scenes.append(inspect(f,a.root))
        except Exception as e: errors.append(dict(path=str(f.relative_to(a.root)),error=str(e)))
    a.output.parent.mkdir(parents=True,exist_ok=True)
    a.output.write_text(json.dumps(dict(scenes=scenes,errors=errors),ensure_ascii=False))
    print('SCENES',len(scenes),'ERRORS',len(errors),'TRANSFORMS',sum(len(s['transforms']) for s in scenes))
    print('ERROR_SAMPLE',errors[:3])
if __name__=='__main__': main()
