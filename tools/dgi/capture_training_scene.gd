extends SceneTree

func _initialize() -> void:
	call_deferred("run")

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

func run() -> void:
	var packed: PackedScene = load("res://scenes/training/training.tscn")
	if packed == null:
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	print("training actor=", scene.get("actor_ids")[int(scene.get("current_actor_index"))], " ready=", scene.get("actor") != null)
	print("ready capture=", await capture("/home/gamedev/darklord-dgi/screens/training-scene.png"))
	scene.call("launch_attack")
	await create_timer(0.7).timeout
	print("flight capture=", await capture("/home/gamedev/darklord-dgi/screens/training-flight.png"))
	await create_timer(0.65).timeout
	print("impact capture=", await capture("/home/gamedev/darklord-dgi/screens/training-impact.png"))
	var hp: int = int(scene.get("combat").get("hp"))
	print("training hp=", hp)
	quit(0 if hp == 90 else 2)
