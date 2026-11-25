extends SceneTree
## A01: four Darklord classes + hero controller + joystick + camera present.
## Device touch not executed in headless CI (documented).

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var fails: PackedStringArray = []

	var path := "res://content/heroes/classes_baseline.json"
	if not FileAccess.file_exists(path):
		fails.append("missing classes_baseline.json")
	else:
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		var classes: Array = data.get("classes", []) if typeof(data) == TYPE_DICTIONARY else []
		var ids: PackedStringArray = []
		for c in classes:
			ids.append(String(c.get("actor_id", "")))
		for need in ["10001", "20001", "30001", "40001"]:
			if need not in ids:
				fails.append("missing class " + need)
		if classes.size() < 4:
			fails.append("expected ≥4 classes")

	for rel in [
		"res://actors/hero_controller.gd",
		"res://actors/equipment.gd",
		"res://actors/hero_combat.gd",
		"res://world/follow_camera.gd",
		"res://ui/controls/virtual_joystick.tscn",
		"res://ui/hud/game_hud.tscn",
	]:
		var abs := ProjectSettings.globalize_path(rel)
		if not (FileAccess.file_exists(abs) or ResourceLoader.exists(rel)):
			fails.append("missing " + rel)

	var HeroCtrl = load("res://actors/hero_controller.gd")
	if HeroCtrl == null:
		fails.append("load hero_controller")
	else:
		var hero: CharacterBody3D = CharacterBody3D.new()
		hero.set_script(HeroCtrl)
		root.add_child(hero)
		hero.call("set_direction", Vector2(0, -1))
		hero.call("set_direction", Vector2.ZERO)
		hero.call("navigate_to", Vector3(5, 0, 5))
		hero.call("stop_navigation")
		hero.queue_free()

	var joy = load("res://ui/controls/virtual_joystick.tscn").instantiate()
	root.add_child(joy)
	joy.queue_free()

	if fails.is_empty():
		print("A01_HERO_SMOKE_OK classes=4 joystick=ok controller=ok")
		quit(0)
		return
	for f in fails:
		print("FAIL ", f)
	print("A01_HERO_SMOKE_FAIL")
	quit(1)
