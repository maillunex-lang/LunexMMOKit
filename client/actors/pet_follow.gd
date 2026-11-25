extends Node3D
## CHAR05: simple local pet follow — keeps AttachmentOffset lateral offset beside a target.

@export var follow_distance := 1.2
@export var follow_height := 0.0
@export var lerp_speed := 8.0

var target: Node3D
var offset: Vector3 = Vector3(1.2, 0, 0)
var follow_scale: Vector3 = Vector3.ONE

func setup(actor: Node3D, local_offset: Vector3, scale_v: Vector3 = Vector3.ONE) -> void:
	target = actor
	offset = local_offset
	follow_scale = scale_v
	scale = follow_scale
	if target != null:
		global_position = target.global_transform * offset

func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	var desired := target.global_transform * offset
	global_position = global_position.lerp(desired, clampf(lerp_speed * delta, 0.0, 1.0))
	rotation.y = target.global_rotation.y
