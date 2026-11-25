extends SceneTree
## C03: manual input cancels auto-battle; celestial is server-side (module load check).

const AutoBattle = preload("res://combat/auto_battle.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var fails: PackedStringArray = []
	var ab = AutoBattle.new()
	root.add_child(ab)
	ab.set_enabled(true)
	if not bool(ab.enabled):
		fails.append("enable")
	var flag := {"cancelled": false}
	ab.cancelled_by_manual.connect(func(): flag["cancelled"] = true)
	ab.on_manual_input()
	if bool(ab.enabled):
		fails.append("still enabled")
	elif not bool(flag["cancelled"]):
		fails.append("signal missing")
	else:
		print("OK manual cancels auto")
	var hc_src := FileAccess.get_file_as_string("res://actors/hero_controller.gd")
	if "auto_pathing = false" not in hc_src:
		fails.append("hero manual path cancel missing")
	else:
		print("OK hero joystick cancels auto_path")
	ab.queue_free()
	_finish(fails)

func _finish(fails: PackedStringArray) -> void:
	if fails.is_empty():
		print("C03_AUTO_BATTLE_SMOKE_OK")
		quit(0)
		return
	for f in fails:
		print("FAIL ", f)
	print("C03_AUTO_BATTLE_SMOKE_FAIL")
	quit(1)
