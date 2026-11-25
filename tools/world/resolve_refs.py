"""Resolve scene GUIDs against original Unity metadata, without modifying originals."""
import argparse,json,pathlib,re,collections
def main():
 p=argparse.ArgumentParser()
 p.add_argument('root',type=pathlib.Path)
 p.add_argument('inventory',type=pathlib.Path)
 p.add_argument('output',type=pathlib.Path)
 a=p.parse_args()
 index=collections.defaultdict(list)
 for f in (a.root/'Client/Assets').rglob('*.meta'):
  with f.open(errors='replace') as h: header=h.read(4096)
  m=re.search(r'^guid:\s*([0-9a-f]{32})\s*$',header,re.M)
  if m:
   asset=f.with_suffix('')
   if asset.exists(): index[m[1]].append(str(asset.relative_to(a.root)))
 inv=json.loads(a.inventory.read_text())
 report=[]
 for s in inv['scenes']:
  resolved={}; missing=[]; builtin=[]; ambiguous={}
  for g in s['guids']:
   paths=index.get(g,[])
   if g.startswith('0000000000000000'): builtin.append(g)
   elif len(paths)==1: resolved[g]=paths[0]
   elif paths: ambiguous[g]=paths
   else: missing.append(g)
  report.append(dict(path=s['path'],resolved=resolved,missing=missing,builtin=builtin,ambiguous=ambiguous))
 a.output.write_text(json.dumps(report,ensure_ascii=False))
 print('SCENES',len(report),'RESOLVED',sum(len(x['resolved']) for x in report),'MISSING',sum(len(x['missing']) for x in report),'AMBIGUOUS',sum(len(x['ambiguous']) for x in report))
if __name__=='__main__':main()
