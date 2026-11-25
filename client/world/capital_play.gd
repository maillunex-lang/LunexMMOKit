extends Node3D
## CAP05 city play: capital geometry + collisions + 4 classes + joystick + follow camera.
const Equipment = preload("res://actors/equipment.gd")
const DarklordMaterial = preload("res://content/shaders/darklord_material.gd")

@export var actor_ids: PackedStringArray = ["10001", "20001", "30001", "40001"]
@export var class_names: PackedStringArray = ["Воин", "Лучник", "Маг", "Ассасин"]
@export var spawn_hint := Vector3(90, 120, -140)
@export var actor_glb_template := "/home/gamedev/darklord-dgi/exports/%s.glb"
@export var weapon_glb_template := "/home/gamedev/darklord-dgi/exports/weapon-%s.glb"
@export var source_root := "/home/gamedev/Darklord"
@export var material_params_path := "/home/gamedev/darklord-dgi/material-params.json"

var weapon_ids := {
	"10001": "100011000",
	"20001": "200011000",
	"30001": "300011000",
	"40001": "400011000",
}
var current_index := 0
var material_params: Dictionary = {}
var hero: CharacterBody3D
var visual: Node3D
var animator: AnimationPlayer
var camera: Camera3D
var joystick
var status_label: Label
var fps_label: Label
var graphics_index := 1
const GRAPHICS_PRESETS := [
	{"name": "Low", "scale": 0.6, "shadows": false, "msaa": 0},
	{"name": "Med", "scale": 0.85, "shadows": true, "msaa": 1},
	{"name": "High", "scale": 1.0, "shadows": true, "msaa": 2},
]

func _ready() -> void:
	_load_materials()
	_ensure_city()
	await get_tree().process_frame
	await get_tree().physics_frame
	_build_collisions()
	for i in range(8):
		await get_tree().physics_frame
	_spawn_hero()
	_build_navigation()
	_build_ui()
	_load_class(0)

func _load_materials() -> void:
	if FileAccess.file_exists(material_params_path):
		material_params = JSON.parse_string(FileAccess.get_file_as_string(material_params_path))

func _ensure_city() -> void:
	if has_node("CapitalCity"):
		return
	var city: Node3D = load("res://world/capital_city.tscn").instantiate()
	city.name = "CapitalCity"
	add_child(city)
	move_child(city, 0)

func _geometry() -> Node3D:
	var city := get_node_or_null("CapitalCity")
	if city and city.has_node("Geometry"):
		return city.get_node("Geometry") as Node3D
	return null

func _build_collisions() -> void:
	var geom := _geometry()
	var col := get_node_or_null("Collisions") as Node3D
	if col == null:
		col = Node3D.new()
		col.name = "Collisions"
		col.set_script(load("res://world/capital_collisions.gd"))
		add_child(col)
	col.set("geometry_root", geom)
	col.set("spawn_pad_center", Vector3(spawn_hint.x, 52, spawn_hint.z))
	var n: int = col.rebuild()
	print("CAP05_COLLISIONS ", n)

func _spawn_hero() -> void:
	hero = CharacterBody3D.new()
	hero.name = "Hero"
	hero.set_script(load("res://actors/hero_controller.gd"))
	hero.floor_snap_length = 0.6
	hero.floor_max_angle = deg_to_rad(55)
	add_child(hero)
	var capsule := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.6
	capsule.shape = shape
	capsule.position = Vector3(0, 0.9, 0)
	hero.add_child(capsule)
	camera = Camera3D.new()
	camera.name = "FollowCamera"
	camera.set_script(load("res://world/follow_camera.gd"))
	add_child(camera)
	camera.set("target", hero)
	camera.set("follow_offset", Vector3(0, 6, 10))
	hero.set("camera", camera)
	hero.position = _find_spawn()
	camera.global_position = hero.global_position + Vector3(0, 6, 10)

func _find_spawn() -> Vector3:
	var space := get_world_3d().direct_space_state
	var from := Vector3(spawn_hint.x, 200, spawn_hint.z)
	var to := Vector3(spawn_hint.x, -50, spawn_hint.z)
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
	if not hit.is_empty():
		print("SPAWN_HIT ", hit.position)
		return hit.position + Vector3(0, 0.25, 0)
	print("SPAWN_MISS_FALLBACK")
	return Vector3(spawn_hint.x, 53.2, spawn_hint.z)

func _build_navigation() -> void:
	var nav := get_node_or_null("Navigation") as NavigationRegion3D
	if nav == null:
		nav = NavigationRegion3D.new()
		nav.name = "Navigation"
		nav.set_script(load("res://world/capital_navigation.gd"))
		add_child(nav)
	if hero:
		nav.set("center", hero.global_position)
	nav.rebuild()

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)
	joystick = load("res://ui/controls/virtual_joystick.tscn").instantiate()
	joystick.name = "Joystick"
	layer.add_child(joystick)
	joystick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	joystick.position = Vector2(48, -220)
	joystick.size = Vector2(160, 160)
	joystick.direction_changed.connect(_on_joy)
	status_label = Label.new()
	status_label.position = Vector2(16, 16)
	layer.add_child(status_label)
	fps_label = Label.new()
	fps_label.position = Vector2(16, 48)
	layer.add_child(fps_label)
	var row := HBoxContainer.new()
	row.position = Vector2(16, 640)
	layer.add_child(row)
	for i in actor_ids.size():
		var b := Button.new()
		b.text = class_names[i] if i < class_names.size() else actor_ids[i]
		b.pressed.connect(_load_class.bind(i))
		row.add_child(b)
	var gfx := Button.new()
	gfx.name = "GfxButton"
	gfx.text = "GFX Med"
	gfx.pressed.connect(_cycle_graphics)
	row.add_child(gfx)
	_apply_graphics(graphics_index)
	_set_status("город")

func _cycle_graphics() -> void:
	graphics_index = (graphics_index + 1) % GRAPHICS_PRESETS.size()
	_apply_graphics(graphics_index)

func _apply_graphics(index: int) -> void:
	var p: Dictionary = GRAPHICS_PRESETS[index]
	get_tree().root.content_scale_factor = float(p.scale)
	var sun := get_node_or_null("CapitalCity/CapitalLighting/Sun") as DirectionalLight3D
	if sun:
		sun.shadow_enabled = bool(p.shadows)
	var vp := get_viewport()
	if vp:
		vp.msaa_3d = int(p.msaa) as Viewport.MSAA
	var hud := get_node_or_null("HUD")
	if hud:
		var gfx_btn := hud.find_child("GfxButton", true, false) as Button
		if gfx_btn:
			gfx_btn.text = "GFX " + String(p.name)
	print("CAP05_GFX ", p.name)

func _on_joy(dir: Vector2) -> void:
	if hero:
		hero.set_direction(dir)

func _unhandled_input(event: InputEvent) -> void:
	# Keyboard fallback; no tap-to-move.
	if event is InputEventKey and hero:
		var dir := Vector2(
			Input.get_axis("ui_left", "ui_right"),
			Input.get_axis("ui_up", "ui_down")
		)
		if joystick and joystick.direction == Vector2.ZERO:
			hero.set_direction(dir)

func _process(_delta: float) -> void:
	if fps_label:
		fps_label.text = "FPS %.0f" % Engine.get_frames_per_second()

func _load_glb(path: String) -> Node3D:
	if not FileAccess.file_exists(path):
		return null
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(path, state) != OK:
		return null
	return doc.generate_scene(state) as Node3D

func _load_class(index: int) -> void:
	current_index = wrapi(index, 0, actor_ids.size())
	if visual and is_instance_valid(visual):
		visual.queue_free()
	visual = null
	animator = null
	var actor_id := String(actor_ids[current_index])
	var weapon_id := String(weapon_ids.get(actor_id, actor_id))
	visual = _load_glb(actor_glb_template % actor_id)
	if visual == null:
		_set_status("нет модели " + actor_id)
		return
	hero.add_child(visual)
	visual.position = Vector3.ZERO
	hero.set("visual", visual)
	if material_params.has(actor_id) and material_params[actor_id].size() > 0:
		DarklordMaterial.apply(visual, material_params[actor_id][0], source_root)
	var weapon := _load_glb(weapon_glb_template % weapon_id)
	if weapon:
		if material_params.has(weapon_id) and material_params[weapon_id].size() > 0:
			DarklordMaterial.apply(weapon, material_params[weapon_id][0], source_root)
		Equipment.equip_weapon(visual, weapon, weapon_id)
	var players := visual.find_children("*", "AnimationPlayer", true, false)
	if players.size() > 0:
		animator = players[0]
		hero.set("animator", animator)
		if animator.has_animation("stand"):
			animator.play("stand")
	var label := class_names[current_index] if current_index < class_names.size() else actor_id
	_set_status("%s @ %s" % [label, str(hero.global_position)])

func _set_status(text: String) -> void:
	if status_label:
		status_label.text = text
	print("CAP05_STATUS ", text)
