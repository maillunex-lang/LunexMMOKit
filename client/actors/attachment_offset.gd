class_name AttachmentOffset
extends Resource

## Editable Darklord attachment offset. Shared by Character Studio and game runtime.
@export var attachment_id: String = ""
@export var kind: String = "weapon" ## weapon | wing | pet | mount_seat | mount | other
@export var class_id: String = ""
@export var model_id: String = ""
@export var equipment_id: String = ""
@export var mount_id: String = ""
@export var socket: String = "Bip001 R Hand"
@export var secondary_socket: String = "" ## left hand / dual
@export_enum("bone", "marker") var socket_mode: String = "bone"
@export var position: Vector3 = Vector3.ZERO
@export var rotation_degrees: Vector3 = Vector3.ZERO
@export var scale: Vector3 = Vector3.ONE
@export var child_name: String = "" ## prefab child for dual blades etc.
@export var animation_overrides: Dictionary = {} ## clip -> Transform3D as 12 floats optional later
@export var notes: String = ""
@export var source_unity: String = ""

func to_transform() -> Transform3D:
	var basis := Basis.from_euler(Vector3(
		deg_to_rad(rotation_degrees.x),
		deg_to_rad(rotation_degrees.y),
		deg_to_rad(rotation_degrees.z)
	))
	basis = basis.scaled(scale)
	return Transform3D(basis, position)
