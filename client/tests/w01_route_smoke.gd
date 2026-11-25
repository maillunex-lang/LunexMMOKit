extends SceneTree
## W01: corridor length → 2–4 min walk; chunks stream; LOD; nav path; memory delta logged.

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var fails: PackedStringArray = []
	var path := "res://world/route_corridor/route_play.tscn"
	if not ResourceLoader.exists(path):
		fails.append("route_play missing")
		_finish(fails)
		return
	var packed: PackedScene = load(path)
	var scene: Node3D = packed.instantiate()
	root.add_child(scene)
	# Allow _ready + async nav bake
	for _i in 8:
		await process_frame
	await root.get_tree().physics_frame
	await root.get_tree().physics_frame
	var length_m: float = scene.route_length_m()
	var minutes: float = scene.estimated_walk_minutes(3.0)
	print("OK length_m=", length_m, " walk_min@", 3.0, "=", "%.2f" % minutes)
	if minutes < 2.0 or minutes > 4.0:
		fails.append("walk_minutes out of 2–4 got=%.2f" % minutes)
	# Start: capital chunk should load
	scene.advance_hero(2.0)
	await process_frame
	var start_loaded: int = scene.loaded_chunk_count()
	print("OK start_loaded=", start_loaded)
	if start_loaded < 1:
		fails.append("no chunk at start")
	var mem0: int = scene.mem_delta_kb()
	# Walk mid → more chunks; far ones may unload depending on radii
	scene.advance_hero(330.0)
	await process_frame
	var mid_loaded: int = scene.loaded_chunk_count()
	print("OK mid_loaded=", mid_loaded, " mem_delta_kb=", scene.mem_delta_kb())
	if mid_loaded < 1:
		fails.append("no chunk at mid")
	scene.advance_hero(640.0)
	await process_frame
	var end_loaded: int = scene.loaded_chunk_count()
	print("OK end_loaded=", end_loaded, " mem_delta_kb=", scene.mem_delta_kb())
	if end_loaded < 1:
		fails.append("no chunk at end")
	# Nav path across corridor
	await root.get_tree().physics_frame
	var nav_path: PackedVector3Array = scene.query_path()
	print("OK nav_points=", nav_path.size())
	if nav_path.size() < 2:
		fails.append("nav path empty")
	else:
		var travel := 0.0
		for i in range(1, nav_path.size()):
			travel += nav_path[i - 1].distance_to(nav_path[i])
		print("OK nav_travel_m=", "%.1f" % travel)
		if travel < length_m * 0.7:
			fails.append("nav too short")
	# Collisions present
	var bodies := scene.find_children("*", "StaticBody3D", true, false)
	print("OK static_bodies=", bodies.size(), " mem0=", mem0, " mem_end=", scene.mem_delta_kb())
	if bodies.size() < 2:
		fails.append("few collisions")
	# LOD nodes exist on a loaded chunk
	var streamer := scene.get_node_or_null("ChunkStreamer")
	if streamer == null:
		fails.append("streamer missing")
	else:
		var has_lod := false
		for child in streamer.get_children():
			if child.get_node_or_null("Detail") != null and child.get_node_or_null("FarProxy") != null:
				has_lod = true
				break
		if not has_lod:
			fails.append("lod nodes missing")
		else:
			print("OK lod Detail/FarProxy present")
	scene.queue_free()
	_finish(fails)

func _finish(fails: PackedStringArray) -> void:
	if fails.is_empty():
		print("W01_ROUTE_SMOKE_OK")
		quit(0)
		return
	for f in fails:
		print("FAIL ", f)
	print("W01_ROUTE_SMOKE_FAIL")
	quit(1)
