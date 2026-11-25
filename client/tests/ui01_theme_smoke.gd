extends SceneTree
## UI01: theme + icons present; inventory report exists.

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var fails: PackedStringArray = []
	if not ResourceLoader.exists("res://ui/theme/lunex_theme.tres"):
		fails.append("lunex_theme.tres")
	else:
		var th = load("res://ui/theme/lunex_theme.tres")
		if th == null:
			fails.append("theme load")
	for icon in ["icon_hp.png", "icon_mp.png", "icon_quest.png", "icon_attack.png", "button_normal.png"]:
		var p: String = "res://ui/theme/icons/" + icon
		if not FileAccess.file_exists(p):
			fails.append(icon)
	var report: String = ProjectSettings.globalize_path("res://").path_join("../docs/UI_INVENTORY.md")
	if not FileAccess.file_exists(report):
		fails.append("UI_INVENTORY.md")
	if fails.is_empty():
		print("UI01_THEME_SMOKE_OK")
		quit(0)
		return
	for f in fails:
		print("FAIL ", f)
	print("UI01_THEME_SMOKE_FAIL")
	quit(1)
