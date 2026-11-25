extends SceneTree
## CAP04: add direct FBX placements (water, crystal mesh, walksurface) onto v7 capital.
const BASE := "user://dgi/" ## research-only; copy from LUNEX_DGI_ROOT outside git
func read_json(path: String):
	return JSON.parse_string(FileAccess.get_file_as_string(BASE + path))
func glb_meshes(glb: String) -> Array:
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(BASE + "city-glb/" + glb, state) != OK:
		return []
	var model := doc.generate_scene(state)
	root.add_child(model)
	var copies: Array = []
	for n in model.find_children("*", "MeshInstance3D", true, false):
		var rel: Transform3D = model.global_transform.affine_inverse() * n.global_transform
		copies.append({"name": String(n.name), "mesh": n.mesh, "transform": rel})
	model.free()
	return copies
func water_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.15, 0.35, 0.55, 0.65)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.15
	m.metallic = 0.05
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m
func crystal_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.55, 0.85, 1.0, 0.85)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true
	m.emission = Color(0.2, 0.55, 0.9)
	m.emission_energy_multiplier = 1.5
	m.roughness = 0.2
	return m
func _initialize():
	call_deferred("run")
func run():
	var placements: Array = read_json("city-placements.json")
	var classify: Dictionary = read_json("city-cap04-classify.json")
	var by_id := {}
	for p in placements:
		by_id[str(p.id)] = p
	var city: Node3D = load("res://world/imported/capital_geometry_v7.tscn").instantiate()
	root.add_child(city)
	var layout: Node3D = load("res://world/imported/cs_yw_zhucheng01_layout.tscn").instantiate()
	root.add_child(layout)
	var parents := {}
	for node in layout.find_children("*", "Node3D", true, false):
		if node.has_meta("source_id"):
			parents[str(node.get_meta("source_id"))] = node
	var added := 0
	var mesh_count := 0
	for row in classify.get("include_as_direct_fbx", []):
		var pid := str(row.id)
		if not by_id.has(pid):
			print("MISSING_PLACEMENT ", pid)
			continue
		var p: Dictionary = by_id[pid]
		var meshes: Array = glb_meshes(String(row.glb))
		if meshes.is_empty():
			print("NO_MESHES ", row.glb)
			continue
		var n := Node3D.new()
		n.name = "Prefab_" + pid
		city.add_child(n)
		n.owner = city
		n.position = Vector3(p.position[0], p.position[1], p.position[2])
		n.quaternion = Quaternion(p.rotation[0], p.rotation[1], p.rotation[2], p.rotation[3]).normalized()
		n.scale = Vector3(p.scale[0], p.scale[1], p.scale[2])
		var parent_key := str(int(p.parent))
		if parents.has(parent_key):
			n.transform = parents[parent_key].global_transform * n.transform
		n.set_meta("source_asset", p.asset)
		n.set_meta("source_parent", p.parent)
		n.set_meta("cap04_role", String(row.role))
		for mrow in meshes:
			var mi := MeshInstance3D.new()
			mi.name = "Mesh_" + String(mrow.name)
			mi.mesh = mrow.mesh
			# Placement already carries Unity FBX ±90 axis conversion. Keep GLB translation/scale
			# but drop GLB local rotation to avoid double -90 (water became a vertical plane).
			var rel: Transform3D = mrow.transform
			mi.position = rel.origin
			mi.scale = rel.basis.get_scale()
			mi.rotation = Vector3.ZERO
			n.add_child(mi)
			mi.owner = city
			if String(row.role) == "water":
				for i in range(mi.mesh.get_surface_count()):
					mi.set_surface_override_material(i, water_material())
			elif String(row.role) == "crystal_mesh":
				for i in range(mi.mesh.get_surface_count()):
					mi.set_surface_override_material(i, crystal_material())
			elif String(row.role) == "walksurface":
				mi.visible = false
				mi.set_meta("walksurface", true)
			mesh_count += 1
		added += 1
		print("ADDED ", row.role, " meshes ", meshes.size())
	layout.free()
	var path := "res://world/imported/capital_geometry_v8.tscn"
	if FileAccess.file_exists(path):
		print("REFUSE_OVERWRITE")
		city.free()
		quit(1)
		return
	var packed := PackedScene.new()
	packed.pack(city)
	var err := ResourceSaver.save(packed, path)
	print("CAP04_ADDED ", added, " MESHES ", mesh_count, " SAVE ", err)
	city.free()
	quit(0 if err == OK and added == 3 else 1)
