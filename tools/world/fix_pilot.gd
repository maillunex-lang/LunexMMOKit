extends SceneTree
func _initialize():
	var scene: Node3D = load("res://world/imported/mh_scene_07_preview.tscn").instantiate()
	var ground: MeshInstance3D = scene.get_node("Object_477512445/Object_311392025/Object_1435492447/GroundMesh")
	ground.rotation.x = PI
	var nav: MeshInstance3D = scene.get_node("Object_477512445/Object_359807223/Object_1817125895/NavigationSource")
	nav.rotation.x = PI
	var env: WorldEnvironment = scene.get_node("Environment")
	var light := DirectionalLight3D.new()
	light.name = "DiagnosticLight"
	light.rotation_degrees = Vector3(-55,-30,0)
	light.light_energy = 1.1
	scene.add_child(light)
	light.owner = scene
	var packed := PackedScene.new()
	packed.pack(scene)
	var path := "res://world/imported/mh_scene_07_corrected.tscn"
	if FileAccess.file_exists(path):
		quit(1)
		return
	var err := ResourceSaver.save(packed,path)
	scene.free()
	quit(err)
