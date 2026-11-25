extends SceneTree
func _initialize():
	call_deferred("capture")
func capture():
	var scene: Node3D = load("res://world/imported/mh_scene_07_corrected.tscn").instantiate()
	root.add_child(scene)
	root.size = Vector2i(1280,720)
	var camera: Camera3D = scene.get_node("Object_568556382/OriginalCamera")
	camera.make_current()
	var mesh: MeshInstance3D = scene.get_node("Object_477512445/Object_311392025/Object_1435492447/GroundMesh")
	var bounds: AABB = mesh.global_transform * mesh.get_aabb()
	print("BOUNDS ",bounds," CAMERA ",camera.global_transform)
	var center := bounds.get_center()
	camera.far = maxf(120,bounds.size.length()*4)

	await process_frame
	await RenderingServer.frame_post_draw
	var err := root.get_texture().get_image().save_png("user://screens/world-corrected-camera.png")
	print("CAPTURE ",err)
	quit(err)
