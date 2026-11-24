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
