extends CharacterBody3D
## Manual joystick + optional NavigationAgent3D auto-path (NavMesh, not fixed waypoints).

@export var speed := 3.0
@export var turn_speed := 12.0
@export var visual: Node3D
@export var animator: AnimationPlayer
@export var camera: Camera3D

var direction := Vector2.ZERO
var auto_pathing := false
var _agent: NavigationAgent3D

func _ready() -> void:
	_agent = NavigationAgent3D.new()
	_agent.name = "NavigationAgent3D"
	_agent.path_desired_distance = 0.6
	_agent.target_desired_distance = 1.1
	_agent.avoidance_enabled = false
	add_child(_agent)

func set_direction(value: Vector2) -> void:
	direction = value.limit_length()
	if direction.length() > 0.05:
		# Manual input cancels auto-path.
		auto_pathing = false

func navigate_to(world_pos: Vector3) -> void:
	if _agent == null:
		return
	auto_pathing = true
	direction = Vector2.ZERO
	_agent.set_target_position(world_pos)

func stop_navigation() -> void:
	auto_pathing = false
	if _agent:
		_agent.set_target_position(global_position)

func _physics_process(delta: float) -> void:
	var movement := Vector3.ZERO
	if auto_pathing and _agent:
		if _agent.is_navigation_finished():
			auto_pathing = false
		else:
			var next: Vector3 = _agent.get_next_path_position()
			var to := next - global_position
			to.y = 0
			if to.length() > 0.05:
				movement = to.normalized()
	else:
		var forward := Vector3(0, 0, -1)
		var right := Vector3.RIGHT
		if is_instance_valid(camera):
			forward = -camera.global_basis.z
			forward.y = 0
			forward = forward.normalized()
			right = forward.cross(Vector3.UP)
		movement = right * direction.x - forward * direction.y

	velocity.x = movement.x * speed
	velocity.z = movement.z * speed
	velocity.y -= 9.8 * delta
	move_and_slide()
	if movement.length() > 0.01 and is_instance_valid(visual):
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(movement.x, movement.z), minf(turn_speed * delta, 1))
	if is_instance_valid(animator):
		var clip := "run" if movement.length() > 0.01 else "stand"
		if animator.current_animation != clip and animator.has_animation(clip):
			animator.play(clip)
