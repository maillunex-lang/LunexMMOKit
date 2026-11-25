extends SceneTree
## FIX-009: session persists quests across travel; rewards not duplicated.
## godot --path client --headless --script res://tests/session_loop_smoke.gd

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var fails: PackedStringArray = []
	var session: Node = root.get_node_or_null("/root/GameSession")
	if session == null:
		print("SESSION_LOOP_SMOKE_FAIL GameSession autoload missing")
		quit(1)
		return
	session.reset_new_character("10001", 0)
	var QuestLogScript = load("res://content/quests/quest_log.gd")
	var log1 = QuestLogScript.new()
	root.add_child(log1)
	log1.load_catalog()
	var started := false
	for qid in log1.catalog.keys():
		if log1.start_quest(qid):
			started = true
			log1._complete(qid)
			var xp1: int = log1.xp
			log1.active[qid] = {"id": qid, "objectives": []}
			log1._complete(qid)
			if log1.xp != xp1:
				fails.append("dupe reward xp %d→%d" % [xp1, log1.xp])
			var count := 0
			for id in log1.completed:
				if String(id) == String(qid):
					count += 1
			if count > 1:
				fails.append("dupe completed entry")
			break
	if not started:
		print("WARN no quests in catalog to complete")

	session.sync_quest_log(log1)
	session.travel_to("ashen_outskirts")
	session.travel_to("shard_ruins")
	session.travel_to("eternity_capital")
	session.save_to_disk()

	var log2 = QuestLogScript.new()
	root.add_child(log2)
	log2.load_catalog()
	session.apply_to_quest_log(log2)
	if int(log2.xp) != int(log1.xp):
		fails.append("xp not restored %d vs %d" % [log2.xp, log1.xp])
	for id in log1.completed:
		if id not in log2.completed:
			fails.append("completed missing after travel: " + String(id))
	var unlocked: Array = session.unlocked_locations
	if not unlocked.has("ashen_outskirts"):
		fails.append("ashen not unlocked")
	if not unlocked.has("shard_ruins"):
		fails.append("ruins not unlocked")
	if String(session.current_location) != "eternity_capital":
		fails.append("current location " + String(session.current_location))

	for s in [
		"res://world/locations/eternity_capital/eternity_play.tscn",
		"res://world/locations/ashen_outskirts/ashen_play.tscn",
		"res://world/locations/shard_ruins/ruins_play.tscn",
	]:
		if not ResourceLoader.exists(s):
			fails.append("missing " + s)

	if fails.is_empty():
		print("SESSION_LOOP_SMOKE_OK xp=", log2.xp, " completed=", log2.completed, " locs=", unlocked)
		quit(0)
	else:
		print("SESSION_LOOP_SMOKE_FAIL")
		for f in fails:
			print(" - ", f)
		quit(1)
