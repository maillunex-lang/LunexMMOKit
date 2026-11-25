extends Camera3D
@export var target: Node3D
@export var follow_offset := Vector3(0,8,10)
@export var smoothing := 8.0
func _process(delta):
	if is_instance_valid(target):
		global_position = global_position.lerp(target.global_position+follow_offset,1.0-exp(-smoothing*delta))
		look_at(target.global_position+Vector3.UP)
