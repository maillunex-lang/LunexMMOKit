extends SceneTree
## CAP04 visual check: water + crystal mesh + effect crystal + terrain under editable lighting.
const OUT := "/home/gamedev/darklord-dgi/screens/"
func _initialize():
	call_deferred("run")
func run():
	root.size = Vector2i(1280, 720)
	var city: Node3D = load("res://world/capital_city.tscn").instantiate()
	root.add_child(city)
	await process_frame
	await process_frame
	var geometry: Node3D = city.get_node_or_null("Geometry") as Node3D
	if geometry == null:
		print("NO_GEOMETRY")
		quit(1)
		return
	# Frame water + crystal_mesh + effect (keep effect visible for this pass)
	var focus := AABB()
	var first := true
	for n in geometry.get_children():
		var role := String(n.get_meta("cap04_role", ""))
		var asset := String(n.get_meta("source_asset", ""))
		var keep := role in ["water", "crystal_mesh"] or "cs_zc_03_shuijing" in asset
		if not keep:
			continue
		for m in n.find_children("*", "MeshInstance3D", true, false):
			if not m.visible:
				continue
			var b: AABB = m.global_transform * m.get_aabb()
			focus = b if first else focus.merge(b)
			first = false
	if first:
		print("NO_FOCUS")
		quit(1)
		return
	var cam := Camera3D.new()
	city.add_child(cam)
	var center := focus.get_center()
	var dist: float = maxf(focus.size.length() * 0.7, 40.0)
	# Cap extreme effect height for framing
	dist = minf(dist, 220.0)
	cam.position = center + Vector3(0.7, 0.35, 0.9).normalized() * dist
	cam.far = 2000.0
	cam.fov = 50.0
	cam.look_at(center)
	cam.make_current()
	print("FOCUS ", focus)
	await process_frame
	await RenderingServer.frame_post_draw
	var err := root.get_texture().get_image().save_png(OUT + "capital-cap04-polish.png")
	print("CAPTURE_POLISH ", err)
	# Second shot: terrain splat only (hide effects/tall)
	for n in geometry.get_children():
		var asset := String(n.get_meta("source_asset", ""))
		if asset.begins_with("Resources/Effect/") or "/yinying/" in asset:
			n.hide()
	var tbounds := AABB()
	first = true
	for m in geometry.find_children("*", "MeshInstance3D", true, false):
		if not m.is_visible_in_tree():
			continue
		var b2: AABB = m.global_transform * m.get_aabb()
		if b2.size.y > 80.0:
			continue
		tbounds = b2 if first else tbounds.merge(b2)
		first = false
	center = tbounds.get_center()
	dist = maxf(tbounds.size.length() * 0.5, 80.0)
	cam.position = center + Vector3(0.2, 1.2, 0.4).normalized() * dist
	cam.look_at(center + Vector3(0, -5, 0))
	await process_frame
	await RenderingServer.frame_post_draw
	err = root.get_texture().get_image().save_png(OUT + "capital-terrain-splat-v8.png")
	print("CAPTURE_TERRAIN ", err, " TBOUNDS ", tbounds)
	quit(err)
