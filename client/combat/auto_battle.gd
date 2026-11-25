extends Node
## C03: client auto-battle assist. Manual joystick / skill input cancels local auto flag.
## Server remains authoritative via /v1/world/auto_battle when online.

signal cancelled_by_manual
signal toggled(enabled: bool)

var enabled := false
var target_id := 0

func set_enabled(on: bool) -> void:
	enabled = on
	toggled.emit(enabled)

func toggle() -> void:
	set_enabled(not enabled)

func on_manual_input() -> void:
	if enabled:
		enabled = false
		toggled.emit(false)
		cancelled_by_manual.emit()

func pick_nearest_hostile(origin: Vector3, tree: SceneTree, max_range: float = 12.0) -> Node:
	var best: Node = null
	var best_d := max_range
	for n in tree.get_nodes_in_group("hostile"):
		if n is Node3D and is_instance_valid(n):
			var d: float = origin.distance_to((n as Node3D).global_position)
			if d <= best_d:
				best_d = d
				best = n
	return best
