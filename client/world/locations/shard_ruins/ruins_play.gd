extends Node3D
## Shard Ruins playable wrapper.

const QuestLogScript = preload("res://content/quests/quest_log.gd")

var hero: CharacterBody3D
var camera: Camera3D
var joystick
var status_label: Label
var quest_log

func _ready() -> void:
	if not has_node("ShardRuins"):
		var loc: Node3D = load("res://world/locations/shard_ruins/shard_ruins.tscn").instantiate()
		loc.name = "ShardRuins"
		add_child(loc)
		move_child(loc, 0)
	quest_log = QuestLogScript.new()
	add_child(quest_log)
	quest_log.load_catalog()
	await get_tree().physics_frame
	_spawn_hero()
	_build_ui()
	_ensure_nav()

func _ensure_nav() -> void:
	var nav := NavigationRegion3D.new()
	nav.name = "Navigation"
	nav.set_script(load("res://world/location_navigation.gd"))
	add_child(nav)
	nav.set("half_extent", 45.0)
	nav.rebuild()

func _spawn_hero() -> void:
	hero = CharacterBody3D.new()
	hero.name = "Hero"
	hero.set_script(load("res://actors/hero_controller.gd"))
	add_child(hero)
	var capsule := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.6
	capsule.shape = shape
	capsule.position = Vector3(0, 0.9, 0)
	hero.add_child(capsule)
	var vis := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.35
	cap.height = 1.5
	vis.mesh = cap
	vis.position.y = 0.9
	hero.add_child(vis)
	hero.set("visual", vis)
	camera = Camera3D.new()
	camera.set_script(load("res://world/follow_camera.gd"))
	add_child(camera)
	camera.set("target", hero)
	camera.set("follow_offset", Vector3(0, 5.5, 9))
	hero.set("camera", camera)
	var spawn := get_node_or_null("ShardRuins/PlayerSpawn") as Node3D
	hero.global_position = spawn.global_position if spawn else Vector3(0, 1, -14)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	joystick = load("res://ui/controls/virtual_joystick.tscn").instantiate()
	layer.add_child(joystick)
	joystick.position = Vector2(48, -220)
	joystick.size = Vector2(160, 160)
	joystick.direction_changed.connect(func(d): if hero: hero.set_direction(d))
	status_label = Label.new()
	status_label.position = Vector2(16, 16)
	status_label.text = "Руины Осколка — E учёный, G к цели, F выход"
	layer.add_child(status_label)
	var back := Button.new()
	back.text = "К Пепельному рубежу"
	back.position = Vector2(16, 640)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://world/locations/ashen_outskirts/ashen_play.tscn"))
	layer.add_child(back)

func _unhandled_input(event: InputEvent) -> void:
	if hero == null:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		_talk_scholar()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_G:
		var scholar := get_node_or_null("ShardRuins/ShardScholar") as Node3D
		if scholar and hero.has_method("navigate_to"):
			hero.navigate_to(scholar.global_position)
			status_label.text = "Автопуть к учёному (NavMesh)"
	elif event is InputEventKey and event.pressed and event.keycode == KEY_F:
		get_tree().change_scene_to_file("res://world/locations/ashen_outskirts/ashen_play.tscn")
	if joystick and joystick.direction != Vector2.ZERO:
		return
	hero.set_direction(Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down")))

func _talk_scholar() -> void:
	var scholar := get_node_or_null("ShardRuins/ShardScholar") as Node3D
	if scholar == null or hero.global_position.distance_to(scholar.global_position) > 4.0:
		status_label.text = "Подойди к Хранителю знаний"
		return
	quest_log.notify_talk("npc_shard_scholar")
	status_label.text = "Учёный: осколок здесь ещё дышит. Запиши показания."
