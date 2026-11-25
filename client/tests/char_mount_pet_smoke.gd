extends SceneTree
## CHAR04 / CHAR05: mount seat + pet follow portable smoke via assets/studio.

const Equipment = preload("res://actors/equipment.gd")
const Library = preload("res://actors/attachment_library.gd")
const PetFollow = preload("res://actors/pet_follow.gd")

func _initialize() -> void:
	call_deferred("run")

func _load_glb(path: String) -> Node3D:
	if path.is_empty() or not FileAccess.file_exists(path):
		return null
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(path, state) != OK:
		return null
	return doc.generate_scene(state)

func run() -> void:
	var fails: PackedStringArray = []
	var assets: Node = root.get_node_or_null("/root/LunexAssets")
	if assets == null:
		fails.append("assets")
		_finish(fails)
		return
	assets.refresh()
	if not bool(assets.ready_ok):
		fails.append("assets not ready")
		_finish(fails)
		return
	var acc := String(assets.accessory_root())
	if acc.is_empty():
		fails.append("accessory_root")
		_finish(fails)
		return
	var mount_path := acc.path_join("mount.glb")
	var pet_path := acc.path_join("pet.glb")
	var wing_path := acc.path_join("wing.glb")
	for mid in ["mount_001", "mount_002"]:
		if Library.load_offset("mount_seat", mid) == null:
			fails.append("missing seat " + mid)
	for pid in ["XN_pet_01", "XN_pet_02"]:
		if Library.load_offset("pet", pid) == null:
			fails.append("missing pet " + pid)

	for actor_id in ["10001", "20001", "30001", "40001"]:
		var actor := _load_glb(assets.actor_glb(actor_id))
		if actor == null:
			fails.append("actor " + actor_id)
			continue
		root.add_child(actor)
		# CHAR04 mount
		var mount := _load_glb(mount_path)
		if mount == null:
			fails.append("mount glb")
		else:
			root.add_child(mount)
			var mh := Equipment.mount_actor(mount, actor, "mount_001")
			if mh.is_empty():
				fails.append("mount seat " + actor_id)
			elif String(mh.get("socket", "")) != "Horse_E_back2":
				fails.append("seat socket " + actor_id + " " + String(mh.get("socket", "")))
			else:
				print("OK ", actor_id, " mount→Horse_E_back2")
				# actor should not be at world origin relative to seat
				if actor.get_parent() != mh.get("marker"):
					fails.append("actor parent " + actor_id)
				Equipment.dismount_actor(mh)
			mount.queue_free()
		# CHAR05 pet follow
		var pet := _load_glb(pet_path)
		if pet == null:
			fails.append("pet glb")
		else:
			var poff = Library.load_offset("pet", "XN_pet_01")
			var follow: Node3D = PetFollow.new()
			root.add_child(follow)
			follow.setup(actor, poff.to_transform().origin if poff else Vector3(1.2, 0, 0))
			follow.add_child(pet)
			var before := follow.global_position
			actor.global_position = Vector3(2, 0, 3)
			follow._process(1.0)
			if follow.global_position.is_equal_approx(before):
				fails.append("pet follow stuck " + actor_id)
			else:
				print("OK ", actor_id, " pet follow")
			follow.queue_free()
		# CHAR03 wing visuals: glow panels hidden without texture pack
		var wing := _load_glb(wing_path)
		if wing:
			var fixed := Equipment.prepare_accessory_visuals(wing, "wing", acc, false)
			var wh := Equipment.equip_accessory(actor, wing, "wing", "wing_L_01")
			if wh.is_empty():
				fails.append("wing " + actor_id)
			else:
				print("OK ", actor_id, " wing visuals fixed=", fixed)
				Equipment.unequip_accessory(wh)
			if is_instance_valid(wing) and wing.get_parent() == null:
				wing.free()
		actor.queue_free()
	_finish(fails)

func _finish(fails: PackedStringArray) -> void:
	if fails.is_empty():
		print("CHAR_MOUNT_PET_SMOKE_OK")
		quit(0)
		return
	for f in fails:
		print("FAIL ", f)
	print("CHAR_MOUNT_PET_SMOKE_FAIL")
	quit(1)
