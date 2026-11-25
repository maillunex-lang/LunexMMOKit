extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	var city:Node3D=load("res://world/imported/capital_geometry_v7.tscn").instantiate()
	root.add_child(city)
	var rows:Array=[]
	var bounds:=AABB()
	var first:=true
	for m in city.find_children("*","MeshInstance3D",true,false):
		var b:AABB=m.global_transform*m.get_aabb()
		var prefab:Node=m
		while prefab and not str(prefab.name).begins_with("Prefab_"):
			prefab=prefab.get_parent()
		var asset:String=prefab.get_meta("source_asset","") if prefab else ""
		rows.append({"name":m.name,"asset":asset,"center":[b.get_center().x,b.get_center().y,b.get_center().z],"size":[b.size.x,b.size.y,b.size.z],"height":b.size.y})
		bounds=b if first else bounds.merge(b)
		first=false
	rows.sort_custom(func(a,b): return a.height>b.height)
	var out={"count":rows.size(),"bounds":{"center":[bounds.get_center().x,bounds.get_center().y,bounds.get_center().z],"size":[bounds.size.x,bounds.size.y,bounds.size.z]},"tallest":rows.slice(0,mini(15,rows.size()))}
	FileAccess.open("user://dgi/city-bounds-v7.json",FileAccess.WRITE).store_string(JSON.stringify(out, "\t"))
	print("MESHES ",rows.size()," BOUNDS ",bounds)
	quit(0)
