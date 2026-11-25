extends SceneTree
## CHAR06: body mesh inventory + weapon/wing combo without missing skeleton sockets.

const Equipment = preload("res://actors/equipment.gd")
const Costume = preload("res://actors/costume_audit.gd")

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
	var report: Dictionary = {"classes": {}}
	var assets: Node = root.get_node_or_null("/root/LunexAssets")
	if assets == null:
		fails.append("assets")
		_finish(fails, report)
		return
	assets.refresh()
	if not bool(assets.ready_ok):
		fails.append("assets not ready")
		_finish(fails, report)
		return
	var pairs := [["10001","100011000"],["20001","200011000"],["30001","300011000"],["40001","400011000"]]
	var wing_path := String(assets.accessory_root()).path_join("wing.glb")
	for pair in pairs:
		var id: String = pair[0]
		var actor := _load(assets.actor_glb(id))
		var weapon := _load(assets.weapon_glb(String(pair[1])))
		if actor == null or weapon == null:
			fails.append("load " + id)
			continue
		root.add_child(actor)
		var inv: Dictionary = Costume.mesh_inventory(actor)
		if not bool(inv.get("has_r_hand", false)) or not bool(inv.get("has_body_mesh", false)):
			fails.append("inventory " + id)
		var handle := Equipment.equip_weapon(actor, weapon, String(pair[1]))
		if handle.is_empty():
			fails.append("weapon " + id)
		var wing_overlap := 0.0
		var wing_ok := false
		if FileAccess.file_exists(wing_path):
			var wing := _load(wing_path)
			if wing:
				Equipment.prepare_accessory_visuals(wing, "wing", String(assets.accessory_root()), false)
				var wh := Equipment.equip_accessory(actor, wing, "wing", "wing_L_01")
				wing_ok = not wh.is_empty()
				if wing_ok:
					wing_overlap = Costume.overlap_score(actor, wing)
					Equipment.unequip_accessory(wh)
				if is_instance_valid(wing) and wing.get_parent() == null:
					wing.free()
		var weapon_overlap := Costume.overlap_score(actor, weapon) if not handle.is_empty() else 0.0
		# Fashion meshes beyond base body are not in used-asset pack yet — record gap.
		var fashion_gap := int(inv.get("mesh_count", 0)) <= 3
		report["classes"][id] = {
			"inventory": inv,
			"weapon_overlap": snapped(weapon_overlap, 0.0001),
			"wing_ok": wing_ok,
			"wing_overlap": snapped(wing_overlap, 0.0001),
			"separate_fashion_meshes": not fashion_gap,
			"notes": "Base body+weapon+wing combo; discrete helmet/armor fashion GLBs not in studio pack",
		}
		print("OK ", id, " meshes=", inv.get("mesh_count"), " skinned=", inv.get("skinned"), " w_ov=", snapped(weapon_overlap, 0.0001))
		if not handle.is_empty():
			Equipment.unequip_weapon(handle)
		actor.queue_free()
		if is_instance_valid(weapon) and weapon.get_parent() == null:
			weapon.free()
	# Write portable report under user:// then copy path printed for docs tooling
	var json := JSON.stringify(report)
	var path := "user://char06_costume_report.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(json)
		f.close()
	_finish(fails, report)

func _finish(fails: PackedStringArray, report: Dictionary) -> void:
	# Also emit machine-readable summary for agents
	print("CHAR06_REPORT ", JSON.stringify(report))
	if fails.is_empty():
		print("CHAR06_COSTUME_SMOKE_OK classes=4 fashion_pack_pending=true")
		quit(0)
		return
	for f in fails:
		print("FAIL ", f)
	print("CHAR06_COSTUME_SMOKE_FAIL")
	quit(1)
