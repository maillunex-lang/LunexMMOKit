extends Node3D
signal arrived
signal expired
var target: Node3D
var speed := 2.4
var lifetime := 1.0
var elapsed := 0.0
var finished := false
func _physics_process(delta: float) -> void:
	if finished: return
	if not is_instance_valid(target):
		finish(false)
		return
	var remaining := maxf(0.0,lifetime-elapsed)
	var step := minf(delta,remaining)
	global_position = global_position.move_toward(target.global_position,speed*step)
	elapsed += step
	if global_position.distance_to(target.global_position)<0.0001:
		finish(true)
	elif elapsed >= lifetime:
		finish(false)
func finish(hit: bool) -> void:
	finished = true
	if hit: arrived.emit()
	else: expired.emit()
	queue_free()
