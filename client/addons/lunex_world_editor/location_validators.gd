extends RefCounted
## FIX-007: location diagnostics for editor + headless CI.

static func collect_stable(root: Node, kind: String = "") -> Array:
	var out: Array = []
	_walk(root, out, kind)
	return out

static func _walk(n: Node, out: Array, kind: String) -> void:
	if n.has_meta("stable_id") or n.has_meta("instance_id"):
		var sid := String(n.get_meta("instance_id", n.get_meta("stable_id", "")))
		var role := String(n.get_meta("npc_role", ""))
		var portal := n.has_meta("portal_id") or String(n.get_meta("id_kind", "")).begins_with("portal") or String(n.name).begins_with("Portal")
		var spawn := String(n.name).contains("Spawn") or n.has_meta("respawn_id") or String(n.get_meta("id_kind", "")) == "spawn"
		var match := kind == "" \
			or (kind == "npc" and (role != "" or String(n.name).begins_with("Quest") or String(n.name).begins_with("Plaza"))) \
			or (kind == "portal" and portal) \
			or (kind == "spawn" and spawn) \
			or (kind == "quest" and (n.has_meta("quest_id") or String(n.get_meta("id_kind", "")) == "qobj"))
		if match:
			out.append({
				"node": String(n.get_path()),
				"stable_id": sid,
				"pos": (n as Node3D).global_position if n is Node3D else Vector3.ZERO,
			})
	for c in n.get_children():
		_walk(c, out, kind)

static func validate_location(root: Node3D) -> Dictionary:
	var issues: Array = []
	var spawns := collect_stable(root, "spawn")
	var npcs := collect_stable(root, "npc")
	var portals := collect_stable(root, "portal")
	var quests := collect_stable(root, "quest")

	if spawns.is_empty():
		var ps := root.find_child("PlayerSpawn", true, false)
		if ps is Node3D:
			spawns.append({"node": String(ps.get_path()), "stable_id": "PlayerSpawn", "pos": ps.global_position})
		else:
			issues.append({"code": "no_spawn", "msg": "No PlayerSpawn / spawn stable_id", "node": String(root.get_path())})

	var space := root.get_world_3d().direct_space_state if root.is_inside_tree() and root.get_world_3d() else null

	# Floating / sunk probes for StaticBody3D
	for mi in root.find_children("*", "StaticBody3D", true, false):
		if not (mi is Node3D):
			continue
		var body := mi as Node3D
		var y := body.global_position.y
		if y > 8.0:
			issues.append({"code": "floating_high", "msg": "y=%.1f" % y, "node": String(body.get_path())})
		if space:
			var dist := _surface_distance(space, body)
			if dist > 2.5:
				issues.append({"code": "hanging", "msg": "surface_gap=%.2f" % dist, "node": String(body.get_path())})
			elif dist < -1.0:
				issues.append({"code": "sunk", "msg": "surface_gap=%.2f" % dist, "node": String(body.get_path())})

	# Overlap heuristic: two StaticBody origins very close
	var bodies: Array = root.find_children("*", "StaticBody3D", true, false)
	for i in mini(bodies.size(), 80):
		for j in range(i + 1, mini(bodies.size(), 80)):
			var a: Node3D = bodies[i]
			var b: Node3D = bodies[j]
			if a.global_position.distance_to(b.global_position) < 0.05:
				issues.append({"code": "overlap_origin", "msg": "same origin", "node": String(a.get_path())})
				break

	# Duplicate IDs
	var seen := {}
	for entry in collect_stable(root):
		var sid: String = entry.stable_id
		if sid.is_empty():
			continue
		if seen.has(sid):
			issues.append({"code": "duplicate_stable_id", "msg": sid, "stable_id": sid, "node": entry.node, "nodes": [seen[sid], entry.node]})
		else:
			seen[sid] = entry.node

	# Nav mesh with real polygons
	var region := root.find_child("NavigationRegion3D", true, false) as NavigationRegion3D
	if region == null:
		region = root.find_child("Navigation", true, false) as NavigationRegion3D
	if region == null or region.navigation_mesh == null:
		issues.append({"code": "no_navmesh", "msg": "Bake NavigationMesh before auto-path", "node": String(root.get_path())})
	elif region.navigation_mesh.get_polygon_count() <= 0:
		issues.append({"code": "empty_navmesh", "msg": "NavigationMesh has 0 polygons", "node": String(region.get_path())})
	else:
		# Connectivity: try path spawn → each NPC/portal
		if space and region.navigation_mesh.get_polygon_count() > 0 and root.is_inside_tree():
			var map := root.get_world_3d().navigation_map
			var spawn_pos := spawns[0].pos if spawns.size() else root.global_position
			for entry in npcs + portals + quests:
				var path: PackedVector3Array = NavigationServer3D.map_get_path(map, spawn_pos, entry.pos, true)
				if path.is_empty():
					issues.append({"code": "unreachable", "msg": "no nav path from spawn", "node": entry.node, "stable_id": entry.stable_id})

	# Missing PackedScene / mesh resources on MeshInstance
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_inst := mi as MeshInstance3D
		if mesh_inst.mesh == null:
			issues.append({"code": "missing_mesh", "msg": "MeshInstance3D.mesh is null", "node": String(mesh_inst.get_path())})
		else:
			for s in mesh_inst.mesh.get_surface_count():
				var mat := mesh_inst.get_active_material(s)
				if mat == null:
					issues.append({"code": "missing_material", "msg": "surface %d" % s, "node": String(mesh_inst.get_path())})
					break

	# Safe spawn: ray down from spawn should hit floor
	if space and spawns.size():
		var sp: Vector3 = spawns[0].pos
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(sp + Vector3(0, 2, 0), sp + Vector3(0, -5, 0)))
		if hit.is_empty():
			issues.append({"code": "unsafe_spawn", "msg": "no floor under spawn", "node": spawns[0].node})

	return {
		"ok": issues.is_empty(),
		"issues": issues,
		"counts": {"spawns": spawns.size(), "npcs": npcs.size(), "portals": portals.size(), "quests": quests.size()},
		"location_revision": int(root.get_meta("location_revision", 0)),
	}

static func _surface_distance(space: PhysicsDirectSpaceState3D, body: Node3D) -> float:
	var origin := body.global_position + Vector3(0, 30, 0)
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(origin, body.global_position + Vector3(0, -50, 0)))
	if hit.is_empty():
		return 999.0
	return body.global_position.y - float(hit.position.y)
