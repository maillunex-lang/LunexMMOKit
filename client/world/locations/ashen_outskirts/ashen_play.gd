extends Node3D
## Playable Ashen Outskirts — chapter 1 destination.

func _ready() -> void:
	if not has_node("AshenOutskirts"):
		var loc: Node3D = load("res://world/locations/ashen_outskirts/ashen_outskirts.tscn").instantiate()
		loc.name = "AshenOutskirts"
		add_child(loc)
		move_child(loc, 0)
