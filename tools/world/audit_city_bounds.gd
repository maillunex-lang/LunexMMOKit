extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	var city: Node3D=load("res://world/imported/capital_geometry_v6.tscn").instantiate()
	root.add_child(city)
	var rows:Array=[]
	for m in city.find_children("*","MeshInstance3D",true,false):
		var p:Node=m
		while p!=city and not p.has_meta("source_asset"):p=p.get_parent()
		var b:AABB=m.global_transform*m.get_aabb()
		rows.append({"node":str(city.get_path_to(m)),"asset":p.get_meta("source_asset",""),"height":b.size.y,"min_y":b.position.y,"max_y":b.end.y,"visible":m.is_visible_in_tree()})
	rows.sort_custom(func(a,b):return a.height>b.height)
	var f:=FileAccess.open("/home/gamedev/darklord-dgi/city-bounds-v6.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(rows,"  "))
	for r in rows.slice(0,12):print(r)
	print("MESH_COUNT ",rows.size())
	quit()
