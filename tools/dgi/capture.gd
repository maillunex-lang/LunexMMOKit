extends SceneTree
const Materials = preload("res://darklord_material.gd")
const Equipment = preload("res://equipment.gd")

func _initialize():
	call_deferred("run")

func load_model(path: String) -> Node3D:
	var d := GLTFDocument.new()
	var s := GLTFState.new()
	if d.append_from_file(path, s) != OK:
		return null
	return d.generate_scene(s)

func add_camera() -> Camera3D:
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.position = Vector3(2.0, 1.5, 3.2)
	cam.look_at(Vector3(0, 1.0, 0))
	cam.current = true
	cam.fov = 38
	cam.near = 0.02
	return cam

func add_light() -> void:
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

func capture(path: String) -> Error:
	await process_frame
	await RenderingServer.frame_post_draw
	var tmp := path + ".tmp.png"
	var result := root.get_texture().get_image().save_png(tmp)
	if result == OK:
		result = DirAccess.rename_absolute(tmp, path)
		if result != OK:
			DirAccess.remove_absolute(tmp)
	return result

func full_camera(cam: Camera3D) -> void:
	cam.position = Vector3(2.0, 1.5, 3.2)
	cam.look_at(Vector3(0, 1.0, 0))
	cam.fov = 38

func alt_camera(cam: Camera3D) -> void:
	cam.position = Vector3(-2.0, 1.5, 3.2)
	cam.look_at(Vector3(0, 1.0, 0))
	cam.fov = 38

func grip_camera(cam: Camera3D, marker: Node3D) -> void:
	var focus := marker.global_position
	cam.position = focus + Vector3(0.38, 0.22, 0.58)
	cam.look_at(focus)
	cam.fov = 30

func grip_alt_camera(cam: Camera3D, marker: Node3D) -> void:
	var focus := marker.global_position
	cam.position = focus + Vector3(-0.42, 0.28, 0.52)
	cam.look_at(focus)
	cam.fov = 30

func primary_marker(handle: Dictionary) -> Node3D:
	if String(handle.get("mode", "")) == "single":
		return handle.get("marker", null)
	var attachments: Array = handle.get("attachments", [])
	if attachments.size() > 0:
		return attachments[0].get("marker", null)
	return null

func run():
	var base := "/home/gamedev/darklord-dgi/"
	var cam := add_camera()
	add_light()
	var actors := {
		"10001": "100011000",
		"20001": "200011000",
		"30001": "300011000",
		"40001": "400011000",
	}
	for id in actors:
		var weapon_id: String = actors[id]
		var a := load_model(base + "exports/" + id + ".glb")
		var w := load_model(base + "exports/weapon-" + weapon_id + ".glb")
		if a == null or w == null:
			quit(1)
			return
		var records: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base + "material-params.json"))
		var body_count := Materials.apply(a, records[id][0], "/home/gamedev/Darklord")
		print("BODY ", id, " meshes=", body_count)
		if body_count == 0:
			quit(5)
			return
		var material_count := Materials.apply(w, records[weapon_id][0], "/home/gamedev/Darklord")
		print("MATERIAL ", id, " meshes=", material_count)
		if material_count == 0:
			quit(4)
			return
		root.add_child(a)
		var handle := Equipment.equip_weapon(a, w, weapon_id)
		if handle.is_empty():
			quit(2)
			return
		var marker := primary_marker(handle)
		if marker == null:
			quit(3)
			return
		var players := a.find_children("*", "AnimationPlayer", true, false)
		if players.size() == 0:
			quit(6)
			return
		var player := players[0] as AnimationPlayer
		for clip in ["stand", "attack001"]:
			if not player.has_animation(clip):
				print("missing ", id, " ", clip)
				continue
			player.play(clip)
			player.seek(player.get_animation(clip).length * 0.45, true)
			player.pause()
			full_camera(cam)
			print(id, " ", clip, " save=", await capture(base + "screens/" + id + "-" + clip + ".png"))
			alt_camera(cam)
			await capture(base + "screens/" + id + "-" + clip + "-alt.png")
			grip_camera(cam, marker)
			print(id, " ", clip, " grip save=", await capture(base + "screens/" + id + "-" + clip + "-grip.png"))
			grip_alt_camera(cam, marker)
			await capture(base + "screens/" + id + "-" + clip + "-grip-alt.png")
			player.stop()
		if not Equipment.unequip_weapon(handle):
			quit(7)
			return
		a.free()
		if is_instance_valid(w) and w.get_parent() == null:
			w.free()
	quit(0)
