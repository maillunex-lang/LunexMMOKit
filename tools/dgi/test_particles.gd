extends SceneTree
const Preview = preload("res://particle_preview.gd")
func _initialize():
	call_deferred("run")
func run():
	var records: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("/home/gamedev/darklord-dgi/particle-index.json"))
	var count := 0
	for key in records:
		var node := Preview.build(records[key],"/home/gamedev/Darklord")
		root.add_child(node)
		print(key," converted=",node.get_child_count()," source=",records[key].size())
		count += node.get_child_count()
		await process_frame
		node.free()
	quit(0 if count==8 else 1)
