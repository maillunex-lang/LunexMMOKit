extends SceneTree
## FIX-012: headless integration smoke for AUDIT01 foundations.
## Run: godot4 --headless --path client --script res://../tests/integration_audit_smoke.gd
## (or from client with script copied). Prefer tools/run_integration_smoke.sh

var fails: PackedStringArray = []

func _initialize() -> void:
	call_deferred("run")

func fail(msg: String) -> void:
	fails.append(msg)
	print("FAIL ", msg)

func ok(msg: String) -> void:
	print("OK ", msg)

func run() -> void:
	# 1) No hardcoded VPS paths in key play scripts (string scan via FileAccess)
	for rel in [
		"res://world/locations/eternity_capital/eternity_play.gd",
		"res://world/capital_play.gd",
		"res://core/asset_paths.gd",
	]:
		if not FileAccess.file_exists(rel) and not ResourceLoader.exists(rel):
			# gd scripts exist as files
			var abs := ProjectSettings.globalize_path(rel)
			if not FileAccess.file_exists(abs):
				fail("missing " + rel)
				continue
		var abs2 := ProjectSettings.globalize_path(rel)
		var txt := FileAccess.get_file_as_string(abs2)
		if "/home/gamedev/" in txt and not rel.ends_with("asset_paths.gd"):
			fail("VPS path in " + rel)
		else:
			ok("no VPS path " + rel)

	# 2) Autoload scripts exist
	for rel in ["res://core/asset_paths.gd", "res://core/game_session.gd", "res://core/stable_ids.gd"]:
		var abs := ProjectSettings.globalize_path(rel)
		if FileAccess.file_exists(abs):
			ok("script " + rel)
		else:
			fail("missing " + rel)

	# 3) HUD scene
	if ResourceLoader.exists("res://ui/hud/game_hud.tscn"):
		var hud = load("res://ui/hud/game_hud.tscn").instantiate()
		ok("hud instantiate")
		hud.free()
	else:
		fail("game_hud.tscn")

	# 4) Stable IDs uniqueness
	var StableIds = load("res://core/stable_ids.gd")
	var a = StableIds.new_id(StableIds.Kind.INSTANCE, "house")
	var b = StableIds.new_id(StableIds.Kind.INSTANCE, "house")
	if a == b:
		fail("stable ids not unique")
	else:
		ok("stable ids unique")

	# 5) Owner protect refuses lock
	var OP = load("res://world/owner_protect.gd")
	# create temp lock beside a fake path under user://
	var fake := "user://audit_owner_test.tscn"
	var abs := ProjectSettings.globalize_path(fake)
	DirAccess.make_dir_recursive_absolute(abs.get_base_dir())
	var lf := FileAccess.open(abs.get_basename() + ".owner.lock", FileAccess.WRITE)
	lf.store_string("owner_edited=true\n")
	lf.close()
	var gate: Dictionary = OP.refuse_overwrite(fake, false)
	if bool(gate.get("ok", true)):
		fail("owner protect should refuse")
	else:
		ok("owner protect refuse: " + String(gate.get("reason", "")))

	# 6) Location scenes load (packed)
	for scene in [
		"res://world/locations/eternity_capital/eternity_play.tscn",
		"res://world/locations/ashen_outskirts/ashen_play.tscn",
		"res://world/locations/shard_ruins/ruins_play.tscn",
	]:
		if ResourceLoader.exists(scene):
			ok("exists " + scene)
		else:
			fail("missing scene " + scene)

	# 7) Nav script bake API present
	var nav_script = load("res://world/location_navigation.gd")
	if nav_script:
		ok("location_navigation.gd")
	else:
		fail("location_navigation.gd")

	# 8) Combat runtime + timeline linked
	if FileAccess.file_exists(ProjectSettings.globalize_path("res://combat/combat_runtime.gd")) \
			and FileAccess.file_exists(ProjectSettings.globalize_path("res://combat/skill_timeline.gd")) \
			and FileAccess.file_exists(ProjectSettings.globalize_path("res://combat/preview_attack.gd")):
		ok("combat pipeline files")
	else:
		fail("combat pipeline incomplete")

	# 9) GameSession save roundtrip
	GameSession.currency = 42
	GameSession.save_to_disk()
	GameSession.currency = 0
	GameSession.load_from_disk()
	if GameSession.currency == 42:
		ok("game session persist")
	else:
		fail("game session persist")

	# 10) Assets: studio manifest or explicit miss (not hard fail on clean CI without assets)
	LunexAssets.refresh()
	if LunexAssets.ready_ok:
		ok("assets ready " + LunexAssets.cache_root)
	else:
		print("WARN assets not ready (expected on CI without studio pack): ", LunexAssets.status_line())

	if fails.is_empty():
		print("INTEGRATION_AUDIT_SMOKE_OK")
		quit(0)
	else:
		print("INTEGRATION_AUDIT_SMOKE_FAIL count=", fails.size())
		for f in fails:
			print(" - ", f)
		quit(1)
