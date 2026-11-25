extends Node3D
## Ashen Outskirts: warden quests, portals to capital / shard ruins, NavMesh auto-path.
## Uses GameSession (FIX-009). LOCAL PROTOTYPE until server authority.

const QuestLogScript = preload("res://content/quests/quest_log.gd")

var hero: CharacterBody3D
var camera: Camera3D
var hud
var quest_log

func _ready() -> void:
	if not has_node("AshenOutskirts"):
		var loc: Node3D = load("res://world/locations/ashen_outskirts/ashen_outskirts.tscn").instantiate()
		loc.name = "AshenOutskirts"
		add_child(loc)
		move_child(loc, 0)
	quest_log = QuestLogScript.new()
	add_child(quest_log)
	quest_log.load_catalog()
	GameSession.apply_to_quest_log(quest_log)
	GameSession.travel_to("ashen_outskirts")
	await get_tree().physics_frame
	_spawn_hero()
	_build_ui()
	_ensure_nav()
	_refresh_quest()

func _ensure_nav() -> void:
	var nav := NavigationRegion3D.new()
	nav.name = "Navigation"
	nav.set_script(load("res://world/location_navigation.gd"))
	add_child(nav)
	nav.set("half_extent", 50.0)
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
	var spawn := get_node_or_null("AshenOutskirts/PlayerSpawn") as Node3D
	hero.global_position = spawn.global_position if spawn else Vector3(0, 1, -8)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = load("res://ui/hud/game_hud.tscn").instantiate()
	layer.add_child(hud)
	hud.joystick_moved.connect(func(d): if hero: hero.set_direction(d))
	hud.interact_pressed.connect(_talk_warden)
	hud.goto_pressed.connect(_goto_objective)
	hud.portal_pressed.connect(_enter_ruins)
	hud.set_status("Пепельный рубеж · ПРОТОТИП · " + LunexAssets.status_line())
	var row := HBoxContainer.new()
	row.position = Vector2(200, 16)
	layer.add_child(row)
	var back := Button.new()
	back.text = "Столица"
	back.pressed.connect(_to_capital)
	row.add_child(back)
	var ruins := Button.new()
	ruins.text = "Руины"
	ruins.pressed.connect(_enter_ruins)
	row.add_child(ruins)

func _refresh_quest() -> void:
	if hud and quest_log:
		hud.set_quest(quest_log.tracker_text())
	GameSession.sync_quest_log(quest_log)

func _unhandled_input(event: InputEvent) -> void:
	if hero == null:
		return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_E: _talk_warden()
			KEY_G: _goto_objective()
			KEY_R: _enter_ruins()
			KEY_F: _to_capital()
	if hud and hud.joystick and hud.joystick.direction != Vector2.ZERO:
		return
	hero.set_direction(Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down")))

func _talk_warden() -> void:
	var warden := get_node_or_null("AshenOutskirts/AshenWarden") as Node3D
	if warden == null or hero.global_position.distance_to(warden.global_position) > 4.0:
		hud.set_status("Подойди к Хранителю рубежа")
		return
	var started: String = String(quest_log.offer_from_npc("npc_ashen_warden"))
	quest_log.notify_talk("npc_ashen_warden")
	hud.set_status(("Квест: " + started) if started != "" else "Хранитель: иди к Руинам Осколка")
	_refresh_quest()

func _goto_objective() -> void:
	var warden := get_node_or_null("AshenOutskirts/AshenWarden") as Node3D
	var ruins := get_node_or_null("AshenOutskirts/Portal_RuinsGate") as Node3D
	var target: Node3D = ruins if ruins else warden
	if target and hero.has_method("navigate_to"):
		hero.navigate_to(target.global_position)
		hud.set_status("Автопуть (NavMesh)")

func _persist_and_go(scene: String, loc_id: String) -> void:
	GameSession.sync_quest_log(quest_log)
	GameSession.travel_to(loc_id)
	get_tree().change_scene_to_file(scene)

func _to_capital() -> void:
	_persist_and_go("res://world/locations/eternity_capital/eternity_play.tscn", "eternity_capital")

func _enter_ruins() -> void:
	var portal := get_node_or_null("AshenOutskirts/Portal_RuinsGate") as Node3D
	if portal:
		quest_log.notify_goto("portal_ruins_gate")
		_refresh_quest()
	_persist_and_go("res://world/locations/shard_ruins/ruins_play.tscn", "shard_ruins")
