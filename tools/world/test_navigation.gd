extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	var scene: Node3D = load("res://world/imported/mh_scene_07_corrected.tscn").instantiate()
	root.add_child(scene)
	var source: MeshInstance3D = scene.get_node("Object_477512445/Object_359807223/Object_1817125895/NavigationSource")
	var region := NavigationRegion3D.new()
	region.position = Vector3(129.5,52.7,-121.8)
	region.enabled = true
	region.name = "WalkNavigation"
	scene.add_child(region)
	region.owner = scene
	var mesh := NavigationMesh.new()
	mesh.agent_radius = 0.4
	mesh.agent_height = 1.8
	mesh.agent_max_slope = 89.0
	mesh.agent_max_climb = 1.0
	var data := NavigationMeshSourceGeometryData3D.new()
	data.add_mesh(source.mesh, source.global_transform)
	NavigationServer3D.bake_from_source_geometry_data(mesh,data)
	var tri := mesh.get_polygon(0)
	var vv := mesh.get_vertices()
	print("POLYGON0 ",tri," VERTS ",vv.slice(0,5)," FACE_NORMAL ",(vv[tri[1]]-vv[tri[0]]).cross(vv[tri[2]]-vv[tri[0]]).normalized())
	# FBX imported walksurface faces downward after Unity→Godot conversion.
	# Reverse winding of baked polygons before handing them to NavigationServer.
	var corrected := NavigationMesh.new()
	var original_vertices := mesh.get_vertices()
	var offsets := PackedVector3Array()
	for v in original_vertices:
		offsets.append(v - Vector3(129.5, 52.7, -121.8))
	corrected.vertices = offsets
	for j in range(mesh.get_polygon_count()):
		var polygon := mesh.get_polygon(j)
		polygon.reverse()
		corrected.add_polygon(polygon)
	mesh = corrected
	region.navigation_mesh = mesh
	print("REGION_NAV_MESH ",region.navigation_mesh.get_polygon_count()," LAYERS ",region.navigation_layers)
	await physics_frame
	await physics_frame
	var map := region.get_navigation_map()
	print("MAP ",map," ACTIVE ",NavigationServer3D.map_is_active(map)," REGION ",region.get_rid())
	print("BEFORE_FORCE_UPDATE")
	NavigationServer3D.map_force_update(map)
	for i in range(6): await physics_frame
	NavigationServer3D.map_force_update(map)
	print("MAP_CELL ",NavigationServer3D.map_get_cell_size(map)," UP ",NavigationServer3D.map_get_up(map))
	print("MAP_COUNT ",NavigationServer3D.map_get_regions(map).size())
	print("AFTER_FORCE_UPDATE")
	for i in range(120):
		if NavigationServer3D.map_get_iteration_id(map) > 0:
			break
		await physics_frame
	print("REGIONS ",NavigationServer3D.map_get_regions(map)," ITER ",NavigationServer3D.map_get_iteration_id(map)," VERTICES ",mesh.get_vertices().size()," NMAP_VERTICES ", NavigationServer3D.region_get_connections_count(region.get_rid()))
	var verts := mesh.get_vertices()
	var min_v := Vector3(INF,INF,INF)
	var max_v := Vector3(-INF,-INF,-INF)
	for v in verts:
		min_v=min_v.min(v)
		max_v=max_v.max(v)
	print("MESH_BOUNDS ",min_v," ",max_v," REGION_POS ",region.global_position," SOURCE_POS ",source.global_position," MAP_UP ",NavigationServer3D.map_get_up(map))
	var center := (source.global_transform * source.get_aabb()).get_center()
	var manual_path := NavigationServer3D.map_get_path(map,Vector3(129,53, -121),Vector3(135,53,-121),true)
	print("MANUAL_PATH ",manual_path)
	print("REGION_ENABLED_QUERY ",region.enabled," SERVER_REGION_ENABLED ",NavigationServer3D.region_get_enabled(region.get_rid())," EDGE ",NavigationServer3D.region_get_connections_count(region.get_rid()))
	var max_negative := 0
	var max_positive := 0
	var max_zero := 0
	for ti in range(mesh.get_polygon_count()):
		var tm := mesh.get_polygon(ti)
		var tx := mesh.get_vertices()
		var nr := (tx[tm[1]]-tx[tm[0]]).cross(tx[tm[2]]-tx[tm[0]])
		if nr.y < -0.0001: max_negative += 1
		elif nr.y > 0.0001: max_positive += 1
		else: max_zero += 1
	print("WINDING_STATS positive=",max_positive," negative=",max_negative," degenerate=",max_zero)
	var area_sum := 0.0
	for ti in range(mesh.get_polygon_count()):
		var tm := mesh.get_polygon(ti)
		var tx := mesh.get_vertices()
		area_sum += (tx[tm[1]]-tx[tm[0]]).cross(tx[tm[2]]-tx[tm[0]]).length()*0.5
	print("TRI_AREA_SUM ",area_sum)
	var firstp := mesh.get_polygon(0)
	var firstv := mesh.get_vertices()
	var tn := (firstv[firstp[1]]-firstv[firstp[0]]).cross(firstv[firstp[2]]-firstv[firstp[0]]).normalized()
	print("TRI_NORMAL ",tn," POLY_0 ",firstp)
	var a := NavigationServer3D.map_get_closest_point(map,center)
	print("MAP_CLOSEST_OWN ",NavigationServer3D.map_get_closest_point_owner(map,center))
	var b := NavigationServer3D.map_get_closest_point(map,center+Vector3(5,0,0))
	var path := NavigationServer3D.map_get_path(map,a,b,true)
	print("POLYGON0_CORRECTED ",mesh.get_polygon(0)," NAV_REGION_POLYS ",region.navigation_mesh.get_polygon_count())
	var sample := mesh.get_polygon(0)
	var sample_v := mesh.get_vertices()
	print("SAMPLE_TRI_POINTS ",sample_v[sample[0]]," ",sample_v[sample[1]]," ",sample_v[sample[2]])
	print("NAV_POLYGONS ",mesh.get_polygon_count()," PATH_POINTS ",path.size()," DISTANCE ",a.distance_to(b)," CENTER ",center," A ",a," B ",b)
	if mesh.get_polygon_count()==0 or path.size()<2 or a.distance_to(b)<1:
		quit(1)
		return
	var packed := PackedScene.new()
	packed.pack(scene)
	var output := "res://world/imported/mh_scene_07_navigation.tscn"
	if FileAccess.file_exists(output):
		quit(1)
		return
	quit(ResourceSaver.save(packed,output))
