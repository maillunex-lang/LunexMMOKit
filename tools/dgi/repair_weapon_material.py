import pathlib,sqlite3,json,struct,re,shutil
root=pathlib.Path('/home/gamedev/Darklord')
out=pathlib.Path('/home/gamedev/darklord-dgi/exports')
db=sqlite3.connect('file:/home/gamedev/darklord-dgi/catalog.sqlite?mode=ro',uri=True)
for id in ['100011000','300011000']:
 v=json.loads(db.execute('select data from visual_models where id=?',(id,)).fetchone()[0])
 mat=next(p for p in v['prefab_dependencies'] if '/Materials/' in p)
 guid=re.search(r'_MainTex:\s*m_Texture: \{[^}]*guid: ([a-f0-9]{32})',(root/mat).read_text()).group(1)
 path,=db.execute('select path from assets where guid=?',(guid,)).fetchone()
 p=out/('weapon-'+id+'.glb');backup=p.with_suffix('.original.glb')
 if not backup.exists():shutil.copy2(p,backup)
 b=backup.read_bytes();n=struct.unpack_from('<I',b,12)[0];j=json.loads(b[20:20+n]);binary=b[28+n:]
 assert len(j['materials'])==1 and not j.get('images')
 tex=(root/path).read_bytes();assert tex.startswith(b'\x89PNG')
 offset=len(binary);binary+=tex;binary+=b'\0'*(-len(binary)%4)
 j['bufferViews'].append({'buffer':0,'byteOffset':offset,'byteLength':len(tex)})
 j['images']=[{'bufferView':len(j['bufferViews'])-1,'mimeType':'image/png'}];j['textures']=[{'source':0}]
 j['materials'][0]['pbrMetallicRoughness']['baseColorTexture']={'index':0}
 j['buffers'][0]['byteLength']=len(binary)
 data=json.dumps(j,separators=(',',':')).encode();data+=b' '*(-len(data)%4)
 p.write_bytes(struct.pack('<4sII',b'glTF',2,28+len(data)+len(binary))+struct.pack('<I4s',len(data),b'JSON')+data+struct.pack('<I4s',len(binary),b'BIN\0')+binary)
 print(id,path)
