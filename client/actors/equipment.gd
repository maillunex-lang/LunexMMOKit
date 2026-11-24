extends RefCounted

## Darklord base weapon attachment specifications.
## Source rule: CActorObject.ChangeWeapon parents the selected weapon container
## to the hand socket and then sets local position, rotation and scale to identity.
## Assassin is the only base class that splits DM_R_wuqi01 and DM_L_wuqi01.

static func _right_blade_transform() -> Transform3D:
	return Transform3D(Basis(Quaternion(0.0000009685756, -0.00000028312215, 1.0, -0.000000043711115)), Vector3.ZERO)

static func _left_blade_transform() -> Transform3D:
	return Transform3D(Basis.from_scale(Vector3(-1.0, 1.0000004, 1.0000001)), Vector3.ZERO)

static func darklord_base_weapon_spec(weapon_id: String) -> Dictionary:
	match weapon_id:
		"100011000":
			return {"mode": "single", "marker": "DM_R_Hand2"}
		"200011000":
			return {"mode": "single", "marker": "DM_R_Hand2"}
		"300011000":
			return {"mode": "single", "marker": "DM_R_Hand2"}
		"400011000":
			return {
				"mode": "dual",
				"right_marker": "DM_R_Hand2",
				"left_marker": "DM_L_Hand2",
				"right_children": {"body2": _right_blade_transform()},
				"left_children": {"body1": _left_blade_transform()},
			}
	return {}

static func find_unique_marker(actor: Node3D, marker_name: String) -> Node3D:
	var nodes := actor.find_children(marker_name, "Node3D", true, false)
	if nodes.size() != 1:
		return null
	return nodes[0] as Node3D

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

static func equip_weapon(actor: Node3D, item: Node3D, weapon_id: String) -> Dictionary:
	var spec := darklord_base_weapon_spec(weapon_id)
	if spec.is_empty() or actor == null or item == null:
		return {}
	spec["weapon_id"] = weapon_id
	if String(spec.get("mode", "")) == "dual":
		return _equip_dual(actor, item, spec)
	return _equip_single(actor, item, spec)

static func _equip_single(actor: Node3D, item: Node3D, spec: Dictionary) -> Dictionary:
	var marker := find_unique_marker(actor, String(spec.get("marker", "DM_R_Hand2")))
	if marker == null:
		return {}
	var original := _detach(item)
	marker.add_child(item)
	item.transform = Transform3D.IDENTITY
	return {
		"mode": "single",
		"weapon_id": String(spec.get("weapon_id", "")),
		"marker": marker,
		"root": item,
		"original_parent": original["parent"],
		"original_transform": original["transform"],
	}

static func _equip_dual(actor: Node3D, item: Node3D, spec: Dictionary) -> Dictionary:
	var right_marker := find_unique_marker(actor, String(spec.get("right_marker", "DM_R_Hand2")))
	var left_marker := find_unique_marker(actor, String(spec.get("left_marker", "DM_L_Hand2")))
	if right_marker == null or left_marker == null:
		return {}
	var attachments := []
	for side in ["right", "left"]:
		var marker: Node3D = right_marker if side == "right" else left_marker
		var children: Dictionary = spec.get(side + "_children", {})
		for child_name in children.keys():
			var child := item.find_child(String(child_name), true, false) as Node3D
			if child == null:
				for entry in attachments:
					_restore(entry["node"], entry["original_parent"], entry["original_transform"])
				return {}
			var original := _detach(child)
			marker.add_child(child)
			child.transform = children[child_name]
			attachments.append({
				"name": String(child_name),
				"node": child,
				"marker": marker,
				"spec_transform": children[child_name],
				"original_parent": original["parent"],
				"original_transform": original["transform"],
			})
	item.visible = false
	return {
		"mode": "dual",
		"weapon_id": String(spec.get("weapon_id", "")),
		"host": item,
		"attachments": attachments,
	}

static func unequip_weapon(handle: Dictionary) -> bool:
	if handle.is_empty():
		return false
	if String(handle.get("mode", "")) == "dual":
		var host: Node3D = handle.get("host")
		for entry in handle.get("attachments", []):
			var node: Node3D = entry.get("node")
			if node == null or not is_instance_valid(node):
				continue
			var marker: Node3D = entry.get("marker")
			if marker != null and node.get_parent() == marker:
				marker.remove_child(node)
			_restore(node, host, entry.get("original_transform", Transform3D.IDENTITY))
		if host != null and is_instance_valid(host):
			host.visible = true
		return true
	var root: Node3D = handle.get("root")
	var marker: Node3D = handle.get("marker")
	if root == null or not is_instance_valid(root):
		return false
	if marker != null and root.get_parent() == marker:
		marker.remove_child(root)
	_restore(root, handle.get("original_parent"), handle.get("original_transform", Transform3D.IDENTITY))
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

## Imported Darklord sockets are animated Node3D markers, not skin joints.
static func attach_marker(actor: Node3D, marker_name: String, item: Node3D, offset: Transform3D = Transform3D.IDENTITY) -> Node3D:
	var marker := find_unique_marker(actor, marker_name)
	if marker == null or item.get_parent() != null:
		return null
	marker.add_child(item)
	item.transform = offset
	return marker

## Compatibility helper for the original assassin split.
static func attach_dual(actor: Node3D, item: Node3D) -> Array[Node3D]:
	var spec := darklord_base_weapon_spec("400011000")
	var handle := _equip_dual(actor, item, spec)
	if handle.is_empty():
		return []
	var out: Array[Node3D] = []
	for entry in handle.get("attachments", []):
		out.append(entry.get("node"))
	return out
