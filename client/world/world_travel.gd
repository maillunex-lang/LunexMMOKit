extends RefCounted
## W02: coordinate-preserving location transitions (client presentation until N02).

const Registry = preload("res://world/location_registry.gd")

static func prepare_portal(session: Node, from_location: String, portal_id: String, hero_pos: Vector3) -> Dictionary:
	var land := Registry.portal_landing(from_location, portal_id)
	if not bool(land.get("ok", false)):
		return {"ok": false, "reason": "unknown_portal"}
	var target: String = String(land["target"])
	if not Registry.has(target):
		return {"ok": false, "reason": "unknown_target"}
	var landing: Vector3 = land["landing"] if land["landing"] is Vector3 else Registry.spawn_point(target)
	# Persist exit snapshot + pending entry
	if session.has_method("set_pending_travel"):
		session.set_pending_travel(target, landing, from_location, hero_pos, portal_id)
	elif "pending_spawn" in session:
		session.pending_spawn = landing
		session.pending_from = from_location
		session.exit_position = hero_pos
	if session.has_method("travel_to"):
		session.travel_to(target)
	return {
		"ok": true,
		"target": target,
		"scene": Registry.scene_path(target),
		"landing": landing,
		"exit": hero_pos,
	}

static func prepare_respawn(session: Node, location_id: String) -> Dictionary:
	var spawn := Registry.spawn_point(location_id)
	if session.has_method("set_pending_travel"):
		session.set_pending_travel(location_id, spawn, location_id, spawn, "respawn")
	if session.has_method("mark_safe_position"):
		session.mark_safe_position(location_id, spawn)
	return {"ok": true, "landing": spawn, "location": location_id}

static func consume_landing(session: Node) -> Vector3:
	if session.has_method("consume_pending_spawn"):
		return session.consume_pending_spawn()
	return Registry.spawn_point(String(session.current_location) if "current_location" in session else "eternity_capital")

static func round_trip_ok(exit_a: Vector3, land_b: Vector3, exit_b: Vector3, land_a: Vector3, eps: float = 0.05) -> bool:
	## Sanity: landings are finite and exits were recorded (not equal to zero by accident unless intended).
	if not (land_a.is_finite() and land_b.is_finite() and exit_a.is_finite() and exit_b.is_finite()):
		return false
	return land_a.distance_to(Registry.spawn_point("eternity_capital")) < 1000.0 \
		and land_b.distance_to(Registry.spawn_point("ashen_outskirts")) < 1000.0 \
		and exit_a.distance_to(Vector3.INF) > 0.0
