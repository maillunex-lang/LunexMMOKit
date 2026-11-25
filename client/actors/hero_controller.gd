extends CharacterBody3D
@export var speed := 3.0
@export var turn_speed := 12.0
@export var visual: Node3D
@export var animator: AnimationPlayer
@export var camera: Camera3D
var direction := Vector2.ZERO
func set_direction(value: Vector2):
	direction = value.limit_length()
func _physics_process(delta):
	var forward := Vector3(0,0,-1)
	var right := Vector3.RIGHT
	if is_instance_valid(camera):
		forward = -camera.global_basis.z
		forward.y = 0
		forward = forward.normalized()
		right = forward.cross(Vector3.UP)
	var movement := right*direction.x-forward*direction.y
	velocity.x = movement.x*speed
	velocity.z = movement.z*speed
	velocity.y -= 9.8*delta
	move_and_slide()
	if movement.length()>0.01 and is_instance_valid(visual):
		visual.rotation.y = lerp_angle(visual.rotation.y,atan2(movement.x,movement.z),minf(turn_speed*delta,1))
	if is_instance_valid(animator):
		var clip := "run" if movement.length()>0.01 else "stand"
		if animator.current_animation != clip and animator.has_animation(clip):
			animator.play(clip)
