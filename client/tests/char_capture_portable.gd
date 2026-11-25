extends SceneTree
## Portable CHARACTER-AUDIT / CHAR03 captures via LunexAssets (no hardcoded VPS paths required).
## OUT dir: LUNEX_CHAR_CAPTURE_OUT or /home/gamedev/darklord-dgi/screens/character-audit/

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

func run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var assets: Node = root.get_node_or_null("/root/LunexAssets")
	if assets == null:
		print("CAPTURE_FAIL LunexAssets")
		quit(1)
		return
	assets.refresh()
	if not bool(assets.ready_ok):
		print("CAPTURE_FAIL assets")
		quit(1)
		return
	var out := OS.get_environment("LUNEX_CHAR_CAPTURE_OUT").strip_edges()
	if out.is_empty():
		out = "/home/gamedev/darklord-dgi/screens/character-audit/"
	if not out.ends_with("/"):
		out += "/"
	DirAccess.make_dir_recursive_absolute(out)
	var wing_out := out.path_join("../wing-audit/")
	DirAccess.make_dir_recursive_absolute(wing_out)

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

	var pairs := [
		["10001", "100011000"],
		["20001", "200011000"],
		["30001", "300011000"],
		["40001", "400011000"],
	]
	var wing_path: String = ""
	var acc := String(assets.accessory_root())
	if not acc.is_empty():
		wing_path = acc.path_join("wing.glb")
	var ok := 0
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
		var center := Vector3(0, 1.0, 0)
		var marker: Node3D = null
		if handle.get("mode") == "single":
			marker = handle.get("bone_socket")
		elif handle.get("attachments"):
			marker = handle["attachments"][0].get("bone_socket")
		for clip in ["stand", "attack001"]:
			if not player.has_animation(clip):
				continue
			player.play(clip)
			player.seek(player.get_animation(clip).length * 0.45, true)
			player.pause()
			var shots := {
				"front": Vector3(0.0, 0.4, 3.2),
				"side": Vector3(3.2, 0.4, 0.0),
				"hand": null,
			}
			for name in shots:
				if name == "hand":
					if marker == null:
						continue
					_aim(cam, marker.global_position, Vector3(0.35, 0.2, 0.55), 28.0)
				else:
					_aim(cam, center, shots[name], 38.0)
				await process_frame
				await RenderingServer.frame_post_draw
				var path: String = out + id + "-" + clip + "-tuned-" + String(name) + ".png"
				if root.get_texture().get_image().save_png(path) == OK:
					ok += 1
					print("SHOT ", path)
			player.stop()
		# Wing still frame
		if not wing_path.is_empty() and FileAccess.file_exists(wing_path):
			var wing := _load(wing_path)
			if wing:
				var wh := Equipment.equip_accessory(a, wing, "wing", "wing_L_01")
				if not wh.is_empty():
					if player.has_animation("stand"):
						player.play("stand")
						player.seek(0.2, true)
						player.pause()
					_aim(cam, Vector3(0, 1.1, 0), Vector3(0.0, 0.3, -3.0), 38.0)
					await process_frame
					await RenderingServer.frame_post_draw
					var wpath: String = wing_out.path_join(id + "-wing-back.png")
					if root.get_texture().get_image().save_png(wpath) == OK:
						ok += 1
						print("WING ", wpath)
					_aim(cam, Vector3(0, 1.2, -0.1), Vector3(0.4, 0.2, -0.8), 30.0)
					await process_frame
					await RenderingServer.frame_post_draw
					var cpath: String = wing_out.path_join(id + "-wing-close.png")
					if root.get_texture().get_image().save_png(cpath) == OK:
						ok += 1
						print("WING ", cpath)
					Equipment.unequip_accessory(wh)
				if is_instance_valid(wing) and wing.get_parent() == null:
					wing.free()
		Equipment.unequip_weapon(handle)
		a.queue_free()
		if is_instance_valid(w) and w.get_parent() == null:
			w.free()
	print("CHAR_CAPTURE_OK ", ok)
	quit(0 if ok > 0 else 1)
