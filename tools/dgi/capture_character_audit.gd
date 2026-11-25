extends SceneTree
## Multi-angle CHARACTER-AUDIT captures. Uses runtime Equipment + Attachment resources.
const Materials = preload("res://content/shaders/darklord_material.gd")
const Equipment = preload("res://actors/equipment.gd")

func _initialize():
	call_deferred("run")

func load_model(path: String) -> Node3D:
	var d := GLTFDocument.new()
	var s := GLTFState.new()
	if d.append_from_file(path, s) != OK:
		return null
	return d.generate_scene(s)

func setup_env() -> Camera3D:
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
	return cam

func capture(path: String) -> Error:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image().save_png(path)

func aim(cam: Camera3D, center: Vector3, offset: Vector3, fov: float) -> void:
	cam.position = center + offset
	cam.look_at(center)
	cam.fov = fov

func run():
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var base := "/home/gamedev/darklord-dgi/"
	var out := base + "screens/character-audit/"
	DirAccess.make_dir_recursive_absolute(out)
	var cam := setup_env()
	var actors := {"10001":"100011000","20001":"200011000","30001":"300011000","40001":"400011000"}
	var records: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base + "material-params.json"))
	var ok := 0
	for id in actors:
		var weapon_id: String = actors[id]
		var a := load_model(base + "exports/" + id + ".glb")
		var w := load_model(base + "exports/weapon-" + weapon_id + ".glb")
		if a == null or w == null:
			print("LOAD_FAIL ", id)
			continue
		Materials.apply(a, records[id][0], "/home/gamedev/Darklord")
		Materials.apply(w, records[weapon_id][0], "/home/gamedev/Darklord")
		root.add_child(a)
		var handle := Equipment.equip_weapon(a, w, weapon_id)
		var players := a.find_children("*", "AnimationPlayer", true, false)
		if handle.is_empty() or players.is_empty():
			print("EQUIP_FAIL ", id)
			a.free()
			continue
		var player := players[0] as AnimationPlayer
		var center := Vector3(0, 1.0, 0)
		var marker: Node3D = null
		if handle.get("mode")=="single":
			marker = handle.get("bone_socket")
			if marker == null:
				marker = handle.get("marker")
		elif handle.get("attachments"):
			var first: Dictionary = handle["attachments"][0]
			marker = first.get("bone_socket")
			if marker == null:
				marker = first.get("marker")
		for clip in ["stand", "attack001"]:
			if not player.has_animation(clip):
				continue
			player.play(clip)
			player.seek(player.get_animation(clip).length * 0.45, true)
			player.pause()
			var shots := {
				"front": Vector3(0.0, 0.4, 3.2),
				"back": Vector3(0.0, 0.4, -3.2),
				"side": Vector3(3.2, 0.4, 0.0),
				"angle45": Vector3(2.2, 0.8, 2.2),
			}
			for name in shots:
				aim(cam, center, shots[name], 38.0)
				var path: String = out + id + "-" + clip + "-" + String(name) + ".png"
				var err := await capture(path)
				print("SHOT ", path, " ", err)
				if err == OK:
					ok += 1
			if marker != null:
				aim(cam, marker.global_position, Vector3(0.35, 0.2, 0.55), 28.0)
				var gpath: String = out + id + "-" + clip + "-hand.png"
				var gerr := await capture(gpath)
				print("HAND ", gpath, " ", gerr)
				if gerr == OK:
					ok += 1
			player.stop()
		Equipment.unequip_weapon(handle)
		a.free()
		if is_instance_valid(w) and w.get_parent() == null:
			w.free()
	print("CAPTURES_OK ", ok)
	quit(0 if ok > 0 else 1)
