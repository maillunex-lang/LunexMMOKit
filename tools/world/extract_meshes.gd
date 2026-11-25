extends SceneTree
func _initialize():
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file("res://world/models/FB_12_dm.glb",state) != OK:
		quit(1)
		return
	var scene := doc.generate_scene(state)
	for n in scene.find_children("*","MeshInstance3D",true,false):
		var mesh: Mesh = n.mesh
		var err := ResourceSaver.save(mesh,"res://world/models/"+str(n.name)+".res")
		print(n.name," ",err)
		if err != OK:
			scene.free()
			quit(1)
			return
	scene.free()
	quit()
