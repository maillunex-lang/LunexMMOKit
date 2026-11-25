extends SceneTree
## Compare v7 prefab global origins with placement×parent expectation.
func _initialize():
	call_deferred("run")
func run():
	var base := "/home/gamedev/darklord-dgi/"
	var placements: Array = JSON.parse_string(FileAccess.get_file_as_string(base + "city-placements.json"))
	var city: Node3D = load("res://world/imported/capital_geometry_v7.tscn").instantiate()
	root.add_child(city)
	var layout: Node3D = load("res://world/imported/cs_yw_zhucheng01_layout.tscn").instantiate()
	root.add_child(layout)
	var parents := {}
	for node in layout.find_children("*", "Node3D", true, false):
		if node.has_meta("source_id"):
			parents[str(node.get_meta("source_id"))] = node
	var by_id := {}
	for p in placements:
		by_id[str(p.id)] = p
	var rows: Array = []
	var checked := 0
	var within_1 := 0
	var within_5 := 0
	for n in city.get_children():
		var name: String = String(n.name)
		if not name.begins_with("Prefab_"):
			continue
		var pid: String = name.trim_prefix("Prefab_")
		if not by_id.has(pid):
			continue
		var p: Dictionary = by_id[pid]
		var local := Transform3D(
			Basis(Quaternion(p.rotation[0], p.rotation[1], p.rotation[2], p.rotation[3]).normalized()).scaled(Vector3(p.scale[0], p.scale[1], p.scale[2])),
			Vector3(p.position[0], p.position[1], p.position[2])
		)
		var expected := local
		var parent_key := str(int(p.parent))
		if parents.has(parent_key):
			expected = parents[parent_key].global_transform * local
		var got: Vector3 = n.global_position
		var exp_pos: Vector3 = expected.origin
		var delta: float = got.distance_to(exp_pos)
		checked += 1
		if delta <= 1.0:
			within_1 += 1
		if delta <= 5.0:
			within_5 += 1
		rows.append({
			"id": pid,
			"asset": String(p.asset).get_file(),
			"delta": delta,
			"got": [got.x, got.y, got.z],
			"expected": [exp_pos.x, exp_pos.y, exp_pos.z],
		})
	rows.sort_custom(func(a, b): return a.delta > b.delta)
	var report := {
		"checked": checked,
		"within_1m": within_1,
		"within_5m": within_5,
		"worst": rows.slice(0, mini(20, rows.size())),
	}
	FileAccess.open(base + "city-coord-compare-v7.json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("CHECKED ", checked, " WITHIN_1 ", within_1, " WITHIN_5 ", within_5)
	if rows.size() > 0:
		print("WORST ", rows[0])
	city.free()
	layout.free()
	quit(0 if checked > 0 and within_1 == checked else 2)
