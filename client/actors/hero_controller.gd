extends CharacterBody3D
## Manual joystick + NavigationAgent3D auto-path. Joystick cancels auto-path. No tap-to-move.
## Stuck detection repaths. Positions remain client-predicted until server authority (N02).

@export var speed := 3.0
@export var turn_speed := 12.0
@export var visual: Node3D
@export var animator: AnimationPlayer
@export var camera: Camera3D
@export var stuck_seconds := 1.25
@export var stuck_distance := 0.35

var direction := Vector2.ZERO
var auto_pathing := false
var _agent: NavigationAgent3D
var _nav_target := Vector3.ZERO
var _stuck_timer := 0.0
var _stuck_anchor := Vector3.ZERO

func _ready() -> void:
	add_to_group("player_hero")
	_agent = NavigationAgent3D.new()
	_agent.name = "NavigationAgent3D"
	_agent.path_desired_distance = 0.6
	_agent.target_desired_distance = 1.1
	_agent.avoidance_enabled = false
	add_child(_agent)

func set_direction(value: Vector2) -> void:
	direction = value.limit_length()
	if direction.length() > 0.05:
		auto_pathing = false

func navigate_to(world_pos: Vector3) -> void:
	if _agent == null:
		return
	auto_pathing = true
	direction = Vector2.ZERO
	_nav_target = world_pos
	_stuck_timer = 0.0
	_stuck_anchor = global_position
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
			# Stuck detection → repath
			if global_position.distance_to(_stuck_anchor) < stuck_distance:
				_stuck_timer += delta
				if _stuck_timer >= stuck_seconds:
					_agent.set_target_position(_nav_target)
					_stuck_timer = 0.0
					_stuck_anchor = global_position
			else:
				_stuck_timer = 0.0
				_stuck_anchor = global_position
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
