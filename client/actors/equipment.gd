extends RefCounted

const Library = preload("res://actors/attachment_library.gd")

## Darklord weapon attachment runtime.
## Offsets come from AttachmentOffset resources (res://content/attachments + user overrides).
## Prefer Skeleton3D bone sockets (Bip001 R/L Hand): DM_*_Hand2 markers under Prop1 stay at hip in stand.

static func darklord_base_weapon_spec(weapon_id: String) -> Dictionary:
	var single = Library.load_offset("weapon", weapon_id)
	if weapon_id == "400011000":
		var right = Library.load_offset("weapon", weapon_id, "", "body2")
		var left = Library.load_offset("weapon", weapon_id, "", "body1")
		if right == null or left == null:
			return {}
		return {
			"mode": "dual",
			"right": right,
			"left": left,
		}
	if single == null:
		if weapon_id in ["100011000", "200011000", "300011000"]:
			return {
				"mode": "single",
				"socket": "Bip001 R Hand",
				"socket_mode": "bone",
				"offset": Transform3D.IDENTITY,
			}
		return {}
	return {
		"mode": "single",
		"socket": single.socket if String(single.socket) != "" else "Bip001 R Hand",
		"socket_mode": single.socket_mode if String(single.socket_mode) != "" else "bone",
		"offset": single.to_transform(),
		"resource": single,
	}

static func find_unique_marker(actor: Node3D, marker_name: String) -> Node3D:
	var nodes := actor.find_children(marker_name, "Node3D", true, false)
	if nodes.size() != 1:
		return null
	return nodes[0] as Node3D

static func find_skeleton(actor: Node3D) -> Skeleton3D:
	var skels := actor.find_children("*", "Skeleton3D", true, false)
	if skels.is_empty():
		return null
	return skels[0] as Skeleton3D

static func _detach(node: Node3D) -> Dictionary:
	var parent := node.get_parent()
	var transform := node.transform
	if parent != null:
		parent.remove_child(node)
	node.owner = null
	return {"parent": parent, "transform": transform}

static func _restore(node: Node3D, parent: Node, transform: Transform3D) -> void:
	if parent != null and is_instance_valid(parent):
		parent.add_child(node)
	node.transform = transform

static func _bind_to_socket(actor: Node3D, socket_name: String, socket_mode: String, item: Node3D, offset: Transform3D) -> Dictionary:
	var original := _detach(item)
	if socket_mode == "marker":
		var marker := find_unique_marker(actor, socket_name)
		if marker == null:
			_restore(item, original["parent"], original["transform"])
			return {}
		marker.add_child(item)
		item.transform = offset
		return {
			"bind": "marker",
			"marker": marker,
			"root": item,
			"original_parent": original["parent"],
			"original_transform": original["transform"],
		}
	var skeleton := find_skeleton(actor)
	if skeleton == null or skeleton.find_bone(socket_name) < 0:
		_restore(item, original["parent"], original["transform"])
		return {}
	var bone_socket := BoneAttachment3D.new()
	bone_socket.name = "Attach_" + socket_name
	bone_socket.bone_name = socket_name
	skeleton.add_child(bone_socket)
	bone_socket.add_child(item)
	item.transform = offset
	return {
		"bind": "bone",
		"bone_socket": bone_socket,
		"root": item,
		"original_parent": original["parent"],
		"original_transform": original["transform"],
	}

static func equip_weapon(actor: Node3D, item: Node3D, weapon_id: String) -> Dictionary:
	var spec := darklord_base_weapon_spec(weapon_id)
	if spec.is_empty() or actor == null or item == null:
		return {}
	spec["weapon_id"] = weapon_id
	if String(spec.get("mode", "")) == "dual":
		return _equip_dual(actor, item, spec)
	return _equip_single(actor, item, spec)

static func _equip_single(actor: Node3D, item: Node3D, spec: Dictionary) -> Dictionary:
	var bound := _bind_to_socket(
		actor,
		String(spec.get("socket", "Bip001 R Hand")),
		String(spec.get("socket_mode", "bone")),
		item,
		spec.get("offset", Transform3D.IDENTITY)
	)
	if bound.is_empty():
		return {}
	bound["mode"] = "single"
	bound["weapon_id"] = String(spec.get("weapon_id", ""))
	return bound

static func _equip_dual(actor: Node3D, item: Node3D, spec: Dictionary) -> Dictionary:
	var right_res = spec.get("right")
	var left_res = spec.get("left")
	var right_socket: String = right_res.socket if right_res and String(right_res.socket) != "" else "Bip001 R Hand"
	var left_socket: String = left_res.socket if left_res and String(left_res.socket) != "" else "Bip001 L Hand"
	var right_mode: String = right_res.socket_mode if right_res and String(right_res.socket_mode) != "" else "bone"
	var left_mode: String = left_res.socket_mode if left_res and String(left_res.socket_mode) != "" else "bone"
	var children := {
		"body2": {"socket": right_socket, "mode": right_mode, "offset": right_res.to_transform() if right_res else Transform3D.IDENTITY},
		"body1": {"socket": left_socket, "mode": left_mode, "offset": left_res.to_transform() if left_res else Transform3D.IDENTITY},
	}
	var attachments := []
	for child_name in children.keys():
		var child := item.find_child(String(child_name), true, false) as Node3D
		if child == null:
			for entry in attachments:
				_unequip_bound(entry)
			return {}
		var cfg: Dictionary = children[child_name]
		var bound := _bind_to_socket(actor, String(cfg.socket), String(cfg.mode), child, cfg.offset)
		if bound.is_empty():
			for entry in attachments:
				_unequip_bound(entry)
			return {}
		bound["name"] = String(child_name)
		attachments.append(bound)
	item.visible = false
	return {
		"mode": "dual",
		"weapon_id": String(spec.get("weapon_id", "")),
		"host": item,
		"attachments": attachments,
	}

static func _unequip_bound(bound: Dictionary) -> void:
	var root: Node3D = bound.get("root")
	if root == null or not is_instance_valid(root):
		return
	var parent := root.get_parent()
	if parent != null:
		parent.remove_child(root)
	_restore(root, bound.get("original_parent"), bound.get("original_transform", Transform3D.IDENTITY))
	var bone_socket: BoneAttachment3D = bound.get("bone_socket")
	if bone_socket != null and is_instance_valid(bone_socket):
		bone_socket.queue_free()

static func unequip_weapon(handle: Dictionary) -> bool:
	if handle.is_empty():
		return false
	if String(handle.get("mode", "")) == "dual":
		var host: Node3D = handle.get("host")
		for entry in handle.get("attachments", []):
			_unequip_bound(entry)
		if host != null and is_instance_valid(host):
			host.visible = true
		return true
	_unequip_bound(handle)
	return true

static func attach(skeleton: Skeleton3D, bone_name: String, item: Node3D, offset: Transform3D = Transform3D.IDENTITY) -> BoneAttachment3D:
	var index := skeleton.find_bone(bone_name)
	if index < 0 or item.get_parent() != null:
		return null
	var socket := BoneAttachment3D.new()
	socket.bone_name = bone_name
	skeleton.add_child(socket)
	socket.add_child(item)
	item.transform = offset
	return socket

static func remove(socket: BoneAttachment3D) -> void:
	if is_instance_valid(socket):
		socket.queue_free()

static func attach_marker(actor: Node3D, marker_name: String, item: Node3D, offset: Transform3D = Transform3D.IDENTITY) -> Node3D:
	var marker := find_unique_marker(actor, marker_name)
	if marker == null or item.get_parent() != null:
		return null
	marker.add_child(item)
	item.transform = offset
	return marker

static func attach_dual(actor: Node3D, item: Node3D) -> Array[Node3D]:
	var handle := equip_weapon(actor, item, "400011000")
	if handle.is_empty():
		return []
	var out: Array[Node3D] = []
	for entry in handle.get("attachments", []):
		out.append(entry.get("root"))
	return out
