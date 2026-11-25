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
var prototype_local := true ## true until authoritative server owns state

func _ready() -> void:
	load_from_disk()

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
	if "active" in log_node:
		active_quests = (log_node.active as Dictionary).duplicate(true)
	if "completed" in log_node:
		var c = log_node.completed
		if c is Array:
			completed_quests = c.duplicate()
		elif c is Dictionary:
			completed_quests = c.keys()
	save_to_disk()
	changed.emit()

func apply_to_quest_log(log_node: Node) -> void:
	if log_node == null:
		return
	if "active" in log_node:
		log_node.active = active_quests.duplicate(true)
	if "completed" in log_node and log_node.completed is Array:
		log_node.completed = completed_quests.duplicate()

func travel_to(location_id: String) -> void:
	var prev := current_location
	if not unlocked_locations.has(location_id):
		unlocked_locations.append(location_id)
	current_location = location_id
	save_to_disk()
	location_changed.emit(prev, location_id)
	changed.emit()

func save_to_disk() -> void:
	var data := {
		"v": 1,
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
	prototype_local = bool(d.get("prototype_local", true))
