extends SceneTree
## CHARACTER-AUDIT / CHAR02 / CHAR03 / CHAR08: portable attachment smoke via assets/studio.

const Equipment = preload("res://actors/equipment.gd")
const Library = preload("res://actors/attachment_library.gd")

func _initialize() -> void:
	call_deferred("run")

func _load_glb(abs_path: String) -> Node3D:
	if abs_path.is_empty() or not FileAccess.file_exists(abs_path):
		return null
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(abs_path, state) != OK:
		return null
	return doc.generate_scene(state)

func run() -> void:
	var fails: PackedStringArray = []
	var assets: Node = root.get_node_or_null("/root/LunexAssets")
	if assets == null:
		fails.append("LunexAssets missing")
		_finish(fails)
		return
	assets.refresh()
	if not bool(assets.ready_ok):
		fails.append("studio assets not ready")
		_finish(fails)
		return

	# CHAR08: weapon/wing/pet/mount defaults exist
	for wid in ["100011000", "200011000", "300011000"]:
		if Library.load_offset("weapon", wid) == null:
			fails.append("missing attachment " + wid)
	if Library.load_offset("weapon", "400011000", "", "body1") == null:
		fails.append("missing dual body1")
	if Library.load_offset("weapon", "400011000", "", "body2") == null:
		fails.append("missing dual body2")
	for kind_id in [["wing", "wing_L_01"], ["pet", "XN_pet_01"], ["mount_seat", "mount_001"]]:
		if Library.load_offset(kind_id[0], kind_id[1]) == null:
			fails.append("missing " + kind_id[0] + " " + kind_id[1])
	var wing_off = Library.load_offset("wing", "wing_L_01")
	if wing_off == null or String(wing_off.socket_mode) != "marker":
		fails.append("wing must use marker socket_mode")

	var pairs := [
		["10001", "100011000"],
		["20001", "200011000"],
		["30001", "300011000"],
		["40001", "400011000"],
	]
	var wing_path: String = assets.accessory_root().path_join("wing.glb") if not String(assets.accessory_root()).is_empty() else ""
	for pair in pairs:
		var actor_path: String = assets.actor_glb(String(pair[0]))
		var weapon_path: String = assets.weapon_glb(String(pair[1]))
		var actor := _load_glb(actor_path)
		var item := _load_glb(weapon_path)
		if actor == null or item == null:
			fails.append("glb " + String(pair[0]))
			continue
		root.add_child(actor)
		var skel := Equipment.find_skeleton(actor)
		if skel == null:
			fails.append("no skeleton " + String(pair[0]))
			actor.queue_free()
			continue
		if skel.find_bone("Bip001 R Hand") < 0:
			fails.append("no R Hand bone " + String(pair[0]))
		var handle: Dictionary = Equipment.equip_weapon(actor, item, String(pair[1]))
		if handle.is_empty():
			fails.append("equip failed " + String(pair[0]))
		else:
			var mode := String(handle.get("mode", ""))
			var expected_single := "Bip001 R Hand"
			var off_res = Library.load_offset("weapon", String(pair[1]))
			if off_res != null and String(off_res.socket) != "":
				expected_single = String(off_res.socket)
			if mode == "single":
				var bone_sock: BoneAttachment3D = handle.get("bone_socket")
				if bone_sock == null or String(handle.get("bind", "")) != "bone":
					fails.append("not bone bind " + String(pair[0]))
				elif bone_sock.bone_name != expected_single:
					fails.append("socket want " + expected_single + " got " + bone_sock.bone_name + " " + String(pair[0]))
				else:
					print("OK ", pair[0], " single→", bone_sock.bone_name)
			elif mode == "dual":
				var names: PackedStringArray = []
				for entry in handle.get("attachments", []):
					var bs: BoneAttachment3D = entry.get("bone_socket")
					if bs:
						names.append(bs.bone_name)
				if not ("Bip001 R Hand" in names and "Bip001 L Hand" in names):
					fails.append("dual hands " + String(pair[0]) + " got " + ",".join(names))
				else:
					print("OK ", pair[0], " dual→", ",".join(names))
			var players := actor.find_children("*", "AnimationPlayer", true, false)
			if players.size():
				var player: AnimationPlayer = players[0]
				for anim in player.get_animation_list():
					var lower := String(anim).to_lower()
					if "attack" in lower or "stand" in lower:
						player.play(anim)
						player.seek(0.35, true)
						player.advance(0.0)
						# CHAR02: weapon must stay bone-parented through attack pose
						if mode == "single":
							var bs: BoneAttachment3D = handle.get("bone_socket")
							if bs == null or not is_instance_valid(bs) or item.get_parent() != bs:
								fails.append("detach on anim " + String(pair[0]))
						elif mode == "dual":
							for entry in handle.get("attachments", []):
								var root_n: Node3D = entry.get("root")
								var bsd: BoneAttachment3D = entry.get("bone_socket")
								if root_n == null or bsd == null or root_n.get_parent() != bsd:
									fails.append("dual detach " + String(pair[0]))
									break
						print("OK ", pair[0], " attack-parent")
						break
			Equipment.unequip_weapon(handle)

		# CHAR03: wing attaches to E_back2 marker on every class
		if not wing_path.is_empty() and FileAccess.file_exists(wing_path):
			var wing := _load_glb(wing_path)
			if wing == null:
				fails.append("wing glb " + String(pair[0]))
			else:
				var wh: Dictionary = Equipment.equip_accessory(actor, wing, "wing", "wing_L_01")
				if wh.is_empty():
					fails.append("wing equip " + String(pair[0]))
				elif String(wh.get("bind", "")) != "marker":
					fails.append("wing not marker " + String(pair[0]))
				else:
					var mk: Node3D = wh.get("marker")
					if mk == null or mk.name != "E_back2":
						fails.append("wing socket " + String(pair[0]) + " " + (mk.name if mk else "?"))
					else:
						print("OK ", pair[0], " wing→E_back2")
					Equipment.unequip_accessory(wh)
				if is_instance_valid(wing) and wing.get_parent() == null:
					wing.free()

		actor.queue_free()
		if item and is_instance_valid(item) and item.get_parent() == null:
			item.free()

	_finish(fails)

func _finish(fails: PackedStringArray) -> void:
	if fails.is_empty():
		print("CHAR_ATTACHMENT_SMOKE_OK bone_sockets+wings+resources")
		quit(0)
		return
	for f in fails:
		print("FAIL ", f)
	print("CHAR_ATTACHMENT_SMOKE_FAIL")
	quit(1)
