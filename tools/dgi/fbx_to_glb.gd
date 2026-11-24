extends SceneTree
func _initialize():
	var job_text := FileAccess.get_file_as_string("res://job.json")
	var job: Dictionary = JSON.parse_string(job_text)
	if job == null or not job.has("output"):
		quit(2)
		return
	var scene := load("res://model.fbx") as PackedScene
	if scene == null:
		quit(3)
		return
	var node := scene.instantiate()
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_scene(node, state)
	if err == OK:
		err = doc.write_to_filesystem(state, String(job["output"]))
	node.free()
	quit(0 if err == OK else 4)
