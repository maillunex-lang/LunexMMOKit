extends SceneTree
## UI02: original Darklord atlases + skinned HUD/menus load.

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var fails: PackedStringArray = []
	for rel in [
		"res://ui/darklord/atlases/UICommon.png",
		"res://ui/darklord/atlases/UIMain.png",
		"res://ui/darklord/atlases/Login.png",
		"res://ui/darklord/atlases/NewHP.png",
		"res://ui/darklord/sprites/UICommon/frame1.png",
		"res://ui/darklord/sprites/UICommon/btn_green.png",
		"res://ui/darklord/sprites/UIMain/joystick_back.png",
		"res://ui/darklord/sprites/UIMain/joystick_thumb.png",
		"res://ui/darklord/sprites/NewHP/hpbar_1.png",
		"res://ui/darklord/fonts/simhei.ttf",
		"res://ui/theme/darklord_skin.gd",
		"res://ui/hud/game_hud.tscn",
		"res://ui/menus/auth_panel.tscn",
		"res://ui/menus/class_select_panel.tscn",
		"res://ui/menus/inventory_panel.tscn",
	]:
		if not (FileAccess.file_exists(rel) or ResourceLoader.exists(rel)):
			fails.append(rel)

	var DlSkin = load("res://ui/theme/darklord_skin.gd")
	var th: Theme = DlSkin.build_theme()
	if th == null:
		fails.append("theme")
	if DlSkin.tex("UICommon/frame1.png") == null:
		fails.append("frame1 tex null")
	if DlSkin.tex("UIMain/joystick_back.png") == null:
		fails.append("joystick tex null")

	var hud = load("res://ui/hud/game_hud.tscn").instantiate()
	root.add_child(hud)
	if hud.get_node_or_null("%HpBar") == null:
		fails.append("HpBar missing")
	hud.queue_free()

	for scene in ["res://ui/menus/auth_panel.tscn", "res://ui/menus/class_select_panel.tscn", "res://ui/menus/inventory_panel.tscn"]:
		var n = load(scene).instantiate()
		root.add_child(n)
		n.queue_free()

	if fails.is_empty():
		print("UI02_DARKLORD_SKIN_SMOKE_OK")
		quit(0)
		return
	for f in fails:
		print("FAIL ", f)
	print("UI02_DARKLORD_SKIN_SMOKE_FAIL")
	quit(1)
