extends Node3D
## Editable capital wrapper: lighting + CAP04 polish around generated geometry.
## Geometry scene stays on VPS (large); path is overridable for editor.
@export_file("*.tscn") var geometry_scene := "res://world/imported/capital_geometry_v8.tscn"
@export var apply_polish := true
var geometry: Node3D

func _ready() -> void:
	_ensure_lighting()
	_load_geometry()
	if apply_polish and geometry:
		var polish := Node.new()
		polish.name = "Cap04Polish"
		polish.set_script(load("res://world/cap04_polish.gd"))
		polish.set("geometry_root", geometry)
		add_child(polish)

func _ensure_lighting() -> void:
	if has_node("CapitalLighting"):
		return
	var lighting: Node = load("res://world/capital_lighting.tscn").instantiate()
	add_child(lighting)

func _load_geometry() -> void:
	if has_node("Geometry"):
		geometry = $Geometry as Node3D
		return
	if not ResourceLoader.exists(geometry_scene):
		push_warning("Capital geometry missing: " + geometry_scene)
		return
	geometry = load(geometry_scene).instantiate()
	geometry.name = "Geometry"
	add_child(geometry)
	move_child(geometry, 0)
