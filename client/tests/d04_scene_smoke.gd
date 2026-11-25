extends SceneTree
## D04: capital has collisions; play scene bakes NavigationRegion3D at runtime.

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var fails: PackedStringArray = []
	var capital_path := "res://world/locations/eternity_capital/eternity_capital.tscn"
	var play_path := "res://world/locations/eternity_capital/eternity_play.tscn"
	if not ResourceLoader.exists(capital_path):
		fails.append("capital missing")
	if not ResourceLoader.exists(play_path):
		fails.append("play missing")
	if fails.is_empty():
		var packed: PackedScene = load(capital_path)
		if packed == null:
			fails.append("capital load")
		else:
			var scene := packed.instantiate()
			root.add_child(scene)
			var bodies := scene.find_children("*", "StaticBody3D", true, false)
			var shapes := scene.find_children("*", "CollisionShape3D", true, false)
			print("OK capital bodies=", bodies.size(), " shapes=", shapes.size())
			if bodies.size() < 10:
				fails.append("few bodies")
			scene.queue_free()
		# Runtime nav is created by eternity_play._ensure_nav (not baked into capital.tscn)
		var play_src := FileAccess.get_file_as_string("res://world/locations/eternity_capital/eternity_play.gd")
		if "NavigationRegion3D" not in play_src or "_ensure_nav" not in play_src:
			fails.append("play nav missing")
		else:
			print("OK eternity_play runtime nav")
		if not FileAccess.file_exists("res://world/location_navigation.gd"):
			fails.append("location_navigation.gd")
	for loc in ["ashen_outskirts", "shard_ruins"]:
		var dir := DirAccess.open("res://world/locations/%s" % loc)
		if dir == null:
			fails.append("loc " + loc)
		else:
			print("OK loc ", loc)
	if fails.is_empty():
		print("D04_SCENE_SMOKE_OK")
		quit(0)
		return
	for f in fails:
		print("FAIL ", f)
	print("D04_SCENE_SMOKE_FAIL")
	quit(1)
