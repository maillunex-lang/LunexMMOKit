extends RefCounted
## Loads Darklord-derived class baseline and drives slice combat (CD/range/damage from source tables).

const PATH := "res://content/heroes/classes_baseline.json"

var catalog: Dictionary = {}
var by_actor: Dictionary = {}

func load_data(path: String = PATH) -> void:
	if not FileAccess.file_exists(path):
		push_warning("Missing hero baseline: " + path)
		return
	catalog = JSON.parse_string(FileAccess.get_file_as_string(path))
	by_actor.clear()
	for c in catalog.get("classes", []):
		by_actor[String(c.actor_id)] = c

func class_of(actor_id: String) -> Dictionary:
	return by_actor.get(actor_id, {})

func hotbar(actor_id: String) -> Array:
	var c := class_of(actor_id)
	return c.get("hotbar_skills", [])

func basic(actor_id: String) -> Dictionary:
	var c := class_of(actor_id)
	var arr: Array = c.get("basic_attacks", [])
	return arr[0] if arr.size() else {}
