extends Node
## FIX-009: location-independent player session (client cache).
## Server authority supersedes this in N01+; until then marked as local prototype.

signal changed
signal location_changed(from_id: String, to_id: String)

const SAVE_PATH := "user://game_session_v1.json"

var class_actor_id: String = "10001"
var class_index: int = 0
var level: int = 1
var xp: int = 0
var hp: int = 500
var max_hp: int = 500
var mp: int = 100
var max_mp: int = 100
var currency: int = 0
var combat_power: int = 0
var inventory: Array = []
var equipment: Dictionary = {}
var active_quests: Dictionary = {}
var completed_quests: Array = []
var quest_progress: Dictionary = {}
var unlocked_locations: Array = ["eternity_capital"]
var current_location: String = "eternity_capital"
## W02: pending portal landing + last safe/exit coords (client presentation until N02)
var pending_spawn: Vector3 = Vector3.ZERO
var pending_spawn_valid := false
var pending_from: String = ""
var pending_portal_id: String = ""
var exit_position: Vector3 = Vector3.ZERO
var last_safe_location: String = "eternity_capital"
var last_safe_position: Vector3 = Vector3(0, 1, -60)
var prototype_local := true ## true until authoritative server owns state
## N01 / FIX-009: auth bridge (client cache of server session)
var server_url: String = "http://127.0.0.1:18080"
var auth_token: String = ""
var account_id: int = 0
var account_login: String = ""
var character_id: int = 0
var character_name: String = ""
var protocol_version: int = 1

func _ready() -> void:
	load_from_disk()

func apply_auth(res: Dictionary, login: String = "") -> void:
	## Store login/register response fields for reconnect.
	if login != "":
		account_login = login
	auth_token = String(res.get("token", auth_token))
	account_id = int(res.get("account_id", account_id))
	protocol_version = int(res.get("protocol_version", protocol_version))
	if auth_token != "":
		prototype_local = false
	save_to_disk()
	changed.emit()

func apply_character(ch: Dictionary) -> void:
	character_id = int(ch.get("id", character_id))
	character_name = String(ch.get("name", character_name))
	if ch.has("class_actor_id"):
		class_actor_id = String(ch.get("class_actor_id"))
	if ch.has("level"):
		level = int(ch.get("level"))
	if ch.has("location_id"):
		current_location = String(ch.get("location_id"))
	save_to_disk()
	changed.emit()

func clear_auth() -> void:
	auth_token = ""
	account_id = 0
	character_id = 0
	character_name = ""
	prototype_local = true
	save_to_disk()
	changed.emit()

func has_server_session() -> bool:
	return auth_token != "" and account_id > 0

func reset_new_character(actor_id: String, idx: int) -> void:
	class_actor_id = actor_id
	class_index = idx
	level = 1
	xp = 0
	hp = max_hp
	mp = max_mp
	currency = 0
	combat_power = 0
	inventory = []
	equipment = {}
	active_quests = {}
	completed_quests = []
	quest_progress = {}
	unlocked_locations = ["eternity_capital"]
	current_location = "eternity_capital"
	save_to_disk()
	changed.emit()

func set_vitals(h: int, mh: int, m: int, mm: int) -> void:
	hp = h
	max_hp = mh
	mp = m
	max_mp = mm
	changed.emit()

func set_class(actor_id: String, idx: int) -> void:
	class_actor_id = actor_id
	class_index = idx
	changed.emit()

func sync_quest_log(log_node: Node) -> void:
	if log_node == null:
		return
	if log_node.has_method("export_state"):
		var st: Dictionary = log_node.export_state()
		active_quests = st.get("active", {}).duplicate(true)
		completed_quests = st.get("completed", [])
		xp = int(st.get("xp", xp))
	else:
		if "active" in log_node:
			active_quests = (log_node.active as Dictionary).duplicate(true)
		if "completed" in log_node:
			var c = log_node.completed
			if c is PackedStringArray or c is Array:
				completed_quests = []
				for id in c:
					completed_quests.append(String(id))
		if "xp" in log_node:
			xp = int(log_node.xp)
	save_to_disk()
	changed.emit()

func apply_to_quest_log(log_node: Node) -> void:
	if log_node == null:
		return
	if log_node.has_method("import_state"):
		log_node.import_state({
			"active": active_quests,
			"completed": completed_quests,
			"xp": xp,
		})
		return
	if "active" in log_node:
		log_node.active = active_quests.duplicate(true)
	if "completed" in log_node:
		log_node.completed = PackedStringArray(completed_quests)
	if "xp" in log_node:
		log_node.xp = xp

func travel_to(location_id: String) -> void:
	var prev := current_location
	if not unlocked_locations.has(location_id):
		unlocked_locations.append(location_id)
	current_location = location_id
	save_to_disk()
	location_changed.emit(prev, location_id)
	changed.emit()

func set_pending_travel(target: String, landing: Vector3, from_id: String, exit_pos: Vector3, portal_id: String = "") -> void:
	pending_spawn = landing
	pending_spawn_valid = true
	pending_from = from_id
	pending_portal_id = portal_id
	exit_position = exit_pos
	if not unlocked_locations.has(target):
		unlocked_locations.append(target)
	save_to_disk()
	changed.emit()

func consume_pending_spawn() -> Vector3:
	if pending_spawn_valid:
		pending_spawn_valid = false
		var p := pending_spawn
		save_to_disk()
		return p
	const Registry = preload("res://world/location_registry.gd")
	return Registry.spawn_point(current_location)

func mark_safe_position(location_id: String, pos: Vector3) -> void:
	last_safe_location = location_id
	last_safe_position = pos
	save_to_disk()

func _vec3_to_arr(v: Vector3) -> Array:
	return [v.x, v.y, v.z]

func _arr_to_vec3(a: Variant, fallback: Vector3) -> Vector3:
	if a is Array and a.size() >= 3:
		return Vector3(float(a[0]), float(a[1]), float(a[2]))
	return fallback

func save_to_disk() -> void:
	var data := {
		"v": 2,
		"prototype_local": prototype_local,
		"class_actor_id": class_actor_id,
		"class_index": class_index,
		"level": level,
		"xp": xp,
		"hp": hp,
		"max_hp": max_hp,
		"mp": mp,
		"max_mp": max_mp,
		"currency": currency,
		"combat_power": combat_power,
		"inventory": inventory,
		"equipment": equipment,
		"active_quests": active_quests,
		"completed_quests": completed_quests,
		"quest_progress": quest_progress,
		"unlocked_locations": unlocked_locations,
		"current_location": current_location,
		"pending_spawn": _vec3_to_arr(pending_spawn),
		"pending_spawn_valid": pending_spawn_valid,
		"pending_from": pending_from,
		"pending_portal_id": pending_portal_id,
		"exit_position": _vec3_to_arr(exit_position),
		"last_safe_location": last_safe_location,
		"last_safe_position": _vec3_to_arr(last_safe_position),
		"server_url": server_url,
		"auth_token": auth_token,
		"account_id": account_id,
		"account_login": account_login,
		"character_id": character_id,
		"character_name": character_name,
		"protocol_version": protocol_version,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))

func load_from_disk() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not parsed is Dictionary:
		return
	var d: Dictionary = parsed
	class_actor_id = String(d.get("class_actor_id", class_actor_id))
	class_index = int(d.get("class_index", class_index))
	level = int(d.get("level", level))
	xp = int(d.get("xp", xp))
	hp = int(d.get("hp", hp))
	max_hp = int(d.get("max_hp", max_hp))
	mp = int(d.get("mp", mp))
	max_mp = int(d.get("max_mp", max_mp))
	currency = int(d.get("currency", currency))
	combat_power = int(d.get("combat_power", combat_power))
	inventory = d.get("inventory", [])
	equipment = d.get("equipment", {})
	active_quests = d.get("active_quests", {})
	completed_quests = d.get("completed_quests", [])
	quest_progress = d.get("quest_progress", {})
	unlocked_locations = d.get("unlocked_locations", unlocked_locations)
	current_location = String(d.get("current_location", current_location))
	pending_spawn = _arr_to_vec3(d.get("pending_spawn", []), pending_spawn)
	pending_spawn_valid = bool(d.get("pending_spawn_valid", false))
	pending_from = String(d.get("pending_from", ""))
	pending_portal_id = String(d.get("pending_portal_id", ""))
	exit_position = _arr_to_vec3(d.get("exit_position", []), exit_position)
	last_safe_location = String(d.get("last_safe_location", last_safe_location))
	last_safe_position = _arr_to_vec3(d.get("last_safe_position", []), last_safe_position)
	prototype_local = bool(d.get("prototype_local", true))
	server_url = String(d.get("server_url", server_url))
	auth_token = String(d.get("auth_token", auth_token))
	account_id = int(d.get("account_id", account_id))
	account_login = String(d.get("account_login", account_login))
	character_id = int(d.get("character_id", character_id))
	character_name = String(d.get("character_name", character_name))
	protocol_version = int(d.get("protocol_version", protocol_version))
