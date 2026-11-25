extends SceneTree
## D03: Godot can import four actor types + weapons + accessories from assets/studio.

func _initialize() -> void:
	call_deferred("run")

func _load(path: String) -> Node3D:
	if path.is_empty() or not FileAccess.file_exists(path):
		return null
	var d := GLTFDocument.new()
	var s := GLTFState.new()
	if d.append_from_file(path, s) != OK:
		return null
	return d.generate_scene(s)

func run() -> void:
	var fails: PackedStringArray = []
	var assets: Node = root.get_node_or_null("/root/LunexAssets")
	if assets == null:
		fails.append("LunexAssets")
		_finish(fails)
		return
	assets.refresh()
	if not bool(assets.ready_ok):
		fails.append("assets")
		_finish(fails)
		return
	for id in ["10001", "20001", "30001", "40001"]:
		var a := _load(assets.actor_glb(id))
		if a == null:
			fails.append("actor " + id)
			continue
		var skels := a.find_children("*", "Skeleton3D", true, false)
		var players := a.find_children("*", "AnimationPlayer", true, false)
		if skels.is_empty() or players.is_empty():
			fails.append("rig " + id)
		else:
			print("OK actor ", id, " anims=", players[0].get_animation_list().size())
		a.free()
	for wid in ["100011000", "200011000", "300011000", "400011000"]:
		var w := _load(assets.weapon_glb(wid))
		if w == null:
			fails.append("weapon " + wid)
		else:
			print("OK weapon ", wid)
			w.free()
	var acc := String(assets.accessory_root())
	for name in ["wing.glb", "pet.glb", "mount.glb"]:
		var p := acc.path_join(name)
		var n := _load(p)
		if n == null:
			fails.append(name)
		else:
			print("OK accessory ", name)
			n.free()
	_finish(fails)

func _finish(fails: PackedStringArray) -> void:
	if fails.is_empty():
		print("D03_STUDIO_IMPORT_SMOKE_OK")
		quit(0)
		return
	for f in fails:
		print("FAIL ", f)
	print("D03_STUDIO_IMPORT_SMOKE_FAIL")
	quit(1)
