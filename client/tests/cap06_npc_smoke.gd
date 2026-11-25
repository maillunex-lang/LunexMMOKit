extends SceneTree
## CAP06: NPC catalog + dialogs cover chapter01 quest stable_ids.

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var fails: PackedStringArray = []
	var cat_path := "res://content/npcs/npc_catalog.json"
	var dlg_path := "res://content/dialogs/chapter01_dialogs.json"
	var quest_path := "res://content/quests/chapter01_quests.json"
	for p in [cat_path, dlg_path, quest_path]:
		if not FileAccess.file_exists(p):
			fails.append("missing " + p)
	if fails.size():
		_fail(fails)
		return

	var catalog = JSON.parse_string(FileAccess.get_file_as_string(cat_path))
	var dialogs = JSON.parse_string(FileAccess.get_file_as_string(dlg_path))
	var quests = JSON.parse_string(FileAccess.get_file_as_string(quest_path))
	var by_id := {}
	for m in catalog.get("markers", []):
		by_id[String(m.get("stable_id", ""))] = m
	var dlg_ids := {}
	for d in dialogs.get("dialogs", []):
		dlg_ids[String(d.get("id", ""))] = true

	var needed: PackedStringArray = []
	for q in quests.get("quests", []):
		for key in ["giver_stable_id", "turnin_stable_id"]:
			var sid := String(q.get(key, ""))
			if sid.begins_with("npc_") and sid not in needed:
				needed.append(sid)
		for obj in q.get("objectives", []):
			var sid2 := String(obj.get("stable_id", ""))
			if sid2.begins_with("npc_") and sid2 not in needed:
				needed.append(sid2)
			if sid2.begins_with("portal_") and sid2 not in by_id:
				fails.append("portal missing in catalog: " + sid2)

	for sid in needed:
		if sid not in by_id:
			fails.append("npc missing in catalog: " + sid)
			continue
		var dlg := String(by_id[sid].get("dialog_id", ""))
		if dlg != "" and dlg not in dlg_ids:
			fails.append("dialog missing: " + dlg)

	if by_id.size() < 8:
		fails.append("expected ≥8 markers")

	if fails.is_empty():
		print("CAP06_NPC_SMOKE_OK markers=%d dialogs=%d npcs=%d" % [by_id.size(), dlg_ids.size(), needed.size()])
		quit(0)
		return
	_fail(fails)

func _fail(fails: PackedStringArray) -> void:
	for f in fails:
		print("FAIL ", f)
	print("CAP06_NPC_SMOKE_FAIL")
	quit(1)
