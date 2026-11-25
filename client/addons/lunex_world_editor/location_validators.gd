extends RefCounted
## WORLD-EDITOR-003 location validators (editor + headless CI).

static func collect_stable(root: Node, kind: String = "") -> Array:
	var out: Array = []
	_walk(root, out, kind)
	return out

static func _walk(n: Node, out: Array, kind: String) -> void:
	if n.has_meta("stable_id"):
		var role := String(n.get_meta("npc_role", ""))
		var portal := n.has_meta("portal_id") or String(n.name).begins_with("Portal")
		var spawn := String(n.name).contains("Spawn") or n.has_meta("respawn_id")
		var match := kind == "" \
			or (kind == "npc" and (role != "" or String(n.name).begins_with("Quest") or String(n.name).begins_with("Plaza"))) \
			or (kind == "portal" and portal) \
			or (kind == "spawn" and spawn)
		if match:
			out.append({"node": String(n.get_path()), "stable_id": String(n.get_meta("stable_id")), "pos": (n as Node3D).global_position if n is Node3D else Vector3.ZERO})
	for c in n.get_children():
		_walk(c, out, kind)

static func validate_location(root: Node3D) -> Dictionary:
	var issues: Array = []
	var spawns := collect_stable(root, "spawn")
	var npcs := collect_stable(root, "npc")
	var portals := collect_stable(root, "portal")
	if spawns.is_empty():
		# Fallback: conventional PlayerSpawn node without meta yet.
		var ps := root.find_child("PlayerSpawn", true, false)
		if ps is Node3D:
			spawns.append({"node": String(ps.get_path()), "stable_id": "PlayerSpawn", "pos": ps.global_position})
		else:
			issues.append({"code": "no_spawn", "msg": "No PlayerSpawn / spawn stable_id"})
	# Floating props: MeshInstance/StaticBody roots high above origin without nearby floor probe (heuristic).
	for mi in root.find_children("*", "StaticBody3D", true, false):
		if mi is Node3D and mi.global_position.y > 8.0:
			issues.append({"code": "floating_high", "node": String(mi.get_path()), "y": mi.global_position.y})
	# Duplicate stable_id
	var seen := {}
	for entry in collect_stable(root):
		var sid: String = entry.stable_id
		if seen.has(sid):
			issues.append({"code": "duplicate_stable_id", "stable_id": sid, "nodes": [seen[sid], entry.node]})
		else:
			seen[sid] = entry.node
	# Nav presence
	var region := root.find_child("NavigationRegion3D", true, false)
	if region == null or (region as NavigationRegion3D).navigation_mesh == null:
		issues.append({"code": "no_navmesh", "msg": "Bake NavigationMesh before auto-path"})
	return {
		"ok": issues.is_empty(),
		"issues": issues,
		"counts": {"spawns": spawns.size(), "npcs": npcs.size(), "portals": portals.size()},
		"location_revision": int(root.get_meta("location_revision", 0)),
	}
