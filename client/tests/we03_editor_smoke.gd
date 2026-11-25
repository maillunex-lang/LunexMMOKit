extends SceneTree
## WE03 headless: marker kits, theme, owner protect, validator, shared catalog present.

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var fails: PackedStringArray = []
	for rel in [
		"res://addons/lunex_world_editor/plugin.cfg",
		"res://addons/lunex_world_editor/library_dock.tscn",
		"res://world/library/markers/npc_marker.tscn",
		"res://world/library/markers/portal_marker.tscn",
		"res://world/library/markers/spawn_marker.tscn",
		"res://content/locations/eternity_capital_shared.json",
	]:
		var abs := ProjectSettings.globalize_path(rel)
		if not (FileAccess.file_exists(abs) or ResourceLoader.exists(rel)):
			fails.append("missing " + rel)

	for kit in ["npc_marker", "portal_marker", "spawn_marker"]:
		var p := "res://world/library/markers/%s.tscn" % kit
		if ResourceLoader.exists(p):
			var n = load(p).instantiate()
			n.queue_free()
		else:
			fails.append("instantiate " + kit)

	var StableIds = load("res://core/stable_ids.gd")
	var n := Node3D.new()
	n.name = "PlazaElder"
	n.set_meta("npc_role", "quest")
	root.add_child(n)
	var sid: String = StableIds.ensure_on_node(n, StableIds.Kind.NPC, "plazaelder")
	if sid == "" or not n.has_meta("instance_id"):
		fails.append("stable id on npc")
	n.queue_free()

	var OP = load("res://world/owner_protect.gd")
	var fake := "user://we03_owner_test.tscn"
	var abs := ProjectSettings.globalize_path(fake)
	DirAccess.make_dir_recursive_absolute(abs.get_base_dir())
	var lf := FileAccess.open(abs.get_basename() + ".owner.lock", FileAccess.WRITE)
	lf.store_string("owner_edited=true\n")
	lf.close()
	var gate: Dictionary = OP.refuse_overwrite(fake, false)
	if bool(gate.get("ok", true)):
		fails.append("owner protect")

	if fails.is_empty():
		print("WE03_EDITOR_SMOKE_OK")
		quit(0)
		return
	for f in fails:
		print("FAIL ", f)
	print("WE03_EDITOR_SMOKE_FAIL")
	quit(1)
