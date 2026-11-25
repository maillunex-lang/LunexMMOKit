import tempfile,pathlib
from scene_inventory import inspect
with tempfile.TemporaryDirectory() as d:
 r=pathlib.Path(d);p=r/'test.unity'
 p.write_text("""--- !u!1 &10
GameObject:
  m_Name: Tree
--- !u!4 &20
Transform:
  m_GameObject: {fileID: 10}
  m_Father: {fileID: 0}
  m_LocalPosition: {x: 1, y: 2, z: 3}
  m_LocalRotation: {x: 0, y: 0, z: 0, w: 1}
  m_LocalScale: {x: 1, y: 1, z: 1}
--- !u!33 &30
MeshFilter:
  m_Mesh: {fileID: 4300000, guid: abcdefabcdefabcdefabcdefabcdefab}
""")
 s=inspect(p,r)
 assert s['transforms'][0]['name']=='Tree'
 assert s['transforms'][0]['position']['z']==3
 assert s['guids']==['abcdefabcdefabcdefabcdefabcdefab']
 print('INVENTORY_FIXTURE_OK')
