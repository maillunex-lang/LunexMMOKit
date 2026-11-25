extends Node3D
## Playable wrapper for WORLD-DESIGN-002 Eternity Capital (joystick, 4 classes, FPS).
const Equipment = preload("res://actors/equipment.gd")
const DarklordMaterial = preload("res://content/shaders/darklord_material.gd")

@export var actor_ids: PackedStringArray = ["10001", "20001", "30001", "40001"]
@export var class_names: PackedStringArray = ["Воин", "Лучник", "Маг", "Ассасин"]
@export var actor_glb_template := "/home/gamedev/darklord-dgi/exports/%s.glb"
@export var weapon_glb_template := "/home/gamedev/darklord-dgi/exports/weapon-%s.glb"
@export var source_root := "/home/gamedev/Darklord"
@export var material_params_path := "/home/gamedev/darklord-dgi/material-params.json"

var weapon_ids := {"10001": "100011000", "20001": "200011000", "30001": "300011000", "40001": "400011000"}
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

func _ready() -> void:
	if FileAccess.file_exists(material_params_path):
		material_params = JSON.parse_string(FileAccess.get_file_as_string(material_params_path))
	if not has_node("EternityCapital"):
		var city: Node3D = load("res://world/locations/eternity_capital/eternity_capital.tscn").instantiate()
		city.name = "EternityCapital"
		add_child(city)
		move_child(city, 0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_spawn_hero()
	_build_ui()
	_load_class(0)

func _spawn_hero() -> void:
	hero = CharacterBody3D.new()
	hero.name = "Hero"
	hero.set_script(load("res://actors/hero_controller.gd"))
	hero.floor_snap_length = 0.6
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
	camera.set("follow_offset", Vector3(0, 5.5, 9))
	hero.set("camera", camera)
	var spawn := get_node_or_null("EternityCapital/PlayerSpawn") as Node3D
	hero.global_position = spawn.global_position if spawn else Vector3(0, 1, -60)
	camera.global_position = hero.global_position + Vector3(0, 5.5, 9)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)
	joystick = load("res://ui/controls/virtual_joystick.tscn").instantiate()
	layer.add_child(joystick)
	joystick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	joystick.position = Vector2(48, -220)
	joystick.size = Vector2(160, 160)
	joystick.direction_changed.connect(func(d): if hero: hero.set_direction(d))
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
		b.text = class_names[i]
		b.pressed.connect(_load_class.bind(i))
		row.add_child(b)

func _process(_d: float) -> void:
	if fps_label:
		fps_label.text = "FPS %.0f" % Engine.get_frames_per_second()

func _unhandled_input(_event: InputEvent) -> void:
	if hero == null:
		return
	if joystick and joystick.direction != Vector2.ZERO:
		return
	hero.set_direction(Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down")))

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
	var actor_id := String(actor_ids[current_index])
	var weapon_id := String(weapon_ids[actor_id])
	visual = _load_glb(actor_glb_template % actor_id)
	if visual == null:
		status_label.text = "нет модели " + actor_id
		return
	hero.add_child(visual)
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
	status_label.text = "%s | Eternity Capital" % class_names[current_index]
