extends RefCounted
## Attach a separately imported item to an explicitly verified skeleton socket.
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
	var markers := actor.find_children(marker_name, "Node3D", true, false)
	if markers.size() != 1 or item.get_parent() != null:
		return null
	var marker: Node3D = markers[0]
	marker.add_child(item)
	item.transform = offset
	return marker

## Reconstruct the two Unity weapon containers. FBX geometry is already
## converted by Godot; child transforms are candidates until visual parity.
static func attach_dual(actor: Node3D, item: Node3D) -> Array[Node3D]:
	var right := item.find_child("body2", true, false) as Node3D
	var left := item.find_child("body1", true, false) as Node3D
	var r := actor.find_children("DM_R_Hand2", "Node3D", true, false)
	var l := actor.find_children("DM_L_Hand2", "Node3D", true, false)
	if right == null or left == null or r.size() != 1 or l.size() != 1:
		return []
	right.reparent(r[0], false)
	left.reparent(l[0], false)
	right.transform = Transform3D(Basis(Vector3.BACK, PI), Vector3.ZERO)
	left.transform = Transform3D(Basis.from_scale(Vector3(-1, 1, 1)), Vector3.ZERO)
	return [right, left]
