extends SceneTree
func _initialize() -> void:
	call_deferred("go")
func go() -> void:
	var scene: Node3D = load("res://scenes/training/training.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	for i in range(4):
		scene._load_actor(i)
		await process_frame
		scene._select_accessory(1,"mount")
		var ap: AnimationPlayer = scene.animation_player
		assert(ap.current_animation == "mount_stand")
		ap.seek(0.5, true)
		ap.advance(0.0)
		scene._update_camera()
		await RenderingServer.frame_post_draw
		var path: String = "/home/gamedev/darklord-dgi/screens/mount-fix-%d.png" % i
		var err: Error = scene.get_viewport().get_texture().get_image().save_png(path)
		print("CAPTURE ",i," ",err," ",path)
		scene._select_accessory(0,"mount")
	scene.queue_free()
	await process_frame
	quit()
