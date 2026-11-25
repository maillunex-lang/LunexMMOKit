extends RefCounted
## CHAR06: inventory skinned mesh parts and combo AABB sanity (body+weapon+wing).

static func mesh_inventory(actor: Node3D) -> Dictionary:
	var meshes: PackedStringArray = []
	var skinned := 0
	var missing_mat := 0
	for mesh in actor.find_children("*", "MeshInstance3D", true, false):
		meshes.append(String(mesh.name))
		if mesh.skin != null:
			skinned += 1
		var mat: Material = mesh.get_active_material(0)
		if mat == null and mesh.mesh != null and mesh.mesh.get_surface_count() > 0:
			missing_mat += 1
	var bones: PackedStringArray = []
	var skel := actor.find_children("*", "Skeleton3D", true, false)
	if skel.size():
		var s: Skeleton3D = skel[0]
		for i in s.get_bone_count():
			bones.append(s.get_bone_name(i))
	return {
		"mesh_count": meshes.size(),
		"meshes": meshes,
		"skinned": skinned,
		"missing_mat_surfaces": missing_mat,
		"has_head_bone": "Bip001 Head" in bones,
		"has_r_hand": "Bip001 R Hand" in bones,
		"has_l_hand": "Bip001 L Hand" in bones,
		"has_body_mesh": _has_body(meshes),
	}

static func _has_body(meshes: PackedStringArray) -> bool:
	for m in meshes:
		var l := m.to_lower()
		if "body" in l or "tou" in l or l == "mesh":
			return true
	return meshes.size() > 0

static func aabb_of(node: Node3D) -> AABB:
	var first := true
	var out := AABB()
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		if not mesh.visible:
			continue
		var ab: AABB = mesh.global_transform * mesh.get_aabb()
		if first:
			out = ab
			first = false
		else:
			out = out.merge(ab)
	return out

## Returns overlap volume proxy (intersection size product) between body and item.
static func overlap_score(body: Node3D, item: Node3D) -> float:
	var a := aabb_of(body)
	var b := aabb_of(item)
	if a.size == Vector3.ZERO or b.size == Vector3.ZERO:
		return 0.0
	var mn := Vector3(
		maxf(a.position.x, b.position.x),
		maxf(a.position.y, b.position.y),
		maxf(a.position.z, b.position.z)
	)
	var mx := Vector3(
		minf(a.position.x + a.size.x, b.position.x + b.size.x),
		minf(a.position.y + a.size.y, b.position.y + b.size.y),
		minf(a.position.z + a.size.z, b.position.z + b.size.z)
	)
	var d := mx - mn
	if d.x <= 0.0 or d.y <= 0.0 or d.z <= 0.0:
		return 0.0
	return d.x * d.y * d.z
