"""Convert unique city FBX dependencies once; retain provenance and validate GLB."""
import hashlib,json,pathlib,subprocess,sys,struct
root=pathlib.Path(sys.argv[1]); data=json.load(open(sys.argv[2])); out=pathlib.Path(sys.argv[3]);out.mkdir(parents=True,exist_ok=True)
paths={p for v in data.values() for m in v['meshes'] for p in m['assets']}
paths.update(k for k in data if k.lower().endswith('.fbx'))
report=[]
for p in sorted(paths):
    dest=out/(hashlib.sha256(p.encode()).hexdigest()[:16]+'.glb')
    try:
        if not dest.exists():
            subprocess.run([sys.executable,'tools/dgi/convert_mesh_fbx.py',str(root/p),str(dest)],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.PIPE,timeout=180)
        raw=dest.read_bytes()
        magic,version,size,n,kind=struct.unpack_from('<4sIIII',raw)
        assert magic==b'glTF' and version==2 and size==len(raw) and kind==0x4e4f534a
        j=json.loads(raw[20:20+n])
        assert j.get('meshes')
        report.append(dict(source=p,file=dest.name,meshes=len(j['meshes']),nodes=len(j.get('nodes',[])),bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest()))
    except Exception as e:
        report.append(dict(source=p,error=str(e)))
    (out/'manifest.json').write_text(json.dumps(report,indent=2))
    print(p, 'OK' if 'file' in report[-1] else 'FAILED',flush=True)
print('TOTAL',len(report),'OK',sum('file' in r for r in report))
