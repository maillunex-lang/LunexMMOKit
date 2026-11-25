extends SceneTree
func _initialize():
	call_deferred("verify")
func verify():
	var scene: Node3D = load("res://world/imported/mh_scene_07_navigation.tscn").instantiate()
	root.add_child(scene)
	var region: NavigationRegion3D = scene.get_node("WalkNavigation")
	if region.navigation_mesh == null or region.navigation_mesh.get_polygon_count() != 109:
		push_error("Missing navigation mesh")
		quit(1)
		return
	for i in range(8): await physics_frame
	var map := region.get_navigation_map()
	NavigationServer3D.map_force_update(map)
	var path := NavigationServer3D.map_get_path(map,Vector3(129,53,-121),Vector3(135,53,-121),true)
	print("SCENE_RELOAD polygon_count=",region.navigation_mesh.get_polygon_count()," path_points=",path.size()," iteration=",NavigationServer3D.map_get_iteration_id(map))
	quit(0 if path.size() >= 2 else 1)
