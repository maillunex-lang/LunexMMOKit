extends SceneTree
## CHAR10: matrix capture set (stand/attack × angles + wing/mount). Requires LUNEX_CHAR_CAPTURE_OUT.

const Equipment = preload("res://actors/equipment.gd")

func _initialize() -> void:
	call_deferred("run")

func _load(path: String) -> Node3D:
	if path.is_empty() or not FileAccess.file_exists(path):
		return null
	var d := GLTFDocument.new()
	var s := GLTFState.new()
	if d.append_from_file(path, s) != OK:
		return null
	return d.generate_scene(s)

func _aim(cam: Camera3D, center: Vector3, offset: Vector3, fov: float) -> void:
	cam.position = center + offset
	cam.look_at(center)
	cam.fov = fov

func _shot(cam: Camera3D, path: String) -> bool:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image().save_png(path) == OK

func run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var out := OS.get_environment("LUNEX_CHAR_CAPTURE_OUT").strip_edges()
	if out.is_empty():
		print("CHAR10_CAPTURE_FAIL set LUNEX_CHAR_CAPTURE_OUT")
		quit(1)
		return
	if not out.ends_with("/"):
		out += "/"
	DirAccess.make_dir_recursive_absolute(out)
	DirAccess.make_dir_recursive_absolute(out.path_join("wing"))
	DirAccess.make_dir_recursive_absolute(out.path_join("mount"))
	var assets: Node = root.get_node_or_null("/root/LunexAssets")
	if assets == null:
		print("CHAR10_CAPTURE_FAIL LunexAssets")
		quit(1)
		return
	assets.refresh()
	if not bool(assets.ready_ok):
		print("CHAR10_CAPTURE_FAIL assets")
		quit(1)
		return
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.current = true
	cam.near = 0.02
	var light := DirectionalLight3D.new()
	root.add_child(light)
	light.rotation_degrees = Vector3(-35, -30, 0)
	light.light_energy = 1.5
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("#303746")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.7
	root.add_child(env)
	var pairs := [["10001","100011000"],["20001","200011000"],["30001","300011000"],["40001","400011000"]]
	var angles := {
		"front": Vector3(0, 0.4, 3.2),
		"side": Vector3(3.2, 0.4, 0),
		"back": Vector3(0, 0.4, -3.2),
		"angle45": Vector3(2.2, 0.8, 2.2),
	}
	var ok := 0
	var acc := String(assets.accessory_root())
	for pair in pairs:
		var id: String = pair[0]
		var wid: String = pair[1]
		var a := _load(assets.actor_glb(id))
		var w := _load(assets.weapon_glb(wid))
		if a == null or w == null:
			print("LOAD_FAIL ", id)
			continue
		root.add_child(a)
		var handle := Equipment.equip_weapon(a, w, wid)
		var players := a.find_children("*", "AnimationPlayer", true, false)
		if handle.is_empty() or players.is_empty():
			print("EQUIP_FAIL ", id)
			a.queue_free()
			continue
		var player: AnimationPlayer = players[0]
		for clip in ["stand", "attack001"]:
			if not player.has_animation(clip):
				continue
			player.play(clip)
			player.seek(player.get_animation(clip).length * 0.45, true)
			player.pause()
			for aname in angles:
				_aim(cam, Vector3(0, 1.0, 0), angles[aname], 38.0)
				var path: String = out + id + "-" + clip + "-" + String(aname) + ".png"
				if await _shot(cam, path):
					ok += 1
					print("SHOT ", path)
		# wing back
		if not acc.is_empty():
			var wing := _load(acc.path_join("wing.glb"))
			if wing:
				Equipment.prepare_accessory_visuals(wing, "wing", acc, false)
				var wh := Equipment.equip_accessory(a, wing, "wing", "wing_L_01")
				if not wh.is_empty() and player.has_animation("stand"):
					player.play("stand"); player.seek(0.2, true); player.pause()
					_aim(cam, Vector3(0, 1.1, 0), Vector3(0, 0.3, -3.0), 38.0)
					if await _shot(cam, out.path_join("wing").path_join(id + "-wing-back.png")):
						ok += 1
					Equipment.unequip_accessory(wh)
				if is_instance_valid(wing) and wing.get_parent() == null:
					wing.free()
			var mount := _load(acc.path_join("mount.glb"))
			if mount:
				root.add_child(mount)
				var mh := Equipment.mount_actor(mount, a, "mount_001")
				if not mh.is_empty():
					_aim(cam, Vector3(0, 1.4, 0), Vector3(2.5, 1.0, 3.5), 42.0)
					if await _shot(cam, out.path_join("mount").path_join(id + "-mount-side.png")):
						ok += 1
					Equipment.dismount_actor(mh)
				mount.queue_free()
		Equipment.unequip_weapon(handle)
		a.queue_free()
		if is_instance_valid(w) and w.get_parent() == null:
			w.free()
	print("CHAR10_CAPTURE_OK ", ok)
	quit(0 if ok >= 16 else 1)
