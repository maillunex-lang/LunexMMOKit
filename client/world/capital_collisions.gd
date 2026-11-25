extends Node3D
## Builds editable StaticBody3D collisions from walksurface + named ground meshes.
## Collision nodes are children of this node so they can be inspected/saved separately.
@export var geometry_root: Node3D
@export var include_terrain := true
@export var max_terrain_meshes := 4
@export var spawn_pad_center := Vector3(90, 52, -140)
@export var spawn_pad_size := Vector3(60, 2, 60)

func rebuild() -> int:
	for c in get_children():
		c.queue_free()
	var count := 0
	count += _add_spawn_pad()
	if geometry_root == null:
		return count
	count += _add_from_meta("walksurface")
	count += _add_from_role("walksurface")
	if include_terrain:
		count += _add_terrain()
	return count

func _add_spawn_pad() -> int:
	var body := StaticBody3D.new()
	body.name = "SpawnPad"
	add_child(body)
	body.position = spawn_pad_center
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = spawn_pad_size
	col.shape = box
	body.add_child(col)
	body.set_meta("spawn_pad", true)
	return 1

func _add_from_meta(meta_key: String) -> int:
	var n := 0
	for mi in geometry_root.find_children("*", "MeshInstance3D", true, false):
		if not mi.has_meta(meta_key):
			continue
		if _add_mesh_body(mi, "Walk_" + String(mi.name)):
			n += 1
	return n

func _add_from_role(role: String) -> int:
	var n := 0
	for prefab in geometry_root.get_children():
		if String(prefab.get_meta("cap04_role", "")) != role:
			continue
		for mi in prefab.find_children("*", "MeshInstance3D", true, false):
			if _add_mesh_body(mi, "Role_" + role + "_" + String(mi.name)):
				n += 1
	return n

func _add_terrain() -> int:
	var candidates: Array = []
	for mi in geometry_root.find_children("*", "MeshInstance3D", true, false):
		var asset := ""
		var p: Node = mi
		while p:
			if p.has_meta("source_asset"):
				asset = String(p.get_meta("source_asset"))
				break
			p = p.get_parent()
		var name_l := String(mi.name).to_lower()
		if "terrain" in asset.to_lower() or "dixing" in asset.to_lower() or "terrain" in name_l:
			var b: AABB = mi.get_aabb()
			candidates.append({"mi": mi, "area": b.size.x * b.size.z})
	candidates.sort_custom(func(a, b): return a.area > b.area)
	var n := 0
	for i in range(mini(candidates.size(), max_terrain_meshes)):
		if _add_mesh_body(candidates[i].mi, "Terrain_" + String(candidates[i].mi.name)):
			n += 1
	return n

func _add_mesh_body(mi: MeshInstance3D, body_name: String) -> bool:
	if mi.mesh == null:
		return false
	var body := StaticBody3D.new()
	body.name = body_name
	add_child(body)
	body.global_transform = mi.global_transform
	var shape := mi.mesh.create_trimesh_shape()
	if shape == null:
		body.queue_free()
		return false
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	body.set_meta("source_mesh", mi.get_path())
	return true
