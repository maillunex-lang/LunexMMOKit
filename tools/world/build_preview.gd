extends SceneTree
func _initialize():
	var scene: Node3D = load("res://world/imported/mh_scene_07_geometry.tscn").instantiate()
	var camera := Camera3D.new()
	camera.name = "OriginalCamera"
	camera.fov = 40
	camera.near = 1
	camera.far = 120
	var parent: Node3D = scene.get_node("Object_568556382")
	parent.add_child(camera)
	camera.owner = scene
	var env := WorldEnvironment.new()
	env.name = "Environment"
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.37170202,0.60723746,0.9191176)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.28650516,0.23129326,0.50735295)
	env.environment.ambient_light_energy = 1.0
	scene.add_child(env)
	env.owner = scene
	var nav := scene.get_node("Object_477512445/Object_359807223/Object_1817125895/NavigationSource") as MeshInstance3D
	var body := StaticBody3D.new()
	body.name = "WalkCollision"
	nav.add_child(body)
	body.owner = scene
	var shape := CollisionShape3D.new()
	shape.shape = nav.mesh.create_trimesh_shape()
	body.add_child(shape)
	shape.owner = scene
	var packed := PackedScene.new()
	if packed.pack(scene) != OK:
		quit(1)
		return
	var path := "res://world/imported/mh_scene_07_preview.tscn"
	if FileAccess.file_exists(path):
		push_error("Refusing overwrite")
		quit(1)
		return
	var err := ResourceSaver.save(packed,path)
	scene.free()
	quit(err)
