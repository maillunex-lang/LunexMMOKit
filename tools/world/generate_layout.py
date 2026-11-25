"""Generate native editable transform hierarchy; geometry is a separate import stage."""
import argparse,json,pathlib
def generate(scene,out):
    if out.exists(): raise FileExistsError("Refusing to overwrite editable scene")
    nodes={t['id']:t for t in scene['transforms']}
    paths={}; lines=['[gd_scene format=3]','','[node name="ImportedLayout" type="Node3D"]']
    pending=dict(nodes)
    while pending:
        ready=[k for k,t in pending.items() if t['parent']=='0' or t['parent'] in paths or t['parent'] not in nodes]
        if not ready: raise ValueError("Cyclic transform hierarchy")
        for k in ready:
            t=pending.pop(k); parent=paths.get(t['parent'],'.')
            name='Object_'+k.replace('-','n')
            paths[k]=name if parent=='.' else parent+'/'+name
            p=t['position'] or dict(x=0,y=0,z=0)
            q=t['rotation'] or dict(x=0,y=0,z=0,w=1)
            s=t['scale'] or dict(x=1,y=1,z=1)
            # Reflect Z to convert Unity left-handed coordinates.
            lines.extend(['',f'[node name="{name}" type="Node3D" parent="{parent}"]',
              f'position = Vector3({p["x"]}, {p["y"]}, {-p["z"]})',
              f'quaternion = Quaternion({-q["x"]}, {-q["y"]}, {q["z"]}, {q["w"]})',
              f'scale = Vector3({s["x"]}, {s["y"]}, {s["z"]})',
              'metadata/source_name = '+json.dumps(t['name'],ensure_ascii=False),
              'metadata/source_id = '+json.dumps(k)])
    out.parent.mkdir(parents=True,exist_ok=True)
    out.write_text('\n'.join(lines)+'\n')
    print('LAYOUT_NODES',len(paths))
if __name__=='__main__':
    from scene_inventory import inspect
    p=argparse.ArgumentParser();p.add_argument('root',type=pathlib.Path);p.add_argument('scene',type=pathlib.Path);p.add_argument('output',type=pathlib.Path);a=p.parse_args()
    generate(inspect(a.scene,a.root),a.output)
