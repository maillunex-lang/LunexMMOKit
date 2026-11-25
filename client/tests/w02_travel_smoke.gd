extends SceneTree
## W02: round-trip portal coords + safe zones + minimap UV.

const Registry = preload("res://world/location_registry.gd")
const Travel = preload("res://world/world_travel.gd")
const Minimap = preload("res://ui/hud/minimap.gd")
const MapPanel = preload("res://ui/hud/world_map_panel.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var fails: PackedStringArray = []
	# Registry completeness
	for id in ["eternity_capital", "ashen_outskirts", "shard_ruins"]:
		if not Registry.has(id):
			fails.append("missing " + id)
		elif not ResourceLoader.exists(Registry.scene_path(id)):
			fails.append("scene " + id)
		else:
			print("OK loc ", id, " spawn=", Registry.spawn_point(id))
	# Round-trip capital → ashen → capital with recorded exit/landing
	var session: Node = root.get_node_or_null("/root/GameSession")
	if session == null:
		fails.append("GameSession missing")
		_finish(fails)
		return
	session.current_location = "eternity_capital"
	var exit_cap := Vector3(12.5, 1.0, -48.0)
	var land_ashen := Vector3.ZERO
	var land_cap := Vector3.ZERO
	var out: Dictionary = Travel.prepare_portal(session, "eternity_capital", "portal_ashen_gate", exit_cap)
	if not bool(out.get("ok", false)):
		fails.append("portal out")
	else:
		land_ashen = out["landing"]
		print("OK out exit=", exit_cap, " land=", land_ashen, " loc=", session.current_location)
		if session.current_location != "ashen_outskirts":
			fails.append("loc after out")
		if not session.pending_spawn_valid:
			fails.append("pending missing")
		if session.exit_position.distance_to(exit_cap) > 0.01:
			fails.append("exit mismatch")
		var applied: Vector3 = session.consume_pending_spawn()
		if applied.distance_to(land_ashen) > 0.01:
			fails.append("consume landing")
		if session.pending_spawn_valid:
			fails.append("pending not cleared")
	# Return trip
	var exit_ashen := Vector3(3.0, 1.0, 5.0)
	var back: Dictionary = Travel.prepare_portal(session, "ashen_outskirts", "portal_capital_return", exit_ashen)
	if not bool(back.get("ok", false)):
		fails.append("portal back")
	else:
		land_cap = back["landing"]
		print("OK back exit=", exit_ashen, " land=", land_cap, " loc=", session.current_location)
		if session.current_location != "eternity_capital":
			fails.append("loc after back")
		var applied2: Vector3 = session.consume_pending_spawn()
		if applied2.distance_to(land_cap) > 0.01:
			fails.append("back landing")
		var expect_ashen: Vector3 = Registry.portal_landing("eternity_capital", "portal_ashen_gate")["landing"]
		var expect_cap: Vector3 = Registry.portal_landing("ashen_outskirts", "portal_capital_return")["landing"]
		if land_ashen.distance_to(expect_ashen) > 0.01 or land_cap.distance_to(expect_cap) > 0.01:
			fails.append("catalog landing drift")
		else:
			print("OK round-trip landings match catalog")
	# Safe zones
	if not Registry.in_safe_zone("eternity_capital", Vector3(0, 0, -20)):
		fails.append("capital safe")
	if Registry.in_safe_zone("ashen_outskirts", Vector3(200, 0, 200)):
		fails.append("ashen unsafe false+")
	else:
		print("OK safe zones")
	session.mark_safe_position("eternity_capital", Vector3(0, 1, -60))
	if session.last_safe_location != "eternity_capital":
		fails.append("safe mark")
	# Minimap UV + panel
	var mm: Control = Minimap.new()
	root.add_child(mm)
	mm.set_location("route_corridor")
	mm.update_hero(Vector3(0, 1, 325))
	var uv := Registry.world_to_map_uv("route_corridor", Vector3(0, 1, 325))
	print("OK minimap uv=", uv)
	if uv.y < 0.4 or uv.y > 0.6:
		fails.append("uv mid")
	var panel: Control = MapPanel.new()
	root.add_child(panel)
	panel.show_map("eternity_capital", Vector3(0, 1, -20), ["eternity_capital", "ashen_outskirts"])
	if not panel.visible:
		fails.append("map panel")
	else:
		print("OK world map panel")
	panel.hide_map()
	mm.queue_free()
	panel.queue_free()
	# Respawn helper
	var rs: Dictionary = Travel.prepare_respawn(session, "shard_ruins")
	if not bool(rs.get("ok", false)):
		fails.append("respawn")
	else:
		print("OK respawn ", rs.get("landing"))
	_finish(fails)

func _finish(fails: PackedStringArray) -> void:
	if fails.is_empty():
		print("W02_TRAVEL_SMOKE_OK")
		quit(0)
		return
	for f in fails:
		print("FAIL ", f)
	print("W02_TRAVEL_SMOKE_FAIL")
	quit(1)
