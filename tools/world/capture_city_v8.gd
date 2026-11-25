extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	var city: Node3D = load("res://world/imported/capital_geometry_v8.tscn").instantiate()
	root.add_child(city)
	root.size = Vector2i(1280, 720)
	for n in city.get_children():
		var asset: String = n.get_meta("source_asset", "")
		if asset.begins_with("Resources/Effect/") or "/yinying/" in asset:
			n.hide()
		# Hide tall effect crystal spiral for architecture framing; keep crystal_mesh FBX.
		if "cs_zc_03_shuijing_01" in asset:
			n.hide()
	var bounds := AABB()
	var first := true
	for m in city.find_children("*", "MeshInstance3D", true, false):
		if not m.is_visible_in_tree():
			continue
		var b: AABB = m.global_transform * m.get_aabb()
		if b.size.y > 120.0:
			continue
		bounds = b if first else bounds.merge(b)
		first = false
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.38, 0.52, 0.68)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.85, 0.9, 1.0)
	env.environment.ambient_light_energy = 0.85
	city.add_child(env)
	var light := DirectionalLight3D.new()
	city.add_child(light)
	light.rotation_degrees = Vector3(-50, -40, 0)
	light.light_energy = 1.2
	var cam := Camera3D.new()
	city.add_child(cam)
	var center := bounds.get_center()
	var dist: float = maxf(bounds.size.length() * 0.55, 80.0)
	cam.position = center + Vector3(0.55, 0.65, 1.0).normalized() * dist
	cam.far = dist * 8.0
	cam.fov = 50.0
	cam.look_at(center)
	cam.make_current()
	print("V8_BOUNDS ", bounds)
	print("V8_SIZE ", bounds.size)
	await process_frame
	await RenderingServer.frame_post_draw
	var err := root.get_texture().get_image().save_png("/home/gamedev/darklord-dgi/screens/capital-architecture-v8.png")
	print("CAPTURE ", err)
	quit(err)
