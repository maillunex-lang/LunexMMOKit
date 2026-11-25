extends CharacterBody3D
## Lightweight hostile for chapter-1 vertical slice.

@export var stable_id: String = "mob_shardling"
@export var display_name: String = "Осколочник"
@export var max_hp: int = 40
@export var touch_damage: int = 0

var hp: int
signal died(stable_id: String)

func _ready() -> void:
	hp = max_hp
	set_meta("stable_id", stable_id)
	set_meta("hostile", true)
	add_to_group("hostile")
	if not has_node("Visual"):
		var mi := MeshInstance3D.new()
		mi.name = "Visual"
		var cap := CapsuleMesh.new()
		cap.radius = 0.4
		cap.height = 1.4
		mi.mesh = cap
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.55, 0.25, 0.45)
		mi.set_surface_override_material(0, mat)
		mi.position.y = 0.9
		add_child(mi)
	if not has_node("CollisionShape3D"):
		var col := CollisionShape3D.new()
		var shape := CapsuleShape3D.new()
		shape.radius = 0.4
		shape.height = 1.4
		col.shape = shape
		col.position.y = 0.9
		add_child(col)

func apply_damage(amount: int) -> void:
	if hp <= 0:
		return
	hp -= amount
	if hp <= 0:
		died.emit(stable_id)
		queue_free()
