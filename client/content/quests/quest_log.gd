extends Node
## Runtime quest progress. Objectives resolve by stable_id.
signal quest_updated(quest_id: String)
signal quest_completed(quest_id: String)

var catalog: Dictionary = {}
var active: Dictionary = {} ## quest_id -> {step progress}
var completed: PackedStringArray = []
var xp: int = 0

func load_catalog(path: String = "res://content/quests/chapter01_quests.json") -> void:
	if not FileAccess.file_exists(path):
		push_warning("Quest catalog missing: " + path)
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		return
	catalog.clear()
	for q in data.get("quests", []):
		catalog[String(q.id)] = q

func start_quest(quest_id: String) -> bool:
	if not catalog.has(quest_id) or active.has(quest_id) or quest_id in completed:
		return false
	var q: Dictionary = catalog[quest_id]
	var prog := {"id": quest_id, "objectives": []}
	for obj in q.get("objectives", []):
		prog.objectives.append({"type": obj.type, "stable_id": obj.stable_id, "need": int(obj.count), "have": 0, "text": obj.get("text", "")})
	active[quest_id] = prog
	quest_updated.emit(quest_id)
	return true

func offer_from_npc(stable_id: String) -> String:
	## Returns quest id started or empty.
	for qid in catalog.keys():
		if qid in completed or active.has(qid):
			continue
		var q: Dictionary = catalog[qid]
		if String(q.get("giver_stable_id", "")) == stable_id:
			if start_quest(qid):
				return qid
	return ""

func notify_talk(stable_id: String) -> void:
	_progress("talk", stable_id, 1)
	_try_turnin(stable_id)
	# After turn-in/complete, allow this NPC to offer the next quest.
	offer_from_npc(stable_id)

func notify_kill(stable_id: String, amount: int = 1) -> void:
	_progress("kill", stable_id, amount)

func notify_goto(stable_id: String) -> void:
	_progress("goto", stable_id, 1)

func _progress(otype: String, stable_id: String, amount: int) -> void:
	var to_complete: PackedStringArray = []
	for qid in active.keys():
		var prog: Dictionary = active[qid]
		var changed := false
		for obj in prog.objectives:
			if String(obj.type) == otype and String(obj.stable_id) == stable_id and int(obj.have) < int(obj.need):
				obj.have = mini(int(obj.need), int(obj.have) + amount)
				changed = true
		if changed:
			quest_updated.emit(qid)
			if _objectives_done(prog):
				to_complete.append(qid)
	for qid in to_complete:
		_complete(qid)

func _objectives_done(prog: Dictionary) -> bool:
	for obj in prog.objectives:
		if int(obj.have) < int(obj.need):
			return false
	return true

func _try_turnin(stable_id: String) -> void:
	for qid in active.keys():
		var q: Dictionary = catalog[qid]
		if String(q.get("turnin_stable_id", "")) != stable_id:
			continue
		var prog: Dictionary = active[qid]
		if _objectives_done(prog):
			_complete(qid)

func _complete(quest_id: String) -> void:
	if not active.has(quest_id):
		return
	# Anti-dupe: never grant reward twice for the same quest id (FIX-009).
	if quest_id in completed:
		active.erase(quest_id)
		return
	var q: Dictionary = catalog[quest_id]
	var reward := int(q.get("reward_xp", 0))
	xp += reward
	active.erase(quest_id)
	completed.append(quest_id)
	quest_completed.emit(quest_id)
	var nxt := String(q.get("next_quest_id", ""))
	if nxt != "" and catalog.has(nxt):
		# Next becomes available from its giver; auto-start if same turn-in chain wants continuity
		pass

func has_completed(quest_id: String) -> bool:
	return quest_id in completed

func export_state() -> Dictionary:
	return {
		"active": active.duplicate(true),
		"completed": Array(completed),
		"xp": xp,
	}

func import_state(data: Dictionary) -> void:
	active = data.get("active", {}).duplicate(true) if data.get("active") is Dictionary else {}
	completed = PackedStringArray()
	for id in data.get("completed", []):
		completed.append(String(id))
	xp = int(data.get("xp", xp))

func tracker_text() -> String:
	if active.is_empty():
		if completed.is_empty():
			return "Квесты: подойди к стражу площади"
		return "Квесты: глава 1 — продолжение у NPC"
	var lines: PackedStringArray = []
	for qid in active.keys():
		var q: Dictionary = catalog[qid]
		var prog: Dictionary = active[qid]
		lines.append("[b]%s[/b]" % String(q.title))
		for obj in prog.objectives:
			lines.append(" • %s (%d/%d)" % [obj.text, obj.have, obj.need])
	lines.append("XP %d" % xp)
	return "\n".join(lines)
