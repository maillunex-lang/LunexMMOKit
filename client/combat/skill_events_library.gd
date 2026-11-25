extends RefCounted
## CHAR07: load attack hit/fire times from extracted XML JSON (no magic constants).

const PATH := "res://content/combat/class_attack_events.json"

static func load_catalog() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return parsed if parsed is Dictionary else {}

static func attack001_event(actor_id: String) -> Dictionary:
	var cat := load_catalog()
	var classes: Dictionary = cat.get("classes", {})
	if not classes.has(actor_id):
		return {}
	var entry: Dictionary = classes[actor_id]
	var primary: Variant = entry.get("attack001", {})
	return primary if primary is Dictionary else {}

static func attack001_timeline(actor_id: String) -> Array:
	var ev := attack001_event(actor_id)
	if ev.is_empty() or not ev.has("kind") or not ev.has("time"):
		return []
	return [{"kind": String(ev["kind"]), "time": float(ev["time"])}]
