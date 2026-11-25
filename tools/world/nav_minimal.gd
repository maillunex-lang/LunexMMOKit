extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	var scene := Node3D.new()
	root.add_child(scene)
	var region := NavigationRegion3D.new()
	scene.add_child(region)
	var nav := NavigationMesh.new()
	nav.vertices = PackedVector3Array([Vector3(-5,0,-5),Vector3(5,0,-5),Vector3(5,0,5),Vector3(-5,0,5)])
	nav.add_polygon(PackedInt32Array([0,2,1]))
	nav.add_polygon(PackedInt32Array([0,3,2]))
	region.navigation_mesh=nav
	print("REGION_NAV_GET ",region.navigation_mesh," POLYS ",region.navigation_mesh.get_polygon_count())
	await physics_frame
	await physics_frame
	var map := region.get_navigation_map()
	NavigationServer3D.map_set_active(map,true)
	NavigationServer3D.map_force_update(map)
	for i in range(5): await physics_frame
	NavigationServer3D.map_force_update(map)
	print("MINIMAL_REGION_RID ",region.get_rid()," MAP_REGION ",NavigationServer3D.region_get_map(region.get_rid()))
	print("MINIMAL_MAP_STATE ",NavigationServer3D.map_is_active(map)," CELLS ",NavigationServer3D.map_get_cell_size(map))
	print("MINIMAL_REGIONS ",NavigationServer3D.map_get_regions(map)," ITER ",NavigationServer3D.map_get_iteration_id(map)," ENABLED ",region.enabled)
	var closest := NavigationServer3D.map_get_closest_point(map,Vector3(4,0,4))
	var path := NavigationServer3D.map_get_path(map,Vector3(-3,0,-3),Vector3(3,0,3),true)
	print("MINIMAL_NORM ",(nav.vertices[2]-nav.vertices[0]).cross(nav.vertices[1]-nav.vertices[0]).normalized()," MAP ",map," POLYS ",nav.get_polygon_count()," CLOSEST ",closest," CLOSEST_OWNER ",NavigationServer3D.map_get_closest_point_owner(map,Vector3(4,0,4))," PATH ",path)
	quit(0 if path.size()>1 else 1)
