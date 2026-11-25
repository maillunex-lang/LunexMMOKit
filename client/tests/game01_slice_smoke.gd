extends SceneTree
## GAME01: chapter1 quests + 4 classes + three play scenes exist (local prototype).

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var fails: PackedStringArray = []
	var qpath := "res://content/quests/chapter01_quests.json"
	if not FileAccess.file_exists(qpath):
		fails.append("quests")
	else:
		var data = JSON.parse_string(FileAccess.get_file_as_string(qpath))
		var quests: Array = data.get("quests", [])
		if quests.size() < 4:
			fails.append("need ≥4 chapter quests")
	var cpath := "res://content/heroes/classes_baseline.json"
	if not FileAccess.file_exists(cpath):
		fails.append("classes")
	else:
		var data2 = JSON.parse_string(FileAccess.get_file_as_string(cpath))
		if (data2.get("classes", []) as Array).size() < 4:
			fails.append("4 classes")
	for scene in [
		"res://world/locations/eternity_capital/eternity_play.tscn",
		"res://world/locations/ashen_outskirts/ashen_play.tscn",
		"res://world/locations/shard_ruins/ruins_play.tscn",
	]:
		if not ResourceLoader.exists(scene):
			fails.append(scene)
	if fails.is_empty():
		print("GAME01_SLICE_SMOKE_OK prototype_local=true")
		quit(0)
		return
	for f in fails:
		print("FAIL ", f)
	print("GAME01_SLICE_SMOKE_FAIL")
	quit(1)
