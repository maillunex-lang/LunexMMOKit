extends SceneTree
## FIX-001: bake NavMesh with a building on the path; path must detour (not go through).
## godot --path client --headless --script res://tests/nav_obstacle_smoke.gd

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var root := Node3D.new()
	root.name = "NavTestRoot"
	root.set_meta("location_id", "nav_test")
	self.root.add_child(root)

	# Walkable ground collider
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	var gshape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 0.2, 40)
	gshape.shape = box
	gshape.position = Vector3(0, -0.1, 0)
	ground.add_child(gshape)
	root.add_child(ground)

	# Building blocking the straight line from (-10,0,0) to (10,0,0)
	var building := StaticBody3D.new()
	building.name = "BuildingBlock"
	var bshape := CollisionShape3D.new()
	var bbox := BoxShape3D.new()
	bbox.size = Vector3(4, 4, 8)
	bshape.shape = bbox
	bshape.position = Vector3(0, 2, 0)
	building.add_child(bshape)
	building.position = Vector3(0, 0, 0)
	root.add_child(building)

	var nav := NavigationRegion3D.new()
	nav.name = "NavigationRegion3D"
	nav.set_script(load("res://world/location_navigation.gd"))
	root.add_child(nav)
	nav.set("fallback_half_extent", 20.0)
	nav.set("bake_path", "")
	await nav.rebuild(root)

	var mesh: NavigationMesh = nav.navigation_mesh
	if mesh == null or mesh.get_polygon_count() <= 0:
		print("NAV_OBSTACLE_FAIL empty mesh polys=", 0 if mesh == null else mesh.get_polygon_count())
		quit(1)
		return

	await self.root.get_tree().physics_frame
	await self.root.get_tree().physics_frame
	var map := root.get_world_3d().navigation_map
	NavigationServer3D.map_force_update(map)
	await self.root.get_tree().physics_frame

	var start := Vector3(-12, 0.1, 0)
	var goal := Vector3(12, 0.1, 0)
	var path: PackedVector3Array = NavigationServer3D.map_get_path(map, start, goal, true)
	if path.is_empty():
		print("NAV_OBSTACLE_FAIL no path")
		quit(1)
		return

	# Path must not cut through building AABB X≈0 with |Z|<3 at mid
	var through := false
	for i in range(path.size() - 1):
		var a: Vector3 = path[i]
		var b: Vector3 = path[i + 1]
		# sample segment
		for t in 8:
			var p: Vector3 = a.lerp(b, float(t) / 8.0)
			if absf(p.x) < 1.2 and absf(p.z) < 3.5:
				through = true
				break
		if through:
			break

	# Move building aside and rebake — path may straighten
	building.position = Vector3(0, 0, 12)
	await nav.rebuild(root)
	await self.root.get_tree().physics_frame
	NavigationServer3D.map_force_update(map)
	await self.root.get_tree().physics_frame
	var path2: PackedVector3Array = NavigationServer3D.map_get_path(map, start, goal, true)

	print("NAV_OBSTACLE polys=", mesh.get_polygon_count(), " path_pts=", path.size(), " through_block=", through, " path2_pts=", path2.size())
	if through:
		print("NAV_OBSTACLE_FAIL path crossed building footprint")
		quit(1)
		return
	if path2.is_empty():
		print("NAV_OBSTACLE_FAIL rebake path empty")
		quit(1)
		return
	print("NAV_OBSTACLE_SMOKE_OK")
	quit(0)
