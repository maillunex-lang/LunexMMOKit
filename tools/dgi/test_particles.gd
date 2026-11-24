extends SceneTree
const Preview = preload("res://particle_preview.gd")

func _initialize():
	call_deferred("run")

func run():
	var records: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("/home/gamedev/darklord-dgi/particle-index.json"))
	var expected := {
		"FS_W_attack001.prefab": 3,
		"FS_hti.prefab": 5,
	}
	var total := 0
	var failures := []
	for key in records:
		var payload: Dictionary = records[key]
		var node: Node3D = Preview.build(payload, "/home/gamedev/Darklord")
		root.add_child(node)
		var count: int = Preview.emitter_count(node)
		var hierarchy_count: int = max(0, node.find_children("*", "Node3D", true, false).size() - count)
		var expected_count := 0
		for suffix in expected:
			if key.ends_with(suffix):
				expected_count = expected[suffix]
		var ok: bool = count == expected_count and count == payload.get("emitters", []).size()
		print(key, " emitters=", count, " hierarchy_nodes=", hierarchy_count, " source_emitters=", payload.get("emitters", []).size(), " ok=", ok)
		if not ok:
			failures.append(key)
		total += count
		await process_frame
		Preview.dispose(node)
	print("total_emitters=", total, " failures=", failures)
	quit(0 if failures.is_empty() and total == 8 else 1)
