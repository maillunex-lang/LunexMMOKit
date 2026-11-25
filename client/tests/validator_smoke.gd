extends SceneTree
## FIX-007: headless location validator cases (no_spawn, duplicate_stable_id).

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var VALIDATOR = load("res://addons/lunex_world_editor/location_validators.gd")
	var StableIds = load("res://core/stable_ids.gd")

	# Case A: empty root → no_spawn
	var root_a := Node3D.new()
	root_a.name = "EmptyLoc"
	root.add_child(root_a)
	var report_a: Dictionary = VALIDATOR.validate_location(root_a)
	var codes_a: PackedStringArray = []
	for issue in report_a.get("issues", []):
		codes_a.append(String(issue.get("code", "")))
	if not ("no_spawn" in codes_a):
		print("VALIDATOR_SMOKE_FAIL expected no_spawn got ", codes_a)
		quit(1)

	# Case B: duplicate stable ids
	var root_b := Node3D.new()
	root_b.name = "DupLoc"
	root.add_child(root_b)
	var spawn := Marker3D.new()
	spawn.name = "PlayerSpawn"
	root_b.add_child(spawn)
	var n1 := Node3D.new()
	n1.name = "A"
	n1.set_meta("instance_id", "inst_dup_test")
	n1.set_meta("stable_id", "inst_dup_test")
	root_b.add_child(n1)
	var n2 := Node3D.new()
	n2.name = "B"
	n2.set_meta("instance_id", "inst_dup_test")
	n2.set_meta("stable_id", "inst_dup_test")
	root_b.add_child(n2)
	var report_b: Dictionary = VALIDATOR.validate_location(root_b)
	var codes_b: PackedStringArray = []
	for issue in report_b.get("issues", []):
		codes_b.append(String(issue.get("code", "")))
	if not ("duplicate_stable_id" in codes_b):
		print("VALIDATOR_SMOKE_FAIL expected duplicate_stable_id got ", codes_b)
		quit(1)

	# Case C: legacy migrate
	var legacy := Node3D.new()
	legacy.name = "PortalEast"
	legacy.set_meta("stable_id", "portal_legacy_only")
	root_b.add_child(legacy)
	var migrated: int = StableIds.migrate_legacy_tree(root_b)
	if migrated < 1:
		print("VALIDATOR_SMOKE_FAIL migrate_legacy_tree changed 0")
		quit(1)
	if String(legacy.get_meta("instance_id", "")) != "portal_legacy_only":
		print("VALIDATOR_SMOKE_FAIL instance_id not promoted")
		quit(1)
	if String(legacy.get_meta("id_kind", "")) != "portal":
		print("VALIDATOR_SMOKE_FAIL id_kind infer fail got ", legacy.get_meta("id_kind", ""))
		quit(1)

	print("VALIDATOR_SMOKE_OK no_spawn+dup+migrate")
	quit(0)
